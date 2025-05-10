//
//  HealthManager.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation
import HealthKit
import SwiftUI

enum HealthKitFetchError: Error {
    case invalidType
    case queryFailed(Error)
    case noData
}

func getSortedUUID() -> String {
    return "\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString)"
}

class HealthManager {
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    private init(){
        Task {
            do {
                try await requestAuthorization()
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func requestAuthorization() async throws {
        let calories = HKQuantityType(.activeEnergyBurned)
        let exercise = HKQuantityType(.appleExerciseTime)
        let stand = HKCategoryType(.appleStandHour)
        let workout = HKObjectType.workoutType()
        let steps = HKQuantityType(.stepCount)
        
        let healthTypes : Set<HKObjectType> = [calories, exercise, stand, workout, steps]
        try await healthStore.requestAuthorization(toShare: [], read: healthTypes)
    }
    
    func fetchHKStatistic(statistic: HKStatistic, startDate: Date, endDate: Date, completion: @escaping (Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        guard let queryType = statistic.queryType() else {
            DispatchQueue.main.async {
                completion(.failure(HealthKitFetchError.invalidType))
            }
            return
        }
        
        if let quantityType = queryType as? HKQuantityType, let options = statistic.options() {
            executeStatisticsQuery(quantityType: quantityType, predicate: predicate, options: options, statistic: statistic, completion: completion)
        } else if let sampleType = queryType as? HKSampleType {
            executeSampleQuery(sampleType: sampleType, predicate: predicate, statistic: statistic, completion: completion)
        } else {
            DispatchQueue.main.async {
                completion(.failure(HealthKitFetchError.invalidType))
            }
        }
    }
    
    private func executeStatisticsQuery(quantityType: HKQuantityType, predicate: NSPredicate, options: HKStatisticsOptions, statistic: HKStatistic, completion: @escaping (Result<Double, Error>) -> Void) {
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: options) { _, statistics, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitFetchError.queryFailed(error)))
                }
                return
            }
            let value = statistic.processStatistics(statistics)
            
            DispatchQueue.main.async {
                completion(.success(value))
            }
        }
        
        healthStore.execute(query)
    }

    private func executeSampleQuery(sampleType: HKSampleType, predicate: NSPredicate, statistic: HKStatistic, completion: @escaping (Result<Double, Error>) -> Void) {
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitFetchError.queryFailed(error)))
                }
                return
            }
            let samples = samples ?? []
            let value = statistic.process(samples: samples)
            
            DispatchQueue.main.async {
                completion(.success(value))
            }
        }
        healthStore.execute(query)
    }
    

    private func fetchWeekWorkoutStatsAsync(selectedWorkouts: [HKWorkoutActivityType]?, statistics: Set<ActivityStatistic>) async throws -> [Activity] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date())
        let startDate = calendar.date(from: startOfWeek) ?? Date().addingTimeInterval(-7*24*60*60)
        
        let workouts = try await fetchWorkouts(from: startDate, to: Date())
        let filteredWorkouts = filterOverlappingWorkouts(workouts)
        
        var stats: [HKWorkoutActivityType: [ActivityStatistic: Double]] = [:]
        
        for workout in filteredWorkouts {
            let type = workout.workoutActivityType
            guard selectedWorkouts?.contains(type) ?? true else { continue }
            
            for statistic in statistics {
                let value = extractStatistic(from: workout, for: statistic)
                stats[type, default: [:]][statistic, default: 0.0] += value
            }
        }
        
        let activities = stats.enumerated().map { index, entry in
            let (type, statistics) = entry
            return Activity(
                id: "\(index)",
                type: .exercise,
                title: type.displayName,
                imageName: type.imageName,
                tintColor: type.color,
                statistics: statistics
            )
        }
        
        return activities
    }
    
    // ExerciseViewModel
    func fetchWeekWorkoutStats(selectedWorkouts: [HKWorkoutActivityType]?, statistics: Set<ActivityStatistic>, completion: @escaping (Result<[Activity], Error>) -> Void) {
        Task {
            do {
                let result = try await fetchWeekWorkoutStatsAsync(selectedWorkouts: selectedWorkouts, statistics: statistics)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout] {
        return try await withCheckedThrowingContinuation { continuation in
            let workouts = HKSampleType.workoutType()
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: workouts,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = results as? [HKWorkout] else {
                    continuation.resume(throwing: NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert samples to workouts"]))
                    return
                }
                
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }


    private func extractStatistic(from workout: HKWorkout, for statistic: ActivityStatistic) -> Double {
        switch statistic {
        case .calories:
            let energyType = HKQuantityType(.activeEnergyBurned)
            return workout.statistics(for: energyType)?
                .sumQuantity()?
                .doubleValue(for: .kilocalorie()) ?? 0.0
        case .duration:
            return workout.duration / 60.0
        default:
            return 0.0
        }
    }

    private func filterOverlappingWorkouts(_ workouts: [HKWorkout]) -> [HKWorkout] {
        let watchWorkouts = workouts.filter { workout in
                workout.device?.model?.lowercased().contains("watch") ?? false
            }
       
        let otherWorkouts = workouts.filter { workout in
            !(workout.device?.model?.lowercased().contains("watch") ?? false)
        }
        
        var filteredWorkouts: [HKWorkout] = otherWorkouts.filter { workout in
            !watchWorkouts.contains { $0.startDate <= workout.endDate || workout.startDate  <= $0.endDate }
        }
        
        filteredWorkouts.append(contentsOf: watchWorkouts)
        return filteredWorkouts.sorted { $0.startDate > $1.startDate }
    }
    
    func fetchWorkoutsForMonth(month: Date, completion: @escaping (Result<[Workout], Error>) -> Void) {
        let workouts = HKSampleType.workoutType()
        let (startDate, endDate) = month.fetchMonthStartAndEndDate()
        
        let predicate = HKQuery.predicateForSamples(withStart:startDate, end:endDate)
        
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: workouts, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let workouts = results as? [HKWorkout], error == nil else {
                completion(.failure(error ?? URLError(.badURL)))
                return
            }
            
            let filteredWorkouts = self.filterOverlappingWorkouts(workouts)
            
            
            let formattedWorkouts: [Workout] = filteredWorkouts.enumerated().map { index, workout in
                
                let energyType = HKQuantityType(.activeEnergyBurned)
                let calories = workout.statistics(for: energyType)?
                        .sumQuantity()?
                        .doubleValue(for: .kilocalorie()) ?? 0
                return Workout(id: index,
                               title: workout.workoutActivityType.displayName,
                               imageName:workout.workoutActivityType.imageName,
                               duration: "\(Int(workout.duration)/60) min",
                               date: workout.startDate.formatWorkoutDate(),
                               calories: "\(calories.formattedNumberString()) kcal",
                               tintColor: workout.workoutActivityType.color)
            }
            
            completion(.success(formattedWorkouts))
        }
        
        healthStore.execute(query)
        
    }
}



// MARK: ChartDataView
extension HealthManager {
    func fetchEarliestStepDate(completion: @escaping (Date?) -> Void) {
        let steps = HKQuantityType(.stepCount)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(
            sampleType: steps,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let firstSample = samples?.first as? HKQuantitySample, error == nil else {
                print("Error fetching earliest step data: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            completion(firstSample.startDate)
        }
        
        healthStore.execute(query)
    }
    
    func calculateNumberOfUnits(from startDate: Date, to endDate: Date, unit: TimeUnit) -> Int {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [unit.calendarComponent]

        
        let dateComponents = calendar.dateComponents(components, from: startDate, to: endDate)
        
        return dateComponents.value(for: unit.calendarComponent) ?? 0
    }
    
    func fetchAllTimeStepsData(timeUnit: TimeUnit, completion: @escaping (Result<[GraphDataPoint], Error>) -> Void) {
        fetchEarliestStepDate { [weak self] earliestDate in
            guard let self = self, let earliestDate = earliestDate else {
                completion(.failure(NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine earliest date"])))
                return
            }
            
            let (startDate, _) = timeUnit.getStartAndEndDates(for: earliestDate)
            
            let today = Date()
            let count = self.calculateNumberOfUnits(from: startDate, to: today, unit: timeUnit) + 1
            
            self.fetchStepsGraphChartData(count: count, timeUnit: timeUnit, completion: completion)
        }
    }
    func fetchStepsGraphChartData(count: Int, timeUnit: TimeUnit, completion: @escaping (Result<[GraphDataPoint], Error>) -> Void) {
        let steps = HKQuantityType(.stepCount)
        var graphData = [GraphDataPoint]()
        let group = DispatchGroup()
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<count {
            group.enter()
            guard let periodDate = calendar.date(byAdding: timeUnit.calendarComponent, value: -i, to: Date()) else {
                group.leave()
                continue
            }
            let (startOfPeriod, endOfPeriod) = timeUnit.getStartAndEndDates(for: periodDate)
            
            let actualEndDate = i == 0 ? min(endOfPeriod, today) : endOfPeriod
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfPeriod, end: actualEndDate)
            
            let interval = DateComponents(day: 1)
            let anchorDate = calendar.startOfDay(for: startOfPeriod)
            
            let query = HKStatisticsCollectionQuery(quantityType: steps,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval)
            
            query.initialResultsHandler = { _, statisticsCollection, error in
                defer { group.leave() }
                
                guard let statisticsCollection = statisticsCollection, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                var dailyTotals: [Double] = []
                statisticsCollection.enumerateStatistics(from: startOfPeriod, to: actualEndDate) { statistics, _ in
                    if let quantity = statistics.sumQuantity() {
                        let steps = quantity.doubleValue(for: .count())
                        dailyTotals.append(steps)
                    } else {
                        dailyTotals.append(0)
                    }
                }
                
                guard !dailyTotals.isEmpty else { return }
                
                let cumulativeSum = dailyTotals.reduce(0, +)
                
                let totalDaysInPeriod = calendar.dateComponents([.day], from: startOfPeriod, to: actualEndDate).day! + 1
                let mean = dailyTotals.reduce(0, +) / Double(dailyTotals.count)
                let variance = dailyTotals.reduce(0) { $0 + pow($1 - mean, 2) } / Double(dailyTotals.count)
                let stdDev = sqrt(variance)
                let maxValue = dailyTotals.max() ?? 0
                let minValue = dailyTotals.min() ?? 0
                
                let dataPoint = GraphDataPoint(
                    date: startOfPeriod,
                    value: mean,
                    stdDev: stdDev,
                    cumSum: cumulativeSum,
                    minDaily: minValue,
                    maxDaily: maxValue,
                    daysInPeriod: totalDaysInPeriod
                )
                graphData.append(dataPoint)
            }
            
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            let sorted = graphData.sorted(by: { $0.date < $1.date })
            completion(.success(sorted))
        }
    }   
    
    func fetchDailyStepsData(count: Int, completion: @escaping (Result<[CountDataPoint], Error>) -> Void) {
        let steps = HKQuantityType(.stepCount)
        var dailyData = [CountDataPoint]()
        let group = DispatchGroup()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<count {
            group.enter()
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else {
                group.leave()
                continue
            }
            
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
            
            let query = HKStatisticsQuery(
                quantityType: steps,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching steps for \(date): \(error.localizedDescription)")
                    return
                }
                
                let count = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                let dataPoint = CountDataPoint(date: startOfDay, count: Int(count))
                dailyData.append(dataPoint)
            }
            healthStore.execute(query)
        }
        
        group.notify(queue: .main) {
            let sortedData = dailyData.sorted { $0.date < $1.date }
            completion(.success(sortedData))
        }
    }
}

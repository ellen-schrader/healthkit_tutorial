//
//  HealthManager.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation
import HealthKit
import SwiftUI

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
    
    func fetchTodayCaloriesBurned(completion: @escaping(Result<Double, Error>) -> Void){
        let calories = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: calories, quantitySamplePredicate: predicate) { _, results, error in
            guard let quantity = results?.sumQuantity() , error == nil else {
                completion(.failure(NSError()))
                return
            }
            
            let calories = quantity.doubleValue(for: .kilocalorie())
            completion(.success(calories))
        }
        healthStore.execute(query)
    }
    
    func fetchTodayExerciseTime(completion: @escaping(Result<Double, Error>) -> Void) {
        let exercise = HKQuantityType(.appleExerciseTime)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        
        let query = HKStatisticsQuery(quantityType: exercise, quantitySamplePredicate: predicate) { _, results, error in
            if let quantity = results?.sumQuantity() {
                let exerciseTime = quantity.doubleValue(for: .minute())
                completion(.success(exerciseTime))
            } else {
                // Fallback to summing workout durations
                self.computeExerciseTimeFromWorkouts(completion: completion)
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchWeekTotalStats(statistics: Set<ActivityStatistic>, completion: @escaping (Result<[ActivityStatistic: Double], Error>) -> Void) {
        Task {
            do {
                let result = try await fetchWeekTotalStatsAsync(statistics: statistics)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchWeekTotalStatsAsync(statistics: Set<ActivityStatistic>) async throws -> [ActivityStatistic: Double] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date())
        let startDate = calendar.date(from: startOfWeek) ?? Date().addingTimeInterval(-7*24*60*60)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        var totals: [ActivityStatistic: Double] = [:]
        
        for stat in statistics {
            let quantityType: HKQuantityType
            let unit: HKUnit
            
            switch stat {
            case .calories:
                quantityType = HKQuantityType(.activeEnergyBurned)
                unit = .kilocalorie()
                
            case .duration:
                quantityType = HKQuantityType(.appleExerciseTime)
                unit = .minute()
                
            case .steps:
                quantityType = HKQuantityType(.stepCount)
                unit = .count()
                
            default:
                continue
            }
            let value = try await queryStatistic(type: quantityType, unit: unit, predicate: predicate)
            totals[stat] = value
        }
        
        return totals
    }

    private func queryStatistic(type: HKQuantityType, unit: HKUnit, predicate: NSPredicate) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let quantity = results?.sumQuantity() {
                    let value = quantity.doubleValue(for: unit)
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            
            healthStore.execute(query)
        }
    }

    func fetchWeekWorkoutStatsAsync(selectedWorkouts: [HKWorkoutActivityType]?, statistics: Set<ActivityStatistic>) async throws -> [Activity] {
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
    
    
    // Added this to compute time from workouts in case exercise minutes is nil. For users who manually add workouts and do not have an apple watch.
    private func computeExerciseTimeFromWorkouts(completion: @escaping(Result<Double, Error>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                completion(.failure(error ?? NSError(domain: "HealthKit", code: 1)))
                return
            }
            let totalMinutes = workouts.reduce(0.0) { $0 + $1.duration / 60.0 }
            completion(.success(totalMinutes))
        }
        
        healthStore.execute(query)
    }
    
    func fetchTodayStandHours(completion: @escaping(Result<Int, Error>) -> Void){
        let stand = HKCategoryType(.appleStandHour)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKSampleQuery(sampleType: stand, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil){
            _, results, error in
            guard let samples = results as? [HKCategorySample] , error == nil else {
                completion(.failure(NSError()))
                return
            }
            let standCount = samples.filter({$0.value == 0}).count // 0 for hours in which the user actually stood (counter intuitive)
            completion(.success(standCount))
        }
        healthStore.execute(query)
    }
    
    //MARK: Fitness Activity
    
    func fetchTodaySteps(completion: @escaping(Result<Activity, Error>) -> Void){
        let steps = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: steps, quantitySamplePredicate: predicate) { _, results, error in
            guard let quantity = results?.sumQuantity() , error == nil else {
                completion(.failure(NSError()))
                return
            }
            
            let steps = quantity.doubleValue(for: .count())
            let activity = Activity(id: getSortedUUID(),
                                    type: .exercise,
                                    title: "Steps",
                                    imageName: "figure.walk",
                                    tintColor: .green,
                                    statistics: [.steps : steps])
            completion(.success(activity))
        }
        healthStore.execute(query)
    }
    
    func fetchCurrentWeeksWorkoutStats(
        selectedWorkouts: [HKWorkoutActivityType]?,
        statistics: Set<ActivityStatistic>,
        completion: @escaping (Result<[Activity], Error>) -> Void){
            
        let workoutType = HKSampleType.workoutType()
        let calendar = Calendar.current
        let now = Date()
        let startOfWeekComponents = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now)
        let startDate = calendar.date(from: startOfWeekComponents) ?? now.addingTimeInterval(-7 * 24 * 60 * 60)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
        
        let query = HKSampleQuery(sampleType: workoutType,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) {[weak self] _, results, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let workouts = results as? [HKWorkout] else {
                completion(.failure(NSError()))
                return
            }
            
            var stats: [HKWorkoutActivityType: [ActivityStatistic: Double]] = [:]
            
            let filteredWorkouts = self.filterOverlappingWorkouts(workouts)
            
            for workout in filteredWorkouts {
                let type = workout.workoutActivityType
                guard selectedWorkouts?.contains(type) ?? true else { continue }
                
                for statistic in statistics {
                    let value = self.extractStatistic(from: workout, for: statistic)
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
            completion(.success(activities))
        }
        healthStore.execute(query)
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

    func filterOverlappingWorkouts(_ workouts: [HKWorkout]) -> [HKWorkout] {
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

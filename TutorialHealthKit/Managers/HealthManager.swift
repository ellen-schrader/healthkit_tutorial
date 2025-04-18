//
//  HealthManager.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation
import HealthKit
import SwiftUI

extension Double {
    func formattedNumberString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US") // Ensures 1,000 instead of 1.000
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
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
    
    func fetchTodayCaloriesBurned(completion: @escaping(Result<Activity, Error>) -> Void){
        let calories = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
        let query = HKStatisticsQuery(quantityType: calories, quantitySamplePredicate: predicate) { _, results, error in
            guard let quantity = results?.sumQuantity() , error == nil else {
                completion(.failure(NSError()))
                return
            }
            
            let calorieCount = quantity.doubleValue(for: .kilocalorie())
            
            let activity = Activity(id: 1,
                                    title: "Calories",
                                    subtitle: "Goal 600 kcal",
                                    imageName: "flame.fill",
                                    tintColor: .orange,
                                    amount: calorieCount.formattedNumberString())
            completion(.success(activity))
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
            let activity = Activity(id: 0,
                                    title: "Steps",
                                    subtitle: "Goal 10,000",
                                    imageName: "figure.walk",
                                    tintColor: .green,
                                    amount: steps.formattedNumberString())
            completion(.success(activity))
        }
        healthStore.execute(query)
    }
    
    func fetchCurrentWeeksWorkoutStats(completion: @escaping (Result<[Activity], Error>) -> Void) {
        let workouts = HKSampleType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: .startOfWeek, end: Date())
        
        let query = HKSampleQuery(sampleType: workouts, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let workouts = results as? [HKWorkout], error == nil else {
                completion(.failure(error ?? NSError()))
                return
            }
            
            var stats: [HKWorkoutActivityType: Int] = [:]
            let includedTypes: [HKWorkoutActivityType] = [.running, .traditionalStrengthTraining, .walking, .cooldown, .yoga]
            
            let filteredWorkouts = self.filterOverlappingWorkouts(workouts)
            
            for workout in filteredWorkouts {
                let type = workout.workoutActivityType
                guard includedTypes.contains(type) else { continue }
                
                let duration = Int(workout.duration) / 60
                stats[type, default: 0] += duration
            }
            let activities: [Activity] = stats.enumerated().map { index, pair in
                let (type, minutes) = pair
                return Activity(
                    id: index + 2, // after steps and calories
                    title: type.displayName,
                    subtitle: "This week",
                    imageName: type.imageName,
                    tintColor: type.color,
                    amount: "\(minutes) min"
                )
            }
            
            completion(.success(activities))
        }
        
        healthStore.execute(query)
    }
    
    //  MARK: Recent Workouts
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
                let dailyMean = cumulativeSum / Double(totalDaysInPeriod)
                let mean = dailyTotals.reduce(0, +) / Double(dailyTotals.count)
                let variance = dailyTotals.reduce(0) { $0 + pow($1 - mean, 2) } / Double(dailyTotals.count)
                let stdDev = sqrt(variance)
                
                let dataPoint = GraphDataPoint(
                    date: startOfPeriod,
                    value: mean,
                    stdDev: stdDev,
                    total: cumulativeSum,
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

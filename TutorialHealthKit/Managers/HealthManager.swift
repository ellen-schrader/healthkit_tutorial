//
//  HealthManager.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation
import HealthKit

import SwiftUI
import HealthKit

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .traditionalStrengthTraining: return "Strength"
        case .walking: return "Walking"
        case .cooldown: return "Cooldown"
        default: return "Other"
        }
    }

    var imageName: String {
        switch self {
        case .running: return "figure.run"
        case .traditionalStrengthTraining: return "dumbbell"
        case .walking: return "figure.walk"
        case .cooldown: return "wind"
        default: return "questionmark"
        }
    }

    var color: Color {
        switch self {
        case .running: return .blue
        case .traditionalStrengthTraining: return .red
        case .walking: return .green
        case .cooldown: return .orange
        default: return .gray
        }
    }
}


extension Date {
    
    static var startOfDay: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    static var startOfWeek: Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 2 // Monday
        return calendar.date(from: components) ?? Date()
    }
    
    
    
}

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
    
//    func fetchTodayExerciseTime(completion: @escaping(Result<Double, Error>) -> Void){
//        let exercise = HKQuantityType(.appleExerciseTime)
//        let predicate = HKQuery.predicateForSamples(withStart: .startOfDay, end: Date())
//        let query = HKStatisticsQuery(quantityType: exercise, quantitySamplePredicate: predicate) { _, results, error in
//            guard let quantity = results?.sumQuantity() , error == nil else {
//                completion(.failure(NSError()))
//                return
//            }
//            
//            let exerciseTime = quantity.doubleValue(for: .minute())
//            completion(.success(exerciseTime))
//        }
//        healthStore.execute(query)
//    }
    
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
            print("Workout: \(workouts)")
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

            for workout in workouts {
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

    
}

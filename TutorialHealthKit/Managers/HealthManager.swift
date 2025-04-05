//
//  HealthManager.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation
import HealthKit

extension Date {
    
    static var startOfDay: Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
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
        
        let healthTypes : Set<HKObjectType> = [calories, exercise, stand, workout]
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
            
            let calorieCount = quantity.doubleValue(for: .kilocalorie())
            completion(.success(calorieCount))
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
}

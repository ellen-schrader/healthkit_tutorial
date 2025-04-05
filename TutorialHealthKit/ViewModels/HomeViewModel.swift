//
//  HomeViewModel.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation


class HomeViewModel: ObservableObject {
    
    let healthManager = HealthManager.shared
    
    @Published var calories: Int = 0
    @Published var exercise: Int = 0
    @Published var stand: Int = 0
    

    @Published var mockActivities: [Activity] = [
        Activity(id: 0,
                 title: "Steps",
                 subtitle: "Goal 10,000",
                 imageName: "figure.walk",
                 tintColor: .green,
                 amount: "1,234"),
        Activity(id: 1,
                 title: "Calories",
                 subtitle: "Goal 800 kcal",
                 imageName: "flame.fill",
                 tintColor: .orange,
                 amount: "600"),
        Activity(id: 2,
                 title: "Run",
                 subtitle: "Goal 30min",
                 imageName: "figure.run",
                 tintColor: .red,
                 amount: "10min"),
        Activity(id: 3,
                 title: "Sleep",
                 subtitle: "Goal 8 hours",
                 imageName: "bed.double.fill",
                 tintColor: .blue,
                 amount: "7.5h")
    ]
    
    @Published var mockWorkouts: [Workout] = [
        Workout(id: 0, title: "Running", imageName: "figure.run", duration: "23 min", date: Date().formatted(.dateTime.month().day()), calories: "341 kcal", tintColor: .cyan),
        Workout(id: 1, title: "Yoga", imageName: "figure.yoga", duration: "30 min", date: Date().formatted(.dateTime.month().day()), calories: "75 kcal", tintColor: .cyan),
        Workout(id: 2, title: "Strength Training", imageName: "figure.strengthtraining.traditional", duration: "56 min", date: Date().formatted(.dateTime.month().day()), calories: "402 kcal", tintColor: .cyan),
        Workout(id: 3, title: "Walk", imageName: "figure.walk", duration: "75 min", date: Date().formatted(.dateTime.month().day()), calories: "202 kcal", tintColor: .cyan)
    ]
    
    
    init() {
        Task {
            do{
                try await healthManager.requestAuthorization()
                fetchTodayCaloriesBurned()
                fetchTodayExerciseTime()
                fetchTodayStandHours()}
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func fetchTodayCaloriesBurned() {
        healthManager.fetchTodayCaloriesBurned { result in
            switch result {
            case .success(let calories):
                DispatchQueue.main.async {
                    self.calories = Int(calories)
                }
            case .failure(let error):
                print("Error fetching calories: \(error)")
            }
        }
    }
    
    func fetchTodayExerciseTime(){
        healthManager.fetchTodayExerciseTime{
            result in
            switch result {
            case .success(let time):
                DispatchQueue.main.async {
                    self.exercise = Int(time)
                    print("Exercise time: \(self.exercise)")
                }
                
            case .failure(let error):
                print("Error fetching exercise time: \(error)")
            }
        }
    }
    
    func fetchTodayStandHours() {
        healthManager.fetchTodayStandHours{
            result in
            switch result {
            case .success(let hours):
                DispatchQueue.main.async {
                    self.stand = hours
                }
            case .failure(let error):
                print("Error fetching stand: \(error)")
            }
        }
        
    }
    
}

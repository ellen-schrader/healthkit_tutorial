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
    @Published var activities: [Activity] = []
    @Published var workouts: [Workout] = []
    

    @Published var mockActivities: [Activity] = [
        Activity(id: "0",
                 type: .exercise,
                 title: "Exercise",
                 imageName: "dumbbell.fill",
                 tintColor: .red,
                 statistics: [.duration : 170]),
        Activity(id: "1",
                 type: .metabolism,
                 title: "Metabolism",
                 imageName: "flame.fill",
                 tintColor: .orange,
                 statistics: [.calories: 600]),
        Activity(id: "2",
                 type: .sleep,
                 title: "Sleep",
                 imageName: "moon.fill",
                 tintColor: .blue,
                 statistics: [.duration: 460]
                 ),
        Activity(id: "3",
                 type: .mentalHealth,
                 title: "Mental",
                 imageName: "brain.head.profile",
                 tintColor: .purple,
                 statistics: [.mood: 5])
    ]
    
    @Published var mockWorkouts: [Workout] = [
        Workout(id: 0, title: "Running", imageName: "figure.run", duration: "23 min", date: Date().formatted(.dateTime.month().day()), calories: "341 kcal", tintColor: .cyan),
        Workout(id: 1, title: "Yoga", imageName: "figure.yoga", duration: "30 min", date: Date().formatted(.dateTime.month().day()), calories: "75 kcal", tintColor: .cyan),
        Workout(id: 2, title: "Strength Training", imageName: "figure.strengthtraining.traditional", duration: "56 min", date: Date().formatted(.dateTime.month().day()), calories: "402 kcal", tintColor: .cyan),
        Workout(id: 3, title: "Walk", imageName: "figure.walk", duration: "75 min", date: Date().formatted(.dateTime.month().day()), calories: "202 kcal", tintColor: .cyan)
    ]
    
    
    init() {
//        Task {
//            do{
//                try await healthManager.requestAuthorization()
//                fetchTodayCaloriesBurned()
//                fetchTodayExerciseTime()
//                fetchTodayStandHours()
//                fetchTodaySteps()
//                fetchWorkoutStats()
//                fetchRecentWorkouts(month: Date(), numberOfWorkouts: 10)
//                
//            }
//            catch {
//                print(error.localizedDescription)
//            }
//        }
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
    
    //MARK: Fitness Activity
    
    func fetchTodaySteps(){
        healthManager.fetchTodaySteps{
            result in
            switch result {
            case .success(let steps):
                DispatchQueue.main.async {
                    self.activities.append(steps)
                }
            case .failure(let error):
                print("Error fetching steps: \(error)")
            }
        }
    }
    
    func fetchWorkoutStats(){
        healthManager.fetchWeekWorkoutStats(selectedWorkouts: nil, statistics: [.duration, .calories]){
            result in
            switch result {
            case .success(let stats):
                DispatchQueue.main.async {
                    self.activities.append(contentsOf: stats)
                }
            case .failure(let error):
                print("Error fetching workout stats: \(error)")
            }
        }
    }
    
    func fetchRecentWorkouts(month: Date, numberOfWorkouts: Int){
        healthManager.fetchWorkoutsForMonth(month: month){
            result in
            switch result {
            case .success(let workouts):
                DispatchQueue.main.async {
                    self.workouts = Array(workouts.prefix(numberOfWorkouts))
                }
            case .failure(let error):
                print("Error fetching workouts: \(error)")
            }
        }
    }
    
}

//
//  HomeViewModel.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    
    let healthManager = HealthManager.shared
    @Published var activityUpdateTrigger = UUID()
    private var cancellables = Set<AnyCancellable>()
    @Published var stand: Int = 0
    
    @Published var workouts: [Workout] = []
    @Published var _activities: [String : Activity] = [
        "Exercise": Activity(id: "0",
                           type: .exercise,
                           title: "Exercise",
                           imageName: "dumbbell.fill",
                           tintColor: .red,
                           statistics: [.duration: 0]),
        "Metabolism" : Activity(id: "1",
                                    type: .metabolism,
                                    title: "Metabolism",
                                    imageName: "flame.fill",
                                    tintColor: .orange,
                                    statistics: [.calories: 0]),
        "Sleep" : Activity(id: "2",
                             type: .sleep,
                             title: "Sleep",
                             imageName: "moon.fill",
                             tintColor: .blue,
                             statistics: [.hours: 0]),
        "Mental":    Activity(id: "3",
                              type: .mentalHealth,
                              title: "Mental",
                              imageName: "brain.head.profile",
                              tintColor: .purple,
                              statistics: [.mood: 0])
    ]
    
    var calories: Int {
        return Int(activities["Metabolism"]?.statistics[.calories] ?? 0)
        }
    
    var mood: Int{
        return Int(activities["Mood"]?.statistics[.mood] ?? 0)
    }
    
    var exercise: Int{
        return Int(activities["Exercise"]?.statistics[.duration] ?? 0)
    }
    

    var activities: [String : Activity] {
        _ = activityUpdateTrigger
        return _activities
    }

    func updateActivity(_ key: String, with activity: Activity) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self._activities[key] = activity
            self.activityUpdateTrigger = UUID()
        }
    }

    
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
                fetchTodayStandHours()
                fetchTodaySleepDuration()
                
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
    }

    
    func fetchTodayCaloriesBurned() {
            healthManager.fetchHKStatistic(statistic: .caloriesBurned, startDate: .startOfDay, endDate: Date()) { [weak self] result in
                switch result {
                case .success(let calories):
                    DispatchQueue.main.async {
                        guard let self = self, let activity = self.activities["Metabolism"] else { return }
                        let updatedActivity = activity.updatingStatistic(.calories, value: calories)
                        self.updateActivity("Metabolism", with: updatedActivity)
                        print("Calories: \(calories)")
                    }
                case .failure(let error):
                    print("Error fetching calories: \(error)")
                }
            }
        }
    
    func fetchTodayExerciseTime() {
        healthManager.fetchHKStatistic(statistic: .exerciseTime, startDate: .startOfDay, endDate: Date()) { [weak self] result in
            switch result {
            case .success(let minutes):
                DispatchQueue.main.async {
                    guard let self = self, let activity = self._activities["Exercise"] else { return }
                    let updatedActivity = activity.updatingStatistic(.duration, value: minutes)
                    self.updateActivity("Exercise", with: updatedActivity)
                    print("Updated exercise: \(minutes)")
                }
            case .failure(let error):
                print("Error fetching exercise time: \(error)")
            }
        }
    }
    
    func fetchTodayStandHours() {
        healthManager.fetchHKStatistic(statistic: .standHours, startDate: .startOfDay, endDate: Date()) { [weak self] result in
            switch result {
            case .success(let hours):
                DispatchQueue.main.async {
                    self?.stand = Int(hours)
                }
            case .failure(let error):
                print("Error fetching stand hours: \(error)")
            }
        }
    }

    func fetchTodaySleepDuration() {
        healthManager.fetchHKStatistic(statistic: .sleepDuration, startDate: .startOfDay, endDate: Date()) { [weak self] result in
            switch result {
            case .success(let duration):
                DispatchQueue.main.async {
                    guard let self = self, let activity = self._activities["Sleep"] else { return }
                    let updatedActivity = activity.updatingStatistic(.hours, value: duration)
                    self.updateActivity("Sleep", with: updatedActivity)
                    print("Updated sleep: \(duration)")
                }
            case .failure(let error):
                print("Error fetching sleep duration: \(error)")
            }
        }
    }
    
}

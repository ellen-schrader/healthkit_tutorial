//
//  ExerciseViewModel.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 19/04/2025.
//

import Foundation
import HealthKit

class ExerciseViewModel: ObservableObject {
    
    let healthManager = HealthManager.shared

    @Published var isLoading: Bool = false
    
    @Published var calories: Int = 0
    @Published var exercise: Int = 0
    @Published var steps: Int = 0
    
    @Published var activities: [Activity] = []
    @Published var workouts: [Workout] = []
    
    @Published var activityGoal: [ActivityStatistic:Double] = [ActivityStatistic.duration: 300.0, ActivityStatistic.calories: 4200.0]
    
    @Published var totals: [ActivityStatistic:Double] = [:]
    
    @Published var proportionActivities: [ActivityStatistic:[BarChartItem]] = [:]
    
    private var selectedActivities: [HKWorkoutActivityType] = [.running, .traditionalStrengthTraining, .cooldown, .yoga]
    

    @Published var mockActivities: [Activity] = [
        Activity(id: "0",
                 type: .exercise,
                 title: "Strength",
                 imageName: "dumbbell.fill",
                 tintColor: .red,
                 statistics: [.duration : 160]),
        Activity(id: "1",
                 type: .exercise,
                 title: "Cardio",
                 imageName: "figure.run",
                 tintColor: .orange,
                 statistics: [.duration: 60])
    ]
    
    @Published var mockWorkouts: [Workout] = [
        Workout(id: 0, title: "Running", imageName: "figure.run", duration: "23 min", date: Date().formatted(.dateTime.month().day()), calories: "341 kcal", tintColor: .cyan),
        Workout(id: 1, title: "Yoga", imageName: "figure.yoga", duration: "30 min", date: Date().formatted(.dateTime.month().day()), calories: "75 kcal", tintColor: .cyan),
        Workout(id: 2, title: "Strength Training", imageName: "figure.strengthtraining.traditional", duration: "56 min", date: Date().formatted(.dateTime.month().day()), calories: "402 kcal", tintColor: .cyan),
        Workout(id: 3, title: "Walk", imageName: "figure.walk", duration: "75 min", date: Date().formatted(.dateTime.month().day()), calories: "202 kcal", tintColor: .cyan)
    ]
    
    @Published var mockSummaryData: [BarChartItem] = [
        .init(id: 0, name: "Cardio", size: 0.3, color: .blue),
        .init(id: 1, name: "Strength", size: 0.4, color: .red),
        .init(id: 2, name: "Mobility", size: 0.1, color: .orange),
        .init(id: 3, name: "Missing", size: 0.2, color:  .gray.opacity(0.2))
    ]
    
    init() {
        Task {
            do{
                try await healthManager.requestAuthorization()
                fetchWeekTotalStats()
                fetchWorkoutStats(statistics: [.duration, .calories])
                fetchRecentWorkouts(month: Date(), numberOfWorkouts: 5)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func fetchTodayCaloriesBurned() {
        healthManager.fetchHKStatistic(statistic: .caloriesBurned, startDate: .startOfDay, endDate: Date()) { result in
            switch result {
            case .success(let calories):
                self.calories = Int(calories)
            case .failure(let error):
                print("Error fetching calories: \(error)")
            }
        }
    }
    
    //MARK: Fitness Activity
    
    func fetchWeekTotalStats(){
        healthManager.fetchHKStatistic(statistic: .caloriesBurned, startDate: .startOfWeek, endDate: Date()) { result in
            switch result {
            case .success(let calories):
                self.totals[.calories] = calories
            case .failure(let error):
                print("Error fetching weeks exercise timr: \(error)")
            }
        }
        
        healthManager.fetchHKStatistic(statistic: .exerciseTime, startDate: .startOfWeek, endDate: Date()) { result in
            switch result {
            case .success(let duration):
                self.totals[.duration] = duration
            case .failure(let error):
                print("Error fetching weeks exercise time: \(error)")
            }
        }
    }
    
    func fetchWorkoutStats(statistics: Set<ActivityStatistic> = [.duration, .calories]) {
        healthManager.fetchWeekWorkoutStats(selectedWorkouts: self.selectedActivities,
                                                statistics: statistics) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let stats):
                DispatchQueue.main.async {
                    self.activities = stats
                    for statistic in statistics {
                        self.getProportionWorkouts(statistic: statistic)
                    }
                }
            case .failure(let error):
                print("Error fetching workout stats: \(error)")
            }
        }
    }
    
    func getProportionWorkouts(statistic: ActivityStatistic = ActivityStatistic.duration){
        if self.activities == [] {
            return
        }
        
        let totalSelectedWorkouts: Double = self.activities.reduce(0, {$0 + ($1.statistics[statistic] ?? 0.0)})
        let total: Double = self.totals[statistic] ?? totalSelectedWorkouts
        let goal: Double = self.activityGoal[statistic] ?? 100
        
        var proportionWorkouts: [BarChartItem] = self.activities.enumerated().map { index, activity in
            let barChartItem: BarChartItem
            barChartItem = BarChartItem(
                id: index,
                name: activity.title,
                size: (activity.statistics[statistic] ?? 0.0)/total,
                color: activity.tintColor
            )
            return barChartItem
        }
        
        let otherWorkouts: BarChartItem = BarChartItem(
            id: self.activities.count,
            name: "Other",
            size: (total - totalSelectedWorkouts)/goal,
            color: .gray
        )
        
        let missing: BarChartItem = BarChartItem(
            id: self.activities.count + 1,
            name: "Missing",
            size: total < goal ? (goal - total)/goal :0.0,
            color: .gray.opacity(0.2)
        )
        
        proportionWorkouts.append(otherWorkouts)
        proportionWorkouts.append(missing)
        
        print(proportionWorkouts)
        
        self.proportionActivities[statistic] = proportionWorkouts
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

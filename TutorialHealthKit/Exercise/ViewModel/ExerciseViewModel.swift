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

    @Published var activities: [Activity] = []
    @Published var workouts: [Workout] = []
    
    @Published var activityGoal: [ActivityStatistic:Double] = [ActivityStatistic.duration: 300.0, ActivityStatistic.calories: 4200.0]
    
    @Published var totals: [ActivityStatistic:Double] = [:]
    
    @Published var proportionActivities: [ActivityStatistic:[BarChartItem]] = [:]
    
    @Published var selectedActivities: [HKWorkoutActivityType] = [.running, .traditionalStrengthTraining, .cooldown, .yoga]
    @Published var availableWorkoutTypes: [HKWorkoutActivityType] = [
        .running, .walking, .yoga, .traditionalStrengthTraining, 
        .cooldown, .cycling, .swimming, .hiking]
    
    
    private let selectedWorkoutsKey = "SelectedWorkoutTypes"
    private let defaultWorkoutTypes: [HKWorkoutActivityType] = [.running, .traditionalStrengthTraining, .cooldown, .yoga]
       
    init() {
           loadSelectedWorkouts()
           if selectedActivities.isEmpty {
               selectedActivities = defaultWorkoutTypes
           }
        
           Task {
               do {
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
    
    private func saveSelectedWorkouts() {
        let rawValues = selectedActivities.map { $0.rawValue }
        UserDefaults.standard.set(rawValues, forKey: selectedWorkoutsKey)
        print("Saved workout types: \(selectedActivities.map(\.displayName).joined(separator: ", "))")
    }
    
    private func loadSelectedWorkouts() {
        if let rawValues = UserDefaults.standard.array(forKey: selectedWorkoutsKey) as? [UInt] {
            selectedActivities = rawValues.compactMap { HKWorkoutActivityType(rawValue: $0) }
            print("Loaded workout types: \(selectedActivities.map(\.displayName).joined(separator: ", "))")
        }
    }
    
    func toggleWorkoutSelection(_ workoutType: HKWorkoutActivityType) {
        print("Toggling workout type: \(workoutType.displayName)")
        if self.selectedActivities.contains(workoutType) {
            self.selectedActivities.removeAll { $0 == workoutType }
        } else {
            self.selectedActivities.append(workoutType)
        }
        
        saveSelectedWorkouts()

        print("Selected workout types: \(selectedActivities.map(\.displayName).joined(separator: ", "))")
        self.activities.removeAll()
        self.fetchWorkoutStats(statistics: [.duration, .calories])
    }
    
    func isWorkoutTypeSelected(_ workoutType: HKWorkoutActivityType) -> Bool {
        return self.selectedActivities.contains(workoutType)
    }
    
    func resetToDefaultWorkoutTypes() {
        selectedActivities = defaultWorkoutTypes
        saveSelectedWorkouts()
        self.activities.removeAll()
        self.fetchWorkoutStats(statistics: [.duration, .calories])
    }


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
    

    
    func refresh(){
        DispatchQueue.main.async{
            self.activities.removeAll()
            self.workouts.removeAll()
        }
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
                    let includedActivities = Set(self.activities.map { $0.title })
                    let zeroActivities = self.selectedActivities.filter { workoutType in
                        !includedActivities.contains(workoutType.displayName)
                    }
                    print(self.activities.map{$0.title})
                    print(self.activities)
                    for hkWorkoutType in zeroActivities {
                        self.activities.append(self.createZeroActivity(for: hkWorkoutType))
                    }
                    
                    for statistic in statistics {
                        self.calculateProportions(statistic: statistic)
                    }
                }
            case .failure(let error):
                print("Error fetching workout stats: \(error)")
                DispatchQueue.main.async {
                    for hkWorkoutType in self.selectedActivities {
                        self.activities.append(self.createZeroActivity(for: hkWorkoutType))
                    }
                    for statistic in statistics {
                        self.calculateProportions(statistic: statistic)
                    }
                }
            }
        }
    }
    
    private func createZeroActivity(for workoutType: HKWorkoutActivityType) -> Activity {
        return Activity(
            id: "default-\(workoutType.rawValue)",
            type: .exercise,
            title: workoutType.displayName,
            imageName: workoutType.imageName,
            tintColor: workoutType.color,
            statistics: [.duration: 0.0, .calories: 0.0]
        )
    }
    
    func calculateProportions(statistic: ActivityStatistic) {
        if self.activities.isEmpty {
            return
        }
        
        let totalSelectedWorkouts: Double = self.activities.reduce(0, {$0 + ($1.statistics[statistic] ?? 0.0)})
        let total: Double = self.totals[statistic] ?? totalSelectedWorkouts
        let goal: Double = self.activityGoal[statistic] ?? 100
        
        var proportionWorkouts: [BarChartItem] = self.activities.enumerated().map { index, activity in
            let value = activity.statistics[statistic] ?? 0.0
            return BarChartItem(
                id: index,
                name: activity.title,
                size: value / goal,
                color: activity.tintColor
            )
        }
        
        let otherValue = total - totalSelectedWorkouts
        if otherValue > 0 {
            let otherWorkouts: BarChartItem = BarChartItem(
                id: self.activities.count,
                name: "Other",
                size: otherValue / goal,
                color: .gray
            )
            proportionWorkouts.append(otherWorkouts)
        }
        
        let missingValue = goal - total
        if missingValue > 0 {
            let missing: BarChartItem = BarChartItem(
                id: self.activities.count + 1,
                name: "Missing",
                size: missingValue / goal,
                color: .gray.opacity(0.2)
            )
            proportionWorkouts.append(missing)
        }
        
        print("Bar chart items for \(statistic):")
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

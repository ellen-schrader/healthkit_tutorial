//
//  HomeViewModel.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import Foundation


class HomeViewModel: ObservableObject {
    var calories: Int = 123
    var activity: Int = 45
    var stand: Int = 12
    

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
    
}

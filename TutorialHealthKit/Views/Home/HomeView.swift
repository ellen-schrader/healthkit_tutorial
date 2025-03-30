//
//  HomeView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 29/03/2025.
//

import SwiftUI

struct HomeView: View {
    @State var calories: Int = 123
    @State var activity: Int = 45
    @State var stand: Int = 12
    
    var mockActivities: [Activity] = [
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
    
    var mockWorkouts: [Workout] = [
        Workout(id: 0, title: "Running", imageName: "figure.run", duration: "23 min", date: Date().formatted(.dateTime.month().day()), calories: "341 kcal", tintColor: .cyan),
        Workout(id: 1, title: "Yoga", imageName: "figure.yoga", duration: "30 min", date: Date().formatted(.dateTime.month().day()), calories: "75 kcal", tintColor: .cyan),
        Workout(id: 2, title: "Strength Training", imageName: "figure.strengthtraining.traditional", duration: "56 min", date: Date().formatted(.dateTime.month().day()), calories: "402 kcal", tintColor: .cyan),
        Workout(id: 3, title: "Walk", imageName: "figure.walk", duration: "75 min", date: Date().formatted(.dateTime.month().day()), calories: "202 kcal", tintColor: .cyan)
    ]
                                      
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment : .leading) {
                    Text("Welcome")
                        .font(.largeTitle)
                        .padding()
                    HStack{
                        
                        Spacer()
                        
                        VStack{
                            VStack(alignment: .leading, spacing: 8){
                                Text("Calories")
                                    .font(.callout)
                                    .bold()
                                    .foregroundColor(.red)
                                Text("\(calories) kcal")
                                    .bold()
                            }
                            .padding(.bottom)
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text("Active")
                                    .font(.callout)
                                    .bold()
                                    .foregroundColor(.green)
                                Text("\(activity) mins")
                                    .bold()
                            }
                            .padding(.bottom)
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text("Stand")
                                    .font(.callout)
                                    .bold()
                                    .foregroundColor(.blue)
                                Text("\(stand) hours")
                                    .bold()
                            }
                            
                        }
                        
                        Spacer()
                        
                        
                        ZStack{
                            ProgressCircleView(progress: $calories, color: .red, goal: 600)
                            ProgressCircleView(progress: $activity, color: .green, goal: 60)
                                .padding(.all, 20)
                            ProgressCircleView(progress: $stand, color: .blue, goal: 8)
                                .padding(.all, 40)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                    
                    HStack{
                        Text("Fitness Activity")
                            .font(.title2)
                        Spacer()
                        Button{
                            print("Show More")
                        }label: {
                            Text("Show More")
                                .padding(.all, 10)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(spacing:10), count:2)){
                        ForEach(mockActivities){ activity in
                            ActivityCard(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                    
                    
                    HStack{
                        Text("Recent Workouts")
                            .font(.title2)
                        Spacer()
                        NavigationLink{
                            EmptyView()
                        }label: {
                            Text("Show More")
                                .padding(.all, 10)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                    
                    
                    LazyVGrid(columns: Array(repeating: GridItem(), count:1)){
                        ForEach(mockWorkouts){ workout in
                            WorkoutCard(workout: workout)
                        }
                    }
                    .padding(.horizontal)
                }
                
            }
        }
    }
}

#Preview {
    HomeView()
}

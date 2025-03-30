//
//  HomeView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 29/03/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel = .init()

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
                                Text("\(viewModel.calories) kcal")
                                    .bold()
                            }
                            .padding(.bottom)
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text("Active")
                                    .font(.callout)
                                    .bold()
                                    .foregroundColor(.green)
                                Text("\(viewModel.activity) mins")
                                    .bold()
                            }
                            .padding(.bottom)
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text("Stand")
                                    .font(.callout)
                                    .bold()
                                    .foregroundColor(.blue)
                                Text("\(viewModel.stand) hours")
                                    .bold()
                            }
                            
                        }
                        
                        Spacer()
                        
                        
                        ZStack{
                            ProgressCircleView(progress: $viewModel.calories, color: .red, goal: 600)
                            ProgressCircleView(progress: $viewModel.activity, color: .green, goal: 60)
                                .padding(.all, 20)
                            ProgressCircleView(progress: $viewModel.stand, color: .blue, goal: 8)
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
                        ForEach(viewModel.mockActivities){ activity in
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
                        ForEach(viewModel.mockWorkouts){ workout in
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

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
                                Text("\(viewModel.exercise) mins")
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
                            ProgressCircleView(progress: $viewModel.exercise, color: .green, goal: 60)
                                .padding(.all, 20)
                            ProgressCircleView(progress: $viewModel.stand, color: .blue, goal: 8)
                                .padding(.all, 40)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                    
                    HStack {
                        Text("Categories")
                            .font(.title2)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2)) {
                        ForEach(viewModel.mockActivities.sorted(by: { $0.id < $1.id })) { activity in
                            NavigationLink(destination: getDestinationView(for: activity)) {
                                ActivityCard(activity: activity,
                                             clickable: true,
                                             statistic: activity.statistics.keys.first ?? .duration)
                            }
                            .foregroundStyle(.primary)
//                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Dashboard")
        }
    }
        
        @ViewBuilder
        private func getDestinationView(for activity: Activity) -> some View {
            switch activity.type {
            case .exercise:
                ExerciseHomeView()
            case .metabolism:
                Text("Metabolic View")
            case .sleep:
                Text("Sleep View")
            case .mentalHealth:
                Text("Mental View")
            }
        }
    }


#Preview {
    HomeView()
}


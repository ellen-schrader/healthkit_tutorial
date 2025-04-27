//
//  ExerciseHomeView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 19/04/2025.
//
import SwiftUI

struct ExerciseHomeView: View {
    @StateObject var viewModel: ExerciseViewModel = .init()
   

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading){
                    Text("Exercise")
                            .font(.title)
                            .bold()
                            .padding(.bottom)
                    
                    VStack(alignment: .leading, spacing: 16){
                        Text("Weekly Stats")
                                .font(.title2)
                        ProportionBarChart(data: viewModel.proportionActivities[.duration] ?? [],
                                           total: "\(viewModel.totals[.duration]?.formattedNumberString() ?? "") min",
                                           goal: "\(viewModel.activityGoal[.duration]?.formattedNumberString() ?? "") min",
                                               title: "Exercise Time")
                        ProportionBarChart(data: viewModel.proportionActivities[.calories] ?? [],
                                           total: "\(viewModel.totals[.calories]?.formattedNumberString() ?? "") kcal",
                                           goal: "\(viewModel.activityGoal[.calories]?.formattedNumberString() ?? "") kcal",
                                               title: "Calories Burned")
                            
                    }.padding(.bottom)
                        
                        
                        Text("Categories")
                        .font(.title2)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(spacing:10), count:2)){
                            ForEach(viewModel.activities.sorted(by: { $0.id < $1.id })){ activity in
                                ActivityCard(activity: activity,
                                             statistic: ActivityStatistic.duration)
                            }
                        }
                        .padding(.bottom)
                        
                        
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
                        
                        
                        LazyVGrid(columns: Array(repeating: GridItem(), count:1)){
                            ForEach(viewModel.workouts){ workout in
                                WorkoutCard(workout: workout)
                            }
                        }
                    }
                    
                }
            }.padding(.horizontal)
        }
}

//#Preview {
//    ExerciseHomeView()
//}

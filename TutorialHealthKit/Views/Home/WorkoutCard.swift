//
//  WorkoutCard.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import SwiftUI

struct WorkoutCard: View {
    @State var workout: Workout
    var body: some View {
        HStack {
            Image(systemName: workout.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(workout.tintColor)
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(10)
            VStack(spacing: 16){
                HStack(){
                    Text(workout.title)
                        .font(.title3)
                        .bold(true)
                    
                    Spacer()
                    Text(workout.duration)
                }
                HStack(){
                    Text(workout.date)
                    
                    Spacer()
                    
                    Text(workout.calories)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    let workout = Workout(id: 0, title: "Running", imageName: "figure.run", duration: "23 min", date: Date().formatted(.dateTime.month().day()), calories: "341 kcal", tintColor: .cyan)
    return WorkoutCard(workout: workout)
}

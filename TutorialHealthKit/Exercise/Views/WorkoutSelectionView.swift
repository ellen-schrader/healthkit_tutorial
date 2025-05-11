//
//  WorkoutSelectionView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 11/05/2025.
//

import SwiftUI
import HealthKit

struct WorkoutSelectionView: View {
    @ObservedObject var viewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.availableWorkoutTypes, id: \.rawValue) { workoutType in
                    HStack {
                        Image(systemName: workoutType.imageName)
                            .foregroundColor(workoutType.color)
                            .frame(width: 30, height: 30)
                        
                        Text(workoutType.displayName)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        if viewModel.isWorkoutTypeSelected(workoutType) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleWorkoutSelection(workoutType)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutSelectionView(viewModel: .init())
}

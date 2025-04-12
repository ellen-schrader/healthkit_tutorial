//
//  Workout.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import SwiftUI

struct Workout: Identifiable, Hashable {
    let id: Int
    let title: String
    let imageName: String
    let duration: String
    let date: String
    let calories: String
    let tintColor: Color
}

//
//  GraphDataPoint.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import Foundation

struct GraphDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let mean: Double
    let stdDev: Double
}

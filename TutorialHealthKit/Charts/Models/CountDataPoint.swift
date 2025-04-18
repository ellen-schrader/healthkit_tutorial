//
//  CountDataPoint.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import Foundation


struct CountDataPoint : Identifiable{
    let id = UUID()
    let date: Date
    let count: Int
}

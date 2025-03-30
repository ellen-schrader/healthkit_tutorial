//
//  Activity.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import SwiftUI

struct Activity  : Identifiable, Hashable{
    let id: Int
    let title: String
    let subtitle: String
    let imageName: String
    let tintColor: Color
    let amount: String
    
}

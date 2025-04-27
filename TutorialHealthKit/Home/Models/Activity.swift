//
//  Activity.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import SwiftUI

enum ActivityStatistic: String, CaseIterable{
    case duration
    case calories
    case steps
    case mood
    
    func getMetric() -> String {
        switch self {
        case .duration:
            return "min"
        case .calories:
            return "kcal"
        case .steps:
            return ""
        case .mood :
            return ""
        }
    }
}

enum ActivityType {
    case sleep
    case exercise
    case metabolism
    case mentalHealth
}


struct Activity  : Identifiable, Hashable{
    let id: String
    let type: ActivityType
    let title: String
    let imageName: String
    let tintColor: Color
    let statistics: [ActivityStatistic : Double]
    
    func toString(statistic: ActivityStatistic) -> String{
        return "\(statistics[statistic]?.formattedNumberString() ?? "-") \(statistic.getMetric())"
    }
    
}

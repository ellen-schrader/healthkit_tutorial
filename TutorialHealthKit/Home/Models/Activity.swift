//
//  Activity.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import SwiftUI

enum ActivityStatistic: String, CaseIterable{
    case minutes
    case hours
    case calories
    case steps
    case mood
    case duration
    
    func getMetric() -> String {
        switch self {
        case .minutes:
            return "min"
        case .duration:
            return "min"
        case .hours:
            return "h"
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
    var statistics: [ActivityStatistic : Double]
    
    func toString(statistic: ActivityStatistic) -> String{
        return "\(statistics[statistic]?.formattedNumberString() ?? "-") \(statistic.getMetric())"
    }

    func updatingStatistic(_ statistic: ActivityStatistic, value: Double) -> Activity {
        var updatedStats = statistics
        updatedStats[statistic] = value
        
        return Activity(
            id: id,
            type: type,
            title: title,
            imageName: imageName,
            tintColor: tintColor,
            statistics: updatedStats
        )
    }
    
}

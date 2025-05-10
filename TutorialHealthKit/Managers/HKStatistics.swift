//
//  HKStatistics.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 27/04/2025.
//

import Foundation
import HealthKit


protocol HealthStatisticProcessor {
    func queryType() -> HKObjectType?
    func options() -> HKStatisticsOptions?
    func getUnit() -> HKUnit?
    func process(samples: [HKSample]) -> Double
    func processStatistics(_ statistics: HKStatistics?) -> Double
}

extension HealthStatisticProcessor {
    func processStatistics(_ statistics: HKStatistics?) -> Double {
        guard let statistics = statistics, let unit = getUnit() else { return 0 }
        
        switch options() {
        case .discreteAverage:
            return statistics.averageQuantity()?.doubleValue(for: unit) ?? 0
        case .cumulativeSum:
            return statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
        default:
            return 0
        }
    }
    
    func options() -> HKStatisticsOptions? { return nil }
}


enum HKStatistic: String, CaseIterable, HealthStatisticProcessor {
    case stepCount
    case caloriesBurned
    case standHours
    case exerciseTime
    case heartRate
    case mindfulMinutes
    case sleepDuration

    var unit: HKUnit? {
        switch self {
        case .stepCount: return .count()
        case .heartRate: return .count().unitDivided(by: .minute())
        case .caloriesBurned: return .kilocalorie()
        case .exerciseTime: return .minute()
        case .standHours: return .hour()
        case .mindfulMinutes: return .minute()
        case .sleepDuration: return .hour()
        }
    }

    var hkType: HKObjectType? {
        switch self {
        case .caloriesBurned: return HKQuantityType(.activeEnergyBurned)
        case .exerciseTime: return HKQuantityType(.appleExerciseTime)
        case .stepCount: return HKQuantityType(.stepCount)
        case .standHours: return HKCategoryType(.appleStandHour)
        case .heartRate: return HKQuantityType(.heartRate)
        case .mindfulMinutes: return HKCategoryType(.mindfulSession)
        case .sleepDuration: return HKCategoryType(.sleepAnalysis)
        }
    }
    
    func queryType() -> HKObjectType? {
           return hkType
    }
       
    func getUnit() -> HKUnit? {
           return unit
       }
       
   func options() -> HKStatisticsOptions? {
       switch self {
       case .stepCount, .caloriesBurned, .exerciseTime:
           return .cumulativeSum
       case .heartRate:
           return .discreteAverage
       default:
           return nil
       }
   }
       
   func process(samples: [HKSample]) -> Double {
       if let categorySamples = samples as? [HKCategorySample] {
           switch self {
           case .standHours:
               let calendar = Calendar.current
               let uniqueHours = Set(categorySamples.filter {
                   $0.value == HKCategoryValueAppleStandHour.stood.rawValue
               }.map {
                   calendar.dateComponents([.year, .month, .day, .hour], from: $0.startDate)
               })
               return Double(uniqueHours.count)
           case .mindfulMinutes:
               return categorySamples.reduce(0.0) { result, sample in
                   return result + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
               }
           case .sleepDuration:
               return categorySamples.reduce(0.0) { result, sample in
                   if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                      sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                      sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                      sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                       
                       let duration = sample.endDate.timeIntervalSince(sample.startDate)
                       return result + duration
                   }
                   return result
               } / 3600.0 // Convert seconds to hours
           default:
               return 0
           }
       }
       return 0
   }
}

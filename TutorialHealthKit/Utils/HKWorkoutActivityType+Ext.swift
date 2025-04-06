//
//  HKWorkoutActivityType+Ext.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 05/04/2025.
//

import SwiftUI
import HealthKit


extension HKWorkoutActivityType {
    
    var imageName: String {
            switch self {
            case .running: return "figure.run"
            case .walking: return "figure.walk"
            case .cycling: return "bicycle"
            case .swimming: return "figure.pool.swim"
            case .cooldown: return "figure.cooldown"
            case .yoga: return "figure.yoga"
            case .rowing: return "figure.indoor.rowing"
            case .elliptical: return "figure.elliptical"
            case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell"
            case .highIntensityIntervalTraining: return "flame"
            case .mindAndBody: return "brain.head.profile"
            case .dance, .danceInspiredTraining: return "figure.dance"
            case .hiking: return "figure.hiking"
            case .coreTraining: return "figure.core.training"
            case .stairs, .stairClimbing: return "stairs"
            case .wheelchairWalkPace, .wheelchairRunPace: return "figure.roll"
            case .pilates: return "figure.pilates"
            case .boxing: return "figure.boxing"
            case .kickboxing: return "figure.kickboxing"
            case .martialArts: return "figure.martial.arts"
            case .fishing: return "fish"
            case .golf: return "figure.golf"
            case .climbing: return "figure.climbing"
            case .equestrianSports: return "figure.equestrian.sports"
            case .snowboarding: return "figure.snowboarding"
            case .downhillSkiing, .crossCountrySkiing, .snowSports: return "figure.skiing.downhill"
            case .discSports: return "circle.grid.cross"
            case .jumpRope: return "figure.jump.rope"
            case .volleyball: return "figure.volleyball"
            case .soccer: return "figure.indoor.soccer"
            case .basketball: return "figure.basketball"
            case .baseball: return "figure.baseball"
            case .tennis : return "figure.tennis"
            case .tableTennis: return "figure.table.tennis"
            case .rugby: return "figure.rugby"
            case .handCycling: return "figure.hand.cycling"
            case .taiChi: return "figure.taichi"
            case .fitnessGaming: return "gamecontroller"
            default: return "questionmark"
            }
        }

    var color: Color {
            switch self {
            case .running: return .blue
            case .walking: return .green
            case .cycling: return .orange
            case .swimming: return .teal
            case .yoga: return .purple
            case .elliptical: return .indigo
            case .functionalStrengthTraining, .traditionalStrengthTraining: return .red
            case .highIntensityIntervalTraining: return .pink
            case .mindAndBody: return .mint
            case .dance, .danceInspiredTraining: return .pink
            case .hiking: return .brown
            case .coreTraining: return .gray
            case .stairs, .stairClimbing: return .gray
            case .wheelchairWalkPace, .wheelchairRunPace: return .blue
            case .rowing: return .cyan
            case .pilates: return .purple
            case .boxing, .kickboxing, .martialArts: return .red
            case .cooldown: return .orange
            case .fishing: return .blue
            case .golf: return .green
            case .climbing: return .brown
            case .equestrianSports: return .indigo
            case .snowboarding, .snowSports, .downhillSkiing, .crossCountrySkiing: return .cyan
            case .discSports: return .yellow
            case .jumpRope: return .pink
            case .volleyball: return .orange
            case .soccer: return .green
            case .basketball: return .orange
            case .baseball, .softball: return .blue
            case .tennis, .tableTennis: return .mint
            case .rugby: return .indigo
            case .handCycling: return .gray
            case .taiChi: return .teal
            case .fitnessGaming: return .purple
            default: return .gray
            }
        }

    var displayName: String {
        switch self {
        case .cooldown:                     return "Cooldown"
        case .americanFootball:             return "American Football"
        case .archery:                      return "Archery"
        case .australianFootball:           return "Australian Football"
        case .badminton:                    return "Badminton"
        case .baseball:                     return "Baseball"
        case .basketball:                   return "Basketball"
        case .bowling:                      return "Bowling"
        case .boxing:                       return "Boxing"
        case .climbing:                     return "Climbing"
        case .crossTraining:                return "Cross Training"
        case .curling:                      return "Curling"
        case .cycling:                      return "Cycling"
        case .dance:                        return "Dance"
        case .danceInspiredTraining:        return "Dance Inspired Training"
        case .elliptical:                   return "Elliptical"
        case .equestrianSports:             return "Equestrian Sports"
        case .fencing:                      return "Fencing"
        case .fishing:                      return "Fishing"
        case .functionalStrengthTraining:   return "Functional"
        case .golf:                         return "Golf"
        case .gymnastics:                   return "Gymnastics"
        case .handball:                     return "Handball"
        case .hiking:                       return "Hiking"
        case .hockey:                       return "Hockey"
        case .hunting:                      return "Hunting"
        case .lacrosse:                     return "Lacrosse"
        case .martialArts:                  return "Martial Arts"
        case .mindAndBody:                  return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports:                 return "Paddle Sports"
        case .play:                         return "Play"
        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "Racquetball"
        case .rowing:                       return "Rowing"
        case .rugby:                        return "Rugby"
        case .running:                      return "Running"
        case .sailing:                      return "Sailing"
        case .skatingSports:                return "Skating Sports"
        case .snowSports:                   return "Snow Sports"
        case .soccer:                       return "Soccer"
        case .softball:                     return "Softball"
        case .squash:                       return "Squash"
        case .stairClimbing:                return "Stair Climbing"
        case .surfingSports:                return "Surfing Sports"
        case .swimming:                     return "Swimming"
        case .tableTennis:                  return "Table Tennis"
        case .tennis:                       return "Tennis"
        case .trackAndField:                return "Track and Field"
        case .traditionalStrengthTraining:  return "Strength"
        case .volleyball:                   return "Volleyball"
        case .walking:                      return "Walking"
        case .waterFitness:                 return "Water Fitness"
        case .waterPolo:                    return "Water Polo"
        case .waterSports:                  return "Water Sports"
        case .wrestling:                    return "Wrestling"
        case .yoga:                         return "Yoga"

        // iOS 10
        case .barre:                        return "Barre"
        case .coreTraining:                 return "Core Training"
        case .crossCountrySkiing:           return "Cross Country Skiing"
        case .downhillSkiing:               return "Downhill Skiing"
        case .flexibility:                  return "Flexibility"
        case .highIntensityIntervalTraining:    return "High Intensity Interval Training"
        case .jumpRope:                     return "Jump Rope"
        case .kickboxing:                   return "Kickboxing"
        case .pilates:                      return "Pilates"
        case .snowboarding:                 return "Snowboarding"
        case .stairs:                       return "Stairs"
        case .stepTraining:                 return "Step Training"
        case .wheelchairWalkPace:           return "Wheelchair Walk Pace"
        case .wheelchairRunPace:            return "Wheelchair Run Pace"

        // iOS 11
        case .taiChi:                       return "Tai Chi"
        case .mixedCardio:                  return "Mixed Cardio"
        case .handCycling:                  return "Hand Cycling"

        // iOS 13
        case .discSports:                   return "Disc Sports"
        case .fitnessGaming:                return "Fitness Gaming"

        // Catch-all
        default:                            return "Other"
        }
    }

}

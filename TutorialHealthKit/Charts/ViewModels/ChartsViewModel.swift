//
//  ChartsViewModel.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import Foundation

enum ChartOptions: String, CaseIterable {
    case oneWeek = "W"
    case oneMonth = "M"
    case threeMonths = "3M"
    case oneYear = "Y"
    case allTime = "Max"
}

class ChartsViewModel: ObservableObject {
    @Published var mockDataDaily: [ChartOptions: [CountDataPoint]]
    @Published var mockDataMonthly: [ChartOptions: [GraphDataPoint]]
    
    @Published var averages: [ChartOptions: Double]
    @Published var totals: [ChartOptions: Int]
    
    private func computeMonthlyStats(from dailyData: [CountDataPoint]) -> [GraphDataPoint] {
            let calendar = Calendar.current
            let groupedByMonth = Dictionary(grouping: dailyData) { item in
                calendar.startOfMonth(for: item.date)
            }
            
            return groupedByMonth.map { date, values in
                let counts = values.map { Double($0.count) }
                let mean = counts.reduce(0, +) / Double(counts.count)
                let variance = counts.map { pow($0 - mean, 2) }.reduce(0, +) / Double(counts.count)
                let stdDev = sqrt(variance)
                
                return GraphDataPoint(date: date, mean: mean, stdDev: stdDev)
            }.sorted { $0.date < $1.date }
        }
    
    init(){
        mockDataDaily = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, []) })
        mockDataMonthly = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, []) })
        
        averages = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, 0.0) })
        totals = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, 0) })
        
        let mockDataMaxDaily = (0..<1024).map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let randomSteps = Int.random(in: 3000...12000)
            return CountDataPoint(date: date, count: randomSteps)
        }
        
        mockDataDaily[.oneWeek] = Array(mockDataMaxDaily.prefix(7))
        mockDataDaily[.oneMonth] = Array(mockDataMaxDaily.prefix(30))
        mockDataDaily[.threeMonths] = Array(mockDataMaxDaily.prefix(90))
        mockDataDaily[.oneYear] = Array(mockDataMaxDaily.prefix(365))
        mockDataDaily[.allTime] = mockDataMaxDaily
        
        
        mockDataMonthly[.threeMonths] = computeMonthlyStats(from: mockDataDaily[.threeMonths]!)
        mockDataMonthly[.oneYear] = computeMonthlyStats(from: mockDataDaily[.oneYear]!)
        mockDataMonthly[.allTime] = computeMonthlyStats(from: mockDataDaily[.allTime]!)
        
        totals[.oneWeek] = mockDataDaily[.oneWeek]!.map { $0.count }.reduce(0, +)
        totals[.oneMonth] = mockDataDaily[.oneMonth]!.map { $0.count }.reduce(0, +)
        totals[.threeMonths] = mockDataDaily[.threeMonths]!.map { $0.count }.reduce(0, +)
        totals[.oneYear] = mockDataDaily[.oneYear]!.map { $0.count }.reduce(0, +)
        totals[.allTime] = mockDataDaily[.allTime]!.map { $0.count }.reduce(0, +)
          
        averages[.oneWeek] = Double(totals[.oneWeek]!) / Double(mockDataDaily[.oneWeek]!.count)
        averages[.oneMonth] = Double(totals[.oneMonth]!) / Double(mockDataDaily[.oneMonth]!.count)
        averages[.threeMonths] = Double(totals[.threeMonths]!) / Double(mockDataDaily[.threeMonths]!.count)
        averages[.oneYear] = Double(totals[.oneYear]!) / Double(mockDataDaily[.oneYear]!.count)
        averages[.allTime] = Double(totals[.allTime]!) / Double(mockDataDaily[.allTime]!.count)
        }
}

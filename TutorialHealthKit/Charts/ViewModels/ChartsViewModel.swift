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

extension ChartOptions {
    var numberOfUnits: Int? {
        switch self {
        case .oneWeek:
            return 7
        case .oneMonth:
            return 31 //TODO: NOT HARDCODE?
        case .threeMonths:
            return 12
        case .oneYear:
            return 12
        case .allTime:
            return nil
        }
    }

    var timeUnit: TimeUnit? {
        switch self {
        case .oneWeek, .oneMonth:
            return .day
        case .threeMonths:
            return .week
        case .oneYear:
            return .month
        case .allTime:
            return .year
        }
    }
    
//    func startDate(from endDate: Date = Date()) -> Date? {
//        guard let unit = calendarComponent,
//              let value = numberOfUnits else { return nil }
//        return Calendar.current.date(byAdding: unit, value: -value, to: endDate)
//    }
}

class ChartsViewModel: ObservableObject {
    @Published var averages: [ChartOptions: Double]
    @Published var totals: [ChartOptions: Double]
    
    let healthManager = HealthManager.shared
    @Published var dataMonthly: [ChartOptions: [GraphDataPoint]]
    @Published var dataDaily: [ChartOptions: [CountDataPoint]]
    
    private func computeMonthlyStats(from dailyData: [CountDataPoint]) -> [GraphDataPoint] {
            let calendar = Calendar.current
            let groupedByMonth = Dictionary(grouping: dailyData) { item in
                calendar.startOfMonth(for: item.date)
            }
            
            return groupedByMonth.map { date, values in
                let counts = values.map { Double($0.count) }
                let value = counts.reduce(0, +) / Double(counts.count)
                let variance = counts.map { pow($0 - value, 2) }.reduce(0, +) / Double(counts.count)
                let stdDev = sqrt(variance)
                
                return GraphDataPoint(date: date, value: value, stdDev: stdDev, total: 0.0, daysInPeriod: 0)
            }.sorted { $0.date < $1.date }
        }
    
    init(){
        dataMonthly = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, []) })
        dataDaily = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, []) })
        averages = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, 0.0) })
        totals = Dictionary(uniqueKeysWithValues: ChartOptions.allCases.map { ($0, 0) })
        
        fetchStepsGraphChartData(chartOption: .oneYear)
        fetchStepsGraphChartData(chartOption: .threeMonths)
        fetchStepsGraphChartData(chartOption: .allTime)
        
        fetchStepsCountData(chartOption: .oneWeek)
        fetchStepsCountData(chartOption: .oneMonth)
        }
    
    func initMockData(){
        let mockDataMaxDaily = (0..<1024).map { daysAgo in
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
            let randomSteps = Int.random(in: 3000...12000)
            return CountDataPoint(date: date, count: randomSteps)
        }
        dataDaily[.oneWeek] = Array(mockDataMaxDaily.prefix(7))
        dataDaily[.oneMonth] = Array(mockDataMaxDaily.prefix(30))
        dataDaily[.threeMonths] = Array(mockDataMaxDaily.prefix(90))
        dataDaily[.oneYear] = Array(mockDataMaxDaily.prefix(365))
        dataDaily[.allTime] = mockDataMaxDaily
        
        
        
        totals[.oneWeek] = dataDaily[.oneWeek]!.map { Double($0.count) }.reduce(0, +)
        totals[.oneMonth] = dataDaily[.oneMonth]!.map { Double($0.count) }.reduce(0, +)
        totals[.threeMonths] = dataDaily[.threeMonths]!.map { Double($0.count) }.reduce(0, +)
        totals[.oneYear] = dataDaily[.oneYear]!.map {Double($0.count) }.reduce(0, +)
        totals[.allTime] = dataDaily[.allTime]!.map { Double($0.count) }.reduce(0, +)
          
        averages[.oneWeek] = Double(totals[.oneWeek]!) / Double(dataDaily[.oneWeek]!.count)
        averages[.oneMonth] = Double(totals[.oneMonth]!) / Double(dataDaily[.oneMonth]!.count)
        averages[.threeMonths] = Double(totals[.threeMonths]!) / Double(dataDaily[.threeMonths]!.count)
        averages[.oneYear] = Double(totals[.oneYear]!) / Double(dataDaily[.oneYear]!.count)
        averages[.allTime] = Double(totals[.allTime]!) / Double(dataDaily[.allTime]!.count)
        dataMonthly[.threeMonths] = computeMonthlyStats(from: dataDaily[.threeMonths]!)
        dataMonthly[.oneYear] = computeMonthlyStats(from: dataDaily[.oneYear]!)
        dataMonthly[.allTime] = computeMonthlyStats(from: dataDaily[.allTime]!)
    }
    
    func fetchStepsGraphChartData(chartOption: ChartOptions) {
        switch chartOption {
        case .allTime:
            healthManager.fetchAllTimeStepsData(timeUnit: chartOption.timeUnit ?? .month) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        self.dataMonthly[chartOption] = data
                        self.updateTotalsAndAverages(for: chartOption)
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            }
            
        default:
            healthManager.fetchStepsGraphChartData(count: chartOption.numberOfUnits ?? 0, timeUnit: chartOption.timeUnit ?? .month) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        self.dataMonthly[chartOption] = data
                        self.updateTotalsAndAverages(for: chartOption)
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                    DispatchQueue.main.async {
                        self.dataMonthly[chartOption] = []
                        self.totals[chartOption] = 0
                    }
                }
            }
        }
    }

    private func updateTotalsAndAverages(for chartOption: ChartOptions) {
        guard let data = self.dataMonthly[chartOption], !data.isEmpty else {
            self.totals[chartOption] = 0
            self.averages[chartOption] = 0
            return
        }
        let totalSteps = data.reduce(0.0, { $0 + $1.total})
        self.totals[chartOption] = totalSteps
        
        let totalDays = data.reduce(0, { $0 + $1.daysInPeriod })
        let average = totalDays > 0 ? Double(totalSteps) / Double(totalDays) : 0
        self.averages[chartOption] = average
        
        print("Updated for \(chartOption.rawValue): Total = \(totalSteps), Avg = \(Int(average))")
    }
    
    func fetchStepsCountData(chartOption : ChartOptions){
        switch chartOption {
            case .oneWeek, .oneMonth:
                healthManager.fetchDailyStepsData(count: chartOption.numberOfUnits ?? 0){result in
                    switch result {
                    case .success(let data):
                        DispatchQueue.main.async{
                            self.dataDaily[chartOption] = data
                            self.totals[chartOption] = data.reduce(0, {$0 + Double($1.count)})
                            self.averages[chartOption] = data.reduce(0.0, {$0 + Double($1.count)})/Double(data.count)
                        }
                    case .failure(let failure):
                        print(failure.localizedDescription)
                        self.dataDaily[chartOption] = []
                    }
                }
                
            default:
                self.dataDaily[chartOption] = []
            }
    }
}

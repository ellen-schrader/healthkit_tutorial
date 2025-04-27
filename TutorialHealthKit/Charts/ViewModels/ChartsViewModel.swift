//
//  ChartsViewModel.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import Foundation

enum StatKey: String, CaseIterable, Comparable {
    case averageDaily = "Average"
    case cumSum = "Total"
    case maxDaily = "Max"
    case minDaily = "Min"
    
    var displayOrder: Int {
        switch self {
        case .averageDaily: return 0
        case .cumSum: return 1
        case .maxDaily: return 2
        case .minDaily: return 3
        }
    }
    
    static func < (lhs: StatKey, rhs: StatKey) -> Bool {
        return lhs.displayOrder < rhs.displayOrder
    }
}

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
}


class ChartsViewModel: ObservableObject {
    @Published var dataDaily: [ChartOptions: [CountDataPoint]] = [:]
    @Published var dataMonthly: [ChartOptions: [GraphDataPoint]] = [:]
    @Published var stats: [ChartOptions: [StatKey: Double]] = [:]
    
    let healthManager = HealthManager.shared
    
    init() {
        initializeStats()
        fetchAllData()
    }

    func fetchAllData() {
        for option in ChartOptions.allCases {
            fetchStepsGraphChartData(chartOption: option)
            fetchStepsCountData(chartOption: option)
        }
    }
    
    private func initializeStats() {
        for option in ChartOptions.allCases {
            stats[option] = [
                .cumSum: 0,
                .averageDaily: 0,
                .maxDaily: 0,
                .minDaily: 0,
            ]
        }
    }
    
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
                
                return GraphDataPoint(date: date, value: value, stdDev: stdDev, cumSum: 0.0, minDaily: 0.0, maxDaily: 0.0, daysInPeriod: 0)
            }.sorted { $0.date < $1.date }
        }
    
    private func initMockData(){
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
        
        self.initializeStats()
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
                        self.updateStats(for: chartOption)
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            }
            
        case .threeMonths, .oneYear:
            healthManager.fetchStepsGraphChartData(count: chartOption.numberOfUnits ?? 0, timeUnit: chartOption.timeUnit ?? .month) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        self.dataMonthly[chartOption] = data
                        self.updateStats(for: chartOption)
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                    DispatchQueue.main.async {
                        self.dataMonthly[chartOption] = []
                        self.resetStats(for: chartOption)
                    }
                }
            }
        default:
            self.dataMonthly[chartOption] = []
            self.resetStats(for: chartOption)
        }
    }

    private func updateStats(for chartOption: ChartOptions) {
        guard let data = dataMonthly[chartOption], !data.isEmpty else {
            resetStats(for: chartOption)
            return
        }
        let totalSteps = data.reduce(0.0, {$0 + $1.cumSum})
        let totalDays = data.reduce(0, {$0 + $1.daysInPeriod})
        let averageDailySteps = totalDays > 0 ? Double(totalSteps) / Double(totalDays) : 0
        let dailyMeans = data.map{$0.value}
        let minDailySteps = data.min(by: {$0.minDaily < $1.minDaily})?.minDaily ?? 0
        let maxDailySteps = data.max(by: {$0.maxDaily < $1.maxDaily})?.maxDaily ?? 0
        
        stats[chartOption] = [
            .cumSum: Double(totalSteps),
            .averageDaily: averageDailySteps,
            .maxDaily: Double(maxDailySteps),
            .minDaily: Double(minDailySteps),
        ]
        print("Updated stats for \(chartOption.rawValue): Total = \(totalSteps), Avg = \(Int(averageDailySteps))")
    }

    private func resetStats(for chartOption: ChartOptions) {
        stats[chartOption] = [
            .cumSum: 0,
            .averageDaily: 0,
            .maxDaily: 0,
            .minDaily: 0
        ]
    }

    func getStat(for option: ChartOptions, key: StatKey) -> Double {
        return stats[option]?[key] ?? 0
    }
    
    func getAllStats(for option: ChartOptions) -> [StatKey: Double] {
        return stats[option] ?? [:]
    }
    
    func fetchStepsCountData(chartOption : ChartOptions){
        switch chartOption {
            case .oneWeek, .oneMonth:
                healthManager.fetchDailyStepsData(count: chartOption.numberOfUnits ?? 0){result in
                    switch result {
                    case .success(let data):
                        DispatchQueue.main.async{
                            self.dataDaily[chartOption] = data
                            self.stats[chartOption]?[.cumSum] = data.reduce(0, {$0 + Double($1.count)})
                            self.stats[chartOption]?[.averageDaily] = data.reduce(0.0, {$0 + Double($1.count)})/Double(data.count)
                            self.stats[chartOption]?[.maxDaily] = Double(data.max(by: {$0.count < $1.count})?.count ?? 0)
                            self.stats[chartOption]?[.minDaily] = Double(data.min(by: {$0.count < $1.count})?.count ?? 0)
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

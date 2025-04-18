//
//  GraphView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//
import SwiftUI
import Charts

struct CountBarView: View {
    var data: [CountDataPoint]
    var timeUnit: Calendar.Component = .day // default to .day
    var goal: Int = 0
    
    var body: some View {
        ZStack {
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: timeUnit),
                        y: .value("Mean", item.count)
                    )
                    .foregroundStyle(item.count > goal ? .green : .gray)
                }
            }
        }
    }
}


#Preview {
    let mockData: [CountDataPoint] = (0..<6).map {
        CountDataPoint(
            date: Calendar.current.date(byAdding: .month, value: $0, to: Date())!,
            count: Int.random(in: 5000...10000)
        )
    }
    return CountBarView(data: mockData, timeUnit: .month, goal: 7000)
}

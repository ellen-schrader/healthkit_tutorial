//
//  GraphView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//
import SwiftUI
import Charts

struct MeanStdGraphView: View {
    var data: [GraphDataPoint]
    var timeUnit: TimeUnit = .day // default to .day
    
    var body: some View {
        ZStack {
            Chart {
                ForEach(data) { item in
                    AreaMark(
                        x: .value("Date", item.date, unit: timeUnit.calendarComponent),
                        yStart: .value("Lower Bound", item.value - item.stdDev),
                        yEnd: .value("Upper Bound", item.value + item.stdDev)
                    )
                    .foregroundStyle(.green.opacity(0.2))

                    LineMark(
                        x: .value("Date", item.date, unit: timeUnit.calendarComponent),
                        y: .value("Mean", item.value)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date, unit: timeUnit.calendarComponent),
                        y: .value("Mean", item.value)
                    )
                    .symbol(Circle())
                    .foregroundStyle(.green)
                }
            }
        }
    }
}


#Preview {
    let mockData: [GraphDataPoint] = (0..<6).map {
        GraphDataPoint(
            date: Calendar.current.date(byAdding: .month, value: $0, to: Date())!,
            value: Double.random(in: 5000...8000),
            stdDev: Double.random(in: 300...800),
            total: Double.random(in: 5000...8000),
            daysInPeriod: Int.random(in: 20...30)
        )
    }

    return MeanStdGraphView(data: mockData, timeUnit: .month)
}

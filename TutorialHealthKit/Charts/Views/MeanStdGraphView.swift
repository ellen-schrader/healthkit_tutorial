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
    var timeUnit: Calendar.Component = .day // default to .day
    
    var body: some View {
        ZStack {
            Chart {
                ForEach(data) { item in
                    AreaMark(
                        x: .value("Date", item.date, unit: timeUnit),
                        yStart: .value("Lower Bound", item.mean - item.stdDev),
                        yEnd: .value("Upper Bound", item.mean + item.stdDev)
                    )
                    .foregroundStyle(.green.opacity(0.2))

                    LineMark(
                        x: .value("Date", item.date, unit: timeUnit),
                        y: .value("Mean", item.mean)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", item.date, unit: timeUnit),
                        y: .value("Mean", item.mean)
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
            mean: Double.random(in: 5000...8000),
            stdDev: Double.random(in: 300...800)
        )
    }

    return MeanStdGraphView(data: mockData, timeUnit: .month)
}

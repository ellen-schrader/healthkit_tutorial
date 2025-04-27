//
//  BarChart.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 19/04/2025.
//

import SwiftUI
import Charts

struct BarChartItem: Identifiable {
    let id: Int
    let name: String
    let size: Double
    let color: Color
}

struct ProportionBarChart: View {
    var data: [BarChartItem]
    var total: String = ""
    var goal: String = ""
    var title: String = ""
    var body: some View {
        VStack{
            HStack{
                Text(title)
                Spacer()
                Text("\(total) / \(goal)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Chart {
                ForEach(data.sorted(by: { $0.id < $1.id })) { category in
                    BarMark(
                        x: .value("Size", category.size),
                        stacking: .center
                    )
                    .foregroundStyle(category.color)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .frame(height: 30)
            .cornerRadius(16)
        }
    }
}

#Preview {
    let activityData: [BarChartItem] = [
        .init(id: 0, name: "Cardio", size: 0.3, color: .blue),
        .init(id: 1,  name: "Strength", size: 0.4, color: .red),
        .init(id: 2, name: "Mobility", size: 0.1, color: .orange),
        .init(id: 3, name: "Missing", size: 0.2, color:  .gray.opacity(0.2))
    ]

    ProportionBarChart(data: activityData, total: "180min", goal: "240min", title: "Exercise Time")
}

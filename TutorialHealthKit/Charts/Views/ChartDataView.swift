//
//  ChartDataView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import SwiftUI

struct ChartDataView: View {
    var stats: [StatKey: Double]
    var displayKeys: [StatKey] = [.averageDaily, .maxDaily, .cumSum]
    private let columns = 3
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            ForEach(displayKeys, id: \.self) { key in
                if let value = stats[key] {
                    StatCardView(title: key.rawValue, value: Double(value).formattedNumberString())
                }
            }
        }
        .padding(.horizontal)
    }
}

struct StatCardView: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title2)
                    .bold()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

// Preview with sample data
#Preview {
    ChartDataView(stats: [
        .cumSum: 1254367,
        .averageDaily: 8765.3,
        .maxDaily: 12543,
        .minDaily: 4321
    ])
}

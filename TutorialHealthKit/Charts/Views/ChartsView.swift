//
//  HistoricDataView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 29/03/2025.
//

import SwiftUI
import Charts

struct ChartsView: View {
    @ObservedObject var viewModel = ChartsViewModel()
    @State var selectedOption: ChartOptions = .oneWeek
    @State var goal: Int = 10000
    
    var body: some View {
        VStack {
            Text("Steps")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            ChartDataView(stats: viewModel.getAllStats(for: selectedOption))
            .padding(.bottom)
            
            TabView(selection: $selectedOption) {
                ForEach(ChartOptions.allCases, id: \.self) { option in
                    VStack {
                        ZStack {
                            switch option {
                            case .oneWeek, .oneMonth:
                                CountBarView(data: viewModel.dataDaily[option] ?? [],
                                             timeUnit: option.timeUnit ?? .day,
                                             goal: goal)
                                .padding(.top)
                            case .threeMonths, .oneYear, .allTime:
                                MeanStdGraphView(data: viewModel.dataMonthly[option] ?? [],
                                               timeUnit: option.timeUnit ?? .month)
                                .padding(.top)
                            }
                        }
                    }
                    .tag(option)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: 300)
            
            // Option indicators
            HStack {
                ForEach(ChartOptions.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        withAnimation {
                            selectedOption = option
                        }
                    }
                    .padding()
                    .foregroundColor(.secondary)
                    .background(selectedOption == option ? .green.opacity(0.6) : .clear)
                    .cornerRadius(10)
                }
            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
    }
}

#Preview {
    ChartsView()
}

#Preview {
    ChartsView()
}


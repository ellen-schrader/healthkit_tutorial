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
        VStack{
            Text("Charts")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            ChartDataView(average: viewModel.averages[selectedOption] ?? 0,
                          total: viewModel.totals[selectedOption] ?? 0)
            
            ZStack{
                switch selectedOption {
                    case .oneWeek:
                    CountBarView(data: viewModel.mockDataDaily[.oneWeek] ?? [], timeUnit: .day, goal: goal)
                    
                case .oneMonth:
                    CountBarView(data: viewModel.mockDataDaily[.oneMonth] ?? [], timeUnit: .day, goal: goal)
                    
                case .threeMonths:
                    CountBarView(data: viewModel.mockDataDaily[.threeMonths] ?? [], timeUnit: .day, goal: goal)
                    
                case .oneYear:
                    MeanStdGraphView(data: viewModel.mockDataMonthly[.oneYear] ?? [],
                                     timeUnit: .month)
                case .allTime:
                    MeanStdGraphView(data: viewModel.mockDataMonthly[.allTime] ?? [],
                                     timeUnit: .month)
                }
            }
            .frame(maxHeight: 350)
            .padding(.horizontal)
            
            HStack{
                ForEach(ChartOptions.allCases, id: \.self){ option in
                    Button(option.rawValue){
                        withAnimation{
                            selectedOption = option
                        }
                    }
                    .padding()
                    .foregroundColor(.secondary)
                    .background(selectedOption == option ? .green.opacity(0.6) :.clear)
                    .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    ChartsView()
}

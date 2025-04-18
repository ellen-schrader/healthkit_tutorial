//
//  ChartDataView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 18/04/2025.
//

import SwiftUI
import Charts

struct ChartDataView: View {
    var average: Double
    var total: Int
    var body: some View {
        HStack{
            Spacer()
            VStack(alignment: .leading, spacing: 16){
                Text("Average")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Text(average.formattedNumberString())
                    .font(.title2)
                    .bold()
                   
            }
            .padding()
            .frame(width:140)
            .background(.gray.opacity(0.2))
            .cornerRadius(10)
            
            Spacer()
            
            VStack(alignment:.leading, spacing: 16){
                Text("Total")
                    .foregroundColor(.secondary)
                    .font(.title3)
                Text("\(total)")
                    .font(.title2)
                    .bold()
            }
            .padding()
            .frame(width:140)
            .background(.gray.opacity(0.2))
            .cornerRadius(10)
            Spacer()
        }.padding(.horizontal)
    }
}

#Preview {
    ChartDataView(average: 7654.32145, total: 204567)
}

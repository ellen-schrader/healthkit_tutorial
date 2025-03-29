//
//  ProgressCircleView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 29/03/2025.
//

import SwiftUI

struct ProgressCircleView: View {
    @Binding var progress: Int
    var color: Color
    var goal: Int
    private let width: CGFloat = 20.0
    
    var body: some View {
        ZStack{
            Circle()
                .stroke(color.opacity(0.3), lineWidth:width)
            
            Circle()
                .trim(from : 0, to : CGFloat(progress)/CGFloat(goal))
                .stroke(color, style : StrokeStyle(lineWidth : width, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(radius:5)
                
        }
        .padding()
    }
}

#Preview {
    ProgressCircleView(progress: .constant(50), color: .green, goal: 100)
}

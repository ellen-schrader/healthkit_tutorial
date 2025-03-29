//
//  HomeView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 29/03/2025.
//

import SwiftUI

struct HomeView: View {
    @State var calories: Int = 123
    @State var activity: Int = 45
    @State var stand: Int = 12
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                Text("Welcome")
                    .font(.largeTitle)
                    .padding()
                HStack{
                    
                    Spacer()
                    
                    VStack{
                        VStack(alignment: .leading, spacing: 8){
                            Text("Calories")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.red)
                            Text("\(calories) kcal")
                                .bold()
                        }
                        .padding(.bottom)
                        
                        VStack(alignment: .leading, spacing: 8){
                            Text("Active")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.green)
                            Text("\(activity) mins")
                                .bold()
                        }
                        .padding(.bottom)
                        
                        VStack(alignment: .leading, spacing: 8){
                            Text("Stand")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.blue)
                            Text("\(stand) hours")
                                .bold()
                        }
                        
                    }
                    
                    Spacer()
                    
                    
                    ZStack{
                        ProgressCircleView(progress: $calories, color: .red, goal: 600)
                        ProgressCircleView(progress: $activity, color: .green, goal: 60)
                            .padding(.all, 20)
                        ProgressCircleView(progress: $stand, color: .blue, goal: 8)
                            .padding(.all, 40)
                    }
                    .padding(.horizontal)
                   
                    Spacer()
                }
                .padding()
            }
            
        }
    }
}

#Preview {
    HomeView()
}

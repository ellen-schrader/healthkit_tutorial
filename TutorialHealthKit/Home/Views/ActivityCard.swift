//
//  ActivityCard.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//

import SwiftUI

struct ActivityCard: View {
    @State var activity: Activity
    var body: some View {
        ZStack{
            Color(uiColor: .systemGray6)
                .cornerRadius(15)
            VStack{
                HStack(alignment: .top){
                    VStack(alignment: .leading, spacing: 8){
                        Text(activity.title)
                        
                        Text(activity.subtitle)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: activity.imageName)
                        .foregroundColor(activity.tintColor)
                }

                
                Text(activity.amount)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                    
            }
            .padding()
        }
    }
}

#Preview {
    let activity = Activity(id: 0, title: "Today steps", subtitle: "Goal 10,000", imageName: "figure.walk", tintColor: .green, amount: "1,234")
    return ActivityCard(activity: activity)
}

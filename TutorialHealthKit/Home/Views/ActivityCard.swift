//
//  ActivityCard.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 30/03/2025.
//
import SwiftUI

struct ActivityCard: View {
    @State var activity: Activity
    var clickable: Bool = false
    var subtitle: String = ""
    var statistic: ActivityStatistic = .duration
    var body: some View {
        ZStack {
            Color(uiColor: .systemGray6)
                .cornerRadius(15)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
            
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.title)
                            .fontWeight(.medium)
                        
                        Text(subtitle)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: activity.imageName)
                        .foregroundColor(activity.tintColor)
                }
                Text(activity.toString(statistic:  statistic))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.vertical, 12)
                
                if clickable {
                    HStack {
                        Spacer()
                        Label("", systemImage: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }.padding()
        }
    }
}

#Preview {
    let activity = Activity(id: "0", type: .exercise, title: "Steps", imageName: "figure.walk", tintColor: .green, statistics: [.steps:  12345, .calories: 600, .duration: 300])
    return ActivityCard(activity: activity,
                        clickable: true,
                        subtitle: "Goal: \(10000.0.formattedNumberString())",
                        statistic: .calories)
}

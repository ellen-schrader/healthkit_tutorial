//
//  TabView.swift
//  TutorialHealthKit
//
//  Created by Ellen Schrader on 29/03/2025.
//

import SwiftUI

struct FitnessTabView: View {
    @State var selectedTab = "Home"
    
    init(){
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.stackedLayoutAppearance.selected.iconColor = .systemGreen
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemGreen]
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some View {
        TabView(selection: $selectedTab){
        HomeView()
                .tag("Home")
                .tabItem{
                    Image(systemName: "house")
                    Text("Home")
                }
        HistoricDataView()
                .tag("Historic")
                .tabItem{
                    Image(systemName: "chart.xyaxis.line")
                    Text("Data")
                }
        }
    }
}

#Preview {
    FitnessTabView()
}

//
//  ContentView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(KMTheme.self) var theme
    @Environment(KMState.self) private var state
    @State private var isShowingOnboarding: Bool = false
    @State private var isShowingAddDashboardSheet: Bool = false

    var body: some View {
        ZStack {
            background
                .zIndex(0)

            content
                .zIndex(1)
        }
        .onAppear {
            if KMCore.isKomariDashboardConfigured {
                state.loadDashboard()
            } else {
                isShowingOnboarding = true
            }
        }
    }

    private var background: some View {
        theme.themeBackgroundColor(scheme: scheme)
            .ignoresSafeArea()
    }

    private var content: some View {
        Group {
            if isShowingOnboarding {
                VStack {
                    Text("Start your journey with Komari Mobile")
                        .font(.title3)
                        .frame(alignment: .center)
                    Button("Start", systemImage: "arrow.right.circle") {
                        isShowingAddDashboardSheet = true
                    }
                    .font(.headline)
                    .padding(.top, 20)
                    .sheet(isPresented: $isShowingAddDashboardSheet) {
                        AddDashboardView(isShowingOnboarding: $isShowingOnboarding)
                    }
                }
                .padding()
            } else {
                HomeView()
            }
        }
    }
}

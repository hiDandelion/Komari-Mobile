//
//  AcknowledgmentView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct AcknowledgmentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("This project is subject to\nApache License\nVersion 2.0, January 2004\nhttps://www.apache.org/licenses/")
                Text("Part of this project is related to Project komari-monitor/komari which is subject to\nMIT License")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
        .padding()
    }
}

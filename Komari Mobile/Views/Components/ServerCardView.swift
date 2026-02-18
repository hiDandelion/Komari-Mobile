//
//  ServerCardView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ServerCardView: View {
    let node: NodeData
    let status: NodeLiveStatus?
    let isOnline: Bool

    var body: some View {
        ServerCard(node: node, status: status, isOnline: isOnline)
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                    .shadow(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
            )
    }
}

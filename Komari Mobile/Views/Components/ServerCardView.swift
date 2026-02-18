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
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
    }
}

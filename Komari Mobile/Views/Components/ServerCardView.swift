//
//  ServerCardView.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
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
            )
    }
}

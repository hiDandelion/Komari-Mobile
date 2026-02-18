//
//  ServerTitle.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ServerTitle: View {
    let node: NodeData
    let isOnline: Bool

    var body: some View {
        HStack {
            CountryFlag(countryFlag: node.region)

            Text(node.name)
                .fontWeight(.bold)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text(isOnline ? String(localized: "Online") : String(localized: "Offline"))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isOnline ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isOnline ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                )
        }
    }
}

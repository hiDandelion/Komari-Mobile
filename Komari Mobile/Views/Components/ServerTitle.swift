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

            Image(systemName: "circlebadge.fill")
                .foregroundStyle(isOnline ? .green : .red)
        }
    }
}

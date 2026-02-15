//
//  PieceOfInfo.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct PieceOfInfo<Content: View>: View {
    let systemImage: String?
    let name: LocalizedStringKey
    let content: Content

    init(systemImage: String? = nil, name: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.systemImage = systemImage
        self.name = name
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                if let systemImage {
                    Label(name, systemImage: systemImage)
                } else {
                    Text(name)
                }

                Spacer()

                content
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading) {
                if let systemImage {
                    Label(name, systemImage: systemImage)
                } else {
                    Text(name)
                }

                content
                    .foregroundStyle(.secondary)
            }
        }
    }
}

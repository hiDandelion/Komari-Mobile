//
//  CopiableModifier.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct CopiableModifier: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "document.on.document")
                }
            }
    }
}

extension View {
    func copiable(_ text: String) -> some View {
        modifier(CopiableModifier(text: text))
    }
}

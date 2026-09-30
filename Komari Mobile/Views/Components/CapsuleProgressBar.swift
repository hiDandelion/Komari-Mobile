//
//  CapsuleProgressBar.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 9/30/26.
//

import SwiftUI

/// Horizontal capsule-shaped progress bar; size it with `.frame(height:)`.
///
/// The fill is a capsule at least as wide as the bar is tall, shifted left so its trailing edge
/// marks the value, and clipped to the track. Very low values therefore show a thin sliver that
/// follows the track's rounded end, instead of a squashed capsule sticking out of it.
struct CapsuleProgressBar<Fill: ShapeStyle>: View {
    /// Percent (0–100)
    let value: Double
    let fill: Fill
    var track: Color = Color(UIColor.systemGray5)

    private var fraction: Double {
        min(max(value, 0), 100) / 100
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * fraction
            let fillWidth = max(width, proxy.size.height)
            Capsule()
                .fill(fill)
                .frame(width: fillWidth, height: proxy.size.height)
                .offset(x: width - fillWidth)
        }
        .background(Capsule().fill(track))
        .clipShape(Capsule())
    }
}

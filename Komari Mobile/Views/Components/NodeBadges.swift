//
//  NodeBadges.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import SwiftUI

// MARK: - Billing Helpers

enum NodeBilling {
    /// Billing cycle label derived from the cycle length in days, matching komari-web semantics
    static func cycleLabel(days: Int) -> String {
        switch days {
        case 27...32: String(localized: "Monthly")
        case 87...95: String(localized: "Quarterly")
        case 175...185: String(localized: "Semi-Annual")
        case 360...370: String(localized: "Annual")
        case 720...750: String(localized: "Biennial")
        case 1080...1150: String(localized: "Triennial")
        case 1800...1850: String(localized: "Quinquennial")
        case -1: String(localized: "One-Time")
        default: String(localized: "\(days) Day(s)")
        }
    }

    static func priceLabel(price: Double, currency: String?, billingCycle: Int?) -> String {
        let amount: String
        if price == -1 {
            amount = String(localized: "Free")
        } else {
            let number = price.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(price))
                : String(format: "%.2f", price)
            amount = "\(currency ?? "$")\(number)"
        }
        guard let billingCycle else { return amount }
        return "\(amount)/\(cycleLabel(days: billingCycle))"
    }

    /// Days until expiry, rounded up. `nil` when the date is absent, unparsable,
    /// or a zero-date placeholder like 0001-01-01.
    static func daysUntilExpiry(_ isoDate: String?) -> Int? {
        guard let isoDate, !isoDate.isEmpty,
              let date = ServerDetailMonitorView.parseDate(isoDate),
              Calendar.current.component(.year, from: date) >= 3 else { return nil }
        return Int(ceil(date.timeIntervalSinceNow / 86400))
    }

    static func expiryLabel(daysLeft: Int) -> String {
        if daysLeft <= 0 {
            return String(localized: "Expired")
        } else if daysLeft > 36500 {
            return String(localized: "Long-Term")
        } else {
            return String(localized: "\(daysLeft)d left")
        }
    }

    static func expiryColor(daysLeft: Int) -> Color {
        if daysLeft <= 7 { return .red }
        if daysLeft <= 15 { return .orange }
        return .green
    }

    /// Traffic usage percentage against the configured limit, matching komari-web semantics
    static func trafficPercentage(totalUp: Int64, totalDown: Int64, limit: Int64, type: String?) -> Double {
        guard limit > 0 else { return 0 }
        let used: Int64 = switch type ?? "sum" {
        case "max": max(totalUp, totalDown)
        case "min": min(totalUp, totalDown)
        case "up": totalUp
        case "down": totalDown
        default: totalUp + totalDown
        }
        return Double(used) / Double(limit) * 100
    }

    static func trafficTypeLabel(_ type: String?) -> String {
        switch type ?? "sum" {
        case "max": String(localized: "Max")
        case "min": String(localized: "Min")
        case "up": String(localized: "Upload")
        case "down": String(localized: "Download")
        default: String(localized: "Sum")
        }
    }
}

// MARK: - Custom Tags

struct NodeTag: Identifiable {
    let index: Int
    let text: String
    let color: Color

    var id: Int { index }

    private static let namedColors: [String: Color] = [
        "ruby": .red, "gray": .gray, "gold": .yellow, "bronze": .brown, "brown": .brown,
        "yellow": .yellow, "amber": .orange, "orange": .orange, "tomato": .red, "red": .red,
        "crimson": .pink, "pink": .pink, "plum": .purple, "purple": .purple, "violet": .purple,
        "iris": .indigo, "indigo": .indigo, "blue": .blue, "cyan": .cyan, "teal": .teal,
        "jade": .mint, "green": .green, "grass": .green, "lime": .green, "mint": .mint, "sky": .cyan
    ]

    private static let palette: [Color] = [
        .red, .gray, .yellow, .brown, .orange, .pink, .purple, .indigo, .blue, .cyan, .teal, .mint, .green
    ]

    /// Parse a `;`-separated tag string where each tag may carry a `<color>` suffix
    static func parse(_ tags: String?) -> [NodeTag] {
        guard let tags, !tags.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return tags.split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, tag in
                if let match = tag.wholeMatch(of: #/(?<text>.*)<(?<color>\w+)>/#),
                   let color = namedColors[String(match.output.color).lowercased()] {
                    return NodeTag(index: index, text: String(match.output.text), color: color)
                }
                return NodeTag(index: index, text: tag, color: palette[index % palette.count])
            }
    }
}

// MARK: - Badge

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .lineLimit(1)
    }
}

// MARK: - Node Badges (price, expiry, custom tags)

struct NodeBadgesView: View {
    let node: NodeData

    static func hasContent(node: NodeData) -> Bool {
        let hasPrice = (node.price ?? 0) != 0
        let hasExpiry = NodeBilling.daysUntilExpiry(node.expiredAt) != nil
        let hasTags = !NodeTag.parse(node.tags).isEmpty
        return hasPrice || hasExpiry || hasTags
    }

    var body: some View {
        FlowLayout(spacing: 5) {
            if let price = node.price, price != 0 {
                BadgeView(
                    text: NodeBilling.priceLabel(price: price, currency: node.currency, billingCycle: node.billingCycle),
                    color: .indigo
                )
            }
            if let daysLeft = NodeBilling.daysUntilExpiry(node.expiredAt) {
                BadgeView(
                    text: NodeBilling.expiryLabel(daysLeft: daysLeft),
                    color: NodeBilling.expiryColor(daysLeft: daysLeft)
                )
            }
            ForEach(NodeTag.parse(node.tags)) { tag in
                BadgeView(text: tag.text, color: tag.color)
            }
        }
    }
}

// MARK: - Traffic Limit Bar

struct TrafficLimitBar: View {
    let totalUp: Int64
    let totalDown: Int64
    let limit: Int64
    let type: String?

    private var percentage: Double {
        NodeBilling.trafficPercentage(totalUp: totalUp, totalDown: totalDown, limit: limit, type: type)
    }

    private var barColor: Color {
        if percentage >= 80 { return .red }
        if percentage >= 60 { return .orange }
        return .green
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Traffic")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .contentTransition(.numericText(value: percentage))
            }
            CapsuleProgressBar(value: percentage, fill: barColor)
                .frame(height: 8)
                .animation(.smooth(duration: 0.5), value: percentage)
            HStack {
                Text(NodeBilling.trafficTypeLabel(type))
                Spacer()
                Text(formatBytes(limit))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Flow Layout

/// Wraps subviews onto new lines when they exceed the proposed width
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + spacing + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            if x > 0 { x += spacing }
            x += size.width
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + spacing + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            if x > 0 { x += spacing }
            subview.place(
                at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )
            x += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }
}

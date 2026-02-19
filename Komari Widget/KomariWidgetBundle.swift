//
//  KomariWidgetBundle.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import WidgetKit
import SwiftUI

@main
struct KomariWidgetBundle: WidgetBundle {
    var body: some Widget {
        ServerStatusWidget()
        LoadChartWidget()
        PingChartWidget()
    }
}

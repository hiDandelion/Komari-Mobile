//
//  KomariWidgetBundle.swift
//  Komari Widget
//
//  Created by Takuma Kirishima on 2/19/26.
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

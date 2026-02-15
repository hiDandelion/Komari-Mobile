//
//  TextWithColorfulIcon.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct TextWithColorfulIcon: View {
    let titleKey: LocalizedStringKey
    let systemName: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(Color.white)
                .padding(5)
                .background(color)
                .cornerRadius(7)
            Text(titleKey)
        }
    }
}

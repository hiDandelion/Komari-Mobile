//
//  KMTheme.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

@Observable
class KMTheme {
    static let KMThemePrimaryColorLight = "KMThemePrimaryColorLight"
    static let KMThemeSecondaryColorLight = "KMThemeSecondaryColorLight"
    static let KMThemeBackgroundColorLight = "KMThemeBackgroundColorLight"
    static let KMThemeActiveColorLight = "KMThemeActiveColorLight"
    static let KMThemeTintColorLight = "KMThemeTintColorLight"
    static let KMThemePrimaryColorDark = "KMThemePrimaryColorDark"
    static let KMThemeSecondaryColorDark = "KMThemeSecondaryColorDark"
    static let KMThemeBackgroundColorDark = "KMThemeBackgroundColorDark"
    static let KMThemeActiveColorDark = "KMThemeActiveColorDark"
    static let KMThemeTintColorDark = "KMThemeTintColorDark"

    var themePrimaryColorLight: Color {
        didSet {
            KMCore.userDefaults.set(themePrimaryColorLight.base64EncodedString, forKey: KMTheme.KMThemePrimaryColorLight)
        }
    }
    var themeSecondaryColorLight: Color {
        didSet {
            KMCore.userDefaults.set(themeSecondaryColorLight.base64EncodedString, forKey: KMTheme.KMThemeSecondaryColorLight)
        }
    }
    var themeBackgroundColorLight: Color {
        didSet {
            KMCore.userDefaults.set(themeBackgroundColorLight.rawValue, forKey: KMTheme.KMThemeBackgroundColorLight)
        }
    }
    var themeActiveColorLight: Color {
        didSet {
            KMCore.userDefaults.set(themeActiveColorLight.base64EncodedString, forKey: KMTheme.KMThemeActiveColorLight)
        }
    }
    var themeTintColorLight: Color {
        didSet {
            KMCore.userDefaults.set(themeTintColorLight.base64EncodedString, forKey: KMTheme.KMThemeTintColorLight)
        }
    }
    var themePrimaryColorDark: Color {
        didSet {
            KMCore.userDefaults.set(themePrimaryColorDark.base64EncodedString, forKey: KMTheme.KMThemePrimaryColorDark)
        }
    }
    var themeSecondaryColorDark: Color {
        didSet {
            KMCore.userDefaults.set(themeSecondaryColorDark.base64EncodedString, forKey: KMTheme.KMThemeSecondaryColorDark)
        }
    }
    var themeBackgroundColorDark: Color {
        didSet {
            KMCore.userDefaults.set(themeBackgroundColorDark.rawValue, forKey: KMTheme.KMThemeBackgroundColorDark)
        }
    }
    var themeActiveColorDark: Color {
        didSet {
            KMCore.userDefaults.set(themeActiveColorDark.base64EncodedString, forKey: KMTheme.KMThemeActiveColorDark)
        }
    }
    var themeTintColorDark: Color {
        didSet {
            KMCore.userDefaults.set(themeTintColorDark.base64EncodedString, forKey: KMTheme.KMThemeTintColorDark)
        }
    }

    init() {
        if
            let themePrimaryColorLightString = KMCore.userDefaults.string(forKey: KMTheme.KMThemePrimaryColorLight),
            let themeSecondaryColorLightString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeSecondaryColorLight),
            let themeBackgroundColorLightString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeBackgroundColorLight),
            let themeActiveColorLightString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeActiveColorLight),
            let themeTintColorLightString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeTintColorLight),
            let themePrimaryColorDarkString = KMCore.userDefaults.string(forKey: KMTheme.KMThemePrimaryColorDark),
            let themeSecondaryColorDarkString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeSecondaryColorDark),
            let themeBackgroundColorDarkString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeBackgroundColorDark),
            let themeActiveColorDarkString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeActiveColorDark),
            let themeTintColorDarkString = KMCore.userDefaults.string(forKey: KMTheme.KMThemeTintColorDark)
        {
            themePrimaryColorLight = Color(base64EncodedString: themePrimaryColorLightString) ?? Color.black
            themeSecondaryColorLight = Color(base64EncodedString: themeSecondaryColorLightString) ?? Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.5)
            themeBackgroundColorLight = Color(base64EncodedString: themeBackgroundColorLightString) ?? Color(red: 140/255, green: 196/255, blue: 246/255)
            themeActiveColorLight = Color(base64EncodedString: themeActiveColorLightString) ?? Color.white
            themeTintColorLight = Color(base64EncodedString: themeTintColorLightString) ?? Color.blue
            themePrimaryColorDark = Color(base64EncodedString: themePrimaryColorDarkString) ?? Color.white
            themeSecondaryColorDark = Color(base64EncodedString: themeSecondaryColorDarkString) ?? Color(red: 28/255, green: 28/255, blue: 28/255, opacity: 0.5)
            themeBackgroundColorDark = Color(base64EncodedString: themeBackgroundColorDarkString) ?? Color.black
            themeActiveColorDark = Color(base64EncodedString: themeActiveColorDarkString) ?? Color.white
            themeTintColorDark = Color(base64EncodedString: themeTintColorDarkString) ?? Color.blue
        }
        else {
            themePrimaryColorLight = Color.black
            themeSecondaryColorLight = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.5)
            themeBackgroundColorLight = Color(red: 140/255, green: 196/255, blue: 246/255)
            themeActiveColorLight = Color.white
            themeTintColorLight = Color.blue
            themePrimaryColorDark = Color.white
            themeSecondaryColorDark = Color(red: 28/255, green: 28/255, blue: 28/255, opacity: 0.5)
            themeBackgroundColorDark = Color.black
            themeActiveColorDark = Color.white
            themeTintColorDark = Color.blue

            KMCore.userDefaults.set(themePrimaryColorLight.base64EncodedString, forKey: KMTheme.KMThemePrimaryColorLight)
            KMCore.userDefaults.set(themeSecondaryColorLight.base64EncodedString, forKey: KMTheme.KMThemeSecondaryColorLight)
            KMCore.userDefaults.set(themeBackgroundColorLight.base64EncodedString, forKey: KMTheme.KMThemeBackgroundColorLight)
            KMCore.userDefaults.set(themeActiveColorLight.base64EncodedString, forKey: KMTheme.KMThemeActiveColorLight)
            KMCore.userDefaults.set(themeTintColorLight.base64EncodedString, forKey: KMTheme.KMThemeTintColorLight)
            KMCore.userDefaults.set(themePrimaryColorDark.base64EncodedString, forKey: KMTheme.KMThemePrimaryColorDark)
            KMCore.userDefaults.set(themeSecondaryColorDark.base64EncodedString, forKey: KMTheme.KMThemeSecondaryColorDark)
            KMCore.userDefaults.set(themeBackgroundColorDark.base64EncodedString, forKey: KMTheme.KMThemeBackgroundColorDark)
            KMCore.userDefaults.set(themeActiveColorDark.base64EncodedString, forKey: KMTheme.KMThemeActiveColorDark)
            KMCore.userDefaults.set(themeTintColorDark.base64EncodedString, forKey: KMTheme.KMThemeTintColorDark)
        }
    }

    func themePrimaryColor(scheme: ColorScheme) -> Color {
        return scheme == .light ? themePrimaryColorLight : themePrimaryColorDark
    }

    func themeSecondaryColor(scheme: ColorScheme) -> Color {
        return scheme == .light ? themeSecondaryColorLight : themeSecondaryColorDark
    }

    func themeActiveColor(scheme: ColorScheme) -> Color {
        return scheme == .light ? themeActiveColorLight : themeActiveColorDark
    }

    func themeTintColor(scheme: ColorScheme) -> Color {
        return scheme == .light ? themeTintColorLight : themeTintColorDark
    }

    func themeBackgroundColor(scheme: ColorScheme) -> Color {
        return scheme == .light ? themeBackgroundColorLight : themeBackgroundColorDark
    }
}

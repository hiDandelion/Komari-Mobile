//
//  ThemeSettingsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI
import PhotosUI

struct ThemeSettingsView: View {
    @Environment(KMTheme.self) var theme
    @AppStorage("KMBackgroundPhotoData", store: KMCore.userDefaults) private var backgroundPhotoData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State var backgroundImage: UIImage?

    var body: some View {
        Form {
            Section {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text("Select Custom Background")
                }
                .onChange(of: selectedPhoto) {
                    Task {
                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                            backgroundPhotoData = data
                            backgroundImage = UIImage(data: data)
                        }
                    }
                }

                if backgroundImage != nil {
                    Button("Delete Custom Background") {
                        backgroundPhotoData = nil
                        backgroundImage = nil
                    }
                }
            } header: {
                Text("Background Customization")
            }
            .onAppear {
                let backgroundPhotoData = KMCore.userDefaults.data(forKey: "KMBackgroundPhotoData")
                if let backgroundPhotoData {
                    backgroundImage = UIImage(data: backgroundPhotoData)
                }
            }

            Section {
                ColorPicker("Primary Color Light Mode", selection: Bindable(theme).themePrimaryColorLight)
                ColorPicker("Secondary Color Light Mode", selection: Bindable(theme).themeSecondaryColorLight)
                ColorPicker("Background Color Light Mode", selection: Bindable(theme).themeBackgroundColorLight)
                ColorPicker("Active Color Light Mode", selection: Bindable(theme).themeActiveColorLight)
                ColorPicker("Tint Color Light Mode", selection: Bindable(theme).themeTintColorLight)
                ColorPicker("Primary Color Dark Mode", selection: Bindable(theme).themePrimaryColorDark)
                ColorPicker("Secondary Color Dark Mode", selection: Bindable(theme).themeSecondaryColorDark)
                ColorPicker("Background Color Dark Mode", selection: Bindable(theme).themeBackgroundColorDark)
                ColorPicker("Active Color Dark Mode", selection: Bindable(theme).themeActiveColorDark)
                ColorPicker("Tint Color Dark Mode", selection: Bindable(theme).themeTintColorDark)
            } header: {
                Text("Theme Customization")
            }
        }
        .navigationTitle("Theme Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

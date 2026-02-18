//
//  GetOSLogo.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct GetOSLogo {
    private static let osKeywords: [(keywords: [String], name: String)] = [
        (["alma", "almalinux"], "AlmaLinux"),
        (["alpine"], "Alpine Linux"),
        (["armbian"], "Armbian"),
        (["centos", "cent os"], "CentOS"),
        (["debian", "deb"], "Debian"),
        (["freebsd", "bsd"], "FreeBSD"),
        (["ubuntu", "elementary"], "Ubuntu"),
        (["windows", "win", "microsoft"], "Windows"),
        (["arch", "archlinux"], "Arch Linux"),
        (["kali"], "Kali Linux"),
        (["istoreos", "istore"], "iStoreOS"),
        (["openwrt", "qwrt"], "OpenWrt"),
        (["immortalwrt", "immortal"], "ImmortalWrt"),
        (["nixos", "nix"], "NixOS"),
        (["rocky"], "Rocky Linux"),
        (["fedora"], "Fedora"),
        (["opensuse", "suse"], "openSUSE"),
        (["gentoo"], "Gentoo"),
        (["redhat", "rhel", "red hat"], "Red Hat"),
        (["mint", "linux mint"], "Linux Mint"),
        (["manjaro"], "Manjaro"),
        (["synology", "dsm"], "Synology DSM"),
        (["fnos", "fnnas"], "fnOS"),
        (["proxmox"], "Proxmox VE"),
        (["macos", "darwin"], "macOS"),
        (["ios"], "iOS"),
        (["astra"], "Astra Linux"),
        (["orange pi", "orangepi"], "Orange Pi"),
        (["huawei", "euleros"], "Huawei"),
        (["aliyun", "alibaba"], "Aliyun"),
        (["opencloud"], "OpenCloudOS"),
        (["unraid"], "Unraid"),
    ]

    static func name(for osString: String) -> String {
        let lower = osString.lowercased()
        for entry in osKeywords {
            for keyword in entry.keywords {
                if lower.contains(keyword) {
                    return entry.name
                }
            }
        }
        guard !osString.isEmpty else { return "Unknown" }
        return osString.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? "Unknown"
    }

    @ViewBuilder
    static func logo(for osName: String) -> some View {
        if osName.lowercased().contains("debian") {
            Image("DebianLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("ubuntu") {
            Image("UbuntuLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("windows") {
            Image("WindowsLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("darwin") || osName.lowercased().contains("macos") {
            Image("macOSLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("ios") {
            Image("iOSLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else {
            Image(systemName: "server.rack")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }
}

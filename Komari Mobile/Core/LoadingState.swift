//
//  LoadingState.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

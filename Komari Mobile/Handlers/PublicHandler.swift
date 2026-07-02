//
//  PublicHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation

class PublicHandler {
    /// Fetch public site information (site name, record preserve times, auth capabilities)
    static func getPublicInfo() async throws -> PublicInfo {
        guard let url = KMCore.getAPIURL(endpoint: "/api/public") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch public info failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        do {
            let baseResponse = try decoder.decode(KomariBaseResponse<PublicInfo>.self, from: data)
            guard baseResponse.isSuccess, let info = baseResponse.data else {
                throw KomariError.invalidResponse(baseResponse.message ?? "Fetch public info failed")
            }
            return info
        } catch let error as DecodingError {
            RequestHandler.handleDecodingError(error: error)
            throw error
        }
    }

    /// Fetch the most recent load points for a node (used to seed the real-time chart)
    static func getRecentRecords(uuid: String) async throws -> [RecentRecord] {
        guard let url = KMCore.getAPIURL(endpoint: "/api/recent/\(uuid)") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch recent records failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        do {
            let baseResponse = try decoder.decode(KomariBaseResponse<[RecentRecord]>.self, from: data)
            guard baseResponse.isSuccess else {
                throw KomariError.invalidResponse(baseResponse.message ?? "Fetch recent records failed")
            }
            return baseResponse.data ?? []
        } catch let error as DecodingError {
            RequestHandler.handleDecodingError(error: error)
            throw error
        }
    }

    /// Fetch dashboard version info via RPC2 common:getVersion
    static func getVersion() async throws -> VersionData {
        let result: VersionData = try await RPC2Handler.call(method: "common:getVersion")
        return result
    }
}

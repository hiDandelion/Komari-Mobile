//
//  AdminHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

class AdminHandler {
    /// Add a new client
    static func addClient(name: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/add") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: ["name": name])

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Add client failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Add client failed")
        }
    }

    /// Fetch all nodes with admin details (includes token)
    static func getAdminNodes() async throws -> [AdminNodeData] {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/list") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch admin nodes failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let nodes = try decoder.decode([AdminNodeData].self, from: data)
        return nodes
    }

    /// Edit a client's settings
    static func editClient(uuid: String, changes: [String: Any]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/\(uuid)/edit") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: changes)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Edit client failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Edit client failed")
        }
    }

    /// Remove a client
    static func removeClient(uuid: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/\(uuid)/remove") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Remove client failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Remove client failed")
        }
    }

    // MARK: - Ping Tasks

    /// Fetch all ping tasks
    static func getPingTasks() async throws -> [PingTask] {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/ping") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch ping tasks failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<[PingTask]>.self, from: data)

        guard baseResponse.isSuccess, let tasks = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Fetch ping tasks failed")
        }

        return tasks
    }

    /// Add a new ping task
    static func addPingTask(name: String, type: String, target: String, clients: [String], interval: Int) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/ping/add") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = [
            "name": name,
            "type": type,
            "target": target,
            "clients": clients,
            "interval": interval
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            // Try to extract error message from response
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Add ping task failed")
            }
            throw KomariError.invalidResponse("Add ping task failed with status \(response.statusCode)")
        }
    }

    /// Edit an existing ping task
    static func editPingTask(id: Int, name: String, type: String, target: String, clients: [String], interval: Int) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/ping/edit") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let task: [String: Any] = [
            "id": id,
            "name": name,
            "type": type,
            "target": target,
            "clients": clients,
            "interval": interval
        ]
        let payload: [String: Any] = ["tasks": [task]]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Edit ping task failed")
            }
            throw KomariError.invalidResponse("Edit ping task failed with status \(response.statusCode)")
        }
    }

    /// Delete ping task(s)
    static func deletePingTasks(ids: [Int]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/ping/delete") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = ["id": ids]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Delete ping task failed")
            }
            throw KomariError.invalidResponse("Delete ping task failed with status \(response.statusCode)")
        }
    }

    // MARK: - Offline Notifications

    /// Fetch all offline notification settings
    static func getOfflineNotifications() async throws -> [OfflineNotification] {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/notification/offline") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch offline notifications failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<[OfflineNotification]>.self, from: data)

        guard baseResponse.isSuccess, let notifications = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Fetch offline notifications failed")
        }

        return notifications
    }

    /// Edit offline notification settings for one or more nodes
    static func editOfflineNotifications(entries: [[String: Any]]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/notification/offline/edit") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: entries)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Edit offline notifications failed")
            }
            throw KomariError.invalidResponse("Edit offline notifications failed with status \(response.statusCode)")
        }
    }

    // MARK: - Load Alerts

    /// Fetch all load alerts
    static func getLoadAlerts() async throws -> [LoadAlert] {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/notification/load") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch load alerts failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<[LoadAlert]>.self, from: data)

        guard baseResponse.isSuccess, let alerts = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Fetch load alerts failed")
        }

        return alerts
    }

    /// Add a new load alert
    static func addLoadAlert(name: String, metric: String, threshold: Double, ratio: Double, clients: [String], interval: Int) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/notification/load/add") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = [
            "name": name,
            "metric": metric,
            "threshold": threshold,
            "ratio": ratio,
            "clients": clients,
            "interval": interval
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Add load alert failed")
            }
            throw KomariError.invalidResponse("Add load alert failed with status \(response.statusCode)")
        }
    }

    /// Edit an existing load alert
    static func editLoadAlert(id: Int, name: String, metric: String, threshold: Double, ratio: Double, clients: [String], interval: Int) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/notification/load/edit") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let notification: [String: Any] = [
            "id": id,
            "name": name,
            "metric": metric,
            "threshold": threshold,
            "ratio": ratio,
            "clients": clients,
            "interval": interval
        ]
        let payload: [String: Any] = ["notifications": [notification]]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Edit load alert failed")
            }
            throw KomariError.invalidResponse("Edit load alert failed with status \(response.statusCode)")
        }
    }

    /// Delete load alert(s)
    static func deleteLoadAlerts(ids: [Int]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/notification/load/delete") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = ["id": ids]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Delete load alert failed")
            }
            throw KomariError.invalidResponse("Delete load alert failed with status \(response.statusCode)")
        }
    }

    // MARK: - Dashboard Settings

    /// Fetch dashboard settings
    static func getSettings() async throws -> DashboardSettings {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/settings") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch settings failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<DashboardSettings>.self, from: data)

        guard baseResponse.isSuccess, let settings = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Fetch settings failed")
        }

        return settings
    }

    /// Update dashboard settings (partial update)
    static func updateSettings(changes: [String: Any]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/settings") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: changes)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Update settings failed")
            }
            throw KomariError.invalidResponse("Update settings failed with status \(response.statusCode)")
        }
    }

    // MARK: - Sessions

    /// Fetch all sessions
    static func getSessions() async throws -> (current: String, sessions: [SessionInfo]) {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/session/get") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch sessions failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let sessionsResponse = try decoder.decode(SessionsResponse.self, from: data)

        guard sessionsResponse.status == "success" else {
            throw KomariError.invalidResponse("Fetch sessions failed")
        }

        return (sessionsResponse.current ?? "", sessionsResponse.data ?? [])
    }

    /// Remove a specific session
    static func removeSession(session: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/session/remove") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: ["session": session])

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Remove session failed")
            }
            throw KomariError.invalidResponse("Remove session failed with status \(response.statusCode)")
        }
    }

    /// Remove all sessions
    static func removeAllSessions() async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/session/remove/all") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Remove all sessions failed")
            }
            throw KomariError.invalidResponse("Remove all sessions failed with status \(response.statusCode)")
        }
    }

    // MARK: - Account

    /// Update username
    static func updateUsername(uuid: String, username: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/update/user") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = ["uuid": uuid, "username": username]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Update username failed")
            }
            throw KomariError.invalidResponse("Update username failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<[String: String]?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Update username failed")
        }
    }

    /// Update password
    static func updatePassword(uuid: String, password: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/update/user") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = ["uuid": uuid, "password": password]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Update password failed")
            }
            throw KomariError.invalidResponse("Update password failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<[String: String]?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Update password failed")
        }
    }

    /// Generate 2FA QR code (returns PNG image data)
    static func generate2FA() async throws -> Data {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/2fa/generate") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Generate 2FA failed with status \(response.statusCode)")
        }

        return data
    }

    /// Enable 2FA with verification code
    static func enable2FA(code: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/2fa/enable?code=\(code)") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST"
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Enable 2FA failed")
            }
            throw KomariError.invalidResponse("Enable 2FA failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Enable 2FA failed")
        }
    }

    /// Disable 2FA
    static func disable2FA() async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/2fa/disable") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST"
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Disable 2FA failed")
            }
            throw KomariError.invalidResponse("Disable 2FA failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Disable 2FA failed")
        }
    }

    /// Unbind OAuth2 provider
    static func unbindOAuth2() async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/oauth2/unbind") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST"
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Unbind OAuth2 failed")
            }
            throw KomariError.invalidResponse("Unbind OAuth2 failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Unbind OAuth2 failed")
        }
    }

    // MARK: - Remote Exec

    /// Execute a command on selected nodes
    static func execTask(command: String, clients: [String]) async throws -> ExecTaskData {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/task/exec") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let payload: [String: Any] = [
            "command": command,
            "clients": clients
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Exec task failed")
            }
            throw KomariError.invalidResponse("Exec task failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<ExecTaskData>.self, from: data)

        guard baseResponse.isSuccess, let taskData = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Exec task failed")
        }

        return taskData
    }

    /// Poll for task execution results
    static func getTaskResult(taskId: String) async throws -> [ExecResult] {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/task/\(taskId)/result") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(KomariBaseResponse<String?>.self, from: data) {
                throw KomariError.invalidResponse(errorResponse.message ?? "Fetch task result failed")
            }
            throw KomariError.invalidResponse("Fetch task result failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<[ExecResult]>.self, from: data)

        guard baseResponse.isSuccess, let results = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Fetch task result failed")
        }

        return results
    }

    // MARK: - Logs

    /// Fetch paginated audit logs
    static func getLogs(limit: Int, page: Int) async throws -> (logs: [AuditLog], total: Int) {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/logs?limit=\(limit)&page=\(page)") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Fetch logs failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<LogsData>.self, from: data)

        guard baseResponse.isSuccess, let logsData = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Fetch logs failed")
        }

        return (logsData.logs ?? [], logsData.total ?? 0)
    }

    // MARK: - Client Management

    /// Reorder clients
    static func reorderClients(uuids: [String]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/order") else {
            throw KomariError.invalidDashboardConfiguration
        }

        var orderMap: [String: Int] = [:]
        for (index, uuid) in uuids.enumerated() {
            orderMap[uuid] = index
        }
        let bodyData = try JSONSerialization.data(withJSONObject: orderMap)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Reorder clients failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Reorder clients failed")
        }
    }
}

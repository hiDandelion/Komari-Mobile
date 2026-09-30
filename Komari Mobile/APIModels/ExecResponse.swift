//
//  ExecResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import Foundation

struct ExecTaskData: Codable {
    let taskId: String?
    let clients: [String]?
    /// Offline targets; the command is delivered once they reconnect
    let queuedClients: [String]?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case clients
        case queuedClients = "queued_clients"
    }
}

struct ExecResult: Codable, Identifiable {
    let taskId: String?
    let client: String?
    let clientInfo: ExecClientInfo?
    let result: String?
    let exitCode: Int?
    let finishedAt: String?
    let createdAt: String?

    var id: String { client ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case client
        case clientInfo = "client_info"
        case result
        case exitCode = "exit_code"
        case finishedAt = "finished_at"
        case createdAt = "created_at"
    }
}

struct ExecClientInfo: Codable {
    let uuid: String?
    let name: String?
}

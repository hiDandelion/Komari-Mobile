//
//  ServerAppEntity.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import AppIntents

struct ServerAppEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Server"
    static var defaultQuery = ServerEntityQuery()

    var id: String
    var name: String
    var region: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(region) \(name)")
    }
}

struct ServerEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ServerAppEntity] {
        guard WidgetKMCore.isConfigured else { return [] }
        do {
            try await WidgetDataProvider.ensureAuth()
            let nodes = try await WidgetDataProvider.getNodes()
            return identifiers.compactMap { id in
                guard let node = nodes[id] else { return nil }
                return ServerAppEntity(id: node.uuid, name: node.name, region: node.region)
            }
        } catch {
            return []
        }
    }

    func suggestedEntities() async throws -> [ServerAppEntity] {
        guard WidgetKMCore.isConfigured else { return [] }
        try await WidgetDataProvider.ensureAuth()
        let nodes = try await WidgetDataProvider.getNodes()
        return nodes.values
            .sorted { $0.weight < $1.weight }
            .map { ServerAppEntity(id: $0.uuid, name: $0.name, region: $0.region) }
    }

    func defaultResult() async -> ServerAppEntity? {
        guard WidgetKMCore.isConfigured else { return nil }
        do {
            try await WidgetDataProvider.ensureAuth()
            let nodes = try await WidgetDataProvider.getNodes()
            guard let first = nodes.values.sorted(by: { $0.weight < $1.weight }).first else { return nil }
            return ServerAppEntity(id: first.uuid, name: first.name, region: first.region)
        } catch {
            return nil
        }
    }
}

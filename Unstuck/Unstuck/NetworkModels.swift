// NetworkModels.swift — data models for task breakdowns
// Unstuck

import Foundation

struct BreakdownRequest: Codable { let task: String }
struct BreakdownResponse: Codable { let steps: [BreakdownStep] }

struct BreakdownStep: Codable, Identifiable {
    let id: UUID
    let order: Int
    let text: String
    let estimatedMinutes: Int
    var completed: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, order, text, estimatedMinutes, completed
    }

    // Decode from Gemini JSON — completed defaults to false if absent
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,   forKey: .id)
        order            = try c.decode(Int.self,    forKey: .order)
        text             = try c.decode(String.self, forKey: .text)
        estimatedMinutes = try c.decode(Int.self,    forKey: .estimatedMinutes)
        completed        = try c.decodeIfPresent(Bool.self, forKey: .completed) ?? false
    }

    // Memberwise init for previews and tests
    init(id: UUID = UUID(), order: Int, text: String, estimatedMinutes: Int, completed: Bool = false) {
        self.id = id; self.order = order; self.text = text
        self.estimatedMinutes = estimatedMinutes; self.completed = completed
    }
}

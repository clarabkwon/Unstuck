import Foundation

@MainActor
final class APIClient {
    static let shared = APIClient()

    private var apiKey: String? {
        let fromPlist = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
        if let value = fromPlist?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            return value
        }
        let fromEnv = ProcessInfo.processInfo.environment["API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let value = fromEnv, !value.isEmpty {
            return value
        }
        return nil
    }

    enum APIError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case badStatus(Int, String)
        case emptyResponse
        case parseFailure

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:   return "Missing Gemini API key. Add GEMINI_API_KEY to Info.plist."
            case .invalidURL:      return "Invalid Gemini endpoint URL."
            case .badStatus(let code, let body): return "HTTP \(code): \(body)"
            case .emptyResponse:   return "Empty response from Gemini."
            case .parseFailure:    return "Could not parse Gemini response."
            }
        }
    }

    // MARK: - Gemini envelope types

    private struct GeminiRequest: Encodable {
        struct Content: Encodable {
            struct Part: Encodable { let text: String }
            let parts: [Part]
        }
        let contents: [Content]
    }

    private struct GeminiResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String }
                let parts: [Part]
            }
            let content: Content
        }
        let candidates: [Candidate]
    }

    // MARK: - Public

    func breakdown(task: String) async throws -> [BreakdownStep] {
        guard !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        guard let key = apiKey, !key.isEmpty else { throw APIError.missingAPIKey }

        guard let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)"
        ) else { throw APIError.invalidURL }

        let prompt = """
        Break down this task into 4-6 simple actionable steps.
        Return ONLY a JSON array with no markdown, no explanation.
        Each object must have: id (UUID string), order (integer), text (string), estimatedMinutes (integer).
        Task: \(task)
        """

        let body = GeminiRequest(contents: [
            .init(parts: [.init(text: prompt)])
        ])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.emptyResponse }
        guard 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.badStatus(http.statusCode, body)
        }

        let gemini = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = gemini.candidates.first?.content.parts.first?.text else {
            throw APIError.emptyResponse
        }

        return try parseBreakdown(from: text)
    }

    // MARK: - Parsing

    private func parseBreakdown(from text: String) throws -> [BreakdownStep] {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else { throw APIError.parseFailure }

        if let steps = try? JSONDecoder().decode([BreakdownStep].self, from: data), !steps.isEmpty {
            return steps
        }
        if let obj = try? JSONDecoder().decode([String: [BreakdownStep]].self, from: data),
           let first = obj.values.first, !first.isEmpty {
            return first
        }

        throw APIError.parseFailure
    }
}

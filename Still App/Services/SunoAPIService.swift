//
//  SunoAPIService.swift
//  Still App
//
//  Service for generating meditation music using Suno AI API.
//

import Foundation

// MARK: - Models

struct SunoGenerateRequest: Codable {
    let prompt: String
    let style: String
    let title: String
    let customMode: Bool
    let instrumental: Bool
    let model: String
    let negativeTags: String?
    let callBackUrl: String
    
    enum CodingKeys: String, CodingKey {
        case prompt, style, title, customMode, instrumental, model, negativeTags, callBackUrl
    }
}

struct SunoGenerateResponse: Codable {
    let code: Int
    let msg: String
    let data: SunoTaskData?
}

struct SunoTaskData: Codable {
    let taskId: String
}

struct SunoTaskStatusResponse: Codable {
    let code: Int
    let msg: String
    let data: SunoTaskDetails?
}

struct SunoTaskDetails: Codable {
    let taskId: String?
    let status: String?
    let audioUrl: String?
    let title: String?
    let style: String?
    let prompt: String?
    let errorMessage: String?
    let clips: [SunoClip]?
    let response: SunoResponseData?
}

struct SunoResponseData: Codable {
    let taskId: String?
    let sunoData: [SunoClip]?
}

struct SunoClip: Codable {
    let id: String?
    let audioUrl: String?
    let sourceAudioUrl: String?
    let streamAudioUrl: String?
    let videoUrl: String?
    let imageUrl: String?
    let sourceImageUrl: String?
    let imageLargeUrl: String?
    let title: String?
    let status: String?
    let tags: String?
    let duration: Double?
    
    var resolvedAudioUrl: String? {
        audioUrl ?? sourceAudioUrl ?? streamAudioUrl
    }
    
    var resolvedImageUrl: String? {
        imageUrl ?? sourceImageUrl ?? imageLargeUrl
    }
}

// MARK: - Generated Music Model

struct GeneratedMusic: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let style: String
    let prompt: String
    let audioUrl: String?
    let imageUrl: String?
    let createdAt: Date
    var isPlaying: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, title, style, prompt, audioUrl, imageUrl, createdAt
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GeneratedMusic, rhs: GeneratedMusic) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Music Style Presets

enum MeditationStyle: String, CaseIterable, Identifiable {
    case ambient = "Ambient, Atmospheric, Ethereal"
    case nature = "Nature Sounds, Peaceful, Organic"
    case piano = "Piano, Soft, Melodic, Minimalist"
    case tibetan = "Tibetan, Singing Bowls, Spiritual"
    case binaural = "Binaural, Deep, Resonant, Healing"
    case lofi = "Lo-fi, Calm, Warm, Relaxing"
    case classical = "Classical, Orchestra, Serene"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ambient: return "Ambient"
        case .nature: return "Nature"
        case .piano: return "Piano"
        case .tibetan: return "Tibetan"
        case .binaural: return "Binaural"
        case .lofi: return "Lo-fi"
        case .classical: return "Classical"
        case .custom: return "Custom Style"
        }
    }
    
    var icon: String {
        switch self {
        case .ambient: return "cloud"
        case .nature: return "leaf"
        case .piano: return "pianokeys"
        case .tibetan: return "bell"
        case .binaural: return "waveform.path"
        case .lofi: return "headphones"
        case .classical: return "music.quarternote.3"
        case .custom: return "paintbrush"
        }
    }
}

// MARK: - Suno API Service

class SunoAPIService {
    static let shared = SunoAPIService()
    
    private let apiKey = "e03bcaff433a222200deecb112215f2a"
    private let baseURL = "https://api.sunoapi.org"
    
    private init() {}
    
    // MARK: - Generate Music
    
    func generateMusic(
        prompt: String,
        style: String,
        title: String,
        instrumental: Bool = true
    ) async throws -> String {
        let url = URL(string: "\(baseURL)/api/v1/generate")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SunoGenerateRequest(
            prompt: prompt,
            style: style,
            title: title,
            customMode: true,
            instrumental: instrumental,
            model: "V4_5",
            negativeTags: "Heavy Metal, Aggressive, Fast, Loud, Distorted",
            callBackUrl: "https://stillapp.webhook.placeholder"
        )
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SunoAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(SunoGenerateResponse.self, from: data)
            throw SunoAPIError.apiError(errorResponse?.msg ?? "Unknown error")
        }
        
        let result = try JSONDecoder().decode(SunoGenerateResponse.self, from: data)
        
        guard result.code == 200, let taskId = result.data?.taskId else {
            throw SunoAPIError.apiError(result.msg)
        }
        
        return taskId
    }
    
    // MARK: - Check Task Status
    
    func checkTaskStatus(taskId: String) async throws -> SunoTaskDetails {
        var components = URLComponents(string: "\(baseURL)/api/v1/generate/record-info")!
        components.queryItems = [URLQueryItem(name: "taskId", value: taskId)]
        
        guard let url = components.url else {
            throw SunoAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SunoAPIError.invalidResponse
        }
        
        // Debug: print response for troubleshooting
        if let responseString = String(data: data, encoding: .utf8) {
            print("Suno API Response: \(responseString)")
        }
        
        if httpResponse.statusCode != 200 {
            throw SunoAPIError.apiError("Failed to check task status (HTTP \(httpResponse.statusCode))")
        }
        
        let result = try JSONDecoder().decode(SunoTaskStatusResponse.self, from: data)
        
        guard result.code == 200, let details = result.data else {
            throw SunoAPIError.apiError(result.msg)
        }
        
        return details
    }
    
    // MARK: - Poll for Completion
    
    func waitForCompletion(taskId: String, maxAttempts: Int = 60) async throws -> SunoTaskDetails {
        for attempt in 0..<maxAttempts {
            print("Polling attempt \(attempt + 1)/\(maxAttempts) for task \(taskId)")
            
            let status = try await checkTaskStatus(taskId: taskId)
            let currentStatus = status.status?.lowercased() ?? ""
            
            print("Current status: \(currentStatus)")
            
            // Check for success states
            if currentStatus == "success" || currentStatus == "complete" || currentStatus == "completed" {
                return status
            }
            
            // Check for failure states
            if currentStatus == "failed" || currentStatus == "error" || currentStatus == "failure" {
                throw SunoAPIError.generationFailed(status.errorMessage ?? "Generation failed")
            }
            
            // Wait 5 seconds before next poll
            try await Task.sleep(nanoseconds: 5_000_000_000)
        }
        
        throw SunoAPIError.timeout
    }
    
    // MARK: - Extract Audio URL from Response
    
    func extractAudioUrl(from details: SunoTaskDetails) -> (audioUrl: String?, imageUrl: String?) {
        print("=== Extracting Audio URL ===")
        print("Response object exists: \(details.response != nil)")
        print("SunoData count: \(details.response?.sunoData?.count ?? 0)")
        
        // Try to get from response.sunoData (this is where the API puts it)
        if let sunoData = details.response?.sunoData, let firstClip = sunoData.first {
            print("Found in response.sunoData!")
            print("  audioUrl: \(firstClip.audioUrl ?? "nil")")
            print("  sourceAudioUrl: \(firstClip.sourceAudioUrl ?? "nil")")
            print("  resolvedAudioUrl: \(firstClip.resolvedAudioUrl ?? "nil")")
            return (firstClip.resolvedAudioUrl, firstClip.resolvedImageUrl)
        }
        
        // Try clips array at root level
        if let clips = details.clips, let firstClip = clips.first {
            print("Found in clips: \(firstClip.resolvedAudioUrl ?? "nil")")
            return (firstClip.resolvedAudioUrl, firstClip.resolvedImageUrl)
        }
        
        // Direct audioUrl
        print("Using direct audioUrl: \(details.audioUrl ?? "nil")")
        return (details.audioUrl, nil)
    }
}

// MARK: - Errors

enum SunoAPIError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case generationFailed(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return message
        case .generationFailed(let message):
            return "Music generation failed: \(message)"
        case .timeout:
            return "Generation timed out. Please try again."
        }
    }
}


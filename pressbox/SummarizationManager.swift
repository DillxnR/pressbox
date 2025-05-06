//
//  SummarizationManager.swift
//  pressbox
//
//  Created by Dillon Ring on 5/6/25.
//

import Foundation
import Security

class SummarizationManager {
    // The OpenAI API key
    private var apiKey: String?
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini" // Use GPT-4o mini for summarization
    
    init() {
        // Try to load API key from Keychain
        apiKey = loadAPIKeyFromKeychain()
    }
    
    func setAPIKey(_ key: String) {
        apiKey = key
        saveAPIKeyToKeychain(key)
    }
    
    func hasAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    func summarizeTranscript(_ transcript: String, completion: @escaping (String?, Error?) -> Void) {
        // Check if we have an API key
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            let error = NSError(domain: "SummarizationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "API key not set. Please set your OpenAI API key in settings."])
            completion(nil, error)
            return
        }
        
        // If transcript is too short, no need to summarize
        if transcript.count < 100 {
            completion(transcript, nil)
            return
        }
        
        // Call the OpenAI API
        callOpenAIAPI(transcript: transcript, completion: completion)
    }
    
    private func callOpenAIAPI(transcript: String, completion: @escaping (String?, Error?) -> Void) {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare the prompt
        let prompt = """
        Please create a clear, concise summary of the following transcript. Focus on the main points, key information, and any important decisions or action items. The summary should be about 1/4 the length of the original text.

        TRANSCRIPT:
        \(transcript)
        """
        
        // Prepare the request payload
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that summarizes transcripts accurately and concisely."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.5,
            "max_tokens": min(4000, transcript.count / 3), // Limit max tokens based on transcript length
            "top_p": 1.0
        ]
        
        // Convert payload to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(nil, NSError(domain: "SummarizationError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"]))
            return
        }
        
        request.httpBody = jsonData
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "SummarizationError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            // Parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check for errors in the response
                    if let errorDict = json["error"] as? [String: Any],
                       let message = errorDict["message"] as? String {
                        completion(nil, NSError(domain: "OpenAIError", code: 4, userInfo: [NSLocalizedDescriptionKey: message]))
                        return
                    }
                    
                    if let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(content, nil)
                    } else {
                        completion(nil, NSError(domain: "SummarizationError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response - no content found"]))
                    }
                } else {
                    completion(nil, NSError(domain: "SummarizationError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response - invalid JSON"]))
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    // MARK: - Keychain Access
    
    private func saveAPIKeyToKeychain(_ apiKey: String) {
        let service = "com.pressbox.apikey"
        let account = "openai"
        
        // Delete any existing key
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add the new key
        let keyData = apiKey.data(using: .utf8)!
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving API key to Keychain: \(status)")
        }
    }
    
    private func loadAPIKeyFromKeychain() -> String? {
        let service = "com.pressbox.apikey"
        let account = "openai"
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            print("Error loading API key from Keychain: \(status)")
            return nil
        }
    }
}
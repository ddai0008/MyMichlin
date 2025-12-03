//
//  GeminiManger.swift
//  MyMichlin
//
//  Created by David Dai on 5/11/2025.
//

import Foundation
import FirebaseAILogic


class GeminiManager {
    static let shared = GeminiManager()

    let generativeModel: GenerativeModel
    let databaseController = CoreDataController.shared


    private init() {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        generativeModel = ai.generativeModel(modelName: "gemini-2.5-flash")
    }
    
    // Generate Response based on user info
    func fetchRestaurantReply(for text: String) async throws -> String {
        
        var userPreferenceText = ""
        
        // Get user Info
        if let user = databaseController.fetchUser() {
            let cuisines = user.preferredCuisineArray.joined(separator: ", ")
            userPreferenceText = """
            User Preferences:
            - Name: \(user.userName ?? "Unknown")
            - City: \(user.city ?? "Unknown"), \(user.country ?? "")
            - Favourite cuisines: \(cuisines.isEmpty ? "Not specified" : cuisines)
            - Price range: \(user.preferredPriceRange) / 5
            """
        } else {
            userPreferenceText = "User preferences not found."
        }


        // Build the AI prompt
        let prompt = """
        You are MyMichlin AI Assistant.
        You help users discover and learn about restaurants, cuisines, and dining experiences.
        Use the user’s preferences to personalize responses.
        Be **concise** and clear — answer in 1–3 sentences maximum.
        If the question is unrelated to food or dining, politely redirect them.

        \(userPreferenceText)

        User: \(text)
        """


        // Generate the AI response
        let response = try await generativeModel.generateContent(prompt)
        return response.text ?? "No response from AI."
    }

}

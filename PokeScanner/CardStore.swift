//
//  CardStore.swift
//  PokeScanner
//
//  Created by Martin Laus on 3/18/23.
//

import Combine
import SwiftUI


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}


class CardStore: ObservableObject {
    @Published var cards: [Card] = []

    private var cardsFileURL: URL {
        getDocumentsDirectory().appendingPathComponent("cards.json")
    }

    init() {
        loadCards()
    }

    func loadCards() {
        do {
            let data = try Data(contentsOf: cardsFileURL)
            let decoder = JSONDecoder()
            cards = try decoder.decode([Card].self, from: data)
        } catch {
            print("Error loading cards: \(error)")
            cards = []
        }
    }

    func saveCards() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cards)
            try data.write(to: cardsFileURL, options: .atomic)
        } catch {
            print("Error saving cards: \(error)")
        }
    }
}

//class CardStore: ObservableObject {
//    @Published var cards: [Card] {
//        didSet {
//            saveCards()
//        }
//    }
//
//    init() {
//        let loadedCards: [Card] = {
//            if let data = UserDefaults.standard.data(forKey: "cards"),
//               let decoded = try? JSONDecoder().decode([Card].self, from: data) {
//                return decoded
//            }
//
//            // Create a sample card using UIImage data
//            let sampleImage = UIImage(systemName: "photo")!
//            let imageData = sampleImage.jpegData(compressionQuality: 0.8)!
//
//            return [
//                Card(name: "Sample Pokemon", imageData: imageData, notes: "Sample text from the card")
//            ]
//        }()
//        self.cards = loadedCards
//    }
//
//    private func saveCards() {
//        if let encoded = try? JSONEncoder().encode(cards) {
//            UserDefaults.standard.set(encoded, forKey: "cards")
//        }
//    }
//}


//class CardStore: ObservableObject {
//    @Published var cards: [Card] {
//        didSet {
//            saveCards()
//        }
//    }
//
//    init() {
//        self.cards = loadedCards
//    }
//
//    private func saveCards() {
//        if let encoded = try? JSONEncoder().encode(cards) {
//            UserDefaults.standard.set(encoded, forKey: "cards")
//        }
//    }
//
//    private var loadedCards: [Card] {
//        if let data = UserDefaults.standard.data(forKey: "cards"),
//           let decoded = try? JSONDecoder().decode([Card].self, from: data) {
//            return decoded
//        }
//
//        // Create a sample card using UIImage data
//        let sampleImage = UIImage(systemName: "photo")!
//        let imageData = sampleImage.jpegData(compressionQuality: 0.8)!
//
//        return [
//            Card(name: "Sample Pokemon", imageData: imageData, notes: "Sample text from the card")
//        ]
//    }
//}



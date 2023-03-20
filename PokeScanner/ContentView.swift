//
//  ContentView.swift
//  PokeScanner
//
//  Created by Martin Laus on 3/16/23.
//


import SwiftUI
import Vision
import VisionKit

func generateUniqueFileName(fileExtension: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMddHHmmss"
    let dateString = dateFormatter.string(from: Date())
    let randomUUID = UUID().uuidString
    return "\(dateString)_\(randomUUID).\(fileExtension)"
}


func saveImageToDocuments(image: UIImage, fileName: String) -> URL? {
    let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
    if let data = image.jpegData(compressionQuality: 0.8) {
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image: \(error)")
        }
    }
    return nil
}


struct ContentView: View {
    @StateObject private var cardStore = CardStore()
    @State private var isScanning = false

    var body: some View {
        NavigationView {
            List {
                ForEach(cardStore.cards.indices, id: \.self) { index in
                    CardRow(card: cardStore.cards[index], updateCard: { updatedCard in
                        cardStore.cards[index] = updatedCard
                    })
                }
                .onDelete(perform: deleteCard)
            }
            .navigationTitle("My Cards")
            .navigationBarItems(trailing: Button(action: { isScanning = true }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $isScanning) {
                ScanView(cards: $cardStore.cards, isScanning: $isScanning)
            }
        }
    }
    
    private func deleteCard(at offsets: IndexSet) {
        cardStore.cards.remove(atOffsets: offsets)
        cardStore.saveCards()
    }
}


struct CardRow: View {
    var card: Card
    let updateCard: (Card) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack {
            HStack {
                TextField("Name", text: Binding(
                    get: { card.name },
                    set: { newName in
                        var updatedCard = card
                        updatedCard.name = newName
                        updateCard(updatedCard)
                    }
                ))
                Spacer()
            }
            if isExpanded {
                Button(action: { isExpanded.toggle() }) {
                    Image(uiImage: UIImage(contentsOfFile: card.imageURL.path) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                if let notes = card.notes {
                    Text(notes)
                }
            } else {
                Image(uiImage: UIImage(contentsOfFile: card.imageURL.path) ?? UIImage())
                    .resizable()
                    .frame(width: 100, height: 100)
                    .onTapGesture { isExpanded.toggle() }
            }
        }
    }
}


struct ScanView: UIViewControllerRepresentable {
    @Binding var cards: [Card]
    @Environment(\.presentationMode) var presentationMode
    @Binding var isScanning: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // No updates required
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScanView

        init(_ parent: ScanView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let image = UIImage(cgImage: scan.imageOfPage(at: 0).cgImage!)

            let request = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")

                DispatchQueue.main.async {
                    if let imageURL = saveImageToDocuments(image: image, fileName: generateUniqueFileName(fileExtension: "jpg")) {
                        let newCard = Card(name: "New Card", imageURL: imageURL, notes: recognizedText)
                        self.parent.cards.append(newCard)
                    }
                    self.parent.isScanning = false
                }
            }

            let requests = [request]

            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else { return }
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform(requests)
            }

            parent.presentationMode.wrappedValue.dismiss()
        }

    }
}


struct Card: Codable, Identifiable {
    let id: UUID
    var name: String
    let imageURL: URL
    let notes: String?

    init(id: UUID = UUID(), name: String, imageURL: URL, notes: String? = nil) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.notes = notes
    }

    static func saveImage(imageData: Data) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageName = UUID().uuidString
        let imageURL = documentsDirectory.appendingPathComponent("\(imageName).jpg")
        
        do {
            try imageData.write(to: imageURL)
        } catch {
            print("Error saving image: \(error)")
        }
        
        return imageURL
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

       

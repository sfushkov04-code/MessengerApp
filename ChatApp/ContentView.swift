//
//  ContentView.swift
//  ChatApp
//
//  Created by Fushkov on 28.03.2026.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

let db = Firestore.firestore()

struct ContentView: View {
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var currentUserId: String = "1"
    
    // Для теста фиксируем пользователя
    
    @Namespace var bottomID // Для прокрутки к последнему сообщению

    var body: some View {
        VStack {
            // Сообщения
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(messages) { message in
                            HStack {
                                if message.senderId == currentUserId {
                                    Spacer()
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(15, corners: [.topLeft, .topRight, .bottomLeft])
                                        .frame(maxWidth: 250, alignment: .trailing)
                                } else {
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(15, corners: [.topLeft, .topRight, .bottomRight])
                                        .frame(maxWidth: 250, alignment: .leading)
                                    Spacer()
                                }
                            }
                            .id(message.id) // Для прокрутки
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    // Автоматическая прокрутка к последнему сообщению
                    if let last = messages.last {
                        withAnimation {
                            scrollProxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Поле ввода
            HStack {
                TextField("Сообщение...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Отправить") {
                    sendMessage()
                }
            }
            .padding()
        } // <-- закрываем VStack
        .onAppear {
            // Слушаем сообщения
            listenMessages()
            
            // Анонимная авторизация пользователя
            if Auth.auth().currentUser == nil {
                Auth.auth().signInAnonymously { result, error in
                    if let error = error {
                        print("Ошибка авторизации: \(error)")
                    } else if let user = result?.user {
                        currentUserId = user.uid
                        print("Анонимный пользователь ID: \(currentUserId)")
                    }
                }
            } else {
                currentUserId = Auth.auth().currentUser!.uid
                print("Пользователь уже авторизован ID: \(currentUserId)")
            }
        }
    }
    
    // MARK: - Функции
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = [
            "text": messageText,
            "senderId": currentUserId,
            "timestamp": Timestamp()
        ] as [String : Any]
        
        db.collection("messages").addDocument(data: newMessage) { error in
            if let error = error {
                print("Ошибка отправки: \(error)")
            } else {
                messageText = ""
            }
        }
    }
    
    func listenMessages() {
        db.collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Нет сообщений")
                    return
                }
                
                messages = documents.compactMap { doc in
                    guard let text = doc["text"] as? String,
                          let senderId = doc["senderId"] as? String else { return nil }
                    return Message(id: doc.documentID, text: text, senderId: senderId)
                }
            }
    }
}

// MARK: - Модель сообщения
struct Message: Identifiable {
    let id: String
    let text: String
    let senderId: String
}

// MARK: - Расширение для округления конкретных углов
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = []

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
}

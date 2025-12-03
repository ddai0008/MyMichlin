//
//  ChatViewController.swift
//  MyMichlin
//
//  Created by David Dai on 5/11/2025.
//


import UIKit
import CoreData


class ChatViewController: UIViewController, DatabaseListener {
    
    // Storyboard Outlet
    @IBOutlet weak var ChatTableView: UITableView!
    @IBOutlet weak var QueryTextField: UITextField!
    @IBOutlet weak var SendButton: UIButton!
    @IBOutlet weak var InputStackView: UIStackView!
    
    // Listenser Protocol
    var databaseController: DatabaseProtocol?
    var listenerType: ListenerType = .chat
    var messages: [ChatHistory] = []
    
    // For Protocol
    var restaurantReference: Restaurant?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ChatTableView.delegate = self
        ChatTableView.dataSource = self
        
        configUI()
        setupKeyboardDismissal()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        loadMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // Listener
    func onUserChange(change: DatabaseChange, user: User?) {}
    func onReviewChange(change: DatabaseChange, reviews: [Review]) {}
    func onRestaurantListChange(change: DatabaseChange, restaurant: Restaurant) {}
    
    func onChatHistoryChange(change: DatabaseChange, chats: [ChatHistory]) {
        messages = chats
        ChatTableView.reloadData()
        scrollToBottom()
    }
    
    // UI Config
    func configUI() {
        InputStackView.layer.cornerRadius = 20
        InputStackView.layer.masksToBounds = true
        InputStackView.layer.borderWidth = 0.5
        InputStackView.layer.borderColor = UIColor.systemGray4.cgColor
        
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: QueryTextField.frame.height))
        QueryTextField.leftView = leftPadding
        QueryTextField.leftViewMode = .always
    }
    
    // Keyboard dismiss when click the table view
    func setupKeyboardDismissal() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        ChatTableView.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Load message from CoreData
    func loadMessages() {
        guard let db = databaseController as? CoreDataController else { return }
        messages = db.fetchAllChats()
        ChatTableView.reloadData()
        scrollToBottom()
    }
    
    // Send Message
    @IBAction func sendTapped(_ sender: Any) {
        guard let text = QueryTextField.text, !text.isEmpty else { return }
        guard let db = databaseController as? CoreDataController else { return }
        
        // Save user message
        let _ = db.addChatMessage(message: text, isUser: true)
        scrollToBottom()
        QueryTextField.text = ""
        
        // AI Response via Gemini
        Task {
            do {
                let aiText = try await GeminiManager.shared.fetchRestaurantReply(for: text)
                _ = db.addChatMessage(message: aiText, isUser: false)
            } catch {
                let errorMsg = "Sorry, I couldn’t process that right now. Please try again later."
                _ = db.addChatMessage(message: errorMsg, isUser: false)
            }
        }
    }

    
    // Scroll to bottom when a new message is send
    func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        ChatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // Clear the chat History
    @IBAction func clearHistory(_ sender: Any) {
        showConfirmAlert(
            on: self,
            title: "Clear Chat History",
            message: "Are you sure you want to delete all chat history? This cannot be undone.",
            confirmTitle: "Clear",
            confirmAction: {
                self.databaseController?.clearChatHistory()
            }
        )
    }

}

// Table View setup
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        if message.isUser {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageTableViewCell
            cell.configure(with: message.message ?? "")
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AIMessageCell", for: indexPath) as! AIMessageTableViewCell
            cell.configure(with: message.message ?? "")
            return cell
        }
    }
}






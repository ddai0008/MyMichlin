//
//  ChatHistory+CoreDataProperties.swift
//  MyMichlin
//
//  Created by David Dai on 13/10/2025.
//
//

import Foundation
import CoreData

/**
Chat History to keep track of AI Message
 */
extension ChatHistory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatHistory> {
        return NSFetchRequest<ChatHistory>(entityName: "ChatHistory")
    }

    @NSManaged public var id: String?
    @NSManaged public var isUser: Bool
    @NSManaged public var message: String?
    @NSManaged public var timeStamp: Date?

}

extension ChatHistory : Identifiable {

}

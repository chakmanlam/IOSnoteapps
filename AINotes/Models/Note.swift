//
//  Note.swift
//  AINotes
//
//  Created by Chak Man Lam on 5/22/25.
//

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String // Derived from first line
    var content: String // Full note content
    var createdAt: Date
    var modifiedAt: Date
    
    init(content: String = "") {
        self.id = UUID()
        self.title = Note.extractTitle(from: content)
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    static func extractTitle(from content: String) -> String {
        let lines = content.split(separator: "\n")
        return lines.first.map(String.init) ?? ""
    }
    
    func updateTitle() {
        self.title = Note.extractTitle(from: content)
    }
} 
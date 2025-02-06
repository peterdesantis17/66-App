import Foundation

struct CompletionHistory: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let completionPercentage: Double
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case completionPercentage = "completion_percentage"
        case createdAt = "created_at"
    }
    
    // Regular initializer for creating new instances
    init(id: UUID, userId: UUID, date: Date, completionPercentage: Double, createdAt: Date) {
        self.id = id
        self.userId = userId
        self.date = date
        self.completionPercentage = completionPercentage
        self.createdAt = createdAt
    }
    
    // Decoder initializer for parsing from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        completionPercentage = try container.decode(Double.self, forKey: .completionPercentage)
        
        // Custom date decoding
        let dateString = try container.decode(String.self, forKey: .date)
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        
        // For simple date (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // For ISO8601 with timezone
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let parsedDate = dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .date, 
                in: container, 
                debugDescription: "Invalid date format: \(dateString)")
        }
        
        guard let parsedCreatedAt = isoFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, 
                in: container, 
                debugDescription: "Invalid date format: \(createdAtString)")
        }
        
        date = parsedDate
        createdAt = parsedCreatedAt
    }
} 
import Foundation

enum SearchFilter {
    case dateRange(start: Date, end: Date)
    case tags([String])
    case isPinned
    case isFavorite
    case hasAttachments
}

struct SearchOptions {
    var query: String = ""
    var filters: [SearchFilter] = []
    var sortBy: SearchSortOption = .modifiedAt
    var sortOrder: SearchSortOrder = .descending
    
    enum SearchSortOption {
        case title
        case createdAt
        case modifiedAt
        case tags
    }
    
    enum SearchSortOrder {
        case ascending
        case descending
    }
}

enum SearchError: LocalizedError {
    case invalidQuery
    case searchFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidQuery:
            return "Invalid search query."
        case .searchFailed:
            return "Search failed. Please try again."
        }
    }
}

protocol SearchServiceProtocol {
    func search(options: SearchOptions) throws -> [Note]
    func searchNotes(_ query: String) throws -> [Note]
    func searchByTags(_ tags: [String]) throws -> [Note]
    func searchByDateRange(start: Date, end: Date) throws -> [Note]
    func getRecentNotes(limit: Int) throws -> [Note]
    func getFrequentTags(limit: Int) throws -> [(tag: String, count: Int)]
}

final class SearchService: SearchServiceProtocol {
    
    private let noteStore: NoteStoreProtocol
    private let noteRepository: NoteRepositoryProtocol
    
    init(
        noteStore: NoteStoreProtocol = NoteStore(),
        noteRepository: NoteRepositoryProtocol = NoteRepository()
    ) {
        self.noteStore = noteStore
        self.noteRepository = noteRepository
    }
    
    func search(options: SearchOptions) throws -> [Note] {
        var results = try searchNotes(options.query)
        
        for filter in options.filters {
            results = applyFilter(results, filter)
        }
        
        results = sortResults(results, options)
        
        return results
    }
    
    func searchNotes(_ query: String) throws -> [Note] {
        if query.isEmpty {
            return try noteRepository.getAll()
        }
        
        return try noteRepository.search(query: query)
    }
    
    func searchByTags(_ tags: [String]) throws -> [Note] {
        let allNotes = try noteRepository.getAll()
        
        return allNotes.filter { note in
            tags.allSatisfy { tag in
                note.tags.contains(tag)
            }
        }
    }
    
    func searchByDateRange(start: Date, end: Date) throws -> [Note] {
        let allNotes = try noteRepository.getAll()
        
        return allNotes.filter { note in
            note.createdAt >= start && note.createdAt <= end
        }
    }
    
    func getRecentNotes(limit: Int = 10) throws -> [Note] {
        let allNotes = try noteRepository.getAll()
        
        return allNotes
            .sorted { $0.modifiedAt > $1.modifiedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    func getFrequentTags(limit: Int = 10) throws -> [(tag: String, count: Int)] {
        let allNotes = try noteRepository.getAll()
        
        var tagCounts: [String: Int] = [:]
        
        for note in allNotes {
            for tag in note.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        let sortedTags = tagCounts.sorted { $0.value > $1.value }
        
        return Array(sortedTags.prefix(limit))
            .map { (tag: $0.key, count: $0.value) }
    }
    
    private func applyFilter(_ notes: [Note], _ filter: SearchFilter) -> [Note] {
        switch filter {
        case .dateRange(let start, let end):
            return notes.filter { note in
                note.createdAt >= start && note.createdAt <= end
            }
            
        case .tags(let tags):
            return notes.filter { note in
                tags.allSatisfy { tag in
                    note.tags.contains(tag)
                }
            }
            
        case .isPinned:
            return notes.filter { $0.isPinned }
            
        case .isFavorite:
            return notes.filter { $0.isFavorite }
            
        case .hasAttachments:
            return notes.filter { !$0.attachments.isEmpty }
        }
    }
    
    private func sortResults(_ notes: [Note], _ options: SearchOptions) -> [Note] {
        let sorted: [Note]
        
        switch options.sortBy {
        case .title:
            sorted = notes.sorted {
                options.sortOrder == .ascending ?
                $0.title < $1.title :
                $0.title > $1.title
            }
            
        case .createdAt:
            sorted = notes.sorted {
                options.sortOrder == .ascending ?
                $0.createdAt < $1.createdAt :
                $0.createdAt > $1.createdAt
            }
            
        case .modifiedAt:
            sorted = notes.sorted {
                options.sortOrder == .ascending ?
                $0.modifiedAt < $1.modifiedAt :
                $0.modifiedAt > $1.modifiedAt
            }
            
        case .tags:
            sorted = notes.sorted {
                options.sortOrder == .ascending ?
                $0.tags.count < $1.tags.count :
                $0.tags.count > $1.tags.count
            }
        }
        
        return sorted
    }
}

extension Note {
    var attachments: [String] {
        return []
    }
}

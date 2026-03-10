import SwiftUI

struct AdvancedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var query: String = ""
    @State private var selectedTags: [String] = []
    @State private var dateRange: DateRange = .all
    @State private var showPinnedOnly: Bool = false
    @State private var showFavoriteOnly: Bool = false
    @State private var sortBy: SortOption = .modifiedAt
    @State private var sortOrder: SortOrder = .descending
    
    @State private var searchResults: [Note] = []
    @State private var isSearching: Bool = false
    @State private var allTags: [String] = []
    
    private let searchService = ServiceLocator.shared.searchService
    
    enum DateRange: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case custom = "Custom"
    }
    
    enum SortOption: String, CaseIterable {
        case modifiedAt = "Date Modified"
        case createdAt = "Date Created"
        case title = "Title"
        case tags = "Tags"
    }
    
    enum SortOrder: String, CaseIterable {
        case ascending = "Ascending"
        case descending = "Descending"
    }
    
    var body: some View {
        NavigationView {
            List {
                searchSection
                filterSection
                dateRangeSection
                sortSection
                resultsSection
            }
            .navigationTitle("Advanced Search")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        performSearch()
                    }
                    .disabled(query.isEmpty && selectedTags.isEmpty)
                }
                #elseif os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Search") {
                        performSearch()
                    }
                    .disabled(query.isEmpty && selectedTags.isEmpty)
                }
                #endif
            }
            .task {
                await loadTags()
            }
        }
    }
    
    private var searchSection: some View {
        Section("Search") {
            TextField("Search notes...", text: $query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !query.isEmpty {
                Text("Searching for \"\(query)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var filterSection: some View {
        Section("Filters") {
            TagFilterView(
                selectedTags: $selectedTags,
                availableTags: allTags
            )
            
            Toggle("Pinned Only", isOn: $showPinnedOnly)
            Toggle("Favorite Only", isOn: $showFavoriteOnly)
        }
    }
    
    private var dateRangeSection: some View {
        Section("Date Range") {
            Picker("Date Range", selection: $dateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            
            if dateRange == .custom {
                DatePickerView()
            }
        }
    }
    
    private var sortSection: some View {
        Section("Sort") {
            Picker("Sort By", selection: $sortBy) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            
            Picker("Order", selection: $sortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
        }
    }
    
    private var resultsSection: some View {
        Section("Results (\(searchResults.count))") {
            if isSearching {
                ProgressView("Searching...")
            } else if searchResults.isEmpty {
                Text("No notes found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(searchResults) { note in
                    NavigationLink(destination: NoteEditorView(note: note)) {
                        NoteRowView(note: note)
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        isSearching = true
        
        Task {
            do {
                var options = SearchOptions(query: query)
                
                if !selectedTags.isEmpty {
                    options.filters.append(.tags(selectedTags))
                }
                
                if showPinnedOnly {
                    options.filters.append(.isPinned)
                }
                
                if showFavoriteOnly {
                    options.filters.append(.isFavorite)
                }
                
                let dateRange = getDateRange()
                if let range = dateRange {
                    options.filters.append(.dateRange(start: range.start, end: range.end))
                }
                
                options.sortBy = SearchOptions.SearchSortOption(rawValue: sortBy) ?? .modifiedAt
                options.sortOrder = SearchOptions.SearchSortOrder(rawValue: sortOrder) ?? .descending
                
                searchResults = try searchService.search(options: options)
            } catch {
                print("Search failed: \(error)")
            }
            
            isSearching = false
        }
    }
    
    private func loadTags() async {
        do {
            allTags = try searchService.getFrequentTags(limit: 100).map { $0.tag }
        } catch {
            print("Failed to load tags: \(error)")
        }
    }
    
    private func getDateRange() -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .all:
            return nil
            
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
            
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return (start, now)
            
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return (start, now)
            
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (start, now)
            
        case .custom:
            return nil
        }
    }
}

struct TagFilterView: View {
    @Binding var selectedTags: [String]
    let availableTags: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Tags")
                .font(.headline)
            
            FlowLayout {
                ForEach(availableTags, id: \.self) { tag in
                    SearchTagView(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        onTap: {
                            if selectedTags.contains(tag) {
                                selectedTags.removeAll { $0 == tag }
                            } else {
                                selectedTags.append(tag)
                            }
                        }
                    )
                }
            }
        }
    }
}

struct SearchTagView: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("#\(tag)")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentWidth + size.width > width {
                currentWidth = 0
                currentHeight += size.height + 8
            }
            
            currentWidth += size.width + 8
            height = max(height, currentHeight + size.height)
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += currentRowHeight + 8
                currentRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + 8
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

struct DatePickerView: View {
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            DatePicker("End Date", selection: $endDate, displayedComponents: .date)
        }
    }
}

extension SearchOptions.SearchSortOption {
    init?(rawValue: AdvancedSearchView.SortOption) {
        switch rawValue {
        case .title: self = .title
        case .createdAt: self = .createdAt
        case .modifiedAt: self = .modifiedAt
        case .tags: self = .tags
        }
    }
}

extension SearchOptions.SearchSortOrder {
    init?(rawValue: AdvancedSearchView.SortOrder) {
        switch rawValue {
        case .ascending: self = .ascending
        case .descending: self = .descending
        }
    }
}

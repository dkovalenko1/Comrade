import Foundation

final class TagsPickerViewModel {
    
    // Properties
    
    private let tagService: TagService
    
    private(set) var allTags: [TagEntity] = []
    private(set) var selectedTags: Set<TagEntity>
    
    // Outputs
    
    var onTagsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // Init
    
    init(selectedTags: [TagEntity] = [], tagService: TagService = .shared) {
        self.tagService = tagService
        self.selectedTags = Set(selectedTags)
        loadTags()
    }
    
    // Data Loading
    
    func loadTags() {
        allTags = tagService.fetchAllTags()
        onTagsUpdated?()
    }
    
    func tag(at index: Int) -> TagEntity? {
        guard index < allTags.count else { return nil }
        return allTags[index]
    }
    
    func isTagSelected(_ tag: TagEntity) -> Bool {
        return selectedTags.contains(tag)
    }
    
    // Selection
    
    func selectTag(at index: Int) {
        guard let tag = tag(at: index) else { return }
        selectedTags.insert(tag)
    }
    
    func deselectTag(at index: Int) {
        guard let tag = tag(at: index) else { return }
        selectedTags.remove(tag)
    }
    
    // CRUD
    
    func createTag(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Tag name is required")
            return
        }
        
        let colorHex = tagService.randomColorHex()
        if let newTag = tagService.createTag(name: trimmed, colorHex: colorHex) {
            selectedTags.insert(newTag)
            loadTags()
        } else {
            onError?("Tag with this name already exists")
        }
    }
    
    func updateTag(at index: Int, name: String) {
        guard let tag = tag(at: index) else { return }
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Tag name is required")
            return
        }
        
        tagService.updateTag(tag, name: trimmed)
        loadTags()
    }
    
    func deleteTag(at index: Int) {
        guard let tag = tag(at: index) else { return }
        selectedTags.remove(tag)
        tagService.deleteTag(tag)
        loadTags()
    }
    
    // Output Helpers
    
    var selectedTagsArray: [TagEntity] {
        return Array(selectedTags)
    }
}

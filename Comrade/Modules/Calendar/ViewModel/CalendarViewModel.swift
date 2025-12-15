import Foundation

final class CalendarViewModel {
    
    private let taskService = TaskService.shared
    
    private(set) var currentDate: Date = Date()
    private(set) var selectedDate: Date = Date()
    private(set) var mode: CalendarMode = .week
    
    private(set) var currentWeekDays: [Date] = []
    private(set) var currentMonthGrid: [Date?] = []
    
    private(set) var tasksForSelectedDate: [TaskEntity] = []
    
    private var deadlineDates: Set<String> = []
    
    private(set) var highPriorityTasks: [TaskEntity] = []
    private(set) var mediumPriorityTasks: [TaskEntity] = []
    private(set) var lowPriorityTasks: [TaskEntity] = []
    
    var onDateChanged: (() -> Void)?
    var onDataUpdated: (() -> Void)?
    
    init() {
        let today = Date()
        currentDate = today
        selectedDate = today
        
        refreshDeadlines()
        generateCalendarData()
        fetchTasks()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleTaskUpdates), name: .taskCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTaskUpdates), name: .taskUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTaskUpdates), name: .taskDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTaskUpdates), name: .taskCompleted, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleTaskUpdates() {
        refreshDeadlines()
        fetchTasks()
    }
    
    func switchMode(_ newMode: CalendarMode) {
        mode = newMode
        if mode == .week {
            currentDate = selectedDate
        }
        generateCalendarData()
        onDateChanged?()
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        if mode == .week {
            currentDate = date
        }
        fetchTasks()
        onDateChanged?()
    }
    
    func moveTime(direction: Int) {
        let calendar = Calendar.current
        if mode == .week {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: direction, to: currentDate) {
                currentDate = newDate
            }
        } else {
            if let newDate = calendar.date(byAdding: .month, value: direction, to: currentDate) {
                currentDate = newDate
            }
        }
        generateCalendarData()
        onDateChanged?()
    }
    
    func hasDeadline(on date: Date) -> Bool {
        let key = dateKey(for: date)
        return deadlineDates.contains(key)
    }
    
    private func refreshDeadlines() {
        let tasks = taskService.getActiveTasks()
        deadlineDates.removeAll()
        
        for task in tasks {
            if let deadline = task.deadline {
                deadlineDates.insert(dateKey(for: deadline))
            }
        }
        onDateChanged?()
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func generateCalendarData() {
        let calendar = Calendar.current
        
        var calendarWithLocale = Calendar.current
        calendarWithLocale.firstWeekday = 2
        
        var components = calendarWithLocale.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
        components.weekday = calendarWithLocale.firstWeekday
        let startOfWeek = calendarWithLocale.date(from: components)!
        
        currentWeekDays = (0...6).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek)
        }
        
        let range = calendar.range(of: .day, in: .month, for: currentDate)!
        let componentsMonth = calendar.dateComponents([.year, .month], from: currentDate)
        let startOfMonth = calendar.date(from: componentsMonth)!
        
        let firstDayWeekday = calendar.component(.weekday, from: startOfMonth)
        let paddingCount = (firstDayWeekday - calendarWithLocale.firstWeekday + 7) % 7
        
        var newGrid: [Date?] = []
        for _ in 0..<paddingCount { newGrid.append(nil) }
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                newGrid.append(date)
            }
        }
        currentMonthGrid = newGrid
    }
    
    private func fetchTasks() {
            let allTasks = taskService.getActiveTasks()
            let calendar = Calendar.current
            let startOfSelectedDate = calendar.startOfDay(for: selectedDate)
            let startOfToday = calendar.startOfDay(for: Date())
            
            var visibleTasks = allTasks.filter { task in
                guard let deadline = task.deadline else { return false }
                let startOfDeadline = calendar.startOfDay(for: deadline)
                
                if calendar.isDate(deadline, inSameDayAs: selectedDate) {
                    return true
                }
                
                if startOfDeadline < startOfSelectedDate && startOfSelectedDate <= startOfToday {
                    return true
                }
                
                return false
            }
            
            let timeSorter: (TaskEntity, TaskEntity) -> Bool = { t1, t2 in
                if t1.deadlineIsAllDay != t2.deadlineIsAllDay {
                    return t1.deadlineIsAllDay
                }
                guard let d1 = t1.deadline, let d2 = t2.deadline else { return false }
                return d1 < d2
            }
            
            tasksForSelectedDate = visibleTasks.sorted { t1, t2 in
                if t1.priority != t2.priority {
                    return t1.priority > t2.priority
                }
                return timeSorter(t1, t2)
            }
            
            highPriorityTasks = tasksForSelectedDate.filter { $0.priority == 2 }
            mediumPriorityTasks = tasksForSelectedDate.filter { $0.priority == 1 }
            lowPriorityTasks = tasksForSelectedDate.filter { $0.priority == 0 }
            
            onDataUpdated?()
        }
    
    var titleString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
}

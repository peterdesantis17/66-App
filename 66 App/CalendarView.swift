import SwiftUI

struct CalendarView: View {
    @StateObject private var habitService = HabitService.shared
    @State private var monthOffset: Int = 0
    @State private var completionHistory: [Date: Double] = [:]
    
    private let calendar = Calendar.current
    private let currentDate = Date()
    private let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Color for completion percentage
    private func colorForCompletion(_ completion: Double) -> Color {
        switch completion {
        case 0:
            Color.clear
        case 0..<0.5:
            Color.blue.opacity(0.3)
        case 0.5..<0.8:
            Color.blue.opacity(0.6)
        default:
            Color.blue.opacity(0.9)
        }
    }
    
    private var currentMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
    }
    
    private var displayedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: currentMonth) ?? currentMonth
    }
    
    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval)
    }
    
    private var firstWeekdayOfMonth: Int {
        let components = calendar.dateComponents([.weekday], from: displayedMonth)
        return components.weekday ?? 1
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month and year header with navigation
            HStack {
                Button(action: { monthOffset -= 1 }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                Spacer()
                Text(displayedMonth, formatter: monthFormatter)
                    .font(.title2)
                    .bold()
                Spacer()
                
                Button(action: { monthOffset += 1 }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            
            // Day of week header
            HStack {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 15) {
                // Empty cells for days before the first of the month
                ForEach(0..<firstWeekdayOfMonth-1, id: \.self) { _ in
                    Text("")
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                }
                
                // Day cells
                ForEach(Array(days.enumerated()), id: \.element) { _, date in
                    let isToday = calendar.isDate(date, inSameDayAs: currentDate)
                    let startOfDay = calendar.startOfDay(for: date)
                    let completion = completionHistory[startOfDay] ?? 0
                    
                    Text("\(calendar.component(.day, from: date))")
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .background(colorForCompletion(completion))
                        .clipShape(Circle())
                        .fontWeight(isToday ? .bold : .regular)
                }
            }
        }
        .padding()
        .task {
            await loadCompletionHistory()
        }
        .onChange(of: monthOffset) { _ in
            Task {
                await loadCompletionHistory()
            }
        }
    }
    
    private func loadCompletionHistory() async {
        do {
            let histories = try await habitService.getMonthCompletionHistory(for: displayedMonth)
            
            completionHistory = Dictionary(uniqueKeysWithValues: histories.map { history in
                let date = calendar.startOfDay(for: history.date)
                return (date, history.completionPercentage)
            })
        } catch {
            print("❌ Error loading completion history: \(error)")
        }
    }
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

// Helper extension
extension Calendar {
    func generateDates(for dateInterval: DateInterval, matching components: DateComponents = DateComponents(hour: 0, minute: 0, second: 0)) -> [Date] {
        var dates = [dateInterval.start]
        
        enumerateDates(startingAfter: dateInterval.start,
                      matching: components,
                      matchingPolicy: .nextTime) { date, _, stop in
            guard let date = date else { return }
            
            guard date < dateInterval.end else {
                stop = true
                return
            }
            
            dates.append(date)
        }
        
        return dates
    }
} 
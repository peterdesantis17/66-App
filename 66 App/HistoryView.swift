import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationView {
            VStack {
                CalendarView()
                    .padding()
                
                Spacer()
            }
            .navigationTitle("History")
        }
    }
} 
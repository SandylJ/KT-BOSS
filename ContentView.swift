import SwiftUI
import SwiftData
import HealthKit

struct ContentView: View {
    // MARK: - Environment & Queries
    
    // Get access to the SwiftData database context
    @Environment(\.modelContext) private var modelContext
    
    // Use @Query to fetch all non-completed tasks and keep the list updated automatically.
    // They are sorted by creation date, newest first.
    @Query(filter: #Predicate<Task> { !$0.isCompleted }, sort: \.creationDate, order: .reverse)
    private var tasks: [Task]
    
    // MARK: - State Properties
    
    // We will keep the HealthKitManager as an @StateObject
    @StateObject private var healthKitManager = HealthKitManager()
    
    // Other UI state can remain for now
    @State private var healthSyncMessage: String? = nil
    @State private var isSyncingHealthData = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                // The health sync view can remain as is for now.
                healthSyncView
                
                if tasks.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("No tasks for today!").font(.title2).bold()
                        Text("Add a new task to begin.").foregroundColor(.secondary)
                        // This button is for demonstration purposes to add sample data.
                        Button("Add Sample Task") {
                            addSampleTask()
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding()
                } else {
                    // The list now iterates over the tasks fetched from SwiftData
                    List {
                        ForEach(tasks) { task in
                            taskRow(task: task)
                        }
                        .onDelete(perform: deleteTask)
                    }
                }
            }
            .navigationTitle("Daily Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addSampleTask) {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
        }
        .onAppear {
            // HealthKit authorization request remains the same.
            healthKitManager.requestAuthorization { authorized in
                if !authorized {
                    healthSyncMessage = "Health App permission denied."
                }
            }
        }
    }
    
    // MARK: - UI Views
    
    private var healthSyncView: some View {
        VStack {
            Button(action: syncHealthData) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath.circle")
                    Text("Sync Health Data")
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSyncingHealthData ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isSyncingHealthData)
            .padding(.horizontal)
            
            if let message = healthSyncMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            healthSyncMessage = nil
                        }
                    }
            }
        }
        .padding(.vertical, 10)
    }
    
    // This view is updated to take a SwiftData `Task` object.
    private func taskRow(task: Task) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                Text("Stat: \(task.associatedStat.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                completeTask(task)
            }) {
                Image(systemName: "circle")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Logic & Functions
    
    // This function now creates and saves a new Task to SwiftData.
    private func addSampleTask() {
        withAnimation {
            let newTask = Task(
                title: "Read a chapter of a book",
                difficulty: .easy,
                associatedStat: .intellect
            )
            modelContext.insert(newTask)
        }
    }
    
    // This function now modifies the isCompleted property on the passed-in Task object.
    // SwiftData automatically saves the change.
    private func completeTask(_ task: Task) {
        withAnimation {
            task.isCompleted = true
            task.completionDate = .now
            
            // We will re-implement the XP and reward logic in the next step
            // using the new GameLogicManager.
            print("Completed task: \(task.title)")
        }
    }
    
    // This function handles deleting a task from the list.
    private func deleteTask(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tasks[index])
            }
        }
    }
    
    // HealthKit sync logic remains for now. We will connect it to the new models later.
    private func syncHealthData() {
        isSyncingHealthData = true
        healthSyncMessage = "Syncing..."
        
        // Placeholder for the HealthKit logic you already have.
        // In the future, this will fetch data and automatically complete
        // or create `Task` objects.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncingHealthData = false
            healthSyncMessage = "Health data synced successfully!"
        }
    }
}


// MARK: - Preview
// We update the preview to work with SwiftData.
#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}


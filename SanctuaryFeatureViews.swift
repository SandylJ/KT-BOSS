import SwiftUI
import SwiftData

// MARK: - Main Habit Garden View
// FIXED: Added 'public' so this view can be accessed from SanctuaryView
public struct HabitGardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var user: User
    
    private var plantableItemsInInventory: [InventoryItem] {
        user.inventory?.filter { ItemDatabase.shared.getItem(id: $0.itemID)?.itemType == .plantable } ?? []
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // --- Habit Garden Section ---
                SanctuarySectionView(
                    title: "Habit Garden",
                    itemCount: user.plantedHabitSeeds?.count ?? 0,
                    maxItems: 6,
                    emptyText: "Plant Habit Seeds from your pouch to gain passive bonuses!"
                ) {
                    ForEach(user.plantedHabitSeeds ?? []) { plantedSeed in
                        GardenPlotView(plantedItem: plantedSeed, user: user)
                    }
                }
                
                // --- Alchemist's Greenhouse Section ---
                SanctuarySectionView(
                    title: "Alchemist's Greenhouse",
                    itemCount: user.plantedCrops?.count ?? 0,
                    maxItems: 8,
                    emptyText: "Plant Crop Seeds to grow valuable crafting materials."
                ) {
                    ForEach(user.plantedCrops ?? []) { plantedCrop in
                        GardenPlotView(plantedItem: plantedCrop, user: user)
                    }
                }

                // --- Grove of Elders Section ---
                SanctuarySectionView(
                    title: "Grove of Elders",
                    itemCount: user.plantedTrees?.count ?? 0,
                    maxItems: 3,
                    emptyText: "Plant rare Tree Saplings for immense long-term rewards."
                ) {
                    ForEach(user.plantedTrees ?? []) { plantedTree in
                        GardenPlotView(plantedItem: plantedTree, user: user)
                    }
                }

                // --- Gardening Pouch Section ---
                Section {
                    if plantableItemsInInventory.isEmpty {
                        Text("Complete tasks to find seeds, crops, and saplings.").font(.caption).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(plantableItemsInInventory) { invItem in
                            PlantablePouchItemView(inventoryItem: invItem, user: user)
                        }
                    }
                } header: {
                    Text("Gardening Pouch").font(.title2).bold().padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("My Sanctuary")
    }
}

// MARK: - Reusable Views

struct SanctuarySectionView<Content: View>: View {
    let title: String
    let itemCount: Int
    let maxItems: Int
    let emptyText: String
    @ViewBuilder let content: Content

    var body: some View {
        Section {
            if itemCount == 0 {
                Text(emptyText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Material.thin)
                    .cornerRadius(10)
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    content
                }
                .padding(.horizontal)
            }
        } header: {
            Text("\(title) (\(itemCount)/\(maxItems))")
                .font(.title2).bold().padding([.horizontal, .top])
        }
    }
}

struct GardenPlotView: View {
    @Environment(\.modelContext) private var modelContext
    let plantedItem: any PersistentModel
    @Bindable var user: User
    
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let item: Item?
        let plantedAt: Date?
        
        if let seed = plantedItem as? PlantedHabitSeed {
            item = seed.seed
            plantedAt = seed.plantedAt
        } else if let crop = plantedItem as? PlantedCrop {
            item = crop.crop
            plantedAt = crop.plantedAt
        } else if let tree = plantedItem as? PlantedTree {
            item = tree.tree
            plantedAt = tree.plantedAt
        } else {
            item = nil
            plantedAt = nil
        }
        
        guard let validItem = item, let validPlantedAt = plantedAt, let growTime = validItem.growTime else {
            return AnyView(Text("Invalid Item"))
        }
        
        let timePassed = now.timeIntervalSince(validPlantedAt)
        let progress = min(timePassed / growTime, 1.0)
        let isReady = progress >= 1.0

        return AnyView(
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(rarityColor(for: validItem.rarity).opacity(0.2)).frame(width: 70, height: 70)
                    Image(systemName: validItem.icon).font(.largeTitle).foregroundColor(rarityColor(for: validItem.rarity))
                        .opacity(isReady ? 1.0 : 0.5 + (progress * 0.5))
                    if isReady { Image(systemName: "sparkles").foregroundColor(.yellow) }
                }
                Text(validItem.name).font(.caption).bold().lineLimit(2).multilineTextAlignment(.center)
                
                if isReady {
                    Button("Harvest") {
                        SanctuaryManager.shared.harvest(plantedItem: plantedItem, for: user, context: modelContext)
                    }
                    .buttonStyle(.borderedProminent).tint(.green).font(.caption)
                } else {
                    ProgressView(value: progress)
                    Text(timeRemaining(until: validPlantedAt.addingTimeInterval(growTime)))
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding().background(Material.regular).cornerRadius(15)
            .onReceive(timer) { newDate in self.now = newDate }
        )
    }
    
    private func timeRemaining(until date: Date) -> String {
        let remaining = date.timeIntervalSince(now)
        if remaining <= 0 { return "Ready!" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remaining) ?? "..."
    }
    
    private func rarityColor(for rarity: Item.Rarity) -> Color {
        switch rarity {
        case .common: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }
}

struct PlantablePouchItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var inventoryItem: InventoryItem
    @Bindable var user: User
    
    var body: some View {
        if let item = ItemDatabase.shared.getItem(id: inventoryItem.itemID) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: item.icon).font(.title).foregroundColor(rarityColor(for: item.rarity)).frame(width: 40)
                    VStack(alignment: .leading) {
                        Text("\(item.name) (x\(inventoryItem.quantity))").bold()
                        Text(item.description).font(.caption2).italic().foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                RewardDescriptionView(reward: item.harvestReward)
                
                Button("Plant") {
                    SanctuaryManager.shared.plantItem(itemID: item.id, for: user, context: modelContext)
                }
                .buttonStyle(.bordered).tint(rarityColor(for: item.rarity))
                .disabled(isGardenFull(for: item.plantableType) || inventoryItem.quantity <= 0)
                .frame(maxWidth: .infinity)
            }
            .padding().background(Material.thin).cornerRadius(10).padding(.horizontal)
        }
    }
    
    private func isGardenFull(for type: Item.PlantableType?) -> Bool {
        switch type {
        case .habitSeed: return (user.plantedHabitSeeds?.count ?? 0) >= 6
        case .crop: return (user.plantedCrops?.count ?? 0) >= 8
        case .treeSapling: return (user.plantedTrees?.count ?? 0) >= 3
        default: return true
        }
    }
    
    private func rarityColor(for rarity: Item.Rarity) -> Color {
        switch rarity {
        case .common: return .green
        case .rare: return .blue
        case .epic: return .purple
        }
    }
}

struct RewardDescriptionView: View {
    let reward: Item.HarvestReward?
    
    var body: some View {
        HStack {
            Text("Reward:").font(.caption).bold()
            if let reward = reward {
                switch reward {
                case .currency(let amount):
                    Text("\(amount) Gold").font(.caption).foregroundColor(.yellow)
                case .item(let id, let quantity):
                    if let item = ItemDatabase.shared.getItem(id: id) {
                        Text("\(item.name) x\(quantity)").font(.caption).foregroundColor(.blue)
                    }
                case .experienceBurst(let skill, let amount):
                    Text("+\(amount) \(skill.rawValue.capitalized) XP").font(.caption).foregroundColor(.purple)
                }
            } else {
                Text("None").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}


// MARK: - Other Sanctuary Views
// FIXED: Added 'public' to these views as well
public struct GuildHallView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var user: User
    
    private var availableRoles: [GuildMember.Role] {
        let hiredRoles = Set(user.guildMembers?.map { $0.role } ?? [])
        return GuildMember.Role.allCases.filter { !hiredRoles.contains($0) }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let guild = user.guild {
                    GuildProgressionView(guild: guild)
                }

                Section {
                    if user.guildMembers?.isEmpty ?? true {
                        ContentUnavailableView("Guild is Empty", systemImage: "person.3.slash", description: Text("Hire members from the list below."))
                    } else {
                        ForEach(user.guildMembers ?? []) { member in
                            GuildMemberCardView(member: member, user: user)
                        }
                    }
                } header: {
                    Text("Your Guild").font(.title2).bold().padding(.horizontal)
                }
                
                Section {
                    if availableRoles.isEmpty {
                         Text("All available roles have been hired.").font(.caption).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(availableRoles, id: \.self) { role in
                            HireableMemberCardView(role: role, user: user)
                        }
                    }
                } header: {
                    Text("Available for Hire").font(.title2).bold().padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Guild Hall")
    }
}

public struct ExpeditionBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var user: User
    
    @State private var showLaunchSheetFor: Expedition?
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Section {
                    if user.activeExpeditions?.isEmpty ?? true {
                        Text("No expeditions in progress.").font(.caption).foregroundColor(.secondary).padding()
                    } else {
                        ForEach(user.activeExpeditions ?? []) { activeExpedition in
                            ActiveExpeditionCardView(activeExpedition: activeExpedition)
                        }
                    }
                } header: {
                    Text("In Progress").font(.title2).bold().padding(.horizontal)
                }
                
                Section {
                    ForEach(ItemDatabase.shared.getAllExpeditions()) { expedition in
                        ExpeditionCardView(expedition: expedition, onPrepare: {
                            showLaunchSheetFor = expedition
                        })
                    }
                } header: {
                    Text("Available Expeditions").font(.title2).bold().padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Expedition Board")
        .sheet(item: $showLaunchSheetFor) { expedition in
            ExpeditionLaunchView(expedition: expedition, user: user)
        }
        .onAppear {
            GuildManager.shared.checkCompletedExpeditions(for: user, context: modelContext)
        }
    }
}

// MARK: - Subviews for Guild & Expedition
struct GuildMemberCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var member: GuildMember
    @Bindable var user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(member.name).font(.headline.bold())
                Text("(\(member.role.rawValue))").font(.headline).foregroundColor(.secondary)
                Spacer()
                Text("Lvl \(member.level)").font(.headline.bold())
            }
            
            Text(member.effectDescription()).font(.caption).italic()
            
            ProgressView(value: Double(member.xp % 100), total: 100)
                .padding(.vertical, 4)

            if member.isOnExpedition {
                Text("On Expedition").font(.caption).foregroundColor(.blue).bold()
            } else {
                Button("Upgrade (\(member.upgradeCost()) G)") {
                    GuildManager.shared.upgradeGuildMember(member: member, user: user, context: modelContext)
                }
                .buttonStyle(.bordered).tint(.blue)
                .disabled(user.currency < member.upgradeCost())
            }
        }
        .padding().background(Material.regular).cornerRadius(15).padding(.horizontal)
    }
}

struct HireableMemberCardView: View {
    @Environment(\.modelContext) private var modelContext
    let role: GuildMember.Role
    @Bindable var user: User
    
    var body: some View {
        let cost = 250
        let tempMember = GuildMember(name: "", role: role, owner: nil)
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Hire a \(role.rawValue)").font(.headline.bold())
            Text(tempMember.roleDescription).font(.caption).italic().foregroundColor(.secondary)
            
            Button("Hire (\(cost) G)") {
                GuildManager.shared.hireGuildMember(role: role, for: user, context: modelContext)
            }
            .buttonStyle(.borderedProminent).tint(.green)
            .disabled(user.currency < cost)
        }
        .padding().background(Material.regular).cornerRadius(15).padding(.horizontal)
    }
}

struct ExpeditionCardView: View {
    let expedition: Expedition
    var onPrepare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(expedition.name).font(.headline.bold())
            Text(expedition.description).font(.caption).italic()
            Button("Prepare Party", action: onPrepare)
                .buttonStyle(.borderedProminent).tint(.blue)
        }
        .padding().background(Material.regular).cornerRadius(15).padding(.horizontal)
    }
}

struct ActiveExpeditionCardView: View {
    @Bindable var activeExpedition: ActiveExpedition
    
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let expedition = activeExpedition.expedition {
                Text(expedition.name).font(.headline.bold())
                let progress = max(0, now.timeIntervalSince(activeExpedition.startTime)) / expedition.duration
                ProgressView(value: progress)
                Text("Returning in: \(timeRemaining(until: activeExpedition.endTime))")
                    .font(.caption)
            }
        }
        .padding().background(Material.regular).cornerRadius(15).padding(.horizontal)
        .onReceive(timer) { newDate in self.now = newDate }
    }
    
    private func timeRemaining(until date: Date) -> String {
        let remaining = date.timeIntervalSince(now)
        if remaining <= 0 { return "Any moment now..." }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remaining) ?? "..."
    }
}

struct ExpeditionLaunchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let expedition: Expedition
    @Bindable var user: User
    
    @State private var selectedMemberIDs = Set<UUID>()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text(expedition.name).font(.largeTitle.bold())
                
                let availableMembers = user.guildMembers?.filter { !$0.isOnExpedition } ?? []
                
                List(availableMembers) { member in
                    Button(action: { toggleSelection(member.id) }) {
                        HStack {
                            Image(systemName: selectedMemberIDs.contains(member.id) ? "checkmark.circle.fill" : "circle")
                            Text("\(member.name) (Lvl \(member.level) \(member.role.rawValue))")
                        }
                    }
                }
                
                Button("Launch Expedition") {
                    GuildManager.shared.launchExpedition(expeditionID: expedition.id, with: Array(selectedMemberIDs), for: user, context: modelContext)
                    dismiss()
                }
                .buttonStyle(JuicyButtonStyle())
                .disabled(!isPartyValid())
            }
            .padding()
            .navigationTitle("Form Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedMemberIDs.contains(id) {
            selectedMemberIDs.remove(id)
        } else {
            selectedMemberIDs.insert(id)
        }
    }
    
    private func isPartyValid() -> Bool {
        return selectedMemberIDs.count >= expedition.minMembers
    }
}

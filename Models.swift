import Foundation
import SwiftData

// MARK: - Supporting Enums & Structs

enum TaskDifficulty: String, Codable, CaseIterable { case trivial, easy, medium, hard, epic }
enum ChimeraStat: String, Codable, CaseIterable { case discipline, mindfulness, intellect, creativity, resilience }

enum SkillCategory: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case strength, mind, joy, vitality, awareness, flow, finance, other
}

enum GuildPerk: String, Codable, CaseIterable {
    case increasedGuildXp, reducedUpgradeCost, increasedBountyRewards

    var description: String {
        switch self {
        case .increasedGuildXp: return "+10% Guild XP from all sources"
        case .reducedUpgradeCost: return "-5% Gold cost for Guild Member upgrades"
        case .increasedBountyRewards: return "+10% Guild Seals from Bounties"
        }
    }
}

enum PermanentBonus: String, Codable {
    case xpBoost, newDailyQuest, buffDurationIncrease
    var description: String {
        switch self {
        case .xpBoost: return "+1% XP from all sources"
        case .newDailyQuest: return "Unlocks a new Daily Sanctuary Quest"
        case .buffDurationIncrease: return "All positive buffs last 10% longer"
        }
    }
}

enum QuestType: Codable {
    case milestone(category: SkillCategory, count: Int)
    case streak(category: SkillCategory, days: Int)
    case exploration(categories: [SkillCategory])
}

enum QuestStatus: String, Codable {
    case available, active, completed
}

enum LootReward: Codable, Hashable, Identifiable {
    var id: UUID { UUID() }
    case currency(Int)
    case item(id: String, quantity: Int)
    case experienceBurst(skill: SkillCategory, amount: Int)
    case runes(Int)
    case echoes(Double) // New case for Echoes
}

enum SpellEffect: Codable, Hashable {
    case doubleXP, doubleGold
}

struct Spell: Codable, Hashable, Identifiable {
    var id: String; let name: String; let description: String; let requiredLevel: Int; let runeCost: Int; let effect: SpellEffect
}

struct Recipe: Codable, Hashable, Identifiable {
    var id: String
    let craftedItemID: String
    let requiredMaterials: [String: Int]
    let requiredGold: Int
    var craftedItem: Item? { ItemDatabase.shared.getItem(id: craftedItemID) }
}

// --- NEW: Struct for the Shop System ---
struct TreasureChest: Codable, Hashable, Identifiable {
    var id: String
    let name: String
    let description: String
    let cost: Int
    let keyItemID: String? // e.g., "item_ancient_key"
    let rarity: Item.Rarity
    let icon: String
    let lootTable: [LootReward]
    let rewardCount: ClosedRange<Int> // e.g., 2...5 rewards
}


struct Item: Codable, Hashable, Identifiable {
    var id: String
    let name: String
    let description: String
    let itemType: ItemType
    let rarity: Rarity
    let icon: String
    let plantableType: PlantableType?
    let consumableEffect: ConsumableEffect?
    let growTime: TimeInterval?
    let harvestReward: HarvestReward?
    let slot: EquipmentSlot?
    let bonuses: [EquipmentBonus]?

    enum ItemType: String, Codable { case consumable, material, plantable, special, key, equippable } // Added 'equippable' type
    enum PlantableType: String, Codable { case habitSeed, crop, treeSapling }
    enum Rarity: String, Codable { case common, rare, epic }
    enum ConsumableEffect: Codable, Hashable { case experienceBurst(skill: ChimeraStat, amount: Int), refreshRandomTask }
    enum HarvestReward: Codable, Hashable {
        case currency(Int)
        case item(id: String, quantity: Int)
        case experienceBurst(skill: SkillCategory, amount: Int)
    }
}


enum EquipmentSlot: String, Codable, CaseIterable {
    case head, chest, hands, tool
}

struct EquipmentBonus: Codable, Hashable {
    let stat: ChimeraStat
    let value: Int
}


// MARK: - Core Data Models

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var username: String; var joinDate: Date; var level: Int; var totalXP: Int; var currency: Int
    var xpStrength: Int; var levelStrength: Int; var xpMind: Int; var levelMind: Int
    var xpJoy: Int; var levelJoy: Int; var xpVitality: Int; var levelVitality: Int
    var xpAwareness: Int; var levelAwareness: Int; var xpFlow: Int; var levelFlow: Int
    var willpower: Int = 0
    var currentStatueID: UUID?
    private var appliedBonusesData: Data = Data()
    var appliedBonuses: [PermanentBonus] {
        get { (try? JSONDecoder().decode([PermanentBonus].self, from: appliedBonusesData)) ?? [] }
        set { appliedBonusesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var runes: Int = 5
    var isDoubleXpNextTask: Bool = false
    private var unlockedSpellIDsData: Data = Data()
    var unlockedSpellIDs: [String] {
        get { (try? JSONDecoder().decode([String].self, from: unlockedSpellIDsData)) ?? [] }
        set { unlockedSpellIDsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    private var activeBuffsData: Data = Data()
    var activeBuffs: [SpellEffect: Date] {
        get { (try? JSONDecoder().decode([SpellEffect: Date].self, from: activeBuffsData)) ?? [:] }
        set { activeBuffsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    @Relationship(deleteRule: .cascade, inverse: \Chimera.owner) var chimera: Chimera?
    @Relationship(deleteRule: .cascade) var challenges: [WeeklyChallenge]?
    @Relationship(deleteRule: .cascade) var inventory: [InventoryItem]? = []
    @Relationship(deleteRule: .cascade) var plantedHabitSeeds: [PlantedHabitSeed]? = []
    @Relationship(deleteRule: .cascade) var plantedCrops: [PlantedCrop]? = []
    @Relationship(deleteRule: .cascade) var plantedTrees: [PlantedTree]? = []
    @Relationship(deleteRule: .cascade) var guildMembers: [GuildMember]? = []
    @Relationship(deleteRule: .cascade) var activeExpeditions: [ActiveExpedition]? = []
    @Relationship(deleteRule: .cascade) var statues: [Statue]? = []
    @Relationship(deleteRule: .cascade) var quests: [Quest]? = []
    @Relationship(deleteRule: .cascade) var guildBounties: [GuildBounty]? = []
    @Relationship(deleteRule: .cascade, inverse: \AltarOfWhispers.owner) var altarOfWhispers: AltarOfWhispers?

    private var equippedItemsData: Data = Data()
    var equippedItems: [EquipmentSlot: String] {
        get { (try? JSONDecoder().decode([EquipmentSlot: String].self, from: equippedItemsData)) ?? [:] }
        set { equippedItemsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    @Relationship(deleteRule: .cascade, inverse: \Guild.owner) var guild: Guild?
    var guildSeals: Int = 0


    init(username: String) {
        self.id = UUID(); self.username = username; self.joinDate = .now; self.level = 1
        self.totalXP = 0; self.currency = 100; self.xpStrength = 0; self.levelStrength = 1
        self.xpMind = 0; self.levelMind = 1; self.xpJoy = 0; self.levelJoy = 1
        self.xpVitality = 0; self.levelVitality = 1; self.xpAwareness = 0; self.levelAwareness = 1
        self.xpFlow = 0; self.levelFlow = 1; self.chimera = Chimera(owner: self)
        self.challenges = []; self.inventory = []; self.plantedHabitSeeds = []
        self.plantedCrops = []; self.plantedTrees = []; self.guildMembers = []
        self.activeExpeditions = []; self.willpower = 0; self.statues = []; self.quests = []
        self.runes = 5; self.isDoubleXpNextTask = false; self.unlockedSpellIDs = []; self.activeBuffs = [:]
        self.altarOfWhispers = nil
        self.guild = nil
        self.guildSeals = 0
    }
}

@Model
final class Guild {
    @Attribute(.unique) var id: UUID
    var level: Int
    var xp: Int
    private var unlockedPerksData: Data = Data()
    var unlockedPerks: [GuildPerk] {
        get { (try? JSONDecoder().decode([GuildPerk].self, from: unlockedPerksData)) ?? [] }
        set { unlockedPerksData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var owner: User?

    init(owner: User?) {
        self.id = UUID()
        self.level = 1
        self.xp = 0
        self.owner = owner
        self.unlockedPerks = []
    }

    var xpToNextLevel: Int {
        return level * 1000 // Simple scaling for now
    }
}

@Model
final class GuildBounty {
    @Attribute(.unique) var id: UUID
    var title: String
    var bountyDescription: String // Renamed from description
    var requiredProgress: Int
    var currentProgress: Int
    var guildXpReward: Int
    var guildSealReward: Int
    var isActive: Bool
    var owner: User?

    init(title: String, bountyDescription: String, requiredProgress: Int, guildXpReward: Int, guildSealReward: Int, owner: User?) { // Updated initializer
        self.id = UUID()
        self.title = title
        self.bountyDescription = bountyDescription
        self.requiredProgress = requiredProgress
        self.currentProgress = 0
        self.guildXpReward = guildXpReward
        self.guildSealReward = guildSealReward
        self.isActive = true
        self.owner = owner
    }
}

@Model
final class Quest {
    @Attribute(.unique) var id: UUID
    var title: String; var questDescription: String; var progress: Int; var lastProgressDate: Date?
    private var typeData: Data = Data(); private var rewardsData: Data = Data(); private var statusData: Data = Data()
    var type: QuestType {
        get { (try? JSONDecoder().decode(QuestType.self, from: typeData)) ?? .milestone(category: .other, count: 1) }
        set { typeData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var rewards: [LootReward] {
        get { (try? JSONDecoder().decode([LootReward].self, from: rewardsData)) ?? [] }
        set { rewardsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var status: QuestStatus {
        get {
            if let d = try? JSONDecoder().decode(QuestStatus.self, from: statusData) { return d }
            if let s = String(data: statusData, encoding: .utf8), let r = QuestStatus(rawValue: s) { return r }
            return .available
        }
        set { statusData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    var owner: User?
    init(id: UUID = UUID(), title: String, description: String, type: QuestType, rewards: [LootReward], owner: User?) {
        self.id = UUID(); self.title = title; self.questDescription = description; self.progress = 0
        self.lastProgressDate = nil; self.owner = owner; self.type = type; self.rewards = rewards; self.status = .available
    }
    var objectiveDescription: String {
        switch type {
        case .milestone(let c, let n): return "Complete \(n) \(c.rawValue.capitalized) tasks."
        case .streak(let c, let d): return "Complete a \(c.rawValue.capitalized) task for \(d) days in a row."
        case .exploration(let c): return "Complete a task from each of these categories: \(c.map { $0.rawValue.capitalized }.joined(separator: ", "))."
        }
    }
}

@Model
final class Statue {
    @Attribute(.unique) var id: UUID
    var name: String; var statueDescription: String; var requiredWillpower: Int
    var currentWillpower: Int; var reward: PermanentBonus; var owner: User?
    init(id: UUID = UUID(), name: String, description: String, requiredWillpower: Int, reward: PermanentBonus, owner: User?) {
        self.id = UUID(); self.name = name; self.statueDescription = description; self.requiredWillpower = requiredWillpower
        self.currentWillpower = 0; self.reward = reward; self.owner = owner
    }
    var progress: Double { requiredWillpower > 0 ? Double(currentWillpower) / Double(requiredWillpower) : 0 }
    var isComplete: Bool { currentWillpower >= requiredWillpower }
}

@Model
final class Chimera {
    @Attribute(.unique) var id: UUID; var name: String; var discipline: Int; var mindfulness: Int
    var intellect: Int; var creativity: Int; var resilience: Int; var headPartID: String
    var bodyPartID: String; var auraEffectID: String; var cosmeticHeadItemID: String; var owner: User?
    init(owner: User) {
        self.id = UUID(); self.name = "Chimera"; self.discipline = 0; self.mindfulness = 0
        self.intellect = 0; self.creativity = 0; self.resilience = 0; self.headPartID = "base_head_01"
        self.bodyPartID = "base_body_01"; self.auraEffectID = "none"; self.cosmeticHeadItemID = "none"; self.owner = owner
    }
}

@Model
final class Task {
    @Attribute(.unique) var id: UUID; var title: String; var details: String?; var creationDate: Date
    var dueDate: Date?; var isCompleted: Bool; var completionDate: Date?; var difficulty: TaskDifficulty
    var associatedStat: ChimeraStat
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parentTask) var subTasks: [SubTask]?
    init(title: String, details: String? = nil, dueDate: Date? = nil, difficulty: TaskDifficulty, associatedStat: ChimeraStat) {
        self.id = UUID(); self.title = title; self.details = details; self.creationDate = .now; self.dueDate = dueDate
        self.isCompleted = false; self.completionDate = nil; self.difficulty = difficulty; self.associatedStat = associatedStat
    }
}

@Model
final class SubTask {
    @Attribute(.unique) var id: UUID; var title: String; var isCompleted: Bool; var parentTask: Task?
    init(title: String) { self.id = UUID(); self.title = title; self.isCompleted = false }
}

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID; var date: Date; var moodRating: Int; var entryText: String; var promptUsed: String?
    init(date: Date, moodRating: Int, entryText: String, promptUsed: String?) {
        self.id = UUID(); self.date = date; self.moodRating = moodRating; self.entryText = entryText; self.promptUsed = promptUsed
    }
}

@Model
final class WeeklyChallenge {
    var id: UUID; var title: String; var challengeDescription: String; var progress: Int
    var goal: Int; var isJournalingChallenge: Bool; var statRequirement: ChimeraStat?
    var isCompleted: Bool { progress >= goal }
    init(id: UUID = UUID(), title: String, challengeDescription: String, progress: Int = 0, goal: Int, isJournalingChallenge: Bool = false, statRequirement: ChimeraStat? = nil) {
        self.id = id; self.title = title; self.challengeDescription = challengeDescription; self.progress = progress
        self.goal = goal; self.isJournalingChallenge = isJournalingChallenge; self.statRequirement = statRequirement
    }
}

@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID; var itemID: String; var quantity: Int; var owner: User?
    init(itemID: String, quantity: Int, owner: User?) {
        self.id = UUID(); self.itemID = itemID; self.quantity = quantity; self.owner = owner
    }
}

@Model
final class PlantedHabitSeed {
    @Attribute(.unique) var id: UUID; var seedID: String; var plantedAt: Date; var owner: User?
    var seed: Item? { ItemDatabase.shared.getItem(id: seedID) }
    init(seedID: String, plantedAt: Date, owner: User?) {
        self.id = UUID(); self.seedID = seedID; self.plantedAt = plantedAt; self.owner = owner
    }
}

@Model
final class PlantedCrop {
    @Attribute(.unique) var id: UUID; var cropID: String; var plantedAt: Date; var owner: User?
    var crop: Item? { ItemDatabase.shared.getItem(id: cropID) }
    init(cropID: String, plantedAt: Date, owner: User?) {
        self.id = UUID(); self.cropID = cropID; self.plantedAt = plantedAt; self.owner = owner
    }
}

@Model
final class PlantedTree {
    @Attribute(.unique) var id: UUID; var treeID: String; var plantedAt: Date; var owner: User?
    var tree: Item? { ItemDatabase.shared.getItem(id: treeID) }
    init(treeID: String, plantedAt: Date, owner: User?) {
        self.id = UUID(); self.treeID = treeID; self.plantedAt = plantedAt; self.owner = owner
    }
}

@Model
final class GuildMember {
    @Attribute(.unique) var id: UUID; var name: String; var role: Role; var level: Int
    var xp: Int; var isOnExpedition: Bool; var owner: User?
    enum Role: String, Codable, CaseIterable { case forager = "Forager", gardener = "Gardener", alchemist = "Alchemist", seer = "Seer", blacksmith = "Blacksmith" }
    init(name: String, role: Role, owner: User?) {
        self.id = UUID(); self.name = name; self.role = role; self.level = 1
        self.xp = 0; self.isOnExpedition = false; self.owner = owner
    }
    var roleDescription: String {
        switch self.role {
        case .forager: return "Passively finds seeds and materials over time."
        case .gardener: return "Automatically harvests ready plants from the Garden."
        case .alchemist: return "Periodically transmutes materials or brews simple potions."
        case .seer: return "Boosts the Altar of Whispers' Echo generation."
        case .blacksmith: return "Specializes in crafting and enhancing equipment."
        }
    }
    func effectDescription() -> String {
        switch self.role {
        case .forager: return "Finds an item every \(Int(3600 / Double(self.level))) seconds."
        case .gardener: return "Harvests have a \(self.level * 5)% chance to yield extra materials."
        case .alchemist: return "Every hour, has a \(self.level * 2)% chance to create a potion."
        case .seer: return "Increases Echo generation by \(self.level * 10)%."
        case .blacksmith: return "Can craft materials or enhance equipped items."
        }
    }
    func upgradeCost() -> Int { 100 * Int(pow(2.0, Double(self.level))) }
}

@Model
final class ActiveExpedition {
    @Attribute(.unique) var id: UUID; var expeditionID: String; var memberIDs: [UUID]; var startTime: Date; var owner: User?
    var expedition: Expedition? { ItemDatabase.shared.getExpedition(id: expeditionID) }
    var endTime: Date { guard let e = expedition else { return startTime }; return startTime.addingTimeInterval(e.duration) }
    init(expeditionID: String, memberIDs: [UUID], startTime: Date, owner: User?) {
        self.id = UUID(); self.expeditionID = expeditionID; self.memberIDs = memberIDs; self.startTime = startTime; self.owner = owner
    }
}

struct Expedition: Codable, Identifiable {
    var id: String; let name: String; let description: String; let duration: TimeInterval
    let minMembers: Int; let requiredRoles: [GuildMember.Role]?; let lootTable: [String: Int]; let xpReward: Int
}

@Model
final class AltarOfWhispers {
    @Attribute(.unique) var id: UUID
    var level: Int
    var echoes: Double
    var lastUpdated: Date
    var owner: User?

    // New upgrade levels
    var echoMultiplierLevel: Int
    var runeGenerationLevel: Int
    var goldGenerationLevel: Int

    init(owner: User?) {
        self.id = UUID()
        self.level = 1
        self.echoes = 0
        self.lastUpdated = Date()
        self.owner = owner
        
        // Initialize new properties
        self.echoMultiplierLevel = 1
        self.runeGenerationLevel = 0 // Start at 0, so the user has to buy the first level
        self.goldGenerationLevel = 0 // Start at 0
    }

    // --- COMPUTED PROPERTIES ---

    // Base Echoes per second from the main level
    var baseEchoesPerSecond: Double {
        return Double(level) * 0.1
    }

    // Echo multiplier from its own upgrade path
    var echoMultiplier: Double {
        return 1.0 + (Double(echoMultiplierLevel - 1) * 0.25) // +25% per level
    }
    
    // Total echoes per second
    var echoesPerSecond: Double {
        return baseEchoesPerSecond * echoMultiplier
    }

    // Runes generated per second
    var runesPerSecond: Double {
        return Double(runeGenerationLevel) * 0.001 // 1 rune every ~16 minutes at level 1
    }

    // Gold generated per second
    var goldPerSecond: Double {
        return Double(goldGenerationLevel) * 0.5 // 0.5 gold per second at level 1
    }

    // --- UPGRADE COSTS ---

    var upgradeCost: Double {
        return pow(10, Double(level))
    }
    
    var echoMultiplierUpgradeCost: Double {
        return pow(25, Double(echoMultiplierLevel))
    }

    var runeGenerationUpgradeCost: Double {
        return pow(100, Double(runeGenerationLevel + 1)) // Use +1 because it starts at 0
    }

    var goldGenerationUpgradeCost: Double {
        return pow(50, Double(goldGenerationLevel + 1)) // Use +1 because it starts at 0
    }
}
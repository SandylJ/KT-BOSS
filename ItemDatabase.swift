import Foundation

final class ItemDatabase {
    static let shared = ItemDatabase()

    private let items: [String: Item]
    private let expeditions: [String: Expedition]
    let masterStatueList: [Statue]
    let masterQuestList: [Quest]
    let masterSpellList: [Spell]
    let masterRecipeList: [Recipe]
    let masterChestList: [TreasureChest]

    private init() {
        self.items = Dictionary(uniqueKeysWithValues: ItemDatabase.createAllItems().map { ($0.id, $0) })
        self.expeditions = Dictionary(uniqueKeysWithValues: ItemDatabase.createAllExpeditions().map { ($0.id, $0) })
        self.masterStatueList = ItemDatabase.createAllStatues()
        self.masterQuestList = ItemDatabase.createAllQuests()
        self.masterSpellList = ItemDatabase.createAllSpells()
        self.masterRecipeList = ItemDatabase.createAllRecipes()
        self.masterChestList = ItemDatabase.createAllChests()
    }

    func getItem(id: String) -> Item? { items[id] }
    func getExpedition(id: String) -> Expedition? { expeditions[id] }
    func getAllPlantables() -> [Item] { items.values.filter { $0.itemType == .plantable } }
    func getAllExpeditions() -> [Expedition] { Array(expeditions.values) }

    // MARK: - Master Data Creation
    
    private static func createAllChests() -> [TreasureChest] {
        return [
            TreasureChest(id: "chest_common", name: "Common Chest", description: "Contains a few simple rewards.", cost: 250, keyItemID: nil, rarity: .common, icon: "shippingbox.fill", lootTable: [
                .currency(100), .item(id: "seed_vigor", quantity: 1), .item(id: "material_joyful_ember", quantity: 2)
            ], rewardCount: 1...2),
            TreasureChest(id: "chest_rare", name: "Rare Chest", description: "Contains valuable materials and a chance for rare seeds.", cost: 1000, keyItemID: nil, rarity: .rare, icon: "archivebox.fill", lootTable: [
                .currency(500), .item(id: "seed_clarity", quantity: 1), .item(id: "material_sunstone_shard", quantity: 1), .runes(1)
            ], rewardCount: 2...3),
            TreasureChest(id: "chest_ancient", name: "Ancient Chest", description: "A locked chest from a forgotten era. Requires a special key.", cost: 0, keyItemID: "item_ancient_key", rarity: .epic, icon: "treasurechest.fill", lootTable: [
                .currency(2000), .item(id: "seed_inspiration", quantity: 1), .item(id: "tree_ironwood", quantity: 1), .runes(5)
            ], rewardCount: 3...4)
        ]
    }
    
    private static func createAllRecipes() -> [Recipe] {
        return [
            Recipe(id: "recipe_elixir_strength", craftedItemID: "item_elixir_strength", requiredMaterials: ["item_potion_vigor": 2, "material_sunstone_shard": 1], requiredGold: 100),
            Recipe(id: "recipe_scroll_fortune", craftedItemID: "item_scroll_fortune", requiredMaterials: ["material_joyful_ember": 5, "material_essence": 2], requiredGold: 250)
        ]
    }
    
    private static func createAllSpells() -> [Spell] {
        return [
            Spell(id: "spell_surge_of_power", name: "Surge of Power", description: "Your next completed task grants double XP.", requiredLevel: 2, runeCost: 1, effect: .doubleXP),
            Spell(id: "spell_midas_touch", name: "Midas Touch", description: "For 10 minutes, all tasks grant double gold.", requiredLevel: 5, runeCost: 2, effect: .doubleGold)
        ]
    }
    
    private static func createAllQuests() -> [Quest] {
        return [
            Quest(title: "The First Step", description: "Begin your journey by completing a single Strength task.", type: .milestone(category: .strength, count: 1), rewards: [.currency(50), .experienceBurst(skill: .strength, amount: 25)], owner: nil),
            Quest(title: "A Studious Mind", description: "Knowledge is power. Complete 3 Mind tasks.", type: .milestone(category: .mind, count: 3), rewards: [.currency(100), .experienceBurst(skill: .mind, amount: 75)], owner: nil),
            Quest(title: "Joyful Beginnings", description: "Spread a little happiness by completing 3 Joy tasks.", type: .milestone(category: .joy, count: 3), rewards: [.item(id: "seed_serenity", quantity: 2)], owner: nil),
            Quest(title: "The Consistent Hero", description: "Form a habit by completing a Strength task for 3 days in a row.", type: .streak(category: .strength, days: 3), rewards: [.item(id: "seed_discipline", quantity: 1), .runes(1)], owner: nil),
            Quest(title: "Holistic Development", description: "Show your versatility by completing one task from Strength, Mind, and Joy.", type: .exploration(categories: [.strength, .mind, .joy]), rewards: [.experienceBurst(skill: .vitality, amount: 300), .item(id: "item_ancient_key", quantity: 1)], owner: nil)
        ]
    }
    
    private static func createAllStatues() -> [Statue] {
        return [
            Statue(name: "Statue of the Unwavering Hero", description: "A monument to sheer determination. Completing it grants a permanent boost to all XP gains.", requiredWillpower: 1000, reward: .xpBoost, owner: nil),
            Statue(name: "Statue of the Tireless Guardian", description: "A symbol of endless fortitude. Its completion unlocks a new daily quest slot.", requiredWillpower: 5000, reward: .newDailyQuest, owner: nil),
            Statue(name: "Statue of the Timeless Scholar", description: "A tribute to eternal knowledge. It makes all positive buffs last longer.", requiredWillpower: 10000, reward: .buffDurationIncrease, owner: nil)
        ]
    }
    
    private static func createAllEquipment() -> [Item] {
        return [
            // Head
            Item(id: "equip_leather_cowl", name: "Leather Cowl", description: "A simple leather cowl.", itemType: .equippable, rarity: .common, icon: "person.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .head, bonuses: [EquipmentBonus(stat: .resilience, value: 1)]),
            Item(id: "equip_iron_helmet", name: "Iron Helmet", description: "A sturdy iron helmet.", itemType: .equippable, rarity: .rare, icon: "person.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .head, bonuses: [EquipmentBonus(stat: .resilience, value: 3)]),

            // Chest
            Item(id: "equip_simple_robe", name: "Simple Robe", description: "A simple cloth robe.", itemType: .equippable, rarity: .common, icon: "person.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .chest, bonuses: [EquipmentBonus(stat: .mindfulness, value: 1)]),
            Item(id: "equip_scholars_robe", name: "Scholar's Robe", description: "A robe worn by scholars.", itemType: .equippable, rarity: .rare, icon: "person.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .chest, bonuses: [EquipmentBonus(stat: .intellect, value: 3)]),

            // Hands
            Item(id: "equip_leather_gloves", name: "Leather Gloves", description: "A pair of simple leather gloves.", itemType: .equippable, rarity: .common, icon: "person.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .hands, bonuses: [EquipmentBonus(stat: .creativity, value: 1)]),
            Item(id: "equip_gauntlets_of_strength", name: "Gauntlets of Strength", description: "Gauntlets that imbue the wearer with strength.", itemType: .equippable, rarity: .epic, icon: "person.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .hands, bonuses: [EquipmentBonus(stat: .discipline, value: 5)]),

            // Tool
            Item(id: "equip_rusty_axe", name: "Rusty Axe", description: "A rusty old axe.", itemType: .equippable, rarity: .common, icon: "hammer.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .tool, bonuses: [EquipmentBonus(stat: .discipline, value: 1)]),
            Item(id: "equip_masterwork_pickaxe", name: "Masterwork Pickaxe", description: "A pickaxe of exceptional quality.", itemType: .equippable, rarity: .epic, icon: "hammer.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: .tool, bonuses: [EquipmentBonus(stat: .discipline, value: 10)]),
        ]
    }

    private static func createAllItems() -> [Item] {
        var allItems: [Item] = []
        allItems.append(contentsOf: createAllEquipment())

        allItems.append(contentsOf: [
            // --- NEW: Key Item ---
            Item(id: "item_ancient_key", name: "Ancient Key", description: "A heavy, ornate key that hums with a faint energy. It seems destined for a special lock.", itemType: .key, rarity: .epic, icon: "key.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            
            // --- Potions (Consumables) ---
            Item(id: "item_potion_vigor", name: "Potion of Vigor", description: "A bubbling green liquid that grants a quick burst of energy.", itemType: .consumable, rarity: .common, icon: "testtube.2", plantableType: nil, consumableEffect: .experienceBurst(skill: .discipline, amount: 50), growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            Item(id: "item_elixir_strength", name: "Elixir of Strength", description: "A thick, red potion that courses through your veins with power.", itemType: .consumable, rarity: .rare, icon: "testtube.2", plantableType: nil, consumableEffect: .experienceBurst(skill: .discipline, amount: 150), growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            
            // --- Scrolls (Consumables) ---
            Item(id: "item_scroll_fortune", name: "Scroll of Fortune", description: "This scroll glitters with luck, increasing your chances of finding treasure.", itemType: .consumable, rarity: .rare, icon: "scroll.fill", plantableType: nil, consumableEffect: .refreshRandomTask, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),

            // --- Crafting Materials ---
            Item(id: "material_sunstone_shard", name: "Sunstone Shard", description: "A fragment that glows with the warmth of the sun.", itemType: .material, rarity: .rare, icon: "triangle.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            Item(id: "material_joyful_ember", name: "Joyful Ember", description: "A small, warm ember that crackles with happiness.", itemType: .material, rarity: .common, icon: "flame.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            
            // --- Existing Items ---
            Item(id: "seed_discipline", name: "Seed of Discipline", description: "Consistency in strength builds a foundation of discipline.", itemType: .plantable, rarity: .rare, icon: "flame.fill", plantableType: .habitSeed, consumableEffect: nil, growTime: 7200, harvestReward: .experienceBurst(skill: .strength, amount: 250), slot: nil, bonuses: nil),
            Item(id: "seed_clarity", name: "Seed of Clarity", description: "A focused mind can see through any illusion.", itemType: .plantable, rarity: .rare, icon: "brain.head.profile", plantableType: .habitSeed, consumableEffect: nil, growTime: 7200, harvestReward: .item(id: "material_essence", quantity: 1), slot: nil, bonuses: nil),
            Item(id: "seed_vigor", name: "Seed of Vigor", description: "Caring for the body yields boundless energy.", itemType: .plantable, rarity: .common, icon: "heart.fill", plantableType: .habitSeed, consumableEffect: nil, growTime: 3600, harvestReward: .experienceBurst(skill: .vitality, amount: 100), slot: nil, bonuses: nil),
            Item(id: "seed_serenity", name: "Seed of Serenity", description: "Joy cultivated daily blossoms into lasting peace.", itemType: .plantable, rarity: .common, icon: "face.smiling.fill", plantableType: .habitSeed, consumableEffect: nil, growTime: 3600, harvestReward: .experienceBurst(skill: .joy, amount: 200), slot: nil, bonuses: nil),
            Item(id: "seed_insight", name: "Seed of Insight", description: "Awareness of the self reveals hidden truths.", itemType: .plantable, rarity: .rare, icon: "eye.fill", plantableType: .habitSeed, consumableEffect: nil, growTime: 7200, harvestReward: .item(id: "material_dream_shard", quantity: 1), slot: nil, bonuses: nil),
            Item(id: "seed_inspiration", name: "Seed of Inspiration", description: "Moments of flow can spark brilliant ideas.", itemType: .plantable, rarity: .epic, icon: "wind", plantableType: .habitSeed, consumableEffect: nil, growTime: 14400, harvestReward: .currency(500), slot: nil, bonuses: nil),
            Item(id: "seed_prosperity", name: "Seed of Prosperity", description: "Financial diligence leads to future abundance.", itemType: .plantable, rarity: .common, icon: "dollarsign.circle.fill", plantableType: .habitSeed, consumableEffect: nil, growTime: 3600, harvestReward: .currency(500), slot: nil, bonuses: nil),
            Item(id: "seed_order", name: "Seed of Order", description: "Tidying your space also tidies your mind.", itemType: .plantable, rarity: .common, icon: "sparkles.square.filled.on.square", plantableType: .habitSeed, consumableEffect: nil, growTime: 3600, harvestReward: .experienceBurst(skill: .other, amount: 150), slot: nil, bonuses: nil),
            Item(id: "crop_sunwheat", name: "Sun-Kissed Wheat", description: "Basic wheat that grows quickly.", itemType: .plantable, rarity: .common, icon: "leaf.fill", plantableType: .crop, consumableEffect: nil, growTime: 1800, harvestReward: .item(id: "material_sunwheat_grain", quantity: 3), slot: nil, bonuses: nil),
            Item(id: "crop_glowcap", name: "Glowcap Mushroom", description: "A mushroom that faintly glows.", itemType: .plantable, rarity: .rare, icon: "circle.grid.3x3.fill", plantableType: .crop, consumableEffect: nil, growTime: 5400, harvestReward: .item(id: "material_glowcap_spore", quantity: 2), slot: nil, bonuses: nil),
            Item(id: "tree_ironwood", name: "Ironwood Sapling", description: "A slow-growing but incredibly resilient tree.", itemType: .plantable, rarity: .epic, icon: "tree.fill", plantableType: .treeSapling, consumableEffect: nil, growTime: 86400, harvestReward: .item(id: "material_ironwood_bark", quantity: 5), slot: nil, bonuses: nil),
            Item(id: "material_essence", name: "Focused Essence", description: "A crystalline fragment shimmering with pure mental energy.", itemType: .material, rarity: .common, icon: "sparkles", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            Item(id: "material_dream_shard", name: "Dream Shard", description: "A fragment of a forgotten dream, humming with potential.", itemType: .material, rarity: .rare, icon: "moon.stars.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            Item(id: "material_sunwheat_grain", name: "Sun-Kissed Grain", description: "A warm, golden grain of wheat.", itemType: .material, rarity: .common, icon: "leaf.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            Item(id: "material_glowcap_spore", name: "Glowcap Spore", description: "A faintly glowing mushroom spore.", itemType: .material, rarity: .rare, icon: "circle.grid.3x3.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
            Item(id: "material_ironwood_bark", name: "Ironwood Bark", description: "Remarkably tough bark from the legendary Ironwood tree.", itemType: .material, rarity: .epic, icon: "tree.fill", plantableType: nil, consumableEffect: nil, growTime: nil, harvestReward: nil, slot: nil, bonuses: nil),
        ])
        return allItems
    }

    private static func createAllExpeditions() -> [Expedition] {
        return [
            Expedition(id: "exp_whispering_woods", name: "Forage the Whispering Woods", description: "A simple journey to gather common materials.", duration: 3600, minMembers: 1, requiredRoles: [.forager], lootTable: ["material_essence": 80], xpReward: 50),
            Expedition(id: "exp_sunken_ruins", name: "Explore the Sunken Ruins", description: "A dangerous trek into ancient, waterlogged ruins.", duration: 14400, minMembers: 1, requiredRoles: [.alchemist], lootTable: ["material_dream_shard": 40], xpReward: 200)
        ]
    }
}
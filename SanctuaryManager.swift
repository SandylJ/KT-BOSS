import Foundation
import SwiftData

final class SanctuaryManager {
    static let shared = SanctuaryManager()
    private init() {}

    // MARK: - Garden Logic
    
    func plantItem(itemID: String, for user: User, context: ModelContext) {
        guard let itemToPlant = ItemDatabase.shared.getItem(id: itemID),
              let plantableType = itemToPlant.plantableType else { return }
        
        // Decrement item from inventory
        if let inventoryItem = user.inventory?.first(where: { $0.itemID == itemID }) {
            inventoryItem.quantity -= 1
            if inventoryItem.quantity <= 0 {
                context.delete(inventoryItem)
            }
        } else { return } // Can't plant if they don't have it
        
        // Add to the correct planted list
        switch plantableType {
        case .habitSeed:
            let newPlantedSeed = PlantedHabitSeed(seedID: itemID, plantedAt: .now, owner: user)
            user.plantedHabitSeeds?.append(newPlantedSeed)
        case .crop:
            let newPlantedCrop = PlantedCrop(cropID: itemID, plantedAt: .now, owner: user)
            user.plantedCrops?.append(newPlantedCrop)
        case .treeSapling:
            let newPlantedTree = PlantedTree(treeID: itemID, plantedAt: .now, owner: user)
            user.plantedTrees?.append(newPlantedTree)
        }
    }

    func harvest(plantedItem: any PersistentModel, for user: User, context: ModelContext) {
        var reward: Item.HarvestReward?
        
        // Determine the reward based on the type of item harvested
        if let seed = plantedItem as? PlantedHabitSeed {
            reward = seed.seed?.harvestReward
        } else if let crop = plantedItem as? PlantedCrop {
            reward = crop.crop?.harvestReward
        } else if let tree = plantedItem as? PlantedTree {
            reward = tree.tree?.harvestReward
        }
        
        // Grant the reward
        if let reward = reward {
            grantReward(reward, to: user, context: context)
        } else {
            user.currency += 10 // Fallback
        }
        
        // Delete the harvested item
        context.delete(plantedItem)
    }
    
    private func grantReward(_ reward: Item.HarvestReward, to user: User, context: ModelContext) {
        switch reward {
        case .currency(let amount):
            user.currency += amount
        case .item(let id, let quantity):
            if let inventoryItem = user.inventory?.first(where: { $0.itemID == id }) {
                inventoryItem.quantity += quantity
            } else {
                let newItem = InventoryItem(itemID: id, quantity: quantity, owner: user)
                user.inventory?.append(newItem)
            }
        case .experienceBurst(let skill, let amount):
            _ = GameLogicManager.shared.grantXP(to: skill, amount: amount, for: user)
        }
    }

    // MARK: - Guild & Expedition Logic (Unchanged)
    
    func hireGuildMember(role: GuildMember.Role, for user: User, context: ModelContext) {
        let hireCost = 250
        guard user.currency >= hireCost else { return }
        
        user.currency -= hireCost
        let newMember = GuildMember(name: "New \(role.rawValue)", role: role, owner: user)
        user.guildMembers?.append(newMember)
    }
    
    func upgradeGuildMember(member: GuildMember, user: User, context: ModelContext) {
        let cost = member.upgradeCost()
        guard user.currency >= cost else { return }
        
        user.currency -= cost
        member.level += 1
    }
    
    func launchExpedition(expeditionID: String, with memberIDs: [UUID], for user: User, context: ModelContext) {
        memberIDs.forEach { id in
            user.guildMembers?.first(where: { $0.id == id })?.isOnExpedition = true
        }
        
        let newExpedition = ActiveExpedition(expeditionID: expeditionID, memberIDs: memberIDs, startTime: .now, owner: user)
        user.activeExpeditions?.append(newExpedition)
    }
    
    func checkCompletedExpeditions(for user: User, context: ModelContext) {
        guard let expeditions = user.activeExpeditions, !expeditions.isEmpty else { return }
        
        let completedExpeditions = expeditions.filter { $0.endTime <= .now }
        
        for expedition in completedExpeditions {
            user.totalXP += expedition.expedition?.xpReward ?? 0
            user.currency += 100
            
            expedition.memberIDs.forEach { id in
                user.guildMembers?.first(where: { $0.id == id })?.isOnExpedition = false
            }
            
            context.delete(expedition)
        }
    }
}

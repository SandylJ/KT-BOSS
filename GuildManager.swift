
import Foundation
import SwiftData

final class GuildManager {
    static let shared = GuildManager()
    private init() {}

    func initializeGuild(for user: User, context: ModelContext) {
        guard user.guild == nil else { return }
        let newGuild = Guild(owner: user)
        context.insert(newGuild)
        user.guild = newGuild
    }

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

    // MARK: - Guild Progression

    func addGuildXP(_ amount: Int, for user: User) {
        guard let guild = user.guild else { return }
        guild.xp += amount
        checkGuildLevelUp(for: user)
    }

    private func checkGuildLevelUp(for user: User) {
        guard let guild = user.guild else { return }
        while guild.xp >= guild.xpToNextLevel {
            guild.xp -= guild.xpToNextLevel
            guild.level += 1
            // Unlock a random perk for now, can be more sophisticated later
            if let randomPerk = GuildPerk.allCases.randomElement() {
                guild.unlockedPerks.append(randomPerk)
            }
        }
    }

    // MARK: - Guild Bounties

    func generateDailyBounties(for user: User, context: ModelContext) {
        // For simplicity, generate 3 random bounties daily
        // In a real game, you'd have a master list of bounty templates
        guard user.guildBounties?.isEmpty ?? true else { return }

        for _ in 0..<3 {
            let newBounty = GuildBounty(
                title: "Defeat 5 Goblins",
                description: "Slay the pesky goblins infesting the forest.",
                requiredProgress: 5,
                guildXpReward: 100,
                guildSealReward: 10,
                owner: user
            )
            context.insert(newBounty)
            user.guildBounties?.append(newBounty)
        }
    }

    func completeBounty(bounty: GuildBounty, for user: User) {
        guard bounty.currentProgress >= bounty.requiredProgress else { return }
        bounty.isActive = false // Mark as completed
        addGuildXP(bounty.guildXpReward, for: user)
        user.guildSeals += bounty.guildSealReward
    }

    // MARK: - Blacksmith Logic

    func blacksmithCraftMaterial(for user: User, context: ModelContext) {
        // Example: Blacksmith passively crafts 'material_iron_ore'
        // This would be more complex with different materials and success rates
        if let ironOre = user.inventory?.first(where: { $0.itemID == "material_iron_ore" }) {
            ironOre.quantity += 1
        } else {
            let newItem = InventoryItem(itemID: "material_iron_ore", quantity: 1, owner: user)
            user.inventory?.append(newItem)
        }
    }

    func blacksmithEnhanceEquipment(item: InventoryItem, for user: User) {
        // Example: Blacksmith enhances an equipped item
        // This would involve modifying the item's bonuses directly or creating a new item
        // For simplicity, let's just say it increases a random stat on the item
        guard let equippedItem = ItemDatabase.shared.getItem(id: item.itemID), equippedItem.itemType == .equippable else { return }

        // This is a placeholder. Actual implementation would be more complex.
        print("Blacksmith enhanced \(equippedItem.name)!")
    }
}


import SwiftUI
import SwiftData

struct GuildMasterView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var user: User

    private var guild: Guild? { user.guild }
    private var activeBounties: [GuildBounty] { (user.guildBounties ?? []).filter { $0.isActive } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("The Guild Master")
                    .font(.largeTitle).bold()
                    .padding(.bottom, 5)

                Text("Welcome, \(user.username)! Our guild thrives on the dedication of its members. Take on these bounties to strengthen our ranks and earn valuable Guild Seals.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)

                if let guild = guild {
                    GuildProgressionView(guild: guild)
                }

                Section(header: Text("Guild Bounties").font(.title2).bold()) {
                    if activeBounties.isEmpty {
                        Text("No active bounties today. Check back tomorrow!")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(activeBounties) { bounty in
                            GuildBountyCardView(bounty: bounty, user: user)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Guild Master")
    }
}

struct GuildProgressionView: View {
    @Bindable var guild: Guild

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Guild Level: \(guild.level)")
                .font(.headline)
            ProgressView(value: Double(guild.xp), total: Double(guild.xpToNextLevel))
                .progressViewStyle(.linear)
            Text("\(guild.xp) / \(guild.xpToNextLevel) Guild XP")
                .font(.caption)
                .foregroundColor(.secondary)

            if !guild.unlockedPerks.isEmpty {
                Text("Unlocked Perks:")
                    .font(.headline)
                ForEach(guild.unlockedPerks, id: \.self) { perk in
                    Text("• \(perk.description)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct GuildBountyCardView: View {
    @Bindable var bounty: GuildBounty
    @Bindable var user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(bounty.title)
                .font(.headline)
            Text(bounty.bountyDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: Double(bounty.currentProgress), total: Double(bounty.requiredProgress))
            Text("Progress: \(bounty.currentProgress) / \(bounty.requiredProgress)")
                .font(.caption2)

            if bounty.currentProgress >= bounty.requiredProgress {
                Button("Claim Bounty") {
                    GuildManager.shared.completeBounty(bounty: bounty, for: user)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                Text("Rewards: \(bounty.guildXpReward) Guild XP, \(bounty.guildSealReward) Guild Seals")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(10)
    }
}

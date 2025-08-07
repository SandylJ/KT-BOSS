import SwiftUI
import Vortex

// This view displays a celebratory confetti effect.
struct LevelUpOverlay: View {
    @Binding var didLevelUp: Bool
    
    var body: some View {
        ZStack {
            if didLevelUp {
                VortexViewReader { proxy in
                    VortexView(.confetti) {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 16, height: 16)
                            .tag("square")
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 16)
                            .tag("circle")
                    }
                    .onAppear {
                        proxy.burst()
                        // Reset the state after a delay to hide the overlay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            didLevelUp = false
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false) // Allows taps to go through the overlay
            }
        }
    }
}

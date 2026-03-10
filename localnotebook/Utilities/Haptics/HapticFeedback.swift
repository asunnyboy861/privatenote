import Foundation
#if os(iOS)
import UIKit
#endif

final class HapticFeedback {
    static let shared = HapticFeedback()
    
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "hapticEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "hapticEnabled") }
    }
    
    private init() {}
    
    func playClick() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    func playMedium() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    func playHeavy() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    func playSuccess() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
    
    func playError() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        #endif
    }
    
    func playWarning() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #endif
    }
    
    func playSelection() {
        guard isEnabled else { return }
        
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
    
    func prepare() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).prepare()
        #endif
    }
}

import SwiftUI

extension View {
    func hapticClick() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                HapticFeedback.shared.playClick()
            }
        )
    }
    
    func hapticSuccess() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                HapticFeedback.shared.playSuccess()
            }
        )
    }
}

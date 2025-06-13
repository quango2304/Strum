//
//  DesignSystem.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color.accentColor
        static let secondary = Color.secondary
        static let background = Color(NSColor.controlBackgroundColor)
        static let surface = Color(NSColor.windowBackgroundColor)
        static let surfaceSecondary = Color(NSColor.controlBackgroundColor)
        static let border = Color(NSColor.separatorColor)
        static let overlay = Color.black.opacity(0.3)
        
        // Custom colors for enhanced UI
        static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.8)
        static let hoverBackground = Color.primary.opacity(0.08)
        static let activeBackground = Color.primary.opacity(0.12)
        static let shadowColor = Color.black.opacity(0.1)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Custom typography
        static let playerTitle = Font.system(size: 16, weight: .medium, design: .default)
        static let playerSubtitle = Font.system(size: 14, weight: .regular, design: .default)
        static let trackTitle = Font.system(size: 14, weight: .medium, design: .default)
        static let trackSubtitle = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.2)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isCompact: Bool
    
    init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .system(size: 14, weight: .medium) : .system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isCompact: Bool
    
    init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .system(size: 14, weight: .medium) : .system(size: 16, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let isActive: Bool
    
    init(size: CGFloat = 32, isActive: Bool = false) {
        self.size = size
        self.isActive = isActive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5))
            .foregroundColor(isActive ? .white : .primary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isActive ? Color.accentColor : DesignSystem.Colors.hoverBackground)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style
struct CardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.lg) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(color: DesignSystem.Shadow.light, radius: 2, x: 0, y: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.lg) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Toast Notification
struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isShowing: Bool
    
    enum ToastType {
        case success
        case error
        case info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 16, weight: .medium))
            
            Text(message)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.surface)
                .shadow(color: DesignSystem.Shadow.medium, radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastView.ToastType
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isShowing {
                ToastView(message: message, type: type, isShowing: $isShowing)
                    .zIndex(1000)
                    .padding(.top, DesignSystem.Spacing.lg)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, type: ToastView.ToastType = .success) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type))
    }
}

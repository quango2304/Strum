//
//  ToastView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI

// MARK: - Toast View

/**
 * Temporary notification view that appears at the top of the screen.
 * 
 * Toast notifications provide brief feedback to users about completed actions:
 * - Success messages (green) for successful operations
 * - Error messages (red) for failed operations
 * - Info messages (blue) for general information
 * - Warning messages (orange) for cautionary information
 * 
 * Features:
 * - Automatic dismissal after 3 seconds
 * - Smooth slide-in animation from the top
 * - Themed colors based on message type
 * - Appropriate icons for each message type
 * - Tap to dismiss functionality
 * 
 * The toast appears at the top of the screen and slides down with
 * a smooth animation, then automatically disappears after a delay.
 */
struct ToastView: View {
    // MARK: - Toast Type
    
    /**
     * Enumeration defining different types of toast notifications.
     * 
     * Each type has an associated color scheme and icon to provide
     * clear visual feedback about the nature of the message.
     */
    enum ToastType {
        /// Success notification (green) - for completed operations
        case success
        
        /// Error notification (red) - for failed operations
        case error
        
        /// Information notification (blue) - for general information
        case info
        
        /// Warning notification (orange) - for cautionary messages
        case warning
        
        /// The color associated with this toast type
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .info:
                return .blue
            case .warning:
                return .orange
            }
        }
        
        /// The SF Symbol icon associated with this toast type
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
    }
    
    // MARK: - Properties
    
    /// The message text to display
    let message: String
    
    /// The type of toast notification
    let type: ToastType
    
    /// Controls the visibility of the toast
    @Binding var isShowing: Bool

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon with type-specific color
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 16, weight: .medium))
            
            // Message text
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onTapGesture {
            // Allow manual dismissal by tapping
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowing = false
            }
        }
        .onAppear {
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - Toast Modifier

/**
 * View modifier for adding toast notification functionality to any view.
 * 
 * This modifier overlays a toast notification on top of the content
 * when the isShowing binding is true. The toast appears at the top
 * of the view with appropriate spacing and animations.
 */
struct ToastModifier: ViewModifier {
    /// Controls the visibility of the toast
    @Binding var isShowing: Bool
    
    /// The message text to display
    let message: String
    
    /// The type of toast notification
    let type: ToastView.ToastType
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isShowing {
                ToastView(message: message, type: type, isShowing: $isShowing)
                    .zIndex(1000) // Ensure toast appears above all other content
                    .padding(.top, DesignSystem.Spacing.lg)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

// MARK: - View Extension

/**
 * Extension to View providing convenient toast functionality.
 * 
 * This extension allows any SwiftUI view to easily display toast
 * notifications using a simple modifier syntax.
 */
extension View {
    /**
     * Adds toast notification capability to a view.
     * 
     * - Parameters:
     *   - isShowing: Binding that controls toast visibility
     *   - message: The message text to display
     *   - type: The type of toast notification (defaults to .success)
     * - Returns: A view with toast notification capability
     */
    func toast(isShowing: Binding<Bool>, message: String, type: ToastView.ToastType = .success) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ToastView(message: "Playlist created successfully", type: .success, isShowing: .constant(true))
        ToastView(message: "Failed to import file", type: .error, isShowing: .constant(true))
        ToastView(message: "Import completed", type: .info, isShowing: .constant(true))
        ToastView(message: "File format not supported", type: .warning, isShowing: .constant(true))
    }
    .padding()
}

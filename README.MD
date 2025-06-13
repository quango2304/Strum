# Strum Music Player

A beautiful, modern music player for macOS built with SwiftUI.

## ✨ Recent UI/UX Improvements

### 🎨 Comprehensive Color Theme System
- **10 Beautiful Themes**: Choose from Ocean Blue, Royal Purple, Forest Green, Sunset Orange, Cherry Red, Rose Pink, Tropical Teal, Deep Indigo, Fresh Mint, and Sky Cyan
- **App-Wide Theming**: Every UI element adapts to your chosen theme - backgrounds, surfaces, buttons, controls, and accents
- **Subtle & Beautiful**: Reasonable opacity levels and tasteful color blending that enhances without overwhelming
- **Live Preview**: See theme changes instantly throughout the entire app
- **Persistent Settings**: Your theme choice is saved and restored on app restart
- **Preferences Window**: Beautiful, dedicated preferences interface accessible via menu or ⌘,
- **Theme-Aware Components**: All buttons, surfaces, overlays, and interactive elements use themed colors
- **Gradient Accents**: Each theme features beautiful gradient color combinations
- **Smart Color Blending**: Backgrounds and surfaces receive subtle theme tints for cohesive appearance

### 🎨 Design System
- **Custom Design System**: Implemented a comprehensive design system with consistent colors, typography, spacing, and component styles
- **Enhanced Accent Color**: Beautiful gradient accent color that adapts to light/dark mode
- **Modern Typography**: Improved font hierarchy and sizing throughout the app
- **Consistent Spacing**: Standardized spacing and padding using design tokens

### 🎵 Player Controls
- **Redesigned Controls**: Modern circular buttons with hover states and animations
- **Enhanced Visual Hierarchy**: Better organization of play/pause, previous/next, shuffle, and repeat controls
- **Improved Album Art**: Added shadows and rounded corners for a more polished look
- **macOS Control Center Style Progress Bar**: Pill-shaped progress bar with perfect proportions (20px height)
- **macOS Control Center Style Volume Control**: Authentic Control Center design with gradient colors
- **Interactive Sliders**: Smooth drag interactions with proper bounds and visual feedback
- **Perfect Design Balance**: Track and thumb heights match for authentic macOS appearance
- **Responsive Design**: Controls adapt beautifully to both compact and desktop layouts

### 📋 Playlist Management
- **Beautiful Sidebar**: Improved playlist sidebar with better visual separation
- **Enhanced Add Button**: Modern circular add button with active states
- **Better Hover States**: Smooth animations and visual feedback on hover

### 🎼 Track List
- **Improved Track Rows**: Better spacing, typography, and hover effects
- **Enhanced Album Artwork**: Small thumbnails with shadows and rounded corners
- **Better Playing Indicators**: Clear visual indicators for currently playing tracks
- **Smooth Animations**: Subtle hover animations for better user experience

### 🔔 Toast Notifications
- **Success Notifications**: Beautiful toast notifications for successful imports
- **Multiple Types**: Support for success, error, and info notifications
- **Auto-dismiss**: Notifications automatically disappear after 3 seconds
- **Smooth Animations**: Elegant slide-in/out animations

### 💫 Popup Dialogs
- **Beautiful Popups**: Redesigned add playlist and import dialogs with modern styling
- **Blur Backgrounds**: Elegant overlay backgrounds with proper blur effects
- **Better Forms**: Improved text fields and button styling
- **Smooth Transitions**: Spring animations for popup appearance/dismissal

### 📱 Responsive Design
- **Adaptive Layout**: Maintains responsive design while improving visual polish
- **Touch-Friendly**: Larger touch areas for better usability
- **Consistent Experience**: Beautiful UI across all screen sizes

## 🚀 Features

- **Comprehensive Theme System**: Choose from 10 beautiful color themes that affect every UI element
- **App-Wide Color Coordination**: Backgrounds, surfaces, buttons, and controls all adapt to your theme
- **Preferences System**: Dedicated preferences window with live preview and theme selection
- **Playlist Management**: Create, delete, and organize your music playlists
- **Drag & Drop**: Import music by dragging files or folders
- **Responsive Design**: Adapts to different screen sizes while maintaining theme consistency
- **Modern UI**: Beautiful, polished interface with smooth animations and themed elements
- **Toast Notifications**: Visual feedback for user actions with themed styling
- **Keyboard Shortcuts**: Quick access to common functions (⌘, for preferences)

## 🎨 How to Customize Themes

1. **Via Menu**: Go to `Strum` → `Preferences...` in the menu bar
2. **Via Keyboard**: Press `⌘,` (Command + Comma)
3. **Choose Theme**: Click on any color theme in the preferences window
4. **Live Preview**: See changes instantly in the preview section
5. **Auto-Save**: Your theme choice is automatically saved

## 🎯 Available Themes

- **Ocean Blue**: Classic blue with cyan accents
- **Royal Purple**: Rich purple with pink gradients
- **Forest Green**: Natural green with mint highlights
- **Sunset Orange**: Warm orange with yellow tones
- **Cherry Red**: Bold red with pink accents
- **Rose Pink**: Soft pink with purple gradients
- **Tropical Teal**: Vibrant teal with cyan highlights
- **Deep Indigo**: Rich indigo with purple tones
- **Fresh Mint**: Cool mint with green accents
- **Sky Cyan**: Bright cyan with blue gradients

## 🎨 What Gets Themed

- **Backgrounds**: Main app background with subtle theme tints
- **Surfaces**: Sidebar, player controls, and track list headers
- **Buttons**: All player controls, add buttons, and interactive elements
- **Custom Sliders**: Beautiful gradient progress bars and volume controls
- **Progress Indicators**: Track progress with gradient fill and white thumb
- **Volume Controls**: Gradient volume slider with smart speaker icons
- **Hover States**: Interactive feedback with themed colors
- **Popup Dialogs**: Add playlist and import dialogs
- **Icons & Accents**: Currently playing indicators and gradients
- **Borders & Shadows**: Subtle themed borders and shadow effects

## 🎛️ macOS Control Center Style Controls

### Volume Control
- **macOS Style Design**: Pill-shaped track with same height as the circular thumb (20px)
- **Smart Speaker Icons**: Dynamic icons that change based on volume level (mute, low, medium, high)
- **Gradient Track**: Beautiful gradient fill that follows your theme colors
- **Click to Mute**: Click the speaker icon to quickly mute/unmute
- **Smooth Interactions**: Responsive drag and click interactions with proper thumb positioning

### Progress Bar
- **Control Center Style**: Full-height pill-shaped track matching macOS Control Center design
- **Gradient Progress**: Track progress with beautiful theme-colored gradients
- **Perfect Proportions**: 20px height track with 20px circular white thumb
- **Click to Seek**: Click anywhere on the track to jump to that position
- **Drag to Scrub**: Smooth dragging for precise seeking with proper bounds
- **Time Display**: Monospaced time labels for current and total duration

### Design Details
- **Consistent Heights**: Both track and thumb are 20px for perfect visual balance
- **Pill Shape**: Fully rounded corners (10px radius) for authentic macOS look
- **White Thumb**: Clean white circular indicator with subtle shadow
- **Proper Positioning**: Thumb stays within track bounds with accurate progress calculation
- **Theme Integration**: All gradient colors automatically adapt to your selected theme
- **Smooth Animations**: Subtle hover effects and drag feedback

## TODO:
- Fix thumbnail extraction for better album art display
- thumbnail animation
- allow to search tracks
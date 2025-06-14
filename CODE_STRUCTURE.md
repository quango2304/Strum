# Strum Code Structure Documentation

This document describes the refactored code structure of the Strum music player application, organized for better maintainability, readability, and scalability.

## 📁 Project Structure

```
Strum/
├── App/                          # Application entry point
│   └── StrumApp.swift           # Main app configuration and setup
├── Core/                        # Core business logic and data
│   ├── Models/                  # Data models and entities
│   │   ├── Track.swift         # Audio track model with metadata
│   │   ├── Playlist.swift      # Playlist model and operations
│   │   └── PlayerState.swift   # Player state enumerations
│   ├── Managers/               # Business logic managers
│   │   ├── PlaylistManager.swift      # Playlist CRUD and file import
│   │   ├── MusicPlayerManager.swift   # Audio playback management
│   │   ├── PreferencesManager.swift   # App settings and themes
│   │   └── IconManager.swift          # Dynamic app icon management
│   └── Extensions/             # Model extensions and utilities
│       └── Track+Extensions.swift     # Track formatting and utilities
├── UI/                         # User interface components
│   ├── Views/                  # Main application views
│   │   ├── ContentView.swift          # Primary app interface
│   │   ├── PlayerControlsView.swift   # Music player controls
│   │   ├── TrackListView.swift        # Track listing and management
│   │   └── PlaylistSidebar.swift      # Playlist navigation sidebar
│   ├── Popups/                 # Modal dialogs and popups
│   │   ├── PreferencesView.swift      # Settings and theme selection
│   │   ├── AboutView.swift            # About dialog
│   │   ├── AddPlaylistPopup.swift     # New playlist creation dialog
│   │   ├── EditPlaylistPopup.swift    # Playlist editing dialog
│   │   ├── ImportPopup.swift          # Music import options dialog
│   │   ├── PlaylistNamePopup.swift    # Playlist naming for file imports
│   │   ├── ProgressPopup.swift        # Import progress indicator
│   │   └── ToastView.swift            # Toast notifications
│   ├── Components/             # Reusable UI components (future)
│   └── DesignSystem/           # Design system and styling
│       └── DesignSystem.swift         # Colors, typography, spacing
├── Resources/                  # Application resources
│   ├── Assets.xcassets/        # Images, icons, and visual assets
│   └── Fonts/                  # Custom fonts (if any)
└── Supporting Files/           # Configuration and support files
    └── Strum.entitlements     # App sandbox and permissions
```

## 🏗️ Architecture Overview

### Core Layer
The Core layer contains the fundamental business logic and data management:

- **Models**: Pure data structures representing the app's entities
- **Managers**: Business logic controllers that handle operations and state
- **Extensions**: Utility methods and computed properties for models

### UI Layer
The UI layer handles all user interface concerns:

- **Views**: SwiftUI views that compose the main interface
- **Popups**: Modal dialogs and overlay interfaces
- **Components**: Reusable UI elements (planned for future expansion)
- **DesignSystem**: Centralized styling and theming system

### App Layer
Contains the application entry point and global configuration.

### Resources & Supporting Files
Static assets and configuration files needed for the application.

## 📋 Key Components

### Models

#### Track.swift
- Represents individual audio files with metadata
- Handles security-scoped bookmarks for sandboxed file access
- Supports multiple audio formats (MP3, FLAC, M4A, etc.)
- Includes artwork extraction and caching
- Provides file format and quality information

#### Playlist.swift
- Manages collections of tracks
- Supports CRUD operations (create, read, update, delete)
- Implements Codable for persistence
- Observable for SwiftUI data binding

#### PlayerState.swift
- Enumerations for player states (stopped, playing, paused)
- Shuffle and repeat mode definitions
- UI helper extensions for icons and descriptions

### Managers

#### PlaylistManager.swift
- Handles playlist creation, modification, and deletion
- Manages file and folder import operations
- Provides progress tracking for long-running imports
- Implements debounced saving for performance
- Handles security-scoped resource management

#### MusicPlayerManager.swift
- Controls audio playback using AVAudioPlayer
- Manages playlist navigation and track sequencing
- Implements shuffle and repeat functionality
- Integrates with macOS media controls and Now Playing
- Handles volume control and seeking

#### PreferencesManager.swift
- Manages application settings and preferences
- Handles color theme selection and persistence
- Coordinates with IconManager for dynamic icon updates
- Provides UI state management for popups

#### IconManager.swift
- Manages dynamic app icon changes based on themes
- Maps color themes to corresponding icon variants
- Provides icon preview functionality for preferences
- Uses singleton pattern for consistent management

### UI Components

#### ContentView.swift
- Main application interface with responsive design
- Coordinates between playlist management and music playback
- Handles popup and modal management
- Implements global keyboard shortcuts and ESC handling
- Adapts layout for different screen sizes

#### PlayerControlsView.swift
- Music player interface with playback controls
- Displays current track information and artwork
- Provides volume control and progress seeking
- Responsive design for compact and desktop layouts

#### TrackListView.swift
- Displays tracks in a playlist with metadata
- Supports drag-and-drop file import
- Implements search and filtering functionality
- Handles track selection and playback initiation

#### PlaylistSidebar.swift
- Navigation interface for playlist management
- Supports playlist creation, editing, and deletion
- Handles drag-and-drop for files and folders
- Provides import options and playlist selection

### Popup Components

#### AddPlaylistPopup.swift
- Modal dialog for creating new playlists
- Text input with validation and themed styling
- Keyboard shortcuts (Enter to save, Escape to cancel)
- Automatic text field focus and smooth animations

#### EditPlaylistPopup.swift
- Modal dialog for renaming existing playlists
- Pre-filled text input with current playlist name
- Themed pencil icon and gradient styling
- Input validation and keyboard shortcuts

#### ImportPopup.swift
- Modal dialog for selecting music import methods
- Two options: individual files or entire folders
- Clear descriptions and themed button styling
- Integration with PlaylistManager for import operations

#### PlaylistNamePopup.swift
- Modal dialog for naming playlists during file imports
- Displays count of pending files to be imported
- Creates new playlist and imports files on confirmation
- Used when dragging files without selecting a playlist

#### ProgressPopup.swift
- Non-dismissible progress indicator for file imports
- Real-time progress bar and file count display
- Current file name with truncation for long names
- Fixed dimensions to prevent layout shifts during updates

#### ToastView.swift
- Temporary notification system for user feedback
- Multiple types: success, error, info, warning
- Auto-dismissal after 3 seconds with manual tap option
- Smooth slide-in animation from top of screen

## 🎨 Design System

The DesignSystem.swift file provides:

- **Colors**: Themed color palettes with light/dark mode support
- **Typography**: Consistent font scales and custom text styles
- **Spacing**: Standardized spacing values for layouts
- **Corner Radius**: Consistent rounding for UI elements
- **Shadows**: Depth and elevation effects
- **Button Styles**: Reusable button styling components

## 🔧 Key Features

### Theme System
- Multiple color themes with dynamic app icon changes
- Consistent theming across all UI components
- Gradient effects and subtle background tints
- System accent color integration

### File Management
- Security-scoped bookmark support for sandboxed access
- Comprehensive metadata extraction from audio files
- Support for multiple audio formats including FLAC
- Artwork extraction and caching system

### Performance Optimizations
- Debounced saving to prevent excessive disk writes
- Background processing for file imports with progress tracking
- Efficient artwork caching to prevent repeated image creation
- Responsive UI updates during long-running operations

### User Experience
- Responsive design adapting to different screen sizes
- Global keyboard shortcuts and ESC key handling
- Toast notifications for user feedback
- Progress indicators for import operations
- Drag-and-drop support throughout the interface

## 📝 Code Quality

### Documentation
- Comprehensive inline documentation for all public APIs
- Clear method and property descriptions
- Usage examples and parameter explanations
- Architecture decision documentation

### Organization
- Logical separation of concerns across layers
- Consistent naming conventions
- Clear file and folder structure
- Minimal dependencies between components

### Maintainability
- Modular design enabling easy feature additions
- Centralized styling through the design system
- Clear separation between UI and business logic
- Extensible architecture for future enhancements

This refactored structure provides a solid foundation for continued development while maintaining code quality and developer productivity.

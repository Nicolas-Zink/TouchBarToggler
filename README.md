# TouchBar Toggler

A macOS menu bar application that allows toggling the Touch Bar on M1 MacBooks using a double-press of the Command key.

## Features

- Toggle Touch Bar with double Command key press
- Menu bar icon indicating Touch Bar status
- Simple interface with minimal UI
- Menu bar icon shows current state (filled = disabled, outline = enabled)

## Requirements

- MacBook with Touch Bar (M1/M2)
- macOS 12.0 or later
- System Integrity Protection (SIP) must be disabled

## Installation

1. Download the latest release or build from source
2. Move the app to your Applications folder
3. Launch the app
4. Grant Accessibility permissions when prompted

## Building from Source

1. Clone this repository
2. Open in Xcode
3. Build the project (Product > Build)
4. Find the app in Products folder
5. Move to Applications

## Disabling SIP

The app requires SIP to be disabled:

1. Restart your Mac
2. Hold Power button during startup
3. Open Terminal from Utilities menu
4. Run: `csrutil disable`
5. Restart your Mac

## Usage

- Double-press Command key to toggle Touch Bar
- Click menu bar icon for additional options
- Command icon indicates current Touch Bar state:
  - Outline icon = Touch Bar enabled
  - Filled icon = Touch Bar disabled

## Security Note

This application requires SIP to be disabled as it modifies system settings to control the Touch Bar. Only disable SIP if you understand the security implications.

## License

MIT License

## Acknowledgments

Created for the M1 MacBook community to provide better control over the Touch Bar experience.

# UltimateLoot

**Ultimate loot management system for World of Warcraft 3.3.5a**

UltimateLoot is an intelligent addon that automates loot decisions while providing comprehensive statistics and analytics. Evolved from the AutoPass addon, it offers advanced roll tracking, context-aware settings, and detailed insights into your loot behavior.

## Features

### 🎯 Intelligent Loot Management
- **Quality-based thresholds**: Automatically handle loot up to specified quality levels
- **Pass on All mode**: Override all rules for specific situations
- **Smart item rules**: Custom handling for specific items
- **Real-time notifications**: Know when and why decisions were made

### 📊 Comprehensive Analytics
- **Individual roll tracking**: Pass, Need, and Greed/Disenchant statistics
- **Quality breakdowns**: See patterns across item qualities
- **Time-based analysis**: Track behavior over different periods
- **Top items tracking**: Identify most frequently encountered items

### 🎮 User-Friendly Interface
- **Tabbed interface**: Statistics, Items, History, and Settings
- **Graph visualizations**: Visual representation of your loot patterns
- **Minimap integration**: Quick access and status monitoring
- **Debug tools**: Comprehensive testing and troubleshooting

### ⚙️ Advanced Configuration
- **Profile management**: Character-specific settings
- **Data export/import**: Backup and share your statistics
- **Slash commands**: Quick configuration via chat
- **Ace3 integration**: Professional addon framework

## Installation

1. Download the latest release from the [Releases](../../releases) page
2. Extract to your `Interface/AddOns/` directory
3. Restart World of Warcraft
4. Configure via `/ultimateloot` or `/ul` commands

## Quick Start

1. **Enable the addon**: `/ul enable`
2. **Set quality threshold**: `/ul threshold rare` (handles Uncommon automatically, asks for Rare+)
3. **Open interface**: `/ul show` or click the minimap icon
4. **View statistics**: Check the Statistics tab to see your roll patterns

## Commands

- `/ultimateloot` or `/ul` - Main command help
- `/ul enable|disable` - Toggle addon functionality
- `/ul show` - Open the main interface
- `/ul threshold <quality>` - Set quality threshold
- `/ul passall` - Toggle Pass on All mode
- `/ul stats` - Show quick statistics
- `/ul debug` - Debug mode toggle

## Quality Thresholds

**Note**: This addon only handles Uncommon (Green) and higher quality items.
- **Uncommon** (Green) - Quest rewards, low-level gear
- **Rare** (Blue) - Dungeon drops, crafted items
- **Epic** (Purple) - Raid gear, high-end items
- **Legendary** (Orange) - Extremely rare artifacts

## Configuration

The addon provides extensive configuration options:

- **Loot Quality Threshold**: Automatically handle items up to this quality
- **Pass on All**: Emergency override to pass on everything  
- **Smart Disenchanting**: When items would be passed, automatically disenchant if possible (unless "Pass on All" is active)
- **Notifications**: Toggle roll decision messages
- **Minimap Icon**: Show/hide minimap button
- **Debug Mode**: Enable advanced debugging and testing tools

## Data Management

- **Export**: Save your statistics to share or backup
- **Clear Data**: Reset all tracking data
- **History Limit**: Configure how many entries to keep (default: 1000)
- **Profile Switching**: Character-specific settings

## Development

UltimateLoot is built using the Ace3 framework and follows WoW addon best practices:

- **Modular architecture**: Clean separation of concerns
- **Event-driven**: Efficient resource usage
- **Localization ready**: English and German included
- **Extensible**: Easy to add new features

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## Support

- **Issues**: Report bugs via GitHub Issues
- **Discord**: Join our community (link TBD)
- **Forum**: Warmane forums (link TBD)

## License

This project is open source. See LICENSE file for details.

## Credits

- **Original Author**: Hunterrion (Warmane)
- **Framework**: Ace3 addon framework
- **Community**: Thanks to all testers and feedback providers

---

*Compatible with World of Warcraft 3.3.5a (Wrath of the Lich King)* 
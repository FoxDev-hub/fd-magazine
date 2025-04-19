# FoxDev-Magazine

An interactive magazine system for FiveM servers using the QB-Core/Qbox framework. Create, edit, and read digital magazines in-game with a modern and intuitive interface. Support for multiple editions and player-specific magazine ownership.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)
![QB-Core](https://img.shields.io/badge/qb--core-latest-red)
![QBox](https://img.shields.io/badge/QBox-March%202025-purple)

## 🌟 Features

- **Interactive Reading Experience**
  - Smooth page-turning animations
  - Zoom functionality for detailed viewing
  - Keyboard and mouse navigation
  - Fade-in animations

- **Magazine Editor**
  - Multiple edition support
  - Add/remove pages per edition
  - Reorder pages via drag-and-drop
  - Image URL support
  - Real-time preview
  - Edition publishing system

- **Player Magazine System**
  - Player-specific magazine ownership
  - Edition tracking
  - Purchase history
  - OX Inventory integration

- **Database Integration**
  - Multiple edition support
  - Automatic page ordering
  - Player ownership tracking
  - Edition status management

## 📋 Requirements

- QB-Core Framework
- QBox

## 📦 Installation

1. Download the resource
2. Place it in your resources folder, **The root folder has to be called "fd-magazine"
3. Add `ensure fd-magazine` to your server.cfg
4. Import the SQL file
5. Configure the resource in `config.lua`

## 🛠️ Inventory Setup

### For QB-Inventory (qb-core/shared/items.lua)
```lua
['magazine'] = {
    ['name'] = 'magazine',
    ['label'] = 'Los Santos Magazine',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'magazine.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'A glossy magazine about Los Santos life'
}
```

### For ox_inventory (ox_inventory/data/items.lua)
```lua
['magazine'] = {
    label = 'Magazine',
    weight = 500,
    stack = false,
    close = false,
    description = 'A readable magazine',
    consume = 0,
    client = {
        export = 'fd-magazine.useMagazine'
    }
}
```

## 🔧 Configuration

Edit `config.lua` to customize

-- Jobs that can access the editor
Config.AuthorizedJobs = {
    ['news'] = true,
    ['admin'] = true
}
```

## 🎮 Usage

### Reading a Magazine
1. Purchase or receive a magazine edition
2. Use the magazine item from inventory
3. Navigate using:
   - Arrow keys (← →)
   - Mouse clicks on page corners
   - Navigation buttons
4. Press ESC to close

### Editing a Magazine
1. Select or create an edition
2. Add pages via URL input
3. Drag & drop to reorder
4. Save changes
5. Publish when ready

## 🖼️ Image Guidelines

- **Recommended Format**: JPG/PNG
- **Optimal Resolution**: 1920x1080
- **Maximum File Size**: 5MB
- **Aspect Ratio**: 16:9 (recommended)

## 🔍 Troubleshooting

1. **Images Not Loading**
   - Verify URL is accessible
   - Check image format
   - Ensure URL is HTTPS

2. **Editor Not Opening**
   - Verify job permissions
   - Check server console for errors

3. **Database Issues**
   - Verify oxmysql is running
   - Check table relationships
   - Verify edition exists before adding pages

4. **Edition Access Issues**
   - Check if edition is published
   - Verify player ownership
   - Check edition status (active/inactive)

## 🛠️ Development

### Database Structure
```sql
magazine_editions
- id (AUTO_INCREMENT)
- edition_number (UNIQUE)
- title
- is_active
- is_published
- created_at

magazine_pages
- id (AUTO_INCREMENT)
- page_number
- image_url
- edition_number (FK)
- created_at

```

### File Structure
```
qb-magazine/
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── html/
│   ├── index.html
│   ├── style.css
│   └── script.min.js
├── sql/
│   └── magazine.sql
├── config.lua
└── fxmanifest.lua
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

- Discord: [https://discord.gg/ASTjxYZqVP]

## 🙏 Credits

- FoxDev

## 🔄 Updates

Check [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

Made with ❤️ for the FiveM Community 
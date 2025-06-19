# FD-Magazine

An interactive magazine system for FiveM servers supporting both QB-Core and ESX frameworks. Create, edit, and read digital magazines in-game with a modern and intuitive interface. Support for multiple editions and player-specific magazine ownership.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Version](https://img.shields.io/badge/version-1.1.0-green.svg)
![QB-Core](https://img.shields.io/badge/qb--core-latest-red)
![ESX](https://img.shields.io/badge/ESX-Legacy-blue)
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
  - Multiple inventory system support (OX, QB, QS, QX)

- **Database Integration**
  - Multiple edition support
  - Automatic page ordering
  - Player ownership tracking
  - Edition status management

- **Framework Support**
  - QB-Core Framework
  - ESX Legacy Framework
  - Automatic framework detection

## 📋 Requirements

- QB-Core Framework **OR** ESX Legacy Framework
- oxmysql
- One of the following inventory systems:
  - ox_inventory (recommended)
  - QB-Core inventory
  - QS-Inventory
  - QX-Inventory
- FiveM Server

## ⚙️ Installation

1. **Download & Place Files**
   ```bash
   cd resources
   git clone https://github.com/yourusername/fd-magazine
   ```

2. **Database Setup**
   The resource uses two main tables:
   - `magazine_editions`: Stores different magazine editions
   - `magazine_pages`: Stores pages for each edition

   Import the SQL file from `sql/magazine.sql` which will create all necessary tables and indexes.

3. **Add to Server.cfg**
   ```lua
   ensure oxmysql  # Make sure this loads first
   ensure fd-magazine
   ```

4. **Framework Configuration**
   Edit `config.lua` and set your framework:
   ```lua
   Config.Framework = 'esx'  -- or 'qb' for QB-Core
   ```

5. **Inventory Setup**

   **For OX Inventory:**
   Add to your `ox_inventory/data/items.lua`:
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

   **For QB-Core Inventory:**
   Add to your `qb-core/shared/items.lua`:
   ```lua
   ['magazine'] = {
       name = 'magazine',
       label = 'Magazine',
       weight = 500,
       type = 'item',
       image = 'magazine.png',
       unique = false,
       useable = true,
       shouldClose = false,
       combinable = nil,
       description = 'A readable magazine'
   }
   ```

   **For ESX with ox_inventory:**
   The item will be automatically registered when using ESX with ox_inventory.

## 🔧 Configuration

Edit `config.lua` to customize:

```lua
Config = {}

-- Framework selection ('qb' or 'esx')
Config.Framework = 'esx'

-- Inventory system ('qb', 'ox', 'qs', 'qx')
Config.InventoryType = 'ox'

-- Jobs that can access the editor
Config.AuthorizedJobs = {
    ['news'] = true,
    ['admin'] = true,
    ['unemployed'] = true  -- for testing
}

-- Magazine settings
Config.Magazine = {
    price = 25,
    weight = 500,
    maxPages = 20
}

-- Image Settings
Config.MaxImageSize = 5 * 1024 * 1024  -- 5MB
Config.AllowedImageTypes = {
    'jpg',
    'jpeg',
    'png',
    'gif'
}
```

## 📱 Commands

- `/magazine` - Open owned magazine editions
- `/magazineeditor` - Open editor (authorized jobs only)
- `/createedition [title]` - Create new edition
- `/publishedition [number]` - Publish an edition

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
1. Use `/magazineeditor` command
2. Select or create an edition
3. Add pages via URL input
4. Drag & drop to reorder
5. Save changes
6. Publish when ready

### Managing Editions
1. Create new editions with `/createedition`
2. Add pages to specific editions
3. Set active status
4. Publish when ready
5. Track player ownership

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
   - Ensure framework is properly configured

3. **Database Issues**
   - Verify oxmysql is running
   - Check table relationships
   - Verify edition exists before adding pages

4. **Framework Detection Issues**
   - Check if ESX/QB-Core is properly loaded
   - Verify framework configuration in config.lua
   - Check server console for framework detection messages

5. **Inventory Integration Issues**
   - Verify inventory system configuration
   - Check if item is properly registered
   - Ensure inventory exports are available

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
fd-magazine/
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── html/
│   ├── index.html
│   ├── style.css
│   ├── script.js
│   └── magnifier.css
├── sql/
│   └── magazine.sql
├── config.lua
├── fxmanifest.lua
└── README.md
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

- Discord: [Your Discord Server]
- GitHub Issues: [Repository Issues]
- Documentation: [Wiki Link]

## 🙏 Credits

- QB-Core Framework Team
- ESX Legacy Team
- Turn.js Library
- FiveM Community

## 🔄 Updates

Check [CHANGELOG.md](CHANGELOG.md) for version history and updates.

---

Made with ❤️ for the FiveM Community 
Config = {}

-- Inventory system: 'qb', 'ox', or 'qx'
Config.InventoryType = 'qb'

-- Target system: 'qb' or 'ox' or 'marker'
Config.TargetSystem = 'qb'

-- Edit location
Config.EditLocation = vector3(-1058.06, -248.11, 44.02)

-- Authorized jobs that can edit the magazine
Config.AuthorizedJobs = {
    ['journalist'] = true,
    ['reporter'] = true,
    ['news'] = true
}

-- Magazine settings
Config.Magazine = {
    price = 25,
    weight = 500,
    maxPages = 20,
    slot = 8,
    enableBuyFromProps = true, -- Enable/disable buying magazines from newsstands
    animation = {
        dict = "missheistdockssetup1clipboard@base", -- Animation dictionary
        name = "base" -- Animation name
    }
}

-- Newsstand Props
Config.NewstandProps = {
    "prop_news_disp_02a_s",
    "prop_news_disp_02c",
    "prop_news_disp_05a",
    "prop_news_disp_02e",
    "prop_news_disp_03c",
    "prop_news_disp_06a",
    "prop_news_disp_02a",
    "prop_news_disp_02d",
    "prop_news_disp_02b",
    "prop_news_disp_01a",
    "prop_news_disp_03a"
}

-- Theme settings
Config.Theme = {
    darkMode = false, -- true for dark mode, false for light mode
    useCustomColors = false, -- Set to true to use custom colors below
    colors = {
        -- Dark mode colors
        dark = {
            mainColor = "rgba(13, 15, 25, 0.85)",
            textColor = "#ffffff",
            backgroundColor = "rgba(16, 18, 28, 0.75)",
            accentColor = "#5867d8",
            accentColorLight = "#7c89ff",
            accentColorDark = "#252f7e",
            slotBackgroundColor = "rgba(16, 18, 28, 0.4)",
            slotBorderColor = "rgba(88, 103, 216, 0.3)",
            neonShadow = "0 0 10px rgba(88, 103, 216, 0.5)",
            glassEffect = "rgba(255, 255, 255, 0.05)"
        },
        -- Light mode colors
        light = {
            mainColor = "rgba(255, 255, 255, 0.95)",
            textColor = "#000000",
            backgroundColor = "rgba(240, 240, 240, 0.95)",
            accentColor = "#1976d2",
            accentColorLight = "#42a5f5",
            accentColorDark = "#1565c0",
            slotBackgroundColor = "rgba(200, 200, 200, 0.4)",
            slotBorderColor = "rgba(25, 118, 210, 0.3)",
            neonShadow = "0 0 10px rgba(25, 118, 210, 0.3)",
            glassEffect = "rgba(0, 0, 0, 0.05)"
        },
        -- Custom colors (used when useCustomColors is true)
        custom = {
            mainColor = "rgba(13, 15, 25, 0.85)",
            textColor = "#ffffff",
            backgroundColor = "rgba(16, 18, 28, 0.75)",
            accentColor = "#5867d8",
            accentColorLight = "#7c89ff",
            accentColorDark = "#252f7e",
            slotBackgroundColor = "rgba(16, 18, 28, 0.4)",
            slotBorderColor = "rgba(88, 103, 216, 0.3)",
            neonShadow = "0 0 10px rgba(88, 103, 216, 0.5)",
            glassEffect = "rgba(255, 255, 255, 0.05)"
        }
    }
}

Config.Translations = {
    editor = {
        title = "Magazine Editor",
        newMagazineBtn = "Create New Magazine",
        urlPlaceholder = "Paste image URL here",
        addUrlBtn = "Add Image",
        saveBtn = "Save Changes",
        closeBtn = "Close",
        deleteBtn = "×",
        pageAltText = "Page",
        editText = "Press [E] to edit magazine",
        blipName = "Magazine Editor",
        targetText = "Magazine Editor"
    },
    confirmDialog = {
        title = "Confirm Action",
        message = "Are you sure you want to remove this magazine and create a new one?",
        yesBtn = "Yes",
        noBtn = "No"
    },
    notifications = {
        urlRequired = "Please enter an image URL",
        imageAdded = "Image added successfully",
        magazineCreated = "Created new magazine",
        changesSaved = "Changes saved successfully",
        notAuthorized = "You are not authorized to edit the magazine!"
    },
    reader = {
        prevBtn = "<",
        nextBtn = ">",
        closeBtn = "✕",
        pageText = "Page"
    },
    interaction = {
        buyText = "Buy Magazine",
        buyIcon = "fas fa-book-open"
    }
} 
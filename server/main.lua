local QBCore = exports['qb-core']:GetCoreObject()
local magazinePages = {} -- Store magazine pages in memory

-- Initialize magazine pages from database on resource start
MySQL.ready(function()
    -- Fetch pages from database
    MySQL.Async.fetchAll('SELECT * FROM magazine_pages ORDER BY page_number ASC', {}, function(results)
        if results and next(results) then
            magazinePages = results
        end
    end)
end)

-- Initialize inventory handler based on config
local function InitializeInventoryHandler()
    if Config.InventoryType == 'qb' then
        QBCore.Functions.CreateUseableItem("magazine", function(source, item)
            local src = source
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                TriggerClientEvent('fd-magazine:client:useMagazine', src, item)
            end
        end)
    elseif Config.InventoryType == 'ox' then
        exports.ox_inventory:registerHook('usingItem', function(data)
            if data.item.name == 'magazine' then
                local src = data.source
                local itemData = {
                    metadata = data.item.metadata,
                    info = data.item.metadata
                }
                TriggerClientEvent('fd-magazine:client:useMagazine', src, itemData)
                return false
            end
        end)
    elseif Config.InventoryType == 'qx' then
        exports['qx-inventory']:RegisterUsableItem('magazine', function(source, item)
            local src = source
            TriggerClientEvent('fd-magazine:client:useMagazine', src, item)
        end)
    elseif Config.InventoryType == 'qs' then
        exports['qs-inventory']:CreateUsableItem("magazine", function(source, item)
            local src = source
            TriggerClientEvent('fd-magazine:client:useMagazine', src, item)
        end)
    end
end

-- Initialize when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    InitializeInventoryHandler()
end)

-- Also initialize when database is ready
MySQL.ready(function()
    InitializeInventoryHandler()
end)

-- Helper function to remove item based on inventory type
local function RemoveItem(source, item, amount)
    amount = amount or 1
    if Config.InventoryType == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.RemoveItem(item, amount)
        end
    elseif Config.InventoryType == 'qs' then
        exports['qs-inventory']:RemoveItem(source, item, amount)
    elseif Config.InventoryType == 'ox' then
        exports.ox_inventory:RemoveItem(source, item, amount)
    elseif Config.InventoryType == 'qx' then
        exports['qx-inventory']:RemoveItem(source, item, amount)
    end
end

-- Helper function to add item based on inventory type
local function AddItem(source, item, amount)
    amount = amount or 1
    if Config.InventoryType == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.AddItem(item, amount)
        end
    elseif Config.InventoryType == 'qs' then
        exports['qs-inventory']:AddItem(source, item, amount)
    elseif Config.InventoryType == 'ox' then
        exports.ox_inventory:AddItem(source, item, amount)
    elseif Config.InventoryType == 'qx' then
        exports['qx-inventory']:AddItem(source, item, amount)
    end
end

-- Get editions list
RegisterNetEvent('fd-magazine:server:getEditions', function(targetSrc)
    local src = targetSrc or source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Check if Player exists before accessing its properties
    if Player and not Config.AuthorizedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized to edit the magazine!', 'error')
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM magazine_editions ORDER BY edition_number DESC', {}, function(results)
        if results and next(results) then
            TriggerClientEvent('fd-magazine:client:receiveEditions', src, results)
        else
            TriggerClientEvent('fd-magazine:client:receiveEditions', src, {})
        end
    end)
end)

-- Create new edition
RegisterNetEvent('fd-magazine:server:createEdition', function(title)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
        return
    end
    
    if not Config.AuthorizedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized to create editions!', 'error')
        return
    end
    
    -- Get the highest edition number
    MySQL.Async.fetchScalar('SELECT MAX(edition_number) FROM magazine_editions', {}, function(maxEdition)
        local newEditionNumber = (maxEdition or 0) + 1
        
        -- Insert new edition
        MySQL.Async.insert('INSERT INTO magazine_editions (edition_number, title) VALUES (?, ?)', 
            {newEditionNumber, title}, function(editionId)
            if editionId then
                TriggerClientEvent('QBCore:Notify', src, 'New edition created: ' .. title, 'success')
                -- Refresh editions list
                TriggerEvent('fd-magazine:server:getEditions', src)
            else
                TriggerClientEvent('QBCore:Notify', src, 'Failed to create new edition', 'error')
            end
        end)
    end)
end)

-- Get magazine pages for specific edition
RegisterNetEvent('fd-magazine:server:getEditionPages', function(editionNumber, readOnly)
    local src = source
    
    -- First get the edition details
    MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE edition_number = ?', {editionNumber}, function(editionResults)
        if not editionResults or not editionResults[1] then
            TriggerClientEvent('QBCore:Notify', src, 'Edition not found', 'error')
            return
        end
        
        local edition = editionResults[1]
        
        -- Check if edition is published and not in read-only mode
        if edition.is_published == 1 and not readOnly then
            local Player = QBCore.Functions.GetPlayer(src)
            if not Player then
                TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
                return
            end
            
            if not Config.AuthorizedJobs[Player.PlayerData.job.name] then
                TriggerClientEvent('QBCore:Notify', src, 'You cannot edit published editions', 'error')
                return
            end
        end
        
        -- Then get the pages for this edition
        MySQL.Async.fetchAll('SELECT * FROM magazine_pages WHERE edition_number = ? ORDER BY page_number ASC', 
            {editionNumber}, function(results)
            if results and next(results) then
                
                local pages = {}
                for i, page in ipairs(results) do
                    
                    table.insert(pages, {
                        id = page.id,
                        imageUrl = page.image_url,
                        page_number = page.page_number
                    })
                end
                
                
                TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, pages, true, edition, readOnly)
            else
                -- Try a direct query to see if there are any pages
                MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM magazine_pages WHERE edition_number = ?', 
                    {editionNumber}, function(countResult)
                    if countResult and countResult[1] and countResult[1].count > 0 then
                        print("Direct query found " .. countResult[1].count .. " pages, but they weren't returned properly")
                    else
                        print("Direct query confirmed no pages exist for edition " .. editionNumber)
                    end
                end)
                
                -- Send an empty array for pages
                TriggerClientEvent('QBCore:Notify', src, 'No pages found for this edition', 'info')
                TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, {}, true, edition, readOnly)
            end
        end)
    end)
end)

-- Get magazine pages (original function, modified to get published edition for reading)
RegisterNetEvent('fd-magazine:server:getMagazinePages', function(isEditor, itemData)
    local src = source
    
    -- Get edition number from either QB (info) or OX (metadata) format
    local editionNumber = nil
    if itemData then
        if itemData.info and itemData.info.edition then
            editionNumber = itemData.info.edition -- QB-Core format
        elseif itemData.metadata and itemData.metadata.edition then
            editionNumber = itemData.metadata.edition -- OX format
        end
    end
    
    if editionNumber then
        -- Get the specific edition from the database
        MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE edition_number = ? LIMIT 1', {editionNumber}, function(editionResults)
            if editionResults and editionResults[1] then
                local edition = editionResults[1]
                
                -- Get pages for this edition
                MySQL.Async.fetchAll('SELECT * FROM magazine_pages WHERE edition_number = ? ORDER BY page_number ASC', 
                    {editionNumber}, function(results)
                    if results and next(results) then
                        local pages = {}
                        for i, page in ipairs(results) do
                            table.insert(pages, {
                                id = page.id,
                                imageUrl = page.image_url,
                                page_number = page.page_number
                            })
                        end
                        TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, pages, isEditor, edition, true)
                    else
                        TriggerClientEvent('QBCore:Notify', src, 'This edition has no pages', 'error')
                        TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, {}, isEditor, edition, true)
                    end
                end)
            else
                TriggerClientEvent('QBCore:Notify', src, 'Edition not found', 'error')
            end
        end)
    else
        -- No specific edition in item data, get the active edition
        MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE is_active = 1 AND is_published = 1 LIMIT 1', {}, function(editionResults)
            if not editionResults or not editionResults[1] then
                TriggerClientEvent('QBCore:Notify', src, 'No active edition found', 'error')
                return
            end
            
            local edition = editionResults[1]
            local editionNumber = edition.edition_number
            
            -- Get pages for this edition
            MySQL.Async.fetchAll('SELECT * FROM magazine_pages WHERE edition_number = ? ORDER BY page_number ASC', 
                {editionNumber}, function(results)
                if results and next(results) then
                    local pages = {}
                    for i, page in ipairs(results) do
                        table.insert(pages, {
                            id = page.id,
                            imageUrl = page.image_url,
                            page_number = page.page_number
                        })
                    end
                    TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, pages, isEditor, edition)
                else
                    TriggerClientEvent('QBCore:Notify', src, 'No pages found for this edition', 'error')
                    TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, {}, isEditor, edition)
                end
            end)
        end)
    end
end)

-- Update magazine pages
RegisterNetEvent('fd-magazine:server:updatePages', function(pages)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
        return
    end
    
    if Config.AuthorizedJobs[Player.PlayerData.job.name] then
        -- Update database
        MySQL.Async.execute('TRUNCATE TABLE magazine_pages', {})
        for i, page in ipairs(pages) do
            MySQL.Async.insert('INSERT INTO magazine_pages (page_number, image_url) VALUES (?, ?)',
                {i-1, page.imageUrl})
        end
        TriggerClientEvent('QBCore:Notify', src, 'Magazine updated successfully!', 'success')
    end
end)

-- Clear magazine pages for specific edition
RegisterNetEvent('fd-magazine:server:clearMagazine', function(editionNumber)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
        return
    end
    
    if not Config.AuthorizedJobs[Player.PlayerData.job.name] then
        return
    end
    
    MySQL.Async.execute('DELETE FROM magazine_pages WHERE edition_number = ?', {editionNumber}, function()
        TriggerClientEvent('QBCore:Notify', src, 'Magazine has been cleared', 'success')
    end)
end)

-- Save pages for specific edition
RegisterNetEvent('fd-magazine:server:savePages', function(pages, editionNumber)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
        return
    end
    
    if not Config.AuthorizedJobs[Player.PlayerData.job.name] then
        return
    end
    
    -- Check if editionNumber is provided
    if not editionNumber then
        TriggerClientEvent('QBCore:Notify', src, 'Edition number not provided!', 'error')
        return
    end
    
    -- Delete existing pages for this edition
    MySQL.Async.execute('DELETE FROM magazine_pages WHERE edition_number = ?', {editionNumber}, function()
        -- Insert new pages
        local insertCount = 0
        local totalPages = #pages
        
        if totalPages == 0 then
            TriggerClientEvent('QBCore:Notify', src, 'No pages to save', 'error')
            return
        end
        
        for i, page in ipairs(pages) do
            MySQL.Async.execute('INSERT INTO magazine_pages (image_url, page_number, edition_number) VALUES (?, ?, ?)', {
                page.imageUrl,
                i-1,
                editionNumber
            }, function()
                insertCount = insertCount + 1
                if insertCount == totalPages then
                    TriggerClientEvent('QBCore:Notify', src, 'Magazine pages saved successfully', 'success')
                end
            end)
        end
    end)
end)

-- Update page order for specific edition
RegisterNetEvent('fd-magazine:server:updatePageOrder', function(pages, editionNumber)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
        return
    end
    
    if not Config.AuthorizedJobs[Player.PlayerData.job.name] then
        return
    end

    for _, page in ipairs(pages) do
        MySQL.Async.execute('UPDATE magazine_pages SET page_number = ? WHERE id = ? AND edition_number = ?', {
            page.order,
            page.id,
            editionNumber
        })
    end
end)

-- Helper function to give magazine to player with metadata
function GiveMagazineToPlayer(src, Player, editionNumber, editionTitle)
    -- Remove money first
    if Config.InventoryType == 'ox' then
        local money = exports.ox_inventory:GetItem(src, 'money', nil, true)
        if money >= Config.Magazine.price then
            exports.ox_inventory:RemoveItem(src, 'money', Config.Magazine.price)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Not enough money!', 'error')
            return
        end
    else
        Player.Functions.RemoveMoney('cash', Config.Magazine.price)
    end
    
    -- Add item with metadata
    if editionNumber then
        if Config.InventoryType == 'ox' then
            -- Create metadata table with all necessary information
            local metadata = {
                edition = tonumber(editionNumber),
                title = editionTitle or ("Edition #" .. editionNumber),
                description = "Magazine Edition #" .. editionNumber,
                label = "Magazine - Edition #" .. editionNumber
            }
            
            -- Add the item with metadata
            local success = exports.ox_inventory:AddItem(src, 'magazine', 1, metadata)
            
            if success then
                -- Send success notification
                TriggerClientEvent('QBCore:Notify', src, 'You bought magazine edition #' .. editionNumber .. ' for $' .. Config.Magazine.price, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Failed to give magazine', 'error')
            end
        else
            -- QB-Core inventory handling
            Player.Functions.AddItem('magazine', 1, nil, {
                edition = editionNumber,
                title = editionTitle,
                description = "Magazine - Edition #" .. editionNumber
            })
            TriggerClientEvent('QBCore:Notify', src, 'You bought magazine edition #' .. editionNumber .. ' for $' .. Config.Magazine.price, 'success')
        end
    else
        -- No editions available, give generic magazine
        if Config.InventoryType == 'ox' then
            local metadata = {
                description = "A generic magazine",
                label = "Magazine"
            }
            exports.ox_inventory:AddItem(src, 'magazine', 1, metadata)
        else
            Player.Functions.AddItem('magazine', 1)
        end
        TriggerClientEvent('QBCore:Notify', src, 'You bought a magazine for $' .. Config.Magazine.price, 'success')
    end
    
    if Config.InventoryType ~= 'ox' then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['magazine'], 'add')
    end
end

-- Add this with your other RegisterNetEvent functions
RegisterNetEvent('fd-magazine:server:buyMagazine', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- First check if there are any published editions
    MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM magazine_editions WHERE is_published = 1', {}, function(result)
        if not result or not result[1] or result[1].count == 0 then
            TriggerClientEvent('QBCore:Notify', src, 'No magazines are currently available for purchase!', 'error')
            return
        end

        -- Check if player has enough money
        local hasEnoughMoney = false
        if Config.InventoryType == 'ox' then
            local money = exports.ox_inventory:GetItem(src, 'money', nil, true)
            hasEnoughMoney = money >= Config.Magazine.price
        else
            hasEnoughMoney = Player.PlayerData.money['cash'] >= Config.Magazine.price
        end

        if not hasEnoughMoney then
            TriggerClientEvent('QBCore:Notify', src, 'You need $' .. Config.Magazine.price .. ' to buy a magazine', 'error')
            return
        end

        -- Get the active edition
        MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE is_active = 1 AND is_published = 1 LIMIT 1', {}, function(editionResults)
            local editionNumber = nil
            local editionTitle = nil
            
            if editionResults and editionResults[1] then
                editionNumber = editionResults[1].edition_number
                editionTitle = editionResults[1].title
                -- Give magazine with active edition
                GiveMagazineToPlayer(src, Player, editionNumber, editionTitle)
            else
                -- If no active edition, get the latest published one
                MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE is_published = 1 ORDER BY edition_number DESC LIMIT 1', {}, function(latestResults)
                    if latestResults and latestResults[1] then
                        editionNumber = latestResults[1].edition_number
                        editionTitle = latestResults[1].title
                    end
                    
                    -- Now add the item with metadata
                    GiveMagazineToPlayer(src, Player, editionNumber, editionTitle)
                end)
            end
        end)
    end)
end)

-- Add this with your other RegisterNetEvent functions
RegisterNetEvent('fd-magazine:server:publishEdition', function(editionNumber)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        TriggerClientEvent('QBCore:Notify', src, 'Player data not found!', 'error')
        return
    end
    
    if not Config.AuthorizedJobs[Player.PlayerData.job.name] then
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized to publish editions!', 'error')
        return
    end
    
    -- First, set all editions to inactive
    MySQL.Async.execute('UPDATE magazine_editions SET is_active = 0', {}, function()
        -- Then, set the selected edition to active and published
        MySQL.Async.execute('UPDATE magazine_editions SET is_active = 1, is_published = 1 WHERE edition_number = ?', 
            {editionNumber}, function()
            TriggerClientEvent('QBCore:Notify', src, 'Edition published successfully!', 'success')
            
            -- Get the updated edition data and send it back to the client
            MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE edition_number = ?', {editionNumber}, function(results)
                if results and results[1] then
                    -- Send the updated edition data to the client
                    TriggerClientEvent('fd-magazine:client:editionPublished', src, results[1])
                end
            end)
        end)
    end)
end) 
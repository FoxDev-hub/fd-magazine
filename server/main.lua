-- Framework detection and initialization
local Framework = nil
local QBCore = nil

if Config.Framework ~= 'esx' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local magazinePages = {}
local isInitialized = false

local function CheckESXAvailability()
    
    local esxFound = false
    local esxObject = nil
    
    if ESX then
        esxFound = true
        esxObject = ESX
    end
    
    if not esxFound then
        local exportNames = {
            'es_extended',
            'esx',
            'esxlegacy',
            'esx-legacy'
        }
        
        for _, exportName in ipairs(exportNames) do
            local success, result = pcall(function()
                return exports[exportName]:getSharedObject()
            end)
            if success and result then
                esxFound = true
                esxObject = result
                break
            end
            
            -- Try with capital G
            success, result = pcall(function()
                return exports[exportName]:GetSharedObject()
            end)
            if success and result then
                esxFound = true
                esxObject = result
                break
            end
        end
    end
    
    if not esxFound then
        local resources = {
            'es_extended',
            'esx',
            'esxlegacy',
            'esx-legacy'
        }
        
        for _, resourceName in ipairs(resources) do
            if GetResourceState(resourceName) == 'started' then
                local success, result = pcall(function()
                    return exports[resourceName]:getSharedObject()
                end)
                if success and result then
                    esxFound = true
                    esxObject = result
                    break
                end
            end
        end
    end
    
    if esxFound then
        ESX = esxObject
        return true
    else
        return false
    end
end

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM magazine_pages ORDER BY page_number ASC', {}, function(results)
        if results and next(results) then
            magazinePages = results
        end
    end)
end)

local function GetPlayer(source)
    if not isInitialized then
        return nil
    end
    
    if Config.Framework == 'esx' then
        if ESX then
            return ESX.GetPlayerFromId(source)
        else
            return nil
        end
    else
        return QBCore.Functions.GetPlayer(source)
    end
end

local function ShowNotification(source, message, type)
    if not isInitialized then
        return
    end
    
    if Config.Framework == 'esx' then
        if ESX then
            TriggerClientEvent('esx:showNotification', source, message)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, message, type)
    end
end

local function RemoveMoney(source, amount, moneyType)
    if not isInitialized then
        return false
    end
    
    if Config.Framework == 'esx' then
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                return xPlayer.removeMoney(amount)
            end
        end
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.RemoveMoney(moneyType or 'cash', amount)
        end
    end
    return false
end

local function GetMoney(source, moneyType)
    if not isInitialized then
        return 0
    end
    
    if Config.Framework == 'esx' then
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                return xPlayer.getMoney()
            end
        end
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.money[moneyType or 'cash']
        end
    end
    return 0
end

local function HasJob(source, jobName)
    if not isInitialized then
        return false
    end
    
    if Config.Framework == 'esx' then
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                return xPlayer.job.name == jobName
            end
        end
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.job.name == jobName
        end
    end
    return false
end

local function IsAuthorized(source)
    if not isInitialized then
        return false
    end
    
    if Config.Framework == 'esx' then
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                return Config.AuthorizedJobs[xPlayer.job.name] == true
            end
        end
    else
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Config.AuthorizedJobs[Player.PlayerData.job.name] == true
        end
    end
    return false
end

local function InitializeInventoryHandler()
    if Config.InventoryType == 'qb' then
        if Config.Framework == 'esx' then
            -- TODO
        else
            QBCore.Functions.CreateUseableItem("magazine", function(source, item)
                local src = source
                local Player = GetPlayer(src)
                if Player then
                    TriggerClientEvent('fd-magazine:client:useMagazine', src, item)
                end
            end)
        end
    elseif Config.InventoryType == 'ox' then
        if exports.ox_inventory.registerHook then
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
        else
            if Config.Framework == 'esx' then
                if ESX then
                    ESX.RegisterUsableItem('magazine', function(source)
                        TriggerClientEvent('fd-magazine:client:useMagazine', source, {metadata = {}})
                    end)
                end
            else
                QBCore.Functions.CreateUseableItem("magazine", function(source, item)
                    local src = source
                    TriggerClientEvent('fd-magazine:client:useMagazine', src, item)
                end)
            end
        end
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

local function CompleteInitialization()
    isInitialized = true
    InitializeInventoryHandler()
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    
    if Config.Framework == 'esx' then
        CreateThread(function()
            local attempts = 0
            while not CheckESXAvailability() and attempts < 50 do
                attempts = attempts + 1
                Wait(1000)
            end
            
            if CheckESXAvailability() then
                CompleteInitialization()
            end
        end)
    else
        CompleteInitialization()
    end
end)

MySQL.ready(function()
    if Config.Framework == 'esx' then
        CreateThread(function()
            local attempts = 0
            while not CheckESXAvailability() and attempts < 30 do
                attempts = attempts + 1
                Wait(1000)
            end
            
            if CheckESXAvailability() and not isInitialized then
                CompleteInitialization()
            end
        end)
    else
        if not isInitialized then
            CompleteInitialization()
        end
    end
end)

local function RemoveItem(source, item, amount)
    amount = amount or 1
    if Config.InventoryType == 'qb' then
        local Player = GetPlayer(source)
        if Player then
            if Config.Framework == 'esx' then
                Player.removeInventoryItem(item, amount)
            else
                Player.Functions.RemoveItem(item, amount)
            end
        end
    elseif Config.InventoryType == 'qs' then
        exports['qs-inventory']:RemoveItem(source, item, amount)
    elseif Config.InventoryType == 'ox' then
        exports.ox_inventory:RemoveItem(source, item, amount)
    elseif Config.InventoryType == 'qx' then
        exports['qx-inventory']:RemoveItem(source, item, amount)
    end
end

local function AddItem(source, item, amount, metadata)
    amount = amount or 1
    if Config.InventoryType == 'qb' then
        local Player = GetPlayer(source)
        if Player then
            if Config.Framework == 'esx' then
                Player.addInventoryItem(item, amount, metadata)
            else
                Player.Functions.AddItem(item, amount, nil, metadata)
            end
        end
    elseif Config.InventoryType == 'qs' then
        exports['qs-inventory']:AddItem(source, item, amount, metadata)
    elseif Config.InventoryType == 'ox' then
        exports.ox_inventory:AddItem(source, item, amount, metadata)
    elseif Config.InventoryType == 'qx' then
        exports['qx-inventory']:AddItem(source, item, amount, metadata)
    end
end

RegisterNetEvent('fd-magazine:server:getEditions', function(targetSrc)
    local src = targetSrc or source
    local Player = GetPlayer(src)
    
    if Player and not IsAuthorized(src) then
        ShowNotification(src, 'You are not authorized to edit the magazine!', 'error')
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

RegisterNetEvent('fd-magazine:server:createEdition', function(title)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then
        ShowNotification(src, 'Player data not found!', 'error')
        return
    end
    
    if not IsAuthorized(src) then
        ShowNotification(src, 'You are not authorized to create editions!', 'error')
        return
    end
    
    -- Get the highest edition number
    MySQL.Async.fetchScalar('SELECT MAX(edition_number) FROM magazine_editions', {}, function(maxEdition)
        local newEditionNumber = (maxEdition or 0) + 1
        
        -- Insert new edition
        MySQL.Async.insert('INSERT INTO magazine_editions (edition_number, title) VALUES (?, ?)', 
            {newEditionNumber, title}, function(editionId)
            if editionId then
                ShowNotification(src, 'New edition created: ' .. title, 'success')
                -- Refresh editions list
                TriggerEvent('fd-magazine:server:getEditions', src)
            else
                ShowNotification(src, 'Failed to create new edition', 'error')
            end
        end)
    end)
end)

RegisterNetEvent('fd-magazine:server:getEditionPages', function(editionNumber, readOnly)
    local src = source
    
    MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE edition_number = ?', {editionNumber}, function(editionResults)
        if not editionResults or not editionResults[1] then
            ShowNotification(src, 'Edition not found', 'error')
            return
        end
        
        local edition = editionResults[1]
        
        if edition.is_published == 1 and not readOnly then
            local Player = GetPlayer(src)
            if not Player then
                ShowNotification(src, 'Player data not found!', 'error')
                return
            end
            
            if not IsAuthorized(src) then
                ShowNotification(src, 'You cannot edit published editions', 'error')
                return
            end
        end
        
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
                MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM magazine_pages WHERE edition_number = ?',
                    {editionNumber}, function(countResult)
                    if countResult and countResult[1] and countResult[1].count > 0 then
                        print("Direct query found " .. countResult[1].count .. " pages, but they weren't returned properly")
                    else
                        print("Direct query confirmed no pages exist for edition " .. editionNumber)
                    end
                end)
                
                ShowNotification(src, 'No pages found for this edition', 'info')
                TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, {}, true, edition, readOnly)
            end
        end)
    end)
end)

RegisterNetEvent('fd-magazine:server:getMagazinePages', function(isEditor, itemData)
    local src = source
    
    local editionNumber = nil
    if itemData then
        if itemData.info and itemData.info.edition then
            editionNumber = itemData.info.edition -- QB-Core format
        elseif itemData.metadata and itemData.metadata.edition then
            editionNumber = itemData.metadata.edition -- OX format
        end
    end
    
    if editionNumber then
        MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE edition_number = ? LIMIT 1', {editionNumber}, function(editionResults)
            if editionResults and editionResults[1] then
                local edition = editionResults[1]
                
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
                        ShowNotification(src, 'This edition has no pages', 'error')
                        TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, {}, isEditor, edition, true)
                    end
                end)
            else
                ShowNotification(src, 'Edition not found', 'error')
            end
        end)
    else
        MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE is_active = 1 AND is_published = 1 LIMIT 1', {}, function(editionResults)
            if not editionResults or not editionResults[1] then
                ShowNotification(src, 'No active edition found', 'error')
                return
            end
            
            local edition = editionResults[1]
            local editionNumber = edition.edition_number
            
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
                    ShowNotification(src, 'No pages found for this edition', 'error')
                    TriggerClientEvent('fd-magazine:client:receiveMagazinePages', src, {}, isEditor, edition)
                end
            end)
        end)
    end
end)

RegisterNetEvent('fd-magazine:server:updatePages', function(pages)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then
        ShowNotification(src, 'Player data not found!', 'error')
        return
    end
    
    if IsAuthorized(src) then
        MySQL.Async.execute('TRUNCATE TABLE magazine_pages', {})
        for i, page in ipairs(pages) do
            MySQL.Async.insert('INSERT INTO magazine_pages (page_number, image_url) VALUES (?, ?)',
                {i-1, page.imageUrl})
        end
        ShowNotification(src, 'Magazine updated successfully!', 'success')
    end
end)

RegisterNetEvent('fd-magazine:server:clearMagazine', function(editionNumber)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then
        ShowNotification(src, 'Player data not found!', 'error')
        return
    end
    
    if not IsAuthorized(src) then
        return
    end
    
    MySQL.Async.execute('DELETE FROM magazine_pages WHERE edition_number = ?', {editionNumber}, function()
        ShowNotification(src, 'Magazine has been cleared', 'success')
    end)
end)

RegisterNetEvent('fd-magazine:server:savePages', function(pages, editionNumber)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then
        ShowNotification(src, 'Player data not found!', 'error')
        return
    end
    
    if not IsAuthorized(src) then
        return
    end
    
    if not editionNumber then
        ShowNotification(src, 'Edition number not provided!', 'error')
        return
    end
    
    MySQL.Async.execute('DELETE FROM magazine_pages WHERE edition_number = ?', {editionNumber}, function()
        local insertCount = 0
        local totalPages = #pages
        
        if totalPages == 0 then
            ShowNotification(src, 'No pages to save', 'error')
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
                    ShowNotification(src, 'Magazine pages saved successfully', 'success')
                end
            end)
        end
    end)
end)

RegisterNetEvent('fd-magazine:server:updatePageOrder', function(pages, editionNumber)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then
        ShowNotification(src, 'Player data not found!', 'error')
        return
    end
    
    if not IsAuthorized(src) then
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

function GiveMagazineToPlayer(src, Player, editionNumber, editionTitle)
    -- Remove money first
    if Config.InventoryType == 'ox' then
        local money = exports.ox_inventory:GetItem(src, 'money', nil, true)
        if money >= Config.Magazine.price then
            exports.ox_inventory:RemoveItem(src, 'money', Config.Magazine.price)
        else
            ShowNotification(src, 'Not enough money!', 'error')
            return
        end
    else
        if not RemoveMoney(src, Config.Magazine.price, 'cash') then
            ShowNotification(src, 'Not enough money!', 'error')
            return
        end
    end
    
    if editionNumber then
        if Config.InventoryType == 'ox' then
            local metadata = {
                edition = tonumber(editionNumber),
                title = editionTitle or ("Edition #" .. editionNumber),
                description = "Magazine Edition #" .. editionNumber,
                label = "Magazine - Edition #" .. editionNumber
            }
            
            local success = exports.ox_inventory:AddItem(src, 'magazine', 1, metadata)
            
            if success then
                ShowNotification(src, 'You bought magazine edition #' .. editionNumber .. ' for $' .. Config.Magazine.price, 'success')
            else
                ShowNotification(src, 'Failed to give magazine', 'error')
            end
        else
            local metadata = {
                edition = editionNumber,
                title = editionTitle,
                description = "Magazine - Edition #" .. editionNumber
            }
            AddItem(src, 'magazine', 1, metadata)
            ShowNotification(src, 'You bought magazine edition #' .. editionNumber .. ' for $' .. Config.Magazine.price, 'success')
        end
    else
        if Config.InventoryType == 'ox' then
            local metadata = {
                description = "A generic magazine",
                label = "Magazine"
            }
            exports.ox_inventory:AddItem(src, 'magazine', 1, metadata)
        else
            AddItem(src, 'magazine', 1)
        end
        ShowNotification(src, 'You bought a magazine for $' .. Config.Magazine.price, 'success')
    end
    
    if Config.InventoryType ~= 'ox' and Config.Framework ~= 'esx' then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['magazine'], 'add')
    end
end

RegisterNetEvent('fd-magazine:server:buyMagazine', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end

    MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM magazine_editions WHERE is_published = 1', {}, function(result)
        if not result or not result[1] or result[1].count == 0 then
            ShowNotification(src, 'No magazines are currently available for purchase!', 'error')
            return
        end

        local hasEnoughMoney = false
        if Config.InventoryType == 'ox' then
            local money = exports.ox_inventory:GetItem(src, 'money', nil, true)
            hasEnoughMoney = money >= Config.Magazine.price
        else
            hasEnoughMoney = GetMoney(src, 'cash') >= Config.Magazine.price
        end

        if not hasEnoughMoney then
            ShowNotification(src, 'You need $' .. Config.Magazine.price .. ' to buy a magazine', 'error')
            return
        end

        MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE is_active = 1 AND is_published = 1 LIMIT 1', {}, function(editionResults)
            local editionNumber = nil
            local editionTitle = nil
            
            if editionResults and editionResults[1] then
                editionNumber = editionResults[1].edition_number
                editionTitle = editionResults[1].title
                GiveMagazineToPlayer(src, Player, editionNumber, editionTitle)
            else
                MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE is_published = 1 ORDER BY edition_number DESC LIMIT 1', {}, function(latestResults)
                    if latestResults and latestResults[1] then
                        editionNumber = latestResults[1].edition_number
                        editionTitle = latestResults[1].title
                    end
                    
                    GiveMagazineToPlayer(src, Player, editionNumber, editionTitle)
                end)
            end
        end)
    end)
end)

RegisterNetEvent('fd-magazine:server:publishEdition', function(editionNumber)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then
        ShowNotification(src, 'Player data not found!', 'error')
        return
    end
    
    if not IsAuthorized(src) then
        ShowNotification(src, 'You are not authorized to publish editions!', 'error')
        return
    end
    
    MySQL.Async.execute('UPDATE magazine_editions SET is_active = 0', {}, function()
        MySQL.Async.execute('UPDATE magazine_editions SET is_active = 1, is_published = 1 WHERE edition_number = ?',
            {editionNumber}, function()
            ShowNotification(src, 'Edition published successfully!', 'success')
            
            MySQL.Async.fetchAll('SELECT * FROM magazine_editions WHERE edition_number = ?', {editionNumber}, function(results)
                if results and results[1] then
                    TriggerClientEvent('fd-magazine:client:editionPublished', src, results[1])
                end
            end)
        end)
    end)
end) 
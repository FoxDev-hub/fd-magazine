local QBCore = exports['qb-core']:GetCoreObject()
local isReadingMagazine = false
local currentPage = 1
local magazinePages = {}
local currentEdition = nil
local isEditionsOpen = false

local function stopMagazineAnimation()
    local anim = Config.Magazine.animation
    ClearPedTasks(PlayerPedId())
    StopAnimTask(PlayerPedId(), anim.dict, anim.name, 1.0)
    RemoveAnimDict(anim.dict) 
end

local function forceFocusOff()
    isReadingMagazine = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    TriggerEvent("fd-magazine:client:forceFocusOff")
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isReadingMagazine = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isReadingMagazine = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
    stopMagazineAnimation()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    isReadingMagazine = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    isReadingMagazine = false
    SetNuiFocus(false, false)
    stopMagazineAnimation()
end)

local function hasRequiredJob()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return false end
    
    return Config.AuthorizedJobs[Player.job.name] == true
end

local function SendConfigToNUI()
    SendNUIMessage({
        config = Config
    })
end

local function openMagazine(pages, edition)
    if Config.InventoryType == 'ox' then
        exports.ox_inventory:closeInventory()
    elseif Config.InventoryType == 'qb' then
        TriggerEvent('inventory:client:closeInventory')
    elseif Config.InventoryType == 'qx' then
        exports['qx-inventory']:closeInventory()
    end

    -- Play animation using config settings
    local anim = Config.Magazine.animation
    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do
        Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 8.0, -8.0, -1, 49, 0, false, false, false)

    isReadingMagazine = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    
    CreateThread(function()
        while isReadingMagazine do
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            
            DisableControlAction(0, 199, true) -- Pause Menu
            DisableControlAction(0, 200, true) -- ESC Menu
            DisableControlAction(0, 244, true) -- M key
            DisableControlAction(0, 56, true) -- F9
            DisableControlAction(0, 57, true) -- F10
            DisableControlAction(0, 344, true) -- F11
            
            EnableControlAction(0, 174, true) -- Left Arrow
            EnableControlAction(0, 175, true) -- Right Arrow
            EnableControlAction(0, 177, true) -- ESC
            EnableControlAction(0, 249, true) -- N key for voice chat
            EnableControlAction(0, 245, true) -- T key for chat
            EnableControlAction(0, 32, true) -- W key
            EnableControlAction(0, 34, true) -- A key
            EnableControlAction(0, 33, true) -- S key
            EnableControlAction(0, 35, true) -- D key
            
            Wait(0)
        end
    end)

    SendConfigToNUI() -- Send config first
    SendNUIMessage({
        action = "openMagazine",
        pages = pages,
        edition = edition
    })
end

local function openEditor()
    local Player = QBCore.Functions.GetPlayerData()
    
    if not hasRequiredJob() then
        QBCore.Functions.Notify("You are not authorized to edit the magazine!", "error")
        return
    end
    
    SetNuiFocus(true, true)
    SendConfigToNUI() -- Send config first
    TriggerServerEvent('fd-magazine:server:getEditions')
end

local function openEditorForEdition(edition, pages, readOnly)
    currentEdition = edition
    isEditionsOpen = false
    SetNuiFocus(true, true)
    SendConfigToNUI()
    SendNUIMessage({
        action = 'openEditor',
        edition = edition,
        pages = pages,
        read_only = readOnly
    })
    
    if readOnly then
        QBCore.Functions.Notify("Viewing published edition: " .. edition.title, "primary")
    else
        QBCore.Functions.Notify("Editor opened for edition: " .. edition.title, "success")
    end
end

CreateThread(function()
    if Config.TargetSystem == 'qb' then
        exports['qb-target']:AddBoxZone("magazine_editor", Config.EditLocation, 1.5, 1.5, {
            name = "magazine_editor",
            heading = 0,
            debugPoly = Config.Debug,
            minZ = Config.EditLocation.z - 1.0,
            maxZ = Config.EditLocation.z + 1.0,
        }, {
            options = {
                {
                    icon = "fas fa-newspaper",
                    label = Config.Translations.editor.targetText,
                    action = function()
                        openEditor()
                    end
                }
            },
            distance = 2.0
        })
    elseif Config.TargetSystem == 'ox' then
        exports.ox_target:addBoxZone({
            coords = Config.EditLocation,
            size = vec3(1.5, 1.5, 2.0),
            rotation = 0,
            debug = Config.Debug,
            options = {
                {
                    name = 'magazine_editor',
                    icon = "fas fa-newspaper",
                    label = Config.Translations.editor.targetText,
                    onSelect = function()
                        openEditor()
                    end
                }
            }
        })
    elseif Config.TargetSystem == 'marker' then
        while true do
            Wait(0)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local dist = #(pos - Config.EditLocation)

            DrawMarker(2,
                    Config.EditLocation.x,
                    Config.EditLocation.y,
                    Config.EditLocation.z + 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.5, 0.5, 0.5,
                    255, 0, 0, 100,
                    true, true, 2,
                    false, nil, nil, false)

            if dist < 1.5 then
                DrawText3D(
                        Config.EditLocation.x,
                        Config.EditLocation.y,
                        Config.EditLocation.z + 1.5,
                        Config.Translations.editor.editText
                )
                if IsControlJustPressed(0, 38) then -- E key
                    openEditor()
                end
            end
            Wait(0)
        end
    end
end)

RegisterNetEvent('fd-magazine:client:useMagazine', function(itemData)
    if not isReadingMagazine then
        TriggerServerEvent('fd-magazine:server:getMagazinePages', false, itemData)
    end
end)

RegisterNetEvent('fd-magazine:client:receiveMagazinePages', function(pages, isEditor, edition, readOnly)
    if not pages then
        pages = {}
    end
    
    if isEditor then
        if edition then
            openEditorForEdition(edition, pages, readOnly)
        else
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openEditor',
                pages = pages
            })
            QBCore.Functions.Notify("Editor opened", "success")
        end
    else
        openMagazine(pages, edition)
    end
end)

RegisterNetEvent('fd-magazine:client:receiveEditions', function(editions)
    if isEditionsOpen then
        SendNUIMessage({
            action = 'editionsUpdated',
            editions = editions
        })
    else
        isEditionsOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openEditions',
            editions = editions
        })
    end
end)

RegisterNUICallback('closeMagazine', function(data, cb)
    isReadingMagazine = false
    forceFocusOff()
    SendNUIMessage({
        action = "hide"
    })
    stopMagazineAnimation()
    cb('ok')
end)

RegisterNUICallback('updatePages', function(data)
    if hasRequiredJob() then
        TriggerServerEvent('fd-magazine:server:updatePages', data.pages)
    end
end)

RegisterNUICallback('notify', function(data, cb)
    QBCore.Functions.Notify(data.message, data.type)
    cb('ok')
end)

RegisterNUICallback('closeEditor', function(data, cb)
    isReadingMagazine = false
    forceFocusOff()
    SendNUIMessage({
        action = "hide"
    })
    stopMagazineAnimation()
    cb('ok')
end)

RegisterNUICallback('savePages', function(data, cb)
    local pages = data.pages
    local editionNumber = data.edition_number
    
    TriggerServerEvent('fd-magazine:server:savePages', pages, editionNumber)
    cb({})
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isReadingMagazine and IsControlJustReleased(0, 177) then -- ESC key
            isReadingMagazine = false
            forceFocusOff()
            SendNUIMessage({
                action = "hide"
            })
            stopMagazineAnimation()
            -- Re-enable all controls
            EnableAllControlActions(0)
            EnableAllControlActions(1)
            EnableAllControlActions(2)
            Wait(500) -- Add a small delay before allowing map to be opened again
        end
    end
end)

RegisterNetEvent("fd-magazine:client:forceFocusOff")
AddEventHandler("fd-magazine:client:forceFocusOff", function()
    Citizen.CreateThread(function()
        for i = 1, 10 do
            Citizen.Wait(100)
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
    end)
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

CreateThread(function()
    local blip = AddBlipForCoord(Config.EditLocation.x, Config.EditLocation.y, Config.EditLocation.z)
    SetBlipSprite(blip, 184) -- Change number for different icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2) -- Red color
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Translations.editor.blipName)
    EndTextCommandSetBlipName(blip)
end)

RegisterNUICallback('clearMagazine', function(data, cb)
    TriggerServerEvent('fd-magazine:server:clearMagazine')
    cb({})
end)

RegisterNetEvent('fd-magazine:client:openMagazine')
AddEventHandler('fd-magazine:client:openMagazine', function()
    openMagazine()
    TriggerServerEvent('fd-magazine:server:getMagazinePages', false)
end)

RegisterNUICallback('updatePageOrder', function(data, cb)
    TriggerServerEvent('fd-magazine:server:updatePageOrder', data.pages)
    cb({})
end)

RegisterNUICallback('setNuiFocus', function(data, cb)
    if isReadingMagazine or data.focus then
        SetNuiFocus(data.focus, data.cursor)
    end
    cb('ok')
end)

CreateThread(function()
    while QBCore == nil do
        QBCore = exports['qb-core']:GetCoreObject()
        Wait(100)
    end

    if Config.Magazine.enableBuyFromProps == true then
        if Config.TargetSystem == 'qb' then
            exports['qb-target']:AddTargetModel(Config.NewstandProps, {
                options = {
                    {
                        icon = Config.Translations.interaction.buyIcon,
                        label = Config.Translations.interaction.buyText,
                        action = function()
                            TriggerServerEvent('fd-magazine:server:buyMagazine')
                        end
                    }
                },
                distance = 2.0
            })
        elseif Config.TargetSystem == 'ox' then
            exports.ox_target:addModel(Config.NewstandProps, {
                {
                    name = 'buy_magazine',
                    icon = Config.Translations.interaction.buyIcon,
                    label = Config.Translations.interaction.buyText,
                    onSelect = function()
                        TriggerServerEvent('fd-magazine:server:buyMagazine')
                    end
                }
            })
        end
    end
end)

RegisterNUICallback('getEditionPages', function(data, cb)
    local editionNumber = data.edition_number
    local readOnly = data.read_only or false
    TriggerServerEvent('fd-magazine:server:getEditionPages', editionNumber, readOnly)
    cb('ok')
end)

RegisterNUICallback('createEdition', function(data, cb)
    local title = data.title
    TriggerServerEvent('fd-magazine:server:createEdition', title)
    cb('ok')
end)

RegisterNUICallback('closeEditions', function(data, cb)
    isReadingMagazine = false
    isEditionsOpen = false
    
    forceFocusOff()
    
    SendNUIMessage({
        action = "hide"
    })
    
    cb('ok')
end)

RegisterNUICallback('backToEditions', function(data, cb)
    isEditionsOpen = true
    
    TriggerServerEvent('fd-magazine:server:getEditions')
    
    SetNuiFocus(true, true)
    
    cb('ok')
end)

RegisterNUICallback('publishEdition', function(data, cb)
    local editionNumber = data.edition_number
    TriggerServerEvent('fd-magazine:server:publishEdition', editionNumber)
    cb('ok')
end)

RegisterNetEvent('fd-magazine:client:editionPublished')
AddEventHandler('fd-magazine:client:editionPublished', function(edition)
    SendNUIMessage({
        action = "editionPublished",
        edition = edition
    })
    
    QBCore.Functions.Notify("Edition published successfully!", "success")
end)

RegisterCommand('magazinedebug', function()
    TriggerEvent('fd-magazine:client:useMagazine', {
        metadata = {
            edition = 1  -- Test with edition 1
        }
    })
end, false)

exports('useMagazine', function(data, slot)
    if not isReadingMagazine then
        local itemData = {
            metadata = slot.metadata or {},
            info = slot.metadata or {}
        }
        TriggerServerEvent('fd-magazine:server:getMagazinePages', false, itemData)
    end
    return true
end) 
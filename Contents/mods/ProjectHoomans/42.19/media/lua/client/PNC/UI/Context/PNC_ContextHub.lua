--[[
    PNC Context Hub
    Central reusable NPC selection and right-click hub. Providers attach
    command, debug, dialogue, and future interaction options per selected NPC.
]]

PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local ContextHub = PNC.ContextHub
local Selection = PNC.NPCSelection

ContextHub.Providers = ContextHub.Providers or {}
ContextHub.ProviderOrder = ContextHub.ProviderOrder or {}

local function appendUnique(list, value)
    local i
    for i = 1, #list do
        if list[i] == value then
            return
        end
    end
    list[#list + 1] = value
end

function ContextHub.RegisterProvider(provider)
    if type(provider) ~= "table" or not provider.id or type(provider.addOptions) ~= "function" then
        return false
    end
    ContextHub.Providers[tostring(provider.id)] = provider
    appendUnique(ContextHub.ProviderOrder, tostring(provider.id))
    return true
end

local function hasEnabledProvider(entry, player, contextData)
    local i
    local provider
    for i = 1, #ContextHub.ProviderOrder do
        provider = ContextHub.Providers[ContextHub.ProviderOrder[i]]
        if provider and (provider.isEnabled == nil or provider.isEnabled(entry, player, contextData) ~= false) then
            return true
        end
    end
    return false
end

local function formatEntryLabel(entry)
    local label = tostring(entry and entry.name or "PNC NPC")
    local distance = math.sqrt(tonumber(entry and entry.distSq) or 0)
    local debugPresentation = PNC.Runtime and PNC.Runtime.debugEnabled == true
        or entry and entry.debugRecording == true
    if debugPresentation then
        label = label
            .. " ["
            .. tostring(entry and entry.archetypeLabel or "NPC")
            .. "] "
            .. string.format("(%.1f)", distance)
    end
    if entry and entry.debugRecording == true then
        label = label .. "  [REC]"
    end
    return label
end

local function resolveEntryIcon()
    -- Match Dynamic Trading's production Talk provider exactly. This is a
    -- base-game texture, so no mod-local copy is required.
    return getTexture and getTexture("media/ui/emotes/insult.png") or nil
end

function ContextHub.AddEntryOptions(menu, player, entry, contextData)
    local subMenu = ISContextMenu:getNew(menu)
    local option
    local i
    local provider
    option = menu:addOption(formatEntryLabel(entry))
    if option then
        option.iconTexture = resolveEntryIcon()
    end
    menu:addSubMenu(option, subMenu)
    for i = 1, #ContextHub.ProviderOrder do
        provider = ContextHub.Providers[ContextHub.ProviderOrder[i]]
        if provider and (provider.isEnabled == nil or provider.isEnabled(entry, player, contextData) ~= false) then
            provider.addOptions(subMenu, entry, player, contextData)
        end
    end
end

function ContextHub.BuildWorldContext(playerNum, context, worldObjects, test)
    local player
    local entries
    local square
    local contextData
    local i
    if test then
        return
    end
    player = getSpecificPlayer(playerNum)
    if not player or not context then
        return
    end
    entries, square = Selection.CollectNearbyNPCs(player, worldObjects, 3.0)
    contextData = {
        playerNum = playerNum,
        worldObjects = worldObjects,
        square = square,
    }
    if #entries <= 0 then
        return
    end
    local anyEnabled = false
    for i = 1, #entries do
        if hasEnabledProvider(entries[i], player, contextData) then
            anyEnabled = true
            break
        end
    end
    if not anyEnabled then
        return
    end
    for i = 1, #entries do
        if hasEnabledProvider(entries[i], player, contextData) then
            ContextHub.AddEntryOptions(context, player, entries[i], contextData)
        end
    end
end

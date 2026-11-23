--[[
    PNC Context Hub
    Central reusable NPC selection and right-click hub. Providers attach
    command, debug, dialogue, and future interaction options per selected NPC.
]]

PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"

local HighlightConfig = require "PNC/Conversation/InlineChat/PNC_InlineChatConfig"

local ContextHub = PNC.ContextHub
local Selection = PNC.NPCSelection
local Identity = PNC.NPCIdentityPresentation

ContextHub.Providers = ContextHub.Providers or {}
ContextHub.ProviderOrder = ContextHub.ProviderOrder or {}

local hoverByPlayer = {}

function ContextHub.IsHighlighting(playerNum, zombie)
    local hover = hoverByPlayer[playerNum]
    return hover ~= nil and hover.zombie == zombie
end

local function clearOutline(playerNum, zombie)
    if not zombie then return end
    local chat = PNC.Conversation and PNC.Conversation.InlineChat
    if playerNum == 0 and chat and chat.State then
        for _, target in pairs(chat.State.highlightedZombies or {}) do
            if target == zombie then return end
        end
    end
    zombie:setOutlineHighlight(playerNum, false)
end

local function updateHover()
    for playerNum, hover in pairs(hoverByPlayer) do
        local root = hover.root
        local visible = root:isAnyVisible()
        local menu = visible and root:topmostMenuWithMouse(getMouseX(), getMouseY())
        local zombie
        local selectionKnown = false
        -- Vanilla can briefly return no topmost menu while a context menu or
        -- submenu is still visible (mouse-over bookkeeping is updated in
        -- prerender). Keep the last valid target through that transient gap;
        -- only a concrete option/submenu selection may replace it.
        while menu do
            local option = menu == root and not menu.mouseOut
                and menu.options[menu.mouseOver] or nil
            if menu == root then
                if option then
                    selectionKnown = true
                    zombie = hover.targets[option]
                end
                break
            end
            zombie = hover.targets[menu]
            if zombie then
                selectionKnown = true
                break
            end
            menu = menu.parent
        end
        if zombie and zombie.isDead and zombie:isDead() then zombie = nil end
        if not visible then
            clearOutline(playerNum, hover.zombie)
            hover.zombie = nil
        elseif selectionKnown and hover.zombie ~= zombie then
            clearOutline(playerNum, hover.zombie)
            hover.zombie = zombie
            if zombie then
                local color = HighlightConfig.HIGHLIGHT_COLOR
                zombie:setOutlineHighlight(playerNum, true)
                if zombie.setOutlineHighlightCol then
                    zombie:setOutlineHighlightCol(playerNum, color.r, color.g, color.b, color.a)
                end
            end
        end
        if not visible then hoverByPlayer[playerNum] = nil end
    end
end

if Events and Events.OnTick then Events.OnTick.Add(updateHover) end

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

-- Reusable option presentation for all context providers. Vanilla renders a
-- notAvailable option in red and prevents selection; ordinary disabled options
-- remain grey. good/bad color variants stay available when not disabled.
function ContextHub.ApplyOptionPresentation(option, presentation)
    local color
    if not option or type(presentation) ~= "table" then return option end
    color = presentation.color
    if presentation.disabled == true then
        if color == "bad" or color == "red" then
            option.notAvailable = true
        else
            option.isDisabled = true
        end
    elseif presentation.unavailable == true then
        option.notAvailable = true
    end
    if color == "bad" or color == "red" then
        option.badColor = true
    elseif color == "good" or color == "green" then
        option.goodColor = true
    elseif type(color) == "table" then
        option.color = color
    end
    return option
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
    local known = Identity.IsNameKnown(entry)
    local label = Identity.GetContextLabel(entry)
    local distance = math.sqrt(tonumber(entry and entry.distSq) or 0)
    local debugPresentation = PNC.Runtime and PNC.Runtime.debugEnabled == true
        or entry and entry.debugRecording == true
    if debugPresentation then
        label = label
            .. " ["
            .. tostring(known and Identity.GetArchetype(entry) or "Unknown")
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
    local targets = contextData and contextData.hoverTargets
    local sync = PNC.ClientPresenceSync
    local zombie = entry.zombie or (targets and sync and sync.ResolveBodyForNPC
        and sync.ResolveBodyForNPC(entry.id, entry.snapshot))
    if targets and option and zombie and zombie.setOutlineHighlight then
        targets[option] = zombie
        targets[subMenu] = zombie
    end
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
    local previous = hoverByPlayer[playerNum]
    if previous then clearOutline(playerNum, previous.zombie) end
    hoverByPlayer[playerNum] = nil
    entries, square = Selection.CollectNearbyNPCs(player, worldObjects, 3.0)
    contextData = {
        playerNum = playerNum,
        worldObjects = worldObjects,
        square = square,
        hoverTargets = {},
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
    hoverByPlayer[playerNum] = { root = context, targets = contextData.hoverTargets }
    for i = 1, #entries do
        if hasEnabledProvider(entries[i], player, contextData) then
            ContextHub.AddEntryOptions(context, player, entries[i], contextData)
        end
    end
end

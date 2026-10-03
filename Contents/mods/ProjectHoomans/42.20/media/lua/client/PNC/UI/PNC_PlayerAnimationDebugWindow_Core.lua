require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Debug/PNC_PlayerAnimationDebug"
require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"

PNC = PNC or {}
PNC.PlayerAnimationDebugUI = PNC.PlayerAnimationDebugUI or {}

local WindowAPI = PNC.PlayerAnimationDebugUI
local Debug = PNC.PlayerAnimationDebug
local Catalog = PNC.PlayerAnimationDebugCatalog
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function resolveText(value, key, fallback)
    if value and value ~= "" and value ~= key then return value end
    return fallback
end

local TEXT = {
    title = resolveText(
        getText and PNC.Translation.GetKey("UI_PNC_PlayerAnimation_Title",
            "PLAYER ANIMATION LAB"),
        "UI_PNC_PlayerAnimation_Title", "PLAYER ANIMATION LAB"),
    play = tr("UI_PNC_PlayerAnimation_Play", "PLAY"),
    replay = tr("UI_PNC_PlayerAnimation_Replay", "REPLAY"),
    stop = tr("UI_PNC_PlayerAnimation_Stop", "STOP / RESTORE"),
    dump = tr("UI_PNC_PlayerAnimation_Dump", "DUMP TRACE"),
    loop = tr("UI_PNC_PlayerAnimation_Loop", "LOOP"),
    playerTab = tr("UI_PNC_PlayerAnimation_PlayerTab", "PLAYER"),
    zombieTab = tr("UI_PNC_PlayerAnimation_ZombieTab", "ZOMBIE"),
    allStates = tr("UI_PNC_PlayerAnimation_AllStates", "All player animations"),
    allZombieAnimations = tr("UI_PNC_PlayerAnimation_AllZombieAnimations",
        "All zombie animations"),
    nativeActions = tr("UI_PNC_PlayerAnimation_NativeActions",
        "Native player actions"),
    nativeEmotes = tr("UI_PNC_PlayerAnimation_NativeEmotes",
        "Native player emotes"),
    modPlayer = tr("UI_PNC_PlayerAnimation_ModPlayer", "Mod player AnimSets"),
    actionCategory = tr("UI_PNC_PlayerAnimation_ActionCategory", "Action: "),
    emoteCategory = tr("UI_PNC_PlayerAnimation_EmoteCategory", "Emote: "),
    modCategory = tr("UI_PNC_PlayerAnimation_ModCategory", "Mod: "),
    stateCategory = tr("UI_PNC_PlayerAnimation_StateCategory", "State: "),
    zombieCategory = tr("UI_PNC_PlayerAnimation_ZombieCategory", "Zombie: "),
    fullBodyCategory = tr("UI_PNC_PlayerAnimation_FullBodyCategory",
        "Full body: "),
    search = tr("UI_PNC_PlayerAnimation_Search", "SEARCH PLAYER ANIMATIONS"),
    noClip = tr("UI_PNC_PlayerAnimation_NoClip", "(no player clip)"),
    rawMode = tr("UI_PNC_PlayerAnimation_RawMode",
        "Native player context; imported clips use static action or full-body emote bridges."),
    noPlayer = tr("UI_PNC_PlayerAnimation_NoPlayer", "NO LOCAL PLAYER"),
    noSelection = tr("UI_PNC_PlayerAnimation_NoSelection", "NO ANIMATION SELECTED"),
    noMatching = tr("UI_PNC_PlayerAnimation_NoMatching", "No matching player animations"),
    selection = tr("UI_PNC_PlayerAnimation_Selection", "Selection"),
    state = tr("UI_PNC_PlayerAnimation_State", "Animation state"),
    action = tr("UI_PNC_PlayerAnimation_Action", "Action context"),
    emote = tr("UI_PNC_PlayerAnimation_Emote", "Emote key"),
    clip = tr("UI_PNC_PlayerAnimation_Clip", "Player clip"),
    source = tr("UI_PNC_PlayerAnimation_Source", "Animation source"),
    file = tr("UI_PNC_PlayerAnimation_File", "File"),
    playback = tr("UI_PNC_PlayerAnimation_Playback", "Playback"),
    time = tr("UI_PNC_PlayerAnimation_TrackTime", "Action time"),
    result = tr("UI_PNC_PlayerAnimation_Result", "Last result"),
    player = tr("UI_PNC_PlayerAnimation_Player", "Player"),
    looped = tr("UI_PNC_PlayerAnimation_Looped", "looped"),
    oneShot = tr("UI_PNC_PlayerAnimation_OneShot", "one-shot"),
    loopRequest = tr("UI_PNC_PlayerAnimation_LoopRequest", "Loop request"),
    route = tr("UI_PNC_PlayerAnimation_Route", "Route"),
    compatibility = tr("UI_PNC_PlayerAnimation_Compatibility",
        "Compatibility"),
    sourceState = tr("UI_PNC_PlayerAnimation_SourceState", "Source state"),
    bridge = tr("UI_PNC_PlayerAnimation_Bridge", "Player bridge"),
    previewMode = tr("UI_PNC_PlayerAnimation_PreviewMode", "Preview mode"),
    fullBody = tr("UI_PNC_PlayerAnimation_FullBody", "Full-body emote bridge"),
    actionBridge = tr("UI_PNC_PlayerAnimation_ActionBridge",
        "Player action bridge"),
    nativeEmote = tr("UI_PNC_PlayerAnimation_NativeEmote",
        "Native player emote"),
    auditOnly = tr("UI_PNC_PlayerAnimation_AuditOnly", "AUDIT ONLY"),
    on = tr("UI_PNC_PlayerAnimation_On", "ON"),
    off = tr("UI_PNC_PlayerAnimation_Off", "OFF"),
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function searchPart(value)
    return value == nil and "" or tostring(value)
end

local function searchText(entry)
    return lower(table.concat({
        searchPart(entry.state), searchPart(entry.folder),
        searchPart(entry.file), searchPart(entry.node), searchPart(entry.anim),
        searchPart(entry.extends), searchPart(entry.action),
        searchPart(entry.emote), searchPart(entry.source),
        searchPart(entry.sourceState), searchPart(entry.route),
        searchPart(entry.compatibility), searchPart(entry.bridgeFile),
        searchPart(entry.unsupportedReason), searchPart(entry.fullBody),
    }, " "))
end

local function drawAnimationItem(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.52, 0.78)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local title = "[" .. tostring(entry.sourceState or entry.state or "?")
        .. "] " .. tostring(entry.node or entry.file or "?")
    if entry.playable ~= true then title = title .. " [" .. TEXT.auditOnly .. "]" end
    local clip = tostring(entry.anim or TEXT.noClip)
    if entry.fullBody == true then clip = TEXT.fullBody .. " • " .. clip end
    local file = tostring(entry.folder or "") .. "/" .. tostring(entry.file or "")
    if entry.playable ~= true then
        clip = clip .. " - " .. tostring(entry.unsupportedReason or "")
    end
    list:drawText(Layout.Ellipsize(title, UIFont.Small,
        list:getWidth() - 14), 8, y + 4,
        entry.playable == true and 0.92 or 1.00,
        entry.playable == true and 0.94 or 0.62,
        entry.playable == true and 1.00 or 0.35, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(clip, UIFont.Small,
        list:getWidth() - 14), 8, y + 21,
        0.62, 0.82, 0.95, 1, UIFont.Small)
    list:drawText(Layout.Ellipsize(file, UIFont.Small,
        list:getWidth() - 14), 8, y + 38,
        0.70, 0.72, 0.74, 1, UIFont.Small)
    return y + list.itemheight
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

local function countEntries(entries, predicate)
    local count = 0
    for _, entry in ipairs(entries or {}) do
        if predicate(entry) then count = count + 1 end
    end
    return count
end

local function categoryLabel(prefix, value, count)
    return prefix .. tostring(value) .. " (" .. tostring(count) .. ")"
end

local function buildFilters(source)
    local entries = Catalog.entries or {}
    local filters = {}
    local scopedCount = countEntries(entries, function(entry)
        return source == "zombie" and entry.source == "zombie"
            or source == "player" and entry.source ~= "zombie"
    end)
    filters[#filters + 1] = {
        label = source == "zombie" and TEXT.allZombieAnimations
            or TEXT.allStates,
    }

    if source == "player" then
        local nativeActions = countEntries(entries, function(entry)
            return entry.source == "player_native" and entry.mode == "action"
        end)
        local nativeEmotes = countEntries(entries, function(entry)
            return entry.source == "player_native" and entry.mode == "emote"
        end)
        local modPlayer = countEntries(entries, function(entry)
            return entry.source == "player_mod"
        end)
        if nativeActions > 0 then
            filters[#filters + 1] = {
                label = categoryLabel(TEXT.actionCategory,
                    TEXT.nativeActions, nativeActions),
                source = "player_native",
                mode = "action",
            }
        end
        if nativeEmotes > 0 then
            filters[#filters + 1] = {
                label = categoryLabel(TEXT.emoteCategory,
                    TEXT.nativeEmotes, nativeEmotes),
                source = "player_native",
                mode = "emote",
            }
        end
        if modPlayer > 0 then
            filters[#filters + 1] = {
                label = categoryLabel(TEXT.modCategory, TEXT.modPlayer,
                    modPlayer),
                source = "player_mod",
            }
        end
    end

    local byKey = {}
    local categories = {}
    for _, entry in ipairs(entries) do
        local inTab = source == "zombie" and entry.source == "zombie"
            or source == "player" and entry.source ~= "zombie"
        if inTab then
            local state = tostring(entry.state or entry.folder or "unknown")
            local mode = tostring(entry.mode or "action")
            local entrySource = tostring(entry.source or "")
            local key = entrySource .. "\000" .. mode .. "\000" .. state
            local category = byKey[key]
            if not category then
                local prefix
                if source == "zombie" then
                    prefix = entry.fullBody == true and TEXT.fullBodyCategory
                        or TEXT.zombieCategory
                elseif entrySource == "player_mod" then
                    prefix = TEXT.modCategory
                elseif mode == "emote" then
                    prefix = TEXT.emoteCategory
                else
                    prefix = TEXT.actionCategory
                end
                category = {
                    label = prefix .. state,
                    source = entrySource,
                    mode = mode,
                    state = state,
                    count = 0,
                }
                byKey[key] = category
                categories[#categories + 1] = category
            end
            category.count = category.count + 1
        end
    end
    table.sort(categories, function(left, right)
        return left.label < right.label
    end)
    for _, category in ipairs(categories) do
        category.label = category.label .. " (" .. tostring(category.count)
            .. ")"
        filters[#filters + 1] = category
    end
    -- Keep the count calculation explicit so a malformed catalog cannot make
    -- an empty source tab look populated.
    filters[1].label = filters[1].label .. " (" .. tostring(scopedCount)
        .. ")"
    return filters
end

local function matchesFilter(entry, source, filter)
    local inTab = source == "zombie" and entry.source == "zombie"
        or source == "player" and entry.source ~= "zombie"
    if not inTab then return false end
    if filter.source and entry.source ~= filter.source then return false end
    if filter.mode and entry.mode ~= filter.mode then return false end
    if filter.state and entry.state ~= filter.state then return false end
    return true
end

ISPNCPlayerAnimationDebugWindow = PsychopatzWindow:derive(
    "ISPNCPlayerAnimationDebugWindow")


WindowAPI.Internal = WindowAPI.Internal or {}
local Internal = WindowAPI.Internal
Internal.TEXT = TEXT
Internal.Debug = Debug
Internal.Catalog = Catalog
Internal.UI = UI
Internal.Layout = Layout
Internal.addDetail = addDetail
Internal.tr = tr
Internal.lower = lower
Internal.searchText = searchText
Internal.drawAnimationItem = drawAnimationItem
Internal.buildFilters = buildFilters
Internal.matchesFilter = matchesFilter
Internal.setButtonState = setButtonState

return WindowAPI

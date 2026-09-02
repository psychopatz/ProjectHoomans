require "PNC/Audio/PNC_NPCVoice"
require "PNC/Audio/PNC_NPCVoiceCatalog"

PNC = PNC or {}
PNC.AudioDebug = PNC.AudioDebug or {}

local Model = PNC.AudioDebug
local Voice = PNC.NPCVoice

Model.MIN_VOICE_TYPE = 0
Model.MAX_VOICE_TYPE = 3
Model.MIN_PITCH = -100
Model.MAX_PITCH = 100

local function call(object, method, ...)
    if not object then return nil end
    local lookupOK, fn = pcall(function()
        return object[method]
    end)
    if not lookupOK then return nil end
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function staticCall(class, method, ...)
    if not class then return nil end
    local lookupOK, fn = pcall(function()
        return class[method]
    end)
    if not lookupOK then return nil end
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    return ok and value or nil
end

local function listValues(list)
    local result = {}
    local size = call(list, "size")
    if not size or not list then
        return result
    end
    for index = 0, (tonumber(size) or 0) - 1 do
        local value = call(list, "get", index)
        if value ~= nil then result[#result + 1] = value end
    end
    return result
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(maximum, value))
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function addUnique(list, index, entry)
    local key = tostring(entry.suffix or "")
    if key == "" or index[key] then return false end
    index[key] = true
    list[#list + 1] = entry
    return true
end

local FALLBACK_STYLES = {
    { name = "Kate", prefix = "VoiceFemale", voiceType = 0, bodyTypeDefault = 1 },
    { name = "Casey-Jo", prefix = "VoiceFemale", voiceType = 1, bodyTypeDefault = 1 },
    { name = "Maryanne", prefix = "VoiceFemale", voiceType = 2, bodyTypeDefault = 1 },
    { name = "Janine", prefix = "VoiceFemale", voiceType = 3, bodyTypeDefault = 1 },
    { name = "Bob", prefix = "VoiceMale", voiceType = 0, bodyTypeDefault = 2 },
    { name = "Hank", prefix = "VoiceMale", voiceType = 1, bodyTypeDefault = 2 },
    { name = "James", prefix = "VoiceMale", voiceType = 2, bodyTypeDefault = 2 },
    { name = "Chris", prefix = "VoiceMale", voiceType = 3, bodyTypeDefault = 2 },
}

local BASE_VOICE_SUFFIXES = {
    { "MeleeStab", "Combat" },
    { "MeleeStabOnGround", "Combat" },
    { "MeleeAttackHeavy", "Combat" },
    { "MeleeAttack", "Combat" },
    { "MeleeShove", "Combat" },
    { "MeleeStomp", "Combat" },
    { "PainFromBite", "Pain" },
    { "PainFromScratch", "Pain" },
    { "PainFromLacerate", "Pain" },
    { "PainFromGlassCut", "Pain" },
    { "PainFromFallHigh", "Pain" },
    { "PainFromFallLow", "Pain" },
    { "PainFromHitBlunt", "Pain" },
    { "PainFromRunIntoWall", "Pain" },
    { "PainMoodle", "Pain" },
    { "ShoutHey", "Callout" },
    { "ShoutMegaphoneHey", "Callout" },
    { "WhisperHey", "Callout" },
    { "WhisperPsst", "Callout" },
    { "WhisperMegaphoneHey", "Callout" },
    { "WhisperMegaphonePsst", "Callout" },
    { "LureTsk", "Callout" },
    { "LureCmon", "Callout" },
    { "SneezeLight", "Respiratory" },
    { "SneezeHeavy", "Respiratory" },
    { "Cough", "Respiratory" },
    { "MuffledCough", "Respiratory" },
    { "DrunkHic", "Respiratory" },
    { "DeathAlone", "Death" },
    { "DeathEaten", "Death" },
    { "DeathFall", "Death" },
    { "JumpLow", "Effort" },
    { "JumpHigh", "Effort" },
    { "ClimbWindow", "Effort" },
    { "Exercise", "Effort" },
    { "FreezeShiver", "Effort" },
    { "CorpseDragging", "Effort" },
    { "CorpseHighEffort", "Effort" },
    { "CorpseLowEffort", "Effort" },
    { "ApplyBandage", "Action" },
    { "Vomit", "Action" },
    { "Sleep", "Action" },
    { "Smoke", "Action" },
    { "SighBored", "Mood" },
    { "SighReliefed", "Mood" },
    { "SighSad", "Mood" },
}

local function readStyle(style)
    local prefix = call(style, "getPrefix")
    local name = call(style, "getName")
    local voiceType = call(style, "getVoiceType")
    local bodyTypeDefault = call(style, "getBodyTypeDefault")
    if not prefix or tostring(prefix) == "" then return nil end
    return {
        name = tostring(name or prefix),
        prefix = tostring(prefix),
        voiceType = math.floor(clamp(voiceType, Model.MIN_VOICE_TYPE, Model.MAX_VOICE_TYPE)),
        bodyTypeDefault = math.floor(tonumber(bodyTypeDefault) or 0),
    }
end

function Model.GetVoiceStyles()
    if Model.voiceStyles then return Model.voiceStyles end
    local styles = {}
    local raw = nil
    if getAllVoiceStyles then
        local ok, value = pcall(getAllVoiceStyles)
        if ok then raw = value end
    end
    for _, style in ipairs(listValues(raw)) do
        local value = readStyle(style)
        if value then styles[#styles + 1] = value end
    end
    if #styles == 0 then
        for _, style in ipairs(FALLBACK_STYLES) do
            styles[#styles + 1] = {
                name = style.name,
                prefix = style.prefix,
                voiceType = style.voiceType,
                bodyTypeDefault = style.bodyTypeDefault,
            }
        end
    end
    table.sort(styles, function(left, right)
        return lower(left.name) < lower(right.name)
    end)
    Model.voiceStyles = styles
    return styles
end

function Model.GetVoiceEvents()
    if Model.voiceEvents then return Model.voiceEvents end
    local events = {}
    local index = {}
    for _, definition in ipairs(BASE_VOICE_SUFFIXES) do
        addUnique(events, index, {
            suffix = definition[1],
            category = definition[2],
        })
    end
    local catalog = Voice and Voice.Catalog
    local catalogEvents = catalog and catalog.All and catalog.All() or {}
    for eventID, definition in pairs(catalogEvents) do
        local suffix = definition and definition.suffix
        if suffix and index[tostring(suffix)] then
            for _, event in ipairs(events) do
                if event.suffix == tostring(suffix) then
                    event.semanticID = tostring(eventID)
                    break
                end
            end
        end
    end
    table.sort(events, function(left, right)
        if left.category == right.category then
            return left.suffix < right.suffix
        end
        return left.category < right.category
    end)
    Model.voiceEvents = events
    return events
end

function Model.GetCurrentPlayer()
    if PNC.PlayerVoice and PNC.PlayerVoice.GetPlayer then
        local player = PNC.PlayerVoice.GetPlayer()
        if player then return player end
    end
    if getSpecificPlayer then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok and player then return player end
    end
    return nil
end

function Model.GetPlayerVoiceState(player)
    player = player or Model.GetCurrentPlayer()
    local descriptor = player and call(player, "getDescriptor") or nil
    local prefix = tostring(
        call(descriptor, "getVoicePrefix")
            or call(player, "getVoicePrefix")
            or "VoiceMale"
    )
    if prefix ~= "VoiceFemale" and prefix ~= "VoiceMale" then
        prefix = "VoiceMale"
    end
    local voiceType = math.floor(clamp(
        call(descriptor, "getVoiceType") or call(player, "getVoiceType"),
        Model.MIN_VOICE_TYPE,
        Model.MAX_VOICE_TYPE
    ))
    local pitch = clamp(
        call(descriptor, "getVoicePitch") or call(player, "getVoicePitch"),
        Model.MIN_PITCH,
        Model.MAX_PITCH
    )
    local styleIndex = 1
    for index, style in ipairs(Model.GetVoiceStyles()) do
        if style.prefix == prefix and style.voiceType == voiceType then
            styleIndex = index
            break
        end
    end
    return {
        prefix = prefix,
        voiceType = voiceType,
        pitch = pitch,
        styleIndex = styleIndex,
    }
end

function Model.BuildVoiceProfile(style, voiceType, pitch)
    style = style or Model.GetVoiceStyles()[1] or FALLBACK_STYLES[1]
    return {
        name = tostring(style.name or style.prefix),
        prefix = tostring(style.prefix or "VoiceMale"),
        voiceType = math.floor(clamp(
            voiceType == nil and style.voiceType or voiceType,
            Model.MIN_VOICE_TYPE,
            Model.MAX_VOICE_TYPE
        )),
        pitch = clamp(pitch, Model.MIN_PITCH, Model.MAX_PITCH),
        isFemale = tostring(style.prefix) == "VoiceFemale",
    }
end

function Model.PlayDialogue(player, event, profile)
    if not player then return 0, "player_unavailable" end
    if not event or not event.suffix then return 0, "voice_event_unavailable" end
    if not Voice or type(Voice.PlayPreview) ~= "function" then
        return 0, "voice_backend_unavailable"
    end
    Model.StopSFX()
    local ok, handle = pcall(Voice.PlayPreview, player, event.suffix, profile)
    if not ok or not handle or handle == 0 then
        return 0, "voice_play_failed"
    end
    return handle, nil
end

function Model.StopDialogue(player)
    if not player or not Voice or type(Voice.Stop) ~= "function" then
        return false
    end
    local ok, stopped = pcall(Voice.Stop, player)
    return ok and stopped == true
end

local function getSFXClass()
    return GameSounds
end

function Model.InvalidateSFXCatalog()
    Model.sfxCatalog = nil
    Model.sfxCategories = nil
end

function Model.GetSFXCatalog()
    if Model.sfxCatalog then return Model.sfxCatalog end
    local sounds = {}
    local index = {}
    local categories = staticCall(getSFXClass(), "getCategories")
    for _, category in ipairs(listValues(categories)) do
        local categoryName = tostring(category or "")
        if categoryName ~= "" then
            local rawSounds = staticCall(getSFXClass(), "getSoundsInCategory", categoryName)
            for _, sound in ipairs(listValues(rawSounds)) do
                local name = tostring(call(sound, "getName") or "")
                if name ~= "" and not index[name] then
                    index[name] = true
                    sounds[#sounds + 1] = {
                        name = name,
                        category = tostring(call(sound, "getCategory") or categoryName),
                    }
                end
            end
        end
    end
    table.sort(sounds, function(left, right)
        return lower(left.name) < lower(right.name)
    end)
    Model.sfxCatalog = sounds
    return sounds
end

function Model.GetSFXCategories()
    if Model.sfxCategories then return Model.sfxCategories end
    local categories = { "ALL" }
    local seen = { ALL = true }
    for _, sound in ipairs(Model.GetSFXCatalog()) do
        local category = tostring(sound.category or "")
        if category ~= "" and not seen[category] then
            seen[category] = true
            categories[#categories + 1] = category
        end
    end
    table.sort(categories, function(left, right)
        if left == right then return false end
        if left == "ALL" then return true end
        if right == "ALL" then return false end
        return lower(left) < lower(right)
    end)
    Model.sfxCategories = categories
    return categories
end

function Model.GetSFXEntries(category, query)
    local result = {}
    local wantedCategory = tostring(category or "ALL")
    local wantedQuery = lower(query)
    for _, sound in ipairs(Model.GetSFXCatalog()) do
        local categoryMatches = wantedCategory == "ALL"
            or sound.category == wantedCategory
        local searchMatches = wantedQuery == ""
            or string.find(lower(sound.name .. " " .. sound.category), wantedQuery, 1, true)
        if categoryMatches and searchMatches then
            result[#result + 1] = sound
        end
    end
    return result
end

function Model.RefreshSFXCatalog()
    Model.InvalidateSFXCatalog()
    return Model.GetSFXCatalog()
end

function Model.PlaySFX(name, player)
    name = tostring(name or "")
    if name == "" then return false, "sfx_unavailable" end
    Model.StopDialogue(player)
    Model.StopSFX()
    local known = staticCall(getSFXClass(), "isKnownSound", name)
    if known ~= true then return false, "sfx_unknown" end
    local ok = pcall(GameSounds.previewSound, name)
    return ok, ok and nil or "sfx_play_failed"
end

function Model.StopSFX()
    if not GameSounds or type(GameSounds.stopPreview) ~= "function" then
        return false
    end
    local ok = pcall(GameSounds.stopPreview)
    return ok
end

function Model.IsSFXPlaying()
    local value = staticCall(getSFXClass(), "isPreviewPlaying")
    return value == true
end

function Model.StopAll(player)
    Model.StopDialogue(player)
    Model.StopSFX()
end

return Model

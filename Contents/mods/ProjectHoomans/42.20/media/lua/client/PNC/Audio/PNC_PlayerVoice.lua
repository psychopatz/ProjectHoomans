-- Local player voice identity for the shared PBrainZ TTS gateway.
-- The game descriptor owns the player's voice prefix, type, and pitch. This
-- module only reads that identity and converts it to a compact TTS binding.

PNC = PNC or {}
PNC.PlayerVoice = PNC.PlayerVoice or {}

local Voice = PNC.PlayerVoice

Voice.MIN_PITCH = -48
Voice.MAX_PITCH = 48

local function call(target, method, ...)
    if not target or type(target[method]) ~= "function" then return nil end
    local ok, value = pcall(target[method], target, ...)
    return ok and value or nil
end

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function currentPlayer()
    if getSpecificPlayer then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok and player then return player end
    end
    if getPlayer then
        local ok, player = pcall(getPlayer)
        if ok then return player end
    end
    return nil
end

local function isFemale(player, descriptor)
    local value = call(descriptor, "isFemale")
    if value ~= nil then return value == true end
    value = call(player, "isFemale")
    return value == true
end

local function validPrefix(prefix, female)
    prefix = trim(prefix)
    if prefix == "VoiceFemale" or prefix == "VoiceMale" then
        return prefix
    end
    return female and "VoiceFemale" or "VoiceMale"
end

local function voiceID(message, player)
    local id = message and (message.playerUUID or message.speakerID) or nil
    id = trim(id)
    if id ~= "" and id ~= "unbound" and id ~= "unbound-player" then
        return id
    end
    local username = trim(call(player, "getUsername"))
    if username ~= "" then return username end
    local onlineID = trim(call(player, "getOnlineID"))
    return onlineID ~= "" and onlineID or nil
end

function Voice.GetPlayer()
    return currentPlayer()
end

function Voice.GetProfile(message, player)
    player = player or currentPlayer()
    if not player then return nil end
    local descriptor = call(player, "getDescriptor")
    local female = isFemale(player, descriptor)
    local prefix = validPrefix(
        call(descriptor, "getVoicePrefix") or call(player, "getVoicePrefix"),
        female
    )
    local voiceType = tonumber(
        call(descriptor, "getVoiceType") or call(player, "getVoiceType")
    )
    voiceType = math.max(0, math.min(3, math.floor(voiceType or 0)))
    local pitch = tonumber(
        call(descriptor, "getVoicePitch") or call(player, "getVoicePitch")
    ) or 0
    pitch = math.max(Voice.MIN_PITCH, math.min(Voice.MAX_PITCH, pitch))

    local playerID = voiceID(message, player)
    if not playerID then return nil end
    return {
        speaker_id = playerID,
        speaker_kind = "player",
        player_uuid = playerID,
        slot = prefix .. ":" .. tostring(voiceType),
        pitch = math.floor(pitch + (pitch >= 0 and 0.5 or -0.5)),
        prefix = prefix,
        voiceType = voiceType,
        isFemale = female,
    }
end

return Voice

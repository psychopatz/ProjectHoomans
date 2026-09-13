--
-- PNC NPC Combat Audio
-- Presents authoritative melee audio events exactly once per body.
--

PNC = PNC or {}
PNC.NPCCombatAudio = PNC.NPCCombatAudio or {}

local Audio = PNC.NPCCombatAudio
local Voice = PNC.NPCVoice
local STATE_BY_BODY = setmetatable({}, { __mode = "k" })

local function stateFor(body)
    local state = STATE_BY_BODY[body]
    if not state then
        state = {}
        STATE_BY_BODY[body] = state
    end
    return state
end

local function playBodySound(body, sound)
    local emitter
    local ok
    local handle
    sound = sound and tostring(sound) or nil
    if not body or not sound or sound == "" then return false end
    if body.getEmitter then
        ok, emitter = pcall(body.getEmitter, body)
        if ok and emitter and emitter.playSound then
            ok, handle = pcall(emitter.playSound, emitter, sound)
            if ok and handle ~= nil then return true end
        end
    end
    if body.playSound then
        ok = pcall(body.playSound, body, sound)
        return ok
    end
    return false
end

local function playVoice(snapshot, body, suffix)
    local fallback
    if not suffix or suffix == "" then return false end
    if Voice and Voice.PlayLocal then
        return Voice.PlayLocal(body, suffix, { snapshot = snapshot }) ~= nil
    end
    if not body or not body.playSound then return false end
    fallback = snapshot and snapshot.isFemale
        and "VoiceFemale"
        or "VoiceMale"
    return pcall(body.playSound, body, fallback .. tostring(suffix))
end

local function identityKey(snapshot, body)
    local id = snapshot and snapshot.id or "body"
    local lease = snapshot and snapshot.liveBodyLease or nil
    if lease == nil and body and body.getOnlineID then
        local ok, onlineID = pcall(body.getOnlineID, body)
        if ok then lease = onlineID end
    end
    return tostring(id) .. ":" .. tostring(lease or "")
end

function Audio.Observe(snapshot, body)
    local visual
    local audio
    local state
    local attackKey
    local hitKey
    if type(snapshot) ~= "table" or not body then return false end
    visual = snapshot.visualState
    audio = visual and visual.attackAudio or nil
    if type(audio) ~= "table" then return false end
    state = stateFor(body)
    attackKey = identityKey(snapshot, body)
        .. ":"
        .. tostring(audio.sequence or visual.attackStartedAt or "")
    if state.startKey ~= attackKey then
        state.startKey = attackKey
        playBodySound(body, audio.swingSound)
        playVoice(snapshot, body, audio.voiceSuffix)
    end
    if audio.hitSequence ~= nil and tonumber(audio.hitSequence) > 0 then
        hitKey = attackKey .. ":hit:" .. tostring(audio.hitSequence)
        if state.hitKey ~= hitKey then
            state.hitKey = hitKey
            playBodySound(body, audio.hitSound)
        end
    end
    return true
end

function Audio.Reset()
    STATE_BY_BODY = setmetatable({}, { __mode = "k" })
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Audio.Reset)
end

return Audio

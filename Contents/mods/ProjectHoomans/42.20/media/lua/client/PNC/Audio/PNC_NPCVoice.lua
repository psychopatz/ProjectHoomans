--[[
    PNC client-only NPC voice profiles and emitters.

    PZ separates positional audio from WorldSoundManager events:
      * PlayLocal() plays audio without creating an AI-hearing event.
      * PlayWorld() additionally creates a local world-sound event.

    In multiplayer, this module is local to the client.  PlayWorld() affects
    the local WorldSoundManager; server-authoritative zombie reactions still
    require a server/network event by design.
]]

PNC = PNC or {}
PNC.NPCVoice = PNC.NPCVoice or {}

local Voice = PNC.NPCVoice
local Identity = PNC.Identity

Voice.MODE_LOCAL = "local"
Voice.MODE_WORLD = "world"
Voice.DEFAULT_SOUND = "ShoutHey"
Voice.DEFAULT_WORLD_RADIUS = 18
Voice.DEFAULT_WORLD_VOLUME = 18
Voice.DEFAULT_STRESS_HUMANS = false

-- Keep the variation audible without making every NPC sound artificial.
Voice.FEMALE_PITCH_MIN = -8
Voice.FEMALE_PITCH_MAX = 18
Voice.MALE_PITCH_MIN = -18
Voice.MALE_PITCH_MAX = 8

local FALLBACK_STYLES = {
    female = {
        { prefix = "VoiceFemale", voiceType = 0, name = "Kate" },
        { prefix = "VoiceFemale", voiceType = 1, name = "Casey-Jo" },
        { prefix = "VoiceFemale", voiceType = 2, name = "Maryanne" },
        { prefix = "VoiceFemale", voiceType = 3, name = "Janine" },
    },
    male = {
        { prefix = "VoiceMale", voiceType = 0, name = "Bob" },
        { prefix = "VoiceMale", voiceType = 1, name = "Hank" },
        { prefix = "VoiceMale", voiceType = 2, name = "James" },
        { prefix = "VoiceMale", voiceType = 3, name = "Chris" },
    },
}

local PROFILE_BY_BODY = setmetatable({}, { __mode = "k" })
local ACTIVE_BY_BODY = setmetatable({}, { __mode = "k" })

local function isServerRuntime()
    return isServer and isServer() == true
end

local function getGender(snapshot, body)
    if snapshot and snapshot.isFemale ~= nil then
        return snapshot.isFemale == true
    end
    if body and body.isFemale then
        local ok, value = pcall(body.isFemale, body)
        if ok then return value == true end
    end
    return false
end

local function getSeed(snapshot, body)
    local identity = snapshot and snapshot.identity or nil
    local seed = snapshot and snapshot.identitySeed or nil
    local fallback
    if seed == nil and identity then
        seed = identity.seed
    end
    fallback = snapshot and snapshot.id or nil
    if fallback == nil and body and body.getModData then
        local ok, modData = pcall(body.getModData, body)
        if ok and modData then
            fallback = modData.PNC_UUID
        end
    end
    return Identity and Identity.NormalizeSeed
        and Identity.NormalizeSeed(seed, fallback or "npc_voice")
        or math.max(1, math.floor(tonumber(seed) or 1))
end

local function readStyle(style)
    local prefix
    local voiceType
    local bodyTypeDefault
    local name
    if not style then return nil end
    if style.getPrefix then
        local ok, value = pcall(style.getPrefix, style)
        if ok then prefix = value end
    end
    if style.getVoiceType then
        local ok, value = pcall(style.getVoiceType, style)
        if ok then voiceType = value end
    end
    if style.getBodyTypeDefault then
        local ok, value = pcall(style.getBodyTypeDefault, style)
        if ok then bodyTypeDefault = value end
    end
    if style.getName then
        local ok, value = pcall(style.getName, style)
        if ok then name = value end
    end
    if not prefix or prefix == "" then return nil end
    return {
        prefix = tostring(prefix),
        voiceType = math.max(
            0,
            math.min(3, math.floor(tonumber(voiceType) or 0))
        ),
        bodyTypeDefault = math.floor(tonumber(bodyTypeDefault) or 0),
        name = tostring(name or prefix),
    }
end

local function getStyles(isFemale)
    local styles
    local result = {}
    local wantedPrefix = isFemale and "VoiceFemale" or "VoiceMale"
    local wantedBodyType = isFemale and 1 or 2
    if getAllVoiceStyles then
        local ok, value = pcall(getAllVoiceStyles)
        if ok then styles = value end
    end
    if styles and styles.size and styles.get then
        local ok, size = pcall(styles.size, styles)
        if ok then
            local i
            for i = 0, (tonumber(size) or 0) - 1 do
                local gotStyle
                local style
                gotStyle, style = pcall(styles.get, styles, i)
                if gotStyle then
                    style = readStyle(style)
                    if style and (
                        style.bodyTypeDefault == wantedBodyType
                        or style.bodyTypeDefault == 0
                            and style.prefix == wantedPrefix
                    ) then
                        result[#result + 1] = style
                    end
                end
            end
        end
    end
    if #result > 0 then return result end
    return FALLBACK_STYLES[isFemale and "female" or "male"]
end

local function buildProfile(snapshot, body)
    local isFemale = getGender(snapshot, body)
    local genderKey = isFemale and "female" or "male"
    local seed = getSeed(snapshot, body)
    local styles = getStyles(isFemale)
    local styleIndex
    local style
    local pitchMin
    local pitchMax
    local pitch
    if Identity and Identity.Index then
        styleIndex = Identity.Index(
            seed,
            "voice:style:" .. genderKey,
            #styles
        )
    else
        styleIndex = 1
    end
    style = styles[styleIndex] or styles[1]
    if isFemale then
        pitchMin = Voice.FEMALE_PITCH_MIN
        pitchMax = Voice.FEMALE_PITCH_MAX
    else
        pitchMin = Voice.MALE_PITCH_MIN
        pitchMax = Voice.MALE_PITCH_MAX
    end
    if Identity and Identity.Range then
        pitch = Identity.Range(
            seed,
            "voice:pitch:" .. genderKey,
            pitchMin,
            pitchMax
        )
    else
        pitch = pitchMin
    end
    return {
        seed = seed,
        isFemale = isFemale,
        gender = genderKey,
        name = style.name,
        prefix = style.prefix,
        voiceType = style.voiceType,
        pitch = pitch,
        cacheKey = tostring(seed)
            .. ":" .. genderKey
            .. ":" .. tostring(style.prefix)
            .. ":" .. tostring(style.voiceType)
            .. ":" .. tostring(pitch),
    }
end

local function stopActive(body)
    local active = body and ACTIVE_BY_BODY[body] or nil
    local emitter
    if not active or not body or not body.getEmitter then return false end
    local ok, value = pcall(body.getEmitter, body)
    if not ok then return false end
    emitter = value
    if emitter and emitter.stopSoundLocal then
        pcall(emitter.stopSoundLocal, emitter, active.handle)
        ACTIVE_BY_BODY[body] = nil
        return true
    end
    return false
end

local function resolveAlias(profile, sound)
    local alias = tostring(sound or Voice.DEFAULT_SOUND)
    if alias == "" then return nil end
    if string.sub(alias, 1, 5) == "Voice" then
        return alias
    end
    return profile.prefix .. alias
end

local function applyVoiceParameters(emitter, handle, profile)
    if not emitter or not emitter.setParameterValueByName then
        return false
    end
    -- CharacterSoundEmitter routes this method to its extra emitter.  The
    -- two play methods below intentionally use that same extra lane, so the
    -- FMOD parameters apply to the sound we just started.
    pcall(
        emitter.setParameterValueByName,
        emitter,
        handle,
        "CharacterVoiceType",
        profile.voiceType
    )
    pcall(
        emitter.setParameterValueByName,
        emitter,
        handle,
        "CharacterVoicePitch",
        profile.pitch
    )
    return true
end

local function play(body, sound, mode, options)
    local profile
    local emitter
    local alias
    local ok
    local handle
    local radius
    local volume
    local stressHumans
    if isServerRuntime() or not body then return 0, nil end
    options = options or {}
    profile = options.profile or Voice.Bind(options.snapshot, body)
    if not profile then return 0, nil end
    alias = resolveAlias(profile, sound)
    if not alias or not body.playSoundLocal then return 0, profile end
    stopActive(body)
    ok, handle = pcall(body.playSoundLocal, body, alias)
    if not ok or not handle or handle == 0 then
        return 0, profile
    end
    ok, emitter = pcall(body.getEmitter, body)
    if ok then
        applyVoiceParameters(emitter, handle, profile)
    end
    ACTIVE_BY_BODY[body] = {
        handle = handle,
        alias = alias,
        mode = mode,
    }
    if mode == Voice.MODE_WORLD
        and body.addWorldSoundUnlessInvisible
    then
        radius = math.max(
            0,
            math.floor(tonumber(options.radius) or Voice.DEFAULT_WORLD_RADIUS)
        )
        volume = math.max(
            0,
            math.floor(tonumber(options.volume) or Voice.DEFAULT_WORLD_VOLUME)
        )
        stressHumans = options.stressHumans
        if stressHumans == nil then
            stressHumans = Voice.DEFAULT_STRESS_HUMANS
        else
            stressHumans = stressHumans == true
        end
        pcall(
            body.addWorldSoundUnlessInvisible,
            body,
            radius,
            volume,
            stressHumans
        )
    end
    return handle, profile
end

local function playAt(snapshot, sound, mode, options)
    local profile
    local alias
    local world
    local emitter
    local handle
    local x
    local y
    local z
    local radius
    local volume
    local stressHumans
    local ok
    if isServerRuntime() or type(snapshot) ~= "table" then
        return 0, nil
    end
    options = options or {}
    profile = options.profile or Voice.GetProfile(snapshot, nil)
    if not profile then return 0, nil end
    alias = resolveAlias(profile, sound)
    x = math.floor(tonumber(snapshot.x) or 0)
    y = math.floor(tonumber(snapshot.y) or 0)
    z = math.floor(tonumber(snapshot.z) or 0)
    if not alias or not getWorld then return 0, profile end
    ok, world = pcall(getWorld)
    if not ok or not world or not world.getFreeEmitter then
        return 0, profile
    end
    ok, emitter = pcall(
        world.getFreeEmitter,
        world,
        x + 0.5,
        y + 0.5,
        z
    )
    if not ok or not emitter then return 0, profile end
    if emitter.playSoundImpl then
        ok, handle = pcall(
            emitter.playSoundImpl,
            emitter,
            alias,
            nil
        )
    elseif emitter.playSound then
        ok, handle = pcall(emitter.playSound, emitter, alias)
    end
    if not ok or not handle or handle == 0 then
        return 0, profile
    end
    applyVoiceParameters(emitter, handle, profile)
    if mode == Voice.MODE_WORLD
        and WorldSoundManager
        and WorldSoundManager.instance
        and WorldSoundManager.instance.addSound
    then
        radius = math.max(
            0,
            math.floor(tonumber(options.radius) or Voice.DEFAULT_WORLD_RADIUS)
        )
        volume = math.max(
            0,
            math.floor(tonumber(options.volume) or Voice.DEFAULT_WORLD_VOLUME)
        )
        stressHumans = options.stressHumans
        if stressHumans == nil then
            stressHumans = Voice.DEFAULT_STRESS_HUMANS
        else
            stressHumans = stressHumans == true
        end
        pcall(
            WorldSoundManager.instance.addSound,
            WorldSoundManager.instance,
            nil,
            x,
            y,
            z,
            radius,
            volume,
            stressHumans
        )
    end
    return handle, profile
end

function Voice.GetProfile(snapshot, body)
    if isServerRuntime() or (not body and not snapshot) then return nil end
    local profile = body and PROFILE_BY_BODY[body] or nil
    local seed = getSeed(snapshot, body)
    local isFemale = getGender(snapshot, body)
    local snapshotHasSeed = snapshot
        and (
            snapshot.identitySeed ~= nil
            or snapshot.identity
                and snapshot.identity.seed ~= nil
        )
    local snapshotHasGender = snapshot and snapshot.isFemale ~= nil
    if profile
        and not snapshotHasSeed
        and not snapshotHasGender
    then
        return profile
    end
    if profile
        and profile.seed == seed
        and profile.isFemale == isFemale
    then
        return profile
    end
    local fresh = buildProfile(snapshot, body)
    if profile and profile.cacheKey == fresh.cacheKey then
        return profile
    end
    if body then PROFILE_BY_BODY[body] = fresh end
    return fresh
end

function Voice.Bind(snapshot, body)
    return Voice.GetProfile(snapshot, body)
end

function Voice.GetAlias(body, sound, snapshot)
    local profile = Voice.GetProfile(snapshot, body)
    if not profile then return nil end
    return resolveAlias(profile, sound)
end

function Voice.PlayLocal(body, sound, options)
    return play(body, sound, Voice.MODE_LOCAL, options)
end

-- Debug and presentation tools may need to preview a voice profile without
-- changing the character descriptor. Keep this on the same emitter path as
-- ordinary NPC voice playback so CharacterVoiceType and CharacterVoicePitch
-- affect the sound that was just started.
function Voice.PlayPreview(body, sound, profile)
    return Voice.PlayLocal(body, sound, { profile = profile })
end

function Voice.PlayWorld(body, sound, options)
    return play(body, sound, Voice.MODE_WORLD, options)
end

function Voice.PlayWorldAt(snapshot, sound, options)
    return playAt(snapshot, sound, Voice.MODE_WORLD, options)
end

function Voice.Play(body, sound, mode, options)
    if mode == Voice.MODE_WORLD then
        return Voice.PlayWorld(body, sound, options)
    end
    return Voice.PlayLocal(body, sound, options)
end

function Voice.Stop(body)
    return stopActive(body)
end

function Voice.Reset()
    local body
    for body, _ in pairs(ACTIVE_BY_BODY) do
        stopActive(body)
    end
    PROFILE_BY_BODY = setmetatable({}, { __mode = "k" })
    ACTIVE_BY_BODY = setmetatable({}, { __mode = "k" })
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Voice.Reset)
end

return Voice

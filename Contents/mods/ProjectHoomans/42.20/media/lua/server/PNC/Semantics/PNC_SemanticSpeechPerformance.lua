-- Interruptible NPC animation & base-game voice performance pipeline for
-- DialogueBeats and ConvoEngine. Guarantees bounded durations (never stuck)
-- and immediate safe interruption on combat, damage, or nearby zombies.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Perf = PNC.Semantics.SpeechPerformance or {}
PNC.Semantics.SpeechPerformance = Perf

local DEFAULT_ANIM_DURATION_MS = 2800
local MIN_ANIM_DURATION_MS = 600
local MAX_ANIM_DURATION_MS = 8000
local VOICE_COOLDOWN_MS = 1800
local ZOMBIE_DANGER_RADIUS = 5
local SURRENDER_ZOMBIE_DANGER_RADIUS = 3
local MAX_ACTIVE_ANIMS = 32

-- Verified Build 42 base-game VoiceMale*/VoiceFemale* sound cues (via pz-convo-assets).
local VOICE_CUES = {
    greet      = { male = "VoiceMaleShoutHey",          female = "VoiceFemaleShoutHey" },
    farewell   = { male = "VoiceMaleShoutHey",          female = "VoiceFemaleShoutHey" },
    shout      = { male = "VoiceMaleShoutHey",          female = "VoiceFemaleShoutHey" },
    whisper    = { male = "VoiceMaleWhisperHey",        female = "VoiceFemaleWhisperHey" },
    psst       = { male = "VoiceMaleWhisperPsst",       female = "VoiceFemaleWhisperPsst" },
    relief     = { male = "VoiceMaleSighReliefed",      female = "VoiceFemaleSighReliefed" },
    sigh       = { male = "VoiceMaleSighSad",           female = "VoiceFemaleSighSad" },
    bored      = { male = "VoiceMaleSighBored",         female = "VoiceFemaleSighBored" },
    shiver     = { male = "VoiceMaleFreezeShiver",      female = "VoiceFemaleFreezeShiver" },
    beckon     = { male = "VoiceMaleLureCmon",          female = "VoiceFemaleLureCmon" },
    startle    = { male = "VoiceMalePainFromFallLow",   female = "VoiceFemalePainFromFallLow" },
    pain       = { male = "VoiceMalePainFromScratch",   female = "VoiceFemalePainFromScratch" },
    surrender  = { male = "VoiceMaleShoutHey",          female = "VoiceFemaleShoutHey" },
    attack     = { male = "VoiceMaleMeleeAttack",       female = "VoiceFemaleMeleeAttack" },
    cough      = { male = "VoiceMaleCough",             female = "VoiceFemaleCough" },
    sneeze     = { male = "VoiceMaleSneezeLight",       female = "VoiceFemaleSneezeLight" },
}

local activeAnims = {}
local activeCount = 0
local lastVoiceByNPC = {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function clampDuration(ms)
    local d = tonumber(ms) or DEFAULT_ANIM_DURATION_MS
    if d < MIN_ANIM_DURATION_MS then return MIN_ANIM_DURATION_MS end
    if d > MAX_ANIM_DURATION_MS then return MAX_ANIM_DURATION_MS end
    return math.floor(d)
end

local function liveBodyFor(record)
    if type(record) ~= "table" then return nil end
    if record.zombie ~= nil then return record.zombie end
    if record.body ~= nil then return record.body end
    local reg = PNC.Registry
    if reg and type(reg.GetLiveZombie) == "function" and record.id ~= nil then
        return reg.GetLiveZombie(record.id)
    end
    return nil
end

local function hasNearbyZombieDanger(record, radius, now)
    local Perc = PNC.Perception
    if not Perc or type(Perc.GetZombieCandidatesAt) ~= "function" then return false end
    local x = tonumber(record.x)
    local y = tonumber(record.y)
    local z = tonumber(record.z) or 0
    if not x or not y then return false end
    local cands = Perc.GetZombieCandidatesAt(x, y, z, radius, "speech_perf", 250, 2, now)
    if type(cands) ~= "table" or #cands == 0 then return false end
    for i = 1, #cands do
        local c = cands[i]
        if type(Perc.IsActualZombieBody) ~= "function" or Perc.IsActualZombieBody(c) == true then
            return true
        end
    end
    return false
end

function Perf.IsSafeToPerform(record, opts, at)
    if type(record) ~= "table" or record.alive == false then return false, "dead_or_invalid" end
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(at)
    if record.health and tostring(record.health.state or "normal") == "incapacitated" then
        return false, "incapacitated"
    end
    local allowCombat = opts.allowInCombat == true
    local rt = type(record.runtime) == "table" and record.runtime or nil
    if not allowCombat and rt then
        if rt.target ~= nil or rt.combatTarget ~= nil or rt.attackAction ~= nil
            or now < (tonumber(rt.inCombatUntil) or 0)
        then
            return false, "in_combat"
        end
    end
    local zRadius = allowCombat and SURRENDER_ZOMBIE_DANGER_RADIUS or ZOMBIE_DANGER_RADIUS
    if hasNearbyZombieDanger(record, zRadius, now) then
        return false, "zombie_danger"
    end
    return true, "safe"
end

function Perf.ResolveVoiceSound(voiceSpec, isFemale)
    if type(voiceSpec) == "string" and voiceSpec ~= "" then
        local cue = VOICE_CUES[string.lower(voiceSpec)]
        if cue then
            return isFemale and cue.female or cue.male
        end
        return voiceSpec
    end
    if type(voiceSpec) == "table" then
        return isFemale and (voiceSpec.female or voiceSpec.male) or (voiceSpec.male or voiceSpec.female)
    end
    return nil
end

function Perf.PlayVoice(record, voiceSpec, opts, at)
    if type(record) ~= "table" or voiceSpec == nil then return false, "no_voice" end
    local now = nowMs(at)
    local npcID = tostring(record.id or "")
    if npcID ~= "" and now < (tonumber(lastVoiceByNPC[npcID]) or 0) + VOICE_COOLDOWN_MS then
        return false, "voice_cooldown"
    end
    local body = liveBodyFor(record)
    local isFemale = record.isFemale == true
        or (body and type(body.isFemale) == "function" and pcall(body.isFemale, body) and body:isFemale() == true)
    local soundName = Perf.ResolveVoiceSound(voiceSpec, isFemale)
    if not soundName or soundName == "" then return false, "unknown_voice" end
    if body and type(body.playSound) == "function" then
        pcall(body.playSound, body, soundName)
    end
    if npcID ~= "" then lastVoiceByNPC[npcID] = now end
    return true, soundName
end

function Perf.Interrupt(recordOrID, reason, at)
    local npcID = type(recordOrID) == "table" and tostring(recordOrID.id or "") or tostring(recordOrID or "")
    local entry = activeAnims[npcID]
    if not entry then return false end
    activeAnims[npcID] = nil
    activeCount = math.max(0, activeCount - 1)

    local rec = type(recordOrID) == "table" and recordOrID or entry.record
    local body = liveBodyFor(rec)
    local Pres = PNC.PresentationAnimations
    if Pres and type(Pres.Cancel) == "function" then
        pcall(Pres.Cancel, rec, body, { reason = tostring(reason or "interrupted") })
    end
    if body and type(body.setBumpType) == "function" then
        pcall(body.setBumpType, body, "")
    end
    return true
end

function Perf.Perform(record, spec, at)
    if type(record) ~= "table" or type(spec) ~= "table" then return false, "invalid_args" end
    local now = nowMs(at)
    local voiceOK, voiceRes = false, nil
    if spec.voice ~= nil then
        voiceOK, voiceRes = Perf.PlayVoice(record, spec.voice, spec, now)
    end

    local animID = type(spec.anim) == "string" and spec.anim ~= "" and spec.anim or nil
    if not animID then
        return voiceOK, voiceOK and ("voice:" .. tostring(voiceRes)) or "no_anim"
    end

    local safe, safeReason = Perf.IsSafeToPerform(record, spec, now)
    if not safe then
        return false, safeReason
    end

    local npcID = tostring(record.id or "")
    if npcID == "" then return false, "missing_npc_id" end
    if activeAnims[npcID] ~= nil then
        Perf.Interrupt(record, "replaced", now)
    elseif activeCount >= MAX_ACTIVE_ANIMS then
        return false, "active_anim_cap"
    end

    local durationMs = clampDuration(spec.animDurationMs)
    local body = liveBodyFor(record)
    local Pres = PNC.PresentationAnimations
    local started = false
    if Pres and type(Pres.Request) == "function" and body then
        local ok, res = pcall(Pres.Request, record, body, animID, {
            reason = tostring(spec.reason or "speech_performance"),
            durationMs = durationMs,
        })
        started = ok and res == true
    end
    if not started and body and type(body.setBumpType) == "function" then
        pcall(body.setBumpType, body, animID)
        started = true
    end

    activeAnims[npcID] = {
        npcID = npcID,
        record = record,
        animID = animID,
        allowInCombat = spec.allowInCombat == true,
        startedAt = now,
        expiresAt = now + durationMs,
    }
    activeCount = activeCount + 1
    return true, animID
end

-- Bounded pump: zero work when activeCount == 0; auto-clears expired animations
-- and immediately interrupts on combat or nearby zombie danger.
function Perf.Pump(at)
    if activeCount <= 0 then return 0 end
    local now = nowMs(at)
    local cleared = 0
    local toClear = nil
    for npcID, entry in pairs(activeAnims) do
        local reason = nil
        if now >= (tonumber(entry.expiresAt) or 0) then
            reason = "duration_expired"
        else
            local safe, unsafeReason = Perf.IsSafeToPerform(entry.record, {
                allowInCombat = entry.allowInCombat,
            }, now)
            if not safe then
                reason = unsafeReason
            end
        end
        if reason then
            toClear = toClear or {}
            toClear[#toClear + 1] = { id = npcID, rec = entry.record, reason = reason }
        end
    end
    if toClear then
        for i = 1, #toClear do
            if Perf.Interrupt(toClear[i].rec or toClear[i].id, toClear[i].reason, now) then
                cleared = cleared + 1
            end
        end
    end
    return cleared
end

function Perf.ActiveCount()
    return activeCount
end

function Perf.GetActive(npcID)
    return activeAnims[tostring(npcID or "")]
end

function Perf.RegisterVoiceCue(name, maleSound, femaleSound)
    name = string.lower(tostring(name or ""))
    if name == "" or not maleSound then return false end
    VOICE_CUES[name] = { male = tostring(maleSound), female = tostring(femaleSound or maleSound) }
    return true
end

function Perf.ResetRuntime()
    activeAnims = {}
    activeCount = 0
    lastVoiceByNPC = {}
end

-- Actor-agnostic player performance helper: lets the player play matching
-- Build 42 emotes (player:playEmote) and gender-aware voice cues safely.
function Perf.PerformForPlayer(player, specOrCue, at)
    if not player or type(specOrCue) ~= "table" then return false, "invalid_args" end
    local now = nowMs(at)
    if player.isDead and pcall(player.isDead, player) and player:isDead() == true then
        return false, "player_dead"
    end
    local cue = (specOrCue.anim ~= nil or specOrCue.voice ~= nil)
        and specOrCue
        or (type(Perf.ResolveCue) == "function" and Perf.ResolveCue(specOrCue) or nil)
    if not cue then return false, "no_cue" end

    local played = false
    if cue.voice ~= nil then
        local isFemale = player.isFemale and pcall(player.isFemale, player) and player:isFemale() == true
        local snd = Perf.ResolveVoiceSound(cue.voice, isFemale)
        if snd and player.playSound then
            pcall(player.playSound, player, snd)
            played = true
        end
    end
    if cue.anim and cue.anim ~= "" and player.playEmote then
        local attacking = player.isAttacking and pcall(player.isAttacking, player) and player:isAttacking() == true
        if not attacking or cue.allowInCombat == true then
            pcall(player.playEmote, player, cue.anim)
            played = true
        end
    end
    return played, cue.anim or cue.voice or "none"
end

require "PNC/Semantics/PNC_SemanticSpeechPerformance_Cues"

return Perf

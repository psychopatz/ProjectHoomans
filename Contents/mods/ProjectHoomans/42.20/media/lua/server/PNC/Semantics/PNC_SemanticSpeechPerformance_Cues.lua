-- Declarative animation & base-game voice cue mapping for all non-compat
-- ConvoDSL pools, beat roles, and speech acts (actor-agnostic: NPCs + Player).
-- Every emote & voice ID below is verified via pz-convo-assets against Build 42.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Perf = PNC.Semantics.SpeechPerformance or {}
PNC.Semantics.SpeechPerformance = Perf

-- Role-specific cues (highest priority; exact or prefix match)
local ROLE_CUES = {
    surrender_plea        = { anim = "surrender", animDurationMs = 5000, voice = "surrender", allowInCombat = true },
    surrender_plea_open   = { anim = "surrender", animDurationMs = 5000, voice = "surrender", allowInCombat = true },
    surrender_accept      = { anim = "stop",      animDurationMs = 2400, voice = "shout" },
    surrender_accept_reply= { anim = "stop",      animDurationMs = 2400, voice = "shout" },
    thunder_strike_open   = { anim = "freeze",    animDurationMs = 2000, voice = "startle" },
    house_alarm_open      = { anim = "freeze",    animDurationMs = 2200, voice = "startle" },
    dark_indoors_open     = { anim = "stop",      animDurationMs = 2000, voice = "whisper" },
    weather_fog_open      = { anim = "stop",      animDurationMs = 2000, voice = "whisper" },
    freezing_exposure_open= { voice = "shiver" },
    weather_cold_open     = { voice = "shiver" },
    weather_blizzard_open = { voice = "shiver" },
    catching_cold_open    = { voice = "cough" },
    out_of_rain_open      = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    dried_off_open        = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    warmed_up_open        = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    cooled_down_open      = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    weather_cleared_open  = { anim = "yes",       animDurationMs = 2200, voice = "relief" },
    wound_healed_open     = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    fed_hydrated_open     = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    rested_open           = { anim = "yes",       animDurationMs = 2200, voice = "relief" },
    cold_recovered_open   = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    panic_calmed_open     = { voice = "relief" },
    dawn_survived_open    = { anim = "salute",    animDurationMs = 2400, voice = "relief" },
    light_restored_open   = { anim = "thumbsup",  animDurationMs = 2200, voice = "relief" },
    own_base_open         = { anim = "wavehi",    animDurationMs = 2400, voice = "relief" },
    allied_base_open      = { anim = "wavehi",    animDurationMs = 2400, voice = "greet" },
    hostile_base_open     = { anim = "freeze",    animDurationMs = 2200, voice = "whisper" },
    left_hostile_base_open= { voice = "relief" },
    toll_demand_item_cash_open = { anim = "stop", animDurationMs = 2600, voice = "shout" },
    toll_demand_item_open      = { anim = "stop", animDurationMs = 2600, voice = "shout" },
    toll_demand_cash_open      = { anim = "stop", animDurationMs = 2600, voice = "shout" },
    toll_paid_open             = { anim = "thumbsup", animDurationMs = 2200 },
    toll_refused_open          = { anim = "insult",   animDurationMs = 2200, voice = "shout" },
    toll_refused_reply         = { anim = "no",       animDurationMs = 2200, voice = "shout" },
    flee_last_standing_open    = { voice = "shout" },
    flee_spared_open           = { anim = "wavebye",  animDurationMs = 1800 },
}

-- Pool-level cues (second priority; excludes any `compat` pools automatically)
local POOL_CUES = {
    ["semantic.greeting"]                 = { anim = "wavehi",   animDurationMs = 2400, voice = "greet" },
    ["semantic.farewell"]                 = { anim = "wavebye",  animDurationMs = 2400, voice = "farewell" },
    ["semantic.world.exposure.relief"]    = { anim = "thumbsup", animDurationMs = 2200, voice = "relief" },
    ["semantic.needs.relief"]             = { anim = "thumbsup", animDurationMs = 2200, voice = "relief" },
    ["semantic.combat.injury.pain_reaction"] = { voice = "pain" },
    ["semantic.combat.wound.received_beat"]  = { voice = "pain" },
    ["semantic.medical.distress.call"]       = { voice = "pain" },
    ["semantic.progression.level_up"]        = { anim = "clap",  animDurationMs = 2400, voice = "relief" },
}

-- Speech-act fallback cues (third priority; applies to both NPCs and Player)
local ACT_CUES = {
    GREET             = { anim = "wavehi",     animDurationMs = 2400, voice = "greet" },
    FAREWELL          = { anim = "wavebye",    animDurationMs = 2400, voice = "farewell" },
    DEPART            = { anim = "wavebye",    animDurationMs = 2400, voice = "farewell" },
    THANK             = { anim = "thankyou",   animDurationMs = 2400, voice = "relief" },
    PRAISE            = { anim = "clap",       animDurationMs = 2400 },
    AGREE             = { anim = "yes",        animDurationMs = 2000 },
    ACCEPT            = { anim = "thumbsup",   animDurationMs = 2200 },
    DISAGREE          = { anim = "no",         animDurationMs = 2000 },
    REFUSE            = { anim = "thumbsdown", animDurationMs = 2200, voice = "sigh" },
    INSULT            = { anim = "insult",     animDurationMs = 2200, voice = "shout" },
    ANTAGONIZE        = { anim = "insult",     animDurationMs = 2200, voice = "shout" },
    CLARIFY           = { anim = "shrug",      animDurationMs = 2200 },
    ASK_CLARIFICATION = { anim = "shrug",      animDurationMs = 2200 },
    FOLLOW            = { anim = "followme",   animDurationMs = 2200, voice = "beckon" },
    COME              = { anim = "comehere",   animDurationMs = 2200, voice = "beckon" },
    STOP              = { anim = "stop",       animDurationMs = 2200, voice = "shout" },
    HALT              = { anim = "freeze",     animDurationMs = 2200, voice = "shout" },
    SALUTE            = { anim = "salute",     animDurationMs = 2400 },
    SURRENDER         = { anim = "surrender",  animDurationMs = 5000, voice = "surrender", allowInCombat = true },
}

function Perf.IsCompatPool(poolID)
    local p = string.lower(tostring(poolID or ""))
    return p ~= "" and string.find(p, "compat", 1, true) ~= nil
end

function Perf.ResolveCue(spec)
    if type(spec) ~= "table" then return nil end
    local poolID = tostring(spec.poolID or "")
    if Perf.IsCompatPool(poolID) then
        return nil
    end

    local role = tostring(spec.role or "")
    if role ~= "" and ROLE_CUES[role] then
        return ROLE_CUES[role]
    end
    if poolID ~= "" and POOL_CUES[poolID] then
        return POOL_CUES[poolID]
    end
    local act = string.upper(tostring(spec.act or spec.intent or ""))
    if act ~= "" and ACT_CUES[act] then
        return ACT_CUES[act]
    end
    return nil
end

function Perf.RegisterRoleCue(role, cue)
    role = tostring(role or "")
    if role == "" or type(cue) ~= "table" then return false end
    ROLE_CUES[role] = cue
    return true
end

function Perf.RegisterPoolCue(poolID, cue)
    poolID = tostring(poolID or "")
    if poolID == "" or type(cue) ~= "table" then return false end
    POOL_CUES[poolID] = cue
    return true
end

function Perf.RegisterActCue(act, cue)
    act = string.upper(tostring(act or ""))
    if act == "" or type(cue) ~= "table" then return false end
    ACT_CUES[act] = cue
    return true
end

return Perf

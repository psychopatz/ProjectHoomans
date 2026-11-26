-- Default actor-agnostic problem -> remediation watchers.
-- Works identically for player-led groups and autonomous AI-controlled groups.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

if type(Beats.RegisterStateWatcher) ~= "function" then return Beats end

local SEVERE_WEATHER = {
    storm = true,
    thunderstorm = true,
    tropical_storm = true,
    blizzard = true,
    fog = true,
}

-- 1. Out of the rain / storm (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("exposure.rain_shelter", {
    scope = "group",
    priority = 32,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 120000,
    sample = function(ctx)
        local env = ctx.env or {}
        local exp = ctx.exposure or {}
        local active = exp.isOutside == true and (env.isRaining == true or exp.isSoakingWet == true)
        local variant = exp.isSoakingWet == true and "soaking_wet_rain" or "exposed_rain"
        return active, variant, active and "outside_in_rain" or "sheltered_or_dry"
    end,
    remediate = {
        poolID = "semantic.world.exposure.relief",
        rolePrefix = "out_of_rain",
        act = "REACT",
        replyAct = "AGREE",
        domain = "weather",
        channel = "weather",
        topic = "weather",
        storyKind = "sheltered_from_rain",
        storyTopic = "weather_talk",
        storySalience = 58,
    },
})

-- 2. Dried off after being soaking wet (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("exposure.dried_off", {
    scope = "group",
    priority = 29,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 150000,
    sample = function(ctx)
        local exp = ctx.exposure or {}
        local wet = exp.isSoakingWet == true
        local stillDamp = (tonumber(exp.wetLevel) or 0) > 0 or (tonumber(exp.wetness) or 0) >= 15
        -- Stay active while damp so relief fires once actually dry
        return wet or (stillDamp and exp.isOutside == true), "dried_off", wet and "soaking_wet" or "dry"
    end,
    remediate = {
        poolID = "semantic.world.exposure.relief",
        rolePrefix = "dried_off",
        act = "REACT",
        replyAct = "AGREE",
        domain = "weather",
        channel = "weather",
        topic = "weather",
        storyKind = "dried_off",
        storyTopic = "weather_talk",
        storySalience = 52,
    },
})

-- 3. Warmed up after freezing / chilly exposure (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("exposure.warmed_up", {
    scope = "group",
    priority = 30,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 150000,
    sample = function(ctx)
        local env = ctx.env or {}
        local exp = ctx.exposure or {}
        local active = exp.isFreezing == true
            or (exp.isOutside == true and exp.isChilly == true and (env.isCold == true or env.isSnowing == true or env.isBlizzard == true))
        return active, "warmed_up", active and "cold_exposed" or "warmed"
    end,
    remediate = {
        poolID = "semantic.world.exposure.relief",
        rolePrefix = "warmed_up",
        act = "REACT",
        replyAct = "AGREE",
        domain = "weather",
        channel = "weather",
        topic = "weather",
        storyKind = "warmed_up",
        storyTopic = "weather_talk",
        storySalience = 54,
    },
})

-- 4. Cooled down after overheating (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("exposure.cooled_down", {
    scope = "group",
    priority = 30,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 150000,
    sample = function(ctx)
        local env = ctx.env or {}
        local exp = ctx.exposure or {}
        local active = exp.isOverheating == true
            or (exp.isOutside == true and exp.isHot == true and env.isHot == true)
        return active, "cooled_down", active and "heat_exposed" or "cooled"
    end,
    remediate = {
        poolID = "semantic.world.exposure.relief",
        rolePrefix = "cooled_down",
        act = "REACT",
        replyAct = "AGREE",
        domain = "weather",
        channel = "weather",
        topic = "weather",
        storyKind = "cooled_down",
        storyTopic = "weather_talk",
        storySalience = 52,
    },
})

-- 5. Severe weather cleared (world-scoped)
Beats.RegisterStateWatcher("exposure.weather_cleared", {
    scope = "world",
    priority = 29,
    minActiveMs = 20000,
    remediateWindowMs = 900000,
    remediateCooldownMs = 240000,
    sample = function(ctx)
        local w = tostring(ctx.env and ctx.env.weather or "clear")
        local active = SEVERE_WEATHER[w] == true
        return active, w, active and ("severe_" .. w) or "weather_clear"
    end,
    remediate = {
        poolID = "semantic.world.exposure.relief",
        rolePrefix = "weather_cleared",
        act = "REACT",
        replyAct = "AGREE",
        domain = "weather",
        channel = "weather",
        topic = "weather",
        storyKind = "weather_cleared",
        storyTopic = "weather_talk",
        storySalience = 55,
    },
})

-- 6. Actor wound healed / bleeding stopped (actor-scoped, actor-agnostic)
Beats.RegisterStateWatcher("actor.wound_healed", {
    scope = "actor",
    priority = 33,
    minActiveMs = 8000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 180000,
    sample = function(ctx)
        local a = ctx.actor or {}
        local st = ctx.stats or {}
        local h = type(a.health) == "table" and a.health or {}
        local hState = tostring(h.state or "normal")
        local injured = st.bleeding == true or st.isInjured == true
            or h.bleeding == true or hState == "injured" or hState == "wounded" or hState == "critical"
        return injured, "wound_healed", injured and "actor_injured" or "wound_resolved"
    end,
    remediate = {
        poolID = "semantic.needs.relief",
        rolePrefix = "wound_healed",
        act = "THANK",
        replyAct = "REASSURE",
        domain = "medical",
        channel = "medical",
        topic = "wellbeing_check",
        storyKind = "wound_healed",
        storyTopic = "wellbeing_check",
        storySalience = 60,
    },
})

-- 7. Actor fed & hydrated (actor-scoped, actor-agnostic)
Beats.RegisterStateWatcher("actor.fed_hydrated", {
    scope = "actor",
    priority = 27,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 180000,
    sample = function(ctx)
        local a = ctx.actor or {}
        local needs = type(a.needs) == "table" and a.needs or {}
        local c = type(a.conditionStats) == "table" and a.conditionStats or {}
        local hunger = tonumber(needs.hunger) or tonumber(c.hunger) or 0
        local thirst = tonumber(needs.thirst) or tonumber(c.thirst) or 0
        local hungryOrThirsty = hunger >= 0.55 or thirst >= 0.55
        return hungryOrThirsty, "fed_hydrated", hungryOrThirsty and "hungry_or_thirsty" or "fed_hydrated"
    end,
    remediate = {
        poolID = "semantic.needs.relief",
        rolePrefix = "fed_hydrated",
        act = "REACT",
        replyAct = "AGREE",
        domain = "needs",
        channel = "needs",
        topic = "supplies_check",
        storyKind = "fed_hydrated",
        storyTopic = "supplies_check",
        storySalience = 50,
    },
})

-- 8. Actor rested after fatigue (actor-scoped, actor-agnostic)
Beats.RegisterStateWatcher("actor.rested", {
    scope = "actor",
    priority = 26,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 180000,
    sample = function(ctx)
        local a = ctx.actor or {}
        local st = ctx.stats or {}
        local needs = type(a.needs) == "table" and a.needs or {}
        local c = type(a.conditionStats) == "table" and a.conditionStats or {}
        local fatigue = tonumber(needs.fatigue) or tonumber(c.fatigue) or 0
        local tired = fatigue >= 0.65 or st.isExhausted == true
        return tired, "rested", tired and "fatigued" or "rested"
    end,
    remediate = {
        poolID = "semantic.needs.relief",
        rolePrefix = "rested",
        act = "REACT",
        replyAct = "AGREE",
        domain = "needs",
        channel = "needs",
        topic = "wellbeing_check",
        storyKind = "rested",
        storyTopic = "wellbeing_check",
        storySalience = 48,
    },
})

-- 9. Cold recovered (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("actor.cold_recovered", {
    scope = "group",
    priority = 28,
    minActiveMs = 10000,
    remediateWindowMs = 900000,
    remediateCooldownMs = 240000,
    sample = function(ctx)
        local exp = ctx.exposure or {}
        local hasCold = exp.hasCold == true
        return hasCold, "cold_recovered", hasCold and "has_cold" or "cold_cleared"
    end,
    remediate = {
        poolID = "semantic.needs.relief",
        rolePrefix = "cold_recovered",
        act = "REACT",
        replyAct = "AGREE",
        domain = "medical",
        channel = "medical",
        topic = "wellbeing_check",
        storyKind = "cold_recovered",
        storyTopic = "wellbeing_check",
        storySalience = 54,
    },
})

-- 10. Panic / stress calmed down (actor-scoped, actor-agnostic)
Beats.RegisterStateWatcher("actor.panic_calmed", {
    scope = "actor",
    priority = 28,
    minActiveMs = 8000,
    remediateWindowMs = 300000,
    remediateCooldownMs = 180000,
    sample = function(ctx)
        local a = ctx.actor or {}
        local c = type(a.conditionStats) == "table" and a.conditionStats or {}
        local panic = tonumber(c.panic) or 0
        local stress = tonumber(c.stress) or 0
        local highStress = panic >= 60 or stress >= 0.70
        return highStress, "panic_calmed", highStress and "high_panic_stress" or "calmed"
    end,
    remediate = {
        poolID = "semantic.needs.relief",
        rolePrefix = "panic_calmed",
        act = "REACT",
        replyAct = "REASSURE",
        domain = "social",
        channel = "social",
        topic = "road_morale",
        storyKind = "panic_calmed",
        storyTopic = "road_morale",
        storySalience = 52,
    },
})

return Beats

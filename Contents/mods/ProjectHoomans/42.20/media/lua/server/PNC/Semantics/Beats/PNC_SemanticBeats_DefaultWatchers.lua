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

local NOTABLE_ROOMS = {
    pharmacy = true,
    clinic = true,
    armory = true,
    police = true,
    firestation = true,
    military = true,
    prison = true,
    library = true,
    school = true,
    kitchen = true,
    restaurant = true,
    bakery = true,
    bar = true,
    church = true,
    grocery = true,
    hardware = true,
    clothing = true,
    electronics = true,
    bank = true,
    office = true,
    motel = true,
    garage = true,
    gasstation = true,
    warehouse = true,
    farm = true,
    gym = true,
    store = true,
    house = true,
}

local function sampleGroupRoom(ctx)
    local BC = PNC.Semantics and PNC.Semantics.BeatContext or nil
    if not BC or type(BC.GetActorRoomKind) ~= "function" then return "outside" end
    local members = ctx.group and ctx.group.members or nil
    if type(members) == "table" and members[1] then
        return BC.GetActorRoomKind(members[1])
    end
    return "outside"
end

local function isGroupSquareLit(ctx)
    local util = ctx.util or {}
    if util.powerOn == true then return true end
    local members = ctx.group and ctx.group.members or nil
    local m = type(members) == "table" and members[1] or nil
    if type(m) == "table" and m.hasLight ~= nil then
        return m.hasLight == true
    end
    if type(m) == "table" and type(getCell) == "function" then
        local cell = getCell()
        local sq = cell and type(cell.getGridSquare) == "function" and cell:getGridSquare(
            math.floor(tonumber(m.x) or 0), math.floor(tonumber(m.y) or 0), math.floor(tonumber(m.z) or 0)
        ) or nil
        if sq and type(sq.haveElectricity) == "function" then
            local ok, elec = pcall(sq.haveElectricity, sq)
            if ok and elec == true then return true end
        end
    end
    return false
end

-- 11. Room-entry awareness (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("environment.room_entered", {
    scope = "group",
    priority = 27,
    minActiveMs = 0,
    onsetCooldownMs = 180000,
    sample = function(ctx)
        local rk = sampleGroupRoom(ctx)
        if NOTABLE_ROOMS[rk] then
            return true, "room_" .. rk, "entered_" .. rk
        end
        return false, nil, rk
    end,
    onset = {
        poolID = "semantic.world.room.notice",
        act = "REACT",
        replyAct = "AGREE",
        domain = "scavenging",
        channel = "world",
        topic = "supplies_check",
    },
})

-- 12. Indoors in unpowered darkness -> light/power restored (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("exposure.darkness_lit", {
    scope = "group",
    priority = 30,
    minActiveMs = 10000,
    remediateWindowMs = 600000,
    onsetCooldownMs = 240000,
    remediateCooldownMs = 180000,
    sample = function(ctx)
        local exp = ctx.exposure or {}
        local env = ctx.env or {}
        local tod = tostring(env.timeOfDay or "day")
        local isDarkHours = tod == "night" or tod == "dusk"
        local indoors = exp.isOutside == false
        local lit = isGroupSquareLit(ctx)
        local darkIndoors = indoors and isDarkHours and not lit
        return darkIndoors, "dark_indoors", darkIndoors and "unpowered_dark" or "lit_or_outside"
    end,
    onset = {
        poolID = "semantic.world.darkness",
        rolePrefix = "dark_indoors",
        act = "WARN",
        replyAct = "AGREE",
        domain = "world",
        channel = "world",
        topic = "night_watch",
    },
    remediate = {
        poolID = "semantic.world.darkness",
        rolePrefix = "light_restored",
        act = "REACT",
        replyAct = "AGREE",
        domain = "world",
        channel = "world",
        topic = "night_watch",
        storyKind = "light_restored",
        storyTopic = "night_watch",
        storySalience = 54,
    },
})

-- 13. Dusk warning -> night survived at dawn (world-scoped)
Beats.RegisterStateWatcher("world.night_survived", {
    scope = "world",
    priority = 28,
    minActiveMs = 15000,
    remediateWindowMs = 3600000,
    onsetCooldownMs = 600000,
    remediateCooldownMs = 600000,
    sample = function(ctx)
        local tod = tostring(ctx.env and ctx.env.timeOfDay or "day")
        local isNightOrDusk = tod == "dusk" or tod == "night"
        return isNightOrDusk, tod, isNightOrDusk and tod or "daylight"
    end,
    onset = {
        poolID = "semantic.world.daycycle",
        rolePrefix = "dusk_warning",
        act = "SUGGEST",
        replyAct = "AGREE",
        domain = "world",
        channel = "world",
        topic = "night_watch",
    },
    remediate = {
        poolID = "semantic.world.daycycle",
        rolePrefix = "dawn_survived",
        act = "REACT",
        replyAct = "AGREE",
        domain = "world",
        channel = "world",
        topic = "road_morale",
        storyKind = "night_survived",
        storyTopic = "night_watch",
        storySalience = 60,
    },
})

-- 14. Calm indoor dusk/night downtime reflection (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("social.quiet_moment", {
    scope = "group",
    priority = 22,
    minActiveMs = 60000,
    onsetDelayMs = 60000,
    onsetCooldownMs = 600000,
    sample = function(ctx)
        local exp = ctx.exposure or {}
        local env = ctx.env or {}
        local tod = tostring(env.timeOfDay or "day")
        local calmEvening = (tod == "dusk" or tod == "night")
            and exp.isOutside == false
            and exp.isSoakingWet ~= true
            and exp.isFreezing ~= true
            and exp.isOverheating ~= true
        return calmEvening, "quiet_downtime", calmEvening and "calm_safehouse_evening" or "not_downtime"
    end,
    onset = {
        poolID = "semantic.world.quiet_moment",
        rolePrefix = "quiet_downtime",
        act = "CHAT",
        replyAct = "AGREE",
        domain = "social",
        channel = "social",
        topic = "road_morale",
        storyKind = "quiet_moment_shared",
        storyTopic = "road_morale",
        storySalience = 54,
    },
})

local function sampleGroupTerritory(ctx)
    local Perc = PNC.Perception
    if not Perc or type(Perc.ResolveTerritoryAt) ~= "function" then return nil end
    local members = ctx.group and ctx.group.members or nil
    local anchor = type(members) == "table" and members[1] or nil
    if type(anchor) ~= "table" then return nil end
    local fid = tostring(anchor.factionId or anchor.factionID or "")
    return Perc.ResolveTerritoryAt(anchor, nil, nil, fid)
end

-- 15. Arriving at a player-owned or NPC base / territory (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("territory.base_arrival", {
    scope = "group",
    priority = 34,
    minActiveMs = 0,
    onsetCooldownMs = 180000,
    sample = function(ctx)
        local t = sampleGroupTerritory(ctx)
        if t and t.relation then
            return true, t.relation, "entered_" .. tostring(t.relation)
        end
        return false, nil, "outside_territory"
    end,
    onset = {
        poolID = "semantic.world.territory.arrival",
        act = "REACT",
        replyAct = "AGREE",
        domain = "travel",
        channel = "world",
        topic = "road_morale",
        storyKind = "arrived_at_base",
        storyTopic = "road_morale",
        storySalience = 56,
    },
})

-- 16. Escaping / leaving hostile gang territory safely (group-scoped, actor-agnostic)
Beats.RegisterStateWatcher("territory.hostile_escaped", {
    scope = "group",
    priority = 33,
    minActiveMs = 8000,
    remediateWindowMs = 600000,
    remediateCooldownMs = 180000,
    sample = function(ctx)
        local t = sampleGroupTerritory(ctx)
        local inHostile = t ~= nil and t.relation == "hostile_base"
        return inHostile, "hostile_base", inHostile and "in_hostile_turf" or "clear_of_hostile_turf"
    end,
    remediate = {
        poolID = "semantic.world.territory.arrival",
        rolePrefix = "left_hostile_base",
        act = "REACT",
        replyAct = "AGREE",
        domain = "travel",
        channel = "world",
        topic = "road_morale",
        storyKind = "escaped_hostile_turf",
        storyTopic = "road_morale",
        storySalience = 60,
    },
})

return Beats

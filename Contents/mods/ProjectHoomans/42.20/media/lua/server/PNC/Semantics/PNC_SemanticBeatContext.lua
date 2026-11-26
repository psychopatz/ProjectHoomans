-- Extensible semantic context builder for NPC dialogue and environmental beats.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local BC = PNC.Semantics.BeatContext or {}
PNC.Semantics.BeatContext = BC

BC.VERSION = 1

local WEATHER_TTL_MS = 2000
local EXPOSURE_TTL_MS = 2000
local UTILITIES_TTL_MS = 5000
local ACTOR_STATS_TTL_MS = 1500
local MAX_ACTOR_CACHE = 64
local providers = {}
local providerOrder = {}
local weatherCache = { expiresAt = -1, data = nil }
local exposureCache = { expiresAt = -1, data = nil }
local utilitiesCache = { expiresAt = -1, data = nil }
local actorStatsCache = {}
local actorStatsOrder = {}

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj, ...)
    return ok and val or nil
end

function BC.RegisterProvider(id, fn)
    id = tostring(id or "")
    if id == "" or type(fn) ~= "function" then return false end
    if not providers[id] then providerOrder[#providerOrder + 1] = id end
    providers[id] = fn
    return true
end

function BC.UnregisterProvider(id)
    id = tostring(id or "")
    if not providers[id] then return false end
    providers[id] = nil
    for i = #providerOrder, 1, -1 do
        if providerOrder[i] == id then table.remove(providerOrder, i) end
    end
    return true
end

function BC.ListProviders()
    local out = {}
    for i = 1, #providerOrder do out[i] = providerOrder[i] end
    return out
end

function BC.GetWorldWeather(now, force)
    now = tonumber(now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now())) or 0
    if not force and weatherCache.data and now < (tonumber(weatherCache.expiresAt) or 0) then
        return weatherCache.data
    end
    local cm = type(getClimateManager) == "function" and getClimateManager() or nil
    local isRain = safeCall(cm, "isRaining") == true
    local rain = tonumber(safeCall(cm, "getRainIntensity")) or (isRain and 0.5 or 0)
    local fog = tonumber(safeCall(cm, "getFogIntensity")) or 0
    local isSnow = safeCall(cm, "isSnowing") == true
    local snowIntensity = tonumber(safeCall(cm, "getSnowIntensity")) or (isSnow and 0.5 or 0)
    local windIntensity = tonumber(safeCall(cm, "getWindIntensity")) or 0
    local windKph = tonumber(safeCall(cm, "getWindspeedKph")) or 0
    local temp = tonumber(safeCall(cm, "getTemperature"))
    local isThunder = safeCall(cm, "getIsThunderStorming") == true
    local wp = safeCall(cm, "getWeatherPeriod")
    local wpRunning = wp ~= nil and safeCall(wp, "isRunning") == true
    local isBlizzard = wpRunning and safeCall(wp, "isBlizzard") == true
    local isTropical = wpRunning and safeCall(wp, "isTropicalStorm") == true
    local isPeriodThunder = wpRunning and safeCall(wp, "isThunderStorm") == true
    local isThunderStorming = isThunder or isPeriodThunder

    local clock = PNC.WorldClock
    local hour
    local tod
    if clock and type(clock.Snapshot) == "function" then
        local snap = clock.Snapshot(now, force)
        hour = snap.timeOfDay
        tod = snap.band
    else
        local gt = type(getGameTime) == "function" and getGameTime() or nil
        hour = tonumber(safeCall(gt, "getTimeOfDay")) or 12
        tod = "day"
        if hour >= 5 and hour < 8 then tod = "dawn"
        elseif hour >= 17 and hour < 21 then tod = "dusk"
        elseif hour < 5 or hour >= 21 then tod = "night" end
    end

    local weather = "clear"
    if isBlizzard then weather = "blizzard"
    elseif isTropical then weather = "tropical_storm"
    elseif isThunderStorming then weather = "thunderstorm"
    elseif isSnow or snowIntensity >= 0.15 then weather = "snow"
    elseif isRain or rain >= 0.15 then weather = rain >= 0.7 and "storm" or "rain"
    elseif fog >= 0.35 then weather = "fog"
    elseif windIntensity >= 0.65 or windKph >= 45 then weather = "wind"
    elseif temp ~= nil and temp <= 5 then weather = "cold"
    elseif temp ~= nil and temp >= 32 then weather = "heat" end

    local isRainingFlag = isRain or rain >= 0.15
        or weather == "rain" or weather == "storm"
        or weather == "thunderstorm" or weather == "tropical_storm"
    local data = {
        weather = weather,
        isRaining = isRainingFlag,
        isSnowing = isSnow or snowIntensity >= 0.15 or isBlizzard,
        isThunderStorming = isThunderStorming,
        isBlizzard = isBlizzard,
        isTropicalStorm = isTropical,
        isFoggy = fog >= 0.35,
        isWindy = windIntensity >= 0.65 or windKph >= 45,
        isCold = temp ~= nil and temp <= 5,
        isHot = temp ~= nil and temp >= 32,
        isHarshWeather = weather ~= "clear",
        rainIntensity = rain,
        snowIntensity = snowIntensity,
        fogIntensity = fog,
        windIntensity = windIntensity,
        windSpeedKph = windKph,
        temperature = temp,
        timeOfDay = tod,
    }
    weatherCache.data = data
    weatherCache.expiresAt = now + WEATHER_TTL_MS
    return data
end

local function primaryPlayerForExposure(player)
    if player ~= nil then return player end
    if type(getPlayer) == "function" then
        local ok, p = pcall(getPlayer)
        if ok and p ~= nil then return p end
    end
    if type(getOnlinePlayers) == "function" then
        local ok, list = pcall(getOnlinePlayers)
        if ok and list and type(list.size) == "function" and list:size() > 0 then
            return list:get(0)
        end
    end
    return nil
end

function BC.GetPlayerExposure(player, now, force)
    now = tonumber(now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now())) or 0
    if player == nil and not force and exposureCache.data
        and now < (tonumber(exposureCache.expiresAt) or 0)
    then
        return exposureCache.data
    end
    local p = primaryPlayerForExposure(player)
    if not p then
        return {
            hasPlayer = false,
            isOutside = false,
            wetLevel = 0,
            wetness = 0,
            hypoLevel = 0,
            hyperLevel = 0,
            windchillLevel = 0,
            coldMoodleLevel = 0,
            hasCold = false,
            isSoakingWet = false,
            isFreezing = false,
            isChilly = false,
            isOverheating = false,
            isHot = false,
        }
    end
    local isOutside = safeCall(p, "isOutside") == true
    local moodles = safeCall(p, "getMoodles")
    local mt = rawget(_G, "MoodleType")
    local wetLevel = (moodles and mt and mt.WET and tonumber(safeCall(moodles, "getMoodleLevel", mt.WET))) or 0
    local hypoLevel = (moodles and mt and mt.HYPOTHERMIA and tonumber(safeCall(moodles, "getMoodleLevel", mt.HYPOTHERMIA))) or 0
    local hyperLevel = (moodles and mt and mt.HYPERTHERMIA and tonumber(safeCall(moodles, "getMoodleLevel", mt.HYPERTHERMIA))) or 0
    local windchillLevel = (moodles and mt and mt.WINDCHILL and tonumber(safeCall(moodles, "getMoodleLevel", mt.WINDCHILL))) or 0
    local coldMoodleLevel = (moodles and mt and mt.HAS_A_COLD and tonumber(safeCall(moodles, "getMoodleLevel", mt.HAS_A_COLD))) or 0

    local stats = safeCall(p, "getStats")
    local cs = rawget(_G, "CharacterStat")
    local wetness = (stats and cs and cs.WETNESS and tonumber(safeCall(stats, "get", cs.WETNESS))) or 0
    local bd = safeCall(p, "getBodyDamage")
    local hasCold = (bd and safeCall(bd, "isHasACold") == true) or coldMoodleLevel >= 1

    local data = {
        hasPlayer = true,
        isOutside = isOutside,
        wetLevel = wetLevel,
        wetness = wetness,
        hypoLevel = hypoLevel,
        hyperLevel = hyperLevel,
        windchillLevel = windchillLevel,
        coldMoodleLevel = coldMoodleLevel,
        hasCold = hasCold,
        isSoakingWet = wetLevel >= 2 or wetness >= 35,
        isFreezing = hypoLevel >= 2 or (hypoLevel >= 1 and windchillLevel >= 2),
        isChilly = hypoLevel >= 1 or windchillLevel >= 2,
        isOverheating = hyperLevel >= 2,
        isHot = hyperLevel >= 1,
    }
    if player == nil then
        exposureCache.data = data
        exposureCache.expiresAt = now + EXPOSURE_TTL_MS
    end
    return data
end

function BC.GetWorldUtilities(now, force)
    now = tonumber(now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now())) or 0
    if not force and utilitiesCache.data and now < (tonumber(utilitiesCache.expiresAt) or 0) then
        return utilitiesCache.data
    end
    local sb = (type(getSandboxOptions) == "function" and getSandboxOptions())
        or (SandboxOptions and type(SandboxOptions.getInstance) == "function" and SandboxOptions.getInstance())
        or nil
    local world = (type(getWorld) == "function" and getWorld())
        or (IsoWorld and IsoWorld.instance)
        or nil
    local gt = type(getGameTime) == "function" and getGameTime() or nil

    local worldDays = tonumber(gt and safeCall(gt, "getWorldAgeDaysSinceBegin"))
    if worldDays == nil then
        local hours = tonumber(gt and safeCall(gt, "getWorldAgeHours"))
        worldDays = hours and (hours / 24) or 0
    end
    local currentDay = math.floor(worldDays)

    local elecShutDay = sb and tonumber(safeCall(sb, "getElecShutModifier")) or nil
    local waterShutDay = sb and tonumber(safeCall(sb, "getWaterShutModifier")) or nil

    local powerOn = true
    local hasHydro = world and type(world.isHydroPowerOn) == "function"
    local hasGrid = sb and type(sb.doesPowerGridExist) == "function"
    if hasHydro then
        powerOn = safeCall(world, "isHydroPowerOn") == true
    end
    if hasGrid then
        local grid = safeCall(sb, "doesPowerGridExist") == true
        powerOn = hasHydro and (powerOn and grid) or grid
    elseif not hasHydro and elecShutDay ~= nil and elecShutDay >= 0 then
        powerOn = worldDays < elecShutDay
    end

    local waterOn = true
    if waterShutDay ~= nil and waterShutDay >= 0 then
        waterOn = worldDays < waterShutDay
    end

    local powerOutToday = (not powerOn)
        and elecShutDay ~= nil
        and elecShutDay >= 0
        and currentDay == math.floor(elecShutDay)
    local waterOutToday = (not waterOn)
        and waterShutDay ~= nil
        and waterShutDay >= 0
        and currentDay == math.floor(waterShutDay)

    local data = {
        powerOn = powerOn == true,
        waterOn = waterOn == true,
        elecShutDay = elecShutDay,
        waterShutDay = waterShutDay,
        currentDay = currentDay,
        powerOutToday = powerOutToday == true,
        waterOutToday = waterOutToday == true,
    }
    utilitiesCache.data = data
    utilitiesCache.expiresAt = now + UTILITIES_TTL_MS
    return data
end

local function isRecordIndoors(sp)
    if type(sp) ~= "table" or type(getCell) ~= "function" then return false end
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return false end
    local sq = cell:getGridSquare(
        math.floor(tonumber(sp.x) or 0), math.floor(tonumber(sp.y) or 0), math.floor(tonumber(sp.z) or 0)
    )
    return sq ~= nil and sq.getRoom and sq:getRoom() ~= nil
end

function BC.IsActorIndoors(actor)
    if type(actor) == "table" then
        if actor.isOutside ~= nil and type(actor.isOutside) == "function" then
            return safeCall(actor, "isOutside") == false
        end
        if actor.isIndoors ~= nil then
            return actor.isIndoors == true
        end
        if actor.isOutside ~= nil then
            return actor.isOutside == false
        end
        return isRecordIndoors(actor)
    end
    if actor ~= nil and type(actor.isOutside) == "function" then
        return safeCall(actor, "isOutside") == false
    end
    return false
end

-- Actor-agnostic group exposure snapshot: works for both player-led groups and
-- autonomous AI-controlled NPC squads (zero player dependency).
function BC.GetGroupExposure(group, env, now)
    now = tonumber(now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now())) or 0
    local members = type(group) == "table" and group.members or nil
    if type(members) ~= "table" or #members == 0 then
        return BC.GetPlayerExposure(nil, now)
    end

    -- Check if this group is following/owned by a live player; if so, blend
    -- player's Build 42 moodles/stats with the squad's indoor/outdoor state.
    local player = nil
    local common = PNC.BehaviorCommon
    for i = 1, #members do
        local m = members[i]
        local orderKind = tostring(m.orderSpec and m.orderSpec.kind or "")
        local following = orderKind == tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
            or (m.runtime and m.runtime.followOrderActive == true)
        if following and common and type(common.GetOwner) == "function" then
            local owner = common.GetOwner(m)
            if owner and safeCall(owner, "isDead") ~= true then
                player = owner
                break
            end
        end
    end

    if player ~= nil then
        local pe = BC.GetPlayerExposure(player, now)
        pe.isPlayerLed = true
        return pe
    end

    -- Pure AI-controlled group: derive exposure directly from member squares,
    -- conditionStats/needs, and live world weather.
    local outsideCount = 0
    local maxWetness = 0
    local maxWetLevel = 0
    local maxHypo = 0
    local maxHyper = 0
    local anyCold = false
    for i = 1, #members do
        local m = members[i]
        if not BC.IsActorIndoors(m) then
            outsideCount = outsideCount + 1
        end
        local c = type(m.conditionStats) == "table" and m.conditionStats or nil
        if c then
            local w = tonumber(c.wetness) or 0
            if w > maxWetness then maxWetness = w end
            local wl = tonumber(c.wetLevel) or 0
            if wl > maxWetLevel then maxWetLevel = wl end
            local hy = tonumber(c.hypothermia) or 0
            if hy > maxHypo then maxHypo = hy end
            local ht = tonumber(c.hyperthermia) or 0
            if ht > maxHyper then maxHyper = ht end
            if c.hasCold == true then anyCold = true end
        end
    end

    local isOutside = outsideCount > 0
    local isRaining = env and env.isRaining == true
    local isColdWeather = env and (env.isCold == true or env.isSnowing == true or env.isBlizzard == true)
    local isHotWeather = env and env.isHot == true

    return {
        hasPlayer = false,
        isPlayerLed = false,
        isOutside = isOutside,
        wetLevel = maxWetLevel,
        wetness = maxWetness,
        hypoLevel = maxHypo,
        hyperLevel = maxHyper,
        windchillLevel = (isOutside and env and env.isWindy and isColdWeather) and 2 or 0,
        coldMoodleLevel = anyCold and 1 or 0,
        hasCold = anyCold,
        isSoakingWet = maxWetLevel >= 2 or maxWetness >= 35,
        isFreezing = maxHypo >= 2 or (isOutside and env and env.isBlizzard == true),
        isChilly = maxHypo >= 1 or (isOutside and isColdWeather),
        isOverheating = maxHyper >= 2,
        isHot = maxHyper >= 1 or (isOutside and isHotWeather),
        isRainingOutside = isOutside and isRaining,
    }
end

local function resolveDispositionProjection()
    local dp = PNC and PNC.ConvoEngine and PNC.ConvoEngine.DispositionProjection
    if type(dp) == "table" and type(dp.Resolve) == "function" then
        return dp
    end
    return nil
end

local function hasEntries(tbl)
    if type(tbl) ~= "table" then return false end
    for _ in pairs(tbl) do return true end
    return false
end

local function statsFromFallback(sp, opts)
    if type(sp) ~= "table" then return { style = "neutral", styleProfile = "default" } end
    opts = type(opts) == "table" and opts or {}
    local p = (type(sp.social) == "table" and sp.social.personality) or sp.personality or sp.socialProfile or {}
    local c = type(sp.conditionStats) == "table" and sp.conditionStats or {}
    local h = type(sp.health) == "table" and sp.health or {}
    local body = type(h.body) == "table" and h.body or {}
    local b = tostring(sp.activeBehavior or sp.behavior or "")
    local tRole = tostring(sp.tacticalRole or sp.role or "")
    local isTactical = sp.tactical == true or tRole == "guard" or tRole == "soldier" or tRole == "scout"
    local isHostile = b == "hostile" or sp.isHostile == true
    local passiveCombat = tostring(sp.combatPolicy or "") == "passive" or tostring(sp.attackType or "") == "none"
    local stState = string.lower(tostring(sp.stamina and sp.stamina.state or ""))

    local panic = tonumber(c.panic) or 0
    local stress = tonumber(c.stress) or 0
    local fatigue = tonumber(c.fatigue) or tonumber(sp.needs and sp.needs.fatigue) or 0
    local pain = tonumber(c.pain) or 0
    local bleeding = h.bleeding == true
        or (tonumber(body.bleedingRate) or 0) > 0
        or (tonumber(body.openWoundCount) or 0) > 0
        or (tonumber(h.bleedingRate) or 0) > 0
        or (tonumber(h.openWoundCount) or 0) > 0

    local hState = tostring(h.state or "okay")
    local curHp, maxHp = tonumber(h.current), tonumber(h.max)
    local hpRatio = (curHp and maxHp and maxHp > 0) and math.max(0, math.min(1, curHp / maxHp))
        or ((hState == "injured" or hState == "wounded" or hState == "critical") and 0.6 or 1)

    local DP = resolveDispositionProjection()
    local proj = DP and DP.Resolve(sp, {
        personality = hasEntries(p) and p or nil,
        condition = c,
        temporaryDemeanor = opts.temporaryDemeanor,
        isHostile = isHostile,
        tactical = isTactical,
    }) or nil

    local eff = proj and proj.effectiveDisposition or nil
    local unitDisp = (proj and DP and DP.ToUnitDisposition)
        and DP.ToUnitDisposition(eff) or nil
    local bravery = unitDisp and unitDisp.bravery
        or (eff and (eff.bravery / 100))
        or tonumber(p.bravery) or 0.5
    local aggression = unitDisp and unitDisp.aggression
        or (eff and (eff.aggression / 100))
        or tonumber(p.aggression) or 0.5
    local compassion = unitDisp and unitDisp.compassion
        or (eff and (eff.compassion / 100))
        or tonumber(p.compassion) or 0.5

    local styleProfile = proj and tostring(proj.styleProfile or "default") or nil
    local combatReactionStyle
    local style = "neutral"

    if proj then
        combatReactionStyle = styleProfile == "default" and "practical" or styleProfile
        if isHostile then
            style = "hostile"
        elseif styleProfile == "shaken" or passiveCombat then
            style = "shaken"
        elseif bleeding or pain >= 55 or fatigue >= 0.80 or stState == "exhausted" then
            style = "exhausted"
        elseif styleProfile == "aggressive" or styleProfile == "brave" or styleProfile == "supportive" then
            style = styleProfile
        elseif isTactical then
            style = "tactical"
        else
            style = "neutral"
        end
    else
        if isHostile then style = "hostile"
        elseif panic >= 65 or stress >= 0.80 or bravery <= 0.32 or passiveCombat then style = "shaken"
        elseif bleeding or pain >= 55 or fatigue >= 0.80 or stState == "exhausted" then style = "exhausted"
        elseif aggression >= 0.70 then style = "aggressive"
        elseif bravery >= 0.68 then style = "brave"
        elseif isTactical then style = "tactical"
        elseif compassion >= 0.66 then style = "supportive" end
        styleProfile = (style == "neutral" or style == "tactical" or style == "exhausted") and "default"
            or (style == "hostile" and "cold" or style)
        combatReactionStyle = styleProfile == "default" and "practical" or styleProfile
    end

    local isCowardly = eff
        and ((styleProfile == "shaken") or eff.bravery <= 32 or eff.confidence <= 32 or panic >= 55)
        or (bravery <= 0.32 or panic >= 55)
    local isBrave = eff
        and ((styleProfile == "brave") or (eff.bravery >= 68 and eff.confidence >= 65))
        or (bravery >= 0.68)
    local isExhausted = fatigue >= 0.75 or pain >= 50 or bleeding or stState == "exhausted"
        or hState == "injured" or hState == "wounded" or hState == "critical"

    return {
        style = style,
        styleProfile = styleProfile,
        combatReactionStyle = combatReactionStyle,
        baseDisposition = proj and proj.baseDisposition or nil,
        temporaryDemeanor = proj and proj.temporaryDemeanor or nil,
        effectiveDisposition = eff,
        bravery = bravery, aggression = aggression, compassion = compassion,
        panic = panic, stress = stress, fatigue = fatigue, pain = pain,
        bleeding = bleeding, healthState = hState, hpRatio = hpRatio,
        isCowardly = isCowardly == true, isBrave = isBrave == true,
        isExhausted = isExhausted == true,
    }
end

local function cacheActorStats(key, data, now)
    if actorStatsCache[key] == nil then
        while #actorStatsOrder >= MAX_ACTOR_CACHE do
            local oldest = table.remove(actorStatsOrder, 1)
            actorStatsCache[oldest] = nil
        end
        actorStatsOrder[#actorStatsOrder + 1] = key
    end
    actorStatsCache[key] = { expiresAt = now + ACTOR_STATS_TTL_MS, data = data }
end

function BC.ResolveActorStats(sp, opts, now)
    if type(sp) ~= "table" then return {} end
    opts = type(opts) == "table" and opts or {}
    now = tonumber(now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now())) or 0
    local role = tostring(opts.role or "witness")
    local inCombat = opts.inCombat == true
    local useCache = sp.id ~= nil and opts.temporaryDemeanor == nil and opts.weaponItem == nil and opts.bypassCache ~= true
    local cacheKey = useCache and (tostring(sp.id) .. "|" .. (inCombat and "1" or "0") .. "|" .. role) or nil
    if cacheKey then
        local cached = actorStatsCache[cacheKey]
        if cached and now < (tonumber(cached.expiresAt) or 0) then
            return cached.data
        end
    end

    local Prof = PNC.Semantics and PNC.Semantics.CombatReactionProfile or nil
    local st
    if Prof and type(Prof.Build) == "function" then
        local pr = Prof.Build(sp, "", {
            role = role,
            actorKind = "npc",
            inCombat = inCombat,
            temporaryDemeanor = opts.temporaryDemeanor,
        })
        st = {
            style = pr.allyWarnStyle or pr.combatReactionStyle or "neutral",
            styleProfile = pr.styleProfile or pr.combatReactionStyle or "default",
            combatReactionStyle = pr.combatReactionStyle,
            baseDisposition = pr.baseDisposition,
            temporaryDemeanor = pr.temporaryDemeanor,
            effectiveDisposition = pr.effectiveDisposition,
            bravery = pr.bravery, aggression = pr.aggression, compassion = pr.compassion,
            panic = pr.panic, stress = pr.stress, fatigue = pr.fatigue, pain = pr.pain,
            bleeding = pr.bleeding, healthState = pr.healthState, hpRatio = pr.hpRatio,
            isCowardly = pr.isCowardly, isBrave = pr.isBrave, isExhausted = pr.isExhausted,
            isInjured = pr.bleeding == true
                or pr.healthState == "injured" or pr.healthState == "wounded" or pr.healthState == "critical"
                or (tonumber(pr.hpRatio) or 1) < 0.75,
        }
    else
        st = statsFromFallback(sp, opts)
        st.isInjured = st.bleeding == true
            or st.healthState == "injured" or st.healthState == "wounded" or st.healthState == "critical"
            or (tonumber(st.hpRatio) or 1) < 0.75
    end
    local rt = type(sp.runtime) == "table" and sp.runtime or nil
    local wFam = rt and rt.combatWeaponFamily or nil
    if not wFam and opts.weaponItem and PNC.Semantics.CombatWeaponContext then
        local w = PNC.Semantics.CombatWeaponContext.Build(sp, { weaponItem = opts.weaponItem })
        wFam = w and w.weaponFamily or nil
    end
    st.weaponFamily = wFam
    if cacheKey then cacheActorStats(cacheKey, st, now) end
    return st
end

BC.RegisterProvider("actor_stats", function(ctx, sp, _, opts)
    if type(sp) ~= "table" then return end
    ctx.actor = BC.ResolveActorStats(sp, opts, ctx.now)
end)

BC.RegisterProvider("environment_weather", function(ctx, sp)
    local w = BC.GetWorldWeather(ctx.now)
    local env = type(ctx.env) == "table" and ctx.env or {}
    for k, v in pairs(w) do env[k] = v end
    env.isIndoors = isRecordIndoors(sp)
    ctx.env = env
end)

BC.RegisterProvider("environment_utilities", function(ctx)
    local u = BC.GetWorldUtilities(ctx.now)
    local env = type(ctx.env) == "table" and ctx.env or {}
    for k, v in pairs(u) do env[k] = v end
    ctx.env = env
end)

function BC.Build(speaker, addressee, opts)
    opts = type(opts) == "table" and opts or {}
    local now = tonumber(opts.now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now())) or 0
    local ctx = {
        now = now,
        speaker = speaker,
        addressee = addressee,
        opts = opts,
        actor = {},
        partner = {},
        relationship = {},
        env = {},
        tokens = {},
    }
    for i = 1, #providerOrder do
        local fn = providers[providerOrder[i]]
        if fn then pcall(fn, ctx, speaker, addressee, opts) end
    end
    return ctx
end

function BC.ResetRuntime()
    weatherCache.expiresAt = -1
    weatherCache.data = nil
    exposureCache.expiresAt = -1
    exposureCache.data = nil
    utilitiesCache.expiresAt = -1
    utilitiesCache.data = nil
    actorStatsCache = {}
    actorStatsOrder = {}
end

require "PNC/Semantics/PNC_SemanticBeatContext_Pair"
require "PNC/Semantics/PNC_SemanticBeatContext_MemoryWorld"

return BC

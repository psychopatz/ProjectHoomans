-- Extensible semantic context builder for NPC dialogue and environmental beats.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local BC = PNC.Semantics.BeatContext or {}
PNC.Semantics.BeatContext = BC

BC.VERSION = 1

local WEATHER_TTL_MS = 2000
local UTILITIES_TTL_MS = 5000
local providers = {}
local providerOrder = {}
local weatherCache = { expiresAt = -1, data = nil }
local utilitiesCache = { expiresAt = -1, data = nil }

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
    local gt = type(getGameTime) == "function" and getGameTime() or nil
    local isRain = safeCall(cm, "isRaining") == true
    local rain = tonumber(safeCall(cm, "getRainIntensity")) or (isRain and 0.5 or 0)
    local fog = tonumber(safeCall(cm, "getFogIntensity")) or 0
    local isSnow = safeCall(cm, "isSnowing") == true
    local temp = tonumber(safeCall(cm, "getTemperature"))
    local hour = tonumber(safeCall(gt, "getTimeOfDay")) or 12

    local weather = "clear"
    if isSnow then weather = "snow"
    elseif isRain or rain >= 0.15 then weather = rain >= 0.7 and "storm" or "rain"
    elseif fog >= 0.35 then weather = "fog"
    elseif temp ~= nil and temp <= 5 then weather = "cold" end

    local tod = "day"
    if hour >= 5 and hour < 8 then tod = "dawn"
    elseif hour >= 17 and hour < 21 then tod = "dusk"
    elseif hour < 5 or hour >= 21 then tod = "night" end

    local data = {
        weather = weather,
        isRaining = weather == "rain" or weather == "storm",
        rainIntensity = rain,
        fogIntensity = fog,
        temperature = temp,
        timeOfDay = tod,
    }
    weatherCache.data = data
    weatherCache.expiresAt = now + WEATHER_TTL_MS
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

BC.RegisterProvider("actor_stats", function(ctx, sp, _, opts)
    if type(sp) ~= "table" then return end
    local Prof = PNC.Semantics and PNC.Semantics.CombatReactionProfile or nil
    local st
    if Prof and type(Prof.Build) == "function" then
        local pr = Prof.Build(sp, "", {
            role = opts and opts.role or "witness",
            actorKind = "npc",
            inCombat = opts and opts.inCombat == true,
            temporaryDemeanor = opts and opts.temporaryDemeanor,
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
        }
    else
        st = statsFromFallback(sp, opts)
    end
    local rt = type(sp.runtime) == "table" and sp.runtime or nil
    local wFam = rt and rt.combatWeaponFamily or nil
    if not wFam and opts and opts.weaponItem and PNC.Semantics.CombatWeaponContext then
        local w = PNC.Semantics.CombatWeaponContext.Build(sp, { weaponItem = opts.weaponItem })
        wFam = w and w.weaponFamily or nil
    end
    st.weaponFamily = wFam
    ctx.actor = st
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
    utilitiesCache.expiresAt = -1
    utilitiesCache.data = nil
end

return BC

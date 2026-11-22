-- Extensible semantic context builder for NPC dialogue and environmental beats.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local BC = PNC.Semantics.BeatContext or {}
PNC.Semantics.BeatContext = BC

BC.VERSION = 1

local WEATHER_TTL_MS = 2000
local providers = {}
local providerOrder = {}
local weatherCache = { expiresAt = -1, data = nil }

local function safeCall(obj, method)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj)
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

local function isRecordIndoors(sp)
    if type(sp) ~= "table" or type(getCell) ~= "function" then return false end
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return false end
    local sq = cell:getGridSquare(
        math.floor(tonumber(sp.x) or 0), math.floor(tonumber(sp.y) or 0), math.floor(tonumber(sp.z) or 0)
    )
    return sq ~= nil and sq.getRoom and sq:getRoom() ~= nil
end

local function statsFromFallback(sp)
    if type(sp) ~= "table" then return { style = "neutral" } end
    local p = (type(sp.social) == "table" and sp.social.personality) or sp.personality or sp.socialProfile or {}
    local c = type(sp.conditionStats) == "table" and sp.conditionStats or {}
    local h = type(sp.health) == "table" and sp.health or {}
    local bravery = tonumber(p.bravery) or 0.5
    local aggression = tonumber(p.aggression) or 0.5
    local compassion = tonumber(p.compassion) or 0.5
    local panic = tonumber(c.panic) or 0
    local fatigue = tonumber(c.fatigue) or tonumber(sp.needs and sp.needs.fatigue) or 0
    local pain = tonumber(c.pain) or 0
    local bleeding = h.bleeding == true
    local style = "neutral"
    local b = tostring(sp.activeBehavior or sp.behavior or "")
    local tRole = tostring(sp.tacticalRole or sp.role or "")
    if b == "hostile" or sp.isHostile == true then style = "hostile"
    elseif panic >= 70 or bravery <= 0.30 or tostring(sp.combatPolicy or "") == "passive" or tostring(sp.attackType or "") == "none" then style = "shaken"
    elseif bleeding or pain >= 55 or fatigue >= 0.80 then style = "exhausted"
    elseif aggression >= 0.72 then style = "aggressive"
    elseif bravery >= 0.72 then style = "brave"
    elseif sp.tactical == true or tRole == "guard" or tRole == "soldier" or tRole == "scout" then style = "tactical"
    elseif compassion >= 0.66 then style = "supportive" end
    return {
        style = style, bravery = bravery, aggression = aggression, compassion = compassion,
        panic = panic, stress = tonumber(c.stress) or 0, fatigue = fatigue, pain = pain,
        bleeding = bleeding, healthState = tostring(h.state or "okay"), hpRatio = 1,
        isCowardly = bravery <= 0.30 or panic >= 55, isBrave = bravery >= 0.72,
        isExhausted = fatigue >= 0.75 or pain >= 50 or bleeding,
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
        })
        st = {
            style = pr.allyWarnStyle or pr.combatReactionStyle or "neutral",
            bravery = pr.bravery, aggression = pr.aggression, compassion = pr.compassion,
            panic = pr.panic, stress = pr.stress, fatigue = pr.fatigue, pain = pr.pain,
            bleeding = pr.bleeding, healthState = pr.healthState, hpRatio = pr.hpRatio,
            isCowardly = pr.isCowardly, isBrave = pr.isBrave, isExhausted = pr.isExhausted,
        }
    else
        st = statsFromFallback(sp)
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
    local env = {}
    for k, v in pairs(w) do env[k] = v end
    env.isIndoors = isRecordIndoors(sp)
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
end

return BC

-- Server-authoritative body-part wounds for managed NPCs.
-- Work is event-driven at zombie impact and aggregated during the existing
-- health tick; it never scans every body part on every frame.

PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}

local Wounds = PNC.NPCWounds
local Core = PNC.Core
local Const = PNC.Const
local Settings = PNC.Sandbox

Wounds.Parts = {
    Head =       { id = "Head", label = "Head", engine = "Head", x = 0.50, y = 0.08, weight = 5 },
    Neck =       { id = "Neck", label = "Neck", engine = "Neck", x = 0.50, y = 0.16, weight = 3 },
    Torso_Upper ={ id = "Torso_Upper", label = "Upper Torso", engine = "Torso_Upper", x = 0.50, y = 0.28, weight = 18 },
    Torso_Lower ={ id = "Torso_Lower", label = "Lower Torso", engine = "Torso_Lower", x = 0.50, y = 0.42, weight = 14 },
    Groin =      { id = "Groin", label = "Groin", engine = "Groin", x = 0.50, y = 0.51, weight = 5 },
    UpperArm_L = { id = "UpperArm_L", label = "Left Upper Arm", engine = "UpperArm_L", x = 0.24, y = 0.30, weight = 6 },
    UpperArm_R = { id = "UpperArm_R", label = "Right Upper Arm", engine = "UpperArm_R", x = 0.76, y = 0.30, weight = 6 },
    ForeArm_L =  { id = "ForeArm_L", label = "Left Forearm", engine = "ForeArm_L", x = 0.15, y = 0.45, weight = 5 },
    ForeArm_R =  { id = "ForeArm_R", label = "Right Forearm", engine = "ForeArm_R", x = 0.85, y = 0.45, weight = 5 },
    Hand_L =     { id = "Hand_L", label = "Left Hand", engine = "Hand_L", x = 0.09, y = 0.58, weight = 3 },
    Hand_R =     { id = "Hand_R", label = "Right Hand", engine = "Hand_R", x = 0.91, y = 0.58, weight = 3 },
    UpperLeg_L = { id = "UpperLeg_L", label = "Left Thigh", engine = "UpperLeg_L", x = 0.39, y = 0.62, weight = 8 },
    UpperLeg_R = { id = "UpperLeg_R", label = "Right Thigh", engine = "UpperLeg_R", x = 0.61, y = 0.62, weight = 8 },
    LowerLeg_L = { id = "LowerLeg_L", label = "Left Shin", engine = "LowerLeg_L", x = 0.39, y = 0.80, weight = 6 },
    LowerLeg_R = { id = "LowerLeg_R", label = "Right Shin", engine = "LowerLeg_R", x = 0.61, y = 0.80, weight = 6 },
    Foot_L =     { id = "Foot_L", label = "Left Foot", engine = "Foot_L", x = 0.36, y = 0.96, weight = 2 },
    Foot_R =     { id = "Foot_R", label = "Right Foot", engine = "Foot_R", x = 0.64, y = 0.96, weight = 2 },
}

Wounds.PartOrder = {
    "Head", "Neck", "Torso_Upper", "Torso_Lower", "Groin",
    "UpperArm_L", "UpperArm_R", "ForeArm_L", "ForeArm_R", "Hand_L", "Hand_R",
    "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R",
}

local WOUND_STATS = {
    scratch = { priority = 1, damage = 4, bleedingRate = 0.018 },
    laceration = { priority = 2, damage = 8, bleedingRate = 0.055 },
    bite = { priority = 3, damage = 12, bleedingRate = 0.085 },
}

local function worldHour()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getWorldAgeHours then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return (tonumber(Core.Now()) or 0) / 3600000
end

local function randomPercent()
    if ZombRand then return (tonumber(ZombRand(10000)) or 0) / 100 end
    return math.random() * 100
end

local function choosePart()
    local total = 0
    local roll
    local i
    local part
    for i = 1, #Wounds.PartOrder do
        part = Wounds.Parts[Wounds.PartOrder[i]]
        total = total + (tonumber(part.weight) or 1)
    end
    roll = ZombRand and ZombRand(math.max(1, total)) or math.floor(math.random() * total)
    for i = 1, #Wounds.PartOrder do
        part = Wounds.Parts[Wounds.PartOrder[i]]
        roll = roll - (tonumber(part.weight) or 1)
        if roll < 0 then return part end
    end
    return Wounds.Parts.Torso_Upper
end

local function resolvePartIndex(part)
    local value = BodyPartType and part and BodyPartType[part.engine] or nil
    local ok
    local index
    if not value then return nil, nil end
    if BodyPartType.ToIndex then
        ok, index = pcall(BodyPartType.ToIndex, value)
        if ok and tonumber(index) then return tonumber(index), value end
    end
    if value.index then
        ok, index = pcall(value.index, value)
        if ok and tonumber(index) then return tonumber(index), value end
    end
    return nil, value
end

function Wounds.GetProtection(npcBody, part)
    local index
    local enum
    local ok
    local value
    if not npcBody then return 0 end
    if npcBody.getBodyPartClothingDefense then
        index, enum = resolvePartIndex(part)
        if index ~= nil then
            ok, value = pcall(npcBody.getBodyPartClothingDefense, npcBody, index, true, false)
            if ok and tonumber(value) then return Core.Clamp(tonumber(value), 0, 100) end
        end
        if enum ~= nil then
            ok, value = pcall(npcBody.getBodyPartClothingDefense, npcBody, enum, true, false)
            if ok and tonumber(value) then return Core.Clamp(tonumber(value), 0, 100) end
        end
    end
    -- Older/alternate IsoZombie bindings may not expose per-part defense. Use
    -- a conservative worn-item average so armor still matters without an
    -- expensive inventory or visual scan.
    local worn = npcBody.getWornItems and npcBody:getWornItems() or nil
    local count = 0
    local total = 0
    local i
    local entry
    local item
    local defense
    if worn and worn.size and worn.get then
        for i = 0, worn:size() - 1 do
            entry = worn:get(i)
            item = entry and entry.getItem and entry:getItem() or entry
            defense = item and item.getBiteDefense and tonumber(item:getBiteDefense()) or nil
            if defense then
                total = total + Core.Clamp(defense, 0, 100)
                count = count + 1
            end
        end
    end
    if count > 0 then return Core.Clamp(total / count, 0, 100) end
    return 0
end

function Wounds.Ensure(record)
    local health = PNC.Health and PNC.Health.Ensure and PNC.Health.Ensure(record) or record.health
    health.body = type(health.body) == "table" and health.body or {}
    health.body.wounds = type(health.body.wounds) == "table" and health.body.wounds or {}
    health.body.bleedingRate = tonumber(health.body.bleedingRate) or 0
    health.body.openWoundCount = tonumber(health.body.openWoundCount) or 0
    health.body.bandagedWoundCount = tonumber(health.body.bandagedWoundCount) or 0
    health.body.lastBleedAt = tonumber(health.body.lastBleedAt) or 0
    return health.body
end

function Wounds.Recalculate(record)
    local body = Wounds.Ensure(record)
    local bleedingRate = 0
    local openCount = 0
    local bandagedCount = 0
    local wound
    for _, wound in pairs(body.wounds) do
        if wound.bandaged == true then
            bandagedCount = bandagedCount + 1
        else
            openCount = openCount + 1
            bleedingRate = bleedingRate + math.max(0, tonumber(wound.bleedingRate) or 0)
        end
    end
    body.bleedingRate = bleedingRate
    body.openWoundCount = openCount
    body.bandagedWoundCount = bandagedCount
    return body
end

function Wounds.HasActiveInfection(record)
    local body = record and record.health and record.health.body or nil
    local infection = body and body.infection or nil
    return infection and infection.active == true and infection.fatal ~= true or false
end

local function infect(record, partId, nowHour)
    local body = Wounds.Ensure(record)
    if not Settings.NPCZombieInfectionEnabled() or body.infection and body.infection.active then
        return false
    end
    body.infection = {
        active = true,
        fatal = false,
        sourcePart = partId,
        infectedAtWorldHour = nowHour,
        fatalAtWorldHour = nowHour + Settings.NPCInfectionMortalityHours(),
        reanimateAtWorldHour = 0,
    }
    return true
end

local function chooseWoundType()
    local roll = randomPercent()
    local biteChance = Settings.NPCZombieBiteChance()
    local lacerationChance = Settings.NPCZombieLacerationChance()
    if roll < biteChance then return "bite" end
    if roll < math.min(100, biteChance + lacerationChance) then return "laceration" end
    return "scratch"
end

local function addWound(record, part, woundType, now)
    local body = Wounds.Ensure(record)
    local stats = WOUND_STATS[woundType] or WOUND_STATS.scratch
    local existing = body.wounds[part.id]
    local existingStats = existing and WOUND_STATS[existing.type] or nil
    local wound = existing or {
        partId = part.id,
        createdAt = now,
    }
    if not existingStats or stats.priority >= existingStats.priority then
        wound.type = woundType
    end
    wound.bleedingRate = math.min(0.18, math.max(tonumber(wound.bleedingRate) or 0, stats.bleedingRate)
        + (existing and stats.bleedingRate * 0.35 or 0))
    wound.severity = math.min(100, (tonumber(wound.severity) or 0) + stats.damage)
    wound.bandaged = false
    wound.bandagedAt = 0
    wound.healAtWorldHour = 0
    body.wounds[part.id] = wound
    if woundType == "bite" then infect(record, part.id, worldHour()) end
    Wounds.Recalculate(record)
    return wound, stats.damage
end

function Wounds.ResolveZombieAttack(record, npcBody, attacker)
    local part = choosePart()
    local protection = Wounds.GetProtection(npcBody, part)
    local baseChance = Settings.NPCZombieWoundChance()
    local finalChance = Core.Clamp(baseChance * (1 - protection / 100), 0, 100)
    local woundRoll = randomPercent()
    local woundType
    local wound
    local damage
    if woundRoll >= finalChance then
        return false, {
            outcome = "parried",
            partId = part.id,
            protection = protection,
            chance = finalChance,
            roll = woundRoll,
        }
    end
    woundType = chooseWoundType()
    wound, damage = addWound(record, part, woundType, Core.Now())
    PNC.Health.ApplyDamage(record, npcBody, {
        amount = damage,
        type = "zombie_" .. woundType,
        attackerKind = "zombie",
        x = attacker and attacker.getX and attacker:getX() or record.x,
        y = attacker and attacker.getY and attacker:getY() or record.y,
        z = attacker and attacker.getZ and attacker:getZ() or record.z,
    })
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "npc_wound"
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, {
        outcome = "wounded",
        partId = part.id,
        woundType = wound.type,
        protection = protection,
        chance = finalChance,
        roll = woundRoll,
        infected = Wounds.HasActiveInfection(record),
    }
end

function Wounds.PrepareInfectionDeath(record)
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection or infection.active ~= true then return false end
    infection.active = false
    infection.fatal = true
    infection.fatalAtWorldHour = tonumber(infection.fatalAtWorldHour) or worldHour()
    infection.reanimateAtWorldHour = worldHour() + Settings.NPCReanimationHours()
    return true
end

function Wounds.TriggerInfectionDeath(record, zombie, reason)
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection or infection.active ~= true then return false, "not_infected" end
    if not zombie then
        local newlyPending = infection.pendingFatal ~= true
        infection.pendingFatal = true
        record.health.current = math.max(1, tonumber(record.health.current) or 1)
        if newlyPending and PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "infection")
        end
        return false, "awaiting_live_body"
    end
    Wounds.PrepareInfectionDeath(record)
    PNC.Health.Kill(record, zombie, reason or "zombie_infection")
    return true, "killed"
end

function Wounds.Bandage(record, partId, now)
    local body = Wounds.Ensure(record)
    local wound = body.wounds[tostring(partId or "")]
    if not wound or wound.bandaged == true then return false, "wound_missing" end
    now = tonumber(now) or Core.Now()
    wound.bandaged = true
    wound.bandagedAt = now
    wound.healAtWorldHour = worldHour() + 6
    Wounds.Recalculate(record)
    if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    return true, "bandaged"
end

function Wounds.BandageAll(record, now)
    local body = Wounds.Ensure(record)
    local changed = false
    local partId
    local wound
    now = tonumber(now) or Core.Now()
    for partId, wound in pairs(body.wounds) do
        if wound.bandaged ~= true then
            wound.bandaged = true
            wound.bandagedAt = now
            wound.healAtWorldHour = worldHour() + 6
            changed = true
        end
    end
    Wounds.Recalculate(record)
    return changed
end

function Wounds.Clear(record)
    local body = Wounds.Ensure(record)
    body.wounds = {}
    body.infection = nil
    body.bleedingRate = 0
    body.openWoundCount = 0
    body.bandagedWoundCount = 0
    body.lastBleedAt = 0
end

function Wounds.Update(record, zombie, now)
    local health = record and record.health or nil
    local body = health and Wounds.Ensure(record) or nil
    local infection = body and body.infection or nil
    local currentHour = worldHour()
    local elapsed
    local bleedDamage
    local changed = false
    local partId
    local wound
    if not body or record.alive == false then return false end

    if infection and infection.active == true
        and (infection.pendingFatal == true
            or currentHour >= (tonumber(infection.fatalAtWorldHour) or math.huge))
    then
        Wounds.TriggerInfectionDeath(record, zombie, "zombie_infection")
        return true
    end

    for partId, wound in pairs(body.wounds) do
        if wound.bandaged == true
            and (tonumber(wound.healAtWorldHour) or 0) > 0
            and currentHour >= tonumber(wound.healAtWorldHour)
        then
            body.wounds[partId] = nil
            changed = true
        end
    end
    if changed then
        Wounds.Recalculate(record)
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent = "wound_healed"
        if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "wounds") end
    end

    now = tonumber(now) or Core.Now()
    if body.lastBleedAt <= 0 then
        body.lastBleedAt = now
        return changed
    end
    elapsed = now - body.lastBleedAt
    if elapsed < (tonumber(Const.WOUND_BLEED_UPDATE_MS) or 1000) then return changed end
    body.lastBleedAt = now
    if health.state == "normal" and (tonumber(body.bleedingRate) or 0) > 0 then
        bleedDamage = body.bleedingRate * math.min(10, elapsed / 1000)
        health.current = math.max(0, (tonumber(health.current) or 0) - bleedDamage)
        health.recentDamageUntil = now + (tonumber(Const.RECENT_DAMAGE_SHOW_MS) or 4000)
        if health.current <= 0 then
            if Wounds.HasActiveInfection(record) then
                Wounds.TriggerInfectionDeath(record, zombie, "infected_blood_loss")
            else
                PNC.Health.EnterIncapacitated(record, zombie, "blood_loss")
            end
            return true
        end
        record.runtime = record.runtime or {}
        if now - (tonumber(record.runtime.lastWoundDirtyAt) or 0)
            >= (tonumber(Const.WOUND_DIRTY_FLUSH_MS) or 5000)
        then
            record.runtime.lastWoundDirtyAt = now
            if PNC.Registry and PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "health") end
        end
        changed = true
    end
    return changed
end

function Wounds.BuildSnapshot(record)
    local body = Wounds.Recalculate(record)
    local output = {
        bleedingRate = body.bleedingRate,
        openWoundCount = body.openWoundCount,
        bandagedWoundCount = body.bandagedWoundCount,
        infected = Wounds.HasActiveInfection(record),
        infection = body.infection and Core.DeepCopy(body.infection) or nil,
        wounds = {},
    }
    local i
    local partId
    local wound
    for i = 1, #Wounds.PartOrder do
        partId = Wounds.PartOrder[i]
        wound = body.wounds[partId]
        if wound then output.wounds[partId] = Core.DeepCopy(wound) end
    end
    return output
end

return Wounds

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
    bullet = { priority = 4, damage = 14, bleedingRate = 0.095 },
}
local DEBUG_WOUND_TYPES = { "scratch", "laceration", "bite" }

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

function Wounds.ChoosePartId()
    local part = choosePart()
    return part and part.id or "Torso_Upper"
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
    local initialRatio = Core.Clamp(
        (tonumber(health.current) or tonumber(health.max) or 100)
            / math.max(1, tonumber(health.max) or 100),
        0,
        1
    )
    local i
    local partId
    local partHealth
    health.body = type(health.body) == "table" and health.body or {}
    health.body.wounds = type(health.body.wounds) == "table" and health.body.wounds or {}
    health.body.parts = type(health.body.parts) == "table" and health.body.parts or {}
    for i = 1, #Wounds.PartOrder do
        partId = Wounds.PartOrder[i]
        partHealth = health.body.parts[partId]
        if type(partHealth) ~= "table" then
            partHealth = { current = initialRatio * 100, max = 100 }
            health.body.parts[partId] = partHealth
        else
            partHealth.max = math.max(1, tonumber(partHealth.max) or 100)
            partHealth.current = Core.Clamp(
                tonumber(partHealth.current) or partHealth.max,
                0,
                partHealth.max
            )
        end
    end
    health.body.bleedingRate = tonumber(health.body.bleedingRate) or 0
    health.body.openWoundCount = tonumber(health.body.openWoundCount) or 0
    health.body.bandagedWoundCount = tonumber(health.body.bandagedWoundCount) or 0
    health.body.lastBleedAt = tonumber(health.body.lastBleedAt) or 0
    return health.body
end

-- The public NPC HP value is derived from the mean percentage of all body
-- parts. This keeps the character window, network snapshot, monitor and
-- overhead nameplate on one authoritative value.
function Wounds.SyncOverallHealth(record)
    local health = record and record.health or nil
    local body = health and Wounds.Ensure(record) or nil
    local totalPercent = 0
    local i
    local partHealth
    if not body then return nil end
    for i = 1, #Wounds.PartOrder do
        partHealth = body.parts[Wounds.PartOrder[i]]
        totalPercent = totalPercent + Core.Clamp(
            (tonumber(partHealth.current) or 0) / math.max(1, tonumber(partHealth.max) or 100),
            0,
            1
        )
    end
    body.totalPartHealth = totalPercent * 100
    body.totalPartMax = #Wounds.PartOrder * 100
    body.overallPercent = totalPercent / #Wounds.PartOrder * 100
    health.current = Core.Clamp(
        (tonumber(health.max) or 100) * body.overallPercent / 100,
        0,
        tonumber(health.max) or 100
    )
    return health.current
end

function Wounds.SetOverallHealth(record, value)
    local health = record and record.health or nil
    local body = health and Wounds.Ensure(record) or nil
    local ratio
    local i
    local partHealth
    if not body then return nil end
    ratio = Core.Clamp((tonumber(value) or 0) / math.max(1, tonumber(health.max) or 100), 0, 1)
    for i = 1, #Wounds.PartOrder do
        partHealth = body.parts[Wounds.PartOrder[i]]
        partHealth.current = partHealth.max * ratio
    end
    return Wounds.SyncOverallHealth(record)
end

local function changeBodyHealth(record, amount, partId, healing)
    local body = Wounds.Ensure(record)
    local count = #Wounds.PartOrder
    local selectedScale = partId and 2 or 1
    local otherScale = partId and ((count - selectedScale) / math.max(1, count - 1)) or 1
    local i
    local id
    local partHealth
    local scale
    amount = math.max(0, tonumber(amount) or 0)
    for i = 1, count do
        id = Wounds.PartOrder[i]
        partHealth = body.parts[id]
        scale = id == partId and selectedScale or otherScale
        if healing then
            partHealth.current = math.min(partHealth.max, partHealth.current + amount * scale)
        else
            partHealth.current = math.max(0, partHealth.current - amount * scale)
        end
    end
    return Wounds.SyncOverallHealth(record)
end

function Wounds.ApplyBodyDamage(record, amount, partId)
    return changeBodyHealth(record, amount, partId and tostring(partId) or nil, false)
end

function Wounds.ApplyBodyHealing(record, amount, partId)
    return changeBodyHealth(record, amount, partId and tostring(partId) or nil, true)
end

local function infectionStage(progress)
    if progress < 0.20 then return "incubating" end
    if progress < 0.45 then return "queasy" end
    if progress < 0.65 then return "nauseous" end
    if progress < 0.85 then return "fever" end
    return "terminal"
end

local function refreshInfectionState(record, currentHour, applyDecline)
    local body = Wounds.Ensure(record)
    local infection = body.infection
    local health = record and record.health or nil
    local infectedAt
    local fatalAt
    local duration
    local progress
    local fever
    local stage
    local priorStage
    local targetHealth
    local decline
    local changed = false
    if not infection or infection.active ~= true then return false end
    infectedAt = tonumber(infection.infectedAtWorldHour) or currentHour
    fatalAt = tonumber(infection.fatalAtWorldHour)
        or (infectedAt + Settings.NPCInfectionMortalityHours())
    duration = math.max(0.01, fatalAt - infectedAt)
    progress = Core.Clamp((currentHour - infectedAt) / duration, 0, 1)
    fever = Core.Clamp((progress - 0.45) / 0.45, 0, 1) * 100
    stage = infectionStage(progress)
    priorStage = infection.stage
    if math.abs((tonumber(infection.progress) or -1) - progress) >= 0.001
        or math.abs((tonumber(infection.fever) or -1) - fever) >= 0.1
        or priorStage ~= stage
    then
        changed = true
    end
    infection.progress = progress
    infection.stage = stage
    infection.fever = fever
    infection.temperatureC = 37 + fever / 100 * 3.5
    infection.lastUpdatedWorldHour = currentHour

    -- Once the fever is established, progressively lower the authoritative
    -- body-part aggregate. This is derived from world time, so reconnects and
    -- abstract NPC simulation cannot apply the same interval twice.
    if applyDecline ~= false and health and progress > 0.65 then
        decline = Core.Clamp((progress - 0.65) / 0.35, 0, 1)
        targetHealth = math.max((tonumber(health.max) or 100) * 0.05,
            (tonumber(health.max) or 100) * (1 - decline * 0.95))
        if (tonumber(health.current) or 0) > targetHealth + 0.01 then
            Wounds.ApplyBodyDamage(record, health.current - targetHealth)
            changed = true
        end
    end
    if priorStage ~= stage then
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent = "infection_" .. stage
    end
    return changed
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
    Wounds.SyncOverallHealth(record)
    return body
end

function Wounds.HasActiveInfection(record)
    local body = record and record.health and record.health.body or nil
    local infection = body and body.infection or nil
    return infection and infection.active == true and infection.fatal ~= true or false
end

local function infect(record, partId, nowHour, force)
    local body = Wounds.Ensure(record)
    local chance = Settings.NPCZombieInfectionChance()
    if body.infection and (body.infection.active == true or body.infection.fatal == true) then
        return false, "already_infected"
    end
    if force ~= true then
        if chance <= 0 then return false, "disabled" end
        if randomPercent() >= chance then return false, "roll_failed" end
    end
    body.infection = {
        active = true,
        fatal = false,
        pendingFatal = false,
        sourcePart = partId,
        infectedAtWorldHour = nowHour,
        fatalAtWorldHour = nowHour + Settings.NPCInfectionMortalityHours(),
        reanimateAtWorldHour = 0,
        progress = 0,
        stage = "incubating",
        fever = 0,
        temperatureC = 37,
        lastUpdatedWorldHour = nowHour,
    }
    return true, "infected"
end

function Wounds.ForceInfection(record, partId)
    local applied, reason = infect(
        record,
        tostring(partId or Wounds.ChoosePartId()),
        worldHour(),
        true
    )
    if applied and PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    return applied, reason
end

local function chooseWoundType()
    local roll = randomPercent()
    local biteChance = Settings.NPCZombieBiteChance()
    local lacerationChance = Settings.NPCZombieLacerationChance()
    if roll < biteChance then return "bite" end
    if roll < math.min(100, biteChance + lacerationChance) then return "laceration" end
    return "scratch"
end

local function addWound(record, part, woundType, now, woundDamage)
    local body = Wounds.Ensure(record)
    local stats = WOUND_STATS[woundType] or WOUND_STATS.scratch
    local severityDamage = math.max(0.1, tonumber(woundDamage) or tonumber(stats.damage) or 4)
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
    wound.severity = math.min(100, (tonumber(wound.severity) or 0) + severityDamage)
    wound.damage = math.min(100, (tonumber(wound.damage) or 0) + severityDamage)
    wound.bandaged = false
    wound.bandagedAt = 0
    wound.healAtWorldHour = 0
    body.wounds[part.id] = wound
    if woundType == "bite" then infect(record, part.id, worldHour()) end
    Wounds.Recalculate(record)
    return wound, stats.damage
end

function Wounds.ApplyCombatDamage(record, npcBody, damageEvent)
    local partId = damageEvent and damageEvent.partId and tostring(damageEvent.partId) or Wounds.ChoosePartId()
    local part = Wounds.Parts[partId]
    local woundType = tostring(damageEvent and damageEvent.woundType or "scratch")
    local amount = math.max(0, tonumber(damageEvent and damageEvent.amount) or 0)
    local applied
    local wound
    if not record or record.alive == false or not part or amount <= 0 then
        return false, { outcome = "invalid_target", partId = partId }
    end
    if not WOUND_STATS[woundType] then
        woundType = "scratch"
    end
    applied = PNC.Health.ApplyDamage(record, npcBody, {
        amount = amount,
        partId = part.id,
        type = tostring(damageEvent and damageEvent.type or "combat_" .. woundType),
        attackerID = damageEvent and damageEvent.attackerID,
        attackerKind = damageEvent and damageEvent.attackerKind or "npc",
        attackerOnlineID = damageEvent and damageEvent.attackerOnlineID,
        attackerUsername = damageEvent and damageEvent.attackerUsername,
        weaponFullType = damageEvent and damageEvent.weaponFullType,
        x = damageEvent and damageEvent.x,
        y = damageEvent and damageEvent.y,
        z = damageEvent and damageEvent.z,
    })
    if not applied then
        return false, { outcome = "damage_rejected", partId = part.id }
    end
    if record.alive ~= false then
        wound = addWound(record, part, woundType, Core.Now(), amount)
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = record.alive == false and "death" or "combat_damage"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, {
        outcome = record.alive == false and "killed" or "wounded",
        partId = part.id,
        woundType = wound and wound.type or woundType,
        damage = amount,
        infected = Wounds.HasActiveInfection(record),
    }
end

function Wounds.ApplyDebugWound(record, npcBody, partId, woundType, amount)
    local part = partId and Wounds.Parts[tostring(partId)] or choosePart()
    local selectedType = tostring(woundType or "")
    local wound
    local defaultDamage
    local appliedDamage
    if not record or record.alive == false or not part then
        return false, { outcome = "invalid_target" }
    end
    if not WOUND_STATS[selectedType] then
        local roll = ZombRand and ZombRand(#DEBUG_WOUND_TYPES)
            or math.floor(math.random() * #DEBUG_WOUND_TYPES)
        selectedType = DEBUG_WOUND_TYPES[(tonumber(roll) or 0) + 1] or "scratch"
    end
    wound, defaultDamage = addWound(record, part, selectedType, Core.Now(), amount)
    appliedDamage = math.max(0.1, tonumber(amount) or tonumber(defaultDamage) or 4)
    PNC.Health.ApplyDamage(record, npcBody, {
        amount = appliedDamage,
        partId = part.id,
        type = "debug_" .. selectedType,
        attackerKind = "debug",
    })
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "debug_wound"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
    return true, {
        outcome = "wounded",
        partId = part.id,
        woundType = wound.type,
        damage = appliedDamage,
        infected = Wounds.HasActiveInfection(record),
    }
end

function Wounds.ApplyDebugInfection(record, npcBody, partId, stage)
    local selectedPartId = partId and tostring(partId) or Wounds.ChoosePartId()
    local body
    local infection
    local mortality
    local currentHour
    local progressByStage = {
        incubating = 0.05,
        queasy = 0.30,
        nauseous = 0.55,
        fever = 0.72,
        terminal = 0.92,
    }
    local requestedStage = tostring(stage or "incubating")
    local progress = progressByStage[requestedStage]
        or progressByStage.incubating
    if not record or record.alive == false or not Wounds.Parts[selectedPartId] then
        return false, "invalid_target"
    end
    body = Wounds.Ensure(record)
    if not body.wounds[selectedPartId] then
        local woundApplied, woundResult =
            Wounds.ApplyDebugWound(record, npcBody, selectedPartId, "bite")
        if not woundApplied then return false, woundResult end
        if record.alive == false then
            infection = body.infection
            return infection and infection.fatal == true,
                infection and infection.stage or "target_died"
        end
    end
    if not Wounds.HasActiveInfection(record) then
        Wounds.ForceInfection(record, selectedPartId)
    end
    infection = body.infection
    if not infection or infection.active ~= true then return false, "infection_unavailable" end
    currentHour = worldHour()
    mortality = Settings.NPCInfectionMortalityHours()
    infection.sourcePart = selectedPartId
    infection.infectedAtWorldHour = currentHour - mortality * progress
    infection.fatalAtWorldHour = currentHour + mortality * (1 - progress)
    infection.pendingFatal = false
    refreshInfectionState(record, currentHour, true)
    if requestedStage == "fatal" then
        local killed, reason = Wounds.TriggerInfectionDeath(
            record,
            npcBody,
            "debug_zombie_infection"
        )
        if not killed and reason ~= "awaiting_live_body" then return false, reason end
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "debug_infection_" .. tostring(infection.stage)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    return true, infection.stage
end

function Wounds.ResolveZombieAttack(record, npcBody, attacker, attackerZombieId)
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
        partId = part.id,
        type = "zombie_" .. woundType,
        attackerKind = "zombie",
        attackerZombieId = attackerZombieId,
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
    infection.progress = 1
    infection.stage = "fatal"
    infection.fever = 100
    infection.temperatureC = 40.5
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
        Wounds.SetOverallHealth(record, math.max(1, tonumber(record.health.current) or 1))
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

    if infection and infection.active == true then
        if refreshInfectionState(record, currentHour, false) then changed = true end
        if infection.pendingFatal == true
            or currentHour >= (tonumber(infection.fatalAtWorldHour) or math.huge)
        then
            Wounds.TriggerInfectionDeath(record, zombie, "zombie_infection")
            return true
        end
    end

    for partId, wound in pairs(body.wounds) do
        if wound.bandaged == true
            and (tonumber(wound.healAtWorldHour) or 0) > 0
            and currentHour >= tonumber(wound.healAtWorldHour)
        then
            Wounds.ApplyBodyHealing(record, tonumber(wound.damage) or tonumber(wound.severity) or 0, partId)
            body.wounds[partId] = nil
            changed = true
        end
    end

    if infection and infection.active == true
        and refreshInfectionState(record, currentHour, true)
    then
        changed = true
    end

    if changed then
        Wounds.Recalculate(record)
        record.runtime = record.runtime or {}
        record.runtime.forceSyncEvent = record.runtime.forceSyncEvent or "wound_healed"
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
        partId = nil
        for _, wound in pairs(body.wounds) do
            if wound.bandaged ~= true then partId = wound.partId break end
        end
        PNC.Health.ApplyDamage(record, zombie, {
            amount = bleedDamage,
            partId = partId,
            type = "blood_loss",
            attackerKind = "wound",
        })
        if health.state ~= "normal" or record.alive == false then return true end
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
        parts = Core.DeepCopy(body.parts),
        totalPartHealth = body.totalPartHealth,
        totalPartMax = body.totalPartMax,
        overallPercent = body.overallPercent,
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

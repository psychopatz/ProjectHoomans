-- Cause-agnostic NPC firearm suicide behavior pipeline.
-- Integrates directly into PNC.BehaviorSystem ownership (no split tick loop):
--   * O(1) fast-path per live NPC tick when idle (single timestamp check).
--   * Cause registry (`RegisterCause`) + event-driven trigger (`TryTrigger`)
--     so Knox virus, family-loss grief, extreme trauma, or story causes all
--     share one unified firearm/trait/dialogue/animation/mourning pipeline.
--   * Native witness ownership (`record.runtime.suicideWitness`) so nearby
--     witnesses halt, intervene, reluctantly comply, and mourn even after the
--     victim's record is retired at death.

PNC = PNC or {}
PNC.BehaviorSuicide = PNC.BehaviorSuicide or {}

local Suicide = PNC.BehaviorSuicide

local EVAL_COOLDOWN_MS = 45000
local WITNESS_RADIUS_SQ = 12 * 12

-- Phase timings (milliseconds relative to previous milestone)
local DELAY_INTERVENE_MS = 2200
local DELAY_INSIST_MS = 2200
local DELAY_COMPLY_MS = 2000
local DELAY_EXECUTE_AFTER_COMPLY_MS = 1800
local DELAY_EXECUTE_SOLO_MS = 2400
local DELAY_SHOT_HANDGUN_MS = 750
local DELAY_SHOT_RIFLE_MS = 1350
local DELAY_MOURN_MS = 1800
local DELAY_MOURN_CHIME_MS = 3400
local RAGDOLL_MIN_SETTLE_MS = 450
local RAGDOLL_MAX_SETTLE_MS = 1400
local WITNESS_HARD_TIMEOUT_MS = 18000

local HANDGUN_SCENES = {
    "suicide.handgun",
    "suicide.handgun_02",
    "suicide.handgun_03",
}

local DEFAULT_ROLES = {
    resolve = "suicide_resolve",
    resolveSolo = "suicide_resolve_solo",
    intervene = "suicide_intervene",
    insist = "suicide_insist",
    comply = "suicide_comply",
    mourn = "suicide_mourn",
    mournChime = "suicide_mourn_chime",
}

Suicide.Causes = Suicide.Causes or {}
local sortedCauseIds = {}

local function rebuildCauseOrder()
    sortedCauseIds = {}
    for id in pairs(Suicide.Causes) do
        sortedCauseIds[#sortedCauseIds + 1] = id
    end
    table.sort(sortedCauseIds, function(a, b)
        local ca, cb = Suicide.Causes[a], Suicide.Causes[b]
        local pa = tonumber(ca and ca.priority) or 50
        local pb = tonumber(cb and cb.priority) or 50
        if pa ~= pb then return pa > pb end
        return a < b
    end)
end

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function safeCall(obj, methodName, ...)
    local fn = obj and obj[methodName]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj, ...)
    if ok then return val end
    return nil
end

local function clamp(val, lo, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

local function distanceSq(ax, ay, bx, by)
    local dx = (tonumber(ax) or 0) - (tonumber(bx) or 0)
    local dy = (tonumber(ay) or 0) - (tonumber(by) or 0)
    return dx * dx + dy * dy
end

local function isAuditEnabled()
    local diag = PNC.PerformanceScalingDiagnostics
    return diag ~= nil and diag.SuicideAuditEnabled == true
end

local function logAudit(eventName, fields)
    local diag = PNC.PerformanceScalingDiagnostics
    if not diag or diag.SuicideAuditEnabled ~= true then return false end
    if type(diag.LogSuicideAudit) == "function" then
        return diag.LogSuicideAudit(eventName, fields)
    end
    return false
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

local function isFemaleRecord(record, liveZombie)
    if type(record) == "table" then
        if record.isFemale == true or record.female == true then return true end
        if record.isFemale == false or record.female == false then return false end
        local g = string.lower(tostring(record.gender or ""))
        if g == "female" or g == "woman" or g == "f" then return true end
        if g == "male" or g == "man" or g == "m" then return false end
    end
    local body = liveZombie or liveBodyFor(record)
    if body then
        local f = safeCall(body, "isFemale")
        if type(f) == "boolean" then return f end
    end
    return false
end

function Suicide.BuildPronounTokens(record, liveZombie)
    local female = isFemaleRecord(record, liveZombie)
    local name = tostring(
        (type(record) == "table" and (record.name or record.fullName or record.displayName))
            or "them"
    )
    return {
        ["victim.name"] = name,
        ["victim.subj"] = female and "she" or "he",
        ["victim.Subj"] = female and "She" or "He",
        ["victim.obj"] = female and "her" or "him",
        ["victim.poss"] = female and "her" or "his",
        ["victim.refl"] = female and "herself" or "himself",
        ["victim.gender"] = female and "female" or "male",
    }
end

local function isCalmNPC(rec, now)
    if type(rec) ~= "table" or rec.id == nil or rec.alive == false then return false end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then return false end
    local hState = rec.health and string.lower(tostring(rec.health.state or "normal")) or "normal"
    if hState == "downed" or hState == "unconscious" or hState == "dead" or hState == "incapacitated" then
        return false
    end
    local rt = type(rec.runtime) == "table" and rec.runtime or nil
    if rt and (rt.target ~= nil or rt.attackAction ~= nil or rt.combatTarget ~= nil
        or now < (tonumber(rt.inCombatUntil) or 0))
    then
        return false
    end
    return true
end

local function isHostilePair(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    local h = PNC.Hostility
    if h and type(h.IsHostile) == "function" then
        local ok, res = pcall(h.IsHostile, a, b)
        if ok and res == true then return true end
    end
    local modeA = string.lower(tostring(a.hostility and a.hostility.mode or ""))
    local modeB = string.lower(tostring(b.hostility and b.hostility.mode or ""))
    return modeA == "hostile" or modeB == "hostile"
end

local function isSameTeam(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.groupId ~= nil and a.groupId == b.groupId then return true end
    local fa = a.affiliation and a.affiliation.factionID or a.factionID
    local fb = b.affiliation and b.affiliation.factionID or b.factionID
    return fa ~= nil and fa == fb
end

local function haltActor(record, zombie)
    local common = PNC.BehaviorCommon
    if common and type(common.HaltMovement) == "function" then
        pcall(common.HaltMovement, record, zombie, "suicide_behavior")
    elseif common and type(common.StopMoving) == "function" then
        pcall(common.StopMoving, record, zombie)
    end
end

local function findNearbyWitnesses(rec, now)
    local reg = PNC.Registry
    if not reg or type(reg.ForEach) ~= "function" then return nil, nil end
    local primary, primaryScore = nil, -1
    local secondary, secondaryScore = nil, -1
    local rz = tonumber(rec.z) or 0
    reg.ForEach(function(other)
        if type(other) ~= "table" or other.id == nil or tostring(other.id) == tostring(rec.id) then
            return
        end
        if not isCalmNPC(other, now) or isHostilePair(rec, other) then return end
        local ort = other.runtime
        if ort and (ort.suicideState ~= nil or ort.suicideWitness ~= nil) then return end
        if math.abs((tonumber(other.z) or 0) - rz) >= 1 then return end
        local dSq = distanceSq(rec.x, rec.y, other.x, other.y)
        if dSq > WITNESS_RADIUS_SQ then return end
        local score = (isSameTeam(rec, other) and 1000 or 100) - dSq
        if score > primaryScore then
            secondary, secondaryScore = primary, primaryScore
            primary, primaryScore = other, score
        elseif score > secondaryScore then
            secondary, secondaryScore = other, score
        end
    end)
    return primary, secondary
end

local function hasUnlimitedAmmoReserve(record)
    local firearms = PNC.Firearms
    if firearms and type(firearms.HasUnlimitedReserve) == "function" then
        local ok, res = pcall(firearms.HasUnlimitedReserve, record)
        if ok then return res == true end
    end
    return false
end

local function usesInventoryAmmo(record)
    local firearms = PNC.Firearms
    if firearms and type(firearms.UsesInventoryAmmo) == "function" then
        local ok, res = pcall(firearms.UsesInventoryAmmo, record)
        if ok then return res == true end
    end
    return false
end

local function queryMagazineState(record, weaponItem)
    local firearms = PNC.Firearms
    if not firearms or type(firearms.GetMagazineState) ~= "function" then
        return nil
    end
    local ok, mag = pcall(firearms.GetMagazineState, record, weaponItem)
    if ok and type(mag) == "table" then return mag end
    return nil
end

local function consumeOneLooseRound(record, ammoType, excludeItemID)
    local inv = record and record.inventory
    local items = type(inv) == "table" and inv.items or nil
    local inventorySvc = PNC.Inventory
    if not items or not ammoType or not inventorySvc or type(inventorySvc.ApplyDelta) ~= "function" then
        return false
    end
    local target = string.lower(tostring(ammoType))
    for itemID, entry in pairs(items) do
        if itemID ~= excludeItemID and type(entry) == "table"
            and string.lower(tostring(entry.type or entry.fullType or "")) == target
        then
            local count = math.max(1, math.floor(tonumber(entry.count) or 1))
            local op = count > 1
                and { op = "update", itemID = itemID, count = count - 1 }
                or { op = "remove", itemID = itemID }
            local ok = pcall(inventorySvc.ApplyDelta, record, { op }, "suicide_loose_round_consumed")
            if ok then return true end
        end
    end
    return false
end

local function isLiveHandWeapon(item)
    if not item or type(item) == "table" then return false end
    if instanceof then
        local ok, res = pcall(instanceof, item, "HandWeapon")
        if ok then return res == true end
    end
    return safeCall(item, "isRanged") == true
end

local function isAmmoOrAccessoryType(lowerType)
    if lowerType == "" then return false end
    return string.find(lowerType, "shell", 1, true) ~= nil
        or string.find(lowerType, "bullet", 1, true) ~= nil
        or string.find(lowerType, "ammo", 1, true) ~= nil
        or string.find(lowerType, "box", 1, true) ~= nil
        or string.find(lowerType, "clip", 1, true) ~= nil
        or string.find(lowerType, "mag", 1, true) ~= nil
        or string.find(lowerType, "cartridge", 1, true) ~= nil
        or string.find(lowerType, "holster", 1, true) ~= nil
        or string.find(lowerType, "sling", 1, true) ~= nil
        or string.find(lowerType, "scope", 1, true) ~= nil
end

local function classifyFirearmItem(item, record, body, unlimitedReserve)
    if not item then return nil end
    local fullType = ""
    local subCat = ""
    local isRanged = false
    local ammo = nil
    local chambered = false
    local explicitZeroAmmo = false

    if type(item) == "table" then
        fullType = tostring(item.fullType or item.type or item.itemType or "")
        subCat = tostring(item.subCategory or item.category or "")
        if isAmmoOrAccessoryType(string.lower(fullType)) then return nil end
        isRanged = item.isRanged == true
            or string.lower(subCat) == "firearm"
            or (type(item.isRanged) == "function" and safeCall(item, "isRanged") == true)
        if type(item.getFullType) == "function" then
            fullType = tostring(safeCall(item, "getFullType") or fullType)
        end
        if type(item.getSubCategory) == "function" then
            subCat = tostring(safeCall(item, "getSubCategory") or subCat)
            if string.lower(subCat) == "firearm" then isRanged = true end
        end
        if type(item.getCurrentAmmoCount) == "function" then
            ammo = tonumber(safeCall(item, "getCurrentAmmoCount")) or 0
            explicitZeroAmmo = ammo <= 0
        elseif item.currentAmmoCount ~= nil or item.ammoCount ~= nil or item.ammo ~= nil then
            ammo = tonumber(item.currentAmmoCount or item.ammoCount or item.ammo) or 0
            explicitZeroAmmo = ammo <= 0
        end
        if type(item.isRoundChambered) == "function" then
            chambered = safeCall(item, "isRoundChambered") == true
        elseif item.roundChambered ~= nil then
            chambered = item.roundChambered == true
        end
    else
        -- Java InventoryItem userdata: must be an actual HandWeapon, never ComboItem/ammo
        if not isLiveHandWeapon(item) then return nil end
        local r = safeCall(item, "isRanged")
        subCat = tostring(safeCall(item, "getSubCategory") or "")
        isRanged = (r == true) or (string.lower(subCat) == "firearm")
        fullType = tostring(safeCall(item, "getFullType") or safeCall(item, "getType") or "")
        if not isRanged or isAmmoOrAccessoryType(string.lower(fullType)) then return nil end
        -- On IsoZombie in Build 42, live HandWeapon:getCurrentAmmoCount() stays 0
        -- until PNC.Firearms initializes the magazine on first shot.
        ammo = tonumber(safeCall(item, "getCurrentAmmoCount"))
        chambered = safeCall(item, "isRoundChambered") == true
    end

    local lowerType = string.lower(fullType)
    if isAmmoOrAccessoryType(lowerType) then return nil end
    if not isRanged and type(item) == "table" then
        if string.find(lowerType, "pistol", 1, true)
            or string.find(lowerType, "revolver", 1, true)
            or string.find(lowerType, "rifle", 1, true)
            or string.find(lowerType, "shotgun", 1, true)
            or string.find(lowerType, "assault", 1, true)
            or string.find(lowerType, "varmint", 1, true)
        then
            isRanged = true
        end
    end
    if not isRanged then return nil end

    -- Check canonical PNC.Firearms magazine/reserve state when available so
    -- CompanionAmmoRealismEnabled (NPCAmmoConsumption) is respected accurately.
    local magState = queryMagazineState(record, type(item) ~= "table" and item or nil)
    if magState then
        if magState.ammoNotRequired ~= true and magState.unlimitedReserve ~= true then
            local magCount = tonumber(magState.count) or 0
            local looseCount = tonumber(magState.looseAmmo) or 0
            if magCount <= 0 and looseCount <= 0 and not chambered then
                return nil
            end
        end
    elseif not unlimitedReserve then
        if (explicitZeroAmmo or (type(item) ~= "table" and ammo ~= nil and ammo <= 0)) and not chambered then
            return nil
        end
    end

    local descriptor = nil
    if PNC.Firearms and type(PNC.Firearms.Describe) == "function" and fullType ~= "" then
        local ok, desc = pcall(PNC.Firearms.Describe, record, type(item) ~= "table" and item or nil, body)
        if ok and type(desc) == "table" then descriptor = desc end
    end

    local isHandgun
    if descriptor and descriptor.weaponFamily then
        isHandgun = descriptor.weaponFamily == "handgun"
    else
        isHandgun = string.find(lowerType, "pistol", 1, true) ~= nil
            or string.find(lowerType, "revolver", 1, true) ~= nil
            or string.find(lowerType, "handgun", 1, true) ~= nil
            or string.find(lowerType, "deagle", 1, true) ~= nil
            or string.find(lowerType, "m9", 1, true) ~= nil
            or string.find(lowerType, "m1911", 1, true) ~= nil
    end

    local weaponLabel
    if string.find(lowerType, "revolver", 1, true) then
        weaponLabel = "revolver"
    elseif isHandgun then
        weaponLabel = "pistol"
    elseif string.find(lowerType, "shotgun", 1, true) then
        weaponLabel = "shotgun"
    elseif string.find(lowerType, "rifle", 1, true) or string.find(lowerType, "varmint", 1, true) then
        weaponLabel = "rifle"
    else
        weaponLabel = "gun"
    end

    return {
        kind = isHandgun and "handgun" or "rifle",
        item = item,
        fullType = fullType ~= "" and fullType or (isHandgun and "Base.Pistol" or "Base.HuntingRifle"),
        weaponLabel = weaponLabel,
        shotSound = descriptor and descriptor.shotSound or nil,
        soundRadius = descriptor and descriptor.soundRadius or nil,
        soundVolume = descriptor and descriptor.soundVolume or nil,
    }
end

function Suicide.FindFirearm(record, liveZombie)
    if type(record) ~= "table" then return nil end
    local body = liveZombie or liveBodyFor(record)
    local unlimited = hasUnlimitedAmmoReserve(record)
    if body then
        local primary = safeCall(body, "getPrimaryHandItem")
        local found = classifyFirearmItem(primary, record, body, unlimited)
        if found then return found end
        local inv = safeCall(body, "getInventory")
        local items = inv and safeCall(inv, "getItems") or nil
        local count = tonumber(items and safeCall(items, "size")) or 0
        for i = 0, count - 1 do
            local candidate = safeCall(items, "get", i)
            found = classifyFirearmItem(candidate, record, body, unlimited)
            if found then return found end
        end
    end
    local eq = type(record.equipment) == "table" and record.equipment or nil
    if eq then
        local found = classifyFirearmItem(eq.primary or eq.primaryWeapon or eq.weapon, record, body, unlimited)
        if found then return found end
        if type(eq.primaryFullType) == "string" and eq.primaryFullType ~= "" then
            found = classifyFirearmItem(
                { fullType = eq.primaryFullType, currentAmmoCount = eq.primaryAmmo },
                record, body, unlimited
            )
            if found then return found end
        end
    end
    -- Scan canonical PNC persistent inventory (both map record.inventory.items and flat array)
    local inv = type(record.inventory) == "table" and record.inventory or nil
    if inv then
        if type(inv.items) == "table" then
            for _, entry in pairs(inv.items) do
                local found = classifyFirearmItem(entry, record, body, unlimited)
                if found then return found end
            end
        end
        for i = 1, #inv do
            local found = classifyFirearmItem(inv[i], record, body, unlimited)
            if found then return found end
        end
    end
    return nil
end

local function hasTrait(record, traitId)
    local target = string.lower(tostring(traitId or ""))
    if target == "" or type(record) ~= "table" then return false end
    if PNC.NPCTraitContext and type(PNC.NPCTraitContext.HasTrait) == "function" then
        local ok, res = pcall(PNC.NPCTraitContext.HasTrait, record, traitId)
        if ok and res == true then return true end
    end
    local traits = record.traits
    if type(traits) ~= "table" then return false end
    if traits[traitId] == true or traits[target] == true then return true end
    for i = 1, #traits do
        if string.lower(tostring(traits[i] or "")) == target then return true end
    end
    return false
end

local function readNeed(record, key)
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Get) == "function" then
        local v = tonumber(PNC.IndividualNeeds.Get(record, key))
        if v ~= nil then return v end
    end
    local needs = type(record.needs) == "table" and record.needs or nil
    if needs and tonumber(needs[key]) ~= nil then return tonumber(needs[key]) end
    local stats = type(record.conditionStats) == "table" and record.conditionStats or nil
    return stats and tonumber(stats[key]) or 0
end

local function readPersonality(record, key)
    local p = type(record.personality) == "table" and record.personality or nil
    return p and tonumber(p[key]) or 0.5
end

-- Cause-agnostic probability model combining base cause weight, traits,
-- personality, needs/stress/pain, and normalized urgency [0, 1].
function Suicide.ComputeChance(record, ctx)
    if type(record) ~= "table" then return 0 end
    ctx = type(ctx) == "table" and ctx or {}
    local baseChance = tonumber(ctx.baseChance) or 0.25
    local urgency = clamp(tonumber(ctx.urgency) or 0, 0, 1)

    local chance = baseChance

    if hasTrait(record, "iron_nerves") or hasTrait(record, "brave") or hasTrait(record, "desensitized") then
        chance = chance + 0.18
    end
    if hasTrait(record, "frayed_nerves") or hasTrait(record, "cowardly") then
        chance = chance - 0.12
    end
    if hasTrait(record, "friendly") or hasTrait(record, "protective") or hasTrait(record, "warm") then
        chance = chance + 0.10
    end
    if hasTrait(record, "withdrawn") or hasTrait(record, "reserved") then
        chance = chance + 0.08
    end
    if hasTrait(record, "hardy") or hasTrait(record, "second_wind") then
        chance = chance - 0.08
    end

    local courage = math.max(readPersonality(record, "courage"), readPersonality(record, "resolve"))
    if courage >= 0.65 then chance = chance + 0.08 end

    local altruism = math.max(
        readPersonality(record, "altruism"),
        readPersonality(record, "loyalty"),
        readPersonality(record, "empathy")
    )
    if ctx.hasWitness == true and altruism >= 0.65 then
        chance = chance + 0.10
    end

    local stress = math.max(readNeed(record, "stress"), readNeed(record, "depression"))
    if stress >= 0.60 then chance = chance + 0.10 end

    local pain = readNeed(record, "pain")
    if pain >= 0.70 then chance = chance + 0.08 end

    chance = chance + urgency * 0.20

    return clamp(chance, 0.05, 0.85)
end

function Suicide.RegisterCause(causeId, spec)
    causeId = tostring(causeId or "")
    if causeId == "" or type(spec) ~= "table" then return false end
    local roles = {}
    for k, v in pairs(DEFAULT_ROLES) do
        roles[k] = (type(spec.roles) == "table" and spec.roles[k]) or v
    end
    Suicide.Causes[causeId] = {
        id = causeId,
        priority = tonumber(spec.priority) or 50,
        baseChance = tonumber(spec.baseChance) or 0.25,
        poolID = tostring(spec.poolID or "semantic.companion.need_request"),
        topic = tostring(spec.topic or "knox_distress"),
        deathReason = tostring(spec.deathReason or (causeId .. "_suicide")),
        roles = roles,
        evaluate = type(spec.evaluate) == "function" and spec.evaluate or nil,
        onBeforeKill = type(spec.onBeforeKill) == "function" and spec.onBeforeKill or nil,
    }
    rebuildCauseOrder()
    return true
end

function Suicide.UnregisterCause(causeId)
    causeId = tostring(causeId or "")
    if not Suicide.Causes[causeId] then return false end
    Suicide.Causes[causeId] = nil
    rebuildCauseOrder()
    return true
end

local function speakLine(speaker, addressee, cause, roleKey, act, tokens, now, threadID)
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return false, nil
    end
    if type(speaker) ~= "table" or speaker.id == nil then return false, nil end
    local role = (cause and cause.roles and cause.roles[roleKey]) or DEFAULT_ROLES[roleKey] or roleKey
    local poolID = (cause and cause.poolID) or "semantic.companion.need_request"
    local topic = (cause and cause.topic) or "knox_distress"
    local ref = "suicide:" .. tostring(cause and cause.id or "generic") .. ":" .. tostring(role)
        .. ":" .. tostring(speaker.id) .. ":" .. tostring(math.floor(now))
    local ctx = {
        beatRole = role,
        topic = topic,
        inCombat = false,
        suicideCause = cause and cause.id or nil,
        needType = cause and cause.id == "knox_critical" and "knox" or nil,
        needUrgency = "critical",
    }
    local text, res = Transport.ResolveLine(speaker, {
        eventType = "npc_suicide_beat",
        eventID = ref,
        act = act or "INFORM",
        topic = topic,
        poolID = poolID,
        role = role,
        tokens = tokens,
        context = ctx,
        inCombat = false,
    })
    if not text then return false, nil end
    local sent = Transport.Deliver(speaker, now, {
        eventType = "npc_suicide_beat",
        speechEventID = res and res.realizationID or (poolID .. "." .. tostring(role)),
        act = act or "INFORM",
        domain = "social",
        topic = topic,
        channel = "social",
        family = "npc_suicide",
        priority = 88,
        priorityHoldMs = 2000,
        cooldownMs = 500,
        familyCooldownMs = 500,
        ttlMs = 8000,
        clientCooldowns = { familyMs = 400, speakerMs = 400, ambientMs = 200, mergeWindowMs = 0 },
        responsePlanID = res and res.responsePlanID or nil,
        realizationID = res and res.realizationID or nil,
        poolID = res and res.poolID or poolID,
        lightweightBark = true,
        observerOnly = true,
        eventRef = ref,
        threadID = threadID or ref,
        streamKey = "suicide:" .. tostring(speaker.id),
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
        addressee = addressee,
    })
    local Perf = PNC.Semantics and PNC.Semantics.SpeechPerformance or nil
    if Perf and type(Perf.ResolveCue) == "function" and type(Perf.Perform) == "function" then
        local cue = Perf.ResolveCue({ poolID = poolID, role = role, act = act })
        if cue then
            Perf.Perform(speaker, cue, now)
        end
    end
    return (tonumber(sent) or 0) > 0, text
end

local function pickSceneForFirearm(firearm, now)
    if firearm and firearm.kind == "rifle" then
        return "suicide.rifle", DELAY_SHOT_RIFLE_MS
    end
    local idx = (math.floor(now) % #HANDGUN_SCENES) + 1
    return HANDGUN_SCENES[idx], DELAY_SHOT_HANDGUN_MS
end

local function applyWitnessGrief(witness)
    if type(witness) ~= "table" or witness.alive == false then return end
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Adjust) == "function" then
        pcall(PNC.IndividualNeeds.Adjust, witness, "stress", 0.25)
    elseif type(witness.needs) == "table" then
        witness.needs.stress = clamp((tonumber(witness.needs.stress) or 0) + 0.25, 0, 1)
    end
end

local function resolveLivingNPC(id, fallback)
    if id == nil then return nil end
    local reg = PNC.Registry
    local rec = (reg and type(reg.Get) == "function" and reg.Get(id)) or fallback
    if type(rec) == "table" and rec.alive ~= false then return rec end
    return nil
end

local function releaseWitness(witness)
    if type(witness) == "table" and type(witness.runtime) == "table" then
        witness.runtime.suicideWitness = nil
    end
end

local function attachWitness(witness, roleKind, state, now)
    if type(witness) ~= "table" or witness.alive == false then return end
    witness.runtime = witness.runtime or {}
    witness.runtime.suicideWitness = {
        victimId = state.victimId,
        causeId = state.causeId,
        roleKind = roleKind, -- "primary" or "secondary"
        phase = "watching",
        mournAt = 0,
        expiresAt = now + WITNESS_HARD_TIMEOUT_MS,
        tokens = state.tokens,
        threadID = state.threadID,
    }
end

local function armWitnessMourning(witness, delayMs, now)
    if type(witness) ~= "table" or witness.alive == false then return end
    local wState = witness.runtime and witness.runtime.suicideWitness or nil
    if not wState then return end
    wState.phase = "mourn_pending"
    wState.mournAt = now + delayMs
    wState.expiresAt = now + delayMs + 6000
end

local function finalizeKill(record, body, state, now)
    local cause = Suicide.Causes[state.causeId]
    local firearm = state.firearm or {}

    -- Arm nearby witnesses to mourn on their own behavior ticks after victim retires
    local w1 = resolveLivingNPC(state.witnessId, state.witnessRef)
    local w2 = resolveLivingNPC(state.secondWitnessId, state.secondWitnessRef)
    if w1 then armWitnessMourning(w1, DELAY_MOURN_MS, now) end
    if w2 then armWitnessMourning(w2, DELAY_MOURN_CHIME_MS, now) end

    if record.runtime then record.runtime.suicideState = nil end

    local deathReason = (cause and cause.deathReason) or "suicide"
    if PNC.Health and type(PNC.Health.Kill) == "function" then
        PNC.Health.Kill(record, body, deathReason)
    else
        record.alive = false
        record.deathReason = deathReason
    end

    if isAuditEnabled() then
        logAudit("executed", {
            "npc=" .. tostring(record.id),
            "cause=" .. tostring(state.causeId),
            "scene=" .. tostring(state.sceneId),
            "weapon=" .. tostring(firearm.fullType or "unknown"),
            "deathReason=" .. tostring(deathReason),
            "ragdoll=" .. tostring(state.ragdollStarted == true),
            "witness=" .. tostring(state.witnessId or "none"),
        })
    end
    return true
end

local function drawWeaponViaCombatPipeline(record, body, now)
    -- Use the exact same CombatStance + Equipment presentation pipeline as
    -- combat so the weapon unholsters into hand in both SP and MP.
    if PNC.CombatStance and type(PNC.CombatStance.Maintain) == "function" then
        pcall(PNC.CombatStance.Maintain, record, now)
    end
    if body and PNC.Equipment and type(PNC.Equipment.Apply) == "function" then
        pcall(PNC.Equipment.Apply, body, record)
    end
end

local function triggerGunshotRagdoll(record, body, liveWeapon)
    if not body then return false end
    -- Release the suicide bump animation so the engine can enter ragdoll/falldown
    if PNC.AnimationScenes and type(PNC.AnimationScenes.Stop) == "function" then
        pcall(PNC.AnimationScenes.Stop, record, body, "suicide_shot")
    end
    safeCall(body, "setBumpType", "")
    safeCall(body, "setUseless", false)
    safeCall(body, "setHitReaction", "ShotHead")
    safeCall(body, "setHitForce", 1.0)
    safeCall(body, "setHitFromBehind", false)

    -- Replicate gunshot reaction to MP clients through the canonical combat lane
    if PNC.Network and type(PNC.Network.BroadcastZombieReaction) == "function" then
        pcall(PNC.Network.BroadcastZombieReaction, body, body, {
            kind = "ranged",
            hitReaction = "ShotHead",
            hitForce = 1.0,
            stagger = false,
        })
    end

    local fakeAttacker = (getCell and safeCall(getCell(), "getFakeZombieForHit")) or body
    local hitApplied = false
    local usableWeapon = (isLiveHandWeapon(liveWeapon) and liveWeapon)
        or (type(liveWeapon) == "table" and body.Hit and liveWeapon)
        or nil
    if usableWeapon and body.Hit then
        safeCall(body, "setHealth", 0.01)
        hitApplied = pcall(function()
            body:Hit(usableWeapon, fakeAttacker, 50, false, 1, false)
        end)
    end
    local ragdollActive = safeCall(body, "isRagdollSimulationActive") == true
    return hitApplied and (ragdollActive or safeCall(body, "isDead") == true)
end

local function executeShotAndKill(record, zombie, state, now)
    local body = zombie or liveBodyFor(record)
    local firearm = state.firearm or {}
    local weapon = firearm.item
    local primaryHand = body and safeCall(body, "getPrimaryHandItem") or nil
    local liveWeapon = (isLiveHandWeapon(primaryHand) and primaryHand)
        or (isLiveHandWeapon(weapon) and weapon)
        or (type(primaryHand) == "table" and primaryHand)
        or nil
    local cause = Suicide.Causes[state.causeId]

    -- 1. Emit full weapon fire effects (muzzle flash, gunshot audio, shell drop, world noise)
    local fxEmitted = false
    if body and PNC.FirearmEffects and type(PNC.FirearmEffects.Emit) == "function" then
        local selfTarget = {
            kind = "npc",
            id = record.id,
            x = safeCall(body, "getX") or record.x,
            y = safeCall(body, "getY") or record.y,
            z = safeCall(body, "getZ") or record.z,
            worldObject = body,
        }
        local ok, emitted = pcall(PNC.FirearmEffects.Emit, record, body, selfTarget, liveWeapon)
        fxEmitted = ok and emitted == true
    end

    if body then
        if not fxEmitted then
            local soundName = firearm.shotSound
                or (liveWeapon and safeCall(liveWeapon, "getSwingSound"))
                or (weapon and safeCall(weapon, "getSwingSound"))
                or (firearm.kind == "rifle" and "MSR788Shoot" or "M9Shoot")
            if soundName and soundName ~= "" then
                safeCall(body, "playSound", soundName)
            end
            local radius = tonumber(firearm.soundRadius)
                or tonumber(liveWeapon and safeCall(liveWeapon, "getSoundRadius"))
                or tonumber(weapon and safeCall(weapon, "getSoundRadius"))
                or (firearm.kind == "rifle" and 70 or 45)
            local volume = tonumber(firearm.soundVolume)
                or tonumber(liveWeapon and safeCall(liveWeapon, "getSoundVolume"))
                or tonumber(weapon and safeCall(weapon, "getSoundVolume"))
                or 80
            if body.addWorldSoundUnlessInvisible then
                safeCall(body, "addWorldSoundUnlessInvisible", radius, volume, true)
            elseif addSound then
                pcall(addSound, body, math.floor(tonumber(record.x) or 0), math.floor(tonumber(record.y) or 0),
                    math.floor(tonumber(record.z) or 0), radius, volume)
            end
        end
        safeCall(body, "splatBloodFloorBig")
    end

    -- 2. Consume 1 round through canonical PNC.Firearms.PrepareShot
    local ammoConsumed = false
    local firearms = PNC.Firearms
    if firearms and type(firearms.PrepareShot) == "function" then
        local ok, shotOk, shotReason, shotMag = pcall(firearms.PrepareShot, record, liveWeapon)
        if ok and shotOk == true then
            ammoConsumed = true
        elseif ok and shotReason == "reload_required" and usesInventoryAmmo(record) and type(shotMag) == "table" then
            ammoConsumed = consumeOneLooseRound(record, shotMag.ammoType, shotMag.itemID)
        end
    end
    if not ammoConsumed and (liveWeapon or weapon) then
        local w = liveWeapon or weapon
        local chambered = safeCall(w, "isRoundChambered")
        if chambered == true and w.setRoundChambered then
            safeCall(w, "setRoundChambered", false)
        else
            local curAmmo = tonumber(safeCall(w, "getCurrentAmmoCount"))
            if curAmmo and curAmmo > 0 and w.setCurrentAmmoCount then
                safeCall(w, "setCurrentAmmoCount", curAmmo - 1)
            end
        end
    end

    -- 3. Cause-specific pre-kill hook (e.g., Knox headshot clears infection to prevent reanimation)
    if cause and type(cause.onBeforeKill) == "function" then
        pcall(cause.onBeforeKill, record, body, state)
    end

    -- 4. Apply Build 42 gun ragdoll physics if supported by the live body;
    -- wait briefly for ragdoll physics to settle before finalizing IsoDeadBody.
    if triggerGunshotRagdoll(record, body, liveWeapon) then
        state.ragdollStarted = true
        state.ragdollStartedAt = now
        state.phase = "ragdoll_settle"
        state.nextAt = now + RAGDOLL_MAX_SETTLE_MS
        if isAuditEnabled() then
            logAudit("ragdoll_started", {
                "npc=" .. tostring(record.id),
                "cause=" .. tostring(state.causeId),
                "fxEmitted=" .. tostring(fxEmitted),
            })
        end
        return true
    end

    return finalizeKill(record, body, state, now)
end

local function abortSequence(record, state, reason)
    if isAuditEnabled() then
        logAudit("abort", {
            "npc=" .. tostring(record and record.id or "unknown"),
            "cause=" .. tostring(state and state.causeId or "unknown"),
            "phase=" .. tostring(state and state.phase or "unknown"),
            "reason=" .. tostring(reason or "interrupted"),
        })
    end
    if record and record.runtime then
        record.runtime.suicideState = nil
    end
    if PNC.CombatStance and type(PNC.CombatStance.Clear) == "function" then
        pcall(PNC.CombatStance.Clear, record)
    end
    if state then
        releaseWitness(resolveLivingNPC(state.witnessId, state.witnessRef))
        releaseWitness(resolveLivingNPC(state.secondWitnessId, state.secondWitnessRef))
    end
end

local function defaultRoll()
    if ZombRand then
        return (tonumber(ZombRand(10000)) or 0) / 10000
    end
    return math.random()
end

local function releaseConflictingPosture(record, body)
    local rt = type(record) == "table" and record.runtime or nil
    if not rt then return end
    local executors = PNC.AutonomyExecutors
    if rt.roamingSeat ~= nil then
        if executors and executors.RoamingSeat and type(executors.RoamingSeat.Stop) == "function" then
            pcall(executors.RoamingSeat.Stop, record, body, "suicide_behavior")
        else
            rt.roamingSeat = nil
        end
    end
    if rt.roamAmbient ~= nil then
        if executors and executors.RoamAmbient and type(executors.RoamAmbient.Stop) == "function" then
            pcall(executors.RoamAmbient.Stop, record, body, "suicide_behavior", "movement")
        else
            rt.roamAmbient = nil
        end
    end
    if rt.animationScene ~= nil and PNC.AnimationScenes and type(PNC.AnimationScenes.Stop) == "function" then
        pcall(PNC.AnimationScenes.Stop, record, body, "suicide_behavior")
    end
end

-- Event-driven entry point for any cause (e.g., Knox 90%, family member death, etc.).
function Suicide.TryTrigger(record, zombie, causeId, opts)
    if PNC.Core and type(PNC.Core.IsAuthority) == "function" and PNC.Core.IsAuthority() ~= true then
        return false, "not_authority"
    end
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(opts.now)
    local cause = Suicide.Causes[tostring(causeId or "")]
    if not cause then return false, "unknown_cause" end
    if not isCalmNPC(record, now) then return false, "not_calm" end

    record.runtime = record.runtime or {}
    if record.runtime.suicideState ~= nil or record.runtime.suicideWitness ~= nil then
        return false, "already_in_suicide_sequence"
    end

    local body = zombie or liveBodyFor(record)
    local firearm = Suicide.FindFirearm(record, body)
    if not firearm then
        if isAuditEnabled() then
            logAudit("eval_skip", {
                "npc=" .. tostring(record.id),
                "cause=" .. tostring(cause.id),
                "reason=no_loaded_firearm",
                "unlimited=" .. tostring(hasUnlimitedAmmoReserve(record)),
                "primary=" .. tostring(record.equipment and record.equipment.primaryFullType or "none"),
            })
        end
        return false, "no_loaded_firearm"
    end

    local witness, secondWitness = findNearbyWitnesses(record, now)
    local chance = Suicide.ComputeChance(record, {
        baseChance = opts.baseChance or cause.baseChance,
        urgency = opts.urgency or 0,
        hasWitness = witness ~= nil,
    })
    if opts.force ~= true then
        local rollFn = type(opts.rollFn) == "function" and opts.rollFn or defaultRoll
        local roll = rollFn()
        if roll > chance then
            if isAuditEnabled() then
                logAudit("eval_skip", {
                    "npc=" .. tostring(record.id),
                    "cause=" .. tostring(cause.id),
                    "reason=roll_failed",
                    string.format("roll=%.3f", tonumber(roll) or 1),
                    string.format("chance=%.3f", tonumber(chance) or 0),
                    "weapon=" .. tostring(firearm.fullType),
                    "witness=" .. tostring(witness and witness.id or "none"),
                })
            end
            return false, "roll_failed"
        end
    end

    local tokens = Suicide.BuildPronounTokens(record, body)
    tokens["slot.weapon"] = firearm.weaponLabel or "gun"
    tokens["addressee.name"] = (witness and tostring(witness.name or witness.fullName or "friend")) or "everyone"
    if type(opts.extraTokens) == "table" then
        for k, v in pairs(opts.extraTokens) do
            tokens[k] = v
        end
    end

    local sceneId, shotDelayMs = pickSceneForFirearm(firearm, now)
    local threadID = "suicide:" .. cause.id .. ":" .. tostring(record.id) .. ":" .. tostring(math.floor(now))

    local state = {
        victimId = record.id,
        causeId = cause.id,
        firearm = firearm,
        sceneId = sceneId,
        shotDelayMs = shotDelayMs,
        witnessId = witness and witness.id or nil,
        witnessRef = witness,
        secondWitnessId = secondWitness and secondWitness.id or nil,
        secondWitnessRef = secondWitness,
        tokens = tokens,
        threadID = threadID,
        startedAt = now,
        phase = witness and "intervene" or "execute",
        nextAt = now + (witness and DELAY_INTERVENE_MS or DELAY_EXECUTE_SOLO_MS),
    }

    releaseConflictingPosture(record, body)
    record.runtime.suicideState = state
    if witness then attachWitness(witness, "primary", state, now) end
    if secondWitness then attachWitness(secondWitness, "secondary", state, now) end

    haltActor(record, body)
    drawWeaponViaCombatPipeline(record, body, now)
    speakLine(record, witness, cause, witness and "resolve" or "resolveSolo", "FAREWELL", tokens, now, threadID)
    if isAuditEnabled() then
        logAudit("trigger", {
            "npc=" .. tostring(record.id),
            "cause=" .. tostring(cause.id),
            "scene=" .. tostring(sceneId),
            "weapon=" .. tostring(firearm.fullType),
            "kind=" .. tostring(firearm.kind),
            string.format("chance=%.3f", tonumber(chance) or 0),
            "witness=" .. tostring(witness and witness.id or "none"),
            "secondWitness=" .. tostring(secondWitness and secondWitness.id or "none"),
        })
    end
    return true, state
end

local function tickVictimState(record, zombie, state, now)
    -- Ragdoll settle phase runs after the fatal shot; do not abort on combat/death
    if state.phase == "ragdoll_settle" then
        local body = zombie or liveBodyFor(record)
        local elapsed = now - (tonumber(state.ragdollStartedAt) or now)
        local stillRagdolling = body and safeCall(body, "isRagdollSimulationActive") == true
        if elapsed >= RAGDOLL_MAX_SETTLE_MS or (elapsed >= RAGDOLL_MIN_SETTLE_MS and not stillRagdolling) then
            finalizeKill(record, body, state, now)
        end
        return true
    end

    if not isCalmNPC(record, now) then
        abortSequence(record, state, "not_calm")
        return false
    end

    haltActor(record, zombie)
    drawWeaponViaCombatPipeline(record, zombie, now)
    record.activeJob = "Suicide"
    record.activeBehavior = "Suicide:" .. tostring(state.causeId)

    -- Keep AnimationScenes ticking while the suicide clip is playing
    if record.runtime and record.runtime.animationScene ~= nil
        and PNC.AnimationScenes and type(PNC.AnimationScenes.Tick) == "function"
    then
        PNC.AnimationScenes.Tick(record, zombie, now)
    end

    if now < (tonumber(state.nextAt) or 0) then
        return true
    end

    local cause = Suicide.Causes[state.causeId]
    local witness = resolveLivingNPC(state.witnessId, state.witnessRef)

    if state.phase == "intervene" then
        if witness and isCalmNPC(witness, now) then
            speakLine(witness, record, cause, "intervene", "STOP", state.tokens, now, state.threadID)
            state.phase = "insist"
            state.nextAt = now + DELAY_INSIST_MS
        else
            state.phase = "execute"
            state.nextAt = now + 400
        end
        return true
    elseif state.phase == "insist" then
        if witness and isCalmNPC(witness, now) then
            speakLine(record, witness, cause, "insist", "INFORM", state.tokens, now, state.threadID)
            state.phase = "comply"
            state.nextAt = now + DELAY_COMPLY_MS
        else
            state.phase = "execute"
            state.nextAt = now + 400
        end
        return true
    elseif state.phase == "comply" then
        if witness and isCalmNPC(witness, now) then
            speakLine(witness, record, cause, "comply", "ACCEPT", state.tokens, now, state.threadID)
            state.phase = "execute"
            state.nextAt = now + DELAY_EXECUTE_AFTER_COMPLY_MS
        else
            state.phase = "execute"
            state.nextAt = now + 400
        end
        return true
    elseif state.phase == "execute" then
        local body = zombie or liveBodyFor(record)
        if PNC.AnimationScenes and type(PNC.AnimationScenes.Request) == "function" then
            PNC.AnimationScenes.Request(record, body, state.sceneId, {
                reason = "suicide:" .. tostring(state.causeId),
                props = { primary = state.firearm.fullType },
            })
        end
        state.phase = "shot_kill"
        state.nextAt = now + state.shotDelayMs
        return true
    elseif state.phase == "shot_kill" then
        executeShotAndKill(record, zombie, state, now)
        return true
    end

    abortSequence(record, state)
    return false
end

local function tickWitnessState(record, zombie, wState, now)
    if not isCalmNPC(record, now) or now >= (tonumber(wState.expiresAt) or 0) then
        releaseWitness(record)
        return false
    end

    haltActor(record, zombie)
    record.activeJob = "SuicideWitness"
    record.activeBehavior = "SuicideWitness:" .. tostring(wState.phase)

    if wState.phase == "mourn_pending" and now >= (tonumber(wState.mournAt) or 0) then
        local cause = Suicide.Causes[wState.causeId]
        local roleKey = wState.roleKind == "secondary" and "mournChime" or "mourn"
        speakLine(record, nil, cause, roleKey, "INFORM", wState.tokens, now, wState.threadID)
        applyWitnessGrief(record)
        if isAuditEnabled() then
            logAudit("witness_mourn", {
                "npc=" .. tostring(record.id),
                "victim=" .. tostring(wState.victimId),
                "cause=" .. tostring(wState.causeId),
                "role=" .. tostring(roleKey),
                "pronoun=" .. tostring(wState.tokens and wState.tokens["victim.subj"] or "?"),
            })
        end
        releaseWitness(record)
        return true
    end

    return true
end

-- Native BehaviorSystem ownership tick (called per live NPC in TickOwnership).
-- O(1) fast-path when idle: one timestamp check, zero allocations.
function Suicide.Tick(record, zombie, now, opts)
    if type(record) ~= "table" or record.alive == false then return false end
    now = nowMs(now)
    local runtime = record.runtime

    if runtime then
        if runtime.suicideState ~= nil then
            return tickVictimState(record, zombie, runtime.suicideState, now)
        end
        if runtime.suicideWitness ~= nil then
            return tickWitnessState(record, zombie, runtime.suicideWitness, now)
        end
    end

    opts = type(opts) == "table" and opts or nil
    local nextEvalAt = runtime and tonumber(runtime.nextSuicideEvalAt) or 0
    if not (opts and opts.forceEval == true) and now < nextEvalAt then
        return false
    end

    if not isCalmNPC(record, now) then return false end

    -- Evaluate registered polling causes in priority order (O(1) cheap predicates)
    for i = 1, #sortedCauseIds do
        local cause = Suicide.Causes[sortedCauseIds[i]]
        if cause and cause.evaluate then
            local eligible, urgency, extraTokens = cause.evaluate(record, now)
            if eligible == true then
                record.runtime = record.runtime or {}
                record.runtime.nextSuicideEvalAt = now + EVAL_COOLDOWN_MS
                local ok = Suicide.TryTrigger(record, zombie, cause.id, {
                    now = now,
                    urgency = urgency,
                    extraTokens = extraTokens,
                    rollFn = opts and opts.rollFn or nil,
                    force = opts and opts.force == true or nil,
                })
                if ok then return true end
                return false
            end
        end
    end

    return false
end

-- Built-in cause #1: Critical Knox Virus (>= 90% lethal progression).
Suicide.RegisterCause("knox_critical", {
    priority = 100,
    baseChance = 0.25,
    poolID = "semantic.companion.need_request",
    topic = "knox_distress",
    deathReason = "knox_suicide",
    roles = DEFAULT_ROLES,
    evaluate = function(record)
        local body = record.health and record.health.body or record.bodyHealth or nil
        local inf = type(body) == "table" and type(body.infection) == "table" and body.infection or nil
        if not inf or inf.active ~= true or inf.nonLethalFever == true then
            return false, 0
        end
        local progress = tonumber(inf.progress) or 0
        if progress < 0.90 then return false, 0 end
        local urgency = clamp((progress - 0.90) / 0.10, 0, 1)
        return true, urgency
    end,
    onBeforeKill = function(record)
        -- Destroyed head prevents Knox reanimation
        if PNC.NPCWounds and type(PNC.NPCWounds.ClearInfection) == "function" then
            PNC.NPCWounds.ClearInfection(record, "knox_suicide_headshot")
        elseif record.health and record.health.body then
            record.health.body.infection = nil
        end
    end,
})

return Suicide

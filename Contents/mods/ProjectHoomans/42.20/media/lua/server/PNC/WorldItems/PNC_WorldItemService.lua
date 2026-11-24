-- Autonomous & following-companion ticks for world-item interactions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/WorldItems/PNC_WorldItemService_Requests"

PNC = PNC or {}
PNC.WorldItemService = PNC.WorldItemService or {}

local Service = PNC.WorldItemService
local Categories = PNC.WorldItemCategories

local DEFAULT_AUTONOMOUS_COOLDOWN_MS = 8000
local DEFAULT_FOLLOW_COOLDOWN_MS = 2500
local DEFAULT_RIP_COOLDOWN_MS = 3000

local function nowMs() return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0 end

local function cooldownsFor(npcId)
    local id = tostring(npcId or "")
    Service.CooldownsByNPC[id] = Service.CooldownsByNPC[id] or {}
    return Service.CooldownsByNPC[id]
end

local function isBusy(record, now)
    local rt = record and record.runtime or nil
    return rt ~= nil and (rt.target ~= nil or rt.attackAction ~= nil
        or now < (tonumber(rt.inCombatUntil) or 0)
        or (rt.recentThreat and now <= (tonumber(rt.recentThreat.expiresAt) or 0)))
end

local function isFollowing(record)
    if PNC.HomeDutyService and PNC.HomeDutyService.IsFollowing then
        return PNC.HomeDutyService.IsFollowing(record) == true
    end
    return tostring(record and record.orderSpec and record.orderSpec.kind or "")
        == tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

local function bandageCount(record)
    local Treatment, total = PNC.Treatment, 0
    for _, item in pairs(record and record.inventory and record.inventory.items or {}) do
        if type(item) == "table" and (tonumber(item.stack) or 1) > 0 then
            local t = tostring(item.type or "")
            if t ~= "" and not string.find(t, "Dirty", 1, true)
                and Treatment and Treatment.IsBandageType and Treatment.IsBandageType(t)
            then
                total = total + math.max(1, math.floor(tonumber(item.stack) or 1))
            end
        end
    end
    return total
end

local function hasEdibleFood(record)
    local util = PNC.ItemUtility
    for _, item in pairs(record and record.inventory and record.inventory.items or {}) do
        if type(item) == "table" and (tonumber(item.stack) or 1) > 0 then
            local desc = util and util.DescribeCoreRecord and util.DescribeCoreRecord(item) or nil
            if (desc and desc.food == true and desc.unsafe ~= true)
                or (not desc and (tonumber(item.hungChange) or 0) < 0)
            then
                return true
            end
        end
    end
    return false
end

function Service.RequestCompanionCategoryScavenge(record, ownerPlayer, categories, options)
    options = type(options) == "table" and options or {}
    local normalized = Categories and Categories.NormalizeCategories
        and Categories.NormalizeCategories(categories) or categories
    if Categories and Categories.HasAnyEnabled and not Categories.HasAnyEnabled(normalized) then
        return false, "categories_empty"
    end
    local ox = ownerPlayer and ownerPlayer.getX and tonumber(ownerPlayer:getX()) or record.x
    local oy = ownerPlayer and ownerPlayer.getY and tonumber(ownerPlayer:getY()) or record.y
    local oz = ownerPlayer and ownerPlayer.getZ and tonumber(ownerPlayer:getZ()) or record.z
    local ownerKey = PNC.ScavengePolicy and PNC.ScavengePolicy.OwnerKey
        and ownerPlayer and PNC.ScavengePolicy.OwnerKey(ownerPlayer) or nil
    return Service.RequestIntent(record, {
        action = "grab", purpose = "companion_scavenge",
        precedence = "OPTIONAL", urgency = 0.80, radius = tonumber(options.radius) or 9,
        filter = { categories = normalized, excludeUnsafe = true },
        sourceTypes = options.sourceTypes or { containers = true, floorItems = true, corpses = true },
        ownerKey = ownerKey, ownerX = ox, ownerY = oy, ownerZ = oz,
        maxLeashDist = tonumber(options.maxLeashDist) or 12,
    }, options)
end

function Service.TickFollowCompanion(record, zombie, owner, now, options)
    if not record or record.alive == false or not zombie or not owner then return false, "invalid_follow_state" end
    if not isFollowing(record) then return false, "not_following" end
    if isBusy(record, now) then return false, "combat_active" end
    local rt = record.runtime
    if rt and (rt.medicalCare or (rt.selfTreatment and rt.selfTreatment.phase == "bandaging")) then
        return false, "medical_busy"
    end
    if Service.ActiveByNPC[tostring(record.id)] then return false, "already_active" end

    local policy = PNC.ScavengePolicy
    if not policy or (policy.IsEnabled and policy.IsEnabled(owner) ~= true) then
        return false, "scavenge_disabled"
    end
    local cats = policy.GetCategories and policy.GetCategories(owner) or nil
    if not Categories or not Categories.HasAnyEnabled(cats) then return false, "no_categories_selected" end
    local cdMap = cooldownsFor(record.id)
    now = tonumber(now) or nowMs()
    if now < (tonumber(cdMap.followTick) or 0) then return false, "throttled" end
    cdMap.followTick = now + DEFAULT_FOLLOW_COOLDOWN_MS

    return Service.RequestCompanionCategoryScavenge(record, owner, cats, {
        now = now, cooldownMs = DEFAULT_FOLLOW_COOLDOWN_MS,
        sourceTypes = policy.GetPreferences and policy.GetPreferences(owner) or nil,
        cell = options and options.cell or (zombie.getCell and zombie:getCell()) or nil,
        allowRestrictedZones = options and options.allowRestrictedZones == true,
    })
end

local function emitNoRagsBeat(record, now, sourceType)
    local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
    if not beats or type(beats.Emit) ~= "function" then return end
    local partner = nil
    if type(beats.FindCalmSpeakerNearPoint) == "function" and record.x and record.y then
        local a, b = beats.FindCalmSpeakerNearPoint(record.x, record.y, 10, now)
        if a and a.id ~= record.id then partner = a
        elseif b and b.id ~= record.id then partner = b end
    end
    beats.Emit("medical_rescue.no_rags_notice", {
        speaker = record,
        partner = partner,
        sourceType = sourceType,
        now = now,
    }, now)
end

function Service.TickAutonomous(record, now, options)
    if not record or record.alive == false then return false, "npc_missing" end
    if record.presenceState ~= (PNC.Const and PNC.Const.PRESENCE_LIVE or "live") then return false, "not_live" end
    if record.health and record.health.state == "incapacitated" then return false, "incapacitated" end
    now = tonumber(now) or nowMs()
    if isBusy(record, now) or isFollowing(record) then return false, "busy_or_following" end
    local rt = record.runtime or {}
    if rt.medicalCare or rt.facilityActivity
        or (rt.selfTreatment and rt.selfTreatment.phase == "bandaging")
    then
        return false, "activity_busy"
    end
    if Service.ActiveByNPC[tostring(record.id)] then return false, "already_active" end

    local cdMap = cooldownsFor(record.id)
    if now < (tonumber(cdMap.autoTick) or 0) then return false, "throttled" end
    cdMap.autoTick = now + DEFAULT_AUTONOMOUS_COOLDOWN_MS

    local Treatment = PNC.Treatment
    local needMed = not Treatment or not Treatment.RequiresNPCMedicalItem
        or Treatment.RequiresNPCMedicalItem(record) == true
    local wounds = PNC.NPCWounds and PNC.NPCWounds.FindTreatableWound
        and PNC.NPCWounds.FindTreatableWound(record) or nil
    local bandages = needMed and bandageCount(record) or 1
    if needMed and wounds and bandages < 1 then
        local okWoundRip, wReason, wIntent = Service.RequestBandageRip(record, {
            urgent = true, targetCount = 1, now = now, cooldownMs = DEFAULT_RIP_COOLDOWN_MS,
            cell = options and options.cell or nil,
            allowRestrictedZones = options and options.allowRestrictedZones == true,
        })
        if okWoundRip then
            emitNoRagsBeat(record, now, wIntent and wIntent.candidate and wIntent.candidate.sourceType)
        end
        return okWoundRip, wReason, wIntent
    end
    -- Proactive rag replenishment from corpses, curtains, drawers, and floor items
    -- outside restricted base/safehouse zones (strictly throttled & bucket-cached).
    if needMed and bandages < 1 and now >= (tonumber(cdMap.provisionRip) or 0) then
        cdMap.provisionRip = now + 15000
        local okRip, ripReason, ripIntent = Service.RequestBandageRip(record, {
            urgent = false, targetCount = 2, now = now, cooldownMs = 15000,
            sourceTypes = { corpses = true, containers = true, floorItems = true, curtains = true },
            cell = options and options.cell or nil,
            allowRestrictedZones = false,
        })
        if okRip then
            emitNoRagsBeat(record, now, ripIntent and ripIntent.candidate and ripIntent.candidate.sourceType)
            return true, ripReason, ripIntent
        end
    end

    local hunger = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and tonumber(PNC.IndividualNeeds.Get(record, "hunger")) or 0
    local defs = PNC.NeedsDefinitions
    local trigger = (defs and defs.SUPPLY and defs.SUPPLY.hunger
        and tonumber(defs.SUPPLY.hunger.trigger)) or 0.40
    if hunger >= math.min(0.25, trigger) and not hasEdibleFood(record) then
        return Service.RequestFoodScavenge(record, {
            urgent = hunger >= trigger, now = now, cooldownMs = DEFAULT_AUTONOMOUS_COOLDOWN_MS,
            cell = options and options.cell or nil,
            allowRestrictedZones = options and options.allowRestrictedZones == true,
        })
    end
    return false, "no_world_item_need"
end

return Service

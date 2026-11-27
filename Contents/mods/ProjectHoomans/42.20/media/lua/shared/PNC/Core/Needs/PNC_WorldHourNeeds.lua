-- Unified actor-agnostic World-Hour Needs + Anchor-Slope Stamina/Stress engine.
-- Built atop PNC.DeterministicStat so BOTH colonists and non-colonists share
-- one deterministic O(1) model with mutation-only persistence/network sync.
--
-- Non-colonists:
--   * 0 bytes ModData until they actually eat/drink (deterministic phase from
--     hash(record.id) + worldAgeHours with implicit off-screen foraging wrap).
--   * Only 2 persisted floats (`record.pseudoNeeds = { fedH, drankH }`) once
--     mutated; capped at 0.88 so roamers never silently starve off-screen.
--
-- Stamina & Stress (actor-agnostic anchor-slope `{ v, t, r }`):
--   * Stored in `record.runtime.statAnchors` (bake-on-transition, zero ticks).

PNC = PNC or {}
PNC.WorldHourNeeds = PNC.WorldHourNeeds or {}

local WorldNeeds = PNC.WorldHourNeeds
local Stat = PNC.DeterministicStat or require "PNC/Core/Needs/PNC_DeterministicStat"

local NON_COLONIST_MAX_NEED = 0.88
local OFF_SCREEN_FORAGE_CYCLE_H = 18

-- Mobile-only lethal horizons (world-hours since last fed/drank when all
-- personal inventory, group provisions, and settlement supplies are empty).
WorldNeeds.STARVATION_LETHAL_HOURS = 14 * 24 -- 336h (14 days)
WorldNeeds.DEHYDRATION_LETHAL_HOURS = 7 * 24 -- 168h (7 days)
WorldNeeds.PROVISION_FEED_HOURS = 24
WorldNeeds.PROVISION_DRINK_HOURS = 18

local function nowWorldHours(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.NeedsUtils and type(PNC.NeedsUtils.WorldAgeHours) == "function" then
        return tonumber(PNC.NeedsUtils.WorldAgeHours()) or 0
    end
    if PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function" then
        return tonumber(PNC.Core.NowWorldAgeHours()) or 0
    end
    if getGameTime then
        local ok, gt = pcall(getGameTime)
        if ok and gt and type(gt.getWorldAgeHours) == "function" then
            return tonumber(gt:getWorldAgeHours()) or 0
        end
    end
    return 0
end

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function deterministicPseudoNeed(record, needType, nowH)
    local seed = Stat.HashUnit(tostring(record and record.id or "npc") .. ":" .. tostring(needType))
    local phase = (nowH + seed * OFF_SCREEN_FORAGE_CYCLE_H) % OFF_SCREEN_FORAGE_CYCLE_H
    if needType == "fatigue" then
        -- Circadian curve: higher fatigue at night, lower after dawn
        local hourOfDay = (nowH + seed * 4) % 24
        if hourOfDay >= 21 or hourOfDay < 5 then
            return math.min(NON_COLONIST_MAX_NEED, 0.55 + seed * 0.30)
        end
        return 0.15 + (hourOfDay / 24) * 0.45
    end
    local burn = needType == "thirst" and Stat.THIRST_BURN_HOURS or Stat.HUNGER_BURN_HOURS
    local val = (phase / burn) * 1.15
    if val > NON_COLONIST_MAX_NEED then val = NON_COLONIST_MAX_NEED end
    if val < 0 then val = 0 end
    return val
end

-- O(1) read for non-colonist pseudo-needs (0 allocations when untouched).
function WorldNeeds.GetPseudoNeed(record, needType, at)
    if type(record) ~= "table" then return 0 end
    needType = tostring(needType or "")
    local nowH = nowWorldHours(at)
    local pn = type(record.pseudoNeeds) == "table" and record.pseudoNeeds or nil

    if needType == "hunger" then
        if pn and tonumber(pn.fedH) ~= nil then
            local elapsed = nowH - tonumber(pn.fedH)
            if elapsed > OFF_SCREEN_FORAGE_CYCLE_H then
                return deterministicPseudoNeed(record, "hunger", nowH)
            end
            local need = Stat.HorizonNeed(tonumber(pn.fedH), nowH, Stat.HUNGER_BURN_HOURS, NON_COLONIST_MAX_NEED)
            return need
        end
        return deterministicPseudoNeed(record, "hunger", nowH)
    elseif needType == "thirst" then
        if pn and tonumber(pn.drankH) ~= nil then
            local elapsed = nowH - tonumber(pn.drankH)
            if elapsed > OFF_SCREEN_FORAGE_CYCLE_H then
                return deterministicPseudoNeed(record, "thirst", nowH)
            end
            local need = Stat.HorizonNeed(tonumber(pn.drankH), nowH, Stat.THIRST_BURN_HOURS, NON_COLONIST_MAX_NEED)
            return need
        end
        return deterministicPseudoNeed(record, "thirst", nowH)
    elseif needType == "fatigue" then
        return deterministicPseudoNeed(record, "fatigue", nowH)
    end
    return 0
end

-- Satisfies a non-colonist need by advancing their world-hour horizon.
-- Accepts either normalized relief [0,1] or a food/drink descriptor `{ calories, hungerChange, thirstChange }`.
function WorldNeeds.SatisfyPseudoNeed(record, needType, reliefOrSpec, at)
    if type(record) ~= "table" then return false end
    local nowH = nowWorldHours(at)
    needType = tostring(needType or "")
    record.pseudoNeeds = type(record.pseudoNeeds) == "table" and record.pseudoNeeds or {}
    local pn = record.pseudoNeeds

    if needType == "hunger" then
        local currentNeed = WorldNeeds.GetPseudoNeed(record, "hunger", nowH)
        local currentH = Stat.NeedToHorizon(currentNeed, nowH, Stat.HUNGER_BURN_HOURS)
        local addH
        if type(reliefOrSpec) == "table" then
            addH = Stat.CaloriesToFuelHours(reliefOrSpec.calories, reliefOrSpec.hungerChange)
        else
            addH = math.max(0, tonumber(reliefOrSpec) or 0) * Stat.HUNGER_BURN_HOURS
        end
        local maxH = nowH + Stat.MAX_FUEL_BANK_HOURS * 0.5
        pn.fedH = math.min(maxH, math.max(nowH - Stat.HUNGER_BURN_HOURS, currentH + addH))
        return true, WorldNeeds.GetPseudoNeed(record, "hunger", nowH)
    elseif needType == "thirst" then
        local currentNeed = WorldNeeds.GetPseudoNeed(record, "thirst", nowH)
        local currentH = Stat.NeedToHorizon(currentNeed, nowH, Stat.THIRST_BURN_HOURS)
        local addH
        if type(reliefOrSpec) == "table" then
            addH = Stat.ThirstToWaterHours(reliefOrSpec.thirstChange)
        else
            addH = math.max(0, tonumber(reliefOrSpec) or 0) * Stat.THIRST_BURN_HOURS
        end
        local maxH = nowH + Stat.MAX_WATER_BANK_HOURS * 0.5
        pn.drankH = math.min(maxH, math.max(nowH - Stat.THIRST_BURN_HOURS, currentH + addH))
        return true, WorldNeeds.GetPseudoNeed(record, "thirst", nowH)
    end
    return false
end

-- Actor-agnostic stamina anchor `{ v, t, r }` (time unit: milliseconds; value [0, 1]).
local function ensureStatAnchor(record, key, defaultVal, now, defaultRate)
    record.runtime = record.runtime or {}
    record.runtime.statAnchors = record.runtime.statAnchors or {}
    local a = record.runtime.statAnchors[key]
    if type(a) ~= "table" then
        a = Stat.Anchor(defaultVal, now, defaultRate or 0, 0, 1)
        record.runtime.statAnchors[key] = a
    end
    return a
end

function WorldNeeds.GetStamina(record, at)
    if type(record) ~= "table" then return 1 end
    local rt = record.runtime
    local a = rt and rt.statAnchors and rt.statAnchors.stamina or nil
    if not a then return 1 end
    return Stat.Evaluate(a, nowMs(at), 0, 1)
end

-- Bake-on-transition for stamina (e.g. start sprint: rate = -0.00004/ms; idle regen: +0.00003/ms).
function WorldNeeds.SetStaminaRate(record, ratePerMs, at)
    if type(record) ~= "table" then return 1 end
    local now = nowMs(at)
    local a = ensureStatAnchor(record, "stamina", 1, now, 0)
    return Stat.Bake(a, now, ratePerMs, 0, 1)
end

function WorldNeeds.ConsumeStamina(record, cost, at)
    if type(record) ~= "table" then return 1 end
    local now = nowMs(at)
    local a = ensureStatAnchor(record, "stamina", 1, now, 0)
    return Stat.Shift(a, now, -math.abs(tonumber(cost) or 0), 0, 1)
end

-- Actor-agnostic stress anchor `{ v, t, r }` (time unit: world hours; decays naturally).
local DEFAULT_STRESS_DECAY_PER_HOUR = -0.08

function WorldNeeds.GetStress(record, at)
    if type(record) ~= "table" then return 0 end
    local rt = record.runtime
    local a = rt and rt.statAnchors and rt.statAnchors.stress or nil
    if not a then
        return tonumber(record.needs and record.needs.stress) or 0
    end
    return Stat.Evaluate(a, nowWorldHours(at), 0, 1)
end

function WorldNeeds.AddStress(record, delta, at)
    if type(record) ~= "table" then return 0 end
    local nowH = nowWorldHours(at)
    local base = tonumber(record.needs and record.needs.stress) or 0
    local a = ensureStatAnchor(record, "stress", base, nowH, DEFAULT_STRESS_DECAY_PER_HOUR)
    return Stat.Shift(a, nowH, tonumber(delta) or 0, 0, 1)
end

-- Resolves the NPC's AbstractGroup (mobile or settlement-linked), if any.
function WorldNeeds.ResolveGroup(record)
    if type(record) ~= "table" then return nil end
    local groups = PNC.AbstractGroups
    if type(groups) ~= "table" then return nil end
    local gid = record.groupId or record.abstractGroupId
        or (record.affiliation and record.affiliation.groupId)
    if gid and type(groups.Get) == "function" then
        local g = groups.Get(gid)
        if g then return g end
    end
    if record.id and type(groups.FindByMember) == "function" then
        return groups.FindByMember(record.id)
    end
    return nil
end

local function resolveCommunityID(record, group)
    if type(record) == "table" then
        local cid = record.communityID or record.homeCommunityId
            or (record.affiliation and (record.affiliation.communityID or record.affiliation.homeCommunityId))
        if cid and tostring(cid) ~= "" then return tostring(cid) end
    end
    if type(group) == "table" then
        local cid = group.homeCommunityId or group.communityID
        if cid and tostring(cid) ~= "" then return tostring(cid) end
    end
    return nil
end

-- Returns true if the NPC belongs to a settlement/colony that still has
-- abstract provision points for `needType` ("hunger" -> "food", "thirst" -> "water").
function WorldNeeds.HasSettlementBacking(record, needType)
    if type(record) ~= "table" then return false, nil end
    local group = WorldNeeds.ResolveGroup(record)
    local cid = resolveCommunityID(record, group)
    if not cid then return false, nil end
    local cat = (needType == "thirst" or needType == "water") and "water" or "food"
    if PNC.Communities and type(PNC.Communities.GetSupply) == "function" then
        local amount = tonumber(PNC.Communities.GetSupply(cid, cat))
        if amount ~= nil then
            return amount > 0, cid
        end
    end
    -- Settlement exists without explicit supply depletion: abstractly supplied.
    return true, cid
end

local function findPersonalSustenanceItem(record, needType)
    local inv = type(record) == "table" and record.inventory or nil
    if type(inv) ~= "table" or type(inv.items) ~= "table" then return nil, nil end
    local wantWater = (needType == "thirst" or needType == "water")
    local util = PNC.ItemUtility
    for itemID, item in pairs(inv.items) do
        if type(item) == "table" and item.fullType then
            if util and type(util.DescribeNPCItem) == "function" and type(util.Supports) == "function" then
                local desc = util.DescribeNPCItem(item)
                local req = wantWater and { need = "thirst" } or { need = "hunger" }
                if desc and util.Supports(desc, req) then
                    return itemID, item, desc
                end
            else
                -- Lightweight descriptor fallback for headless/non-colonist items
                if wantWater and (tonumber(item.thirstChange) or 0) < 0 then
                    return itemID, item, item
                elseif not wantWater and ((tonumber(item.hungerChange) or 0) < 0 or (tonumber(item.calories) or 0) > 0) then
                    return itemID, item, item
                end
            end
        end
    end
    return nil, nil, nil
end

-- Enacts eating/drinking from the NPC's unified PNC.Inventory, consuming the item
-- and satisfying their world-hour need (or colonist need if recruited).
function WorldNeeds.ConsumePersonalSustenance(record, needType, at)
    if type(record) ~= "table" then return false, "invalid_record" end
    local nowH = nowWorldHours(at)
    local normNeed = (needType == "thirst" or needType == "water") and "thirst" or "hunger"
    local itemID, item, desc = findPersonalSustenanceItem(record, normNeed)
    if not itemID or not item then return false, "no_item" end

    local consumed = false
    if PNC.SupplyInventory and type(PNC.SupplyInventory.Consume) == "function" then
        local ok = PNC.SupplyInventory.Consume(record, itemID, {
            need = normNeed,
            reason = "world_hour_sustenance",
        })
        consumed = ok == true
    end
    if not consumed then
        -- Direct unified PNC.Inventory consumption fallback
        if PNC.Inventory and type(PNC.Inventory.RemoveItem) == "function" then
            PNC.Inventory.RemoveItem(record, itemID)
            consumed = true
        elseif record.inventory and record.inventory.items then
            record.inventory.items[itemID] = nil
            consumed = true
        end
    end
    if not consumed then return false, "consume_failed" end

    local spec = {
        calories = tonumber(desc and desc.calories or item.calories) or 400,
        hungerChange = tonumber(desc and desc.hungerChange or item.hungerChange) or (normNeed == "hunger" and -0.35 or 0),
        thirstChange = tonumber(desc and desc.thirstChange or item.thirstChange) or (normNeed == "thirst" and -0.45 or 0),
    }
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Satisfy) == "function" then
        PNC.IndividualNeeds.Satisfy(record, normNeed, spec, "personal_inventory")
    else
        WorldNeeds.SatisfyPseudoNeed(record, normNeed, spec, nowH)
    end
    return true, item.fullType
end

-- Resets starving members' world-hour horizons after group food/water resupply
-- without double-counting into group.resources.
function WorldNeeds.ResetStarvingHorizons(group, resetFood, resetWater, at)
    if type(group) ~= "table" then return 0 end
    if not resetFood and not resetWater then return 0 end
    if not (PNC.Registry and type(PNC.Registry.Get) == "function") then return 0 end
    local nowH = nowWorldHours(at)
    local updated = 0
    for _, npcID in ipairs(group.memberIds or {}) do
        local rec = PNC.Registry.Get(npcID)
        if rec and rec.alive ~= false and type(rec.pseudoNeeds) == "table" then
            if resetFood and rec.pseudoNeeds.fedH and (nowH - rec.pseudoNeeds.fedH) > Stat.HUNGER_BURN_HOURS then
                rec.pseudoNeeds.fedH = nowH
                updated = updated + 1
            end
            if resetWater and rec.pseudoNeeds.drankH and (nowH - rec.pseudoNeeds.drankH) > Stat.THIRST_BURN_HOURS then
                rec.pseudoNeeds.drankH = nowH
                updated = updated + 1
            end
        end
    end
    return updated
end

-- Adds compact provision points to a mobile group (e.g. visiting homes/settlements
-- or scavenging) and resets members' lethal horizons if they were starving.
function WorldNeeds.ReplenishGroupProvisions(group, foodPts, waterPts, at)
    if type(group) ~= "table" then return false end
    local nowH = nowWorldHours(at)
    group.resources = type(group.resources) == "table" and group.resources or {}
    local addFood = math.max(0, math.floor(tonumber(foodPts) or 0))
    local addWater = math.max(0, math.floor(tonumber(waterPts) or 0))
    if addFood > 0 then
        group.resources.food = (tonumber(group.resources.food) or 0) + addFood
    end
    if addWater > 0 then
        group.resources.water = (tonumber(group.resources.water) or 0) + addWater
    end
    WorldNeeds.ResetStarvingHorizons(group, addFood > 0, addWater > 0, nowH)
    return true
end

local function tryDrawGroupProvision(group, needType)
    if type(group) ~= "table" or type(group.resources) ~= "table" then return false end
    local cat = (needType == "thirst" or needType == "water") and "water" or "food"
    local cur = tonumber(group.resources[cat]) or 0
    if cur <= 0 then return false end
    group.resources[cat] = cur - 1
    return true
end

local function applySurvivalDeath(record, group, cause)
    if group and PNC.AbstractCasualtyResolver
        and type(PNC.AbstractCasualtyResolver.KillMembers) == "function"
    then
        PNC.AbstractCasualtyResolver.KillMembers(group, { record.id }, cause)
        return
    end
    record.alive = false
    record.deathCause = cause
end

-- Lazy O(1) survival check for non-colonists:
--   * Settlement NPCs with colony provisions > 0 are abstractly supplied (never starve).
--   * Mobile groups consume personal inventory first, then group provision points.
--   * Only mobile groups with empty provisions die at 7d water (168h) / 14d food (336h).
function WorldNeeds.EvaluateSurvival(record, at, opts)
    if type(record) ~= "table" or record.alive == false then
        return { alive = false, cause = "already_dead" }
    end
    opts = type(opts) == "table" and opts or {}
    local nowH = nowWorldHours(at)
    local group = opts.group or WorldNeeds.ResolveGroup(record)

    -- 1. Settlement-backed NPCs stay supplied while their colony has provisions
    local hasFoodSettlement = WorldNeeds.HasSettlementBacking(record, "hunger")
    local hasWaterSettlement = WorldNeeds.HasSettlementBacking(record, "thirst")
    if hasFoodSettlement and hasWaterSettlement then
        return { alive = true, backedBy = "settlement" }
    end

    -- 2. Mobile group / unbacked roamer: initialize horizons lazily if tracking survival
    record.pseudoNeeds = type(record.pseudoNeeds) == "table" and record.pseudoNeeds or {}
    local pn = record.pseudoNeeds
    if pn.fedH == nil then pn.fedH = nowH end
    if pn.drankH == nil then pn.drankH = nowH end

    local waterDeficit = nowH - tonumber(pn.drankH)
    local foodDeficit = nowH - tonumber(pn.fedH)

    -- 3. Try personal inventory, then group provision pool before allowing lethal deficit
    if not hasWaterSettlement and waterDeficit >= Stat.THIRST_BURN_HOURS * 0.70 then
        local ate = WorldNeeds.ConsumePersonalSustenance(record, "thirst", nowH)
        if not ate and tryDrawGroupProvision(group, "thirst") then
            pn.drankH = nowH + WorldNeeds.PROVISION_DRINK_HOURS * 0.25
        end
        waterDeficit = nowH - tonumber(pn.drankH)
    end
    if not hasFoodSettlement and foodDeficit >= Stat.HUNGER_BURN_HOURS * 0.70 then
        local ate = WorldNeeds.ConsumePersonalSustenance(record, "hunger", nowH)
        if not ate and tryDrawGroupProvision(group, "food") then
            pn.fedH = nowH + WorldNeeds.PROVISION_FEED_HOURS * 0.25
        end
        foodDeficit = nowH - tonumber(pn.fedH)
    end

    -- 4. Mobile-only lethal thresholds (7d water / 14d food)
    if not hasWaterSettlement and waterDeficit >= WorldNeeds.DEHYDRATION_LETHAL_HOURS then
        if opts.applyDeath ~= false then
            applySurvivalDeath(record, group, "dehydration")
        end
        return { alive = false, cause = "dehydration", deficitHours = waterDeficit }
    end
    if not hasFoodSettlement and foodDeficit >= WorldNeeds.STARVATION_LETHAL_HOURS then
        if opts.applyDeath ~= false then
            applySurvivalDeath(record, group, "starvation")
        end
        return { alive = false, cause = "starvation", deficitHours = foodDeficit }
    end

    return {
        alive = true,
        backedBy = group and "mobile_group" or "roamer",
        foodDeficitHours = math.max(0, foodDeficit),
        waterDeficitHours = math.max(0, waterDeficit),
    }
end

return WorldNeeds

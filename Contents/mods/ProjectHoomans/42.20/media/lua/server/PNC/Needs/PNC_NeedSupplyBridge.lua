if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedSupplyBridge = PNC.NeedSupplyBridge or {}

local Bridge = PNC.NeedSupplyBridge
local Definitions = PNC.NeedsDefinitions

local function priority(definition, current)
    local severity = math.max(0, math.min(100,
        (tonumber(current) or 0) * 100))
    return math.max(definition.priorityBase,
        math.min(100, definition.priorityBase + severity * 0.4))
end

function Bridge.RequestForNeed(record, needType, force)
    local definition = Definitions.SUPPLY[needType]
    if not definition then return false, "supply_not_supported" end
    local current = PNC.IndividualNeeds.Get(record, needType)
    if not force and current < definition.trigger then
        return false, "trigger_not_reached"
    end
    local required = math.max(0.001, current - definition.target)
    return PNC.NPCSupplyService.Process({
        requesterId = record.id,
        purpose = "NEED",
        resourceKind = definition.resourceKind,
        required = needType == "hunger"
            and { hunger = required, thirst = 0 }
            or { thirst = required },
        target = definition.target,
        priority = priority(definition, current),
        sourcePolicy = "CURRENT_BASE",
        fulfillment = "INSTANT",
        debug = force == true,
    }, {
        force = force == true,
        personalOnly = true,
    })
end

function Bridge.EnsureMedical(record, treatment, partID, force)
    local definition = Definitions.SUPPLY.medical
    return PNC.NPCSupplyService.Process({
        requesterId = record.id,
        purpose = "NEED",
        resourceKind = "MEDICAL",
        treatment = treatment or "BANDAGE",
        required = { partId = partID },
        priority = definition.priorityBase,
        sourcePolicy = "CURRENT_BASE",
        fulfillment = "INSTANT",
        debug = force == true,
    }, { force = force == true, acquireOnly = true })
end

function Bridge.Evaluate(record, forceKind)
    if not record or record.alive == false then return false end
    local changed = false
    if not forceKind or forceKind == "FOOD" then
        local current = PNC.IndividualNeeds.Get(record, "hunger")
        if forceKind == "FOOD" or current >= Definitions.SUPPLY.hunger.trigger then
            local ok = Bridge.RequestForNeed(record, "hunger", forceKind == "FOOD")
            changed = ok or changed
        end
    end
    if not forceKind or forceKind == "HYDRATION" then
        local current = PNC.IndividualNeeds.Get(record, "hydration")
        if forceKind == "HYDRATION"
            or current >= Definitions.SUPPLY.hydration.trigger
        then
            local ok = Bridge.RequestForNeed(
                record, "hydration", forceKind == "HYDRATION"
            )
            changed = ok or changed
        end
    end
    if forceKind == "MEDICAL" then
        local partID = PNC.NPCWounds and PNC.NPCWounds.FindTreatableWound
            and PNC.NPCWounds.FindTreatableWound(record) or nil
        if not partID then return false, "no_treatable_wound" end
        return Bridge.EnsureMedical(record, "BANDAGE", partID, true)
    end
    return changed
end

return Bridge

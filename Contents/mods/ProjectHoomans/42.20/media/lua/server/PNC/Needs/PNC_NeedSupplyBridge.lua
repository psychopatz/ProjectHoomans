if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedSupplyBridge = PNC.NeedSupplyBridge or {}

local Bridge = PNC.NeedSupplyBridge
local Definitions = PNC.NeedsDefinitions

local function wakeProvision(record, needType, current)
    local definition = Definitions.SUPPLY[needType]
    local scheduler = PNC.ProvisionScheduler
    if not definition or not scheduler or not scheduler.MarkDirty
        or (tonumber(current) or 0) < (tonumber(definition.trigger) or 0)
    then return end
    local required = { hunger = 0, thirst = 0 }
    required[needType] = math.max(0.001, tonumber(current) or 0.001)
    local hasPersonal = PNC.NPCSupplyService
        and PNC.NPCSupplyService.HasPersonalSupply
        and PNC.NPCSupplyService.HasPersonalSupply(
            record, definition.resourceKind, required)
    if hasPersonal == true then return end
    scheduler.MarkDirty(record,
        needType == "hunger" and "food" or "hydration", 0)
end

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
    wakeProvision(record, needType, current)
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
            local routed = PNC.NeedFacilityTriggers
                and PNC.NeedFacilityTriggers.PreferFacility
                and PNC.NeedFacilityTriggers.PreferFacility(record, "hunger")
            local ok = routed or Bridge.RequestForNeed(
                record, "hunger", forceKind == "FOOD")
            changed = ok or changed
        end
    end
    if not forceKind or forceKind == "HYDRATION" then
        local current = PNC.IndividualNeeds.Get(record, "thirst")
        if forceKind == "HYDRATION"
            or current >= Definitions.SUPPLY.thirst.trigger
        then
            local routed = PNC.NeedFacilityTriggers
                and PNC.NeedFacilityTriggers.PreferFacility
                and PNC.NeedFacilityTriggers.PreferFacility(
                    record, "hydration")
            local ok = routed or Bridge.RequestForNeed(
                record, "thirst", forceKind == "HYDRATION")
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

if PNC.IndividualNeeds and PNC.IndividualNeeds.RegisterListener then
    PNC.IndividualNeeds.RegisterListener("severity_changed",
        function(record, needType)
            if needType == "hunger" or needType == "thirst" then
                wakeProvision(record, needType,
                    PNC.IndividualNeeds.Get(record, needType))
            end
        end)
end

return Bridge

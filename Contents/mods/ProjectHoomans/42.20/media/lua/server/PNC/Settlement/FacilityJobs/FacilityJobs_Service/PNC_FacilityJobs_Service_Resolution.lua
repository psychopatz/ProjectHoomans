if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

function H.DefinitionCapability(facility)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    local index
    for index = 1, #(level and level.capabilities or {}) do
        local capability = level.capabilities[index]
        if PNC.FacilityJobDefinitions.Get(capability) then return capability end
    end
    return nil
end

function H.ResolveFoodItemFullType(record, capability, options)
    local explicit = options and options.activityItemFullType or nil
    local supply = record and record.runtime
        and record.runtime.supply and record.runtime.supply.byKind
        and record.runtime.supply.byKind.FOOD or nil
    local used = supply and supply.lastUsedItem or nil
    local candidates = supply and supply.personalCandidates or nil
    local required = {
        hunger = math.max(0.001, tonumber(record and record.needs
            and record.needs.hunger) or 0.001),
        thirst = 0,
    }
    if explicit and tostring(explicit) ~= "" then
        return tostring(explicit)
    end
    if capability ~= "food.dine"
        and capability ~= "survival.eat.inventory"
    then return nil end
    if used and used.fullType then return tostring(used.fullType) end
    if candidates and candidates[1] and candidates[1].fullType then
        return tostring(candidates[1].fullType)
    end
    if PNC.NPCSupplyService
        and PNC.NPCSupplyService.HasPersonalSupply
    then
        local _, fullType = PNC.NPCSupplyService.HasPersonalSupply(
            record, "FOOD", required)
        return fullType and tostring(fullType) or nil
    end
    return nil
end

H.BaseForRecord = function(record)
    local affiliation = record and record.affiliation or {}
    local factionId = tostring(affiliation.factionID
        or affiliation.factionId or record and record.factionId or "")
    local colonyId = tostring(affiliation.communityID
        or affiliation.communityId or record and record.communityId or "")
    local id
    local base
    for id, base in pairs(Repository.State.bases or {}) do
        if factionId ~= "" and tostring(base.factionId or "") == factionId then
            return base
        end
        if colonyId ~= "" and tostring(base.colonyId or "") == colonyId then
            return base
        end
    end
    return nil
end


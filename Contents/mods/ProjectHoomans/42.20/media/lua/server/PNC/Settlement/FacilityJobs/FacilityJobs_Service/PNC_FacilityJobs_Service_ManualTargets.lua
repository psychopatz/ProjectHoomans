if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

function H.HasPersonalFood(record)
    local available
    local fullType
    local itemID
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    available, fullType, itemID = PNC.NPCSupplyService.HasPersonalSupply(
        record, "FOOD", {
            hunger = math.max(0.001, tonumber(record and record.needs
                and record.needs.hunger) or 0.001),
            thirst = 0,
        })
    return available == true, fullType, itemID
end

function H.HasPersonalHydration(record)
    local current = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and PNC.IndividualNeeds.Get(record, "thirst")
        or record and record.needs and record.needs.thirst
    local available
    local fullType
    local itemID
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    available, fullType, itemID = PNC.NPCSupplyService.HasPersonalSupply(
        record, "HYDRATION", {
            hunger = 0,
            thirst = math.max(0.001, tonumber(current) or 0.001),
        })
    return available == true, fullType, itemID
end

function H.ManualFoodAssignment(record)
    local x, y, z = H.LivePosition(record)
    return {
        ok = true,
        facilityId = "manual_food:" .. tostring(record.id),
        componentId = "",
        reservationId = "",
        target = { x = x, y = y, z = z },
    }
end

function H.ManualDrinkAssignment(record)
    local x, y, z = H.LivePosition(record)
    return {
        ok = true,
        facilityId = "manual_drink:" .. tostring(record.id),
        componentId = "",
        reservationId = "",
        target = { x = x, y = y, z = z },
    }
end

-- ManualStart is loaded by the dedicated ManualStart provider.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.HoomansWorldView

function Generator.Validate(plan, context)
    context = context or {}
    local resolved = context.resolved
        or PNC.PopulationSandbox.Resolve()
    if not plan or not plan.generationID then
        return false, "INVALID_PLAN"
    end
    if Sectors.IsCommitted(plan.generationID) then
        return false, "GENERATION_ID_DUPLICATE"
    end
    if not resolved.enabled
        or not resolved.settlementsEnabled
    then
        return false, "GENERATION_DISABLED"
    end

    local activeSettlements = 0
    for _, community in ipairs(PNC.Communities.List()) do
        if community.status == "active"
            and community.mode ~= "nomadic"
        then
            activeSettlements = activeSettlements + 1
        end
    end
    if activeSettlements >= Config.HARD_MAX_SETTLEMENTS then
        return false, "HARD_CAP_REACHED"
    end
    if Sectors.CountSettlements(plan.sectorID)
        >= Config.HARD_MAX_SETTLEMENTS_PER_SECTOR
    then
        return false, "SECTOR_HARD_CAP_REACHED"
    end

    local sector = Sectors.Get(plan.sectorID)
    if not sector or not sector.relevant then
        return false, "SECTOR_NOT_RELEVANT"
    end
    local now = tonumber(context.worldAge)
        or Store.WorldAgeHours()
    if now < (tonumber(
        sector.settlementGenerationCooldownUntil
    ) or 0) then
        return false, "GENERATION_COOLDOWN"
    end
    local budget = PNC.PopulationBudget.Calculate(
        sector,
        context
    )
    if budget.settlements.deficit <= 0 then
        return false, "NO_DEFICIT"
    end

    if not Candidates.HasReservation(
        plan.locationID,
        plan.generationID,
        now
    ) then
        return false, "RESERVATION_LOST"
    end
    local evaluation = Candidates.Evaluate(
        plan.locationID,
        plan.factionArchetypeID,
        resolved,
        now,
        plan.generationID
    )
    if not evaluation.eligible then
        return false, evaluation.reason
    end

    local location = Locations.Get(plan.locationID)
    if not location
        or Sectors.LivePlayerDistance(
            location.x,
            location.y
        ) < resolved.minPlayerGenerationDistance
    then
        return false, "PLAYER_TOO_CLOSE"
    end

    if plan.factionPlan then
        if not PNC.FactionArchetypes.Get(
            plan.factionArchetypeID
        ) then
            return false, "INVALID_FACTION"
        end
    else
        local faction = PNC.Factions.Get(plan.factionID)
        if not faction
            or faction.status ~= "active"
            or faction.ownerPlayerKey
            or PNC.Factions.IsMobileGroup(faction)
        then
            return false, "INVALID_FACTION"
        end
    end
    return true, "VALID"
end

return Generator

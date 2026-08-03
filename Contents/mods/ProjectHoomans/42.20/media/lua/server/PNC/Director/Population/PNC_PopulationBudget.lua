-- Desired/current soft budgets, hysteresis, pressure, and MP footprint scaling.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.PopulationBudget = PNC.PopulationBudget or {}

local Budget = PNC.PopulationBudget
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors

local function rounded(value) return math.max(0, math.floor(value + 0.5)) end

function Budget.MultiplayerFactor(playerCount, activeSectorCount, resolved)
    playerCount = math.max(1, tonumber(playerCount) or 1)
    activeSectorCount = math.max(1, tonumber(activeSectorCount) or 1)
    local playerBonus = (playerCount ^ Config.PLAYER_COUNT_EXPONENT - 1)
        * Config.PLAYER_COUNT_BONUS
    local footprintBonus = math.max(0, activeSectorCount - 1) * Config.FOOTPRINT_BONUS
    local influence = tonumber(resolved and resolved.multiplayerScaling) or 1
    return math.max(1, 1 + (playerBonus + footprintBonus) * influence)
end

function Budget.WorldAgeWeights(worldAge)
    local days = math.max(0, tonumber(worldAge) or 0) / 24
    local maturity = math.min(1, days / 60)
    return { groups = 1.10 - maturity * 0.20,
        settlements = 0.65 + maturity * 0.45,
        refugee = 1.35 - maturity * 0.55,
        established = 0.70 + maturity * 0.45 }
end

function Budget.Calculate(sector, context)
    context = context or {}
    local resolved = context.resolved or PNC.PopulationSandbox.Resolve()
    local players = tonumber(context.playerCount) or 0
    local activeSectors = tonumber(context.activeSectorCount) or 0
    local mp = Budget.MultiplayerFactor(players, activeSectors, resolved)
    local age = Budget.WorldAgeWeights(context.worldAge)
    local relevance = sector.active and 1 or Config.RELEVANT_SECTOR_FACTOR
    local desiredGroups = 0
    local desiredSettlements = 0
    if resolved.enabled and resolved.groupsEnabled then
        desiredGroups = rounded(Config.BASE_GROUPS_PER_ACTIVE_SECTOR
            * relevance * resolved.populationMultiplier
            * resolved.roamingGroupMultiplier * mp * age.groups)
    end
    if resolved.enabled and resolved.settlementsEnabled then
        desiredSettlements = rounded(Config.BASE_SETTLEMENTS_PER_ACTIVE_SECTOR
            * relevance * resolved.populationMultiplier
            * resolved.settlementMultiplier * mp * age.settlements)
    end
    desiredGroups = math.min(desiredGroups, Config.HARD_MAX_GROUPS_PER_SECTOR)
    desiredSettlements = math.min(desiredSettlements,
        Config.HARD_MAX_SETTLEMENTS_PER_SECTOR)
    local currentGroups = Sectors.CountGroups(sector.id)
    local currentSettlements = Sectors.CountSettlements(sector.id)
    local groupLower = math.ceil(desiredGroups * Config.HEALTHY_LOWER_FACTOR)
    local settlementLower = math.ceil(desiredSettlements
        * Config.HEALTHY_LOWER_FACTOR)
    local groupFill = math.ceil(desiredGroups * Config.FILL_UNTIL_FACTOR)
    local settlementFill = math.ceil(desiredSettlements
        * Config.FILL_UNTIL_FACTOR)
    local groupDeficit = currentGroups < groupLower
        and math.max(0, groupFill - currentGroups) or 0
    local settlementDeficit = currentSettlements < settlementLower
        and math.max(0, settlementFill - currentSettlements) or 0
    local output = {
        sectorId = sector.id,
        groups = { desired = desiredGroups, current = currentGroups,
            lowerThreshold = groupLower, fillUntil = groupFill,
            deficit = groupDeficit,
            pressure = desiredGroups > 0 and currentGroups / desiredGroups
                or currentGroups > 0 and math.huge or 1 },
        settlements = { desired = desiredSettlements,
            current = currentSettlements, lowerThreshold = settlementLower,
            fillUntil = settlementFill, deficit = settlementDeficit,
            pressure = desiredSettlements > 0
                and currentSettlements / desiredSettlements
                or currentSettlements > 0 and math.huge or 1 },
        multiplayerFactor = mp, worldAgeWeights = age,
    }
    local _, runtime = Sectors.Ensure(sector.id)
    runtime.desiredGroups, runtime.desiredSettlements = desiredGroups, desiredSettlements
    runtime.groupPressure = output.groups.pressure
    runtime.settlementPressure = output.settlements.pressure
    return output
end

function Budget.NeighborPressure(sectorID, kind)
    local total, count = 0, 0
    for _, id in ipairs(Sectors.NeighborIDs(sectorID)) do
        local runtime = Sectors.Runtime[id]
        if runtime then
            total = total + (kind == "SETTLEMENT"
                and runtime.settlementPressure or runtime.groupPressure or 1)
            count = count + 1
        end
    end
    return count > 0 and total / count or 1
end

return Budget

-- Pure, centralized faction diplomacy tuning. Structural and schema
-- constants remain in PNC_FactionConstants.

PNC = PNC or {}
PNC.FactionBalance = PNC.FactionBalance or {}

local Balance = PNC.FactionBalance

local DEFAULTS = {
    telemetryHistoryLimit = 512,
    incidentHistoryLimit = 64,
    recentIncidentIDLimit = 128,
    attackAggregationHours = 0.01,
    minorAttackDamageThreshold = 0,
    severeAttackDamageThreshold = 25,
    repeatedAttackCount = 2,
    callbackDedupeHours = 1,
    callbackDedupeLimit = 2048,
    reconciliationBatchSize = 16,
    reconciliationQueueLimit = 64,
    defaultTruceHours = 24,
    peaceStandingGain = 15,
    peaceTrustGain = 10,
    peaceGrievanceMultiplier = 0.50,

    standingDecayPerDay = 0.05,
    trustDecayPerDay = 0.025,
    fearDecayPerDay = 0.10,
    grievanceDecayPerDay = 0.01,
    peaceGrievanceDecayMultiplier = 2,

    friendlyEntryStanding = 30,
    friendlyEntryTrust = 10,
    friendlyEntryMaxGrievance = 20,
    friendlyExitStanding = 20,
    friendlyExitMaxGrievance = 30,
    waryEntryStanding = -15,
    waryEntryTrust = -25,
    waryEntryFear = 50,
    waryEntryGrievance = 30,
    waryExitStanding = -5,
    waryExitTrust = -15,
    waryExitFear = 40,
    waryExitGrievance = 20,
    hostileEntryStanding = -45,
    hostileEntryGrievance = 65,
    hostileExitStanding = -30,
    hostileExitGrievance = 50,

    escalationRetaliationWeight = 35,
    escalationAggressionWeight = 15,
    killedRetaliationMinimum = 0.25,
    leaderRetaliationMinimum = 0.25,
    hostileMinorRetaliationMinimum = 0.50,
    leaderAuthorityInfluence = 20,
    secondAuthorityInfluence = 15,
    officerAuthorityInfluence = 10,

    looterHostileAggressionMinimum = 0.70,
    looterAdvantageRatio = 0.75,
    looterStrongerTargetRatio = 1.15,
    hostileCautionMinimum = 0.65,
}

local Limits = {
    telemetryHistoryLimit = { 32, 4096 },
    incidentHistoryLimit = { 8, 256 },
    recentIncidentIDLimit = { 16, 512 },
    attackAggregationHours = { 0.0001, 1 },
    minorAttackDamageThreshold = { 0, 1000 },
    severeAttackDamageThreshold = { 0, 1000 },
    repeatedAttackCount = { 2, 20 },
    callbackDedupeHours = { 0.01, 24 },
    callbackDedupeLimit = { 64, 16384 },
    reconciliationBatchSize = { 1, 128 },
    reconciliationQueueLimit = { 4, 512 },
    defaultTruceHours = { 0.1, 8760 },
    peaceStandingGain = { -100, 100 },
    peaceTrustGain = { -100, 100 },
    peaceGrievanceMultiplier = { 0, 1 },
    standingDecayPerDay = { 0, 10 },
    trustDecayPerDay = { 0, 10 },
    fearDecayPerDay = { 0, 10 },
    grievanceDecayPerDay = { 0, 10 },
    peaceGrievanceDecayMultiplier = { 0, 10 },
    friendlyEntryStanding = { -100, 100 },
    friendlyEntryTrust = { -100, 100 },
    friendlyEntryMaxGrievance = { 0, 100 },
    friendlyExitStanding = { -100, 100 },
    friendlyExitMaxGrievance = { 0, 100 },
    waryEntryStanding = { -100, 100 },
    waryEntryTrust = { -100, 100 },
    waryEntryFear = { 0, 100 },
    waryEntryGrievance = { 0, 100 },
    waryExitStanding = { -100, 100 },
    waryExitTrust = { -100, 100 },
    waryExitFear = { 0, 100 },
    waryExitGrievance = { 0, 100 },
    hostileEntryStanding = { -100, 100 },
    hostileEntryGrievance = { 0, 100 },
    hostileExitStanding = { -100, 100 },
    hostileExitGrievance = { 0, 100 },
    escalationRetaliationWeight = { 0, 200 },
    escalationAggressionWeight = { 0, 200 },
    killedRetaliationMinimum = { 0, 1 },
    leaderRetaliationMinimum = { 0, 1 },
    hostileMinorRetaliationMinimum = { 0, 1 },
    leaderAuthorityInfluence = { 0, 100 },
    secondAuthorityInfluence = { 0, 100 },
    officerAuthorityInfluence = { 0, 100 },
    looterHostileAggressionMinimum = { 0, 1 },
    looterAdvantageRatio = { 0.05, 5 },
    looterStrongerTargetRatio = { 0.05, 5 },
    hostileCautionMinimum = { 0, 1 },
}

local function finite(value)
    value = tonumber(value)
    return value ~= nil and value == value
        and value ~= math.huge and value ~= -math.huge
end

function Balance.Get(name)
    local fallback = DEFAULTS[name]
    if fallback == nil then return nil end
    local configured = PNC.Config
        and PNC.Config.Factions
        and PNC.Config.Factions[name]
    local value = finite(configured) and tonumber(configured)
        or fallback
    local limits = Limits[name]
    if limits then
        value = math.max(limits[1], math.min(limits[2], value))
    end
    return value
end

function Balance.GetAll()
    local output = {}
    for name, _ in pairs(DEFAULTS) do
        output[name] = Balance.Get(name)
    end
    return output
end

function Balance.GetDefaults()
    local output = {}
    for name, value in pairs(DEFAULTS) do
        output[name] = value
    end
    return output
end

return Balance

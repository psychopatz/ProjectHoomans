-- One authority-side resolver for all population SandboxVars.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationSandbox = PNC.PopulationSandbox or {}

local Sandbox = PNC.PopulationSandbox
local Config = PNC.DirectorConfig.Population

local function option(name, fallback)
    local vars = SandboxVars and SandboxVars.ProjectHoomans or nil
    local value = math.floor(tonumber(vars and vars[name]) or fallback or 4)
    return math.max(1, math.min(6, value))
end

local function multiplier(values, value)
    return math.max(0, tonumber(values[value]) or 0)
end

function Sandbox.Resolve()
    local population = option("NPCPopulation", 4)
    local settlements = option("SettlementDensity", 4)
    local groups = option("RoamingGroupDensity", 4)
    local recovery = option("PopulationRegeneration", 4)
    local settlementRecovery = option("SettlementRegeneration", 4)
    local multiplayer = option("MultiplayerPopulationScaling", 4)
    local distance = option("PopulationGenerationDistance", 4)
    local distanceScale = ({ 0.65, 0.78, 0.90, 1.0, 1.15, 1.30 })[distance]
    return {
        enabled = population > 1,
        populationOption = population,
        settlementOption = settlements,
        roamingGroupOption = groups,
        regenerationOption = recovery,
        settlementRegenerationOption = settlementRecovery,
        multiplayerOption = multiplayer,
        generationDistanceOption = distance,
        populationMultiplier = multiplier(Config.DENSITY_MULTIPLIERS, population),
        settlementMultiplier = multiplier(Config.DENSITY_MULTIPLIERS, settlements),
        roamingGroupMultiplier = multiplier(Config.DENSITY_MULTIPLIERS, groups),
        groupRegenerationMultiplier = multiplier(Config.RECOVERY_MULTIPLIERS, recovery),
        settlementRegenerationMultiplier = multiplier(
            Config.RECOVERY_MULTIPLIERS, settlementRecovery),
        multiplayerScaling = multiplier(Config.MULTIPLAYER_MULTIPLIERS, multiplayer),
        minPlayerGenerationDistance = Config.PLAYER_EXCLUSION_RADIUS * distanceScale,
        restrictedPlayerGenerationDistance = Config.PLAYER_RESTRICTED_RADIUS * distanceScale,
        preferredPlayerGenerationDistance = Config.PLAYER_PREFERRED_RADIUS * distanceScale,
        groupsEnabled = population > 1 and groups > 1,
        settlementsEnabled = population > 1 and settlements > 1,
        groupRegenerationEnabled = recovery > 1,
        settlementRegenerationEnabled = settlementRecovery > 1,
    }
end

return Sandbox

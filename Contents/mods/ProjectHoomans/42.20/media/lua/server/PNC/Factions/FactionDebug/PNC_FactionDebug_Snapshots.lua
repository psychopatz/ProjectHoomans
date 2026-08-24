if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance
local copy = Internal.copy
local worldAgeHours = Internal.worldAgeHours
local factionSummary = Internal.factionSummary
local npcSummary = Internal.npcSummary
local npcDiagnostic = Internal.npcDiagnostic
local actionResult = Internal.actionResult

local function resolvePlayerContext(player, at)
    if not player or not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then return nil, nil, nil end
    local playerKey = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "faction_debug_snapshot",
        worldAgeHours = at,
    })
    local playerFaction = playerKey
        and Factions.GetFactionForPlayerKey(playerKey) or nil
    local diplomacyFaction = playerKey
        and Factions.GetDiplomacyFactionForPlayerKey(playerKey) or nil
    return playerKey, playerFaction, diplomacyFaction
end

local function buildRoster(player, playerKey, diplomacyFaction, at)
    local roster = {}
    local diagnostics = {}
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false then
            roster[#roster + 1] = npcSummary(record)
            diagnostics[#diagnostics + 1] = npcDiagnostic(
                record, player, playerKey, diplomacyFaction, at)
        end
    end
    table.sort(roster, function(left, right)
        if left.name ~= right.name then return left.name < right.name end
        return left.id < right.id
    end)
    table.sort(diagnostics, function(left, right)
        return tostring(left.npcID) < tostring(right.npcID)
    end)
    return roster, diagnostics
end

local function buildSelection(
    selectedFactionID, selectedTargetFactionID, diplomacyFaction
)
    local output = { members = {}, diplomacy = {} }
    if not Types.IsValidFactionID(selectedFactionID) then return output end
    local faction = Factions.Get(selectedFactionID)
    if not faction then return output end
    output.selected = factionSummary(faction)
    output.members = copy(Factions.GetMembers(faction.id))
    for targetID, relation in pairs(faction.relations or {}) do
        local item = copy(relation)
        item.sourceFactionID = faction.id
        item.targetFactionID = targetID
        output.diplomacy[#output.diplomacy + 1] = item
    end
    table.sort(output.diplomacy, function(left, right)
        return left.targetFactionID < right.targetFactionID
    end)
    local targetID = Types.IsValidFactionID(selectedTargetFactionID)
        and selectedTargetFactionID or nil
    if not targetID and diplomacyFaction
        and diplomacyFaction.id ~= faction.id
    then
        targetID = diplomacyFaction.id
    end
    if not targetID or targetID == faction.id then return output end
    local target = Factions.Get(targetID)
    if not target then return output end
    output.target = factionSummary(target)
    output.forward = Factions.GetRelation(faction.id, targetID)
    output.reverse = Factions.GetRelation(targetID, faction.id)
    local preview = PNC.FactionIntent.ResolveWithTrace({
        archetypeID = faction.archetypeID,
        policy = faction.policy,
        diplomaticState = output.forward
            and output.forward.state or "unknown",
        atWar = output.forward and output.forward.atWar,
        allied = output.forward and output.forward.allied,
        activeTruce = output.forward
            and output.forward.truceUntil > worldAgeHours(),
    })
    output.intentPreview, output.intentTrace =
        preview.result, preview.trace
    return output
end

local function refineIntent(
    selectedNPCID, selectedTarget, diplomacyFaction, player,
    intentPreview, intentTrace
)
    if not Types.IsValidNPCID(selectedNPCID) or not selectedTarget
        or not PNC.FactionBehavior
        or not PNC.FactionBehavior.ResolveIntentWithTrace
    then return intentPreview, intentTrace end
    local observer = PNC.Registry.Get(selectedNPCID)
    local targetEntity
    if diplomacyFaction and selectedTarget.id == diplomacyFaction.id then
        targetEntity = player
    else
        local targetMembers = Factions.GetMembers(selectedTarget.id)
        local firstMember = targetMembers and targetMembers[1] or nil
        targetEntity = firstMember
            and PNC.Registry.Get(firstMember.npcID) or nil
    end
    if not observer or not targetEntity then
        return intentPreview, intentTrace
    end
    local diagnostic = PNC.FactionBehavior.ResolveIntentWithTrace(
        observer, targetEntity, { worldAgeHours = worldAgeHours() })
    if diagnostic then return diagnostic.result, diagnostic.trace end
    return intentPreview, intentTrace
end

function Debug.BuildSnapshot(
    selectedFactionID,
    selectedNPCID,
    action,
    player,
    selectedTargetFactionID
)
    local at = worldAgeHours()
    local factions = {}
    Factions.EnsureLoaded()
    local playerKey, playerFaction, playerDiplomacyFaction =
        resolvePlayerContext(player, at)
    for _, faction in ipairs(Factions.List()) do
        factions[#factions + 1] = factionSummary(faction)
    end
    local roster, npcDiagnostics = buildRoster(
        player, playerKey, playerDiplomacyFaction, at)
    local selection = buildSelection(
        selectedFactionID, selectedTargetFactionID,
        playerDiplomacyFaction)
    selection.intentPreview, selection.intentTrace = refineIntent(
        selectedNPCID, selection.target, playerDiplomacyFaction, player,
        selection.intentPreview, selection.intentTrace)
    return {
        registrySchemaVersion =
            PNC.FactionConstants.REGISTRY_SCHEMA_VERSION,
        registryRevision = Factions.Registry.revision,
        factions = factions,
        selectedFaction = selection.selected,
        selectedFactionID = selection.selected
            and selection.selected.id or nil,
        selectedTargetFaction = selection.target,
        selectedTargetFactionID = selection.target
            and selection.target.id or nil,
        relationForward = selection.forward,
        relationReverse = selection.reverse,
        intentPreview = selection.intentPreview,
        intentTrace = selection.intentTrace,
        selectedNPCID = Types.IsValidNPCID(selectedNPCID)
            and selectedNPCID or nil,
        members = selection.members,
        diplomacy = selection.diplomacy,
        roster = roster,
        npcDiagnostics = npcDiagnostics,
        currentPlayerKey = playerKey,
        currentPlayerFactionID =
            playerFaction and playerFaction.id or nil,
        currentPlayerDiplomacyFactionID =
            playerDiplomacyFaction and playerDiplomacyFaction.id or nil,
        currentPlayerDiplomacyFaction =
            playerDiplomacyFaction
            and (not playerFaction
                or playerDiplomacyFaction.id ~= playerFaction.id)
            and factionSummary(playerDiplomacyFaction) or nil,
        actionResult = copy(action),
        telemetry = PNC.FactionTelemetry
            and PNC.FactionTelemetry.BuildSnapshot({ maximum = 128 }) or nil,
        activeAggregationEpisodes = PNC.FactionIncidentService
            and PNC.FactionIncidentService.GetActiveEpisodes
            and PNC.FactionIncidentService.GetActiveEpisodes() or {},
        reconciliationJobs = PNC.FactionBehavior
            and PNC.FactionBehavior.GetReconciliationSnapshot
            and PNC.FactionBehavior.GetReconciliationSnapshot() or {},
        validationResult = copy(Debug.LastValidation),
        scenarioResult = copy(Debug.LastScenario),
        scenarioNames = copy(PNC.FactionValidation
            and PNC.FactionValidation.Scenarios or {}),
        balance = PNC.FactionBalance
            and PNC.FactionBalance.GetAll() or {},
        populationDirector = PNC.PopulationDirector
            and PNC.PopulationDirector.GetMetrics
            and copy(PNC.PopulationDirector.GetMetrics()) or nil,
        generatedAt = at,
    }
end

return Debug

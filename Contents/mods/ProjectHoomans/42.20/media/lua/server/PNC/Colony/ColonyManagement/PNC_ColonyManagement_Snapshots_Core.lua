if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local owned = Internal.owned
local summary = Internal.summary

local function playerKey(player)
    if player and type(player.getUsername) == "function" then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    if player and type(player.getOnlineID) == "function" then
        return tostring(player:getOnlineID() or "")
    end
    return "local"
end

-- Resolve the authority identity once per snapshot. Ownership checks can run
-- over a large NPC registry, so they must reuse this result instead of
-- repeatedly probing RuntimeContexts/GetCharacterUUID for every record.
local function resolveSnapshotOwner(player)
    local characters = PNC.PlayerCharacters
    local options = {
        callback = "colony_management_snapshot",
        worldAgeHours = PNC.NeedsUtils
            and PNC.NeedsUtils.WorldAgeHours
            and PNC.NeedsUtils.WorldAgeHours() or nil,
    }
    if not characters or type(characters.GetEntityKey) ~= "function" then
        return nil, nil, false
    end
    local ok, key, reason = pcall(
        characters.GetEntityKey,
        player,
        options
    )
    if ok and key ~= nil and tostring(key) ~= "" then
        return { playerKey = tostring(key) }, "resolved", true
    end
    if not ok then reason = "identity_resolution_failed" end
    return {
        unavailable = true,
        reason = tostring(reason or "player_identity_unavailable"),
    }, tostring(reason or "player_identity_unavailable"), true
end

local function playerFactionForSnapshot(player, ownershipContext,
    resolverAvailable)
    if not PNC.Factions then return nil, "factions_unavailable" end
    if ownershipContext and ownershipContext.playerKey
        and type(PNC.Factions.GetFactionForPlayerKey) == "function"
    then
        return PNC.Factions.GetFactionForPlayerKey(
            ownershipContext.playerKey)
    end
    if not resolverAvailable
        and type(PNC.Factions.GetPlayerFaction) == "function"
    then
        return PNC.Factions.GetPlayerFaction(player)
    end
    return nil, "faction_lookup_unavailable"
end

local function snapshotIdentityStatus(ownershipContext, reason,
    resolverAvailable, playerFaction, factionReason)
    local status = {
        state = not resolverAvailable and "legacy" or "ready",
        factionState = playerFaction and "ready" or "missing",
    }
    if not resolverAvailable then return status end
    if ownershipContext and ownershipContext.playerKey then
        if not playerFaction then
            status.factionReason = tostring(
                factionReason or "faction_not_found")
        end
        return status
    end
    status.state = "pending"
    status.reason = tostring(reason or "player_identity_unavailable")
    return status
end

local function ownedZoneSnapshot(service, player)
    local data = service and service.Data or nil
    local zones = data and data.zones or nil
    local ownerID = playerKey(player)
    local selected
    if type(zones) ~= "table" or type(service.GetSnapshot) ~= "function" then
        return nil
    end
    for _, zone in pairs(zones) do
        if tostring(zone.ownerId or "") == ownerID
            and tostring(zone.ownerType or "player") == "player"
            and zone.enabled ~= false
            and (not selected or tostring(zone.id) < tostring(selected.id))
        then selected = zone end
    end
    return selected and service.GetSnapshot(selected.id) or nil
end

local function enrichSettlement(settlement, base, tasks)
    if not settlement then return end
    settlement.facilities = {}
    settlement.stockpileNodes = {}
    for facilityId, _ in pairs(base.facilityIds or {}) do
        local facility = PNC.FacilityService.BuildSnapshot(facilityId)
        if facility then
            settlement.facilities[#settlement.facilities + 1] = facility
        end
    end
    for nodeId, _ in pairs(base.stockpileNodeIds or {}) do
        local node = PNC.SettlementRepository.GetStockpileNode(nodeId)
        if node then
            settlement.stockpileNodes[#settlement.stockpileNodes + 1] =
                PNC.Core.DeepCopy(node)
        end
    end
    table.sort(settlement.facilities, function(a, b)
        local first = tostring(a.definitionId or "") .. ":"
            .. tostring(a.id or "")
        local second = tostring(b.definitionId or "") .. ":"
            .. tostring(b.id or "")
        return first < second
    end)
    table.sort(settlement.stockpileNodes, function(a, b)
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    local taskByFacility = {}
    for _, task in ipairs(tasks) do
        if task.facilityId then
            taskByFacility[tostring(task.facilityId)] = task
        end
    end
    for _, facility in ipairs(settlement.facilities) do
        facility.activeTask = taskByFacility[tostring(facility.id)]
    end
end

local function taskSnapshotForColony(colonyId)
    if PNC.TaskRequestService and PNC.TaskRequestService.Queries
        and PNC.TaskRequestService.Queries.BuildSnapshot
    then
        return PNC.TaskRequestService.Queries.BuildSnapshot(colonyId)
    end
    if PNC.WorkService and PNC.WorkService.Queries
        and PNC.WorkService.Queries.BuildTaskSnapshot
    then
        return PNC.WorkService.Queries.BuildTaskSnapshot(colonyId)
    end
    return {}
end

-- Settlement consumers need a compact, authoritative refresh when a facility
-- changes outside a command request (for example when construction completes).
-- Keep this separate from the much heavier colony-management snapshot.
function Internal.BuildSettlementSnapshot(baseOrId, tasks)
    local base = type(baseOrId) == "table" and baseOrId
        or PNC.BaseService and PNC.BaseService.Get(baseOrId) or nil
    if not base or not PNC.BaseService
        or not PNC.BaseService.BuildSnapshot
    then
        return nil
    end
    tasks = type(tasks) == "table" and tasks
        or taskSnapshotForColony(base.colonyId)
    local settlement = PNC.BaseService.BuildSnapshot(base)
    enrichSettlement(settlement, base, tasks)
    return settlement
end

local function activeColonyForFaction(playerFaction)
    if not playerFaction or not PNC.Communities
        or not PNC.Communities.GetForFaction
    then
        return nil
    end
    for _, value in ipairs(PNC.Communities.GetForFaction(
        playerFaction.id) or {}) do
        if value.status == "active" then return value end
    end
    return nil
end

-- Base claim and the Command Hub only need identity plus settlement state.
-- Keep this projection separate from the much heavier colony-management
-- payload so it remains safe to send through the MP command buffer.


Internal.SnapshotDeps = {
    playerKey = playerKey,
    resolveSnapshotOwner = resolveSnapshotOwner,
    playerFactionForSnapshot = playerFactionForSnapshot,
    snapshotIdentityStatus = snapshotIdentityStatus,
    ownedZoneSnapshot = ownedZoneSnapshot,
    enrichSettlement = enrichSettlement,
    taskSnapshotForColony = taskSnapshotForColony,
    activeColonyForFaction = activeColonyForFaction,
}

return Management

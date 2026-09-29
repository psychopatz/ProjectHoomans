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
function Management.BuildBaseSnapshot(player)
    local ownershipContext, identityReason, resolverAvailable =
        resolveSnapshotOwner(player)
    local playerFaction, factionReason = playerFactionForSnapshot(
        player, ownershipContext, resolverAvailable)
    local colony = activeColonyForFaction(playerFaction)
    local base = colony and PNC.BaseService
        and PNC.BaseService.GetForColony(colony.id) or nil
    local faction = playerFaction and {
        id = playerFaction.id,
        name = playerFaction.name,
        revision = playerFaction.revision,
    } or nil
    local colonySnapshot = colony and {
        id = colony.id,
        factionID = playerFaction and playerFaction.id or nil,
    } or nil
    local identityStatus = snapshotIdentityStatus(
        ownershipContext,
        identityReason,
        resolverAvailable,
        playerFaction,
        factionReason
    )
    --[[
        The Base window's Facilities tab prices every build requirement against
        the stockpile, so this projection has to carry the stockpile rows. It
        did not, and every requirement therefore read as "0 in stock" no matter
        how full the stockpile was, which disabled BUILD and made the server
        reject the order with MISSING_MATERIALS.

        Trim what only the Colony Storage window renders (journal activity,
        storage metrics, debug authorization): this payload is polled every few
        seconds while the window is open, and the rows are the only part the
        build UI needs.
    ]]
    local storage
    if PNC.ColonyStorageService
        and type(PNC.ColonyStorageService.BuildSnapshot) == "function"
    then
        storage = PNC.ColonyStorageService.BuildSnapshot(
            player, { includeRows = true }, ownershipContext)
        if storage then
            storage.activity = nil
            storage.metrics = nil
            storage.debugAuthorized = nil
        end
    end
    --[[
        The Buildings tab reads snapshot.building for its queue. The base
        projection never carried it, so the tab showed "NO MATCHING RECIPES"
        and an empty blueprint queue while the same data was only available
        through the heavier management projection.

        Only the queue travels: the recipe catalog is derived from
        SpriteConfigManager on both sides, so the client rebuilds it locally and
        prices it against the stockpile rows above. Shipping a few hundred
        descriptors with per-requirement stock on a two-second poll would be
        pure payload.
    ]]
    local building
    if colony and PNC.BuildingService
        and type(PNC.BuildingService.BuildQueueProjection) == "function"
    then
        building = {
            queue = PNC.BuildingService.BuildQueueProjection(colony,
                storage and storage.storageId or storage and storage.id or nil),
            generation = PNC.BuildRecipeCatalog
                and PNC.BuildRecipeCatalog.Generation or nil,
        }
    end
    return {
        colony = colonySnapshot,
        faction = faction,
        settlement = base and Internal.BuildSettlementSnapshot(base, {}) or nil,
        storage = storage,
        building = building,
        identityStatus = identityStatus,
        generatedAt = PNC.NeedsUtils.WorldAgeHours(),
    }
end

local function storageStateFor(storageRecord)
    if not storageRecord then return nil end
    if not PNC.ColonyStorageRepository
        or type(PNC.ColonyStorageRepository.Get) ~= "function"
    then return nil end
    local storageId = storageRecord.storageId or storageRecord.id
    if storageId == nil then return nil end
    return PNC.ColonyStorageRepository.Get(storageId)
end

--[[
    Optional projection groups.

    The full colony-management snapshot is far larger than one engine packet
    (see PNC_Network_Server_Budget), so a caller states which groups it needs
    and receives only those. Omitted groups are absent from the payload rather
    than nil, so the client merge keeps whatever it already had for them.

    A caller that passes no `sections` still receives the complete snapshot, so
    every existing consumer keeps its current contract.
]]
local SNAPSHOT_SECTIONS = {
    roster = true,
    settlement = true,
    storage = true,
    storageAccess = true,
    research = true,
    workshop = true,
    building = true,
    tasks = true,
    provision = true,
    zones = true,
}

local function requestedSections(options)
    local requested = options and options.sections
    if type(requested) ~= "table" then return nil end
    local set = { header = true }
    for _, name in ipairs(requested) do
        name = tostring(name or "")
        if SNAPSHOT_SECTIONS[name] then set[name] = true end
    end
    return set
end

function Management.BuildSnapshot(player, options)
    options = type(options) == "table" and options or {}
    local sections = requestedSections(options)
    local function want(name)
        return sections == nil or sections[name] == true
    end
    local output = {}
    local counts = { hunger = {}, thirst = {}, fatigue = {} }
    local supplyShortages = { food = {}, hydration = {}, medical = {} }
    local ownedRecords = {}
    local candidateRecords = {}
    local playerFaction, colony
    local factionReason
    local ownershipContext, identityReason, resolverAvailable =
        resolveSnapshotOwner(player)
    local identityReady = not resolverAvailable
        or ownershipContext and ownershipContext.playerKey ~= nil
    local function recordOwned(record)
        if resolverAvailable then
            return identityReady and owned(
                record, player, ownershipContext) or false
        end
        return owned(record, player)
    end
    playerFaction, factionReason = playerFactionForSnapshot(
        player, ownershipContext, resolverAvailable)
    if want("roster") then
        for _, record in pairs(PNC.Registry.Data or {}) do
            if record.alive ~= false then
                if recordOwned(record) then
                    ownedRecords[#ownedRecords + 1] = record
                elseif playerFaction and record.affiliation
                    and tostring(record.affiliation.factionID or "")
                        == tostring(playerFaction.id or "")
                then
                    -- The record is already in the resolved player's faction.
                    -- Let the canonical recruitment repair reconcile secondary
                    -- membership state without accepting username ownership.
                    candidateRecords[#candidateRecords + 1] = record
                end
            end
        end
        if PNC.Recruitment and PNC.Recruitment.ReconcileOwned then
            for _, record in ipairs(ownedRecords) do
                PNC.Recruitment.ReconcileOwned(player, record, {
                    ownershipContext = ownershipContext,
                    playerFaction = playerFaction,
                })
            end
            for _, record in ipairs(candidateRecords) do
                local repaired = PNC.Recruitment.ReconcileOwned(player, record, {
                    ownershipContext = ownershipContext,
                    playerFaction = playerFaction,
                })
                if repaired and recordOwned(record) then
                    ownedRecords[#ownedRecords + 1] = record
                end
            end
        end
    end
    colony = activeColonyForFaction(playerFaction)
    if want("roster") then
        local people, attention = {}, {}
        for _, record in ipairs(ownedRecords) do
            local value = summary(record, player, options); people[#people+1]=value
            for _, needType in ipairs(Definitions.TYPES) do
                local level=Definitions.GetLevel(needType, value.needs[needType]); counts[needType][level]=(counts[needType][level] or 0)+1
                if level == "CRITICAL" or level == "SEVERE" or level == "MODERATE" then attention[#attention+1]={ severity=level, npcID=value.id, name=value.name, needType=needType, value=value.needs[needType] } end
            end
            local supply = record.runtime and record.runtime.supply
                and record.runtime.supply.byKind or {}
            for kind, bucket in pairs({
                FOOD = supplyShortages.food,
                HYDRATION = supplyShortages.hydration,
                MEDICAL = supplyShortages.medical,
            }) do
                local lane = supply[kind]
                if lane and lane.phase == "FAILED" then
                    bucket[#bucket + 1] = {
                        npcID = record.id,
                        name = tostring(record.name or record.id),
                        reason = lane.lastFailureReason,
                        nextRetry = lane.nextRetry,
                    }
                end
            end
        end
        table.sort(people,function(a,b) return a.name<b.name end)
        table.sort(attention,function(a,b) return a.value>b.value end)
        output.people = people
        output.attention = attention
        output.levels = counts
        output.supplyShortages = supplyShortages
    end
    -- Facility active-task decoration needs the task projection, so build it
    -- internally whenever either group is requested and only publish it when
    -- the caller asked for tasks.
    local tasks
    local function taskSnapshot()
        if tasks ~= nil then return tasks end
        if not colony then tasks = {} return tasks end
        tasks = PNC.TaskRequestService
            and PNC.TaskRequestService.Queries.BuildSnapshot(colony.id)
            or PNC.WorkService and PNC.WorkService.Queries
                and PNC.WorkService.Queries.BuildTaskSnapshot
                and PNC.WorkService.Queries.BuildTaskSnapshot(colony.id) or {}
        return tasks
    end
    local storage
    local storageReason
    local storageRecord
    -- `storage` carries the stockpile row projection; `storageAccess` is the
    -- same projection without the per-stack rows, for consumers that only need
    -- access and authorization state.
    local storageAccess
    if want("storage") or want("storageAccess") then
        if PNC.ColonyStorageService
            and PNC.ColonyStorageService.BuildSnapshot
        then
            local projectionOptions = options
            if not want("storage") then
                projectionOptions = {
                    includeRows = false,
                    storageId = options.storageId,
                    taskBrainNpcID = options.taskBrainNpcID,
                    search = options.search,
                    sort = options.sort,
                }
            end
            storage, storageReason = PNC.ColonyStorageService.BuildSnapshot(
                player, projectionOptions, ownershipContext)
            if not want("storage") then
                storageAccess = storage
                storage = nil
            end
        end
        storageRecord = storageAccess or storage
    elseif want("research") or want("building") then
        -- Research and construction only need the storage record, not the
        -- stockpile row projection that dominates the payload.
        if PNC.ColonyStorageService
            and type(PNC.ColonyStorageService.ResolveForPlayer) == "function"
        then
            storageRecord, storageReason =
                PNC.ColonyStorageService.ResolveForPlayer(
                    player, options.storageId, ownershipContext)
        end
    end
    local storageState = storageStateFor(storageRecord)
    local identityStatus = snapshotIdentityStatus(
        ownershipContext,
        identityReason,
        resolverAvailable,
        playerFaction,
        factionReason
    )
    output.colony = colony
    output.identityStatus = identityStatus
    output.faction = playerFaction and {
        id = playerFaction.id,
        name = playerFaction.name,
        archetypeID = playerFaction.archetypeID,
        emblem = PNC.Core.DeepCopy(playerFaction.emblem),
        revision = playerFaction.revision,
        renamePending = playerFaction.tags
            and playerFaction.tags.factionNamePending == true or false,
    } or nil
    if want("storage") then
        local storageAccess = storage and storage.access or nil
        output.storage = storage
        output.storageStatus = {
            state = storage and storageAccess
                and storageAccess.hasStockpile == true and "ready"
                or storage and "blocked"
                or identityStatus.state == "pending" and "pending"
                or "unavailable",
            reason = storageAccess and storageAccess.reason
                or storageReason,
            hasStockpile = storageAccess
                and storageAccess.hasStockpile == true or false,
            insideBase = storageAccess
                and storageAccess.insideBase == true or false,
        }
        output.provisionStorage = PNC.ProvisionEvaluator
            and PNC.ProvisionEvaluator.MeasureStorage
            and PNC.ProvisionEvaluator.MeasureStorage(storageState) or {}
    end
    if want("storageAccess") and not want("storage") then
        output.storageAccess = storageAccess
    end
    if want("research") then
        output.research = PNC.ColonyResearchService
            and PNC.ColonyResearchService.BuildSnapshot(storageState)
            or { entries = {} }
    end
    if want("workshop") then
        output.workshop = colony and PNC.CraftingService
            and PNC.CraftingService.Queries.BuildSnapshot(colony.id)
            or { knownRecipes = {}, orders = {} }
    end
    if want("building") then
        output.building = colony and PNC.BuildingService
            and PNC.BuildingService.BuildSnapshot(player, storageState, colony)
            or { recipes = {}, queue = {} }
    end
    if want("tasks") then
        output.tasks = taskSnapshot()
    end
    if want("provision") then
        output.provisionSettings = PNC.ProvisionPolicyService
            and PNC.ProvisionPolicyService.BuildSnapshot
            and PNC.ProvisionPolicyService.BuildSnapshot(player) or nil
    end
    if want("settlement") then
        local base = colony and PNC.BaseService
            and PNC.BaseService.GetForColony(colony.id) or nil
        output.settlement = Internal.BuildSettlementSnapshot(
            base, taskSnapshot())
        output.utilities = { facilities = {} }
    end
    if want("zones") then
        output.zoneState = {
            lumber=ownedZoneSnapshot(PNC.LumberService, player),
            fishing=ownedZoneSnapshot(PNC.FishingService, player),
        }
    end
    output.generatedAt = PNC.NeedsUtils.WorldAgeHours()
    return output
end


return Management

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local Const = PNC.Const
local Policy = PNC.ScavengePolicy
local TERMINAL_STATES = Internal.TERMINAL_STATES
local copy = Internal.Copy
local increment = Internal.Increment
local emit = Internal.Emit
local teamRecords = Internal.TeamRecords
local sessionForNPC = Internal.SessionForNPC
local ownerMatches = Internal.OwnerMatches
local removeSession = Internal.RemoveSession
local makeSessionRoom = Internal.MakeSessionRoom
local normalizePolicy = Internal.NormalizePolicy
local policyEnabled = Internal.PolicyEnabled

function Service.StartSearch(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local records, reason = teamRecords(player, arguments)
    if not records then return false, reason end
    local record = records[1]
    local sourcePolicy = normalizePolicy(arguments.sourcePolicy)
    if not policyEnabled(sourcePolicy) then return false, "source_policy_empty" end
    local radius = math.max(1, math.min(Const.SCAVENGE_MAX_RADIUS,
        math.floor(tonumber(arguments.radius)
            or Const.SCAVENGE_DEFAULT_RADIUS)))
    local replaced = {}
    for _, teamRecord in ipairs(records) do
        local previous = sessionForNPC(teamRecord.id)
        if previous and not replaced[previous.id] then
            replaced[previous.id] = true
            if not TERMINAL_STATES[previous.state] then
                Service.Cancel(player, { sessionId = previous.id,
                    reason = "replaced" })
            else
                removeSession(previous, "replaced_terminal")
            end
        end
    end
    if not makeSessionRoom() then return false, "session_limit" end
    local ownerKey = Policy.OwnerKey(player)
    if not ownerKey then return false, "owner_identity_unavailable" end
    Policy.SetPreferences(player, sourcePolicy)
    local result
    result, reason = WorldLoot.FindSources({
        x = player:getX(), y = player:getY(), z = player:getZ(),
        radius = radius, sourceTypes = sourcePolicy,
        maxCandidates = Const.SCAVENGE_MAX_CANDIDATES,
        ownerToken = ownerKey .. ":" .. tostring(record.id),
    })
    if not result then return false, reason end
    local id = "scavenge:" .. tostring(Service.NextSessionId)
    Service.NextSessionId = Service.NextSessionId + 1
    local npcIds, workers, previousOrders = {}, {}, {}
    for _, teamRecord in ipairs(records) do
        local npcId = tostring(teamRecord.id)
        npcIds[#npcIds + 1] = npcId
        previousOrders[npcId] = copy(teamRecord.orderSpec)
        workers[npcId] = { npcId = npcId, phase = "READY" }
    end
    local session = {
        id = id, revision = 1,
        ownerKey = ownerKey, ownerPlayer = player,
        npcId = tostring(record.id), npcName = tostring(record.name or record.id),
        record = record,
        npcIds = npcIds, workers = workers,
        originX = player:getX(), originY = player:getY(), originZ = player:getZ(),
        radius = radius, sourcePolicy = sourcePolicy,
        candidates = result.sources, candidateCount = #result.sources,
        nextCandidateIndex = 1, processedCount = 0, searchedCount = 0,
        unreachableCount = 0, invalidCount = 0,
        sourceCounts = result.counts,
        worldLootSessionId = result.sessionId,
        manifest = {}, manifestById = {}, nextEntryId = 1,
        activity = {}, state = "DISCOVERING", phase = "DISCOVERING",
        createdAt = PNC.Core.Now(), updatedAt = PNC.Core.Now(),
        previousOrder = copy(record.orderSpec),
        previousOrders = previousOrders,
        runActive = true,
        searchComplete = #result.sources < 1,
        truncated = result.truncated == true,
        collectedCount = 0, unavailableCount = 0,
    }
    Service.Sessions[id] = session
    for _, npcId in ipairs(npcIds) do Service.ByNPC[npcId] = id end
    increment("SearchStarted")
    increment("SourcesScanned", #result.sources)
    emit("SearchStarted", session)
    for _, npcId in ipairs(npcIds) do
        PNC.Tasking.Events.Emit("SCAVENGE_SEARCH_STARTED", {
            npcId = npcId, source = "ScavengeService",
            entityId = session.id,
        }, { immediate = true })
    end
    Service.SendSnapshot(session)
    return true, "search_started", Service.BuildSnapshot(session)
end

function Service.AppendSourceItems(session, source, discoveredByNpcId)
    local remaining = Const.SCAVENGE_MAX_MANIFEST_ENTRIES - #session.manifest
    if remaining <= 0 then
        session.truncated = true
        increment("ManifestCapHits")
        return true, 0
    end
    local items, reason, info = WorldLoot.ListItems(source.sourceToken, {
        maxItems = remaining,
    })
    if not items then return false, reason end
    for index = 1, #items do
        if #session.manifest >= Const.SCAVENGE_MAX_MANIFEST_ENTRIES then
            session.truncated = true
            increment("ManifestCapHits")
            break
        end
        local item = items[index]
        local entry = {
            entryId = session.id .. ":e:" .. tostring(session.nextEntryId),
            sourceToken = source.sourceToken,
            sourceType = source.sourceType,
            sourceLabel = source.label,
            itemToken = item.itemToken,
            fullType = item.fullType,
            displayName = item.displayName,
            category = item.category,
            quantity = item.quantity or 1,
            x = source.x, y = source.y, z = source.z,
            distanceSq = source.approximateDistanceSq,
            discoveredByNpcId = discoveredByNpcId
                and tostring(discoveredByNpcId) or nil,
            autoGrab = Policy.Matches(session.ownerPlayer, item.fullType),
            status = "AVAILABLE",
        }
        session.nextEntryId = session.nextEntryId + 1
        session.manifest[#session.manifest + 1] = entry
        session.manifestById[entry.entryId] = entry
    end
    if info and info.truncated then session.truncated = true end
    increment("ManifestEntries", #items)
    return true, #items
end

return Service

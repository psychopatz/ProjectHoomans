-- Shared authoritative command handlers. SP dispatches in-process; MP uses
-- the same functions through OnClientCommand.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}

local Commands = PNC.PlayerKnowledgeCommands
local Network = PNC.Network
local Core = PNC.Core

Commands.Processed = Commands.Processed or {}
Commands.Uncommitted = Commands.Uncommitted or {}
Commands.Diagnostics = Commands.Diagnostics or {}
local BOOTSTRAP_CHUNK_SIZE = 32

function Commands.GetDiagnostics(characterUUID)
    local value = Commands.Diagnostics[tostring(characterUUID or "")]
    return value and Core.DeepCopy(value) or nil
end

local function safeID(value)
    value = tostring(value or "")
    if value == "" or #value > 128 or string.find(value, "%c") then return nil end
    return value
end

local function contextFor(player, reason)
    if not PNC.PlayerContext or not PNC.PlayerContext.Resolve then
        return nil, "player_context_unavailable"
    end
    return PNC.PlayerContext.Resolve(player, reason)
end

local function factFromSnapshot(snapshot, descriptorID)
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if descriptor.descriptorID == descriptorID then return descriptor end
        end
    end
    return nil
end

local function sanitizeSnapshot(snapshot)
    local safe = Core.DeepCopy(snapshot or {})
    local nameFact = factFromSnapshot(safe, "identity.name")
    safe.identity = type(safe.identity) == "table" and safe.identity or {}
    safe.identity.displayName = nameFact and tostring(nameFact.value) or nil
    if not nameFact then safe.identity.archetypeLabel = nil end
    return safe, nameFact
end

local function presentationFor(player, npcID, requestID)
    local context, reason = contextFor(player, "npc_presentation")
    if not context then
        return { requestID = requestID, npcID = npcID, state = "error", reason = reason }
    end
    if Commands.Uncommitted[context.characterUUID]
        and Commands.Uncommitted[context.characterUUID][npcID]
    then
        return {
            requestID = requestID, npcID = npcID, state = "error",
            reason = "knowledge_commit_pending",
            characterUUID = context.characterUUID,
            bindingRevision = context.bindingRevision,
        }
    end
    local snapshot
    local nameFact
    snapshot, reason = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    if not snapshot then
        return {
            requestID = requestID, npcID = npcID, state = "error",
            reason = reason, bindingRevision = context.bindingRevision,
        }
    end
    snapshot, nameFact = sanitizeSnapshot(snapshot)
    local known = nameFact and nameFact.value ~= nil
    local identity = snapshot.identity or {}
    return {
        requestID = requestID,
        npcID = npcID,
        state = known and "known" or "unknown",
        canAskName = not known,
        displayName = known and tostring(nameFact.value) or "Unknown survivor",
        archetypeLabel = known and identity.archetypeLabel or nil,
        factionName = identity.factionName,
        portrait = snapshot.portrait,
        relationship = snapshot.relationship,
        snapshot = snapshot,
        characterUUID = context.characterUUID,
        accountKey = context.accountKey,
        bindingRevision = context.bindingRevision,
        knowledgeRevision = tonumber(snapshot.revision) or 0,
    }
end

function Commands.HandleBootstrap(player, args)
    args = type(args) == "table" and args or {}
    local context, reason = contextFor(player, "player_bootstrap")
    local payload
    if not context then
        payload = { requestID = args.requestID, state = "error", reason = reason }
    else
        local committed, commitReason = PNC.PersistenceCoordinator.Commit(
            "player_bootstrap"
        )
        if not committed then
            payload = { requestID = args.requestID, state = "error",
                reason = commitReason, context = context }
            Network.SendPlayerBootstrap(player, payload)
            return payload
        end
        local snapshots
        snapshots, reason = PNC.NPCKnowledge.BuildKnownSnapshotsForPlayer(player)
        if not snapshots then
            payload = { requestID = args.requestID, state = "error", reason = reason }
        else
            for index = 1, #snapshots do
                snapshots[index] = sanitizeSnapshot(snapshots[index])
            end
            local chunkCount = math.max(1, math.ceil(
                #snapshots / BOOTSTRAP_CHUNK_SIZE
            ))
            local knowledgeRevision = tonumber(PNC.NPCKnowledge.Registry
                and PNC.NPCKnowledge.Registry.revision) or 0
            for chunkIndex = 1, chunkCount do
                local chunk = {}
                local first = (chunkIndex - 1) * BOOTSTRAP_CHUNK_SIZE + 1
                local last = math.min(#snapshots,
                    chunkIndex * BOOTSTRAP_CHUNK_SIZE)
                for index = first, last do chunk[#chunk + 1] = snapshots[index] end
                payload = {
                    requestID = args.requestID,
                    state = chunkIndex == chunkCount and "known" or "loading",
                    context = context,
                    snapshots = chunk,
                    chunkIndex = chunkIndex,
                    chunkCount = chunkCount,
                    knowledgeRevision = knowledgeRevision,
                }
                Network.SendPlayerBootstrap(player, payload)
            end
            Commands.Diagnostics[context.characterUUID] = {
                accountKey = context.accountKey,
                characterUUID = context.characterUUID,
                bindingRevision = context.bindingRevision,
                bootstrapRevision = knowledgeRevision,
                knowledgeRevision = knowledgeRevision,
                migrationResult = PNC.PlayerCharacters.Registry.migration
                    and PNC.PlayerCharacters.Registry.migration.status,
                aliases = Core.DeepCopy(
                    PNC.PlayerCharacters.Registry.uuidAliases or {}
                ),
            }
            return payload
        end
    end
    Network.SendPlayerBootstrap(player, payload)
    return payload
end

function Commands.HandlePresentation(player, args)
    args = type(args) == "table" and args or {}
    local npcID = safeID(args.npcID)
    local payload = npcID and presentationFor(player, npcID, args.requestID)
        or { requestID = args.requestID, state = "error", reason = "invalid_npc_id" }
    Network.SendNPCPresentation(player, payload)
    return payload
end

local function introductionText(npcID)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcID)
    if not record then return nil end
    local identity = PNC.Identity and PNC.Identity.GetCharacterSummary
        and PNC.Identity.GetCharacterSummary(record) or {}
    local name = identity.displayName or record.name
    if not name then return nil end
    local faction = record.affiliation and PNC.Factions
        and PNC.Factions.GetPresentation
        and PNC.Factions.GetPresentation(record.affiliation.factionID) or nil
    if faction and faction.name then
        return "I'm " .. tostring(name) .. ". I'm with "
            .. tostring(faction.name) .. "."
    end
    return "I'm " .. tostring(name) .. "."
end

function Commands.HandleDisclosure(player, args)
    args = type(args) == "table" and args or {}
    local requestID = safeID(args.requestID)
    local npcID = safeID(args.npcID)
    local topicID = safeID(args.topicID)
    local context, reason = contextFor(player, "knowledge_disclosure")
    local payload
    if not requestID or not npcID or not topicID or not context then
        payload = {
            requestID = requestID, npcID = npcID, topicID = topicID,
            success = false, reason = reason or "invalid_disclosure_request",
        }
    else
        local byCharacter = Commands.Processed[context.characterUUID] or {}
        Commands.Processed[context.characterUUID] = byCharacter
        if byCharacter[requestID] then
            payload = Core.DeepCopy(byCharacter[requestID])
            payload.replayed = true
        else
            local disclosure
            local pendingByNPC = Commands.Uncommitted[context.characterUUID]
                or {}
            Commands.Uncommitted[context.characterUUID] = pendingByNPC
            if pendingByNPC[npcID]
                or PNC.NPCKnowledge.GetDescriptor(
                    context.characterUUID, npcID, "identity.name"
                )
            then
                disclosure = { topicID = topicID,
                    revealed = { "identity.name" }, failures = {} }
            else
                disclosure, reason = PNC.NPCKnowledge.DiscoverTopicForPlayer(
                    player, npcID, topicID, nil, "direct_disclosure", true
                )
            end
            local committed, commitReason = false, reason
            if disclosure then
                committed, commitReason = PNC.PersistenceCoordinator.Commit(
                    "knowledge_disclosure:" .. requestID
                )
            end
            if committed then
                pendingByNPC[npcID] = nil
                local presentation = presentationFor(player, npcID, requestID)
                payload = {
                    requestID = requestID, npcID = npcID, topicID = topicID,
                    success = true, reason = "committed",
                    responseText = introductionText(npcID),
                    revealedFacts = disclosure.revealed or {},
                    presentation = presentation,
                    bindingRevision = context.bindingRevision,
                    knowledgeRevision = presentation.knowledgeRevision,
                }
                byCharacter[requestID] = Core.DeepCopy(payload)
                Commands.Diagnostics[context.characterUUID] =
                    Commands.Diagnostics[context.characterUUID] or {}
                Commands.Diagnostics[context.characterUUID]
                    .disclosureCommitResult = "committed"
                Commands.Diagnostics[context.characterUUID]
                    .knowledgeRevision = presentation.knowledgeRevision
            else
                pendingByNPC[npcID] = true
                payload = {
                    requestID = requestID, npcID = npcID, topicID = topicID,
                    success = false, reason = commitReason or "commit_failed",
                    presentation = { npcID = npcID, state = "error",
                        reason = commitReason or "commit_failed" },
                }
                Commands.Diagnostics[context.characterUUID] =
                    Commands.Diagnostics[context.characterUUID] or {}
                Commands.Diagnostics[context.characterUUID]
                    .disclosureCommitResult = tostring(commitReason)
            end
        end
    end
    Network.SendKnowledgeDisclosure(player, payload)
    return payload
end

return Commands

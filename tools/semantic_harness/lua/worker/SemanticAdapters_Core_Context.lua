-- Conversation lease, identity, and player-context adapter setup.

local function configureContext(state)
    local context = state.context
    local SemanticAdapters = state.SemanticAdapters
    local Runtime = state.Runtime
    local Values = state.Values
    local number = state.number
    local playerData = state.playerData
    local npcData = state.npcData
    local runtime = state.runtime
    local player = state.player
    local conversationToken = state.conversationToken
    local sourceKind = state.sourceKind
    local productionPlayers = Runtime.productionPlayerCharactersService
    local productionGetEntityKey = productionPlayers
        and productionPlayers.GetEntityKey
    local productionGetRegistryRecord = productionPlayers
        and productionPlayers.GetRegistryRecord

    npcData.id = npcData.id or npcData.npcID
    npcData.runtime = type(npcData.runtime) == "table"
        and npcData.runtime or {}
    local productionRecord = sourceKind == "SAVE"
        and Runtime.hydratedNpcRecord or nil
    PNC = PNC or {}
    PNC.ConversationScene = PNC.ConversationScene or {}
    PNC.ConversationScene.LEASE_MS =
        tonumber(PNC.ConversationScene.LEASE_MS) or 3500
    local leaseDuration = PNC.ConversationScene.LEASE_MS
    local function ensureConversationLease(record)
        if type(record) ~= "table" then return end
        record.runtime = type(record.runtime) == "table"
            and record.runtime or {}
        if type(record.runtime.conversationLease) ~= "table" then
            record.runtime.conversationLease = {
                token = conversationToken,
                playerOnlineID = player and player.getOnlineID
                    and player:getOnlineID() or nil,
                playerUsername = player and player.getUsername
                    and player:getUsername() or nil,
                startedAt = tonumber(Runtime.now) or 0,
                expiresAt = (tonumber(Runtime.now) or 0) + leaseDuration,
                maximumDistance = 6,
                dangerRadius = 8,
            }
        end
    end
    ensureConversationLease(npcData)
    -- The conversation authority resolves SAVE actors through the isolated
    -- production registry. The lease is an engine/scene fixture, so attach
    -- the same worker-owned lease to that hydrated working record as well.
    ensureConversationLease(productionRecord)

    local function identityName(npc)
        return SemanticAdapters.identityName(context, npc)
    end

    -- Scenario fixtures use the compact forename/surname shape, while the
    -- production registry exposes the normalized identity record consumed by
    -- Knowledge providers. Normalize that fixture once at the existing
    -- adapter boundary so the worker exercises the real provider and
    -- player-scoped disclosure path instead of a harness-only name store.
    npcData.identity = type(npcData.identity) == "table"
        and npcData.identity or {}
    if tostring(npcData.identity.displayName or "") == "" then
        local normalizedName = identityName(npcData)
        if normalizedName ~= "" then
            npcData.identity.displayName = normalizedName
        end
    end
    local function rawRelationshipFor(npcID)
        return SemanticAdapters.identityRelationshipFor(context, npcID)
    end
    local function rawRelationshipSnapshotFor(npcID)
        return SemanticAdapters.identityRelationshipSnapshotFor(context, npcID)
    end

    PNC = PNC or {}
    PNC.Core = PNC.Core or {}
    PNC.Core.SemanticHarness = true
    PNC.Core.Now = function() return Runtime.now end
    PNC.Core.DeepCopy = function(value) return Values.productionCopy(value) end
    PNC.Const = PNC.Const or {}
    PNC.Const.MODULE = "ProjectHoomans"
    PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST = "SemanticIdentityRequest"
    PNC.Const.CMD_SEMANTIC_IDENTITY_RESULT = "SemanticIdentityResult"
    PNC.Network = PNC.Network or {}
    PNC.Network.ClientState = PNC.Network.ClientState or {}
    local semanticHubPresentation =
        PNC.Network.ClientState.semanticHubPresentation
    Values.clearTable(PNC.Network.ClientState)
    PNC.Network.ClientState.semanticHubPresentation =
        semanticHubPresentation or {}
    PNC.Network.ClientState.conversationRelationships = {}
    PNC.Network.ClientState.pendingSemanticIdentity = {}
    PNC.Network.ClientState.characterPayloads = {}
    PNC.Network.Internal = PNC.Network.Internal or {}
    PNC.Semantics = PNC.Semantics or {}
    PNC.Conversation = PNC.Conversation or {}
    PNC.Conversation.Registry = PNC.Conversation.Registry or {}
    PNC.Conversation.Audience = PNC.Conversation.Audience or {
        IsPlayerHostile = function() return false end,
    }
    PNC.Conversation.Relationship = PNC.Conversation.Relationship or {}
    PNC.Conversation.Relationship.ReceivePresentation = function()
        return true
    end
    PNC.ConversationScene = PNC.ConversationScene or {}

    local function validateHarnessLease(record, leasePlayer, token)
        local lease = record and record.runtime
            and record.runtime.conversationLease or nil
        if type(lease) ~= "table" or tostring(lease.token or "") == "" then
            return false, "lease_missing"
        end
        if tostring(lease.token) ~= tostring(token or "") then
            return false, "invalid_lease"
        end
        local ownsLease = false
        if lease.playerOnlineID ~= nil
            and leasePlayer and leasePlayer.getOnlineID
            and tostring(lease.playerOnlineID)
                == tostring(leasePlayer:getOnlineID())
        then
            ownsLease = true
        end
        if not ownsLease and lease.playerUsername ~= nil
            and leasePlayer and leasePlayer.getUsername
            and tostring(lease.playerUsername)
                == tostring(leasePlayer:getUsername())
        then
            ownsLease = true
        end
        if not ownsLease then
            return false, "conversation_player_mismatch"
        end
        if (tonumber(Runtime.now) or 0)
            >= (tonumber(lease.expiresAt) or 0)
        then
            return false, "conversation_expired"
        end
        return true, lease
    end

    PNC.ConversationScene.ValidateConversationLease = function(
        record, leasePlayer, token
    )
        return validateHarnessLease(record, leasePlayer, token)
    end
    PNC.ConversationScene.Begin = function(
        record, _, leasePlayer, token
    )
        local valid, leaseOrReason = validateHarnessLease(
            record, leasePlayer, token
        )
        if not valid then return false, leaseOrReason end
        leaseOrReason.expiresAt = (tonumber(Runtime.now) or 0)
            + leaseDuration
        return true, leaseOrReason
    end
    PNC.Registry = PNC.Registry or {}
    if sourceKind == "SAVE"
        and type(Runtime.hydratedNpcRecord) == "table"
    then
        -- The production relationship/knowledge services resolve through the
        -- isolated hydrated record, never through the Python scenario table.
        PNC.Registry.Get = function(id)
            return tostring(id) == tostring(Runtime.hydratedNpcRecord.id)
                and Runtime.hydratedNpcRecord or nil
        end
    else
        PNC.Registry.Get = function(id)
            return tostring(id) == tostring(npcData.npcID) and npcData or nil
        end
    end
    PNC.Registry.GetLiveZombie = function(id)
        return tostring(id) == tostring(npcData.id) and {} or nil
    end
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerCharacters.GetEntityKey = function(player, identityContext)
        if sourceKind == "SAVE"
            and type(productionGetEntityKey) == "function"
        then
            local key, reason = productionGetEntityKey(
                player, identityContext
            )
            if key then return key, reason end
        end
        return sourceKind == "SAVE" and playerData.entityKey
            or playerData.entityKey
            or ("player:harness:" .. tostring(playerData.characterUUID)),
            "harness_resolved"
    end
    PNC.PlayerCharacters.GetRegistryRecord = function(characterUUID)
        if sourceKind == "SAVE"
            and type(productionGetRegistryRecord) == "function"
        then
            local record = productionGetRegistryRecord(characterUUID)
            if type(record) == "table" then return record end
        end
        if tostring(characterUUID) ~= tostring(playerData.characterUUID) then
            return nil
        end
        return {
            uuid = playerData.characterUUID,
            accountKey = playerData.accountKey or "harness",
            accountIdentity = playerData.accountIdentity
                or playerData.accountKey or "harness",
            displayName = playerData.displayName,
            forename = playerData.forename,
            surname = playerData.surname,
            socialProfile = Values.copy(playerData.socialProfile),
        }
    end
    PNC.PlayerCharacters.Registry = PNC.PlayerCharacters.Registry or {
        uuidAliases = {},
    }
    PNC.PlayerCharacters.ApplyConductRecord = function(_, conduct)
        Runtime.playerConduct = Values.copy(conduct)
        return true, "updated"
    end
    PNC.PlayerContext = PNC.PlayerContext or {}
    PNC.PlayerContext.Resolve = function()
        return {
            characterUUID = playerData.characterUUID,
            entityKey = playerData.entityKey
                or ("player:harness:" .. tostring(playerData.characterUUID)),
        }, "harness_resolved"
    end
    PNC.PlayerContext.Peek = PNC.PlayerContext.Resolve
    PNC.Relationships = PNC.Relationships or {}

    state.identityName = identityName
    state.rawRelationshipFor = rawRelationshipFor
    state.rawRelationshipSnapshotFor = rawRelationshipSnapshotFor
    state.leaseDuration = leaseDuration
end

return configureContext

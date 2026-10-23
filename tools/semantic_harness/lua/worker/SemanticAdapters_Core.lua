local Provider = {}

function Provider.configure(context, SemanticAdapters)
    local Runtime = context.Runtime
    local Values = context.Values
    local number = Values.number
    local playerData = context.playerData
    local npcData = context.npcData
    local conversationData = context.scenario.conversation or {}
    local runtime = context.runtime
    local player = context.player
    local conversationToken = tostring(conversationData.token or "")

    npcData.id = npcData.id or npcData.npcID
    npcData.runtime = type(npcData.runtime) == "table"
        and npcData.runtime or {}
    PNC = PNC or {}
    PNC.ConversationScene = PNC.ConversationScene or {}
    PNC.ConversationScene.LEASE_MS =
        tonumber(PNC.ConversationScene.LEASE_MS) or 3500
    local leaseDuration = PNC.ConversationScene.LEASE_MS
    if type(npcData.runtime.conversationLease) ~= "table" then
        npcData.runtime.conversationLease = {
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
    local function relationshipFor(npcID)
        return SemanticAdapters.relationshipFor(context, npcID)
    end
    local function relationshipSnapshotFor(npcID)
        return SemanticAdapters.relationshipSnapshotFor(context, npcID)
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
    Values.clearTable(PNC.Network.ClientState)
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
    PNC.Registry.Get = function(id)
        return tostring(id) == tostring(npcData.npcID) and npcData or nil
    end
    PNC.Registry.GetLiveZombie = function(id)
        return tostring(id) == tostring(npcData.id) and {} or nil
    end
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerCharacters.GetEntityKey = function()
        return "player:harness:" .. tostring(playerData.characterUUID),
            "harness_resolved"
    end
    PNC.PlayerCharacters.GetRegistryRecord = function(characterUUID)
        if tostring(characterUUID) ~= tostring(playerData.characterUUID) then
            return nil
        end
        return {
            uuid = playerData.characterUUID,
            accountKey = "harness",
            accountIdentity = "harness",
            displayName = playerData.displayName,
            forename = playerData.forename,
            surname = playerData.surname,
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
            entityKey = "player:" .. tostring(playerData.characterUUID),
        }, "harness_resolved"
    end
    PNC.PlayerContext.Peek = PNC.PlayerContext.Resolve
    PNC.Relationships = PNC.Relationships or {}
    PNC.Relationships.Get = function(npcID)
        return relationshipSnapshotFor(npcID)
    end
    PNC.Relationships.ApplyConversationEffect = function(
        npcID, _, effect, effectContext
    )
        local relationship = relationshipFor(npcID)
        relationship.approval = number(relationship.approval, 0)
            + number(effect.approval, 0)
        relationship.respect = number(relationship.respect, 0)
            + number(effect.respect, 0)
        relationship.familiarity = number(relationship.familiarity, 0)
            + number(effect.familiarity, 0)
        relationship.revision = number(relationship.revision, 0) + 1
        if effect.tags and effect.tags.untrustworthy then
            relationship.identityTrust = "untrustworthy"
        elseif effect.tags and effect.tags.truthful then
            relationship.identityTrust = "trusted"
        end
        local clientState = PNC.Network and PNC.Network.ClientState
        if clientState then
            clientState.conversationRelationships =
                clientState.conversationRelationships or {}
            clientState.conversationRelationships[tostring(npcID)] =
                Values.copy(relationship)
        end
        return true, "applied", {
            eventID = effectContext and effectContext.eventID,
            memoryID = effectContext and effectContext.eventID,
            memoryType = effect.memoryType,
        }
    end
    local function proposalEvaluation(npcID, relationshipOverride)
        local relationship = relationshipOverride or relationshipFor(npcID)
        local npcProfile = context.npcPersonality or {}
        local playerProfile = context.playerSocialProfile or {}
        local npcGender = npcData.gender
            or npcData.identity and npcData.identity.gender
        local playerGender = playerData.gender
        local compatible = false
        local available = npcData.alive ~= false
            and npcData.available ~= false
            and npcData.healthState ~= "dead"
            and playerData.alive ~= false
        local targetKey = "player:harness:"
            .. tostring(playerData.characterUUID or "")
        if PNC.SocialProfileMath
            and type(PNC.SocialProfileMath.AreMutuallyOrientationCompatible)
                == "function"
        then
            compatible = PNC.SocialProfileMath
                .AreMutuallyOrientationCompatible(
                    npcProfile,
                    npcGender == "female",
                    playerProfile,
                    playerGender == "female"
                ) == true
        end
        local evaluation = PNC.RelationshipProposalPolicy
            .EvaluateEligibility(
                relationship,
                relationship.bond or { class = "none" },
                compatible,
                available,
                tonumber(Runtime.now) or 0
            )
        evaluation.action = PNC.RelationshipProposalPolicy.ActionID()
        evaluation.targetKey = targetKey
        evaluation.relationship = relationship
        evaluation.bond = Values.copy(relationship.bond)
        evaluation.npcProfile = Values.copy(npcProfile)
        evaluation.playerProfile = Values.copy(playerProfile)
        evaluation.npcGender = npcGender
        evaluation.playerGender = playerGender
        return evaluation
    end
    PNC.Relationships.EvaluateProposal = proposalEvaluation
    PNC.Relationships.Preview = function(npcID, values)
        local relationship = Values.copy(relationshipFor(npcID))
        values = type(values) == "table" and values or {}
        for _, key in ipairs({ "approval", "respect", "familiarity" }) do
            if values[key] ~= nil then
                relationship[key] = number(values[key], relationship[key] or 0)
            end
        end
        if PNC.RelationshipStates
            and type(PNC.RelationshipStates.ExplainState) == "function"
        then
            local explanation = PNC.RelationshipStates.ExplainState(relationship)
            relationship.state = explanation.state
            relationship.relationshipState = explanation.state
        end
        local evaluation = proposalEvaluation(npcID, relationship)
        local explanation = PNC.RelationshipStates
            and type(PNC.RelationshipStates.ExplainState) == "function"
            and PNC.RelationshipStates.ExplainState(relationship)
            or { state = relationship.state or "unknown", reason = "unavailable" }
        evaluation.relationship = Values.copy(relationship)
        evaluation.standing = explanation.state
        evaluation.standingReason = explanation.reason
        evaluation.preview = true
        return evaluation
    end
    PNC.Relationships.Propose = function(npcID)
        local evaluation = proposalEvaluation(npcID)
        local relationship = evaluation.relationship
        local acceptance
        local accepted
        local eventType
        local eventID
        if not evaluation.eligible then
            evaluation.accepted = false
            evaluation.result = "blocked"
            evaluation.serverAuthoritative = true
            return false, evaluation.reason, evaluation
        end
        acceptance = PNC.RelationshipProposalPolicy.EvaluateAcceptance(
            npcData.identitySeed or npcData.npcID,
            evaluation.targetKey .. ":" .. tostring(relationship.revision)
                .. ":" .. PNC.RelationshipProposalPolicy.ActionID(),
            relationship,
            context.npcPersonality
        )
        accepted = acceptance.accepted == true
        eventType = accepted
            and "relationship_proposal_accepted"
            or "relationship_proposal_rejected"
        eventID = "social:" .. eventType .. ":" .. tostring(npcID)
            .. ":" .. tostring(relationship.revision + 1)
        relationship.memories = relationship.memories or {}
        relationship.memories[#relationship.memories + 1] = {
            id = eventID,
            type = eventType,
            aboutKey = evaluation.targetKey,
            createdAt = tonumber(Runtime.now) or 0,
            permanent = accepted,
            strength = accepted and 1 or 0.5,
        }
        while #relationship.memories > 20 do
            table.remove(relationship.memories, 1)
        end
        if accepted then
            relationship.bond = {
                schemaVersion = 1,
                class = "lover",
                kind = nil,
                establishedAt = tonumber(Runtime.now) or 0,
                source = "relationship_proposal",
            }
        else
            relationship.cooldowns = relationship.cooldowns or {}
            relationship.cooldowns[
                PNC.RelationshipProposalPolicy.CooldownType()
            ] = (tonumber(Runtime.now) or 0)
                + PNC.RelationshipProposalPolicy.CooldownHours(
                    context.npcPersonality.romanceStyle
                )
        end
        relationship.revision = (tonumber(relationship.revision) or 0) + 1
        npcData.relationship = Values.copy(relationship)
        Runtime.socialEvents = Runtime.socialEvents or {}
        Runtime.socialEvents[#Runtime.socialEvents + 1] = {
            type = eventType,
            eventID = eventID,
            action = PNC.RelationshipProposalPolicy.ActionID(),
            at = tonumber(Runtime.now) or 0,
        }
        while #Runtime.socialEvents > 20 do
            table.remove(Runtime.socialEvents, 1)
        end
        evaluation.acceptance = acceptance
        evaluation.accepted = accepted
        evaluation.result = accepted and "accepted" or "rejected"
        evaluation.serverAuthoritative = true
        evaluation.relationship = Values.copy(relationship)
        evaluation.bond = Values.copy(relationship.bond)
        evaluation.cooldownUntil = relationship.cooldowns
            and relationship.cooldowns[
                PNC.RelationshipProposalPolicy.CooldownType()
            ] or nil
        return true, evaluation.result, evaluation
    end
    PNC.RelationshipPresentation = PNC.RelationshipPresentation or {}
    PNC.RelationshipPresentation.Summarize = function(value)
        return Values.copy(value)
    end

    PNC.NPCKnowledgeAPI = PNC.NPCKnowledgeAPI or {}
    if type(PNC.NPCKnowledgeAPI.DiscloseForPlayer) ~= "function" then
    PNC.NPCKnowledgeAPI.DiscloseForPlayer = function(_, options)
        npcData.identityState = "known"
        PNC.Network.ClientState.npcPresentations =
            PNC.Network.ClientState.npcPresentations or {}
        PNC.Network.ClientState.npcPresentations[npcData.npcID] = {
            state = "known",
            displayName = identityName(npcData),
        }
        if Runtime.view and Runtime.view.spec
            and Runtime.view.spec.context
        then
            Runtime.view.spec.context.identityState = "known"
        end
        Runtime.disclosures = number(Runtime.disclosures, 0) + 1
        Runtime.knowledge = options
        return { accepted = true, revealed = { "identity.name" } }
    end
    end
    PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}
    PNC.PlayerKnowledgeCommands.Internal =
        PNC.PlayerKnowledgeCommands.Internal or {}
    PNC.PlayerKnowledgeCommands.Internal.SafeID = function(value)
        value = tostring(value or "")
        return value ~= "" and value or nil
    end
    PNC.PlayerKnowledgeCommands.Internal.ContextFor = function()
        return {
            characterUUID = playerData.characterUUID,
            entityKey = "player:" .. tostring(playerData.characterUUID),
        }
    end
    PNC.PlayerKnowledgeCommands.Internal.IntroductionText = function()
        return "I'm " .. identityName(npcData) .. "."
    end

    return {
        context = context,
        Runtime = Runtime,
        Values = Values,
        number = number,
        playerData = playerData,
        npcData = npcData,
        runtime = runtime,
        player = player,
        leaseDuration = leaseDuration,
        conversationToken = conversationToken,
        identityName = identityName,
        relationshipFor = relationshipFor,
        relationshipSnapshotFor = relationshipSnapshotFor,
    }
end

return Provider

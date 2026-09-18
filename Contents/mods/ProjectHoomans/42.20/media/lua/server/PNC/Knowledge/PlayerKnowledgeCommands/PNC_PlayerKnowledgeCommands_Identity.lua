-- Server-authoritative semantic identity exchange.
-- The client may report what the player said, but only this boundary can
-- compare it with the canonical player identity and mutate reputation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}

if not (PNC.Semantics and PNC.Semantics.IdentityExchange) then
    require "PNC/Semantics/PNC_SemanticIdentityExchange"
end

local Commands = PNC.PlayerKnowledgeCommands
local H = Commands.Internal
local Core = PNC.Core
local Network = PNC.Network
local Identity = PNC.Semantics.IdentityExchange
local Relationships = PNC.Relationships
local Presentation = PNC.RelationshipPresentation

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    if time and time.getWorldAgeHours then
        return math.max(0, tonumber(time:getWorldAgeHours()) or 0)
    end
    return 0
end

local function clean(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function playerName(player, context)
    local record = context and context.characterUUID
        and PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
        and PNC.PlayerCharacters.GetRegistryRecord(context.characterUUID)
        or nil
    local name = record and (record.displayName
        or record.identity and record.identity.displayName)
    if record and (record.forename or record.surname) then
        local forename = clean(record.forename)
        local surname = clean(record.surname)
        local composed = forename
        if surname ~= "" then
            composed = composed .. (composed ~= "" and " " or "") .. surname
        end
        if composed ~= "" then name = composed end
    end
    if not name and player and player.getDescriptor then
        local descriptor = player:getDescriptor()
        local forename = descriptor and descriptor.getForename
            and clean(descriptor:getForename()) or ""
        local surname = descriptor and descriptor.getSurname
            and clean(descriptor:getSurname()) or ""
        name = forename
        if surname ~= "" then
            name = name .. (name ~= "" and " " or "") .. surname
        end
    end
    if not name and player and player.getDisplayName then
        name = player:getDisplayName()
    end
    return clean(name)
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

local function npcName(record)
    local identity = record and record.identity
    return clean(identity and identity.displayName
        or record and (record.displayName or record.name))
end

local function localized(key, fallback, ...)
    local translation = PNC.Translation
    if translation and type(translation.TrFormat) == "function" then
        return translation.TrFormat(key, fallback, ...)
    end
    return fallback
end

local function identityResponse(record, truthful, introduction)
    if truthful then
        local name = npcName(record)
        if name == "" and introduction then
            local introduced = clean(introduction)
            local extracted = string.match(introduced, "^[Ii]'m%s+(.+)%.$")
            name = clean(extracted or "")
        end
        if name ~= "" then
            local fallback = "Nice to meet you. I'm " .. name .. "."
            return localized(
                "UI_PNC_Conversation_ToolReply_AskNameNamed_1",
                fallback,
                name
            ), "UI_PNC_Conversation_ToolReply_AskNameNamed_1", { name }
        end
        return localized(
            "UI_PNC_Conversation_ToolReply_AskNameUnnamed_1",
            "Nice to meet you."
        ), "UI_PNC_Conversation_ToolReply_AskNameUnnamed_1", nil
    end
    local key = "UI_PNC_Conversation_Identity_FalseName"
    return localized(key, "That isn't your exact name. Don't lie to me."),
        key, nil
end

local function sendRejected(player, args, reason)
    local payload = {
        requestID = tostring(args and args.requestID or ""),
        npcID = tostring(args and args.npcID or ""),
        kind = tostring(args and args.kind or ""),
        accepted = false,
        reason = tostring(reason or "identity_exchange_rejected"),
    }
    if Network and Network.SendSemanticIdentityResult then
        Network.SendSemanticIdentityResult(player, payload)
    end
    return false, payload.reason
end

function Commands.HandleSemanticIdentity(player, args)
    args = type(args) == "table" and args or {}
    local requestID = H.SafeID(args.requestID)
    local npcID = H.SafeID(args.npcID)
    local kind = tostring(args.kind or "")
    local claimedName = clean(args.claimedName)
    local context
    local record
    local targetKey
    local reason
    local lease
    if not requestID or not npcID then
        return sendRejected(player, args, "identity_request_invalid")
    end
    if kind ~= Identity.EVENT_CLAIM and kind ~= Identity.EVENT_EVASION then
        return sendRejected(player, args, "identity_event_invalid")
    end
    if kind == Identity.EVENT_CLAIM and claimedName == "" then
        return sendRejected(player, args, "identity_claim_missing")
    end

    record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcID)
    if not record then return sendRejected(player, args, "npc_not_found") end
    local authority = PNC.Conversation
        and PNC.Conversation.Authority
    local validator = authority and authority.Internal
        and authority.Internal.ValidateLease
    if type(validator) == "function" then
        local valid
        valid, reason, lease = validator(
            player, record, args.conversationToken or args.token
        )
        if valid ~= true then return sendRejected(player, args, reason) end
    end

    context, reason = H.ContextFor(player, "semantic_identity")
    if not context then return sendRejected(player, args, reason) end
    targetKey = context.playerEntityKey
    if not targetKey then
        return sendRejected(player, args, "player_identity_unavailable")
    end

    local at = worldAgeHours()
    local before = Relationships.Get(npcID, targetKey)
    local truthful = nil
    local trustLabel = nil
    local effect
    if kind == Identity.EVENT_CLAIM then
        local actualName = playerName(player, context)
        if actualName == "" then
            return sendRejected(player, args, "player_name_unavailable")
        end
        truthful = Identity.ClaimMatchesName
            and Identity.ClaimMatchesName(claimedName, actualName)
            or Identity.NamesEqual(claimedName, actualName)
        if truthful then
            effect = {
                memoryType = "identity_introduction",
                interactionType = "identity_introduction",
                approval = 1,
                respect = 2,
                familiarity = 6,
                decayPerDay = 0.02,
                tags = { identity = true, truthful = true },
            }
        else
            trustLabel = Identity.TRUST_UNTRUSTWORTHY
            effect = {
                memoryType = "identity_deception",
                interactionType = "identity_deception",
                approval = -4,
                respect = -6,
                familiarity = 1,
                decayPerDay = 0.01,
                tags = {
                    identity = true,
                    deception = true,
                    untrustworthy = true,
                },
            }
        end
    else
        trustLabel = Identity.TRUST_UNTRUSTWORTHY
        effect = {
            memoryType = "identity_evasion",
            interactionType = "identity_evasion",
            approval = -2,
            respect = -3,
            familiarity = 0,
            decayPerDay = 0.01,
            tags = {
                identity = true,
                evasion = true,
                untrustworthy = true,
            },
        }
    end

    local eventID = "semantic_identity:" .. requestID
    local applied, applyReason, details = Relationships.ApplyConversationEffect(
        npcID,
        targetKey,
        effect,
        {
            blockID = "semantic_identity",
            choiceID = kind,
            outcomeID = requestID,
            eventID = eventID,
            interactionType = effect.interactionType,
            worldAgeHours = at,
            sourceSystem = "semantic_identity",
            interaction = {
                kind = kind,
                source = "semantic_dialogue",
                interactionType = effect.interactionType,
                claimedName = kind == Identity.EVENT_CLAIM
                    and claimedName or nil,
                truthful = truthful,
                applied = true,
                eventID = eventID,
                at = at,
                worldAgeHours = at,
            },
        }
    )
    if applied ~= true then
        return sendRejected(player, args, applyReason or "relationship_rejected")
    end

    local after = Relationships.Get(npcID, targetKey) or {}
    local summary = Presentation and Presentation.Summarize
        and Presentation.Summarize(after, true) or after
    summary.npcID = npcID
    summary.identityTrust = trustLabel
    local delta = relationshipDelta(before, after)
    local responseText
    local responseKey
    local responseArgs
    if kind == Identity.EVENT_CLAIM and truthful then
        if PNC.NPCKnowledgeAPI
            and PNC.NPCKnowledgeAPI.DiscloseForPlayer
        then
            PNC.NPCKnowledgeAPI.DiscloseForPlayer(player, {
                npcID = npcID,
                topicID = "identity_name",
                requestID = requestID .. ":identity_name",
                conversationToken = args.conversationToken or args.token,
                origin = "semantic_identity_claim",
            })
        end
        local introduction = Commands.Internal.IntroductionText
            and Commands.Internal.IntroductionText(npcID)
        responseText, responseKey, responseArgs = identityResponse(
            record, true, introduction
        )
    elseif kind == Identity.EVENT_CLAIM then
        responseText, responseKey, responseArgs = identityResponse(
            record, false
        )
    end

    local payload = {
        requestID = requestID,
        npcID = npcID,
        kind = kind,
        accepted = true,
        truthful = truthful,
        trustLabel = trustLabel,
        responseText = responseText,
        responseKey = responseKey,
        responseArgs = responseArgs,
        relationship = summary,
        relationshipBefore = before,
        relationshipAfter = summary,
        relationshipDelta = delta,
        relationshipRevision = summary.revision,
        eventID = details and details.eventID or eventID,
        memoryID = details and details.memoryID,
        memoryType = details and details.memoryType or effect.memoryType,
        leaseToken = lease and lease.token,
    }
    if Network and Network.SendSemanticIdentityResult then
        Network.SendSemanticIdentityResult(player, payload)
    end
    if Network and Network.SendConversationRelationship then
        Network.SendConversationRelationship(player, summary,
            "semantic_identity", {
                source = "semantic_identity",
                eventID = payload.eventID,
                relationshipBefore = before,
                relationshipAfter = summary,
                relationshipDelta = delta,
            })
    end
    return true, payload
end

return Commands

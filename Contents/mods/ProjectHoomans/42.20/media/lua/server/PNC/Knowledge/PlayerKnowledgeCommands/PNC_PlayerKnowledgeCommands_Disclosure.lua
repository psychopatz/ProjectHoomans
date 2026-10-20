if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Commands = PNC.PlayerKnowledgeCommands
local H = Commands.Internal
local Network = PNC.Network
local Core = PNC.Core

function H.IntroductionText(npcID)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcID)
    if not record then return nil end
    local identity = PNC.Identity and PNC.Identity.GetCharacterSummary
        and PNC.Identity.GetCharacterSummary(record) or {}
    local name = identity.displayName
    if not name then return nil end
    return "I'm " .. tostring(name) .. "."
end

function H.BackstoryDisclosureText(npcID, topicID)
    local memory = PNC.Conversation and PNC.Conversation.Memory or nil
    local kind = PNC.NPCKnowledge
        and PNC.NPCKnowledge.BackstoryKindForTopic
        and PNC.NPCKnowledge.BackstoryKindForTopic(topicID) or nil
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not memory or not kind or not record
        or type(memory.GetBackstory) ~= "function"
    then return nil end
    local fact = memory.GetBackstory(record, kind)
    if not fact then return nil end
    if kind == "date_of_birth" then
        return string.format("%04d-%02d-%02d",
            tonumber(fact.year) or 0,
            tonumber(fact.month) or 0,
            tonumber(fact.day) or 0)
    end
    local content = memory.GetBackstoryText
        and memory.GetBackstoryText(fact, "EN") or fact.value
    if memory.RenderText then content = memory.RenderText(content, fact) end
    return type(content) == "string" and content ~= "" and content or nil
end

function H.BackstoryRefusalText(reason)
    if reason == "insufficient_familiarity" then
        return "I don't know you well enough to talk about that."
    end
    if reason == "not_disclosable" then
        return "I'd rather keep that private."
    end
    return "I'm not ready to talk about that yet."
end

function Commands.HandleDisclosure(player, args)
    args = type(args) == "table" and args or {}
    local requestID = H.SafeID(args.requestID)
    local npcID = H.SafeID(args.npcID)
    local topicID = H.SafeID(args.topicID)
    local preferenceItemType = H.SafeID(args.preferenceItemType)
    local context, reason = H.ContextFor(player, "knowledge_disclosure")
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
            if pendingByNPC[npcID] then
                if PNC.NPCKnowledgeAPI
                    and PNC.NPCKnowledgeAPI.CommitPendingForPlayer
                then
                    local result
                    result, reason = PNC.NPCKnowledgeAPI.CommitPendingForPlayer(
                        player,
                        {
                            npcID = npcID,
                            topicID = topicID,
                            requestID = requestID,
                            conversationToken = args.conversationToken
                                or args.token,
                            origin = args.origin or "conversation",
                            preferenceItemType = preferenceItemType,
                        }
                    )
                    if result then disclosure = result end
                else
                    reason = "knowledge_commit_pending"
                end
            else
                if PNC.NPCKnowledgeAPI
                    and PNC.NPCKnowledgeAPI.DiscloseForPlayer
                then
                    local result
                    result, reason = PNC.NPCKnowledgeAPI.DiscloseForPlayer(
                        player,
                        {
                            npcID = npcID,
                            topicID = topicID,
                            requestID = requestID,
                            conversationToken = args.conversationToken
                                or args.token,
                            origin = args.origin or "conversation",
                            preferenceItemType = preferenceItemType,
                        }
                    )
                    if result then
                        disclosure = result
                    end
                else
                    if topicID == "identity_name" then
                        reason = "identity_knowledge_api_unavailable"
                    else
                        disclosure, reason =
                            PNC.NPCKnowledge.DiscoverTopicForPlayer(
                                player,
                                npcID,
                                topicID,
                                nil,
                                "direct_disclosure",
                                true
                            )
                    end
                end
            end
            local committed, commitReason = disclosure ~= nil, reason
            if committed then
                pendingByNPC[npcID] = nil
                local presentation = H.PresentationFor(player, npcID, requestID)
                payload = {
                    requestID = requestID, npcID = npcID, topicID = topicID,
                    success = true, reason = "committed",
                    responseText = topicID == "identity_name"
                        and H.IntroductionText(npcID)
                        or string.sub(topicID, 1, 10) == "backstory."
                        and H.BackstoryDisclosureText(npcID, topicID) or nil,
                    -- The snapshot is already filtered by the authoritative
                    -- API for this player character. Deliver it with the
                    -- result so the client can update its private dossier
                    -- without projecting NPC truth locally.
                    snapshot = disclosure.snapshot,
                    giftPreference = disclosure.giftPreference,
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
                local commitFailure = commitReason == "disk_failed"
                    or commitReason == "knowledge_save_failed"
                    or commitReason == "persistence_unavailable"
                if commitFailure then pendingByNPC[npcID] = true end
                payload = {
                    requestID = requestID, npcID = npcID, topicID = topicID,
                    success = false, reason = commitReason or "commit_failed",
                    responseText = string.sub(topicID, 1, 10) == "backstory."
                        and H.BackstoryRefusalText(commitReason) or nil,
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

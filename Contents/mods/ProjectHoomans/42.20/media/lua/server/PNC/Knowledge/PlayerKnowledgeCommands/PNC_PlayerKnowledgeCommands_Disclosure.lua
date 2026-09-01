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
    local name = identity.displayName or record.name
    if not name then return nil end
    return "I'm " .. tostring(name) .. "."
end

function Commands.HandleDisclosure(player, args)
    args = type(args) == "table" and args or {}
    local requestID = H.SafeID(args.requestID)
    local npcID = H.SafeID(args.npcID)
    local topicID = H.SafeID(args.topicID)
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
                        }
                    )
                    if result then
                        disclosure = result
                    end
                else
                    disclosure, reason = PNC.NPCKnowledge.DiscoverTopicForPlayer(
                        player, npcID, topicID, nil, "direct_disclosure", true
                    )
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
                        and H.IntroductionText(npcID) or nil,
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

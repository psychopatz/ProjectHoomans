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
                local presentation = H.PresentationFor(player, npcID, requestID)
                payload = {
                    requestID = requestID, npcID = npcID, topicID = topicID,
                    success = true, reason = "committed",
                    responseText = H.IntroductionText(npcID),
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

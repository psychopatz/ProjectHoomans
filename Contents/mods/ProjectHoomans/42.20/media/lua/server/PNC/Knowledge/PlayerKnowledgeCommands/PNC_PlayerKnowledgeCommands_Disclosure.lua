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

function H.NicknameText(npcID)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcID)
    local identity = record and record.identity or nil
    local nickname = identity and identity.nickname or nil
    if (not nickname or tostring(nickname) == "")
        and PNC.IdentityNames
        and type(PNC.IdentityNames.ResolveNickname) == "function"
    then
        local survivor = identity and identity.survivor or {}
        local isFemale = identity and identity.isFemale
        if isFemale == nil and record then isFemale = record.isFemale end
        nickname = PNC.IdentityNames.ResolveNickname(
            survivor and survivor.forename,
            identity and identity.seed or record and record.identitySeed,
            {
                isFemale = isFemale,
                version = PNC.IdentityNames.NICKNAME_GENERATOR_VERSION,
            }
        )
    end
    nickname = tostring(nickname or "")
    return nickname ~= "" and "I'm " .. nickname .. "." or nil
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

function H.FactionDisclosureText(disclosure)
    local snapshot = type(disclosure) == "table" and disclosure.snapshot or nil
    local fact = snapshot and H.FactFromSnapshot
        and H.FactFromSnapshot(snapshot, "faction.identity") or nil
    local name = fact and tostring(fact.value or "")
        or (snapshot and snapshot.identity
            and tostring(snapshot.identity.factionName or ""))
        or ""
    if name ~= "" then
        return "I'm with " .. name .. "."
    end
    return "I don't belong to any group I can name."
end

function H.FactionRefusalText(reason)
    if reason == "insufficient_familiarity" then
        return "We haven't known each other long enough for me to get into who I'm with."
    end
    if reason == "not_disclosable" then
        return "I'd rather not say who I'm with."
    end
    if reason == "truth_unavailable" then
        return "I don't belong to any group I can name."
    end
    return "I don't share who I'm with yet."
end

function H.IdentityFacetDisclosureText(topicID, disclosure)
    local snapshot = type(disclosure) == "table" and disclosure.snapshot or nil
    local id = snapshot and type(snapshot.identity) == "table"
        and snapshot.identity or {}
    if topicID == "identity_nickname" then
        local fact = snapshot and H.FactFromSnapshot
            and H.FactFromSnapshot(snapshot, "identity.nickname") or nil
        local nick = fact and tostring(fact.value or "")
            or tostring(id.nickname or "")
        if nick ~= "" then
            return "Most people call me " .. nick .. "."
        end
        return "I don't really use a nickname."
    end
    if topicID == "identity_full_name" then
        local surFact = snapshot and H.FactFromSnapshot
            and H.FactFromSnapshot(snapshot, "identity.surname") or nil
        local surname = surFact and tostring(surFact.value or "")
            or tostring(id.surname or "")
        if surname ~= "" then
            return "My surname is " .. surname .. "."
        end
        local fullFact = snapshot and H.FactFromSnapshot
            and H.FactFromSnapshot(snapshot, "identity.full_name") or nil
        local fullName = fullFact and tostring(fullFact.value or "")
            or tostring(id.displayName or "")
        if fullName ~= "" then
            return "My full name is " .. fullName .. "."
        end
        return "I don't have much more to add to my name."
    end
    return nil
end

function H.IdentityFacetRefusalText(topicID, reason)
    if reason == "identity_claim_required" then
        return "Who's asking? Tell me your name first."
    end
    if topicID == "identity_nickname" then
        if reason == "truth_unavailable" then
            return "I don't really use a nickname."
        end
        return "I don't really go by a nickname."
    end
    if topicID == "identity_full_name" then
        if reason == "insufficient_familiarity" then
            return "Let's stick to first names until we know each other a bit better."
        end
        return "I'd rather not share my last name right now."
    end
    return nil
end

function Commands.HandleDisclosure(player, args)
    args = type(args) == "table" and args or {}
    local requestID = H.SafeID(args.requestID)
    local npcID = H.SafeID(args.npcID)
    local topicID = H.SafeID(args.topicID)
    local preferenceItemType = H.SafeID(args.preferenceItemType)
    -- Presentation metadata only: authoritative Knowledge still decides
    -- disclosure and returns the player-filtered snapshot.
    local responsePoolID = H.SafeID(args.responsePoolID)
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
                    responsePoolID = responsePoolID,
                    responseText = topicID == "identity_name"
                        and H.IntroductionText(npcID)
                        or topicID == "faction"
                        and H.FactionDisclosureText(disclosure)
                        or (topicID == "identity_nickname"
                            or topicID == "identity_full_name")
                        and H.IdentityFacetDisclosureText(topicID, disclosure)
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
                    responsePoolID = responsePoolID,
                    responseText = topicID == "faction"
                        and H.FactionRefusalText(commitReason)
                        or (topicID == "identity_nickname"
                            or topicID == "identity_full_name")
                        and H.IdentityFacetRefusalText(topicID, commitReason)
                        or string.sub(topicID, 1, 10) == "backstory."
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

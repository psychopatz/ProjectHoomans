-- Client-side social greeting presentation provider.
local Presentation = PNC.CompanionCommandPresentation
local Internal = Presentation.Internal
local Registry = Internal.Registry
local targetName = Internal.TargetName

function Presentation.HandleSocialGreeting(greeting)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local eventID = tostring(greeting and greeting.eventID or "")
    local npcID = tostring(greeting and greeting.npcID or "")
    local player
    local body
    local snapshot
    local text
    local diary
    local memory
    local resolvedText
    local context
    local socialFlavor
    local queueAccepted
    local queueReason
    local queuedReaction = false
    if not state or eventID == "" or npcID == "" then return false end
    state.socialGreetingResults = state.socialGreetingResults or {}
    state.socialGreetingResultOrder = state.socialGreetingResultOrder or {}
    if state.socialGreetingResults[eventID] then return false end
    state.socialGreetingResults[eventID] = greeting
    state.socialGreetingResultOrder[#state.socialGreetingResultOrder + 1] = eventID
    while #state.socialGreetingResultOrder > 32 do
        local oldest = table.remove(state.socialGreetingResultOrder, 1)
        state.socialGreetingResults[oldest] = nil
    end
    player = getSpecificPlayer and getSpecificPlayer(0) or nil
    body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(npcID) or nil
    snapshot = state.snapshots and state.snapshots[npcID]
        or Registry and Registry.Get and Registry.Get(npcID)
        or { id = npcID }
    context = {
        target = snapshot,
        npcID = npcID,
        playerActor = player,
        speakerName = targetName(snapshot),
        seed = eventID,
        eventID = eventID,
    }
    if greeting.eventType == "corpse_reaction"
        and type(greeting.gossipPacket) == "table"
    then
        memory = PNC.Conversation and PNC.Conversation.Memory or nil
        if memory and memory.GetGossipTemplateByCode
            and not memory.GetGossipTemplateByCode(greeting.gossipPacket.c)
        then
            return false
        end
        if not memory or type(memory.RenderGossipPacket) ~= "function" then
            return false
        end
        resolvedText = memory.RenderGossipPacket(greeting.gossipPacket)
        if type(resolvedText) ~= "string" or resolvedText == "" then
            return false
        end
        context.resolvedText = resolvedText
        context.corpseNPCID = greeting.corpseNPCID
        context.corpseName = greeting.corpseName
        context.factionName = greeting.factionName
        context.relationshipKind = greeting.relationshipKind
        context.memoryID = greeting.memoryID
        context.memoryType = greeting.memoryType
        context.eventType = "corpse_reaction"
        socialFlavor = PNC.SocialFlavorPresentation
        if not socialFlavor or type(socialFlavor.Receive) ~= "function" then
            local ok = pcall(
                require,
                "PNC/Conversation/PNC_SocialFlavorPresentation"
            )
            socialFlavor = ok and PNC.SocialFlavorPresentation or nil
        end
        if socialFlavor and type(socialFlavor.Receive) == "function" then
            queueAccepted, queueReason = socialFlavor.Receive({
                eventID = eventID,
                npcID = npcID,
                flavorID = greeting.flavorID,
                family = "corpse_reaction",
                eventType = "corpse_reaction",
                socialRole = snapshot.socialRole or snapshot.npcType
                    or greeting.npcType,
                priority = 100,
                weight = 10000,
                text = resolvedText,
                llmEligible = false,
                memoryEligible = false,
                mergeKey = "",
                cooldowns = {
                    familyMs = 0,
                    speakerMs = 0,
                    ambientMs = 0,
                    mergeWindowMs = 0,
                },
                presentationState = {
                    interrupt = true,
                },
                context = {
                    npcID = npcID,
                    eventID = eventID,
                    eventType = "corpse_reaction",
                    corpseNPCID = greeting.corpseNPCID,
                    corpseName = greeting.corpseName,
                    factionName = greeting.factionName,
                    relationshipKind = greeting.relationshipKind,
                    memoryID = greeting.memoryID,
                    memoryType = greeting.memoryType,
                    interactionType = greeting.interactionType,
                },
                ttlMs = 4000,
                holdMs = 1500,
                pumpImmediately = true,
            }, nil, {
                npcID = npcID,
                eventID = eventID,
            })
            if queueAccepted == true then
                queuedReaction = true
                text = resolvedText
            elseif queueReason == "duplicate_delivered"
                or queueReason == "duplicate_queued"
            then
                return false
            end
        end
    end
    if not queuedReaction then
        _, text = Presentation.ShowAmbientNPCFlavor(
            body,
            greeting.flavorID,
            context
        )
    end
    diary = PNC.Conversation and PNC.Conversation.Diary or nil
    if not diary then
        local ok, loaded = pcall(
            require,
            "PNC/Conversation/PNC_ConversationDiary"
        )
        diary = ok and loaded or nil
    end
    if diary and diary.Append and not queuedReaction then
        diary.Append(npcID, {
            kind = greeting.eventType == "corpse_reaction"
                and "npc_corpse_reaction" or "npc_proximity_greeting",
            eventType = greeting.eventType,
            npcText = text,
            delta = greeting.relationshipDelta,
            before = greeting.relationshipBefore,
            after = greeting.relationshipAfter,
            memoryID = greeting.memoryID,
            memoryType = greeting.memoryType,
            interactionType = greeting.interactionType,
            eventID = eventID,
            applied = greeting.applied == true,
            npcType = greeting.npcType,
            relationshipTier = greeting.relationshipTier,
            greetingState = greeting.greetingState,
            greetingDay = greeting.greetingDay,
            corpseNPCID = greeting.corpseNPCID,
            corpseName = greeting.corpseName,
            factionName = greeting.factionName,
            relationshipKind = greeting.relationshipKind,
        })
    end
    return text ~= nil and text ~= ""
end



return Presentation

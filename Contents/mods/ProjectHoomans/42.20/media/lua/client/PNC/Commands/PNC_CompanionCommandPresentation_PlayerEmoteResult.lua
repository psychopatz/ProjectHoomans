-- Client-side player-emote interaction result presentation provider.
local Presentation = PNC.CompanionCommandPresentation
local Internal = Presentation.Internal
local Registry = Internal.Registry
local Flavor = Internal.Flavor
local speak = Internal.speak

function Presentation.HandlePlayerEmoteInteractionResult(result)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local requestID = tostring(result and result.requestID or "")
    local key = requestID .. ":" .. tostring(result and result.eventID or "")
    local player
    local first
    local latest
    local diary
    if type(result) ~= "table" or requestID == "" then return false end
    if key == ":" then return false end
    if not state then return false end
    state.playerEmoteInteractionResults =
        state.playerEmoteInteractionResults or {}
    state.playerEmoteInteractionResultOrder =
        state.playerEmoteInteractionResultOrder or {}
    if state.playerEmoteInteractionResults[key] then return false end
    state.playerEmoteInteractionResults[key] = result
    state.playerEmoteInteractionResultOrder[#state.playerEmoteInteractionResultOrder + 1] = key
    while #state.playerEmoteInteractionResultOrder > 32 do
        local oldest = table.remove(state.playerEmoteInteractionResultOrder, 1)
        state.playerEmoteInteractionResults[oldest] = nil
    end
    player = getSpecificPlayer and getSpecificPlayer(0) or nil
    diary = PNC.Conversation and PNC.Conversation.Diary or nil
    if not diary then
        local ok, loaded = pcall(
            require,
            "PNC/Conversation/PNC_ConversationDiary"
        )
        diary = ok and loaded or nil
    end
    for _, target in ipairs(result.targets or {}) do
        if target.accepted == true then
            local npcID = tostring(target.npcID or "")
            local body = Registry and Registry.GetLiveZombie
                and Registry.GetLiveZombie(npcID) or nil
            local snapshot = state.snapshots and state.snapshots[npcID]
                or Registry and Registry.Get and Registry.Get(npcID)
                or { id = npcID }
            local flavorContext = Presentation.BuildFlavorContext(
                player,
                { target = snapshot }
            )
            local replyText
            local playerText
            if target.replyFlavorID then
                _, _, replyText = Presentation.EnqueueFlavor(
                    target.replyFlavorID,
                    "npc",
                    body,
                    {
                        target = snapshot,
                        targets = { snapshot },
                        npcID = npcID,
                        playerActor = player,
                        commandID = "vanilla_emote_"
                            .. tostring(result.emote),
                        seed = target.eventID or key,
                    },
                    {
                        eventID = target.eventID or key,
                        family = "emote_interaction",
                    }
                )
            end
            if Flavor and Flavor.Resolve then
                playerText = Flavor.Resolve(
                    "vanilla_emote_" .. tostring(result.emote or ""),
                    "player",
                    requestID,
                    flavorContext
                )
            end
            if target.relationshipAfter
                and PNC.Conversation
                and PNC.Conversation.Relationship
                and PNC.Conversation.Relationship.ReceiveAfter
            then
                PNC.Conversation.Relationship.ReceiveAfter(
                    npcID,
                    target.relationshipAfter,
                    target.relationshipDelta,
                    {
                        source = "player_emote",
                        eventID = target.eventID,
                    }
                )
            end
            latest = {
                npcID = target.npcID,
                source = "player_emote",
                emote = result.emote,
                delta = target.relationshipDelta,
                before = target.relationshipBefore,
                after = target.relationshipAfter,
                effects = {
                    memoryID = target.memoryID,
                    memoryType = target.memoryType,
                    interactionType = target.interactionType,
                    eventID = target.eventID,
                    applied = target.applied == true,
                    npcType = target.npcType,
                    relationshipTier = target.relationshipTier,
                    greetingState = target.greetingState,
                    greetingDay = target.greetingDay,
                },
                applied = target.applied == true,
                npcType = target.npcType,
                relationshipTier = target.relationshipTier,
                greetingState = target.greetingState,
                greetingDay = target.greetingDay,
                at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            }
            state.lastConversationDeltas = state.lastConversationDeltas or {}
            state.lastConversationDeltas[npcID] = latest
            first = first or target
            if diary and diary.Append then
                diary.Append(npcID, {
                    kind = "player_emote",
                    choiceID = result.emote,
                    playerText = playerText,
                    npcText = replyText,
                    delta = target.relationshipDelta,
                    before = target.relationshipBefore,
                    after = target.relationshipAfter,
                    memoryID = target.memoryID,
                    memoryType = target.memoryType,
                    interactionType = target.interactionType,
                    eventID = target.eventID,
                    applied = target.applied == true,
                    npcType = target.npcType,
                    greetingState = target.greetingState,
                    greetingDay = target.greetingDay,
                })
            end

            -- Keep an already-open relationship inspector in sync with the
            -- authoritative result instead of waiting for a manual refresh.
            if state.relationshipDebug
                and state.relationshipDebug.observer
                and tostring(state.relationshipDebug.observer.npcID
                    or state.relationshipDebug.observer.id or "") == npcID
                and state.relationshipDebug.target
                and state.relationshipDebug.target.kind == "player"
                and target.relationshipAfter
            then
                state.relationshipDebug.relationship = target.relationshipAfter
                state.relationshipDebug.generatedAt = latest.at
                state.lastRelationshipDebugReceiveAt = latest.at
            end
        end
    end
    if first then
        -- Preserve the legacy slot while the per-NPC map handles broadcasts
        -- addressed to more than one nearby NPC.
        state.lastConversationDelta = latest
    end
    return true
end

function Presentation.PlayCommand(player, commandID, target, context, outcome)
    local definition = Commands and Commands.Get(commandID) or nil
    context = type(context) == "table" and context or {}
    if not player or not definition
        or player.isDead and player:isDead()
    then
        return false
    end
    if definition.emote and player.playEmote then
        player:playEmote(definition.emote)
    end
    context.playerActor = player
    context.commandID = context.commandID or commandID
    context.target = context.target or target
    context.targets = context.targets or (target and { target } or nil)
    if outcome and Presentation.ShowCommandInteraction then
        Presentation.ShowCommandInteraction(
            player,
            commandID,
            context.target,
            context.targets,
            outcome,
            context
        )
    elseif Presentation.EnqueueFlavor then
        Presentation.EnqueueFlavor(
            commandID,
            "player",
            player,
            context,
            { family = "emote_interaction" }
        )
    else
        Presentation.ShowPlayerFlavor(player, commandID, context)
    end
    return true
end

local function isLocalOwner(snapshot, player)
    local owner = snapshot and snapshot.characterWindow
        and snapshot.characterWindow.ownerUsername or nil
    if not player or owner == nil or not player.getUsername then return false end
    return tostring(owner) == tostring(player:getUsername() or "")
end

function Presentation.SyncAcknowledgement(zombie, snapshot, modData)
    local feedback = snapshot and snapshot.commandFeedback or nil
    local revision = tonumber(feedback and feedback.revision)
    local token
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local text
    if not zombie or not modData or not feedback or revision == nil then
        return false
    end
    token = tostring(feedback.id or "")
        .. ":" .. tostring(revision)
        .. ":" .. tostring(feedback.issuedAt or 0)
    if tostring(modData.PNC_CommandAckToken or "") == token then
        return false
    end
    -- Consume feedback even when it belongs to another player so ownership
    -- changes never replay an old acknowledgement locally.
    modData.PNC_CommandAckToken = token
    if Presentation.IsCommandAcknowledgementSuppressed
        and Presentation.IsCommandAcknowledgementSuppressed(
            feedback.id,
            snapshot and snapshot.id
        )
    then
        return false
    end
    if not isLocalOwner(snapshot, player) then return false end
    local flavorContext = Presentation.BuildFlavorContext(player, {
        npcID = snapshot and snapshot.id,
        target = snapshot,
    })
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(
            feedback.id,
            "npc",
            tostring(snapshot.id or "") .. ":" .. tostring(revision),
            flavorContext
        )
        or nil
    return speak(zombie, text)
end

require "PNC/Commands/PNC_CompanionCommandInteraction"


return Presentation

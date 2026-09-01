-- Client-only speech and emote presentation for authority-owned commands.

PNC = PNC or {}
PNC.CompanionCommandPresentation = PNC.CompanionCommandPresentation or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "PNC/Audio/PNC_PlayerSpeech"

local Presentation = PNC.CompanionCommandPresentation
local Commands = PNC.CompanionCommands
local Flavor = PNC.CompanionCommandFlavor
local Identity = PNC.NPCIdentityPresentation
local Registry = PNC.Registry
local PlayerSpeech = PNC.PlayerSpeech
local Message = PsychopatzCore and PsychopatzCore.Conversation
    and PsychopatzCore.Conversation.Message or nil

Presentation.FlavorRevision = Presentation.FlavorRevision or 0

local function speak(actor, text)
    if not actor or not text or text == "" then return false end
    if actor.Say then
        actor:Say(text)
        return true
    end
    if actor.setHaloNote then
        actor:setHaloNote(text, 255, 255, 255, 300)
        return true
    end
    return false
end

local function targetName(target)
    return Identity.GetName(target or { recruited = true })
end

local function normalizeTargets(context)
    if type(context) ~= "table" then return {} end
    if type(context.targets) == "table" then return context.targets end
    if context.target then return { context.target } end
    if context.id or context.name or context.displayName
        or context.source
    then
        return { context }
    end
    return {}
end

local function formatTargetNames(targets)
    local count = #targets
    if count <= 0 then return "everyone" end
    if count == 1 then return targetName(targets[1]) end
    if count == 2 then
        return targetName(targets[1])
            .. " and " .. targetName(targets[2])
    end
    return targetName(targets[1])
        .. ", " .. targetName(targets[2])
        .. ", and " .. tostring(count - 2) .. " more"
end

function Presentation.BuildFlavorContext(player, context)
    local targets = normalizeTargets(context)
    local names = formatTargetNames(targets)
    return {
        name = targets[1] and targetName(targets[1]) or "Companion",
        names = names,
        count = #targets,
        player = tostring(player and player.getUsername
            and player:getUsername() or "Survivor"),
    }
end

function Presentation.ShowPlayerFlavor(player, commandID, context)
    local seed
    local text
    local flavorContext
    if not player
        or player.isDead and player:isDead()
    then
        return false
    end
    Presentation.FlavorRevision = Presentation.FlavorRevision + 1
    seed = tostring(player.getUsername and player:getUsername() or "")
        .. ":" .. tostring(PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
        .. ":" .. tostring(Presentation.FlavorRevision)
    flavorContext = Presentation.BuildFlavorContext(player, context)
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(commandID, "player", seed, flavorContext)
        or nil
    -- The player adapter keeps the standard visible presentation and
    -- best-effort routes the same canonical line through the optional voice
    -- endpoint. If the brain is unavailable it remains a normal game string.
    if PlayerSpeech and PlayerSpeech.Speak then
        return PlayerSpeech.Speak(player, text, {
            commandID = commandID,
            eventID = type(context) == "table" and context.eventID or nil,
            conversationID = type(context) == "table"
                and (context.conversationID or context.conversation_id) or nil,
            target = type(context) == "table" and context.target or nil,
            targets = type(context) == "table" and context.targets or nil,
        }) == true
    end
    return speak(player, text)
end

function Presentation.ShowNPCFlavor(actor, flavorID, context)
    local player = type(context) == "table" and context.playerActor
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local flavorContext
    local seed
    local text
    if not actor or not flavorID
        or actor.isDead and actor:isDead()
    then
        return false
    end
    Presentation.FlavorRevision = Presentation.FlavorRevision + 1
    flavorContext = Presentation.BuildFlavorContext(player, context)
    seed = type(context) == "table" and context.seed or nil
    seed = tostring(seed or "") .. ":" .. tostring(Presentation.FlavorRevision)
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(flavorID, "npc", seed, flavorContext)
        or nil
    return speak(actor, text), text
end

local function publishNPCMessage(actor, text, context)
    local target = type(context) == "table" and context.target or nil
    local player = type(context) == "table" and context.playerActor or nil
    local eventID = type(context) == "table" and context.eventID or nil
    local npcID = type(context) == "table" and (context.npcID
        or target and (target.id or target.npcID)) or nil
    local speakerName = type(context) == "table" and context.speakerName or nil
    local message
    local ok
    if not Message or type(Message.New) ~= "function"
        or type(Message.Publish) ~= "function"
    then
        return false
    end
    npcID = tostring(npcID or "")
    if npcID == "" or tostring(text or "") == "" then return false end
    message = Message.New({
        messageID = eventID and ("social-greeting:" .. tostring(eventID))
            or Message.NewID("social-greeting"),
        conversationID = eventID and ("social-greeting:" .. tostring(eventID))
            or Message.NewID("social-greeting-conversation"),
        sequence = 1,
        speaker = "npc",
        speakerID = npcID,
        speakerName = speakerName,
        speakerKind = "npc",
        playerUUID = player and player.getUsername
            and player:getUsername() or nil,
        npcUUID = npcID,
        namespace = "ProjectHoomans",
        payload = {
            text = text,
            flavorID = type(context) == "table" and context.flavorID or nil,
        },
        text = text,
        source = {
            kind = "social_greeting",
            channel = "ambient_social",
            contextEligible = false,
            eventID = eventID,
        },
        presentationState = {
            conversationUI = false,
            nameplate = true,
            tts = false,
        },
    })
    ok = pcall(Message.Publish, message)
    if not ok then return false end
    return true
end

-- Ambient NPC greetings use the same flavor resolver as emote replies, but
-- publish a canonical NPC message so nameplates and other speech consumers see
-- the exact line. Native Say() is only the fallback when the message bus is
-- unavailable.
function Presentation.ShowAmbientNPCFlavor(actor, flavorID, context)
    local player = type(context) == "table" and context.playerActor
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local flavorContext
    local seed
    local text
    local published
    if not flavorID then return false end
    Presentation.FlavorRevision = Presentation.FlavorRevision + 1
    flavorContext = Presentation.BuildFlavorContext(player, context)
    seed = type(context) == "table" and context.seed or nil
    -- The server event id is the stable flavor seed.  Do not include the
    -- local presentation counter or two clients/replays can choose different
    -- lines for the same authoritative greeting.
    seed = tostring(seed or "")
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(flavorID, "npc", seed, flavorContext)
        or nil
    if not text or text == "" then return false end
    if type(context) ~= "table" then context = {} end
    context.playerActor = player
    context.flavorID = flavorID
    published = publishNPCMessage(actor, text, context)
    if not published then speak(actor, text) end
    return true, text
end

function Presentation.HandleSocialGreeting(greeting)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local eventID = tostring(greeting and greeting.eventID or "")
    local npcID = tostring(greeting and greeting.npcID or "")
    local player
    local body
    local snapshot
    local text
    local diary
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
    _, text = Presentation.ShowAmbientNPCFlavor(
        body,
        greeting.flavorID,
        {
            target = snapshot,
            npcID = npcID,
            playerActor = player,
            speakerName = targetName(snapshot),
            seed = eventID,
            eventID = eventID,
        }
    )
    diary = PNC.Conversation and PNC.Conversation.Diary or nil
    if not diary then
        local ok, loaded = pcall(
            require,
            "PNC/Conversation/PNC_ConversationDiary"
        )
        diary = ok and loaded or nil
    end
    if diary and diary.Append then
        diary.Append(npcID, {
            kind = "npc_proximity_greeting",
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
        })
    end
    return text ~= nil and text ~= ""
end

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
            if body and target.replyFlavorID then
                _, replyText = Presentation.ShowNPCFlavor(body, target.replyFlavorID, {
                    target = snapshot,
                    playerActor = player,
                    seed = target.eventID or key,
                })
            elseif target.replyFlavorID and Flavor and Flavor.Resolve then
                replyText = Flavor.Resolve(
                    target.replyFlavorID,
                    "npc",
                    target.eventID or key,
                    flavorContext
                )
            end
            if Flavor and Flavor.Resolve then
                playerText = Flavor.Resolve(
                    "vanilla_emote_" .. tostring(result.emote or ""),
                    "player",
                    requestID .. ":" .. npcID,
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

function Presentation.PlayCommand(player, commandID, target)
    local definition = Commands and Commands.Get(commandID) or nil
    if not player or not definition
        or player.isDead and player:isDead()
    then
        return false
    end
    if definition.emote and player.playEmote then
        player:playEmote(definition.emote)
    end
    Presentation.ShowPlayerFlavor(player, commandID, {
        target = target,
    })
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
    if not isLocalOwner(snapshot, player) then return false end
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(
            feedback.id,
            "npc",
            tostring(snapshot.id or "") .. ":" .. tostring(revision),
            {
                name = Identity.GetName(snapshot),
                names = Identity.GetName(snapshot),
                count = 1,
                player = tostring(player and player.getUsername
                    and player:getUsername() or "Survivor"),
            }
        )
        or nil
    return speak(zombie, text)
end

return Presentation

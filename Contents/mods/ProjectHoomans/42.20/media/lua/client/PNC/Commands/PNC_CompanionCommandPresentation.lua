-- Client-only speech and emote presentation for authority-owned commands.

PNC = PNC or {}
PNC.CompanionCommandPresentation = PNC.CompanionCommandPresentation or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "PNC/Core/Identity/PNC_FlavorAddress"
require "PNC/Audio/PNC_PlayerSpeech"
local InteractionPresentationRegistry = require
    "PNC/Conversation/PNC_SemanticInteractionPresentationRegistry"
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil
local RealizationAuthority = PNC.Semantics
    and PNC.Semantics.RealizationAuthority or nil
if type(InteractionLifecycle) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticInteractionLifecycle"
    )
    InteractionLifecycle = ok and loaded or nil
end
if type(RealizationAuthority) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
    )
    RealizationAuthority = ok and loaded or nil
end

local Presentation = PNC.CompanionCommandPresentation
local Commands = PNC.CompanionCommands
local Flavor = PNC.CompanionCommandFlavor
local Identity = PNC.NPCIdentityPresentation
local FlavorAddress = PNC.FlavorAddress
local Registry = PNC.Registry
local PlayerSpeech = PNC.PlayerSpeech
local AddressResolver = PNC.Semantics
    and PNC.Semantics.AddressResolver
    or require "PNC/Semantics/PNC_SemanticAddressResolver"
local SocialReactions = PNC.Semantics
    and PNC.Semantics.SocialReactions or nil
if type(SocialReactions) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticSocialReaction"
    )
    SocialReactions = ok and loaded or nil
end
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
    if context.id or context.displayName
        or context.source
    then
        return { context }
    end
    return {}
end

local function targetSource(target)
    if type(target) ~= "table" then return target end
    return target.source or target.record or target.snapshot or target
end

local function targetID(target, source)
    return target and (target.id or target.npcID)
        or source and (source.id or source.npcID)
        or nil
end

local function knownTargetName(target)
    local known
    if Identity and type(Identity.GetKnownName) == "function" then
        known = Identity.GetKnownName(targetSource(target))
        if known and not AddressResolver.IsPlaceholder(known) then
            return known
        end
        return nil
    end
    known = targetName(target)
    if known and not AddressResolver.IsPlaceholder(known) then
        return known
    end
    return nil
end

local function targetAddress(target, context, state)
    local source = targetSource(target) or {}
    local id = targetID(target, source)
    local known = knownTargetName(target)
    local history = state and state.semanticAddressHistory
        and id and state.semanticAddressHistory[tostring(id)] or nil
    local address
    if known then return known end
    address = AddressResolver.Resolve({
        target = source,
        identityKnown = false,
        knownName = nil,
        relationshipKind = target and (
            target.relationshipKind or target.relationshipCategory
                or target.relationshipState
        ) or nil,
        familiarity = target and target.familiarity or nil,
        tone = target and (target.tone or target.beatTone) or nil,
        persona = target and (target.persona or target.personaStyle) or nil,
        gender = target and (target.gender or target.sex) or nil,
        language = context and context.language or nil,
        recentAddresses = history,
    })
    if state and id and address and not address.known then
        state.semanticAddressHistory = state.semanticAddressHistory or {}
        state.semanticAddressHistory[tostring(id)] =
            state.semanticAddressHistory[tostring(id)] or {}
        AddressResolver.Remember(
            state.semanticAddressHistory[tostring(id)], address
        )
    end
    return address and address.address or "stranger"
end

local function formatTargetNames(targets, context, state)
    local count = #targets
    local names = {}
    local index
    if count <= 0 then return "everyone" end
    for index, target in ipairs(targets) do
        names[index] = targetAddress(target, context, state)
    end
    if count == 1 then return names[1] end
    if count == 2 then
        return names[1] .. " and " .. names[2]
    end
    return names[1]
        .. ", " .. names[2]
        .. ", and " .. tostring(count - 2) .. " more"
end

local PLAYER_EMOTE_ACTS = {
    wavehi = "GREET",
    wavebye = "FAREWELL",
    thankyou = "THANK",
    thumbsup = "ACK",
    thumbsdown = "DISAPPROVE",
    insult = "INSULT",
    clap = "PRAISE",
    salute = "ACK",
}

local function semanticPlayerID(player, state)
    local playerContext = state and state.playerContext or {}
    if player and player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return username end
    end
    return tostring(
        playerContext.characterUUID or playerContext.playerUUID
            or "local-player"
    )
end

local function ensureAmbientInteraction(context, npcID, player)
    context = type(context) == "table" and context or {}
    if context.interaction then
        if context.responsePlanID and context.realizationID then
            return context.interaction
        end
        return nil
    end
    local Envelope = InteractionLifecycle
        and InteractionLifecycle.Envelope or nil
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local playerUUID = context.playerUUID
        or playerContext.characterUUID or playerContext.playerUUID
        or player and player.getUsername and player:getUsername() or nil
    local eventID = context.eventID or context.eventRef
    local eventType = context.eventType or context.source or "social_flavor"
    if not Envelope or type(Envelope.NPCSpeech) ~= "function"
        or not npcID or not eventID or not playerUUID
        or not context.responsePlanID or not context.realizationID
    then
        -- A legacy/compatibility presentation may still carry a Flavor ID,
        -- but it is not allowed to synthesize semantic provenance after the
        -- renderer has selected its wording.
        return nil
    end
    context.interaction = Envelope.NPCSpeech({
        npcID = npcID,
        targetID = playerUUID,
        playerUUID = playerUUID,
        act = context.act or "REACT",
        topic = context.topic or eventType,
        beatID = context.beatID
            or "beat:" .. tostring(eventType) .. ":" .. tostring(eventID),
        responsePlanID = context.responsePlanID
            or "social.reaction." .. tostring(eventType),
        flowID = context.flowID
            or "social:" .. tostring(eventType),
        poolID = context.poolID or context.flavorID,
        eventType = eventType,
        eventRef = eventID,
        factRefs = context.factRefs,
    })
    return context.interaction
end

function Presentation.BuildFlavorContext(player, context)
    local targets = normalizeTargets(context)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local names = formatTargetNames(
        targets,
        type(context) == "table" and context or {},
        state
    )
    local playerContext = state.playerContext or {}
    local npcID = type(context) == "table" and context.npcID
        or targets[1] and (targets[1].id or targets[1].npcID)
        or "command-flavor"
    local playerAddress = FlavorAddress.ResolveForNPC({
        npcID = npcID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(
            targets[1], npcID
        ),
        player = player,
        playerContext = playerContext,
        playerUUID = playerContext.characterUUID
            or playerContext.playerUUID,
        playerNameKnown = type(context) == "table"
            and context.playerNameKnown or nil,
        isFemale = type(context) == "table"
            and context.playerIsFemale or nil,
        state = state,
    })
    return {
        name = targets[1] and targetName(targets[1]) or "Companion",
        names = names,
        count = #targets,
        player = playerAddress.addressName,
        playerName = playerAddress.addressName,
        playerAddressName = playerAddress.addressName,
        playerFullName = playerAddress.fullName,
        playerFirstName = playerAddress.firstName,
        playerSurname = playerAddress.surname,
        playerLastName = playerAddress.lastName,
        playerNameKnown = playerAddress.known,
        playerIsFemale = playerAddress.isFemale,
        playerNicknameID = playerAddress.nicknameID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(targets[1], npcID),
    }
end

-- Select the player's emote speech meaning before the authored content
-- renderer is reached. CompanionCommandFlavor remains the compatibility
-- content source for localized wording variants only.
function Presentation.ResolvePlayerEmoteRealization(emoteID, context)
    context = type(context) == "table" and context or {}
    local state = PNC.Network and PNC.Network.ClientState or {}
    local player = context.playerActor
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local action = tostring(emoteID or "")
    local actorID = semanticPlayerID(player, state)
    local realization
    local reason
    if action == "" then return nil, "player_emote_action_required" end
    if not RealizationAuthority
        or type(RealizationAuthority.Resolve) ~= "function"
    then
        return nil, "semantic_realization_unavailable"
    end
    realization, reason = RealizationAuthority.Resolve({
        poolID = "semantic.emote.player",
        responsePlanID = "semantic.emote.player",
        realizationFamily = "emote_player",
        act = PLAYER_EMOTE_ACTS[action] or "REACT",
        context = {
            action = action,
            eventType = context.eventType or "player_emote_" .. action,
            npcID = "player:" .. actorID,
            currentTopic = context.currentTopic or context.topic,
            previousTopic = context.previousTopic,
            socialStyle = context.socialStyle,
        },
        salt = context.requestID or context.eventID or action,
    })
    if not realization then
        return nil, reason or "player_emote_realization_unavailable"
    end
    if type(RealizationAuthority.AttachProvenance) == "function" then
        RealizationAuthority.AttachProvenance(context, realization)
    end
    return realization
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

function Presentation.ShowCommandRejection(player, actor, commandID, reason,
    context)
    local reasonText = tostring(reason or "")
    if tostring(commandID or "") ~= "camp"
        or (string.sub(reasonText, 1, 5) ~= "camp_"
            and string.sub(reasonText, 1, 9) ~= "campfire_")
    then
        return false
    end
    context = type(context) == "table" and context or {}
    context.playerActor = context.playerActor or player
    context.liveActor = context.liveActor or actor
    if Presentation.ShowCommandInteraction then
        return Presentation.ShowCommandInteraction(
            player,
            commandID,
            context.target,
            context.targets,
            "invalid",
            context
        )
    end
    local playerShown = Presentation.ShowPlayerFlavor(
        player,
        "camp_rejected",
        context
    )
    local shown = actor
        and Presentation.ShowNPCFlavor(actor, "camp_rejected", context)
        or false
    return playerShown == true or shown == true
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
    InteractionPresentationRegistry.Remember(
        eventID,
        type(context) == "table" and context.interaction or nil
    )
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
            semanticOwned = type(context) == "table"
                and context.semanticOwned == true or false,
            contentOwner = type(context) == "table"
                and context.contentOwner or nil,
            poolID = type(context) == "table"
                and context.poolID or nil,
            responsePlanID = type(context) == "table"
                and context.responsePlanID or nil,
            realizationFamily = type(context) == "table"
                and context.realizationFamily or nil,
            realizationID = type(context) == "table"
                and context.realizationID or nil,
            factRefs = type(context) == "table"
                and context.factRefs or nil,
        },
        text = text,
        source = {
            kind = type(context) == "table" and context.semanticOwned == true
                and "semantic_speech" or "social_greeting",
            channel = "ambient_social",
            contextEligible = false,
            semanticOwned = type(context) == "table"
                and context.semanticOwned == true or false,
            contentOwner = type(context) == "table"
                and context.contentOwner or nil,
            poolID = type(context) == "table"
                and context.poolID or nil,
            eventID = eventID,
            interaction = type(context) == "table"
                and context.interaction or nil,
            semanticAct = type(context) == "table"
                and context.semanticAct or nil,
            topic = type(context) == "table" and context.topic or nil,
            responsePlanID = type(context) == "table"
                and context.responsePlanID or nil,
            realizationFamily = type(context) == "table"
                and context.realizationFamily or nil,
            realizationID = type(context) == "table"
                and context.realizationID or nil,
            factRefs = type(context) == "table"
                and context.factRefs or nil,
        },
        presentationState = {
            conversationUI = false,
            nameplate = true,
            -- This is a canonical NPC greeting, not a legacy TTS callback.
            -- Leave it eligible for the shared Core voice stream.
            tts = true,
        },
    })
    ok = pcall(Message.Publish, message)
    if not ok then return false end
    return true
end

-- Ambient NPC speech publishes a canonical NPC message so nameplates and
-- other speech consumers share one presentation path. A server-selected
-- localized gossip packet may supply resolvedText; ordinary greetings carry
-- their selected semantic realization from the server.
function Presentation.ShowAmbientNPCFlavor(actor, flavorID, context)
    local player = type(context) == "table" and context.playerActor
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local text
    local published
    local semantic
    local resolvedText = type(context) == "table"
        and context.resolvedText or nil
    if not flavorID then return false end
    Presentation.FlavorRevision = Presentation.FlavorRevision + 1
    if type(resolvedText) == "string" and resolvedText ~= "" then
        text = resolvedText
    else
        if type(context) ~= "table" then context = {} end
        semantic = context.realizationID and context.responsePlanID
            and {
                responsePlanID = context.responsePlanID,
                realizationFamily = context.realizationFamily,
                realizationID = context.realizationID,
                fallback = context.resolvedText,
                groundedFactRefs = context.factRefs,
            }
        if not semantic and SocialReactions
            and type(SocialReactions.Resolve) == "function"
        then
            semantic = SocialReactions.Resolve({
                eventType = context.eventType or flavorID,
                eventID = context.eventID or context.eventRef or flavorID,
                npcID = context.npcID,
                context = context,
                groundedFactRefs = context.factRefs,
            })
        end
        if semantic then
            context.responsePlanID = semantic.responsePlanID
            context.realizationFamily = semantic.realizationFamily
            context.realizationID = semantic.realizationID
            context.factRefs = semantic.groundedFactRefs
            text = semantic.fallback
        else
            -- A Project Hoomans NPC event cannot fall through to a first-party
            -- flavor selector after semantic migration.
            return false, "semantic_realization_required"
        end
    end
    if not text or text == "" then return false end
    if type(context) ~= "table" then context = {} end
    context.playerActor = player
    context.flavorID = flavorID
    ensureAmbientInteraction(context, context.npcID
        or context.target and (context.target.id or context.target.npcID), player)
    published = publishNPCMessage(actor, text, context)
    if not published then speak(actor, text) end
    return true, text
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
    local acknowledgementContext = {
        npcID = snapshot and snapshot.id,
        target = snapshot,
        eventType = "companion_command_acknowledgement",
        commandID = feedback.id,
        commandReason = feedback.reason,
    }
    local semantic = SocialReactions and SocialReactions.Resolve and
        SocialReactions.Resolve({
            eventType = "companion_command_acknowledgement",
            eventID = tostring(snapshot.id or "") .. ":" .. tostring(revision),
            npcID = snapshot and snapshot.id,
            context = acknowledgementContext,
        }) or nil
    if semantic then
        text = semantic.fallback
    else
        -- Command acknowledgement is a semantic-owned packet. A missing
        -- catalog result is an explicit delivery failure, never a legacy
        -- prose lookup.
        return false
    end
    return speak(zombie, text)
end

Presentation.Internal = Presentation.Internal or {}
local Internal = Presentation.Internal
Internal.Registry = Registry
Internal.Flavor = Flavor
Internal.TargetName = targetName
Internal.speak = speak

require "PNC/Commands/PNC_CompanionCommandPresentation_SocialGreeting"
require "PNC/Commands/PNC_CompanionCommandPresentation_PlayerEmoteResult"

require "PNC/Commands/PNC_CompanionCommandInteraction"

return Presentation

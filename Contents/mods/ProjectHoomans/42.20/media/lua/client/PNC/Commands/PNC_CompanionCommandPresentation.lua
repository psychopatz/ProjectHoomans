-- Client-only speech and emote presentation for authority-owned commands.

PNC = PNC or {}
PNC.CompanionCommandPresentation = PNC.CompanionCommandPresentation or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"
require "PNC/Core/Identity/PNC_FlavorAddress"
require "PNC/Audio/PNC_PlayerSpeech"

local Presentation = PNC.CompanionCommandPresentation
local Commands = PNC.CompanionCommands
local Flavor = PNC.CompanionCommandFlavor
local Identity = PNC.NPCIdentityPresentation
local FlavorAddress = PNC.FlavorAddress
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
    if context.id or context.displayName
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
    local state = PNC.Network and PNC.Network.ClientState or {}
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
-- localized gossip packet may supply resolvedText; ordinary greetings use
-- the standard flavor resolver below.
function Presentation.ShowAmbientNPCFlavor(actor, flavorID, context)
    local player = type(context) == "table" and context.playerActor
        or getSpecificPlayer and getSpecificPlayer(0) or nil
    local flavorContext
    local seed
    local text
    local published
    local resolvedText = type(context) == "table"
        and context.resolvedText or nil
    if not flavorID then return false end
    Presentation.FlavorRevision = Presentation.FlavorRevision + 1
    if type(resolvedText) == "string" and resolvedText ~= "" then
        text = resolvedText
    else
        flavorContext = Presentation.BuildFlavorContext(player, context)
        seed = type(context) == "table" and context.seed or nil
        -- The server event id is the stable flavor seed. Do not include the
        -- local presentation counter or replays could choose another line.
        seed = tostring(seed or "")
        text = Flavor and Flavor.Resolve
            and Flavor.Resolve(flavorID, "npc", seed, flavorContext)
            or nil
    end
    if not text or text == "" then return false end
    if type(context) ~= "table" then context = {} end
    context.playerActor = player
    context.flavorID = flavorID
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

-- Canonical semantic speech mapping for companion commands, emotes, and
-- greetings.  This module maps bounded domain facts to existing
-- ResponseCatalog pools; it does not own a wording table or a second
-- selector.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Speech = PNC.ConvoEngine.CompanionSpeech or {}
PNC.ConvoEngine.CompanionSpeech = Speech

local Authority = PNC.ConvoEngine.RealizationAuthority
    or require "PNC/ConvoEngine/Dialogue/RealizationAuthority"
local SpeechRealization = PNC.ConvoEngine.SpeechRealization
    or require "PNC/ConvoEngine/SpeechRealization"
local TokenFormatter = PNC.ConvoEngine.TokenFormatter
    or require "PNC/ConvoEngine/TokenFormatter"
local CombatReactionProfile = PNC.Semantics.CombatReactionProfile
    or require "PNC/Semantics/PNC_SemanticCombatReactionProfile"

Speech.VERSION = 1
Speech.CONTENT_OWNER = "projecthoomans.dialogue_content.commands_emotes"

local EMOTE_ACTS = {
    insult = "INSULT",
    thumbsdown = "DISAPPROVE",
    wavehi = "GREET",
    wavebye = "FAREWELL",
    thankyou = "THANK",
    thumbsup = "ACK",
    clap = "PRAISE",
    salute = "ACK",
}

local COMMAND_ACTS = {
    follow = "DIRECTIVE",
    stay = "DIRECTIVE",
    camp = "DIRECTIVE",
    return_home = "DIRECTIVE",
    attack_auto = "DIRECTIVE",
    attack_melee = "DIRECTIVE",
    attack_ranged = "DIRECTIVE",
    attack_none = "DIRECTIVE",
}

local function copied(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 6 then return nil end
    local output = {}
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = copied(item, depth + 1)
        end
    end
    return output
end

local function formatTokens(text, context)
    local output = tostring(text or "")
    if not string.find(output, "{", 1, true) then return output end
    local ctx = type(context) == "table" and context or {}
    local tokens = {}
    local function mergeScalar(tbl)
        if type(tbl) ~= "table" then return end
        for key, value in pairs(tbl) do
            if type(key) == "string"
                and (type(value) == "string" or type(value) == "number")
            then
                tokens[key] = value
            end
        end
    end
    mergeScalar(ctx)
    mergeScalar(ctx.renderTokens)
    mergeScalar(ctx.contentArgs)

    -- Command wording is authored with the actor-neutral ConvoEngine binding.
    -- Populate addressee.name (when known/named), speaker.name, scene.location,
    -- and scene.clock, rejecting empty or "Unknown" placeholders so
    -- TokenFormatter collapses optional vocatives cleanly.
    local addresseeKnown = ctx.playerNameKnown ~= false
    local rawAddressee = tokens["addressee.name"]
        or tokens.names
        or tokens.name
        or ctx.addresseeName
        or (addresseeKnown and (ctx.playerFirstName or ctx.playerAddressName or ctx.playerName))
        or (ctx.npcIdentityKnown ~= false and (ctx.npcFirstName or ctx.npcName))
    tokens["addressee.name"] = TokenFormatter.CleanName(rawAddressee)

    local rec = type(ctx.npcRecord) == "table" and ctx.npcRecord
        or (type(ctx.target) == "table" and ctx.target or nil)
    local rawSpeaker = tokens["speaker.name"]
        or ctx.speakerName
        or ctx.npcFirstName
        or ctx.npcFullName
        or ctx.npcName
        or (rec and (rec.name or rec.fullName or rec.displayName))
    tokens["speaker.name"] = TokenFormatter.FirstTokenName(rawSpeaker)

    local rawLocation = tokens["scene.location"]
        or ctx.sceneLocation
        or ctx.locationLabel
        or ctx.locationName
        or ctx.zoneName
        or ctx.settlementName
        or ctx.roomName
        or (rec and (rec.zoneName or rec.locationName or rec.settlementName or rec.roomName))
    tokens["scene.location"] = TokenFormatter.CleanLocation(rawLocation)

    local rawClock = tokens["scene.clock"]
        or ctx.sceneClock
        or ctx.timeOfDay
    tokens["scene.clock"] = TokenFormatter.CleanName(rawClock)

    return TokenFormatter.Format(output, tokens)
end

local function rendered(realization, context)
    local output
    local renderContext = copied(context or {})
    local applied
    if type(realization) ~= "table" then return nil end
    renderContext.phraseSalt = renderContext.phraseSalt
        or renderContext.requestID
        or renderContext.eventID
        or realization.realizationID
    if SpeechRealization and type(SpeechRealization.Apply) == "function" then
        applied = SpeechRealization.Apply({
            selectionID = realization.realizationID,
            templateID = realization.templateID,
            fallback = realization.fallback,
            args = realization.translationArgs,
            plan = realization.responsePlan,
        }, renderContext)
    end
    output = copied(realization)
    if type(applied) == "table" then
        output.fallback = applied.fallback or output.fallback
        output.templateID = applied.templateID or output.templateID
        output.renderTemplateID = applied.renderTemplateID
        output.responsePlan = applied.plan or output.responsePlan
        output.phraseFamilyID = applied.phraseFamilyID
        output.phraseID = applied.phraseID
        output.phrasePoolSize = applied.phrasePoolSize
        output.phraseSelection = applied.phraseSelection
        output.speechStyleVariant = applied.speechStyleVariant
        output.realization = applied.realization
    end
    output.fallback = formatTokens(output.fallback, renderContext)
    output.semanticOwned = true
    output.contentOwner = output.contentOwner or Speech.CONTENT_OWNER
    output.selectionSource = output.selectionSource or "semantic_response_catalog"
    return output
end

local function resolve(poolID, spec, context)
    spec = type(spec) == "table" and spec or {}
    context = type(context) == "table" and context or {}
    local realization
    local reason
    if not Authority or type(Authority.Resolve) ~= "function" then
        return nil, "semantic_realization_unavailable"
    end
    realization, reason = Authority.Resolve({
        poolID = poolID,
        responsePlanID = spec.responsePlanID or poolID,
        realizationFamily = spec.realizationFamily or poolID,
        act = spec.act or "REPLY",
        topic = spec.topic,
        context = context,
        salt = spec.salt or context.requestID or context.eventID
            or context.npcID or poolID,
        groundedFactRefs = spec.groundedFactRefs or context.factRefs,
    })
    if not realization then
        return nil, reason or "semantic_realization_unavailable"
    end
    return rendered(realization, context)
end

function Speech.ResolvePlayerCommand(commandID, outcome, context)
    context = copied(context or {})
    commandID = tostring(commandID or "")
    local semanticCommandID = commandID
    local semanticOutcome = outcome
    if commandID == "camp_none" then
        semanticCommandID = "camp"
        semanticOutcome = "none"
    elseif commandID == "camp_rejected" then
        semanticCommandID = "camp"
        semanticOutcome = "invalid"
    end
    context.commandID = semanticCommandID
    context.commandOutcome = semanticOutcome
    context.action = semanticCommandID
    return resolve("semantic.command.player", {
        act = COMMAND_ACTS[semanticCommandID] or "DIRECTIVE",
        topic = "companion_command",
        realizationFamily = "companion_command_player",
    }, context)
end

function Speech.ResolveNPCCommand(commandID, outcome, context)
    context = copied(context or {})
    commandID = tostring(commandID or "")
    context.commandID = commandID
    context.commandOutcome = outcome
    context.action = commandID

    if outcome ~= "invalid"
        and (commandID == "combat_engage"
            or commandID == "combat_avoid"
            or commandID == "combat_hold")
    then
        local record = context.npcRecord or context.target
        local profile = record and CombatReactionProfile
            and type(CombatReactionProfile.Build) == "function"
            and CombatReactionProfile.Build(record, context.playerKey, {
                role = "witness",
                actorKind = "player",
                zombieObservation = record.runtime
                    and record.runtime.zombieObservation,
            }) or nil
        context.combatReactionStyle = profile
            and profile.combatReactionStyle or "practical"
        context.combatReactionMood = profile
            and profile.combatReactionMood or "steady"
        return resolve("semantic.combat.horde.ack", {
            act = "ACK",
            topic = "combat",
            realizationFamily = "combat_horde_ack",
        }, context)
    end

    return resolve("semantic.command.reply", {
        act = outcome == "invalid" and "REACT" or "ACK",
        topic = "companion_command",
        realizationFamily = "companion_command_reply",
    }, context)
end

function Speech.ResolvePlayerEmote(emoteID, context)
    context = copied(context or {})
    emoteID = tostring(emoteID or "")
    context.action = emoteID
    context.eventType = context.eventType or "player_emote_" .. emoteID
    return resolve("semantic.emote.player", {
        act = EMOTE_ACTS[emoteID] or "REACT",
        topic = context.topic or "social_emote",
        realizationFamily = "emote_player",
    }, context)
end

function Speech.ResolveNPCEmote(emoteID, context)
    context = copied(context or {})
    emoteID = tostring(emoteID or "")
    context.action = emoteID
    context.eventType = context.eventType or "player_emote_" .. emoteID
    return resolve("semantic.emote.reply", {
        act = EMOTE_ACTS[emoteID] or "REACT",
        topic = context.topic or "social_emote",
        realizationFamily = "emote_reply",
    }, context)
end

function Speech.ResolveGreeting(context)
    context = copied(context or {})
    context.eventType = context.eventType or "npc_proximity_greeting"
    return resolve("semantic.flow.greeting.opening", {
        act = "GREET",
        topic = "greeting",
        realizationFamily = "greeting",
    }, context)
end

return Speech

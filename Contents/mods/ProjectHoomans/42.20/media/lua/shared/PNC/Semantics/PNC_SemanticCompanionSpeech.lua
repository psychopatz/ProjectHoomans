-- Canonical semantic speech mapping for companion commands, emotes, and
-- greetings.  This module maps bounded domain facts to existing
-- ResponseCatalog pools; it does not own a wording table or a second
-- selector.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Speech = PNC.Semantics.CompanionSpeech or {}
PNC.Semantics.CompanionSpeech = Speech

local Authority = PNC.Semantics.RealizationAuthority
    or require "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
local SpeechRealization = PNC.Semantics.SpeechRealization
    or require "PNC/Semantics/PNC_SpeechRealization"
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
    local values = type(context) == "table"
        and (context.contentArgs or context.renderTokens or context)
        or {}
    local key
    local value
    for key, value in pairs(values) do
        if type(key) == "string"
            and (type(value) == "string" or type(value) == "number")
        then
            output = string.gsub(output, "{" .. tostring(key) .. "}",
                function() return tostring(value) end)
        end
    end
    return output
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
    context.commandID = commandID
    context.commandOutcome = outcome
    context.action = commandID
    return resolve("semantic.command.player", {
        act = COMMAND_ACTS[commandID] or "DIRECTIVE",
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

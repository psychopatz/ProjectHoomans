-- Small deterministic response composer for high-confidence semantic turns.
--
-- This is intentionally a response-layer extension, not parser logic. It
-- reads an observation snapshot and produces a presentation-safe fallback;
-- it does not mutate the world or perform an NPC action.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse or {}
PNC.Semantics.LocalResponse = Response

Response.VERSION = 1
local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    Catalog = type(loaded) == "table" and loaded or nil
end

local LEGACY_TEXT_FALLBACKS = {
    ["semantic.question.time"] = "I can't tell the exact time.",
    ["semantic.question.date"] = "I don't know today's date.",
    ["semantic.question.weather"] =
        "I can't tell what the weather's doing right now.",
    ["semantic.question.identity"] = "I'm a survivor.",
    ["semantic.identity.exchange"] = "Nice to meet you. I'm a survivor.",
    ["semantic.identity.evasion"] =
        "I asked you your name. Don't just change the subject.",
    ["semantic.social.self_reflection"] =
        "Don't talk about yourself like that.",
    ["semantic.question.location"] =
        "I know where they are, but not exactly.",
    ["semantic.question.location_unknown"] = "I don't know where they are.",
    ["semantic.question.seen_yes"] = "Yes, I saw them.",
    ["semantic.question.seen_no"] = "No, I haven't seen them.",
    ["semantic.question.seen_unknown"] =
        "I don't know if I've seen them.",
    ["semantic.question.fact_clarification"] =
        "I'm not sure which person you mean.",
}

function Response.RegisterTextFallbacks()
    local text = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if not text or type(text.RegisterFallback) ~= "function" then
        return 0
    end
    local count = 0
    for key, fallback in pairs(LEGACY_TEXT_FALLBACKS) do
        text.RegisterFallback(key, fallback)
        count = count + 1
    end
    return count
end

Response.RegisterTextFallbacks()

local function copyArgs(values)
    local output = {}
    if type(values) ~= "table" then return output end
    local key
    local value
    for key, value in pairs(values) do output[key] = value end
    return output
end

local function socialCounts(state)
    local hostilityCount = 0
    local insultCount = 0
    local lastSpeechAct
    local events = state and type(state.Recent) == "function"
        and state:Recent(8, true) or {}
    local index
    local event
    for index = 1, #events do
        event = events[index]
        if index == 1 then lastSpeechAct = event.speechAct end
        if event.speechAct == "INSULT"
            or event.speechAct == "HOSTILE_REMARK"
            or event.speechAct == "THREATEN"
        then
            hostilityCount = hostilityCount + 1
        end
        if event.speechAct == "INSULT" then insultCount = insultCount + 1 end
    end
    return hostilityCount, insultCount, lastSpeechAct
end

local function selectorContext(ir, state, context)
    context = type(context) == "table" and context or {}
    local world = type(context.worldContext) == "table"
        and context.worldContext or {}
    local time = type(world.time) == "table" and world.time or {}
    local situation = type(context.dialogueSituation) == "table"
        and context.dialogueSituation or {}
    local npc = type(situation.npc) == "table" and situation.npc or {}
    local activity = type(npc.activity) == "table" and npc.activity or {}
    local needs = type(npc.needs) == "table" and npc.needs or {}
    local emotion = type(npc.emotion) == "table" and npc.emotion or {}
    local social = type(situation.social) == "table" and situation.social or {}
    local hostilityCount, insultCount, lastSpeechAct = socialCounts(state)
    local topic = ir and ir.extensions and ir.extensions.topic or nil
    if type(topic) == "table" then
        topic = topic.id or topic.key
    end
    return {
        npcID = context.npcID,
        currentTopic = topic or state and state.currentTopic
            or context.currentTopic,
        previousTopic = state and state.previousTopic
            or context.previousTopic,
        intent = ir and ir.intent,
        action = ir and ir.action,
        subject = ir and ir.subject,
        relationshipState = context.relationshipState
            or context.conversationRelationshipID,
        identityTrust = context.identityTrust,
        pendingRequest = state and state.pendingRequest
            or context.pendingRequest,
        worldContext = world,
        timeBand = world.timeBand or time.band or context.timeBand,
        activity = activity.id,
        busy = activity.busy,
        needType = needs.highest,
        needUrgency = needs.urgency,
        emotionType = emotion.highest,
        emotionUrgency = emotion.urgency,
        healthState = npc.healthState,
        relationshipAttitude = social.attitude,
        socialStyle = context.socialStyle or social.style,
        hostilityCount = hostilityCount,
        insultCount = insultCount,
        lastSpeechAct = lastSpeechAct,
    }
end

local function catalogResponse(poolID, ir, state, context, args)
    if not Catalog or type(Catalog.Select) ~= "function" then return nil end
    local selected = Catalog.Select(
        poolID,
        selectorContext(ir, state, context),
        tostring(state and state.sequence or 0) .. ":"
            .. tostring(ir and ir.rawText or "")
    )
    if type(selected) ~= "table" then return nil end
    return {
        templateID = selected.templateID or selected.id,
        fallback = selected.fallback,
        args = copyArgs(args),
    }
end

local function clockText(world)
    local time = world and (world.time or world)
    if type(time) == "table" and time.available == false then return nil end
    local hour = tonumber(time and (time.hour or time.hour24))
    local minute = tonumber(time and (time.minute or time.minutes)) or 0
    if hour == nil then return nil end
    hour = math.floor(hour) % 24
    local suffix = hour >= 12 and "PM" or "AM"
    local displayHour = hour % 12
    if displayHour == 0 then displayHour = 12 end
    return string.format("It's %d:%02d %s.", displayHour, minute, suffix)
end

local MONTH_NAMES = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
}

local function dayText(world)
    world = type(world) == "table" and world or {}
    local calendar = type(world.calendar) == "table" and world.calendar or {}
    local year = tonumber(calendar.year)
    local month = tonumber(calendar.month)
    local day = tonumber(calendar.day)
    if year and month and day
        and year > 0 and month >= 1 and month <= 12
        and day >= 1 and day <= 31
    then
        return "It's " .. tostring(MONTH_NAMES[math.floor(month)]) .. " "
            .. tostring(math.floor(day)) .. ", " .. tostring(math.floor(year))
            .. "."
    end
    local gameDay = tonumber(world.gameDay)
    if gameDay ~= nil then return "It's day " .. tostring(math.floor(gameDay)) .. "." end
    return nil
end

local function weatherText(world)
    local weather = world and world.weather or nil
    if type(weather) ~= "table" then return nil end
    local raining = weather.raining == true
    local foggy = weather.foggy == true
    local snowing = weather.snowing == true
    if snowing and foggy then return "It's snowing and foggy out." end
    if snowing then return "It's snowing right now." end
    if raining and foggy then return "It's raining and foggy out." end
    if raining then return "It's raining right now." end
    if foggy then return "It's foggy out." end
    if weather.raining == false or weather.foggy == false then
        return "The weather looks clear right now."
    end
    local temperature = tonumber(weather.temperatureC)
    if temperature then
        return string.format("It's about %.1f degrees out.", temperature)
    end
    return nil
end

local function identityText(context)
    local name = type(context) == "table" and (
        context.npcFullName or context.npcName
    ) or nil
    local identityState = type(context) == "table"
        and context.identityState or nil
    name = tostring(name or "")
    if identityState == "known"
        and name ~= ""
        and string.lower(name) ~= "unknown survivor"
    then
        return "I'm " .. name .. "."
    end
    return "I'm a survivor."
end

local function targetText(target, fact)
    local value = fact and fact.targetName or nil
    if value == nil and type(target) == "table" then
        value = target.name or target.text or target.value
    end
    value = tostring(value or "them")
    return value ~= "" and value or "them"
end

local function factFor(ir)
    local extensions = ir and ir.extensions or nil
    local facts = type(extensions) == "table" and extensions.facts or nil
    local subject = ir and ir.subject or nil
    local fact = type(facts) == "table" and facts[subject] or nil
    return type(fact) == "table" and fact or nil
end

local function locationText(ir, fact)
    local location = fact and fact.location or nil
    local name = targetText(ir and ir.target, fact)
    local band = location and location.distanceBand or nil
    local label = location and location.label or nil
    if label then return name .. " is at " .. tostring(label) .. "." end
    if band == "nearby" then return name .. " is nearby." end
    if band == "not_far" then
        return "I last saw " .. name .. " not far from here."
    end
    if band == "far" then return "I last saw " .. name .. " farther out." end
    return "I know where " .. name .. " is, but not exactly."
end

-- The question resolver is a pure domain spoke. These helpers are read-only
-- response utilities shared with it; the public Response.Resolve contract is
-- unchanged.
Response.Internal = Response.Internal or {}
local Internal = Response.Internal
Internal.CopyArgs = copyArgs
Internal.CatalogResponse = catalogResponse
Internal.ClockText = clockText
Internal.DayText = dayText
Internal.WeatherText = weatherText
Internal.IdentityText = identityText
Internal.TargetText = targetText
Internal.FactFor = factFor
Internal.LocationText = locationText

local function recentTurnsFrom(context, limit)
    context = type(context) == "table" and context or {}
    local dialogue = type(context.semanticDialogueContext) == "table"
        and context.semanticDialogueContext
        or type(context.semanticContextState) == "table"
        and context.semanticContextState or nil
    if not dialogue then return {} end

    local recentTurns = dialogue.recentTurns
    if type(recentTurns) ~= "table"
        and type(dialogue.RecentTurns) == "function"
    then
        recentTurns = dialogue:RecentTurns(limit or 6, true)
    end
    return type(recentTurns) == "table" and recentTurns or {}
end

Internal.RecentTurns = recentTurnsFrom

local function followsRelationshipStatusAnswer(context)
    local recentTurns = recentTurnsFrom(context, 2)
    if #recentTurns == 0 then return false end

    local responseTurn = recentTurns[1]
    -- Some callers snapshot context before recording the player's input;
    -- others record it before resolving the response. Support both orders.
    if type(responseTurn) == "table"
        and responseTurn.speaker == "player"
        and responseTurn.intent == "ACKNOWLEDGE"
    then
        responseTurn = recentTurns[2]
    end

    return type(responseTurn) == "table"
        and responseTurn.speaker == "npc"
        and responseTurn.speechAct == "ANSWER"
        and responseTurn.branch == "QUESTION_RECEIVED"
        and (responseTurn.subject == "RELATIONSHIP_STATUS"
            or responseTurn.topic == "RELATIONSHIP_STATUS")
end

local resolveQuestion = require
    "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions"

function Response.Resolve(ir, state, context, branch)
    if type(ir) ~= "table" then return nil end
    if branch == "GREET_ACKNOWLEDGED" then
        return catalogResponse("semantic.greeting", ir, state, context, {
            topic = state and state.currentTopic,
        })
    end
    if branch == "COMPLIMENT_RECEIVED" then
        return catalogResponse("semantic.compliment", ir, state, context)
    end
    if branch == "OFFER_RECEIVED" then
        return catalogResponse("semantic.offer", ir, state, context, {
            object = ir.object,
            topic = state and state.currentTopic,
        })
    end
    if branch == "GIFT_SELECTION_REQUIRED" then
        return {
            templateID = "semantic.gift.selection_required",
            fallback = "Oh? What did you bring me?",
            args = copyArgs({ object = ir.object }),
        }
    end
    if branch == "GIFT_OFFER_DISPATCHED" then
        return {
            templateID = "semantic.gift.pending",
            fallback = "",
            args = copyArgs({ object = ir.object }),
        }
    end
    if branch == "GIFT_CONSENT_DECLINED" then
        return {
            templateID = "semantic.gift.consent.declined",
            fallback = "No problem. I'll leave it with you.",
        }
    end
    if branch == "GIFT_CONSENT_AMBIGUOUS" then
        return {
            templateID = "semantic.gift.consent.ambiguous",
            fallback = "More than one of us wants it. Please offer it to one person directly.",
        }
    end
    if branch == "QUESTION_RECEIVED" and type(resolveQuestion) == "function" then
        local response = resolveQuestion(ir, state, context)
        if response then return response end
    end
    if branch == "IDENTITY_CLAIM_RECEIVED" then
        local claim = ir.slots and ir.slots.identityClaim or {}
        return {
            templateID = "semantic.identity.exchange",
            -- The authoritative identity-claim result decides whether the
            -- NPC may disclose their own name. Do not leak it before the
            -- server validates the player's claim.
            fallback = "Nice to meet you. What's your name?",
            args = copyArgs({
                playerName = claim.name,
                npcName = context and (context.npcFullName or context.npcName),
            }),
        }
    end
    if branch == "GOSSIP_RECEIVED" then
        local response = catalogResponse(
            "semantic.gossip", ir, state, context, {
                target = targetText(ir.target),
                event = ir.slots and ir.slots.information
                    and ir.slots.information.event,
            }
        )
        if response then
            local information = ir.slots and ir.slots.information or nil
            local gossip = context and context.npcGossip or nil
            local statements = type(gossip) == "table"
                and gossip.statements or nil
            local gossipLines = {}
            local index
            local line
            if type(statements) == "table" then
                for index = 1, math.min(#statements, 4) do
                    line = statements[index]
                    if type(line) == "string" and line ~= "" then
                        gossipLines[#gossipLines + 1] = line
                    end
                end
            end
            if #gossipLines > 0 then
                response.templateID = "semantic.gossip.memory"
                response.fallback = table.concat(gossipLines, " ")
                response.args = nil
                return response
            end
            if type(information) == "table"
                and information.event == "NEWS"
            then
                local target = type(ir.target) == "table"
                    and ir.target.unresolved ~= true
                    and ir.target or nil
                local name = target and targetText(target) or ""
                if name ~= "" and name ~= "them" then
                    response.fallback = "I haven't heard anything new about "
                        .. name .. " lately."
                else
                    response.fallback = "I haven't heard any news lately."
                end
            else
                local name = targetText(ir.target)
                response.fallback = "I haven't heard anything about "
                    .. name .. " yet."
            end
            return response
        end
    end
    if branch == "HOSTILE_REMARK_RECEIVED" then
        local hostilityCount = socialCounts(state)
        return catalogResponse(
            "semantic.hostile_remark", ir, state, context, {
                speechAct = ir.speechAct,
                intensity = ir.emotionalState
                    and ir.emotionalState.intensity,
                hostilityCount = hostilityCount,
            }
        )
    end
    if branch == "SELF_REFLECTION_RECEIVED" then
        return catalogResponse(
            "semantic.self_reflection", ir, state, context, {
                reflectionType = ir.socialContext
                    and ir.socialContext.reflectionType,
                relationshipState = context and context.relationshipState,
                socialStyle = context and context.socialStyle,
            }
        )
    end
    if branch == "SELF_STATE_RECEIVED" then
        return catalogResponse(
            "semantic.self_state", ir, state, context, {
                state = ir.slots and ir.slots.state,
            }
        )
    end
    if branch == "IDENTITY_NAME_EVASION" then
        return catalogResponse(
            "semantic.identity.evasion", ir, state, context, {
                relationshipState = context and context.relationshipState,
                socialStyle = context and context.socialStyle,
            }
        )
    end
    if branch == "THREAT_RECEIVED" then
        return catalogResponse("semantic.threat", ir, state, context, {
            speechAct = ir.speechAct,
        })
    end
    if branch == "SOCIAL_ACKNOWLEDGED" then
        if ir.intent == "ACKNOWLEDGE"
            and followsRelationshipStatusAnswer(context)
        then
            return catalogResponse(
                "semantic.question.relationship_status.acknowledged",
                ir,
                state,
                context
            )
        end
        if ir.intent == "THANK" then
            return catalogResponse("semantic.thanks", ir, state, context, {
                topic = state and state.currentTopic,
            })
        end
        if ir.intent == "ACCEPT" or ir.intent == "AGREE" then
            return catalogResponse("semantic.accept", ir, state, context, {
                action = state and state.pendingRequest
                    and state.pendingRequest.action,
                topic = state and state.currentTopic,
            })
        end
        if ir.intent == "REFUSE" or ir.intent == "DISAGREE" then
            return catalogResponse("semantic.refuse", ir, state, context, {
                action = state and state.pendingRequest
                    and state.pendingRequest.action,
                topic = state and state.currentTopic,
            })
        end
    end
    return nil
end

return Response

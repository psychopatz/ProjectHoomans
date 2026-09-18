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

function Response.Resolve(ir, state, context, branch)
    if type(ir) ~= "table" then return nil end
    local world = type(context) == "table" and context.worldContext or nil
    if branch == "GREET_ACKNOWLEDGED" then
        return catalogResponse("semantic.greeting", ir, state, context, {
            topic = state and state.currentTopic,
        })
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
    if branch == "QUESTION_RECEIVED" and ir.subject == "TIME" then
        local text = clockText(world)
        if text then
            return {
                templateID = "semantic.question.time",
                fallback = text,
                args = copyArgs({
                    hour = world.time and world.time.hour,
                    minute = world.time and world.time.minute,
                    gameDay = world.gameDay,
                }),
            }
        end
    end
    if branch == "QUESTION_RECEIVED" and ir.subject == "DATE" then
        local text = dayText(world)
        if text then
            local calendar = world.calendar or {}
            return {
                templateID = "semantic.question.date",
                fallback = text,
                args = copyArgs({
                    gameDay = world.gameDay,
                    year = calendar.year,
                    month = calendar.month,
                    day = calendar.day,
                }),
            }
        end
    end
    if branch == "QUESTION_RECEIVED" and ir.subject == "WEATHER" then
        local text = weatherText(world)
        return {
            templateID = "semantic.question.weather",
            fallback = text or "I can't tell what the weather's doing right now.",
            args = copyArgs({ weather = world and world.weather }),
        }
    end
    if branch == "QUESTION_RECEIVED" and ir.subject == "IDENTITY" then
        local text
        if context and context.identityTrust == "untrustworthy" then
            text = "I don't share my name with liars. What's yours, truthfully?"
        elseif context and context.identityState == "known" then
            text = identityText(context) .. " What's your name?"
        else
            text = "I'll tell you my name once we've established some trust."
                .. " What's your name?"
        end
        return {
            templateID = "semantic.question.identity",
            fallback = text,
            args = copyArgs({
                npcName = context and (context.npcFullName or context.npcName),
            }),
        }
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
    if branch == "QUESTION_RECEIVED" and ir.subject == "ACTIVITY" then
        return catalogResponse(
            "semantic.question.activity", ir, state, context, {
                activity = context and context.dialogueSituation
                    and context.dialogueSituation.npc
                    and context.dialogueSituation.npc.activity
                    and context.dialogueSituation.npc.activity.id,
            }
        )
    end
    if branch == "QUESTION_RECEIVED" and ir.subject == "WELLBEING" then
        return catalogResponse(
            "semantic.question.wellbeing", ir, state, context, {
                needType = context and context.dialogueSituation
                    and context.dialogueSituation.npc
                    and context.dialogueSituation.npc.needs
                    and context.dialogueSituation.npc.needs.highest,
            }
        )
    end
    if branch == "QUESTION_RECEIVED"
        and (ir.subject == "LOCATION" or ir.subject == "SEEN")
    then
        local fact = factFor(ir)
        if fact and fact.status == "known" then
            if ir.subject == "LOCATION" then
                return {
                    templateID = "semantic.question.location",
                    fallback = locationText(ir, fact),
                    args = copyArgs({
                        target = targetText(ir.target, fact),
                        location = fact.location,
                        freshness = fact.freshness,
                    }),
                }
            end
            if fact.value == true then
                return {
                    templateID = "semantic.question.seen_yes",
                    fallback = "Yes, I saw " .. targetText(ir.target, fact) .. ".",
                    args = copyArgs({ target = targetText(ir.target, fact) }),
                }
            end
            if fact.value == false then
                return {
                    templateID = "semantic.question.seen_no",
                    fallback = "No, I haven't seen " .. targetText(ir.target, fact) .. ".",
                    args = copyArgs({ target = targetText(ir.target, fact) }),
                }
            end
        elseif fact and fact.status == "ambiguous" then
            return {
                templateID = "semantic.question.fact_clarification",
                fallback = "I'm not sure which person you mean.",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        elseif ir.subject == "LOCATION" then
            return {
                templateID = "semantic.question.location_unknown",
                fallback = "I don't know where " .. targetText(ir.target, fact)
                    .. " is.",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        else
            return {
                templateID = "semantic.question.seen_unknown",
                fallback = "I don't know if I've seen "
                    .. targetText(ir.target, fact) .. ".",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        end
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
            local name = targetText(ir.target)
            response.fallback = "I haven't heard anything about "
                .. name .. " yet."
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
        if ir.intent == "THANK" then
            return catalogResponse("semantic.thanks", ir, state, context, {
                topic = state and state.currentTopic,
            })
        end
        if ir.intent == "ACCEPT" then
            return catalogResponse("semantic.accept", ir, state, context, {
                action = state and state.pendingRequest
                    and state.pendingRequest.action,
                topic = state and state.currentTopic,
            })
        end
        if ir.intent == "REFUSE" then
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

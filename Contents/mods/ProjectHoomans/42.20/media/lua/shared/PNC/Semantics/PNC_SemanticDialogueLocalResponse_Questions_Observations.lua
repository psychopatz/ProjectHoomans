-- Deterministic observation and social question responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local clockFacts = Internal.ClockFacts
local dayFacts = Internal.DayFacts
local weatherFacts = Internal.WeatherFacts

local function resolveNeeds(ir, state, context)
    if ir and ir.subject == "QUANTITY" then
        return catalogResponse(
            "semantic.question.needs.quantity", ir, state, context
        )
    end
    return catalogResponse(
        "semantic.question.needs.offer", ir, state, context
    )
end

local function resolveTime(world)
    local facts = clockFacts(world)
    if not facts then return nil end
    return {
        templateID = "semantic.question.time",
        args = copyArgs({
            time = facts.display,
            hour = facts.hour,
            minute = facts.minute,
            gameDay = world.gameDay,
        }),
    }
end

local function resolveDate(world)
    local facts = dayFacts(world)
    if not facts then return nil end
    if facts.gameDay ~= nil then
        return {
            templateID = "semantic.question.day",
            args = copyArgs({ gameDay = facts.gameDay }),
        }
    end
    return {
        templateID = "semantic.question.date",
        args = copyArgs({
            year = facts.year,
            month = facts.month,
            day = facts.day,
        }),
    }
end

local function resolveWeather(world)
    local facts = weatherFacts(world)
    local kind = facts and facts.kind or "unknown"
    return {
        templateID = "semantic.question.weather." .. kind,
        args = copyArgs({
            weather = world and world.weather,
            temperature = facts and facts.temperature,
        }),
    }
end

local function resolveIdentityQuestion(ir, state, context)
    if context and context.identityTrust == "untrustworthy" then
        local response = catalogResponse(
            "semantic.question.identity", ir, state, context
        )
        if response then return response end
    elseif Internal.IdentityKnown(context)
    then
        return {
            templateID = "semantic.question.identity.known",
            args = copyArgs({
                npcName = context.npcFullName or context.npcName,
            }),
        }
    else
        local response = catalogResponse(
            "semantic.question.identity", ir, state, context
        )
        if response then return response end
    end
    return {
        templateID = "semantic.question.identity",
        args = copyArgs({
            npcName = context and (context.npcFullName or context.npcName),
        }),
    }
end

local function resolveActivity(ir, state, context)
    return catalogResponse(
        "semantic.question.activity", ir, state, context, {
            activity = context and context.dialogueSituation
                and context.dialogueSituation.npc
                and context.dialogueSituation.npc.activity
                and context.dialogueSituation.npc.activity.id,
        }
    )
end

local function resolveWhatsUp(ir, state, context)
    local situation = context and context.dialogueSituation or nil
    local npc = situation and situation.npc or nil
    local activity = npc and npc.activity or nil
    local weather = context and context.worldContext
        and context.worldContext.weather or nil
    local busy = npc and npc.busy == true
        or activity and (activity.busy == true or activity.id == "working")
    return catalogResponse(
        "semantic.question.whats_up", ir, state, context, {
            subject = "CONVERSATION_TOPIC",
            activity = activity and activity.id or nil,
            busy = busy == true,
            raining = weather and weather.raining == true or false,
        }
    )
end

local function resolveWellbeing(ir, state, context)
    local extensions = type(ir.extensions) == "table" and ir.extensions or nil
    local followsWellbeingAnswer = Internal.FollowsWellbeingAnswer
    local situation = context and context.dialogueSituation
    local npc = situation and situation.npc or nil
    local needs = npc and npc.needs or nil
    local emotion = npc and npc.emotion or nil
    local healthState = npc and npc.healthState or nil
    local personality = context and context.npcPersonality
    local authoredStyle = type(personality) == "table"
        and personality.socialStyle or nil
    if extensions and extensions.dialogueFollowUp == "WELLBEING"
        and type(followsWellbeingAnswer) == "function"
        and followsWellbeingAnswer(context)
    then
        return catalogResponse(
            "semantic.question.wellbeing.follow_up", ir, state, context
        )
    end
    if type(healthState) == "string"
        and (healthState == "injured"
            or healthState == "wounded"
            or healthState == "critical")
        and (authoredStyle == "friendly"
            or authoredStyle == "protective"
            or authoredStyle == "withdrawn")
    then
        local grounded = catalogResponse(
            "semantic.question.wellbeing.grounded", ir, state, context
        )
        if grounded then return grounded end
    end
    local healthUnknown = type(healthState) ~= "string"
        or healthState == ""
        or healthState == "unknown"
    if healthUnknown
        and (type(needs) ~= "table" or needs.highest == nil)
        and (type(emotion) ~= "table" or emotion.highest == nil)
    then
        return catalogResponse(
            "semantic.question.wellbeing.unknown", ir, state, context
        )
    end
    return catalogResponse(
        "semantic.question.wellbeing", ir, state, context, {
            needType = context and context.dialogueSituation
                and context.dialogueSituation.npc
                and context.dialogueSituation.npc.needs
                and context.dialogueSituation.npc.needs.highest,
        }
    )
end

Internal.ResolveNeeds = resolveNeeds
Internal.ResolveTime = resolveTime
Internal.ResolveDate = resolveDate
Internal.ResolveWeather = resolveWeather
Internal.ResolveIdentityQuestion = resolveIdentityQuestion
Internal.ResolveActivity = resolveActivity
Internal.ResolveWhatsUp = resolveWhatsUp
Internal.ResolveWellbeing = resolveWellbeing

return Response

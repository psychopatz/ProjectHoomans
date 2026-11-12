-- Deterministic observation and social question responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local clockText = Internal.ClockText
local dayText = Internal.DayText
local weatherText = Internal.WeatherText
local identityText = Internal.IdentityText

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
    local text = clockText(world)
    if not text then return nil end
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

local function resolveDate(world)
    local text = dayText(world)
    if not text then return nil end
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

local function resolveWeather(world)
    local text = weatherText(world)
    return {
        templateID = "semantic.question.weather",
        fallback = text or "I can't tell what the weather's doing right now.",
        args = copyArgs({ weather = world and world.weather }),
    }
end

local function resolveIdentityQuestion(ir, state, context)
    local text
    if context and context.identityTrust == "untrustworthy" then
        local response = catalogResponse(
            "semantic.question.identity", ir, state, context
        )
        if response then return response end
        text = "I don't share my name with liars. What's yours, truthfully?"
    elseif Internal.IdentityKnown(context)
    then
        return {
            templateID = "semantic.question.identity.known",
            fallback = identityText(context) .. " We already know each other.",
            args = copyArgs({
                npcName = context.npcFullName or context.npcName,
                ["speaker.name"] = context.npcFullName or context.npcName,
            }),
        }
    else
        local response = catalogResponse(
            "semantic.question.identity", ir, state, context
        )
        if response then return response end
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

local function cleanIdentityFacet(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    local normalized = string.lower(value)
    if normalized == "stranger"
        or normalized == "unknown survivor"
        or normalized == "unknown"
    then
        return nil
    end
    return value
end

local function knowledgeIdentity(context)
    local knowledge = context and context.npcKnowledge or nil
    local identity = type(knowledge) == "table"
        and knowledge.identity or nil
    if type(identity) == "table" then return identity end
    local entry = context and context.entry or nil
    local snapshot = type(entry) == "table" and entry.snapshot or nil
    identity = type(snapshot) == "table" and snapshot.identity or nil
    return type(identity) == "table" and identity or {}
end

local function fullNameWithoutNickname(value)
    value = cleanIdentityFacet(value)
    if not value then return nil end
    value = string.gsub(value, "%s*%([^()]*)%)%s*$", "")
    return cleanIdentityFacet(value)
end

local function identityFacetValue(context, facet)
    local identity = knowledgeIdentity(context)
    if facet == "nickname" then
        local nickname = cleanIdentityFacet(identity.nickname)
        if nickname then return nickname end
        local visible = cleanIdentityFacet(context and context.npcName)
        local parenthetical = visible
            and string.match(visible, "%(([^()]*)%)%s*$") or nil
        if parenthetical then return cleanIdentityFacet(parenthetical) end
        if context and context.identityLevel == "nickname" then
            return visible
        end
        return nil
    end
    if facet == "surname" then
        local surname = cleanIdentityFacet(identity.surname)
            or cleanIdentityFacet(context and context.npcSurname)
        if surname then return surname end
        local fullName = fullNameWithoutNickname(
            identity.displayName or context and context.npcFullName
        )
        return fullName and cleanIdentityFacet(
            string.match(fullName, "^%S+%s+(.+)$")
        ) or nil
    end
    if facet == "faction" then
        local faction = cleanIdentityFacet(
            context and context.factionName or identity.factionName
        )
        if faction then return faction end
        local knownFaction = context and context.knownFaction
        return type(knownFaction) == "table"
            and cleanIdentityFacet(knownFaction.name) or nil
    end
    return nil
end

local function resolveIdentityFacetQuestion(facet, ir, state, context)
    local value = identityFacetValue(context, facet)
    local templateID
    local fallback
    local unknown
    if facet == "nickname" then
        templateID = value
            and "semantic.question.identity.nickname.known"
            or "semantic.question.identity.nickname.unknown"
        fallback = value
            and "Most people call me " .. value .. "."
            or "I don't share what people call me yet."
        unknown = "IDENTITY_NICKNAME"
    elseif facet == "surname" then
        templateID = value
            and "semantic.question.identity.surname.known"
            or "semantic.question.identity.surname.unknown"
        fallback = value
            and "My surname is " .. value .. "."
            or "I keep my surname private for now."
        unknown = "IDENTITY_SURNAME"
    else
        templateID = value
            and "semantic.question.identity.faction.known"
            or "semantic.question.identity.faction.unknown"
        fallback = value
            and "I'm with " .. value .. "."
            or "I don't share who I'm with yet."
        unknown = "IDENTITY_FACTION"
    end
    return {
        templateID = templateID,
        fallback = fallback,
        args = copyArgs({
            nickname = facet == "nickname" and value or nil,
            surname = facet == "surname" and value or nil,
            factionName = facet == "faction" and value or nil,
        }),
        dialogueAct = "FACT_ANSWER",
        topic = unknown,
        uncertainty = value and "known" or "unknown",
        groundedFactRefs = value and { "identity." .. facet } or {},
        selectionSource = "identity_knowledge",
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
Internal.ResolveIdentityFacetQuestion = resolveIdentityFacetQuestion
Internal.ResolveActivity = resolveActivity
Internal.ResolveWhatsUp = resolveWhatsUp
Internal.ResolveWellbeing = resolveWellbeing

return Response

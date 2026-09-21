-- Pure response mapping for semantic questions. The shared resolver supplies
-- presentation-safe helpers; this module reads only the IR and world snapshot.
local PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local clockText = Internal.ClockText
local dayText = Internal.DayText
local weatherText = Internal.WeatherText
local identityText = Internal.IdentityText
local targetText = Internal.TargetText
local factFor = Internal.FactFor
local locationText = Internal.LocationText

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
    elseif context and context.identityState == "known"
        and context.identityClaimVerified == true
    then
        text = identityText(context) .. " What's your name?"
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

local function resolveWellbeing(ir, state, context)
    return catalogResponse(
        "semantic.question.wellbeing", ir, state, context, {
            needType = context and context.dialogueSituation
                and context.dialogueSituation.npc
                and context.dialogueSituation.npc.needs
                and context.dialogueSituation.npc.needs.highest,
        }
    )
end

local function isCommittedRelation(value)
    if type(value) ~= "string" then return false end
    value = string.lower(value)
    value = string.gsub(value, "[%s%-]", "_")
    value = string.gsub(value, "[^%w_]", "")
    return value == "lover" or value == "partner" or value == "spouse"
end

local function hasKnownCurrentPartner(context)
    context = type(context) == "table" and context or {}
    local relationship = type(context.relationship) == "table"
        and context.relationship or {}
    local npcRecord = type(context.npcRecord) == "table"
        and context.npcRecord or {}
    local npcGeneration = type(npcRecord.generation) == "table"
        and npcRecord.generation or {}
    local entry = type(context.entry) == "table" and context.entry or {}
    local entryRecord = type(entry.record) == "table" and entry.record or {}
    local entryGeneration = type(entryRecord.generation) == "table"
        and entryRecord.generation or {}

    return isCommittedRelation(context.relationshipState)
        or isCommittedRelation(context.conversationRelationshipID)
        or isCommittedRelation(context.relationshipKind)
        or isCommittedRelation(context.conversationRelationship)
        or isCommittedRelation(relationship.category)
        or isCommittedRelation(relationship.status)
        or isCommittedRelation(relationship.relationshipKind)
        or isCommittedRelation(relationship.relationshipState)
        or isCommittedRelation(npcGeneration.relationshipKind)
        or isCommittedRelation(entryGeneration.relationshipKind)
end

local function followsRecentCompliment(context)
    local recentTurns = type(Internal.RecentTurns) == "function"
        and Internal.RecentTurns(context, 2) or {}
    if type(recentTurns) ~= "table" or #recentTurns < 2 then
        return false
    end

    local npcReply = recentTurns[1]
    local playerCompliment = recentTurns[2]
    return type(npcReply) == "table"
        and npcReply.speaker == "npc"
        and npcReply.speechAct == "COMPLIMENT_RESPONSE"
        and type(playerCompliment) == "table"
        and playerCompliment.speaker == "player"
        and (playerCompliment.intent == "COMPLIMENT"
            or playerCompliment.speechAct == "COMPLIMENT")
end

local function resolveRelationshipStatus(ir, state, context)
    local followsCompliment = followsRecentCompliment(context)
    if hasKnownCurrentPartner(context) then
        if followsCompliment then
            local response = catalogResponse(
                "semantic.question.relationship_status.committed_after_compliment",
                ir,
                state,
                context
            )
            if response then return response end
        end
        return catalogResponse(
            "semantic.question.relationship_status.committed",
            ir,
            state,
            context
        ) or {
            templateID = "semantic.question.relationship_status.committed",
            fallback = "I thought we were already together.",
        }
    end

    if followsCompliment then
        local response = catalogResponse(
            "semantic.question.relationship_status.unknown_after_compliment",
            ir,
            state,
            context
        )
        if response then return response end
    end

    -- A missing partner fact is not evidence that the NPC is single. Keep the
    -- deterministic answer open-ended until the character has an authored or
    -- authoritative relationship status.
    return catalogResponse(
        "semantic.question.relationship_status.unknown",
        ir,
        state,
        context
    ) or {
        templateID = "semantic.question.relationship_status.uncertain",
        fallback = "I haven't really thought about dating. Right now, I'm focused on surviving.",
    }
end

local function resolveLocationOrSeen(ir)
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

return function(ir, state, context)
    if type(ir) ~= "table" then return nil end
    local world = type(context) == "table" and context.worldContext or nil
    if ir.subject == "TIME" then return resolveTime(world) end
    if ir.subject == "DATE" then return resolveDate(world) end
    if ir.subject == "WEATHER" then return resolveWeather(world) end
    if ir.subject == "IDENTITY" then
        return resolveIdentityQuestion(ir, state, context)
    end
    if ir.subject == "RELATIONSHIP_STATUS" then
        return resolveRelationshipStatus(ir, state, context)
    end
    if ir.subject == "ACTIVITY" then
        return resolveActivity(ir, state, context)
    end
    if ir.subject == "WELLBEING" then
        return resolveWellbeing(ir, state, context)
    end
    if ir.subject == "LOCATION" or ir.subject == "SEEN" then
        return resolveLocationOrSeen(ir)
    end
    return nil
end

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

local function resolveIdentityQuestion(context)
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
    if ir.subject == "IDENTITY" then return resolveIdentityQuestion(context) end
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

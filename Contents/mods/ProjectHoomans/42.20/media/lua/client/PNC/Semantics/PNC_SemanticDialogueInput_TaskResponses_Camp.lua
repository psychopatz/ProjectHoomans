-- Pure camp-site result projection and response wording.
local CampResponses = {}

local function textValue(value)
    local valueType = type(value)
    if value == nil or valueType == "table" or valueType == "function"
        or valueType == "thread"
    then
        return nil
    end
    value = tostring(value)
    return value ~= "" and value or nil
end

local function firstValue(...)
    local count = select("#", ...)
    for index = 1, count do
        local value = textValue(select(index, ...))
        if value then return value end
    end
    return nil
end

-- Prefer authoritative server details over the bounded client observation
-- retained in the pending request.
function CampResponses.CampSiteDetails(primary, secondary)
    local output = {}

    local function read(value)
        if type(value) ~= "table" then return end
        local details = type(value.details) == "table"
            and value.details or nil
        local site = details and type(details.site) == "table"
            and details.site or nil
        local request = type(value.request) == "table"
            and value.request or nil
        local target = request and type(request.target) == "table"
            and request.target or nil
        target = target or type(value.target) == "table"
            and value.target or nil
        local intent = type(value.actionIntent) == "table"
            and value.actionIntent or nil
        target = target or intent and type(intent.target) == "table"
            and intent.target or nil
        local hint = target and type(target.clientHint) == "table"
            and target.clientHint or nil

        output.label = output.label or firstValue(
            value.siteLabel,
            details and details.siteLabel,
            site and site.label,
            value.label,
            hint and hint.label
        )
        output.scope = output.scope or firstValue(
            value.siteScope,
            details and details.siteScope,
            site and (site.siteScope or site.scope),
            value.scope,
            hint and (hint.siteScope or hint.scope)
        )
        output.siteID = output.siteID or firstValue(
            value.siteID,
            details and details.siteID,
            site and site.siteID,
            value.campfireID,
            hint and (hint.siteID or hint.campfireID)
        )
        output.roomType = output.roomType or firstValue(
            value.siteRoomType,
            value.roomType,
            details and (details.siteRoomType or details.roomType),
            site and site.roomType,
            hint and hint.roomType
        )
        output.risk = output.risk or firstValue(
            value.siteRisk,
            value.risk,
            details and (details.siteRisk or details.risk),
            site and site.risk,
            hint and hint.risk
        )
    end

    read(primary)
    read(secondary)
    if not output.label and not output.scope and not output.siteID
        and not output.roomType and not output.risk
    then
        return nil
    end
    return output
end

local function withArticle(label)
    local lowered = string.lower(label)
    if string.sub(lowered, 1, 4) == "the " then return label end
    return "the " .. label
end

function CampResponses.CampLocationPhrase(details)
    local label = details and textValue(details.label)
    if not label then return nil end
    local lowered = string.lower(label)
    local scope = string.lower(tostring(details.scope or ""))
    if scope == "campfire" or lowered == "campfire" then
        return "by " .. withArticle(label)
    end
    if scope == "room" then
        return "in " .. withArticle(label)
    end
    return "at " .. withArticle(label)
end

function CampResponses.CampResponseFor(primary, secondary, phase)
    local details = CampResponses.CampSiteDetails(primary, secondary)
    local location = CampResponses.CampLocationPhrase(details)
    if not location then
        if phase == "completed" then
            return "We're set up at the safe place."
        end
        return nil
    end
    if phase == "completed" then
        return "We're set up " .. location .. "."
    end
    if phase == "pending" then
        return "I'll head " .. location .. " and set up camp."
    end
    return "I'll set up camp " .. location .. "."
end

function CampResponses.FailureResponse(reason)
    reason = string.lower(tostring(reason or ""))
    if reason == "camp_no_visible_site"
        or string.find(reason, "camp_site_hint", 1, true)
    then
        return "I don't see a safe place to camp nearby."
    end
    if string.find(reason, "no_safe_room", 1, true)
        or string.find(reason, "no_room_or_campfire", 1, true)
    then
        return "I don't see a safe place to camp nearby."
    end
    if string.find(reason, "room_not_found", 1, true) then
        return "I can't find a safe room like that nearby."
    end
    if string.find(reason, "campfire", 1, true) then
        return "There isn't a usable campfire nearby."
    end
    return nil
end

return CampResponses

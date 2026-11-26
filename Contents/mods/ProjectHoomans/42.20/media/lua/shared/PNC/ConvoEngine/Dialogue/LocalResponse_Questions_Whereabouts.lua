-- Generic community-role whereabouts response realization.
--
-- The fact is supplied by the authoritative Hoomans cognition projection.
-- This spoke chooses a normal response-catalog variant; it does not inspect
-- excursions or mutate movement state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Response = PNC.ConvoEngine.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local factFor = Internal.FactFor

local function roleValue(value, fallback)
    if type(value) ~= "table" then return fallback end
    local role = value.roleLabel or value.role
    role = tostring(role or "")
    return role ~= "" and role or fallback
end

local function etaText(value, context)
    local expected = tonumber(value and value.expectedReturnAt)
    local world = type(context) == "table" and context.worldContext or nil
    local now = tonumber(world and (
        world.worldAgeHours or world.ageHours
    ))
    local remaining
    if expected == nil or now == nil then return nil end
    remaining = expected - now
    if remaining <= 24 then return "later today" end
    if remaining <= 48 then return "tomorrow" end
    return "in a few days"
end

local function fallbackResponse(role, fact, value, context)
    local destination = value and value.destinationName
    local direction = value and (
        value.directionLabel or value.direction8
    )
    local eta = etaText(value, context)
    local status = value and (value.status or value.phase) or "unknown"
    local fallback
    if destination and direction then
        fallback = "Our " .. role .. " is at " .. destination
            .. ", " .. direction .. " of here."
        if eta then fallback = fallback .. " They should be back " .. eta .. "." end
    elseif status == "preparing" or value and value.phase == "PREPARING" then
        fallback = "Our " .. role .. " is preparing to leave."
    elseif status == "returning" or value and value.phase == "RETURNING_HOME" then
        fallback = "Our " .. role .. " is on the way home."
    elseif status == "away" then
        fallback = "Our " .. role .. " is away right now."
    elseif status == "home" then
        fallback = "Our " .. role .. " is here."
    else
        fallback = "I don't know where our " .. role .. " is."
    end
    return {
        templateID = "semantic.question.community_role_whereabouts." .. status,
        fallback = fallback,
        args = copyArgs({
            role = role,
            destination = destination,
            direction = direction,
            eta = eta,
            state = value and value.phase,
            factStatus = fact and fact.status or "unknown",
        }),
        sourcePoolID = "semantic.question.community_role_whereabouts",
        dialogueAct = "FACT_ANSWER",
        topic = "COMMUNITY_ROLE_WHEREABOUTS",
        groundedFactRefs = { "community.excursion.role_whereabouts" },
        uncertainty = fact and fact.status or "unknown",
        tone = "direct",
        selectionSource = "fact_provider",
    }
end

local function resolveCommunityRoleWhereabouts(ir, state, context)
    local fact = factFor(ir)
    local value = fact and fact.value
    local role = roleValue(value, "trader")
    local destination = type(value) == "table"
        and value.destinationName or nil
    local direction = type(value) == "table" and (
        value.directionLabel or value.direction8
    ) or nil
    local eta = etaText(value, context)
    local status = type(value) == "table"
        and string.lower(tostring(value.status or "")) or ""
    local phase = type(value) == "table"
        and tostring(value.phase or "") or ""
    local poolID
    local response

    if not fact or fact.status ~= "known" then
        poolID = "semantic.question.community_role_whereabouts.unknown"
    elseif destination and direction then
        poolID = eta
            and "semantic.question.community_role_whereabouts.visiting_eta"
            or "semantic.question.community_role_whereabouts.visiting"
    elseif phase == "PREPARING" or status == "preparing" then
        poolID = "semantic.question.community_role_whereabouts.preparing"
    elseif phase == "RETURNING_HOME" or status == "returning" then
        poolID = "semantic.question.community_role_whereabouts.returning"
    elseif status == "away" then
        poolID = "semantic.question.community_role_whereabouts.away"
    elseif status == "home" or phase == "AT_HOME" then
        poolID = "semantic.question.community_role_whereabouts.home"
    else
        poolID = "semantic.question.community_role_whereabouts.unknown"
    end

    response = catalogResponse(poolID, ir, state, context, {
        role = role,
        destination = destination,
        direction = direction,
        eta = eta,
        state = phase,
        factStatus = fact and fact.status or "unknown",
    })
    if response then
        response.dialogueAct = response.dialogueAct or "FACT_ANSWER"
        response.topic = response.topic or "COMMUNITY_ROLE_WHEREABOUTS"
        response.groundedFactRefs = response.groundedFactRefs
            or { "community.excursion.role_whereabouts" }
        response.selectionSource = response.selectionSource or "fact_provider"
        return response
    end
    return fallbackResponse(role, fact, value, context)
end

local function resolveCurrentLocation(ir, state, context)
    local okLoc, locResolver = pcall(require, "PNC/ConvoEngine/Dialogue/CurrentLocationResolver")
    local resolver = (okLoc and type(locResolver) == "table" and locResolver)
        or (PNC.ConvoEngine and PNC.ConvoEngine.CurrentLocationResolver)
    local npcRecord = type(context) == "table" and (
        context.npcRecord
        or (type(context.entry) == "table" and (context.entry.record or context.entry))
        or {
            id = context.npcID,
            identitySeed = context.npcIdentitySeed,
            npcType = context.npcType,
            hometown = context.hometown,
            spawnTown = context.spawnTown,
        }
    ) or nil
    local loc, fam
    if resolver and type(resolver.ResolveForNPC) == "function" then
        loc, fam = resolver.ResolveForNPC(npcRecord, context)
    elseif resolver and type(resolver.ResolveForContext) == "function" then
        loc = resolver.ResolveForContext(context)
        fam = { level = "familiar", familiar = true, isHometown = false }
    else
        loc = { known = false }
        fam = { level = "unfamiliar", familiar = false }
    end

    local known = loc and loc.known == true and tostring(loc.phrase or "") ~= ""
    local immediate = loc and tostring(loc.immediatePhrase or "") or ""
    local poolID
    if not known then
        poolID = "semantic.question.current_location.unknown"
    elseif fam and fam.level == "local" and fam.isHometown == true then
        poolID = "semantic.question.current_location.local"
    elseif fam and fam.familiar == false then
        poolID = immediate ~= "" and "semantic.question.current_location.unfamiliar_room"
            or "semantic.question.current_location.unfamiliar"
    else
        poolID = "semantic.question.current_location"
    end

    local args = {
        ["location.phrase"] = known and loc.phrase or "",
        ["location.immediate"] = immediate,
        location = known and loc.phrase or "",
        town = loc and loc.townName or nil,
        room = loc and loc.roomLabel or nil,
        zone = loc and loc.zoneLabel or nil,
        familiarity = fam and fam.level or "unknown",
        hometown = fam and fam.hometown or nil,
    }
    local response = catalogResponse(poolID, ir, state, context, args)
    if response then
        if type(response.fallback) == "string" then
            if known then
                response.fallback = string.gsub(response.fallback, "{location%.phrase}", function()
                    return tostring(loc.phrase)
                end)
            end
            if immediate ~= "" then
                response.fallback = string.gsub(response.fallback, "{location%.immediate}", function()
                    return immediate
                end)
            end
        end
        return response
    end
    local fallbackLine
    if not known then
        fallbackLine = "Honestly, I'm not completely sure where we are right now."
    elseif fam and fam.familiar == false then
        fallbackLine = immediate ~= ""
            and ("We're " .. immediate .. ", though I'm not really familiar with this town.")
            or "Honestly, I'm not from around here—I don't really know this area."
    else
        fallbackLine = "We're " .. tostring(loc.phrase) .. "."
    end
    return {
        templateID = poolID,
        fallback = fallbackLine,
        args = copyArgs(args),
        sourcePoolID = poolID,
        dialogueAct = "FACT_ANSWER",
        topic = "CURRENT_LOCATION",
        tone = "direct",
    }
end

Internal.ResolveCommunityRoleWhereabouts = resolveCommunityRoleWhereabouts
Internal.ResolveCurrentLocation = resolveCurrentLocation

return Response

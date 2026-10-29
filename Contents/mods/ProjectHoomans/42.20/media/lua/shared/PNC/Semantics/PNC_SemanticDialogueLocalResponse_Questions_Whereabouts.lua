-- Generic community-role whereabouts response realization.
--
-- The fact is supplied by the authoritative Hoomans cognition projection.
-- This spoke chooses a normal response-catalog variant; it does not inspect
-- excursions or mutate movement state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
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
    return response or fallbackResponse(role, fact, value, context)
end

Internal.ResolveCommunityRoleWhereabouts = resolveCommunityRoleWhereabouts

return Response

--[[
    PNC Navigation Router

    Selects a navigation provider while PathService remains the single movement
    coordinator. A provider may adjust a steering target or ask PathService for
    a bounded native-engine movement handoff.

    The direct provider is intentionally a no-op fallback. Meaningful movement
    uses the native engine controller across local, travel, and combat
    policies. SP may retain allocation-free sub-tile corrections; MP always
    keeps a single client-native movement owner.
]]

PNC = PNC or {}
PNC.NavigationRouter = PNC.NavigationRouter or {}

local Router = PNC.NavigationRouter

Router.Providers = Router.Providers or {}
Router.Policies = Router.Policies or {}
Router.DIRECT_PROVIDER = "direct"

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function ensureState(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    record.runtime.navigationRouter = record.runtime.navigationRouter or {}
    return record.runtime.navigationRouter
end

local function clearProvider(record, providerName)
    local provider = Router.Providers[providerName]
    if provider and provider.Clear then
        provider.Clear(record)
    end
end

function Router.RegisterProvider(name, provider)
    name = tostring(name or "")
    if name == "" or type(provider) ~= "table"
        or type(provider.GetSteeringTarget) ~= "function"
    then
        return false
    end
    Router.Providers[name] = provider
    return true
end

function Router.RegisterPolicy(name, specification)
    name = tostring(name or "")
    if name == "" or type(specification) ~= "table" then
        return false
    end
    Router.Policies[name] = specification
    return true
end

local function isCombatRequest(record, reason)
    local behavior = lower(record and record.activeBehavior)
    local job = lower(record and record.activeJob)
    local value = lower(reason)
    local runtime = record and record.runtime or nil
    local retreat = record and record.runtime
        and record.runtime.combatRetreat or nil
    if behavior:find("combat", 1, true)
        or job:find("engage", 1, true)
        or job:find("hunt", 1, true)
        or (
            runtime
            and runtime.target ~= nil
            and lower(runtime.combatBlockReason)
                :find("engaging", 1, true) == 1
        )
        or (retreat and retreat.phase == "retreat")
    then
        return true
    end
    return value:find("combat", 1, true) ~= nil
        or value:find("retreat", 1, true) ~= nil
        or value:find("kiting", 1, true) ~= nil
        or value:find("horde", 1, true) ~= nil
        or value:find("maintaining_range", 1, true) ~= nil
        or value:find("closing_to_", 1, true) ~= nil
        or value:find("disengage", 1, true) ~= nil
        or value:find("avoiding_threat", 1, true) ~= nil
end

local function inferPolicy(record, reason)
    if isCombatRequest(record, reason) then
        return "combat"
    end
    if lower(reason):find("journey:", 1, true) == 1
        or lower(record and record.activeBehavior):find("travel:", 1, true) == 1
    then
        return "travel"
    end
    return "local"
end

function Router.Resolve(record, reason, options, body)
    local requested = options and (
        options.navigationPolicy or options.policy
    ) or nil
    local policyName = tostring(requested or inferPolicy(record, reason))
    local policy = Router.Policies[policyName] or Router.Policies["local"]
        or { provider = Router.DIRECT_PROVIDER }
    local providerName = tostring(
        policy.provider or Router.DIRECT_PROVIDER
    )
    local fallbackReason
    local planner = PNC.EnginePathPlanner
    if providerName == "engine_path"
        and planner
        and planner.CanUseNativePath
    then
        local nativeSafe
        nativeSafe, fallbackReason =
            planner.CanUseNativePath(body)
        if not nativeSafe then
            providerName = Router.DIRECT_PROVIDER
        end
    end
    local state = ensureState(record)
    if state and (
        state.policy ~= policyName or state.provider ~= providerName
    ) then
        if state.provider then
            clearProvider(record, state.provider)
        end
        state.policy = policyName
        state.provider = providerName
        state.switches = (tonumber(state.switches) or 0) + 1
    end
    if state then
        state.lastFallbackReason = fallbackReason
    end
    return policyName, providerName, policy
end

function Router.GetSteeringTarget(
    record,
    body,
    finalTarget,
    policyName,
    providerName,
    policy
)
    local provider
    local state
    local steeringTarget
    if providerName == Router.DIRECT_PROVIDER then
        return finalTarget
    end
    provider = Router.Providers[providerName]
    if not provider then
        return finalTarget
    end
    state = ensureState(record)
    if state then
        state.providerCalls = (tonumber(state.providerCalls) or 0) + 1
    end
    steeringTarget = provider.GetSteeringTarget(
        record,
        body,
        finalTarget,
        policy or Router.Policies[policyName]
    )
    return steeringTarget or finalTarget
end

function Router.Clear(record)
    local state = record and record.runtime
        and record.runtime.navigationRouter or nil
    if state and state.provider then
        clearProvider(record, state.provider)
    end
    if record and record.runtime then
        record.runtime.navigationRouter = nil
    end
end

function Router.Invalidate(record, reason)
    local state = record and record.runtime
        and record.runtime.navigationRouter or nil
    local provider = state and Router.Providers[state.provider] or nil
    local invalidated = false
    if provider and provider.Invalidate then
        invalidated = provider.Invalidate(record, reason) == true
    elseif provider and provider.Clear then
        provider.Clear(record)
        invalidated = true
    end
    if state then
        state.invalidations =
            (tonumber(state.invalidations) or 0) + 1
        state.lastInvalidationReason = reason
    end
    return invalidated
end

Router.RegisterProvider("engine_path", {
    GetSteeringTarget = function(record, body, finalTarget, policy)
        local planner = PNC.EnginePathPlanner
        if not planner or not planner.GetSteeringTarget then
            return finalTarget
        end
        return planner.GetSteeringTarget(
            record,
            body,
            finalTarget,
            policy
        )
    end,
    Clear = function(record)
        local planner = PNC.EnginePathPlanner
        if planner and planner.Clear then
            planner.Clear(record)
        end
    end,
    Invalidate = function(record, reason)
        local planner = PNC.EnginePathPlanner
        return planner and planner.Invalidate
            and planner.Invalidate(record, reason) or false
    end,
})

Router.RegisterPolicy("direct", {
    provider = Router.DIRECT_PROVIDER,
})
Router.RegisterPolicy("combat", {
    provider = "engine_path",
})
Router.RegisterPolicy("local", {
    provider = "engine_path",
})
Router.RegisterPolicy("travel", {
    provider = "engine_path",
})

return Router

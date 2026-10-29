if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

-- Generic purpose-agnostic destination selection for mobile groups whose
-- persisted mobility intent is commercial. Hoomans owns candidate discovery,
-- safety, reachability, travel, and visit lifecycle. External consumers may
-- add only a bounded opportunity score.

PNC = PNC or {}
PNC.CommercialMobilityService = PNC.CommercialMobilityService or {}

local Service = PNC.CommercialMobilityService
local Constants = PNC.FactionConstants
local Config = PNC.DirectorConfig
local Factions = PNC.Factions
local MobileDirector = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local MAX_SCORERS = 8
local MAX_DIAGNOSTICS = 32

Service.OpportunityScorers = Service.OpportunityScorers or {}
Service.Diagnostics = Service.Diagnostics or {}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function clamp(value, low, high, fallback)
    value = finite(value, fallback)
    return math.max(low, math.min(high, value))
end

local function worldAge(value)
    if value ~= nil then return math.max(0, finite(value, 0)) end
    return H and H.WorldAge and H.WorldAge() or 0
end

local function copy(value)
    return H and H.Copy and H.Copy(value) or value
end

local function diagnostic(kind, name, reason)
    local entries = Service.Diagnostics
    entries[#entries + 1] = {
        kind = tostring(kind or "unknown"),
        name = tostring(name or ""),
        reason = tostring(reason or ""),
        at = worldAge(),
    }
    while #entries > MAX_DIAGNOSTICS do table.remove(entries, 1) end
end

local function scorerIndex(name)
    for index = 1, #Service.OpportunityScorers do
        if Service.OpportunityScorers[index].name == name then
            return index
        end
    end
    return nil
end

function Service.RegisterOpportunityScorer(name, scorer)
    name = tostring(name or "")
    if name == "" or #name > 96 then
        return false, "scorer_name_invalid"
    end
    if type(scorer) ~= "function" then
        return false, "scorer_required"
    end
    local index = scorerIndex(name)
    if index then
        Service.OpportunityScorers[index].scorer = scorer
        return true, "scorer_replaced"
    end
    if #Service.OpportunityScorers >= MAX_SCORERS then
        diagnostic("registration", name, "scorer_limit")
        return false, "scorer_limit"
    end
    Service.OpportunityScorers[#Service.OpportunityScorers + 1] = {
        name = name,
        scorer = scorer,
    }
    return true, "scorer_registered"
end

function Service.GetDiagnostics(limit)
    local output = {}
    local requested = math.max(0, math.floor(tonumber(limit)
        or #Service.Diagnostics))
    local first = math.max(1, #Service.Diagnostics - requested + 1)
    for index = first, #Service.Diagnostics do
        output[#output + 1] = copy(Service.Diagnostics[index])
    end
    return output
end

local function targetKey(target)
    return tostring(target and (target.communityID or target.locationID) or "")
end

local function historyKey(entry)
    return tostring(entry and (entry.communityID or entry.locationID) or "")
end

local function onCooldown(faction, target, at, options)
    if type(options) == "table"
        and type(options.cooldown) == "function"
    then
        local ok, result = pcall(options.cooldown, copy(target), at)
        if ok and result == true then return true end
        if not ok then
            diagnostic("cooldown", "external", result)
            return true
        end
    end
    local wanted = targetKey(target)
    local history = faction.mobile and faction.mobile.settlementHistory or {}
    for _, entry in ipairs(history) do
        if historyKey(entry) == wanted
            and finite(entry.cooldownUntil, 0) > at
        then
            return true
        end
    end
    return false
end

local function isEligibleFaction(faction, at, options)
    local mobile = faction and faction.mobile or nil
    if type(options) == "table" and options.resident == true then
        if not faction or faction.status ~= "active" then
            return false, "resident_faction_not_active"
        end
        if mobile then
            return false, "resident_faction_is_mobile"
        end
        return true, "resident_eligible"
    end
    if not faction or faction.status ~= "active"
        or not mobile or mobile.active ~= true
        or tostring(mobile.mobilityIntent or "")
            ~= tostring(Constants.MOBILE_MOBILITY_INTENT_COMMERCIAL)
        or mobile.controlMode ~= Constants.MOBILE_CONTROL_STRATEGIC
        or mobile.pathMode == Constants.MOBILE_PATH_PLAYER
        or mobile.travel or mobile.pendingSettlementArrival
    then
        return false, "commercial_mobility_not_eligible"
    end
    if mobile.visit
        and finite(mobile.visit.expiresAt, 0) > at
    then
        return false, "commercial_visit_active"
    end
    if mobile.activity ~= nil
        and mobile.activity
            ~= Constants.MOBILE_ACTIVITY_STREET_ROAMING
    then
        return false, "commercial_activity_busy"
    end
    return true, "eligible"
end

local function safeTarget(faction, target, at, options)
    local locations = PNC.AbstractLocations
    local visitService = PNC.MobileSettlementVisitService
    local location
    local eligible
    local reason
    if type(target) ~= "table" or not target.locationID
        or not locations or type(locations.Get) ~= "function"
    then
        return false, "settlement_target_unreachable"
    end
    location = locations.Get(target.locationID)
    if not location then return false, "settlement_target_unreachable" end
    if finite(location.danger, 0)
        > finite(Config and Config.COMMERCIAL_MAX_DESTINATION_DANGER, 70)
    then
        return false, "settlement_target_too_dangerous"
    end
    if location.tags and (location.tags.HOSTILE == true
        or location.tags.UNSAFE == true)
    then
        return false, "settlement_target_unsafe"
    end
    if not visitService
        or type(visitService.IsSettlementVisitEligible) ~= "function"
    then
        return false, "settlement_visit_service_unavailable"
    end
    eligible, reason = visitService.IsSettlementVisitEligible(
        faction,
        target,
        at,
        type(options) == "table" and options.resident == true
            and { allowResident = true } or nil
    )
    if not eligible then return false, reason end
    return true, "eligible", location
end

local function baseScore(target)
    local distance = math.sqrt(math.max(0,
        finite(target and target.distanceSq, 0)))
    local danger = finite(target and target.danger, 0)
    return clamp(50 - distance * 0.01 - danger * 0.4,
        -50, 50, 0), distance
end

local function scorerValue(value)
    if type(value) == "table" then value = value.score end
    if value == nil or value == false then return 0 end
    return clamp(value, -25, 25, 0)
end

function Service.SelectDestination(factionOrID, at, options)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions and Factions.Get and Factions.Get(factionOrID)
    local candidates = {}
    local selected
    local selectedScore
    local eligibilityReason
    local now = worldAge(at)
    options = type(options) == "table" and options or {}
    if not H or type(H.ResolveSettlementDepartureTargets) ~= "function" then
        return nil, "settlement_target_resolver_unavailable", candidates
    end
    if not faction then return nil, "faction_not_found", candidates end
    local eligible
    eligible, eligibilityReason = isEligibleFaction(faction, now, options)
    if not eligible then return nil, eligibilityReason, candidates end
    local raw = H.ResolveSettlementDepartureTargets(faction, {
        commercial = true,
        origin = options.origin,
        excludeCommunityID = options.excludeCommunityID,
        candidateLimit = Config
            and Config.COMMERCIAL_DESTINATION_CANDIDATE_LIMIT
            or Constants.COMMERCIAL_DESTINATION_CANDIDATE_LIMIT or 16,
    })
    local seen = {}
    for _, target in ipairs(raw or {}) do
        local key = targetKey(target)
        if not seen[key] and not onCooldown(faction, target, now, options) then
            seen[key] = true
            local safe, reason, location = safeTarget(
                faction, target, now, options)
            if safe then
                target.danger = finite(location and location.danger, 0)
                local score, distance = baseScore(target)
                local economic = 0
                local context = {
                    at = now,
                    distance = distance,
                    distanceSq = finite(target.distanceSq, 0),
                    baseScore = score,
                    opportunityScore = 0,
                }
                for index = 1, #Service.OpportunityScorers do
                    local registration = Service.OpportunityScorers[index]
                    local ok, value = pcall(
                        registration.scorer,
                        copy(faction),
                        copy(target),
                        context
                    )
                    if ok then
                        economic = economic + scorerValue(value)
                    else
                        diagnostic("scorer", registration.name, value)
                    end
                end
                context.opportunityScore = clamp(economic, -50, 50, 0)
                score = clamp(score + context.opportunityScore,
                    -100, 100, 0)
                target = copy(target)
                target.baseScore = context.baseScore
                target.opportunityScore = context.opportunityScore
                target.score = score
                target.distance = distance
                candidates[#candidates + 1] = target
            elseif reason then
                diagnostic("candidate", key, reason)
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.distance ~= right.distance then
            return left.distance < right.distance
        end
        return tostring(left.locationID) < tostring(right.locationID)
    end)
    selected = candidates[1]
    selectedScore = selected and selected.score or nil
    if not selected then return nil, "no_safe_commercial_destination", candidates end
    return selected, "commercial_destination_selected", candidates
end

function Service.StartCommercialTravel(factionOrID, target, at, options)
    local faction = type(factionOrID) == "table" and factionOrID
        or Factions and Factions.Get and Factions.Get(factionOrID)
    local selected
    local reason
    options = type(options) == "table" and options or {}
    if not faction then return false, "faction_not_found" end
    if not target then
        selected, reason = Service.SelectDestination(faction, at, options)
        if not selected then return false, reason end
        target = selected
    end
    local safe, safeReason = safeTarget(
        faction, target, worldAge(at), options)
    if not safe then return false, safeReason end
    if not MobileDirector
        or type(MobileDirector.StartSettlementTravel) ~= "function"
    then
        return false, "mobile_travel_api_unavailable"
    end
    if options.resident == true then
        return false, "resident_excursion_requires_participant_travel"
    end
    return MobileDirector.StartSettlementTravel(
        faction.id,
        target,
        at,
        {
            allowNonStreetRoaming = true,
            purpose = Constants.MOBILE_TRAVEL_PURPOSE_SETTLEMENT_VISIT,
            intent = Constants.MOBILE_SETTLEMENT_VISIT_INTENT_COMMERCIAL,
            mobilityIntent = Constants.MOBILE_MOBILITY_INTENT_COMMERCIAL,
        }
    )
end

function Service.Pump(at, budget)
    local factionIDs = {}
    local moved = 0
    local now = worldAge(at)
    local scanLimit
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.COMMERCIAL_MOBILITY_BUDGET or 4))
    if not H or not H.Authority or not H.Authority() then return 0 end
    scanLimit = math.max(budget, budget * 4)
    for factionID, faction in pairs(
        Factions and Factions.Registry and Factions.Registry.byID or {}
    ) do
        if #factionIDs >= scanLimit then break end
        local eligible = isEligibleFaction(faction, now)
        if eligible then factionIDs[#factionIDs + 1] = factionID end
    end
    table.sort(factionIDs)
    for _, factionID in ipairs(factionIDs) do
        if moved >= budget then break end
        local target = Service.SelectDestination(factionID, now)
        if target then
            local started = Service.StartCommercialTravel(
                factionID,
                target,
                now
            )
            if started then moved = moved + 1 end
        end
    end
    return moved
end

Service.MAX_SCORERS = MAX_SCORERS
Service.MAX_DIAGNOSTICS = MAX_DIAGNOSTICS

return Service

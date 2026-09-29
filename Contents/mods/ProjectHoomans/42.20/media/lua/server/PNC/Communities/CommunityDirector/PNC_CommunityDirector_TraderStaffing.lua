-- Settlement trader staffing.
--
-- New settlements are staffed by PNC.CommunityDirector: the positional role
-- order gives every settler/refugee settlement a trader. Settlements that were
-- generated before that roster existed still have no trader, so this service
-- reconciles them once per world start by promoting a member that has no
-- specific job to the `trader` role.
--
-- The pass is idempotent, bounded, authority-only, and additive: it never
-- creates NPCs, never removes a member, and never changes a settlement that is
-- already staffed or too small to carry a trader.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.SettlementTraderStaffing = PNC.SettlementTraderStaffing or {}

local Staffing = PNC.SettlementTraderStaffing
local Factions = PNC.Factions
local Core = PNC.Core

-- Archetypes that are expected to keep a trader. Looter camps stay
-- coercion-only, and the mobile `trader` archetype is staffed by its own role
-- order and is skipped as a mobile group.
local ELIGIBLE_ARCHETYPES = {
    settler = true,
    refugee = true,
}

local TRADER_ROLE = "trader"
-- A roster of leader + trader + at least one other member. Smaller settlements
-- are left alone until they grow.
local MINIMUM_MEMBERS = 3
-- The role that means "no specific job", so promoting one costs no coverage.
local UNASSIGNED_ROLES = {
    civilian = true,
}
-- Bounded work per pass. Promotions are rare (one per legacy settlement), and a
-- truncated pass is reported instead of silently exceeding the budget.
local MAX_PROMOTIONS_PER_PASS = 32
-- Preference order when a settlement has no unassigned member: the least
-- specialized role is converted first.
local PROMOTION_PRIORITY = {
    "civilian", "scavenger", "cook", "farmer",
    "builder", "mechanic", "medic", "guard",
}

local function logInfo(message)
    if Core and type(Core.LogInfo) == "function" then
        Core.LogInfo(message)
    end
end

local function logWarn(message)
    if Core and type(Core.LogWarn) == "function" then
        Core.LogWarn(message)
    end
end

local function authority()
    if Core and type(Core.IsAuthority) == "function" then
        return Core.IsAuthority() == true
    end
    if not Factions or type(Factions.List) ~= "function" then
        return false
    end
    return true
end

local function worldAge(value)
    local internal = PNC.CommunityDirector
        and PNC.CommunityDirector.Internal or nil
    if internal and type(internal.WorldAge) == "function" then
        return internal.WorldAge(value)
    end
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        return math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
    end
    return 0
end

local function roleOf(member)
    return tostring(
        member and member.affiliation
            and member.affiliation.role or ""
    )
end

local function isEligible(faction)
    if type(faction) ~= "table" then return false, "faction_missing" end
    if faction.status ~= "active" then return false, "faction_not_active" end
    if not ELIGIBLE_ARCHETYPES[faction.archetypeID] then
        return false, "archetype_not_eligible"
    end
    if Factions.IsMobileGroup
        and Factions.IsMobileGroup(faction)
    then
        return false, "mobile_group"
    end
    return true
end

-- The trader of a settlement, or nil. Consumers (for example a trading mod)
-- should ask this instead of predicting role positions themselves.
function Staffing.TraderMember(factionID)
    local members
    local index
    local member
    if not Factions or type(Factions.GetMembers) ~= "function" then
        return nil
    end
    members = Factions.GetMembers(factionID)
    for index = 1, #(type(members) == "table" and members or {}) do
        member = members[index]
        if roleOf(member) == TRADER_ROLE then
            return tostring(member.npcID)
        end
    end
    return nil
end

local function memberCount(faction)
    local count = 0
    for _, _ in pairs(
        type(faction) == "table"
            and type(faction.memberIDs) == "table"
            and faction.memberIDs or {}
    ) do
        count = count + 1
    end
    return count
end

-- Deterministic candidate order: unassigned roles first, then the least
-- specialized remaining role, then the stable npc id.
local function promotionCandidate(factionID)
    local members = Factions.GetMembers(factionID)
    local candidates = {}
    local index
    local member
    local role
    local priority
    local rank = {}
    local stop = #PROMOTION_PRIORITY
    for index = 1, stop do
        rank[PROMOTION_PRIORITY[index]] = index
    end
    for index = 1, #(type(members) == "table" and members or {}) do
        member = members[index]
        role = roleOf(member)
        priority = rank[role]
        if priority or UNASSIGNED_ROLES[role] then
            candidates[#candidates + 1] = {
                npcID = tostring(member.npcID),
                priority = priority or 0,
            }
        end
    end
    table.sort(candidates, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return left.npcID < right.npcID
    end)
    return candidates[1] and candidates[1].npcID or nil
end

-- Ensure one settlement member holds the trader role. Returns
-- ok, reason where reason is one of:
--   "already_staffed", "trader_assigned", "too_small", "no_candidate",
--   "mobile_group", "archetype_not_eligible", "faction_not_active",
--   "faction_missing", "not_authority", plus the faction service's own reasons.
function Staffing.EnsureTrader(factionID, at)
    local faction
    local eligible
    local reason
    local candidate
    local ok
    local roleReason
    if not authority() then return false, "not_authority" end
    faction = Factions.Get and Factions.Get(factionID) or nil
    eligible, reason = isEligible(faction)
    if not eligible then return false, reason end
    if Staffing.TraderMember(factionID) then
        return true, "already_staffed"
    end
    if memberCount(faction) < MINIMUM_MEMBERS then
        return false, "too_small"
    end
    candidate = promotionCandidate(factionID)
    if not candidate then return false, "no_candidate" end
    if type(Factions.SetNPCRole) ~= "function" then
        return false, "role_service_unavailable"
    end
    ok, roleReason = Factions.SetNPCRole(candidate, TRADER_ROLE)
    if not ok and roleReason ~= "unchanged" then
        return false, roleReason or "trader_assignment_failed"
    end
    logInfo("settlement_trader_assigned faction=" .. tostring(factionID)
        .. " archetype=" .. tostring(faction.archetypeID)
        .. " npc=" .. tostring(candidate)
        .. " at=" .. tostring(at))
    return true, "trader_assigned"
end

-- One bounded pass over the persistent faction registry.
function Staffing.Reconcile(at)
    local summary = {
        scanned = 0,
        staffed = 0,
        alreadyStaffed = 0,
        tooSmall = 0,
        skipped = 0,
        failed = 0,
        truncated = false,
    }
    local factions
    local index
    local factionID
    local ok
    local reason
    if not authority() then
        summary.reason = "not_authority"
        return summary
    end
    at = worldAge(at)
    factions = Factions.List()
    for index = 1, #(type(factions) == "table" and factions or {}) do
        factionID = factions[index].id
        summary.scanned = summary.scanned + 1
        if summary.staffed >= MAX_PROMOTIONS_PER_PASS then
            summary.truncated = true
        else
            ok, reason = Staffing.EnsureTrader(factionID, at)
            if ok and reason == "already_staffed" then
                summary.alreadyStaffed = summary.alreadyStaffed + 1
            elseif ok then
                summary.staffed = summary.staffed + 1
            elseif reason == "too_small" then
                summary.tooSmall = summary.tooSmall + 1
            elseif reason == "no_candidate"
                or reason == "mobile_group"
                or reason == "archetype_not_eligible"
                or reason == "faction_not_active"
            then
                summary.skipped = summary.skipped + 1
            else
                summary.failed = summary.failed + 1
                logWarn("settlement_trader_failed faction="
                    .. tostring(factionID)
                    .. " reason=" .. tostring(reason))
            end
        end
    end
    if summary.staffed > 0 or summary.failed > 0 or summary.truncated then
        logInfo("settlement_trader_reconcile scanned="
            .. tostring(summary.scanned)
            .. " staffed=" .. tostring(summary.staffed)
            .. " alreadyStaffed=" .. tostring(summary.alreadyStaffed)
            .. " tooSmall=" .. tostring(summary.tooSmall)
            .. " skipped=" .. tostring(summary.skipped)
            .. " failed=" .. tostring(summary.failed)
            .. " truncated=" .. tostring(summary.truncated))
    end
    return summary
end

Staffing.MINIMUM_MEMBERS = MINIMUM_MEMBERS
Staffing.MAX_PROMOTIONS_PER_PASS = MAX_PROMOTIONS_PER_PASS
Staffing.ELIGIBLE_ARCHETYPES = ELIGIBLE_ARCHETYPES

-- Legacy settlements only need this once per world start. The pass is cheap
-- when every settlement is already staffed (one role scan per faction).
if Events and Events.OnGameStart
    and type(Events.OnGameStart.Add) == "function"
    and not Staffing.StartHookRegistered
then
    Staffing.StartHookRegistered = true
    Events.OnGameStart.Add(function()
        Staffing.Reconcile()
    end)
end

return Staffing

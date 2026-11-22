if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Factions.IsMobileGroup(factionOrID)
    local faction = type(factionOrID) == "table"
        and factionOrID or Internal.registryRecord(factionOrID)
    return type(faction) == "table"
        and type(faction.mobile) == "table"
        and faction.mobile.active == true
end

function Factions.GetMobileGroup(factionID)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return nil, "not_mobile_group"
    end
    return Internal.copy(faction.mobile)
end

-- Canonical aggregate Need state for autonomous mobile groups. This stays on
-- the existing faction record so normal faction save/load owns persistence.
function Factions.GetNeeds(factionID)
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    return Internal.copy(faction.needs)
end

local function sameNeedsValues(left, right)
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    return math.abs((tonumber(left.hunger) or 0) - (tonumber(right.hunger) or 0)) < 1e-6
        and math.abs((tonumber(left.thirst) or 0) - (tonumber(right.thirst) or 0)) < 1e-6
        and math.abs((tonumber(left.fatigue) or 0) - (tonumber(right.fatigue) or 0)) < 1e-6
end

function Factions.SetNeeds(factionID, needs, reason)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then return false, "not_mobile_group" end
    local normalized = PNC.NeedsUtils and PNC.NeedsUtils.NormalizeState
        and PNC.NeedsUtils.NormalizeState(needs, 0) or nil
    if not normalized then return false, "needs_unavailable" end
    if sameNeedsValues(faction.needs, normalized) then
        faction.needs.lastUpdateWorldAge = normalized.lastUpdateWorldAge
        return true, "unchanged", faction.needs
    end
    faction.needs = normalized
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, reason or "group_needs_updated", Internal.copy(faction.needs)
end

function Internal.mobileArchetypeAllowed(faction)
    return faction and Archetypes.SupportsMobile
        and Archetypes.SupportsMobile(faction.archetypeID) == true
end

local function sameAmbientTargetShape(left, right)
    if not left or not right then return left == right end
    return left.kind == right.kind
        and left.siteID == right.siteID
        and left.baseID == right.baseID
        and math.abs((tonumber(left.x) or 0) - (tonumber(right.x) or 0)) < 0.1
        and math.abs((tonumber(left.y) or 0) - (tonumber(right.y) or 0)) < 0.1
        and math.abs((tonumber(left.z) or 0) - (tonumber(right.z) or 0)) < 0.1
end

local function mobileChangeRequiresReconcile(previous, nextMobile)
    if type(previous) ~= "table" then return true end
    if previous.controlMode ~= nextMobile.controlMode
        or previous.pathMode ~= nextMobile.pathMode
        or previous.activity ~= nextMobile.activity
    then
        return true
    end
    local prevSiteID = previous.site and previous.site.id or nil
    local nextSiteID = nextMobile.site and nextMobile.site.id or nil
    if prevSiteID ~= nextSiteID then return true end
    if not sameAmbientTargetShape(previous.strategicTarget, nextMobile.strategicTarget) then
        return true
    end
    local prevAmb = type(previous.ambient) == "table" and previous.ambient or {}
    local nextAmb = type(nextMobile.ambient) == "table" and nextMobile.ambient or {}
    if prevAmb.objective ~= nextAmb.objective
        or prevAmb.holdForNoShelter ~= nextAmb.holdForNoShelter
        or prevAmb.phase ~= nextAmb.phase
        or not sameAmbientTargetShape(prevAmb.target, nextAmb.target)
    then
        return true
    end
    return false
end

-- In-place timestamp advance when an ambient shelter/road validation passes
-- without changing objective, target, or member behavior. Avoids full deep
-- copies, registry dirtying, and redundant FactionBehavior reconciliation.
function Factions.TouchMobileAmbientCheck(factionID, nextCheckAt)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    local ambient = faction.mobile and faction.mobile.ambient or nil
    if type(ambient) ~= "table" then
        return false, "ambient_missing"
    end
    ambient.nextCheckAt = tonumber(nextCheckAt) or ambient.nextCheckAt or 0
    return true, "ambient_check_touched"
end

function Factions.SetMobileGroup(factionID, spec, reason, options)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Internal.mobileArchetypeAllowed(faction) then
        return false, "mobile_archetype_not_allowed"
    end
    local mobile = Types.NormalizeMobileGroup(spec)
    if not mobile then return false, "invalid_mobile_group" end
    local skipCopy = type(options) == "table" and options.skipReturnCopy == true
    if Types.AreEqual(faction.mobile, mobile) then
        return true, "unchanged", skipCopy and faction.mobile or Internal.copy(faction.mobile)
    end
    local shouldReconcile = not (type(options) == "table" and options.skipReconcile == true)
        and mobileChangeRequiresReconcile(faction.mobile, mobile)
    faction.mobile = mobile
    faction.tags = faction.tags or {}
    faction.tags.mobileGroup = true
    faction.tags.mobilePathMode = mobile.pathMode
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if shouldReconcile
        and PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "mobile_group_updated")
        )
    end
    return true, "mobile_group_updated", skipCopy and faction.mobile or Internal.copy(faction.mobile)
end

function Factions.UpdateMobileGroup(factionID, patch, reason, options)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    patch = type(patch) == "table" and patch or {}
    local candidate = {}
    for key, value in pairs(faction.mobile) do
        if patch[key] == nil then
            candidate[key] = Internal.copy(value)
        end
    end
    for key, value in pairs(patch) do
        candidate[key] = Internal.copy(value)
    end
    return Factions.SetMobileGroup(
        factionID,
        candidate,
        reason or "mobile_group_updated",
        options
    )
end

function Factions.ClearMobileGroup(factionID, reason)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return true, "unchanged", nil
    end
    faction.mobile = nil
    faction.tags = faction.tags or {}
    faction.tags.mobileGroup = false
    faction.tags.mobilePathMode = nil
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "mobile_group_cleared")
        )
    end
    return true, "mobile_group_cleared", nil
end

return Factions

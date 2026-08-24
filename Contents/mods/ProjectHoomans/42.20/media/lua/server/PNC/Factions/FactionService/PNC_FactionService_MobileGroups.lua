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

function Factions.SetNeeds(factionID, needs, reason)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then return false, "not_mobile_group" end
    local normalized = PNC.NeedsUtils and PNC.NeedsUtils.NormalizeState
        and PNC.NeedsUtils.NormalizeState(needs, 0) or nil
    if not normalized then return false, "needs_unavailable" end
    faction.needs = normalized
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, reason or "group_needs_updated", Internal.copy(faction.needs)
end

function Internal.mobileArchetypeAllowed(faction)
    return faction and (
        faction.archetypeID == "looter"
        or faction.archetypeID == "trader"
        or faction.archetypeID == "refugee"
    )
end

function Factions.SetMobileGroup(factionID, spec, reason)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Internal.mobileArchetypeAllowed(faction) then
        return false, "mobile_archetype_not_allowed"
    end
    local mobile = Types.NormalizeMobileGroup(spec)
    if not mobile then return false, "invalid_mobile_group" end
    if Types.AreEqual(faction.mobile, mobile) then
        return true, "unchanged", Internal.copy(faction.mobile)
    end
    faction.mobile = mobile
    faction.tags = faction.tags or {}
    faction.tags.mobileGroup = true
    faction.tags.mobilePathMode = mobile.pathMode
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "mobile_group_updated")
        )
    end
    return true, "mobile_group_updated", Internal.copy(faction.mobile)
end

function Factions.UpdateMobileGroup(factionID, patch, reason)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    patch = type(patch) == "table" and patch or {}
    local candidate = Internal.copy(faction.mobile)
    for key, value in pairs(patch) do
        candidate[key] = Internal.copy(value)
    end
    return Factions.SetMobileGroup(
        factionID,
        candidate,
        reason or "mobile_group_updated"
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

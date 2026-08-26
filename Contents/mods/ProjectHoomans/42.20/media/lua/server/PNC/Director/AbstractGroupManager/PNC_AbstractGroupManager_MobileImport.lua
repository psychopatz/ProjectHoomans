if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractGroups = PNC.AbstractGroups or {}
PNC.AbstractGroupManagerInternal =
    PNC.AbstractGroupManagerInternal or {}

local Groups = PNC.AbstractGroups
local H = PNC.AbstractGroupManagerInternal
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Locations = PNC.AbstractLocations
local Core = PNC.Core
local Const = PNC.Const

function Groups.ImportMobileFaction(factionOrID)
    if not H.Authority() then return nil, "not_authority" end
    local faction = type(factionOrID) == "table" and factionOrID
        or PNC.Factions and PNC.Factions.Get(factionOrID) or nil
    if not faction or not PNC.Factions.IsMobileGroup(faction) then
        return nil, "not_mobile_group"
    end
    local location, reason = Locations.RegisterSite(faction.mobile.site, {
        tags = { SHELTER = true,
            SAFE = faction.archetypeID == "refugee",
            COMMERCIAL = faction.archetypeID == "trader" },
    })
    if not location then return nil, reason end
    local existing = Groups.FindByFactionID(faction.id)
    if existing then
        local ambient = faction.mobile.controlMode == "ambient"
        local objective = faction.mobile.ambient
            and faction.mobile.ambient.objective or nil
        if existing.mobileAmbient ~= ambient
            or existing.ambientObjective ~= objective
        then
            existing.mobileAmbient = ambient
            existing.ambientObjective = objective
            H.Touch(existing, "mobile_ambient_import")
        end
        Groups.ReconcileMembers(existing, faction)
        return existing, "existing"
    end
    local ids = H.MemberIDs(faction)
    local group, createReason = Groups.Create({
        id = "agroup_" .. tostring(faction.id),
        factionId = faction.id,
        homeCommunityId = nil,
        groupType = H.GroupTypeForFaction(faction),
        memberIds = ids,
        leaderId = faction.leaderNPCID,
        -- Advanced trade/migration execution is deferred. Existing mobile
        -- factions begin with the supported foundational SCAVENGE mission.
        mission = "SCAVENGE",
        state = "IDLE",
        location = Locations.Ref(location),
        resources = { food = 50, water = 50,
            ammo = faction.archetypeID == "looter" and 50 or 15,
            medical = 10, materials = 0 },
        combatProfileDirty = true,
        combatProfileReason = "mobile_faction_import",
        mobileAmbient = faction.mobile.controlMode == "ambient",
        ambientObjective = faction.mobile.ambient
            and faction.mobile.ambient.objective or nil,
        diagnostics = { memberSignature = H.MemberSignature(ids) },
    })
    if group then Groups.RefreshLOD(group, Store.WorldAgeHours()) end
    return group, createReason
end

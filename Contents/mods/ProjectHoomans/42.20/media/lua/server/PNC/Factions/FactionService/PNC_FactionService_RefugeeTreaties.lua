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
function Internal.refugeeFactionName(faction)
    local base = tostring(faction.name or "Former Survivors")
    local stripped = string.match(base, "^(.-)%s+Survivors$")
    if stripped and stripped ~= "" then base = stripped end
    if not string.match(base, "%s+Refugees$") then
        base = base .. " Refugees"
    end
    base = string.sub(base, 1, Constants.NAME_MAX_LENGTH)
    for otherID, other in pairs(Factions.Registry.byID or {}) do
        if otherID ~= faction.id and other.name == base then
            local suffix = " " .. string.sub(faction.id, -6)
            base = string.sub(
                base,
                1,
                Constants.NAME_MAX_LENGTH - #suffix
            ) .. suffix
            break
        end
    end
    return base
end

function Internal.endFactionTreaties(faction, at)
    local reconcileIDs = {}
    for otherID, relation in pairs(faction.relations or {}) do
        local other = Internal.registryRecord(otherID)
        local reverse = other and other.relations
            and other.relations[faction.id] or nil
        local changed = relation.atWar == true
            or relation.allied == true
            or (tonumber(relation.truceUntil) or 0) > 0
            or reverse and (
                reverse.atWar == true
                or reverse.allied == true
                or (tonumber(reverse.truceUntil) or 0) > 0
            )
        if changed then
            for _, item in ipairs({ relation, reverse }) do
                if item then
                    item.atWar = false
                    item.allied = false
                    item.truceUntil = 0
                    item.warEndedAt = at
                    item.state =
                        PNC.FactionDiplomacyMath.ResolveState(
                            item,
                            at
                        )
                    item.revision = math.max(
                        0,
                        math.floor(tonumber(item.revision) or 0)
                    ) + 1
                end
            end
            if other then Internal.touchFaction(other) end
            reconcileIDs[otherID] = true
        end
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        for otherID, _ in pairs(reconcileIDs) do
            PNC.FactionBehavior.ReconcileFaction(
                otherID,
                "player_faction_disbanded"
            )
        end
    end
end

Internal.retireProvisionalFaction = function(
    faction,
    playerKey,
    worldAgeHours,
    reason
)
    if not Internal.isProvisionalFaction(faction) then
        return false, "not_provisional"
    end
    local at = Internal.finiteTimestamp(
        worldAgeHours,
        faction.createdAt
    )
    if EntityRef.IsPlayer(playerKey) then
        faction.playerMemberKeys[playerKey] = nil
        if Factions.Registry.byPlayerKey[playerKey]
            == faction.id
        then
            Factions.Registry.byPlayerKey[playerKey] = nil
        end
    end
    faction.ownerPlayerKey = nil
    faction.playerMemberKeys = {}
    faction.status = "archived"
    faction.archivedAt = at
    faction.tags = faction.tags or {}
    faction.tags.hiddenFromFactionLists = true
    faction.tags.provisionalRetired = true
    faction.tags.retiredReason = tostring(
        reason or "player_identity_ended"
    )
    Internal.endFactionTreaties(faction, at)
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "provisional_retired", Internal.copy(faction)
end

return Factions

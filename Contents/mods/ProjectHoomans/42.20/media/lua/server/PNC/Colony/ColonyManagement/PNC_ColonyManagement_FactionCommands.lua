if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


function Management.SetFactionEmblemForPlayer(player, args)
    args = type(args) == "table" and args or {}
    if not PNC.Factions or not PNC.Factions.SetPlayerFactionEmblem then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "faction_emblem_unavailable",
        }
    end
    local ok, reason, faction = PNC.Factions.SetPlayerFactionEmblem(
        player, args.emblem)
    if ok == true and PNC.Factions.Save then PNC.Factions.Save() end
    return Management.BuildSnapshot(player), {
        ok = ok == true, reason = reason,
        action = "faction_emblem",
        factionID = faction and faction.id or nil,
    }
end

function Management.RenameFactionForPlayer(player, args)
    args = type(args) == "table" and args or {}
    if not PNC.Factions or not PNC.Factions.SetPlayerFactionName then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "faction_rename_unavailable",
        }
    end
    local ok, reason, faction = PNC.Factions.SetPlayerFactionName(
        player, args.name
    )
    if ok == true and PNC.Factions.Save then PNC.Factions.Save() end
    return Management.BuildSnapshot(player), {
        ok = ok == true,
        reason = reason,
        factionID = faction and faction.id or nil,
    }
end

function Management.RenameForPlayer(player, args)
    args = type(args) == "table" and args or {}
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    local communityID = tostring(args.communityID or "")
    local allowed = false
    if faction and PNC.Communities and PNC.Communities.GetForFaction then
        for _, community in ipairs(PNC.Communities.GetForFaction(faction.id) or {}) do
            if community.id == communityID and community.status == "active" then
                allowed = true
                break
            end
        end
    end
    if not allowed then
        return Management.BuildSnapshot(player), {
            ok = false, reason = "community_not_owned",
        }
    end
    local ok, reason = PNC.Communities.SetName(
        communityID,
        args.name
    )
    if ok == true and PNC.Communities.Save then
        PNC.Communities.Save()
        if GlobalModData and GlobalModData.save then
            GlobalModData.save()
        end
    end
    return Management.BuildSnapshot(player), {
        ok = ok == true,
        reason = reason,
        communityID = communityID,
    }
end


return Management

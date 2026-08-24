if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.BaseValidationService
local H = Validation.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local Definitions = PNC.SettlementDefinitions

function H.Result(ok, reason, details)
    return { ok = ok == true, reason = reason, details = details }
end

function Validation.ProjectFootprint(region)
    local normalized = GridRegion.normalize(region)
    local footprint = { levels = { [0] = { rows = {} } } }
    for _, level in pairs(normalized.levels) do
        for y, spans in pairs(level.rows) do
            local row = footprint.levels[0].rows[y]
            if not row then row = {}; footprint.levels[0].rows[y] = row end
            for index = 1, #spans do row[#row + 1] = spans[index] end
        end
    end
    return GridRegion.normalize(footprint)
end

function Validation.CanUse(player, base)
    if PNC.BasePermissions and PNC.BasePermissions.CanManage then
        return PNC.BasePermissions.CanManage(player, base) == true
    end
    if not base or not player then return false end
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    return faction and tostring(faction.id) == tostring(base.factionId)
end

function Validation.CanCreateFor(player, colonyId, factionId)
    if PNC.BasePermissions and PNC.BasePermissions.CanCreate then
        return PNC.BasePermissions.CanCreate(player, colonyId, factionId) == true
    end
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    local colony = PNC.Communities and PNC.Communities.Get
        and PNC.Communities.Get(colonyId) or nil
    return faction ~= nil and colony ~= nil
        and tostring(faction.id) == tostring(factionId)
        and tostring(colony.factionID or colony.factionId) == tostring(factionId)
        and colony.status == "active"
end

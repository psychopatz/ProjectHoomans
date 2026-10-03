require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

PNC = PNC or {}
PNC.DirectorDebugModel = PNC.DirectorDebugModel or {}

local Model = PNC.DirectorDebugModel
local MobileModel = PNC.MobileGroupDebugModel

local function row(label, value, tone)
    return { label = tostring(label or ""),
        value = tostring(value == nil and "" or value), tone = tone }
end

function Model.GroupItems(snapshot)
    local output = {}
    for _, group in ipairs(snapshot and snapshot.groups or {}) do
        local mobile = group.mobile
        local state = mobile and MobileModel.StateText(mobile, group)
            or nil
        output[#output + 1] = { id = group.id, value = group,
            label = (mobile and "MOBILE / " or "")
                .. group.groupType .. " / " .. group.id,
            detail = (state and state .. " / " or "")
                .. group.mission .. " + " .. group.state
                .. (mobile and " / " .. tostring(mobile.presence) or "") }
    end
    return output
end

function Model.LocationItems(snapshot)
    local output = {}
    for _, location in ipairs(snapshot and snapshot.locations or {}) do
        output[#output + 1] = { id = location.id, value = location,
            label = location.type .. " / " .. location.id,
            detail = string.format("%.0f, %.0f | groups %d",
                location.x or 0, location.y or 0,
                #(location.occupantGroupIds or {})) }
    end
    return output
end

function Model.SectorItems(snapshot)
    local output = {}
    for _, sector in ipairs(snapshot and snapshot.population
        and snapshot.population.sectors or {}) do
        output[#output + 1] = { id = sector.id, value = sector,
            label = (sector.active and "ACTIVE / " or "SECTOR / ") .. sector.id,
            detail = string.format("G %d/%d  S %d/%d  sites %d",
                sector.groupCount or 0, sector.desiredGroups or 0,
                sector.settlementCount or 0, sector.desiredSettlements or 0,
                sector.candidatePool or 0) }
    end
    return output
end




Model.Internal = Model.Internal or {}
Model.Internal.row = row

return Model

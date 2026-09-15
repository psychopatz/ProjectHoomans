-- Mobile-group classification, filtering, and list projections.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal
require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

local MobileModel = PNC.MobileGroupDebugModel
local MOBILE_POOL_ORDER = {
    staging = 1,
    en_route = 2,
    player_colony = 3,
    street_roaming = 4,
}

local MOBILE_POOL_MEANINGS = {
    staging = "Road-visible groups waiting for the daily departure roll.",
    en_route = "Abstract traversal toward an AI-owned settlement.",
    player_colony = "Abstract traversal toward a colony owned by your faction.",
    street_roaming = "Ambient street behavior; may shelter at night.",
}
Internal.MobilePoolMeanings = MOBILE_POOL_MEANINGS

local MOBILE_CATEGORY_ORDER = {
    staging = 1,
    ai_settlement = 2,
    player_colony = 3,
    street_roaming = 4,
}

local MOBILE_CATEGORY_LABELS = {
    staging = "WAITING ON ROAD",
    player_colony = "TRAVELING TO PLAYER COLONY",
    ai_settlement = "TRAVELING TO AI SETTLEMENT",
    street_roaming = "STREET ROAMING",
}

local MOBILE_CATEGORY_TONES = {
    staging = "success",
    player_colony = "danger",
    ai_settlement = "warning",
    street_roaming = "accent",
}

local MOBILE_FILTER_LABELS = {
    all = "ALL MOBILE GROUPS",
    staging = "WAITING ON ROAD",
    player_colony = "TO PLAYER COLONY",
    ai_settlement = "TO AI SETTLEMENT",
    street_roaming = "STREET ROAMING",
}

local MOBILE_FILTERS = {
    all = true,
    staging = true,
    player_colony = true,
    ai_settlement = true,
    street_roaming = true,
}

local function mobileFactionList(snapshot)
    if snapshot and snapshot.mobileGroups then
        return snapshot.mobileGroups
    end
    return snapshot and snapshot.factions or {}
end

local function mobileTargetsPlayerColony(mobile, playerFactionID)
    local target = MobileModel.Target(mobile)
    if not target then return false end
    if target.kind == "player_colony"
        or target.kind == "player_base"
    then
        return true
    end
    return playerFactionID ~= nil
        and target.factionID == playerFactionID
end

function Model.MobileCategory(mobile, playerFactionID)
    local pool = Model.MobilePool(mobile, playerFactionID)
    if pool == "staging" then return "staging" end
    if pool == "player_colony" then return "player_colony" end
    if pool == "en_route" then return "ai_settlement" end
    return "street_roaming"
end

function Model.MobileCategoryLabel(category)
    return MOBILE_CATEGORY_LABELS[category]
        or tostring(category or "UNKNOWN MOBILE STATE")
end

function Model.MobileCategoryTone(category)
    return MOBILE_CATEGORY_TONES[category] or "accent"
end

function Model.MobileFilterLabel(filter)
    return MOBILE_FILTER_LABELS[filter] or MOBILE_FILTER_LABELS.all
end

function Model.NormalizeMobileFilter(filter)
    filter = tostring(filter or "all")
    return MOBILE_FILTERS[filter] and filter or "all"
end

function Model.MobileFilterCount(counts, filter)
    counts = counts or {}
    filter = Model.NormalizeMobileFilter(filter)
    return tonumber(filter == "all" and counts.all
        or counts[filter]) or 0
end

function Model.MobilePool(mobile, playerFactionID)
    local state = MobileModel.State(mobile)
    if state == "road_roaming" then return "staging" end
    if state == "en_route" or state == "arrival_pending" then
        if mobileTargetsPlayerColony(mobile, playerFactionID) then
            return "player_colony"
        end
        return "en_route"
    end
    return "street_roaming"
end

function Model.BuildMobilePoolCounts(snapshot)
    local counts = {
        all = 0,
        staging = 0,
        en_route = 0,
        player_colony = 0,
        ai_settlement = 0,
        street_roaming = 0,
    }
    local playerFactionID = snapshot
        and snapshot.currentPlayerFactionID or nil
    for _, faction in ipairs(mobileFactionList(snapshot)) do
        if faction.mobile and faction.mobile.active == true then
            counts.all = counts.all + 1
            local pool = Model.MobilePool(
                faction.mobile, playerFactionID)
            local category = Model.MobileCategory(
                faction.mobile, playerFactionID)
            if pool == "staging" then
                counts.staging = counts.staging + 1
            elseif pool == "player_colony" then
                counts.player_colony = counts.player_colony + 1
                counts.en_route = counts.en_route + 1
            elseif pool == "en_route" then
                counts.en_route = counts.en_route + 1
            else
                counts.street_roaming = counts.street_roaming + 1
            end
            if category == "ai_settlement" then
                counts.ai_settlement = counts.ai_settlement + 1
            end
        end
    end
    return counts
end

function Model.BuildMobileItems(snapshot, requestedFilter)
    local output = {}
    local filter = Model.NormalizeMobileFilter(requestedFilter)
    local playerFactionID = snapshot
        and snapshot.currentPlayerFactionID or nil
    for _, faction in ipairs(mobileFactionList(snapshot)) do
        if faction.mobile and faction.mobile.active == true then
            local pool = Model.MobilePool(
                faction.mobile, playerFactionID)
            local category = Model.MobileCategory(
                faction.mobile, playerFactionID)
            if filter == "all" or filter == category then
                local destination = MobileModel.TargetText(
                    faction.mobile)
                output[#output + 1] = {
                    id = faction.id,
                    name = faction.name,
                    label = Model.MobileCategoryLabel(category)
                        .. " / " .. tostring(faction.name),
                    detail = MobileModel.StateText(faction.mobile)
                        .. " / " .. tostring(faction.archetypeID)
                        .. " / " .. tostring(faction.mobile.presence
                            or "unknown")
                        .. " / " .. destination,
                    listDetail = MobileModel.StateText(faction.mobile)
                        .. "  /  " .. tostring(faction.mobile.presence
                            or "unknown")
                        .. "  /  " .. destination,
                    faction = faction,
                    pool = pool,
                    category = category,
                    categoryLabel = Model.MobileCategoryLabel(category),
                    categoryTone = Model.MobileCategoryTone(category),
                }
            end
        end
    end
    table.sort(output, function(left, right)
        local leftOrder = MOBILE_CATEGORY_ORDER[left.category]
            or MOBILE_POOL_ORDER[left.pool] or 99
        local rightOrder = MOBILE_CATEGORY_ORDER[right.category]
            or MOBILE_POOL_ORDER[right.pool] or 99
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end
        if left.label ~= right.label then
            return left.label < right.label
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end
return Model

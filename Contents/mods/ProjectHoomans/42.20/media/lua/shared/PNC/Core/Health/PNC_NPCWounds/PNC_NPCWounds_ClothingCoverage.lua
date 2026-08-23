PNC = PNC or {}
local Internal = PNC.NPCWounds.Internal
local Core = PNC.Core

function Internal.ItemCoversPart(item, entry, partId)
    local covered = item and item.getCoveredParts
        and item:getCoveredParts() or nil
    local name
    local i
    if covered and covered.size and covered.get then
        for i = 0, covered:size() - 1 do
            name = tostring(covered:get(i) or "")
            name = string.match(name, "([%w_]+)$") or name
            name = Internal.CoveragePartAliases[name] or name
            if name == partId then return true end
        end
        return false
    end
    name = entry and (
        entry.getLocation and tostring(entry:getLocation())
        or entry.getBodyLocation and tostring(entry:getBodyLocation())
    ) or ""
    name = string.lower(name)
    if partId == "Head" then
        return string.find(name, "head", 1, true) ~= nil
            or string.find(name, "hat", 1, true) ~= nil
    end
    if partId == "Neck" then
        return string.find(name, "neck", 1, true) ~= nil
            or string.find(name, "scarf", 1, true) ~= nil
    end
    if string.find(partId, "Hand", 1, true) then
        return string.find(name, "hand", 1, true) ~= nil
            or string.find(name, "glove", 1, true) ~= nil
    end
    if string.find(partId, "Foot", 1, true) then
        return string.find(name, "shoe", 1, true) ~= nil
            or string.find(name, "sock", 1, true) ~= nil
            or string.find(name, "foot", 1, true) ~= nil
    end
    if string.find(partId, "Leg", 1, true)
        or partId == "Groin"
        or partId == "Torso_Lower"
    then
        return string.find(name, "pants", 1, true) ~= nil
            or string.find(name, "trouser", 1, true) ~= nil
            or string.find(name, "skirt", 1, true) ~= nil
            or string.find(name, "short", 1, true) ~= nil
    end
    return string.find(name, "shirt", 1, true) ~= nil
        or string.find(name, "jacket", 1, true) ~= nil
        or string.find(name, "sweater", 1, true) ~= nil
        or string.find(name, "torso", 1, true) ~= nil
        or string.find(name, "suit", 1, true) ~= nil
end

function Internal.ReadDefense(item, damageType)
    if not item then return nil end
    if damageType == "bullet" then
        return item.getBulletDefense
            and tonumber(item:getBulletDefense()) or nil
    end
    if damageType == "scratch" or damageType == "laceration" then
        return item.getScratchDefense
            and tonumber(item:getScratchDefense()) or nil
    end
    return item.getBiteDefense
        and tonumber(item:getBiteDefense()) or nil
end

function Internal.ConditionRatio(item)
    if not item or not item.getCondition or not item.getConditionMax then
        return 1
    end
    local condition = tonumber(item:getCondition()) or 0
    local maximum = math.max(
        1,
        tonumber(item:getConditionMax()) or 1
    )
    return Core.Clamp(condition / maximum, 0, 1)
end

return Internal

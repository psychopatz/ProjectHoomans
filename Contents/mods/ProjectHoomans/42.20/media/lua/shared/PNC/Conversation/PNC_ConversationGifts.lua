-- Shared gift scoring used by the offer UI and the authoritative server.
-- Keep this deliberately data-only: item names are not trusted input and the
-- server still validates ownership, distance, lease, and transfer direction.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}

local Gifts = PNC.Gifts

local function contains(value, needle)
    return string.find(string.lower(tostring(value or "")), needle, 1, true)
        ~= nil
end

function Gifts.GetItemScore(itemType)
    local approval = 1
    local respect = 0
    local familiarity = 0.5
    local kind = "general"
    local value = string.lower(tostring(itemType or ""))

    if contains(value, "medicine")
        or contains(value, "bandage")
        or contains(value, "firstaid")
        or contains(value, "painkiller")
        or contains(value, "antibiotic")
        or contains(value, "suture")
        or contains(value, "splint")
        or contains(value, "disinfect")
    then
        approval = approval + 3
        respect = respect + 1
        kind = "medical"
    elseif contains(value, "food")
        or contains(value, "water")
        or contains(value, "canned")
        or contains(value, "chips")
        or contains(value, "bread")
        or contains(value, "meat")
        or contains(value, "fish")
        or contains(value, "milk")
        or contains(value, "coffee")
        or contains(value, "soda")
        or contains(value, "pasta")
        or contains(value, "rice")
    then
        approval = approval + 2
        kind = "food"
    elseif contains(value, "weapon")
        or contains(value, "ammo")
        or contains(value, "tool")
        or contains(value, "bullet")
        or contains(value, "shell")
        or contains(value, "shotgun")
        or contains(value, "rifle")
        or contains(value, "pistol")
        or contains(value, "katana")
        or contains(value, "sword")
        or contains(value, "axe")
        or contains(value, "bat")
        or contains(value, "knife")
        or contains(value, "machete")
        or contains(value, "spear")
        or contains(value, "hammer")
        or contains(value, "wrench")
        or contains(value, "screwdriver")
    then
        respect = respect + 2
        kind = "equipment"
    end

    return {
        approval = approval,
        respect = respect,
        familiarity = familiarity,
        score = approval + respect + familiarity,
        kind = kind,
    }
end

function Gifts.IsValidItemType(itemType)
    return Gifts.GetItemScore(itemType).kind ~= "general"
end

function Gifts.EvaluateEffect(itemTypes)
    local approval = 0
    local respect = 0
    local familiarity = 0
    local bestType = "gift"
    local bestScore = -math.huge
    local bestKind = "general"

    for _, itemType in ipairs(itemTypes or {}) do
        local score = Gifts.GetItemScore(itemType)
        approval = approval + score.approval
        respect = respect + score.respect
        familiarity = familiarity + score.familiarity
        if score.score > bestScore then
            bestScore = score.score
            bestType = itemType or bestType
            bestKind = score.kind
        end
    end

    return {
        approval = math.min(12, approval),
        respect = math.min(8, respect),
        familiarity = math.min(3, familiarity),
        memoryID = bestType,
        kind = bestKind,
    }
end

function Gifts.FormatScore(score)
    score = type(score) == "table" and score or {}
    local function number(value)
        value = tonumber(value) or 0
        if value == math.floor(value) then return tostring(math.floor(value)) end
        return string.format("%.1f", value)
    end
    local function signed(value)
        value = tonumber(value) or 0
        return value >= 0 and "+" .. number(value) or number(value)
    end
    return "A" .. signed(score.approval)
        .. " R" .. signed(score.respect)
        .. " F" .. signed(score.familiarity)
        .. "  (" .. number(score.score) .. ")"
end

function Gifts.FormatShortScore(score)
    score = type(score) == "table" and score or {}
    local function number(value)
        value = tonumber(value) or 0
        if value == math.floor(value) then return tostring(math.floor(value)) end
        return string.format("%.1f", value)
    end
    local function signed(value)
        value = tonumber(value) or 0
        return value >= 0 and "+" .. number(value) or number(value)
    end
    return "A" .. signed(score.approval)
        .. "/R" .. signed(score.respect)
        .. "/F" .. signed(score.familiarity)
end

return Gifts

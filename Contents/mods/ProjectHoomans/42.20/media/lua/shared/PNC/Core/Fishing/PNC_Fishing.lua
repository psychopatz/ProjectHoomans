-- Shared fishing rules. The server owns zone state and inventory mutation;
-- this module stays free of live engine objects so abstract and live NPCs
-- resolve the same work-point and catch attempt.

PNC = PNC or {}
PNC.Fishing = PNC.Fishing or {}

local Fishing = PNC.Fishing
local Const = PNC.Const or {}

Fishing.DEFAULT_LOOT = Fishing.DEFAULT_LOOT or {
    -- Native rod fishing returns whole fish. These weights approximate the
    -- native worm-bait pool while keeping abstract NPC fishing independent of
    -- client-only Fishing.Fish objects and live engine state.
    { type = "Base.LargemouthBass", weight = 7 },
    { type = "Base.SmallmouthBass", weight = 7 },
    { type = "Base.WhiteBass", weight = 7 },
    { type = "Base.SpottedBass", weight = 7 },
    { type = "Base.StripedBass", weight = 7 },
    { type = "Base.Bluegill", weight = 7 },
    { type = "Base.WhiteCrappie", weight = 5 },
    { type = "Base.BlackCrappie", weight = 5 },
    { type = "Base.RedearSunfish", weight = 5 },
    { type = "Base.YellowPerch", weight = 5 },
    { type = "Base.Sauger", weight = 7 },
    { type = "Base.GreenSunfish", weight = 9 },
    { type = "Base.Walleye", weight = 5 },
    { type = "Base.FreshwaterDrum", weight = 7 },
    { type = "Base.BlueCatfish", weight = 5 },
    { type = "Base.ChannelCatfish", weight = 5 },
    { type = "Base.FlatheadCatfish", weight = 5 },
    { type = "Base.Muskellunge", weight = 5 },
    { type = "Base.AligatorGar", weight = 5 },
    { type = "Base.Paddlefish", weight = 1 },
    { type = "Base.BaitFish", weight = 7 },
}

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    return math.max(minimum, math.min(maximum, value))
end

local function hash(value)
    local text = tostring(value or "")
    local result = 17
    local index
    for index = 1, #text do
        result = (result * 131 + string.byte(text, index)) % 2147483647
    end
    return result
end

function Fishing.UnitRoll(seed)
    return hash(seed) / 2147483647
end

function Fishing.SkillLevel(record)
    if PNC.Skills and type(PNC.Skills.GetLevel) == "function" then
        return clamp(PNC.Skills.GetLevel(record, "Fishing"), 0, 10)
    end
    return 0
end

function Fishing.CatchChance(record, zone)
    local base = tonumber(zone and zone.catchChance)
        or tonumber(Const.FISHING_BASE_CATCH_CHANCE) or 0.25
    local bonus = tonumber(zone and zone.skillCatchBonus)
        or tonumber(Const.FISHING_SKILL_CATCH_BONUS) or 0.05
    return clamp(base + Fishing.SkillLevel(record) * bonus, 0, 1)
end

function Fishing.RollAttempt(record, zone, attemptIndex)
    local npcId = record and record.id or "unknown"
    local zoneId = zone and zone.id or "unknown"
    local seed = tostring(npcId) .. ":" .. tostring(zoneId) .. ":"
        .. tostring(attemptIndex or 1)
    local roll = Fishing.UnitRoll(seed)
    local chance = Fishing.CatchChance(record, zone)
    return {
        seed = seed,
        roll = roll,
        chance = chance,
        success = roll < chance,
    }
end

function Fishing.SelectLoot(record, zone, attemptIndex)
    local loot = zone and zone.loot or Fishing.DEFAULT_LOOT
    local total = 0
    local index
    local entry
    local roll
    if type(loot) ~= "table" or #loot <= 0 then return nil end
    for index = 1, #loot do
        entry = loot[index]
        if type(entry) == "table" and tostring(entry.type or "") ~= "" then
            total = total + math.max(0, tonumber(entry.weight) or 1)
        end
    end
    if total <= 0 then return nil end
    roll = Fishing.UnitRoll(tostring(record and record.id or "unknown")
        .. ":loot:" .. tostring(zone and zone.id or "unknown") .. ":"
        .. tostring(attemptIndex or 1)) * total
    for index = 1, #loot do
        entry = loot[index]
        if type(entry) == "table" and tostring(entry.type or "") ~= "" then
            roll = roll - math.max(0, tonumber(entry.weight) or 1)
            if roll < 0 then
                return {
                    type = tostring(entry.type),
                    stack = math.max(1, math.floor(tonumber(entry.stack) or 1)),
                }
            end
        end
    end
    return nil
end

function Fishing.WorkPointsPerSecond(zone)
    return math.max(0.1, tonumber(zone and zone.workPointsPerSecond)
        or tonumber(Const.FISHING_WORK_POINTS_PER_SECOND) or 5)
end

function Fishing.RequiredWorkPoints(zone)
    return math.max(1, tonumber(zone and zone.requiredWorkPoints)
        or tonumber(Const.FISHING_REQUIRED_WORK_POINTS) or 100)
end

return Fishing

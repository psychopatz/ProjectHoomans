-- Sparse, deterministic attrition for AI-owned mobile groups.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractMobileAccidents = PNC.AbstractMobileAccidents or {}

local Accidents = PNC.AbstractMobileAccidents
local Groups = PNC.AbstractGroups
local Store = PNC.AbstractWorldStore
local Casualties = PNC.AbstractCasualtyResolver
local Config = PNC.DirectorConfig

local ELIGIBLE_TYPES = { REFUGEE = true, LOOTER = true, TRADER = true }

local function chanceFor(groupType)
    return PNC.Sandbox and PNC.Sandbox.MobileGroupAccidentChance
        and PNC.Sandbox.MobileGroupAccidentChance(groupType) or 0
end

local function roll(bucket, groupID, npcID)
    local seed = "mobile_accident:" .. tostring(bucket) .. ":"
        .. tostring(groupID) .. ":" .. tostring(npcID)
    return PNC.AbstractScavengeResolver.Hash(seed) % 10000
end

local function eligible(group, bucket)
    if not group or not ELIGIBLE_TYPES[tostring(group.groupType or "")] then
        return false
    end
    if group.homeCommunityId ~= nil or group.factionId == nil then return false end
    if PNC.Factions and PNC.Factions.IsPlayerFaction
        and PNC.Factions.IsPlayerFaction(group.factionId)
    then return false end
    if Groups.HasLiveMembers and Groups.HasLiveMembers(group) then return false end
    group.diagnostics = type(group.diagnostics) == "table"
        and group.diagnostics or {}
    return tonumber(group.diagnostics.lastAccidentBucket) ~= bucket
end

function Accidents.Process(at)
    at = tonumber(at) or Store.WorldAgeHours()
    local interval = math.max(0.01,
        tonumber(Config.MOBILE_ACCIDENT_INTERVAL_HOURS) or 2)
    local bucket = math.floor(at / interval)
    local processed = 0
    local touched = false
    for _, group in ipairs(Groups.List()) do
        if eligible(group, bucket) then
            local chance = chanceFor(group.groupType)
            local selected = {}
            if chance > 0 then
                local threshold = math.floor(chance * 100)
                for _, npcID in ipairs(group.memberIds or {}) do
                    local record = PNC.Registry and PNC.Registry.Get(npcID)
                    if record and record.alive ~= false
                        and roll(bucket, group.id, npcID) < threshold
                    then selected[#selected + 1] = npcID end
                end
            end
            group.diagnostics.lastAccidentBucket = bucket
            touched = true
            if #selected > 0 then
                local deaths = Casualties.KillMembers(group, selected,
                    "mobile_group_accident")
                Store.Emit("MOBILE_GROUP_ACCIDENT", {
                    groupId = group.id, factionId = group.factionId,
                    groupType = group.groupType, deaths = #deaths,
                    chance = chance, worldAgeHours = at,
                })
            end
            if #(group.memberIds or {}) == 0 then
                local factionID = group.factionId
                Groups.Remove(group.id, "mobile_group_accident")
                if factionID and PNC.Factions and PNC.Factions.Destroy then
                    PNC.Factions.Destroy(factionID,
                        "mobile_group_accident", at)
                end
            end
            processed = processed + 1
        end
    end
    if touched then Store.Touch("mobile_accidents_processed") end
    return processed
end

return Accidents

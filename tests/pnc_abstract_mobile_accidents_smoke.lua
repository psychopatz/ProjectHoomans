local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/"

local groups = {
    { id = "refugees", factionId = "f_refugee", groupType = "REFUGEE",
        memberIds = { "r1", "r2" }, diagnostics = {} },
    { id = "player", factionId = "f_player", groupType = "LOOTER",
        memberIds = { "p1" }, diagnostics = {} },
    { id = "live", factionId = "f_live", groupType = "TRADER",
        memberIds = { "t1" }, diagnostics = {} },
}
local killed = {}
local destroyed = {}
PNC = {
    DirectorConfig = { MOBILE_ACCIDENT_INTERVAL_HOURS = 2 },
    Sandbox = { MobileGroupAccidentChance = function(kind)
        return kind == "REFUGEE" and 100 or 1
    end },
    AbstractScavengeResolver = { Hash = function() return 0 end },
    AbstractWorldStore = {
        WorldAgeHours = function() return 2 end,
        Touch = function() end,
        Emit = function() end,
    },
    AbstractGroups = {
        List = function() return groups end,
        HasLiveMembers = function(group) return group.id == "live" end,
        Remove = function(id) destroyed[#destroyed + 1] = "group:" .. id end,
    },
    AbstractCasualtyResolver = {
        KillMembers = function(group, ids)
            for _, id in ipairs(ids) do killed[#killed + 1] = id end
            group.memberIds = {}
            return ids
        end,
    },
    Factions = {
        IsPlayerFaction = function(id) return id == "f_player" end,
        Destroy = function(id) destroyed[#destroyed + 1] = "faction:" .. id end,
    },
    Registry = { Get = function(id) return { id = id, alive = true } end },
}

dofile(ROOT .. "PNC_AbstractMobileAccidents.lua")
assert(PNC.AbstractMobileAccidents.Process(2) == 1,
    "accident pass did not isolate eligible abstract AI groups")
assert(#killed == 2 and killed[1] == "r1" and killed[2] == "r2",
    "per-member accident rolls did not select the eligible members")
assert(destroyed[1] == "group:refugees"
    and destroyed[2] == "faction:f_refugee",
    "empty mobile group and faction were not retired")
assert(PNC.AbstractMobileAccidents.Process(2) == 0,
    "same two-hour bucket was processed more than once")

print("pnc_abstract_mobile_accidents_smoke: ok")

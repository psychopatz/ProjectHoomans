local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "assert") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local communitySaves = 0
local community = {
    id = "community_player",
    factionID = "faction_player",
    name = "New Colony",
    renamePending = true,
    status = "active",
    revision = 1,
}
local companion = {
    id = "npc_alex",
    name = "Alex Rivera",
    alive = true,
    recruited = true,
    ownerUsername = "Tester",
    affiliation = { factionID = "faction_player", communityRole = "resident" },
    health = { state = "normal" },
    needs = { hunger = 0.82, hydration = 0.10, fatigue = 0.10 },
}

PNC = {
    NeedsDefinitions = {
        TYPES = { "hunger", "hydration", "fatigue" },
        GetLevel = function(_, value)
            if value >= 0.70 then return "EMERGENCY" end
            if value >= 0.45 then return "CRITICAL" end
            if value >= 0.25 then return "LOW" end
            if value >= 0.15 then return "STABLE" end
            return "GOOD"
        end,
    },
    IndividualNeeds = {
        Ensure = function(record) return record.needs end,
        GetHighestPriority = function() return "hunger", 82 end,
        GetActivity = function() return "Following" end,
    },
    NeedsUtils = { WorldAgeHours = function() return 42 end },
    CompanionCommands = {
        IsOwnedByPlayer = function(record, player)
            return record.ownerUsername == player:getUsername()
        end,
    },
    Registry = { Data = { [companion.id] = companion } },
    Factions = {
        GetPlayerFaction = function() return { id = "faction_player" } end,
    },
    Communities = {
        GetForFaction = function() return { community } end,
        SetName = function(id, name)
            if id ~= community.id then return false, "community_not_found" end
            community.name = name
            community.renamePending = false
            community.revision = community.revision + 1
            return true, "renamed"
        end,
        Save = function() communitySaves = communitySaves + 1 end,
    },
}

local Management = dofile(ROOT .. "PNC_ColonyManagement.lua")
local player = { getUsername = function() return "Tester" end }
local snapshot = Management.BuildSnapshot(player)

equal(#snapshot.people, 1, "owned companion appears")
equal(snapshot.people[1].name, "Alex Rivera", "companion identity presented")
equal(#snapshot.attention, 1, "critical need appears in attention")
equal(snapshot.attention[1].needType, "hunger", "critical need type")

local renamed, result = Management.RenameForPlayer(player, {
    communityID = community.id,
    name = "Riverside Watch",
})
equal(result.ok, true, "owned colony rename succeeds")
equal(renamed.colony.name, "Riverside Watch", "renamed snapshot returned")
equal(renamed.colony.renamePending, false, "name prompt is cleared")
equal(communitySaves, 1, "rename commits community state immediately")

print("pnc_colony_management_smoke: ok")

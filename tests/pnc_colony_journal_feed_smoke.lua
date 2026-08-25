local T = require "tests/support/test"

T.addPackagePaths()

isServer = function() return true end
getGameTime = function()
    return { getWorldAgeHours = function() return 10 end }
end

PNC = {
    EventTypes = nil,
    Registry = { Data = {} },
    Factions = {
        GetPlayerFaction = function()
            return { id = "faction-a" }
        end,
    },
    ColonyStorageRepository = {
        ByID = {
            storage_a = {
                id = "storage_a", ownerFactionId = "faction-a",
                storageType = "primary",
            },
        },
        EnsureLoaded = function() end,
        Get = function(storageID)
            return PNC.ColonyStorageRepository.ByID[tostring(storageID)]
        end,
    },
}

local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local Protocol = require "PNC/Core/Networking/PNC_ColonyJournalProtocol"
local Feed = T.load(T.path(
    "ProjectHoomans", "server", "PNC/Journals/PNC_ColonyJournalFeed.lua"))

local player = {
    getOnlineID = function() return 7 end,
    getUsername = function() return "alice" end,
}

local owned = {
    id = "npc_a", name = "Alice's Guard",
    affiliation = { factionID = "faction-a" },
}
local foreign = {
    id = "npc_b", name = "Foreign Guard",
    affiliation = { factionID = "faction-b" },
}

T.equal(Protocol.MAX_BATCH, 32, "journal batch is bounded")
T.equal(#Protocol.ToWire({
    sequence = 1, at = 2, source = 1, eventCode = 3,
    subjectID = "npc_a", label = "Guard", args = {},
}), 10, "known wire rows use fixed primitive layout")

Feed.AppendNPC(EventTypes.NPC_FOOD_CONSUMED, owned, 601,
    "Base.Apple", 0.25)
Feed.AppendNPC(EventTypes.NPC_FOOD_CONSUMED, foreign, 602,
    "Base.Berry", 0.25)
Feed.AppendStorage(EventTypes.STORAGE_ITEM_DEPOSITED, "storage_a",
    "alice", 101, 3, "test", 603)

local first = Feed.GetDelta(player, { after = 0, limit = 32 })
T.equal(#first.rows, 2, "delta filters entries to the player's faction")
T.equal(first.rows[1][4], Protocol.EventCode(EventTypes.NPC_FOOD_CONSUMED),
    "NPC event code is compact")
T.equal(first.rows[2][3], Protocol.SOURCE_STORAGE,
    "storage source is represented in the wire row")
T.equal(first.more, false, "small delta does not page")
T.truthy(first.nextCursor >= 3, "cursor advances over global sequence")

local after = first.nextCursor
for index = 1, 35 do
    Feed.AppendNPC(EventTypes.NPC_SKILL_LEVEL_UP, owned, 700 + index,
        "Axe", index)
end
local page = Feed.GetDelta(player, { after = after, limit = 2 })
T.equal(#page.rows, 2, "journal page respects requested limit")
T.equal(page.more, true, "journal page reports remaining rows")
T.equal(page.nextCursor, page.rows[2][1], "paged cursor is last sent sequence")

local next = Feed.GetDelta(player, { after = page.nextCursor, limit = 32 })
T.truthy(#next.rows > 0, "journal resumes after the page cursor")
T.finish("pnc_colony_journal_feed_smoke")

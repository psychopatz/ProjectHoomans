local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local records = {
    { id = "npc-1" },
    { id = "npc-2" },
}
local player = { getUsername = function() return "Tester" end }
local fullSync
local detail
local delta
local warning
local canView = true

PNC = {
    Const = {
        CMD_FULL_SYNC_REQUEST = "FullSyncRequest",
        CMD_REQUEST_CHARACTER = "RequestCharacter",
    },
    Registry = {
        ForEach = function(callback)
            for _, record in ipairs(records) do callback(record) end
        end,
        ForEachDeathMarker = function(callback)
            callback({ id = "dead-1" })
        end,
        Get = function(id)
            for _, record in ipairs(records) do
                if record.id == id then return record end
            end
            return nil
        end,
    },
    Network = {
        BuildRosterSnapshot = function(record)
            return { id = record.id, kind = "record" }
        end,
        BuildDeathMarkerSnapshot = function(marker)
            return { id = marker.id, kind = "death" }
        end,
        BroadcastFullSync = function(receivedPlayer, snapshots)
            fullSync = { player = receivedPlayer, snapshots = snapshots }
        end,
        CanViewCharacter = function()
            return canView
        end,
        SendInventoryDelta = function(receivedPlayer, record, revision)
            delta = { player = receivedPlayer, record = record,
                revision = revision }
        end,
        SendCharacterPayload = function(receivedPlayer, record)
            detail = { player = receivedPlayer, record = record }
        end,
    },
    Core = {
        LogWarn = function(message) warning = message end,
    },
}

local Router = require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler"

assertEqual(Router.Handle("FullSyncRequest", player, nil), true,
    "full sync handled")
assertEqual(fullSync.player, player, "full-sync player")
assertEqual(#fullSync.snapshots, 3, "full-sync snapshot count")
assertEqual(fullSync.snapshots[1].id, "npc-1", "first roster snapshot")
assertEqual(fullSync.snapshots[3].kind, "death", "death marker appended")

local detailArgs = { id = "npc-1" }
assertEqual(Router.Handle("RequestCharacter", player, detailArgs), true,
    "character detail handled")
assertEqual(detail.record, records[1], "character detail record")

local deltaArgs = { id = "npc-2", inventoryRevision = "5" }
assertEqual(Router.Handle("RequestCharacter", player, deltaArgs), true,
    "inventory detail handled")
assertEqual(delta.record, records[2], "inventory delta record")
assertEqual(delta.revision, "5", "original inventory revision preserved")

canView = false
assertEqual(Router.Handle("RequestCharacter", player, detailArgs), true,
    "unauthorized detail consumed")
assert(string.find(warning, "player=Tester", 1, true),
    "unauthorized warning omitted player")
assert(string.find(warning, "npc=npc-1", 1, true),
    "unauthorized warning omitted NPC")

warning = nil
assertEqual(Router.Handle("RequestCharacter", player, nil), true,
    "malformed detail consumed")
assertEqual(warning, nil, "malformed detail unexpectedly warned")

print("pnc_server_character_replication_command_handler_smoke: ok")

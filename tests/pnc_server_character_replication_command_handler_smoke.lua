local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

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

T.equal(Router.Handle("FullSyncRequest", player, nil), true,
    "full sync handled")
T.equal(fullSync.player, player, "full-sync player")
T.equal(#fullSync.snapshots, 3, "full-sync snapshot count")
T.equal(fullSync.snapshots[1].id, "npc-1", "first roster snapshot")
T.equal(fullSync.snapshots[3].kind, "death", "death marker appended")

local detailArgs = { id = "npc-1" }
T.equal(Router.Handle("RequestCharacter", player, detailArgs), true,
    "character detail handled")
T.equal(detail.record, records[1], "character detail record")

local deltaArgs = { id = "npc-2", inventoryRevision = "5" }
T.equal(Router.Handle("RequestCharacter", player, deltaArgs), true,
    "inventory detail handled")
T.equal(delta.record, records[2], "inventory delta record")
T.equal(delta.revision, "5", "original inventory revision preserved")

canView = false
T.equal(Router.Handle("RequestCharacter", player, detailArgs), true,
    "unauthorized detail consumed")
T.truthy(string.find(warning, "player=Tester", 1, true),
    "unauthorized warning omitted player")
T.truthy(string.find(warning, "npc=npc-1", 1, true),
    "unauthorized warning omitted NPC")

warning = nil
T.equal(Router.Handle("RequestCharacter", player, nil), true,
    "malformed detail consumed")
T.equal(warning, nil, "malformed detail unexpectedly warned")
T.finish("pnc_server_character_replication_command_handler_smoke")

T.finish("pnc_server_character_replication_command_handler_smoke")

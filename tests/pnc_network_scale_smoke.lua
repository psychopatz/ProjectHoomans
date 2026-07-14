local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Networking/PNC_Network.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local players = {}
for i = 1, 16 do
    local x = i <= 8 and 0 or 100
    players[i] = {
        getUsername = function() return "player_" .. tostring(i) end,
        getOnlineID = function() return i end,
        getAccessLevel = function() return "" end,
        getX = function() return x end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end

local sent = {}
sendServerCommand = function(player, module, command, payload)
    sent[#sent + 1] = { player = player, module = module, command = command, payload = payload }
end
isServer = function() return true end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_ROSTER_SYNC_BEGIN = "RosterSyncBegin",
        CMD_ROSTER_SYNC_CHUNK = "RosterSyncChunk",
        CMD_ROSTER_SYNC_END = "RosterSyncEnd",
        CMD_ROSTER_DELTA = "RosterDelta",
        CMD_SYNC_RECORD = "SyncRecord",
        CMD_REMOVE_RECORD = "RemoveRecord",
        CMD_CHARACTER_PAYLOAD = "CharacterPayload",
        CMD_INVENTORY_DELTA = "InventoryDelta",
        ROSTER_CHUNK_SIZE = 50,
        ROSTER_DELTA_INTERVAL_MS = 10000,
        INTEREST_REFRESH_MS = 1000,
        INTEREST_ENTER_DISTANCE = 48,
        INTEREST_LEAVE_DISTANCE = 56,
        CHARACTER_DETAIL_DISTANCE = 5,
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
    },
    Core = {
        Now = function() return 2000 end,
        IsAuthority = function() return true end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
        ForEachPlayer = function(callback)
            for i = 1, #players do callback(players[i]) end
        end,
    },
    Identity = {
        GetCharacterSummary = function(record)
            return {
                displayName = record.name,
                archetypeID = "Foreman",
                archetypeLabel = "Foreman",
                identitySeed = record.identitySeed,
                isFemale = false,
                survivor = {},
            }
        end,
    },
    Equipment = { Describe = function() return { combatModeResolved = "melee", weaponStatus = "ready" } end },
    Inventory = {
        BuildSummaryPayload = function() return { revision = 0, itemCount = 3 } end,
        BuildFullPayload = function() return { summary = { revision = 0 }, items = {}, containers = {} } end,
        BuildDeltaPayload = function() return nil end,
    },
    Skills = { BuildSnapshot = function() return {} end },
    Stamina = { BuildSnapshot = function() return { current = 100, max = 100, state = "fresh" } end },
    VisualProfiles = { RollAppearance = function() return {} end },
    MotionHints = {},
    Health = { CanRevive = function() return false end },
}

local nearbyRecord = {
    id = "npc_near",
    name = "Nearby",
    identitySeed = 123,
    faction = "colonist",
    presenceState = "live",
    alive = true,
    recruited = false,
    persist = true,
    x = 1,
    y = 0,
    z = 0,
    health = { current = 100, max = 100, state = "normal" },
    equipment = { worn = {}, attached = {} },
    runtime = {},
    presenceRevision = 1,
}

PNC.SpatialIndex = {
    QueryNPCs = function() return { nearbyRecord } end,
}
PNC.Registry = { Get = function() return nearbyRecord end }

dofile(FILE)

local roster = {}
for i = 1, 500 do
    roster[i] = { id = "npc_" .. tostring(i), displayName = "NPC " .. tostring(i) }
end
PNC.Network.BroadcastFullSync(players[1], roster)
assertEqual(#sent, 12, "500-record roster packet count")
assertEqual(sent[1].command, "RosterSyncBegin", "roster begin")
assertEqual(sent[12].command, "RosterSyncEnd", "roster end")
for i = 2, 11 do
    assertEqual(#sent[i].payload.snapshots, 50, "roster chunk size")
    assertEqual(sent[i].payload.snapshots[1].inventory, nil, "roster leaked inventory")
end

sent = {}
PNC.Network.RefreshInterestSets(2000)
assertEqual(#sent, 8, "interest-enter recipient count")
sent = {}
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
assertEqual(#sent, 8, "targeted live snapshot recipient count")
assertEqual(sent[1].payload.snapshot.skillLevels, nil, "tick snapshot leaked detailed skills")

nearbyRecord.x = 100
sent = {}
PNC.Network.RefreshInterestSets(4000)
assertEqual(#sent, 16, "interest enter/exit transition count")
sent = {}
PNC.Network.BroadcastRecord(nearbyRecord, "tick")
assertEqual(#sent, 8, "interest recipients did not switch")

nearbyRecord.ownerUsername = "player_16"
nearbyRecord.x = 1
assertEqual(PNC.Network.CanViewCharacter(players[1], nearbyRecord), true, "nearby detail access")
assertEqual(PNC.Network.CanViewCharacter(players[16], nearbyRecord), true, "owner detail access")
nearbyRecord.ownerUsername = nil
assertEqual(PNC.Network.CanViewCharacter(players[16], nearbyRecord), false, "remote detail rejection")

print("pnc_network_scale_smoke: ok")

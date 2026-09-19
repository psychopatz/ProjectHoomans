local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local playerItems = { { id = "shirt", name = "Shirt" } }
local playerItemList = javaList(playerItems)
local playerInventory = {
    getItems = function() return playerItemList end,
}
local player = {
    getInventory = function() return playerInventory end,
}
local sentCommands = {}
local fullCharacterPayloadCalls = 0
local localInventoryPayloadCalls = 0
local appliedPayloads = {}
local clientOnly = false
local helpers = {
    inventoryNow = function() return 1000 end,
    tr = function(_, fallback) return fallback end,
    INVENTORY_REFRESH_COOLDOWN_MS = 1000,
    INVENTORY_REFRESH_TIMEOUT_MS = 5000,
    INVENTORY_REFRESH_FEEDBACK_MS = 1000,
}

package.preload["PNC/UI/Inventory/InventoryWindow/_Helpers"] = function()
    return helpers
end

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_REQUEST_CHARACTER = "RequestCharacterPayload",
        CMD_REQUEST_CHARACTER_INVENTORY = "RequestCharacterInventoryPayload",
    },
    Core = {
        IsClientOnly = function() return clientOnly end,
    },
    Network = {
        ClientState = {
            characterPayloads = {},
            snapshots = {},
        },
    },
    Client = {
        Internal = {
            GetPlayer = function() return player end,
            ApplyCharacterInventoryPayload = function(payload, source)
                appliedPayloads[#appliedPayloads + 1] = {
                    payload = payload,
                    source = source,
                }
                return true
            end,
        },
    },
    API = {
        GetCharacterPayload = function()
            fullCharacterPayloadCalls = fullCharacterPayloadCalls + 1
            return { snapshot = { id = "npc_test" }, details = { skills = {} } }
        end,
        GetCharacterInventoryPayload = function(npcID)
            localInventoryPayloadCalls = localInventoryPayloadCalls + 1
            return {
                npcId = npcID,
                inventory = { revision = 7, items = {} },
                inventoryFull = true,
            }
        end,
    },
    InventoryTransferEndpoint = {},
}

sendClientCommand = function(target, moduleName, command, args)
    sentCommands[#sentCommands + 1] = {
        target = target,
        module = moduleName,
        command = command,
        args = args,
    }
end

T.load(CLIENT_ROOT .. "PNC/Networking/ClientRequests/PNC_ClientRequests_Character.lua")
package.preload["PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"] = function()
    return {
        Model = {},
        clientState = function() return PNC.Network.ClientState end,
    }
end
T.load(CLIENT_ROOT .. "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_NPC.lua")
ISPNCInventoryWindow = {}
T.load(CLIENT_ROOT .. "PNC/UI/Inventory/InventoryWindow/_Endpoint.lua")

local function openNPCInventory()
    local window = setmetatable({
        updateInventoryRefreshButton = function() end,
        refreshInventory = function(self, force)
            self.refreshCalls = (self.refreshCalls or 0) + 1
            self.lastRefreshForced = force
        end,
    }, { __index = ISPNCInventoryWindow })
    window:setNPC("npc_test")
    return window
end

local singleplayerWindow = openNPCInventory()
T.equal(singleplayerWindow.refreshCalls, 1,
    "singleplayer inventory open did not render its initial view")
T.equal(singleplayerWindow.lastRefreshForced, true,
    "singleplayer inventory open did not force its initial view refresh")
T.equal(localInventoryPayloadCalls, 1,
    "singleplayer inventory open skipped the inventory-only API")
T.equal(fullCharacterPayloadCalls, 0,
    "singleplayer inventory open requested a full character payload")
T.equal(#sentCommands, 0,
    "singleplayer inventory open sent a network command")
T.equal(#appliedPayloads, 1,
    "singleplayer inventory payload was not applied locally")
T.equal(appliedPayloads[1].source, "local_api",
    "singleplayer inventory payload source was not local")
T.equal(appliedPayloads[1].payload.requestID, "1",
    "singleplayer inventory payload did not carry its request ID")

clientOnly = true
local multiplayerWindow = openNPCInventory()
T.equal(multiplayerWindow.refreshCalls, 1,
    "multiplayer inventory open did not render its initial view")
T.equal(localInventoryPayloadCalls, 1,
    "multiplayer client built an inventory payload locally")
T.equal(fullCharacterPayloadCalls, 0,
    "multiplayer inventory open requested a full character payload")
T.equal(#appliedPayloads, 1,
    "multiplayer client applied a local inventory payload")
T.equal(#sentCommands, 1,
    "multiplayer inventory request was not sent exactly once")
T.equal(sentCommands[1].command,
    PNC.Const.CMD_REQUEST_CHARACTER_INVENTORY,
    "multiplayer inventory open used the wrong command")
T.equal(sentCommands[1].args.id, "npc_test",
    "multiplayer inventory request used the wrong NPC ID")
T.equal(sentCommands[1].args.requestID, "2",
    "multiplayer inventory request did not include its request ID")

local buildPlayerRowsCalls = 0
local model = {}
function model.FindContainer(containers, containerID)
    for _, entry in ipairs(containers or {}) do
        if tostring(entry.id) == tostring(containerID) then return entry end
    end
    return nil
end
function model.BuildPlayerContainers(currentPlayer)
    return {
        { id = "root", label = "Inventory", container = currentPlayer:getInventory() },
    }
end
function model.BuildPlayerRows(containerEntry)
    buildPlayerRowsCalls = buildPlayerRowsCalls + 1
    local items = containerEntry.container:getItems()
    local rows = {}
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        rows[#rows + 1] = {
            id = item.id,
            name = item.name,
            itemIDs = { item.id },
        }
    end
    return rows
end
PNC.InventoryUIModel = model
PNC.InventoryWindow = {
    CollectBulkTransferIDs = function() return {} end,
}

local registeredEvents = {}
Events = {
    OnContainerUpdate = {
        Add = function(callback) registeredEvents.OnContainerUpdate = callback end,
    },
}
PNC.NPCIdentityPresentation = {
    GetName = function(snapshot) return snapshot.name or "Test NPC" end,
}
T.load(CLIENT_ROOT .. "PNC/UI/Inventory/InventoryWindow/_Refresh.lua")

getSpecificPlayer = function(index)
    T.equal(index, 0, "inventory refresh selected the wrong local player")
    return player
end

local refreshList = function()
    return {
        items = {},
        clear = function(self) self.items = {} end,
        addItem = function(self, label, item)
            self.items[#self.items + 1] = { text = label, item = item }
        end,
    }
end
local npcRevision = 1
local refreshEndpoint = {
    kind = "npc",
    id = "npc_test",
    revision = function() return npcRevision end,
    containers = function()
        return { { id = "root", label = "Inventory" } }
    end,
    rows = function() return {} end,
}
local refreshWindow = setmetatable({
    npcId = "npc_test",
    transferEndpoint = refreshEndpoint,
    selectedNPCContainer = "root",
    selectedPlayerContainer = "root",
    playerContainers = model.BuildPlayerContainers(player),
    expandedPlayerGroups = {},
    playerList = refreshList(),
    npcList = refreshList(),
    playerContainerList = refreshList(),
    npcContainerList = refreshList(),
    inventory = function()
        error("inventory window performed an unused inventory lookup")
    end,
    updateInventoryRefreshButton = function() end,
    payload = function() return { snapshot = { id = "npc_test", name = "Test NPC" } } end,
    setTitle = function(self, value) self.title = value end,
}, { __index = ISPNCInventoryWindow })
PNC.InventoryWindow.instance = refreshWindow

refreshWindow:refreshInventory(true)
T.equal(buildPlayerRowsCalls, 1,
    "initial inventory open did not build player rows exactly once")
T.equal(refreshWindow.playerList.items[1].item.id, "shirt",
    "initial inventory open did not render the player item")
refreshWindow:refreshInventory(false)
refreshWindow:refreshInventory(false)
T.equal(buildPlayerRowsCalls, 1,
    "stable render refreshes rebuilt player inventory rows")

playerItems[1].name = "Clean Shirt"
T.truthy(registeredEvents.OnContainerUpdate,
    "inventory invalidation event was not registered")
registeredEvents.OnContainerUpdate()
refreshWindow:refreshInventory(false)
T.equal(buildPlayerRowsCalls, 2,
    "container update did not rebuild the cached player rows")
T.equal(refreshWindow.playerList.items[1].text, "Clean Shirt",
    "container update did not render the changed player inventory")

playerItems[#playerItems + 1] = { id = "water", name = "Water Bottle" }
playerItemList = javaList(playerItems)
refreshWindow:refreshInventory(false)
T.equal(buildPlayerRowsCalls, 3,
    "player item count change did not rebuild the cached rows")
T.equal(#refreshWindow.playerList.items, 2,
    "player item count change did not render the new item")

T.finish("pnc_inventory_open_perf_smoke")

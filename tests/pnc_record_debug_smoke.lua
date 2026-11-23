local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")
local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")

local originalPrint = print
local output = {}
print = function(message)
    output[#output + 1] = tostring(message)
end

PNC = { Runtime = { debugEnabled = true } }
T.load(SHARED_ROOT .. "PNC/Core/Base/PNC_Core.lua")

local legacyManagedBody = {
    getModData = function()
        return { PNC_UUID = "npc_legacy", PNC_BodyKind = "live" }
    end,
    getVariableBoolean = function(_, name)
        return name == "PNCActor"
    end,
}
local releasedZombie = {
    getModData = function() return {} end,
    getVariableBoolean = function() return false end,
}
T.equal(PNC.Core.IsManagedNPCBody(legacyManagedBody), true,
    "legacy live body remains recognizable during relog")
T.equal(PNC.Core.IsManagedNPCBody(releasedZombie), false,
    "released reanimation remains an ordinary zombie")

-- The native network update can arrive before the presence presentation has
-- written carrier modData. The client identity index must close that first
-- frame without classifying an unrelated zombie by online ID alone.
PNC.Network = {
    ClientState = {
        managedBodyOnlineIDs = { ["73"] = true },
        managedBodyOnlineIDsReady = true,
    },
}
PNC.Core.IsClientOnly = function() return true end
local untaggedReplica = {
    getModData = function() return {} end,
    getVariableBoolean = function() return false end,
    getOnlineID = function() return 73 end,
}
local unrelatedZombie = {
    getModData = function() return {} end,
    getVariableBoolean = function() return false end,
    getOnlineID = function() return 74 end,
}
T.equal(PNC.Core.IsManagedNPCBody(untaggedReplica), false,
    "online ID hint cannot admit an unbound replica")
T.equal(PNC.Core.IsManagedNPCBody(legacyManagedBody), false,
    "client ModData alone cannot admit a replica")
PNC.MultiplayerBodyBinding = { IsClientBody = function(body)
    return body == untaggedReplica
end }
T.equal(PNC.Core.IsManagedNPCBody(untaggedReplica), true,
    "client managed-body admission uses canonical binding")
T.equal(PNC.Core.IsManagedNPCBody(unrelatedZombie), false,
    "roster identity does not classify an unrelated zombie")

local quietRecord = { id = "npc_quiet", runtime = {} }
local recordedRecord = { id = "npc_recorded", runtime = { debug = true } }
PNC.Core.LogRecordDebug(quietRecord, "quiet record")
T.equal(#output, 0, "global debug does not enable record logs")
PNC.Core.LogRecordDebug(recordedRecord, "recorded record")
T.equal(#output, 1, "selected record emits debug log")
T.contains(output[1], "recorded record", "selected record log message")
PNC.Core.LogDebug("global diagnostic")
T.equal(#output, 2, "global diagnostics remain available")

quietRecord.runtime.debugMovement = true
T.load(SHARED_ROOT .. "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context.lua")
T.equal(PNC.PathService.Internal.isMovementDebugEnabled(quietRecord), false,
    "legacy movement flag cannot bypass recording toggle")
T.equal(PNC.PathService.Internal.isMovementDebugEnabled(recordedRecord), true,
    "recording toggle enables movement logs")

PNC.Core.IsClientOnly = function() return true end
PNC.Core.Now = function() return 1000 end
PNC.ClientPresenceSync = {
    MotionLogByID = {},
    Internal = {},
}
T.load(
    CLIENT_ROOT
        .. "PNC/PresenceSync/PNC_ClientPresenceRuntime.lua"
)
PNC.ClientPresenceSync.Internal.LogClientMotionDebug({
    id = "npc_client_quiet",
    debugState = { debugEnabled = false },
}, "npc_client_quiet", "native_controller_start", "goal=1,0,0")
T.equal(#output, 2, "global debug does not enable client NPC logs")
PNC.ClientPresenceSync.Internal.LogClientMotionDebug({
    id = "npc_client_recorded",
    debugState = { debugEnabled = true },
}, "npc_client_recorded", "native_controller_start", "goal=1,0,0")
T.equal(#output, 3, "recorded client NPC emits native-controller log")
T.contains(output[3], "npc=npc_client_recorded", "recorded client NPC identity")
PNC.ClientPresenceSync.Internal.LogClientMotionDebug({
    id = "npc_client_recorded",
    debugState = { debugEnabled = true },
}, "npc_client_recorded", "native_controller_start", "goal=1,0,0")
T.equal(#output, 3, "duplicate native-controller diagnostic is throttled")

print = originalPrint

local entries = {}
PNC = {
    Runtime = { debugEnabled = false },
    NPCSelection = {
        CollectNearbyNPCs = function()
            return entries, nil
        end,
    },
}

getSpecificPlayer = function() return { id = "player" } end
getTexture = function(path) return path end

local function newMenu()
    local menu = {
        options = {},
        submenus = {},
        visible = true,
        mouseOver = 1,
        mouseOut = false,
        topmost = nil,
    }
    function menu:isAnyVisible()
        return self.visible
    end
    function menu:topmostMenuWithMouse()
        return self.topmost
    end
    function menu:addOption(label)
        local option = { name = label }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:addSubMenu(option, submenu)
        option.submenu = submenu
        submenu.parent = self
        self.submenus[#self.submenus + 1] = submenu
    end
    return menu
end

ISContextMenu = {
    getNew = function()
        return newMenu()
    end,
}
local hoverTick
Events = {
    OnTick = {
        Add = function(callback) hoverTick = callback end,
    },
}
getMouseX = function() return 0 end
getMouseY = function() return 0 end

T.load(T.path("ProjectHoomans", "client", "PNC/Knowledge/PNC_NPCIdentityPresentation.lua"))
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(CLIENT_ROOT .. "PNC/UI/Context/PNC_ContextHub.lua")
PNC.ContextHub.RegisterProvider({
    id = "smoke",
    addOptions = function(menu)
        menu:addOption("Action")
    end,
})

entries = {
    { id = "npc_one", displayName = "Nigel Hidalgo", archetypeLabel = "Foreman", tacticalClass = "neutral", activeBehavior = "FollowOwner", distSq = 1, zombie = { highlights = {} } },
    { id = "npc_two", displayName = "Dario Hanna", archetypeLabel = "Foreman", tacticalClass = "hostile", distSq = 4, zombie = { highlights = {} } },
}
for _, entry in ipairs(entries) do
    function entry.zombie:setOutlineHighlight(playerNum, enabled)
        self.highlights[#self.highlights + 1] = {
            playerNum = playerNum,
            enabled = enabled,
        }
    end
    function entry.zombie:setOutlineHighlightCol() end
end
local menu = newMenu()
PNC.ContextHub.BuildWorldContext(0, menu, {}, false)
T.equal(#menu.options, 2, "NPC entries are listed at context root")
T.equal(menu.options[1].name, "Nigel Hidalgo", "normal label hides debug metadata")
T.equal(menu.options[2].name, "Dario Hanna", "second normal label hides debug metadata")
T.equal(menu.options[1].iconTexture, "media/ui/emotes/insult.png", "Talk provider icon")
T.equal(menu.options[2].iconTexture, "media/ui/emotes/insult.png", "shared Talk provider icon")
T.equal(menu.options[1].submenu.options[1].name, "Action", "provider options remain nested under NPC")

PNC.Runtime.debugEnabled = true
menu = newMenu()
PNC.ContextHub.BuildWorldContext(0, menu, {}, false)
T.contains(menu.options[1].name, "[Foreman]", "debug label archetype")
T.contains(menu.options[1].name, "(1.0)", "debug label distance")

PNC.Runtime.debugEnabled = false
entries[1].debugRecording = true
menu = newMenu()
PNC.ContextHub.BuildWorldContext(0, menu, {}, false)
T.contains(menu.options[1].name, "[REC]", "recorded context indicator")
T.contains(menu.options[1].name, "[Foreman]", "recorded NPC exposes debug metadata")
T.equal(menu.options[2].name, "Dario Hanna", "unrecorded NPC remains uncluttered")

-- A transient nil topmost-menu result is normal while vanilla refreshes its
-- mouse-over bookkeeping. It must not drop the selected NPC's outline.
menu.topmost = menu
menu.mouseOver = 1
hoverTick()
T.equal(entries[1].zombie.highlights[#entries[1].zombie.highlights].enabled,
    true, "context hover enables the selected NPC outline")
menu.topmost = nil
hoverTick()
T.equal(entries[1].zombie.highlights[#entries[1].zombie.highlights].enabled,
    true, "transient menu gap preserves the selected NPC outline")
menu.mouseOver = 2
menu.topmost = menu
hoverTick()
T.equal(entries[1].zombie.highlights[#entries[1].zombie.highlights].enabled,
    false, "moving to another NPC clears the old outline")
T.equal(entries[2].zombie.highlights[#entries[2].zombie.highlights].enabled,
    true, "moving to another NPC highlights the new outline")
menu.visible = false
hoverTick()
T.equal(entries[2].zombie.highlights[#entries[2].zombie.highlights].enabled,
    false, "closing the context menu clears the outline")
T.finish("pnc_record_debug_smoke")

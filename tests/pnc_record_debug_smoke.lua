local T = require "tests/support/test"

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
    local menu = { options = {}, submenus = {} }
    function menu:addOption(label)
        local option = { name = label }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:addSubMenu(option, submenu)
        option.submenu = submenu
        self.submenus[#self.submenus + 1] = submenu
    end
    return menu
end

ISContextMenu = {
    getNew = function()
        return newMenu()
    end,
}

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
    { id = "npc_one", name = "Nigel Hidalgo", archetypeLabel = "Foreman", faction = "neutral", activeBehavior = "FollowOwner", distSq = 1 },
    { id = "npc_two", name = "Dario Hanna", archetypeLabel = "Foreman", faction = "hostile", distSq = 4 },
}
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
T.finish("pnc_record_debug_smoke")

T.finish("pnc_record_debug_smoke")

local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/"
local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertContains(value, fragment, label)
    if not string.find(tostring(value), tostring(fragment), 1, true) then
        error((label or "assertContains") .. ": missing=" .. tostring(fragment) .. " value=" .. tostring(value))
    end
end

local originalPrint = print
local output = {}
print = function(message)
    output[#output + 1] = tostring(message)
end

PNC = { Runtime = { debugEnabled = true } }
dofile(SHARED_ROOT .. "PNC/Core/Base/PNC_Core.lua")

local quietRecord = { id = "npc_quiet", runtime = {} }
local recordedRecord = { id = "npc_recorded", runtime = { debug = true } }
PNC.Core.LogRecordDebug(quietRecord, "quiet record")
assertEqual(#output, 0, "global debug does not enable record logs")
PNC.Core.LogRecordDebug(recordedRecord, "recorded record")
assertEqual(#output, 1, "selected record emits debug log")
assertContains(output[1], "recorded record", "selected record log message")
PNC.Core.LogDebug("global diagnostic")
assertEqual(#output, 2, "global diagnostics remain available")

quietRecord.runtime.debugMovement = true
dofile(SHARED_ROOT .. "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context.lua")
assertEqual(PNC.PathService.Internal.isMovementDebugEnabled(quietRecord), false,
    "legacy movement flag cannot bypass recording toggle")
assertEqual(PNC.PathService.Internal.isMovementDebugEnabled(recordedRecord), true,
    "recording toggle enables movement logs")

PNC.Core.IsClientOnly = function() return true end
PNC.Core.Now = function() return 1000 end
PNC.Const = {
    CLIENT_INTERP_BASE_MS = 150,
    CLIENT_INTERP_MOVE_MIN_MS = 200,
    CLIENT_INTERP_SNAP_DISTANCE = 5,
}
dofile(CLIENT_ROOT .. "PNC/PNC_ClientInterpolation.lua")

local zombie = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
PNC.ClientInterpolation.RecordSnapshot({
    id = "npc_client_quiet",
    x = 1,
    y = 0,
    z = 0,
    visualState = { moving = true },
    debugState = { debugEnabled = false },
}, zombie, 1000)
assertEqual(#output, 2, "global debug does not enable client NPC logs")
PNC.ClientInterpolation.RecordSnapshot({
    id = "npc_client_recorded",
    x = 1,
    y = 0,
    z = 0,
    visualState = { moving = true },
    debugState = { debugEnabled = true },
}, zombie, 1000)
assertEqual(#output, 3, "recorded client NPC emits interpolation log")
assertContains(output[3], "npc=npc_client_recorded", "recorded client NPC identity")

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

dofile(CLIENT_ROOT .. "PNC/UI/Context/PNC_ContextHub.lua")
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
assertEqual(#menu.options, 2, "NPC entries are listed at context root")
assertEqual(menu.options[1].name, "Nigel Hidalgo", "normal label hides debug metadata")
assertEqual(menu.options[2].name, "Dario Hanna", "second normal label hides debug metadata")
assertEqual(menu.options[1].iconTexture, "media/ui/emotes/insult.png", "Talk provider icon")
assertEqual(menu.options[2].iconTexture, "media/ui/emotes/insult.png", "shared Talk provider icon")
assertEqual(menu.options[1].submenu.options[1].name, "Action", "provider options remain nested under NPC")

PNC.Runtime.debugEnabled = true
menu = newMenu()
PNC.ContextHub.BuildWorldContext(0, menu, {}, false)
assertContains(menu.options[1].name, "[Foreman]", "debug label archetype")
assertContains(menu.options[1].name, "(1.0)", "debug label distance")

PNC.Runtime.debugEnabled = false
entries[1].debugRecording = true
menu = newMenu()
PNC.ContextHub.BuildWorldContext(0, menu, {}, false)
assertContains(menu.options[1].name, "[REC]", "recorded context indicator")
assertContains(menu.options[1].name, "[Foreman]", "recorded NPC exposes debug metadata")
assertEqual(menu.options[2].name, "Dario Hanna", "unrecorded NPC remains uncluttered")

print("pnc_record_debug_smoke: ok")

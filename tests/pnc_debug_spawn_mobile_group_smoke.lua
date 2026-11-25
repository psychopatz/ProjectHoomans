local T = require "tests/support/test"

local CLIENT = T.path("ProjectHoomans", "client", "PNC/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

function isClient() return false end
function isServer() return true end
function getGameTime()
    return { getWorldAgeHours = function() return 14.5 end }
end

-- 1. Client menu exposes [Debug] Spawn Hoomans -> Single / Group submenus
local sentCommands = {}
PNC = {
    Client = {
        CanUseDebug = function() return true end,
        SendDebug = function(action, payload)
            sentCommands[#sentCommands + 1] = { action = action, payload = payload }
            return true
        end,
    },
    Core = { LogInfo = function() end, LogWarn = function() end },
    Const = {},
    ServerDebugCommandHandler = { Internal = {} },
}

local function makeMenu()
    local m = { options = {}, submenus = {} }
    function m:addOption(label, target, cb, ...)
        local opt = { label = label, target = target, cb = cb, args = { ... } }
        self.options[#self.options + 1] = opt
        return opt
    end
    function m:addSubMenu(opt, sub)
        self.submenus[opt.label] = sub
    end
    return m
end
ISContextMenu = { getNew = function() return makeMenu() end }

T.load(CLIENT .. "UI/Context/PNC_DebugSpawnMenu.lua")
local topCtx = makeMenu()
local sq = { getX = function() return 100 end, getY = function() return 200 end, getZ = function() return 0 end }
local root = PNC.DebugSpawnMenu.Add(topCtx, sq)
T.truthy(root, "root debug spawn menu created")
T.truthy(root.submenus["Single"], "Single submenu exists")
T.truthy(root.submenus["Group"], "Group submenu exists")
T.equal(#root.submenus["Single"].options, 3, "Single submenu retains Companion, Neutral, Hostile")
T.equal(#root.submenus["Group"].options, 4, "Group submenu exposes Refugee, Refugee Travel, Looter, Looter Raid")

-- Click Refugee Group (Ambient) -> 5 Members
local refSub = root.submenus["Group"].submenus["Refugee Group (Ambient)"]
T.truthy(refSub, "Refugee Group has size submenu")
local opt5 = refSub.options[2]
opt5.cb(opt5.target, opt5.args[1], opt5.args[2], opt5.args[3])
T.equal(#sentCommands, 1, "group option sends debug command")
T.equal(sentCommands[1].action, "spawn_mobile_group", "uses spawn_mobile_group action")
T.equal(sentCommands[1].payload.archetypeID, "refugee", "passes refugee archetype")
T.equal(sentCommands[1].payload.groupSize, 5, "passes 5 members")
T.equal(sentCommands[1].payload.presenceMode, "live", "requests live presence at clicked tile")

-- 2. Server Handler.SpawnMobileGroup routes through production Factions + MobileGroupDirector
local createdFaction = nil
local generatedSpec = nil
local refreshedID = nil
local travelStartedID = nil
PNC.FactionArchetypes = {
    Get = function(id)
        if id == "refugee" or id == "looter" then return { id = id } end
        return nil
    end,
}
PNC.Factions = {
    Create = function(spec)
        createdFaction = { id = "faction:debug_1", archetypeID = spec.archetypeID, tags = spec.tags }
        return true, "created", createdFaction
    end,
}
PNC.MobileGroupDirector = {
    GenerateForFaction = function(fid, spec)
        generatedSpec = { fid = fid, spec = spec }
        return true, "generated", { memberCount = spec.groupSize }
    end,
    RefreshFactionObjective = function(fid)
        refreshedID = fid
        return true
    end,
    StartSettlementTravel = function(fid)
        travelStartedID = fid
        return true
    end,
}

package.loaded["PNC/Core/Companions/PNC_DebugCompanionInitialization"] = {}
T.load(SERVER .. "Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Core.lua")

local faction, reason = PNC.ServerDebugCommandHandler.SpawnMobileGroup(nil, {
    archetypeID = "refugee",
    mobileControlMode = "ambient",
    mobilePathMode = "random",
    startSettlementTravel = true,
    groupSize = 5,
    x = 100, y = 200, z = 0,
})
T.truthy(faction, "SpawnMobileGroup creates real faction")
T.equal(reason, "spawned", "returns spawned status")
T.equal(createdFaction.tags.mobileGroup, true, "marks faction as real mobileGroup")
T.equal(generatedSpec.fid, faction.id, "calls MobileGroupDirector.GenerateForFaction")
T.equal(generatedSpec.spec.presenceMode, "live", "spawns live at requested square")
T.truthy(generatedSpec.spec.siteSpec and generatedSpec.spec.siteSpec.home, "passes explicit siteSpec anchored at clicked square")
T.equal(generatedSpec.spec.siteSpec.home.x, 100, "siteSpec home.x matches clicked x")
T.equal(generatedSpec.spec.siteSpec.home.y, 200, "siteSpec home.y matches clicked y")
T.equal(refreshedID, faction.id, "refreshes mobile objective immediately")
T.equal(travelStartedID, faction.id, "starts settlement travel when requested")

-- 3. Singleplayer ClientActions local handler dispatches spawn_mobile_group
PNC.Network = { ClientState = {} }
local spawnHandlers = dofile(CLIENT .. "Networking/ClientActions/PNC_ClientActions_Debug_Spawn.lua")
T.truthy(type(spawnHandlers.spawn_mobile_group) == "function", "PNC_ClientActions_Debug_Spawn exposes spawn_mobile_group for singleplayer")
local spOk, spReason = spawnHandlers.spawn_mobile_group(nil, {
    archetypeID = "looter",
    groupSize = 3,
    x = 50, y = 60, z = 0,
})
T.truthy(spOk, "singleplayer spawn_mobile_group executes server handler directly")
T.equal(spReason, "spawned", "returns spawned reason in singleplayer")

T.finish("pnc_debug_spawn_mobile_group_smoke")

local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

PNC = {
    Core = {
        Now = function() return 1000 end,
    },
    PuppetOpera = {
        Client = {
            GetNearbyNPCs = function() return {} end,
            GetSnapshot = function() return nil end,
            GetTrace = function() return {} end,
            GetStatus = function() return "idle", nil end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel.lua"
)

local Model = PNC.PuppetOperaDebugModel
local liveRows = {
    {
        id = "npc-cache-one",
        name = "NPC Cache One",
        distSq = 1,
        zombie = {},
        record = {},
    },
}
local discoveryCalls = 0
PNC.PuppetOpera.Client.GetNearbyNPCs = function()
    discoveryCalls = discoveryCalls + 1
    return liveRows
end

Model.BeginRefresh()
local firstLiveRows = Model.GetLiveActorRows(12)
local secondLiveRows = Model.GetLiveActorRows(12)
T.equal(firstLiveRows, secondLiveRows,
    "refresh did not reuse the live actor rows")
T.equal(discoveryCalls, 1,
    "identical live-row reads repeated external discovery")

local firstActorRows = Model.GetActorRows(nil)
local secondActorRows = Model.GetActorRows(nil)
T.equal(firstActorRows, secondActorRows,
    "refresh did not reuse actor rows")
T.equal(discoveryCalls, 1,
    "actor-row reads bypassed the live-row refresh cache")

local targetRows = Model.GetAnimationTargetRows("npc")
T.truthy(targetRows, "target rows could not be built from the refresh cache")
T.equal(discoveryCalls, 1,
    "animation target generation repeated external discovery")

Model.SelectActor("actor_2")
Model.GetLiveActorRows(12)
T.equal(discoveryCalls, 2,
    "editor state change did not invalidate refresh-local rows")
Model.EndRefresh()

liveRows = {
    {
        id = "npc-cache-two",
        name = "NPC Cache Two",
        distSq = 1,
        zombie = {},
        record = {},
    },
}
local nextRows = Model.GetLiveActorRows(12)
T.equal(discoveryCalls, 3,
    "refresh cache survived outside its explicit scope")
T.equal(nextRows[1].id, "npc-cache-two",
    "post-refresh discovery returned stale live data")

return T.finish("pnc_puppet_opera_refresh_cache_smoke")

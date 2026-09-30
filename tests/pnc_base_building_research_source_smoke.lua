-- The Facilities build gate reads the learned technology list from the Base
-- window's own projection. That projection never carried `research`, so a
-- technology the colony had already learned still reported RESEARCH REQUIRED
-- forever. The base snapshot now ships the learned ids; the client also falls
-- back to the cached management projection.
local T = require "tests/support/test"

T.addPackagePaths()

package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return { Probe = function(fullType) return { name = tostring(fullType) } end }
end

getSpecificPlayer = function() return nil end

PNC = {
    FacilityDefinitions = { Get = function() return {} end },
    Network = { ClientState = {} },
}

local Data = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingData.lua")

-- 1. Base projection carries the learned set.
local learned = { "facility:workshop", "hq:2" }
local research = Data.Research({ snapshot = {} }, {
    research = { learnedTechnologyIds = learned, knowledgeRevision = 4 },
})
T.truthy(research ~= nil, "base research projection is used")
T.equal(research.learnedTechnologyIds[1], "facility:workshop",
    "learned technologies travel with the base snapshot")

-- 2. No base research yet: fall back to the management projection, whose set is
--    kept current by the colony knowledge delta.
PNC.Network.ClientState.colonyManagement = {
    research = { learnedTechnologyIds = { "facility:workshop" } },
}
research = Data.Research({ snapshot = {} }, {})
T.truthy(research ~= nil, "management research is used as a fallback")
T.equal(research.learnedTechnologyIds[1], "facility:workshop",
    "fallback carries the learned technologies")

-- 3. Neither projection: report nothing learned rather than inventing a set.
PNC.Network.ClientState.colonyManagement = nil
research = Data.Research({ snapshot = {} }, {})
T.falsy(research ~= nil, "missing projections resolve to no research")

-- 4. A base projection with an empty learned list must still win over a stale
--    management cache (empty is a valid answer).
research = Data.Research({ snapshot = {} },
    { research = { learnedTechnologyIds = {} } })
T.truthy(research ~= nil, "empty learned list is a valid base answer")
T.equal(#research.learnedTechnologyIds, 0,
    "empty learned list is preserved")

-- 5. The server projection actually ships it.
local snapshots = T.read("ProjectHoomans", "server",
    "PNC/Colony/ColonyManagement/PNC_ColonyManagement_Snapshots.lua")
T.contains(snapshots, "learnedTechnologyIds",
    "base snapshot does not ship learned technologies")
T.contains(snapshots, "ResearchRepository.Get(colony.id, false)",
    "base snapshot walks the heavy research projection instead of the state")
local view = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingView.lua")
T.contains(view, "Data.Research(window, snapshot)",
    "facilities tab does not resolve research knowledge")

T.finish("pnc_base_building_research_source_smoke")

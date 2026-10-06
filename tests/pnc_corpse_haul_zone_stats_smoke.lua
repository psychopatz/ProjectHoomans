local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

PNC = {
    Core = { Now = function() return 1234 end },
    BodyLifecycle = { Internal = {
        forEachCorpse = function() end,
    } },
    BaseService = {
        Get = function()
            return { id = "base:zone" }
        end,
    },
    CorpseHaulService = {
        Runtime = { byDrop = {}, destinationStatsByBase = {} },
        Internal = {
            configurationFor = function()
                return {
                    revision = 1,
                    destinationRegion = { levels = {} },
                }
            end,
        },
        CORPSE_COUNT_CACHE_MS = 2000,
    },
}

local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_World_Helpers.lua"
)

-- The regression was a free global `Core` lookup. The module must use the
-- shared PNC.Core clock and remain safe when no world square is loaded.
local stats = Service.GetDestinationTileStats("base:zone")
T.truthy(stats, "destination stats are available")
T.equal(stats.total, 0, "empty configured region is bounded")
T.equal(stats.updatedAt, 1234, "shared Core.Now is used")

T.finish("pnc_corpse_haul_zone_stats_smoke")

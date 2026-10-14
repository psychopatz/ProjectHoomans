local T = require "tests/support/test"
T.addPackagePaths()

local store = {}
local worldHours = 100

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogDebug = function() end,
        LogInfo = function() end,
        LogWarn = function() end,
        IsAuthority = function() return true end,
    },
    Const = {
        HUSK_LEDGER_MODDATA_KEY = "Test_HuskPopulationLedger",
        HUSK_LEDGER_LAYOUT_VERSION = 1,
        HUSK_LEDGER_MAX_ENTRIES = 8,
        HUSK_LEDGER_MAX_PER_RECORD = 2,
        HUSK_LEDGER_TTL_HOURS = 72,
        HUSK_LEDGER_MATCH_RADIUS = 2.0,
    },
}

ModData = {
    getOrCreate = function()
        return store
    end,
}

getGameTime = function()
    return {
        getWorldAgeHours = function()
            return worldHours
        end,
    }
end

local function makeZombie(x, y, z, populationId)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        persistentId = populationId,
    }
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger.lua"
)

local Lifecycle = PNC.BodyLifecycle
local record = {
    id = "npc_population_only",
    x = 100,
    y = 200,
    z = 0,
    runtime = {},
}
local lost = makeZombie(100.5, 200.5, 0, 901)
local entry = Lifecycle.NoteLostBody(record, lost, "population_only_loss")

T.truthy(entry, "population-only body loss was discarded")
T.falsy(entry.outfitId, "population-only entry gained a weak outfit identity")
T.equal(entry.populationId, "901", "population identity was not retained")

local returned = makeZombie(9000, 9000, 0, 901)
T.equal(
    Lifecycle.FindHuskEntry(returned),
    entry,
    "exact population identity did not match after movement"
)
T.truthy(
    Lifecycle.HuskLedgerMatchesEntry(returned, entry),
    "exact population identity failed revalidation"
)
T.falsy(
    Lifecycle.FindHuskEntry(makeZombie(9000, 9000, 0, 902)),
    "wrong population identity matched the husk entry"
)

worldHours = worldHours + 200
Lifecycle.PumpHuskLedger(2000)
T.equal(Lifecycle.HuskLedgerCount(), 0,
    "population-only husk entry did not expire normally")

return T.finish("pnc_husk_population_identity_smoke")

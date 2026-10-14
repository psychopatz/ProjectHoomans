local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local store = {}
local dirtyReasons = {}
local registry = {
    MarkDirty = function(record, reason)
        dirtyReasons[#dirtyReasons + 1] = tostring(reason)
    end,
}

PNC = {
    Core = {
        GenerateID = function(prefix) return prefix .. "_carrier" end,
    },
    Const = {
        BODY_TAG_VERSION = 1,
        BODY_SHELL_VERSION = 1,
        BODY_SHELL_OUTFIT = "PNCShellCarrier",
        BODY_SHELL_CARRIER_VERSION = 1,
        HUSK_LEDGER_MAX_SHELL_CARRIERS = 256,
    },
    BodyLifecycle = {
        Internal = {
            registry = function() return registry end,
            mark = function() end,
        },
        GetBodyPopulationID = function(zombie)
            return zombie and zombie.persistentId
                and tostring(zombie.persistentId) or nil
        end,
    },
}

ModData = {
    getOrCreate = function() return store end,
}

local record = { id = "npc_carrier", runtime = {} }
local modData = {}
local body = {
    persistentId = 901,
    getModData = function() return modData end,
    getPersistentOutfitID = function() return 777 end,
}

T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger.lua")
T.load(ROOT .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_LiveBodies.lua")

T.equal(PNC.BodyLifecycle.StampLiveBody(record, body), "body_carrier",
    "carrier body lease was not created")
T.equal(modData.PNC_ShellCarrier, "PNCShellCarrier",
    "live body did not carry the PNC-only outfit name")
T.equal(modData.PNC_BaseOutfit, "PNCShellCarrier",
    "legacy Naked outfit was still stamped as the base outfit")
T.equal(modData.PNC_ShellCarrierVersion, 1,
    "carrier version was not stamped")
T.equal(record.liveBodyInstanceID, "777",
    "persistent outfit id was not captured")
T.equal(record.liveBodyPopulationID, "901",
    "population id was not captured after body registration")
T.truthy(PNC.BodyLifecycle.IsShellOutfitID(777),
    "persistent outfit id was not added to the shell ledger")
T.truthy(PNC.BodyLifecycle.IsShellCarrierID(777),
    "persistent outfit id was not added to the carrier ledger")
T.truthy(store.shellCarrierIds["777"],
    "carrier id was not persisted")
T.equal(dirtyReasons[1], "live_body_hint",
    "carrier binding did not dirty the registry")
T.falsy(PNC.BodyLifecycle.NoteShellCarrierID(0),
    "zero outfit id was learned as a carrier")
T.falsy(PNC.BodyLifecycle.IsShellCarrierID(0),
    "zero outfit id was treated as a carrier")

PNC.BodyLifecycle.NoteShellOutfitID(778)
T.truthy(PNC.BodyLifecycle.IsShellOutfitID(778),
    "legacy shell outfit was not retained for strict matching")
T.falsy(PNC.BodyLifecycle.IsShellCarrierID(778),
    "legacy shell outfit was promoted to a strong carrier")
T.load(ROOT
    .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/"
    .. "PNC_BodyLifecycle_Startup_Identity.lua")

local carrierBody = {
    getModData = function() return {} end,
    getPersistentOutfitID = function() return 777 end,
    isDead = function() return false end,
}
local legacyBody = {
    getModData = function() return {} end,
    getPersistentOutfitID = function() return 778 end,
    isDead = function() return false end,
}
local _, strongCarrier, weakCarrier =
    PNC.BodyLifecycle.Internal.GetLiveShellIdentity(carrierBody)
local _, strongLegacy, weakLegacy =
    PNC.BodyLifecycle.Internal.GetLiveShellIdentity(legacyBody)
T.truthy(strongCarrier, "learned PNC carrier was not a strong shell identity")
T.falsy(weakCarrier, "carrier unexpectedly depended on weak useless state")
T.falsy(strongLegacy, "unlearned outfit id was treated as a PNC shell")
T.falsy(weakLegacy, "unlearned outfit unexpectedly became weak identity")

for index = 1, 30 do
    store.shellOutfitIds["legacy_" .. tostring(index)] = true
end
T.truthy(PNC.BodyLifecycle.NoteShellCarrierID(779),
    "full legacy shell-outfit set blocked a new carrier id")
T.truthy(PNC.BodyLifecycle.IsShellCarrierID(779),
    "new carrier id was not retained in its separate namespace")

T.finish("pnc_shell_carrier_smoke")

local T = require "tests/support/test"

local values = {}
local warnings = 0
PNC = {
    Core = {
        Now = function() return 42 end,
        LogWarn = function() warnings = warnings + 1 end,
    },
}
ModData = {
    get = function(key) return values[key] end,
    getOrCreate = function(key)
        values[key] = values[key] or {}
        return values[key]
    end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
}

local Reset = T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset.lua")

T.equal(Reset.Check(nil, 2), "empty_state", "missing root is first-run state")
T.equal(Reset.Check({}, 2), "empty_state", "empty root is first-run state")
T.equal(Reset.Check({ schemaVersion = 2, rows = {} }, 2, nil,
    function(value) return type(value.rows) == "table" end), nil,
    "current root is accepted")
T.equal(Reset.Check({ schemaVersion = 1, rows = {} }, 2),
    "version_mismatch", "older root is rejected")
T.equal(Reset.Check({ schemaVersion = 3, rows = {} }, 2),
    "version_mismatch", "future root is rejected")
T.equal(Reset.Check({ schemaVersion = 2 }, 2, nil,
    function(value) return type(value.rows) == "table" end),
    "invalid_state", "malformed current root is rejected")

local store = {}
Reset.Mark(store, { schemaVersion = 1 }, 2, "version_mismatch", "smoke")
T.equal(store.Dirty, true, "reset marks the owner dirty")
T.equal(store.LastReset.fromVersion, 1, "reset keeps source version in runtime")
T.equal(store.LastReset.toVersion, 2, "reset keeps target version in runtime")
T.equal(warnings, 1, "reset emits one owner warning")

values.example = { schemaVersion = 1, stale = true }
local written = Reset.Write("example", { schemaVersion = 2, rows = {} })
T.equal(written, true, "reset rewrite succeeds")
T.equal(values.example.stale, nil, "rewrite removes stale fields")
T.equal(values.example.schemaVersion, 2, "rewrite writes current version")

PNC.Conversation = {}
local History = T.load("ProjectHoomans", "server",
    "PNC/Conversation/PNC_ConversationHistory.lua")
values[History.MODDATA_KEY] = { version = 0, entries = { stale = true } }
History.Loaded = false
History.Load()
T.equal(History.Dirty, true, "history schedules a version reset")
T.equal(History.LastReset.reason, "version_mismatch",
    "history records the reset reason")
T.equal(History.Registry.entries.stale, nil,
    "history discards unsupported entries")
History.Save(false)
T.equal(values[History.MODDATA_KEY].version, History.VERSION,
    "history rewrites its current version")
T.equal(values[History.MODDATA_KEY].entries.stale, nil,
    "history rewrite contains no stale entries")

T.finish("pnc_persistence_reset_smoke")

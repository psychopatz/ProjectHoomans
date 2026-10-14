local T = require "tests/support/test"

local State = T.load("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopGroupState.lua")
local catalogSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopCatalog.lua")
local searchSource = T.read("PsychopatzCore", "client",
    "PsychopatzCore/UI/Components/PsychopatzTextEntry.lua")

T.contains(catalogSource, "CreateSearchEntry",
    "workshop must use the shared search entry")
T.contains(catalogSource, "workshopCollapseAll",
    "workshop must expose a collapse-all control")
T.contains(catalogSource, "workshopExpandAll",
    "workshop must expose an expand-all control")
T.contains(searchSource, "Search_Icon_On.png",
    "shared search entry must use the vanilla search icon")
T.contains(searchSource, "CreateSearchEntry",
    "core must expose a reusable search entry")

local groups = {
    ["skill:CRAFT:|:BLACKSMITH"] = true,
    ["station:CRAFT:forge|advanced%"] = true,
    ["expanded-group"] = false,
}
local encoded = State.Encode(groups)
T.equal(encoded,
    "skill:CRAFT:%7C:BLACKSMITH|station:CRAFT:forge%7Cadvanced%25",
    "collapsed group serialization must be deterministic and escaped")
local decoded = State.Decode(encoded)
T.truthy(decoded["skill:CRAFT:|:BLACKSMITH"],
    "escaped group separator was not restored")
T.truthy(decoded["station:CRAFT:forge|advanced%"],
    "escaped group key was not restored")
T.falsy(decoded["expanded-group"],
    "expanded groups must not be persisted")

local store = { loaded = false, values = { workshopCollapsedGroups = encoded } }
function store:Load() self.loaded = true end
function store:Get(key, fallback) return self.values[key] or fallback end
function store:Set(key, value) self.values[key] = value end
local loaded = State.Load(store)
T.truthy(store.loaded and loaded["station:CRAFT:forge|advanced%"],
    "stored collapse state did not load through the settings store")
State.Save(store, { ["skill:CRAFT:BLACKSMITH"] = true })
T.equal(store.values.workshopCollapsedGroups, "skill:CRAFT:BLACKSMITH",
    "stored collapse state did not save through the settings store")

T.finish("pnc_workshop_group_state_smoke")

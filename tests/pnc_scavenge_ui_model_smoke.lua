local T = require "tests/support/test"

PNC = {}
local Model = T.load("ProjectHoomans", "client",
    "PNC/UI/Scavenge/PNC_ScavengeUIModel.lua")

local manifest = {
    { entryId = "beans:fridge:1", sourceToken = "fridge",
        sourceType = "container", sourceLabel = "Fridge",
        fullType = "Base.CannedBeans",
        displayName = "Canned Beans", quantity = 2, status = "AVAILABLE" },
    { entryId = "beans:corpse:1", sourceToken = "corpse",
        sourceType = "corpse", fullType = "Base.CannedBeans",
        displayName = "Canned Beans", quantity = 1, status = "AVAILABLE" },
    { entryId = "bandage:floor:1", sourceToken = "floor",
        sourceType = "floor", fullType = "SomeMod.FieldBandage",
        displayName = "Field Bandage", quantity = 1,
        autoGrab = true, status = "AVAILABLE" },
}

local groups = Model.GroupManifest(manifest)
T.equal(#groups, 2, "identical FullTypes collapse into parent rows")
T.equal(groups[1].fullType, "Base.CannedBeans", "groups sort by display name")
T.equal(groups[1].quantity, 3, "parent quantity sums source records")
T.equal(#groups[1].entries, 2, "parent retains source breakdown")
T.equal(groups[1].entries[1].sourceToken, "fridge",
    "source token survives UI grouping")
T.equal(groups[1].entries[2].sourceToken, "corpse",
    "second source survives UI grouping")

local sources = Model.GroupManifestBySource(manifest)
T.equal(#sources, 3, "container sources are manifest roots")
T.equal(sources[3].sourceLabel, "Fridge", "container name is root label")
T.equal(#sources[3].items, 1, "expanding source reveals grouped contents")
T.equal(sources[3].items[1].displayName, "Canned Beans",
    "source child uses item display name")
T.equal(sources[3].items[1].quantity, 2,
    "source child retains item quantity")

local auto = Model.SelectableEntryIDs(manifest, {}, true)
T.equal(#auto, 1, "auto-grab selection is exact FullType result")
T.equal(auto[1], "bandage:floor:1", "auto-grab entry")
local manual = Model.SelectableEntryIDs(manifest,
    { ["beans:corpse:1"] = true }, false)
T.equal(#manual, 1, "manual selection only includes chosen entry")
T.equal(manual[1], "beans:corpse:1", "manual entry ID")
local all = Model.AllAvailableEntryIDs(manifest)
T.equal(#all, 3, "take all includes every available source entry")

T.finish("pnc_scavenge_ui_model_smoke")

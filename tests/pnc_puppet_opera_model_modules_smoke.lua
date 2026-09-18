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
T.equal(Model, PNC.PuppetOperaDebugModel,
    "debug model entry did not preserve namespace identity")
T.truthy(Model.Internal and Model.Internal.State,
    "state provider was not loaded through the entry hub")
T.truthy(Model.Internal.currentDraft and Model.Internal.touch,
    "shared state contracts were not installed")
T.truthy(Model.Internal.actorDefinition and Model.Internal.actorBinding
    and Model.Internal.findLiveActorRow,
    "live actor contract provider was not loaded")
T.truthy(Model.GetDraft(), "draft provider was not loaded")
T.truthy(Model.GetNearbyNPCs and Model.GetActorDiscoveryRadius,
    "live actor discovery provider was not loaded")
T.truthy(Model.GetLiveActorRows, "live actor provider was not loaded")
T.truthy(Model.BindLiveActor and Model.UnbindLiveActor,
    "live actor binding provider was not loaded")
T.truthy(Model.SelectLiveActor and Model.GetSelectedNPCID,
    "live actor selection provider was not loaded")
T.truthy(Model.GetActorRows and Model.GetGridActors
    and Model.GetGridPreview and Model.GetActorAtOffset,
    "layout projection provider was not loaded")
T.truthy(Model.SetActorAnchorOffset,
    "layout anchor provider was not loaded")
T.truthy(Model.Internal.validateAnchorOffset
    and Model.Internal.commitAnchorOffset,
    "layout anchor contracts were not installed")
T.truthy(Model.AddActorContainer and Model.RemoveActor,
    "layout actor-slot provider was not loaded")
T.truthy(Model.AddLiveActorToScene,
    "layout live-placement provider was not loaded")
T.truthy(Model.GetBeatRows, "beat provider was not loaded")
T.truthy(Model.Internal.trackForBeat and Model.Internal.beatTrackSummary
    and Model.Internal.ensureTracks and Model.Internal.uniqueID
    and Model.Internal.beatAt,
    "beat shared contracts were not installed before downstream spokes")
T.truthy(Model.GetPlayerCatalogEntries,
    "catalog provider was not loaded")
T.truthy(Model.GetPlayerSource and Model.SetPlayerSource
    and Model.GetNPCState and Model.SetNPCState
    and Model.Internal.entryID and Model.Internal.bumpType
    and Model.Internal.directNPCEntry,
    "catalog state and authority contracts were not loaded")
T.truthy(Model.GetAnimationTargetRows,
    "animation target provider was not loaded")
T.truthy(Model.GetAnimationTarget and Model.SetAnimationTarget
    and Model.GetPreviewTarget and Model.GetActorForCatalog,
    "animation target selection spokes were not loaded")
T.truthy(Model.AssignAnimation,
    "animation assignment provider was not loaded")

local before = Model.GetChangeSerial()
local accepted, reason = Model.SetBlueprintID("missing.debug.blueprint")
T.falsy(accepted, "missing blueprint was accepted")
T.equal(reason, "blueprint_not_found",
    "missing blueprint returned an unstable reason")
T.equal(Model.GetChangeSerial(), before,
    "rejected blueprint selection changed editor state")

local beatRows = Model.GetBeatRows()
T.truthy(beatRows[1] and beatRows[1].summary,
    "beat catalog did not project the selected draft")
local invalidDuration, durationReason = Model.SetBeatDuration(99)
T.falsy(invalidDuration, "invalid beat duration was accepted")
T.equal(durationReason, "duration_must_be_100_to_10000_ms",
    "invalid beat duration returned an unstable reason")
T.truthy(Model.SetBeatDuration(1000),
    "valid beat duration was rejected")
T.truthy(Model.AddBeat(), "beat insertion failed")
T.truthy(Model.DuplicateBeat(), "beat duplication alias failed")
T.falsy(Model.MoveBeat(1), "out-of-range beat move was accepted")
T.equal(Model.MoveBeat(-1), true, "valid beat move failed")
T.truthy(Model.RemoveBeat(), "beat removal failed")
local invalidBeat, invalidBeatReason = Model.SelectBeat(999)
T.falsy(invalidBeat, "missing beat selection was accepted")
T.equal(invalidBeatReason, "beat_not_found",
    "missing beat selection returned an unstable reason")
T.truthy(Model.RemoveBeat(), "last removable beat could not be removed")
local lastBeat, lastBeatReason = Model.RemoveBeat()
T.falsy(lastBeat, "last beat removal violated the minimum invariant")
T.equal(lastBeatReason, "at_least_one_beat_required",
    "last beat removal returned an unstable reason")

return T.finish("pnc_puppet_opera_model_modules_smoke")

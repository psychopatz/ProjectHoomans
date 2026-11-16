local T = require "tests/support/test"

T.addPackagePaths()

local profileSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Profile.lua")
local editorSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor.lua")
local debugSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow.lua")
local companionSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/StartingCompanions/PNC_StartingCompanionComposerWindow.lua")
local composerSource = T.read(
    "ProjectHoomans", "client",
    "PNC/Identity/PNC_NPCAuthoringComposer.lua")
local adapterSource = T.read(
    "ProjectHoomans", "client",
    "PNC/CharacterCreation/PNC_StartingCompanionAuthoringAdapter.lua")
local previewSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Preview.lua")
local lifecycleSource = T.read(
    "ProjectHoomans", "client",
    "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Lifecycle.lua")
local segmentSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Translation/PNC_TranslationBootstrap_Segments.lua")

T.contains(profileSource, "identity.nickname",
    "presentation profile owns canonical nickname metadata")
T.contains(editorSource, "ISPNCNPCAuthoringEditor",
    "shared authoring component has a stable class")
T.contains(editorSource, "clearPresentation",
    "shared authoring component clears stale no-selection state")
T.contains(editorSource, "self:refreshFromAdapter(true)",
    "shared authoring component rebuilds after every valid adapter bind")
T.contains(debugSource, "ISPNCNPCAuthoringEditor:new",
    "debug creator hosts the shared authoring component")
T.contains(debugSource, 'mode = "debug"',
    "debug creator uses the debug presentation profile")
T.contains(companionSource, "ISPNCNPCAuthoringEditor:new",
    "starting companion hosts the shared authoring component")
T.contains(companionSource, 'mode = "companion"',
    "starting companion uses the companion presentation profile")
T.contains(companionSource, "PsychopatzFixedWindow",
    "starting companion uses the fixed non-collapsible host")
T.contains(companionSource, "Store.Save",
    "starting companion exposes the existing preset store")
T.contains(companionSource, "Store.Load",
    "starting companion loads through the existing preset store")
T.contains(companionSource, "Presets.ApplyToSession",
    "preset application stays on the canonical session")
T.contains(adapterSource, "session:SetField",
    "companion edits use the policy-aware session setter")
T.contains(adapterSource, "session:ClearField",
    "companion clears use the policy-aware session clearer")
T.contains(lifecycleSource, "ISPNCNPCAuthoringEditor",
    "mature editor lifecycle is attached to the shared component")
T.contains(previewSource, "Model.BuildPortraitSpec",
    "both hosts retain the mature portrait preview path")
T.contains(previewSource, "previewSpecKey",
    "portrait preview exposes an explicit current spec identity")
T.contains(adapterSource, "PreviewGenerationIdentity",
    "companion adapter exposes deterministic preview generation identity")
T.contains(companionSource, "SelectCompanion",
    "companion selection uses one bounded state transaction")
T.contains(companionSource, "target, combo",
    "companion callbacks use the vanilla combo argument order")
T.contains(segmentSource, "NPCAuthoring = \"Character\"",
    "authoring labels resolve through the Character catalog")
T.contains(segmentSource, "Relationship = \"Character\"",
    "relationship labels resolve through the Character catalog")
T.contains(composerSource, "Composer:FieldRows",
    "canonical field rows remain available for diagnostics")
T.falsy(string.find(companionSource, "FieldRows(", 1, true),
    "normal companion presentation does not enumerate raw registry rows")
T.falsy(string.find(companionSource, "<table>", 1, true),
    "normal companion presentation does not render table placeholders")

PNC = {
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}
local Profile = T.load(
    "ProjectHoomans", "client",
    "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Profile.lua")
local companionFields = Profile.List("companion")
local companionIDs = {}
for _, field in ipairs(companionFields) do companionIDs[field.id] = true end

T.truthy(companionIDs["identity.forename"],
    "companion profile includes first name")
T.truthy(companionIDs["identity.nickname"],
    "companion profile includes canonical nickname")
T.truthy(companionIDs["identity.surname"],
    "companion profile includes surname")
T.truthy(companionIDs["appearance.hairModel"],
    "companion profile includes hair")
T.truthy(companionIDs["appearance.beardModel"],
    "companion profile includes beard")
T.truthy(companionIDs["skills.baseLevels"],
    "companion profile includes shared skills")
T.truthy(companionIDs["traits.npc"],
    "companion profile includes shared NPC traits")
T.truthy(companionIDs["traits.physiological"],
    "companion profile includes shared vanilla traits")
T.truthy(companionIDs["traits.dynamic"],
    "companion profile includes shared dynamic traits")
T.falsy(companionIDs.factionID,
    "companion profile does not leak debug faction authoring")
T.equal(Profile.Label("identity.nickname"), "Nickname",
    "profile resolves nickname to a human label")
T.equal(Profile.SourceHelp("inherited"), "Inherited from Player",
    "profile gives inherited fields a human source explanation")
T.equal(Profile.SourceHelp("derived"), "Relationship Rule",
    "profile gives derived fields a human source explanation")

T.finish("pnc_shared_npc_authoring_editor_smoke")

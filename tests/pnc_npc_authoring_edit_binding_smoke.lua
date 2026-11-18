local F = require('tests/support/pnc_authoring_session')()
local T, Session, Adapter, Model, IDs = F.T, F.Session, F.Adapter, F.Model, F.TID
local session = Session.New({ sessionSeed = 42, context = F.context('Family', false, 'straight') })
session:Reconcile({ IDs.FRIEND, IDs.BROTHER }, session:GetContext())
local adapter = Adapter.New(session, IDs.FRIEND)
PNC.UniqueNPCAppearanceUI = { Internal = { Appearance = PNC.Identity.Appearance } }
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Options_Core.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Options_Catalog.lua')
ISPNCUniqueNPCAppearanceWindow = { Internal = PNC.UniqueNPCAppearanceUI.Internal }
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Editing.lua')
ISPNCNPCAuthoringEditor = { Internal = { Model = Model, UI = {}, tr = function(_, fallback) return fallback end } }
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorWindow_Preview.lua')
local parent = setmetatable({ presentationAdapter = adapter }, { __index = ISPNCNPCAuthoringEditor })
local appearance = setmetatable({ parentEditor = parent, draft = adapter:BuildDraft() }, { __index = ISPNCUniqueNPCAppearanceWindow })
parent.draft, parent.appearanceTab = appearance.draft, appearance
local rebinds = 0
function parent:fieldCapability(id) return self.presentationAdapter:FieldCapability(id) end
function parent:refreshFromAdapter()
    rebinds = rebinds + 1
    self.draft = self.presentationAdapter:BuildDraft(); self.appearanceTab.draft = self.draft
end
function parent:commitAdapterDraft()
    local changed, reason = self.presentationAdapter:CommitDraft(self.appearanceTab.draft)
    if changed then self:refreshFromAdapter() end
    return changed, reason
end
function appearance:syncFromDraft() end -- Native widget paint boundary.
for _, tone in ipairs({ 'tone:1', 'tone:5', 'tone:2' }) do
    appearance:onSkinModeChanged({ selected = 1, options = { { data = tone } } })
    local expected = PNC.UniqueNPCAppearanceUI.Internal.skinTextureForTone(tone, parent.draft.isFemale)
    local _, value = F.Blueprint.Get(session:GetBlueprint(IDs.FRIEND), 'appearance.skinTexture')
    T.equal(value, expected, 'native skin selector commits through the real canonical adapter')
    T.equal(appearance.draft.identity.survivor.skinTexture, expected, 'rebound displayed draft matches accepted skin value')
end
T.equal(rebinds, 3, 'each accepted skin selection rebinds once')
parent.presentationAdapter = Adapter.New(session, IDs.BROTHER)
parent:refreshFromAdapter()
local before = F.Blueprint.Fingerprint(session:GetBlueprint(IDs.BROTHER))
T.falsy(appearance:onSkinModeChanged({ selected = 1, options = { { data = 'tone:5' } } }), 'a stale locked skin callback is rejected')
T.equal(F.Blueprint.Fingerprint(session:GetBlueprint(IDs.BROTHER)), before, 'family skin selection cannot mutate inherited data')
T.equal(appearance.draft.identity.survivor.skinTexture, 'MaleBody03', 'inherited skin remains displayed')
-- The adapter validates the entire edit before its one session mutation.
local candidate = parent.presentationAdapter:BuildDraft()
candidate.identity.survivor.forename = 'Changed'
candidate.skillLevels = { unknown = -1 }
local changed, reason = parent.presentationAdapter:CommitDraft(candidate)
T.falsy(changed, 'invalid multi-field edits fail atomically')
T.truthy(reason, 'invalid edits explain the rejection')
T.equal(F.Blueprint.Fingerprint(session:GetBlueprint(IDs.BROTHER)), before, 'invalid candidate cannot partially rename the companion')
T.finish('pnc_npc_authoring_edit_binding_smoke')

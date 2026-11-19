local F = require('tests/support/pnc_authoring_session')()
local T, Session, copy, ID = F.T, F.Session, F.copy, F.TID
local Presets = require 'PNC/CharacterCreation/PNC_StartingCompanionPresets'
local Preview = require 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringPresetPreview'
local CompanionPreview = require 'PNC/UI/StartingCompanions/PNC_StartingCompanionPresetPreview'
local created, resolved = 0, {}
PNC.UniqueNPCs.Resolve = function(def, options)
    created = created + 1
    resolved[#resolved + 1] = copy(def)
    local record = copy(def)
    record.identitySeed = options.identitySeed
    record.inventory = { items = {}, worn = {}, attached = {}, equipped = {} }
    record.runtime = { appearanceCache = copy(def.identity and def.identity.survivor or {}) }
    return record
end
PNC.Identity.RollAppearance = function(record) return record.runtime.appearanceCache end
PNC.Identity.BuildPortraitSummary = function() return { revision = 1 } end
local context = F.context('Reyes', true, 'straight')
local session = Session.New({ sessionSeed = 42, context = context })
session:Reconcile({ ID.BROTHER, ID.FRIEND }, context)
T.truthy(session:SetField(ID.BROTHER, 'identity.forename', 'Riley'))
T.truthy(session:SetField(ID.FRIEND, 'identity.forename', 'Sam'))
T.truthy(session:SetField(ID.FRIEND, 'identity.isFemale', true))
T.truthy(session:SetField(ID.FRIEND, 'startingItems', { { type = 'Base.Axe', equipSlot = 'primary' } }))
local payload = Presets.FromSession(session, 'My roster')
local hash = F.Authoring.Registry.Hash
local payloadBefore, sessionBefore = hash(payload), hash(session:FinalBlueprints())
local provider = CompanionPreview.BuildProvider(payload, context)
T.equal(created, 0, 'opening a roster does not construct every native portrait')
local first, label, count = provider(1)
T.truthy(first, 'first saved roster member has a portrait')
T.equal(count, 2, 'roster reports every saved member')
T.contains(label, 'Riley', 'portrait caption uses resolved identity')
T.equal(first.isFemale, false, 'brother preview follows fixed gender policy')
T.equal(resolved[1].identity.survivor.surname, 'Reyes', 'preview resolves current-player surname inheritance')
T.equal(provider(1), first, 'reselecting a member reuses its stable native snapshot')
T.equal(created, 1, 'cached selection never rerolls or creates another NPC')
local second, secondLabel = provider(2)
T.truthy(second, 'second roster member has a portrait')
T.truthy(second.isFemale, 'friend preview retains freely authored gender')
T.contains(secondLabel, 'Sam', 'cycling portraits follows the selected roster member')
T.equal(resolved[2].startingItems[1].type, 'Base.Axe', 'saved exact weapon reaches preview resolution')
T.equal(created, 2, 'only visited members construct a native preview')
T.equal(hash(payload), payloadBefore, 'browsing never mutates the saved preset')
T.equal(hash(session:FinalBlueprints()), sessionBefore, 'browsing never applies a preset to the live session')
local single = CompanionPreview.BuildProvider(Presets.TemplateFromSession(session, ID.FRIEND, 'Sam'), context)
local _, _, singleCount = single(1)
T.equal(singleCount, 1, 'single companion presets expose one portrait')
local invalid = CompanionPreview.BuildProvider({}, context)
T.falsy(invalid(1), 'invalid saved data does not construct or leak an old portrait')

local draft = F.Adapter.New(session, ID.FRIEND):BuildDraft()
local before = hash(draft)
local debugPreview = Preview.Draft(draft)
T.truthy(debugPreview(1), 'debug saved-character provider uses the same canonical model')
T.equal(hash(draft), before, 'debug browsing does not attach runtime state to the saved draft')
T.finish('pnc_npc_authoring_preset_preview_smoke')

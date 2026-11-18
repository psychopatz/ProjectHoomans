local F = require('tests/support/pnc_authoring_session')()
local T, Session, Adapter, B, M, IDs = F.T, F.Session, F.Adapter, F.Blueprint, F.Model, F.TID
local V = PNC.NPCAuthoringVariation
local session = Session.New({ sessionSeed = 77, context = F.context('Family', false, 'straight') })
session:Reconcile({ IDs.BROTHER, IDs.FRIEND, IDs.IS_MARRIED }, session:GetContext())
PNC.IdentityNames.Generate = function(seed) return 'New' .. seed .. ' Surname' end
PNC.IdentityNames.ResolveNickname = function() return 'Nickname' end
PNC.SkillCatalog.GetGroups = function() return { { skills = { { id = 'Cooking' }, { id = 'Aiming' } } } } end
PNC.SkillCatalog.Find = function(id) return (id == 'Cooking' or id == 'Aiming') and {} end
PNC.NPCTraits.GetDefinitions = function() return { { id = 'steady' }, { id = 'reckless' }, { id = IDs.FRIEND } } end
PNC.NPCTraits.ResolveSet = function(set) return set, set.steady and set.reckless and { 'conflict' } or {} end
local types = { 'Brave', 'Cowardly', 'pnc:pnc_hasfriend' }
CharacterTraitDefinition = { getTraits = function() return { size = function() return #types end, get = function(_, n)
    local id = types[n + 1]
    return { getType = function() return { getName = function() return id end } end }
end } end }
M.EnsureRuntimeRecord = function() return { inventory = { items = {
    shirt = { type = 'Base.NewShirt', wornSlot = 'Torso', itemState = { visualTextureChoice = 3 } },
    axe = { type = 'Base.Axe', equipSlot = 'primary', stack = 1 },
    document = { type = 'Base.IDcard', templateKey = 'tmpl:identity_card:identity' },
} } } end
M.BuildPortraitSpec = function() return { appearance = { hairModel = 'Short', beardModel = '', skinTexture = 'MaleBody05', hairColor = { r = .8, g = .7, b = .6 } } } end
local brother = Adapter.New(session, IDs.BROTHER)
local original = session:GetBlueprint(IDs.BROTHER)
local seed = original.generationSeed
T.truthy(brother:RandomizeTab('bio'), 'Bio dice commits a canonical variation')
local afterBio = session:GetBlueprint(IDs.BROTHER)
T.equal(B.Get(afterBio, 'identity.surname'), 'absent', 'Bio dice cannot author inherited surname')
T.equal(session:GetSlot(IDs.BROTHER).resolvedDefinition.identity.survivor.surname, 'Family', 'family surname is respected')
T.equal(afterBio.generationSeed, seed, 'Bio does not reroll other generated tabs')
T.truthy(brother:RandomizeTab('attributes'), 'attribute dice uses canonical skill/trait validators')
local afterAttrs = session:GetBlueprint(IDs.BROTHER)
local _, skills = B.Get(afterAttrs, 'skills.baseLevels')
T.truthy(skills.Cooking ~= nil and skills.Aiming ~= nil, 'loaded skill catalog is used')
local _, physiological = B.Get(afterAttrs, 'traits.physiological')
T.falsy(physiological['pnc:pnc_hasfriend'], 'native companion-selection traits are excluded')
local _, npc = B.Get(afterAttrs, 'traits.npc')
local _, dynamic = B.Get(afterAttrs, 'traits.dynamic')
T.falsy((npc or {}).steady and (dynamic or {}).reckless or (npc or {}).reckless and (dynamic or {}).steady, 'conflicting NPC/dynamic traits are not combined')
local friend = Adapter.New(session, IDs.FRIEND)
T.truthy(friend:RandomizeTab('loadout'), 'loadout dice materializes exact clothing and gear')
local loadout = session:GetBlueprint(IDs.FRIEND)
local _, appearance = B.Get(loadout, 'appearance')
T.equal(appearance.slots.Torso.type, 'Base.NewShirt', 'new clothing is stored exactly')
local _, items = B.Get(loadout, 'startingItems')
T.equal(#items, 1, 'identity documents are not promoted into authored gear')
T.equal(items[1].type, 'Base.Axe', 'generated held equipment becomes canonical gear')
local gearHash = PNC.NPCAuthoring.Registry.Hash(items)
T.truthy(friend:RandomizeTab('appearance'), 'appearance dice commits visual fields')
local _, retainedGear = B.Get(session:GetBlueprint(IDs.FRIEND), 'startingItems')
T.equal(PNC.NPCAuthoring.Registry.Hash(retainedGear), gearHash, 'appearance dice leaves loadout unchanged')
local _, retainedAppearance = B.Get(session:GetBlueprint(IDs.FRIEND), 'appearance')
T.equal(retainedAppearance.slots.Torso.type, 'Base.NewShirt', 'appearance dice does not reroll clothing')
T.equal(B.Get(session:GetBlueprint(IDs.BROTHER), 'appearance.skinTexture'), 'absent', 'family skin remains un-authored')
local before = B.Fingerprint(session:GetBlueprint(IDs.FRIEND))
local clearedDraft = friend:BuildDraft()
clearedDraft.authoringClears = { ['appearance.skinTexture'] = true, ['identity.nickname'] = true }
local variedDraft = V.Generate(clearedDraft, 'appearance', 937)
local variedBlueprint = M.BuildBlueprint(variedDraft)
local textureState, texture = B.Get(variedBlueprint, 'appearance.skinTexture')
T.equal(textureState, 'value', 'dice replaces an earlier explicit clear in its scope')
T.equal(texture, 'MaleBody05', 'the newly materialized tone survives canonical serialization')
T.truthy(variedDraft.authoringClears['identity.nickname'], 'dice retains unrelated explicit clears')
local ok, why = friend:RandomizeTab('relations')
T.falsy(ok, 'relationship randomization is left as a TODO')
T.equal(why, 'backstory_pending', 'relationship TODO has an explicit reason')
T.equal(B.Fingerprint(session:GetBlueprint(IDs.FRIEND)), before, 'relationship TODO does not mutate canonical data')
-- A bisexual Lover is editable; changing orientation reinstates the real rule.
session:Refresh(F.context('Family', false, 'bisexual'))
local lover = Adapter.New(session, IDs.IS_MARRIED)
T.truthy(lover:FieldCapability('identity.isFemale').editable, 'bisexual Lover has no gender constraint')
T.truthy(session:SetField(IDs.IS_MARRIED, 'identity.isFemale', false), 'bisexual Lover accepts male choice')
session:Refresh(F.context('Family', false, 'straight'))
T.falsy(lover:FieldCapability('identity.isFemale').editable, 'constraint changes with player orientation without cached policy')
T.equal(session:GetSlot(IDs.IS_MARRIED).resolvedDefinition.isFemale, true, 'straight rule remains authoritative')
T.truthy(string.find(lover:FieldCapability('identity.isFemale').explanation, 'straight', 1, true), 'lock reason explains the current constraint')
local rows = PNC.NPCAuthoringRelationshipPresentation.Rows(lover, lover:BuildDraft())
T.truthy(string.find(rows[1].value, 'partner', 1, true), 'relationship page explains the NPC role in a full sentence')
local Customization = require 'PNC/Core/Identity/PNC_StartingCompanionCustomization'
local sanitized = Customization.SanitizeBlueprint(session:GetBlueprint(IDs.IS_MARRIED), F.StartingTraits.GetDefinition(IDs.IS_MARRIED))
local biContext = F.context('Family', false, 'bisexual')
local biPlan = F.Authoring.Resolver.ResolvePlan(sanitized, biContext, F.Authoring.Resolver.PolicyForStartingCompanion(F.StartingTraits.GetDefinition(IDs.IS_MARRIED), biContext))
T.equal(biPlan.definition.isFemale, false, 'authority sanitization retains a valid bisexual partner choice')
local straightContext = F.context('Family', false, 'straight')
local straightPlan = F.Authoring.Resolver.ResolvePlan(sanitized, straightContext, F.Authoring.Resolver.PolicyForStartingCompanion(F.StartingTraits.GetDefinition(IDs.IS_MARRIED), straightContext))
T.equal(straightPlan.definition.isFemale, true, 'authoritative orientation still overrides incompatible imported intent')
UIFont = { Small = 1 }
getTextManager = function() return { getFontHeight = function() return 20 end, MeasureStringX = function(_, _, text) return #text * 8 end } end
local list = { items = {}, width = 180, setFont = function() end, setScrollHeight = function(self, height) self.scrollHeight = height end }
for _, row in ipairs(rows) do list.items[#list.items + 1] = { item = row } end
PNC.NPCAuthoringRelationshipPresentation.Layout(list)
T.truthy(#list.items[1].item.lines > 1, 'long relationship descriptions wrap on compact layouts')
T.truthy(list.scrollHeight > 8 * 20, 'relationship scroll extent includes wrapped explanation lines')
T.finish('pnc_npc_authoring_scoped_generation_smoke')

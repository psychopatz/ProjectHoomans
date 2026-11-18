local F = require('tests/support/pnc_authoring_session')()
local T, B, M = F.T, F.Blueprint, F.Model
T.load('ProjectHoomans', 'shared', 'PNC/Core/Identity/PNC_UniqueNPCs.lua')
local files = {}
getFileReader = function(path)
    if not files[path] then return nil end
    local done = false
    return { readLine = function() if done then return nil end; done = true; return files[path] end, close = function() end }
end
getFileWriter = function(path)
    return { write = function(_, content) files[path] = content end, close = function() end }
end
local D = require 'PNC/Core/Definitions/PNC_DefinitionDatabase'
local File = require 'PNC/Core/Definitions/PNC_NPCDefinitionFile'
local C = require 'PNC/Core/Definitions/PNC_LocalNPCCollection'
local Storage = require 'PNC/Identity/PNC_UniqueNPCDefinitionStore'
T.equal(D.FileName('Bertram Henry'), 'Bertram_Henry.txt', 'NPC name is a safe editable default filename')
T.equal(D.FileName('Custom.txt'), 'Custom.txt', 'typed extension is not duplicated')
T.equal(D.SafeFileName('../bad.txt'), nil, 'storage boundary rejects traversal')
local draft = M.FromDefinition({ id = 'starter:friend', displayName = 'Bertram Henry', isFemale = false,
    identity = { survivor = { forename = 'Bertram', surname = 'Henry' } } })
local source = B.Fingerprint(M.BuildBlueprint(draft))
M.EnsureRuntimeRecord = function() return { identity = { survivor = { skinTexture = 'MaleBody02', voicePrefix = 'Chris', voiceType = 0, voicePitch = 4 } }, inventory = { items = {
    shirt = { type = 'Base.Tshirt', wornSlot = 'Torso', itemState = { visualTextureChoice = 7 } },
    axe = { type = 'Base.Axe', equipSlot = 'primary' },
    card = { type = 'Base.IDcard', templateKey = 'tmpl:identity_card:npc' },
} } } end
M.BuildPortraitSpec = function() return { appearance = { skinTexture = 'MaleBody02', hairModel = 'Short' } } end
local ok, why = Storage.SaveCharacter(draft, 'Custom.txt')
T.truthy(ok, why)
T.equal(B.Fingerprint(M.BuildBlueprint(draft)), source, 'independent export does not freeze or mutate companion preset intent')
local saved = Storage.LoadFile('Custom.txt')
T.equal(saved.id, 'user:Custom', 'library identity is independent of starter trait ID')
T.equal(saved.appearance.slots.Torso.itemState.visualTextureChoice, 7, 'exact reviewed clothing is reusable')
T.equal(saved.identity.survivor.skinTexture, 'MaleBody02', 'reviewed skin is persisted')
T.equal(#saved.startingItems, 1, 'held gear is included but identity documents are not')
local ordinary = M.BuildBlueprint(draft)
D.WriteFile('npc', 'Draft.txt', File.Encode(ordinary, false))
D.Upsert('npc', 'Draft.txt', { displayName = 'Draft' })
local loaded, count = C.Load()
T.truthy(loaded); T.equal(count, 1, 'only produced characters enter encounter catalog')
T.truthy(PNC.UniqueNPCs.Get('user:Custom'), 'saved character is registered in existing Unique NPC catalog')
T.equal(PNC.UniqueNPCs.Get('starter:friend'), nil, 'ordinary templates do not become encounter characters')
PNC.Core.IsAuthority = function() return true end
PNC.HoomansWorldView = { Registry = {}, EnsureLoaded = function() end, WorldAgeHours = function() return 1 end, Touch = function() end }
PNC.DirectorConfig = { UNIQUE_NPC_POOL_CHANCE = 1 }
local Registry = require 'PNC/Director/PNC_UniqueNPCRegistry'
local claim = Registry.ReserveForGeneration({ force = true, seed = 12 })
T.equal(claim.definitionId, 'user:Custom', 'local character participates in normal generation')
T.truthy(Registry.CommitSpawn(claim, { id = 'runtime:1' }, 1))
T.truthy(Registry.MarkDead({ uniqueDefinitionId = 'user:Custom', id = 'runtime:1' }, 'combat', 2))
C.Load()
T.equal(Registry.Get('user:Custom').status, 'dead', 'reload never resurrects a dead character in the same world')
T.equal(Registry.ReserveForGeneration({ force = true, seed = 12 }), nil, 'dead character is excluded from later generation')
PNC.HoomansWorldView.Registry = {}
T.truthy(Registry.ReserveForGeneration({ force = true, seed = 12 }), 'a different world can encounter the same saved character')
isServer = function() return true end
local admin = { getAccessLevel = function() return 'admin' end }
local member = { getAccessLevel = function() return '' end }
local encoded = B.Serialize(M.BuildBlueprint(saved))
local before = files[D.GetPath('npc', 'Custom.txt')]
T.falsy(C.Publish(member, 'Custom.txt', encoded), 'authority rejects non-admin publication')
T.equal(files[D.GetPath('npc', 'Custom.txt')], before, 'rejected client cannot write the server library')
T.truthy(C.Publish(admin, 'Custom.txt', encoded), 'admin can publish through the same validated file pipeline')
isClient = function() return true end
T.falsy(C.Load(), 'multiplayer clients never auto-register their local files')
T.finish('pnc_local_npc_collection_smoke')

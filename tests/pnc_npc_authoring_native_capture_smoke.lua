local F = require('tests/support/pnc_authoring_session')()
local T, A = F.T, PNC.Identity.Appearance
local locations = { ['Base.Shorts'] = 'base:shorts', ['Base.Pants'] = 'base:pants' }
PNC.Equipment = { CreateItem = function(id) return { getBodyLocation = function() return locations[id] end } end }
BodyLocations = { getGroup = function() return { isExclusive = function(_, left, right) return left ~= right end } end }
local items = { { type = 'Base.Shorts' }, { type = 'Base.Pants' } }
local worn = { size = function() return #items end, getItemByIndex = function(_, index) return items[index + 1] end, getLocation = function(_, item) return locations[item.type] end }
SurvivorDesc = { new = function() return { setFemale = function() end, dressInNamedOutfit = function() end, getWornItems = function() return worn end } end }
PNC.Inventory.CaptureNativeItem = function(item) return { type = item.type, itemState = { visualTextureChoice = 4 } } end
local Capture = require 'PNC/Identity/PNC_UniqueNPCOutfitCapture'
local slots = Capture.Capture('NativeOutfit', false)
T.equal(slots['base:shorts'], nil, 'later native garment replaces an exclusive prior garment')
T.equal(slots['base:pants'].itemState.visualTextureChoice, 4, 'native visual state survives conflict reconciliation')
T.truthy(A.Validate({ slots = slots }), 'materialized outfits remain valid for later skin and name edits')
T.falsy(A.Validate({ slots = { ['base:shorts'] = { mode = 'item', type = 'Base.Shorts' }, ['base:pants'] = { mode = 'item', type = 'Base.Pants' } } }), 'manual conflicting authored slots remain rejected')
local draft = F.Model.FromDefinition({ id = 'person', displayName = 'Test Person', isFemale = false, appearance = { slots = slots } })
draft.runtimeRecord = { inventory = { items = { stale = { type = 'Base.Shorts', wornSlot = 'base:shorts' } } } }
draft.identity.survivor.skinTexture = 'MaleBody02'; draft.appearanceAuthored.skinTexture = true
local blueprint, why = F.Model.BuildBlueprint(draft)
T.truthy(blueprint, why)
local _, appearance = F.Blueprint.Get(blueprint, 'appearance')
T.equal(appearance.slots['base:shorts'], nil, 'old preview clothing cannot poison a new skin candidate')
T.equal(select(2, F.Blueprint.Get(blueprint, 'appearance.skinTexture')), 'MaleBody02', 'skin edit remains serializable')
T.finish('pnc_npc_authoring_native_capture_smoke')

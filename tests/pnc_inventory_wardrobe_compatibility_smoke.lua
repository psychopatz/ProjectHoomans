local T = require 'tests/support/test'
T.addPackagePaths()
PNC = { Identity = {} }
require 'PNC/Core/Identity/PNC_Identity_Appearance'
local locations = { Beanie = 'Hat', HoodUp = 'SweaterHat', HoodDown = 'Sweater', Pants = 'Pants' }
PNC.Equipment = { CreateItem = function(id) return { getBodyLocation = function() return locations[id] end } end }
-- Installed BodyLocations declares SweaterHat exclusive with Hat and Sweater.
PNC.Identity.Appearance.AreExclusive = function(a, b)
    return a == 'SweaterHat' and (b == 'Hat' or b == 'Sweater') or b == 'SweaterHat' and (a == 'Hat' or a == 'Sweater')
end
local Prepared = require 'PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_AppearanceItems'
local invalid = { appearance = { outfitItems = { 'Beanie', 'HoodUp', 'Pants' } } }
local wardrobe = Prepared.Build(invalid)
T.equal(#wardrobe, 3, 'exclusive generated garments all remain inventory items')
T.equal(wardrobe[1].type, 'Beanie', 'the displaced hat remains in the outfit inventory')
T.equal(wardrobe[1].wornSlot, nil, 'the displaced hat is loose')
T.equal(wardrobe[2].wornSlot, 'SweaterHat', 'the later hood wins the native slot')
T.equal(wardrobe[3].legacyIndex, 3, 'conflicts preserve source identity for unaffected garments')
T.equal(#invalid.appearance.outfitItems, 3, 'compatibility projection does not mutate its source profile')
wardrobe = Prepared.Build({ appearance = { outfitItems = { 'HoodUp', 'Beanie', 'Pants' } } })
T.equal(wardrobe[1].wornSlot, nil, 'the reverse order leaves the hood loose')
T.equal(wardrobe[2].wornSlot, 'Hat', 'the reverse order wears the hat')
T.truthy(PNC.Identity.Appearance.WornSlotsConflict('base:hat', 'Hat'),
    'built-in slot aliases resolve to the same location')
T.falsy(PNC.Identity.Appearance.WornSlotsConflict('mod:hat', 'Hat'),
    'modded locations keep distinct namespaces')
wardrobe = Prepared.Build({ appearance = { outfitItemSpecs = {
    { type = 'Beanie' }, { type = 'HoodDown', itemState = { visualTextureChoice = 6 } }, { type = 'Pants' },
} } })
T.equal(#wardrobe, 3, 'hood-down layers correctly with the beanie')
T.equal(wardrobe[2].itemState.visualTextureChoice, 6, 'compatibility projection preserves exact authored visuals')
T.load('ProjectHoomans', 'common_lua', 'PNC/ArchetypeDefinitions/General/PNC_General.lua')
local variant = PNC.PendingArchetypeBundles.General.appearance.variants.male[2]
T.equal(variant[2], 'Base.HoodieDOWN_WhiteTINT', 'the reported starter outfit no longer pairs a beanie with hood-up clothing')
T.finish('pnc_inventory_wardrobe_compatibility_smoke')

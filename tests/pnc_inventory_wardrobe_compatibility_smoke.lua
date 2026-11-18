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
T.equal(#wardrobe, 2, 'exclusive generated garments cannot both remain marked as equipped')
T.equal(wardrobe[1].type, 'HoodUp', 'later hood-up selection deterministically supersedes the conflicting hat')
T.equal(wardrobe[1].wornSlot, 'SweaterHat', 'native item metadata determines the actual worn location')
T.equal(wardrobe[2].legacyIndex, 3, 'filtering preserves source identity for unaffected garments')
T.equal(#invalid.appearance.outfitItems, 3, 'compatibility projection does not mutate its source profile')
wardrobe = Prepared.Build({ appearance = { outfitItems = { 'HoodUp', 'Beanie', 'Pants' } } })
T.equal(wardrobe[1].type, 'Beanie', 'the reverse order has an equally deterministic native-compatible result')
wardrobe = Prepared.Build({ appearance = { outfitItemSpecs = {
    { type = 'Beanie' }, { type = 'HoodDown', itemState = { visualTextureChoice = 6 } }, { type = 'Pants' },
} } })
T.equal(#wardrobe, 3, 'hood-down layers correctly with the beanie')
T.equal(wardrobe[2].itemState.visualTextureChoice, 6, 'compatibility projection preserves exact authored visuals')
T.load('ProjectHoomans', 'common_lua', 'PNC/ArchetypeDefinitions/General/PNC_General.lua')
local variant = PNC.PendingArchetypeBundles.General.appearance.variants.male[2]
T.equal(variant[2], 'Base.HoodieDOWN_WhiteTINT', 'the reported starter outfit no longer pairs a beanie with hood-up clothing')
T.finish('pnc_inventory_wardrobe_compatibility_smoke')

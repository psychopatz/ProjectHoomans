local T = require 'tests/support/test'
T.addPackagePaths()
local native = setmetatable({}, { __tostring = function() return 'base:shirt' end })
PNC = { Inventory = { Internal = {} }, Identity = {}, Core = {} }
local internal = PNC.Inventory.Internal
internal.normalizeString = function(value) return value ~= nil and tostring(value) or nil end
internal.createBaseInventory = function() return { items = {}, template = {} } end
internal.createItem = function(_, inventory, spec) inventory.items[#inventory.items + 1] = spec; return spec end
internal.calculateWeights = function() end
PNC.Equipment = { CreateItem = function(id)
    if id == 'Base.Shirt' then return { { getBodyLocation = function() return native end } } end
    return { getBodyLocation = function() return nil end }
end }
T.load('ProjectHoomans', 'shared', 'PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Templates.lua')
local record = { inventoryAuthority = 'canonical', weaponMode = 'mixed', startingItems = {
    { type = 'Base.Shirt', wornSlot = 'Torso_Upper', itemState = { visualTextureChoice = 6 } },
    { type = 'Mod.LegacyGarment', wornSlot = 'mod:custom' },
} }
local snapshot = internal.buildTemplateSnapshot(record)
T.equal(snapshot.items[1].wornSlot, 'base:shirt', 'canonical clothing resolves compact aliases through native item metadata')
T.equal(snapshot.items[1].itemState.visualTextureChoice, 6, 'native slot resolution preserves canonical item visuals')
T.equal(snapshot.items[2].wornSlot, 'mod:custom', 'items without native metadata retain provider-owned slot identity')
T.equal(snapshot.template.weaponMode, 'mixed', 'canonical provider combat policy remains authoritative')
T.equal(record.startingItems[1].wornSlot, 'Torso_Upper', 'native projection never rewrites provider-owned source data')
T.finish('pnc_dynamic_trading_canonical_slot_smoke')

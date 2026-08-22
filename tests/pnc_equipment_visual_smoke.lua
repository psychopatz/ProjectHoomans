local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local refreshCount = 0
local clothingVisuals = {}
local clothingVisualStates = {}
PNC = {
    Core = { LogWarn = function() end },
    Visuals = {
        ClearAttachedItems = function(zombie)
            zombie.attached = {}
        end,
        RefreshModel = function()
            refreshCount = refreshCount + 1
        end,
        AddClothingVisual = function(zombie, fullType, visualState)
            clothingVisuals[#clothingVisuals + 1] = fullType
            clothingVisualStates[#clothingVisualStates + 1] =
                visualState
            if zombie and zombie.visualTypes then
                zombie.visualTypes[#zombie.visualTypes + 1] = {
                    getItemType = function()
                        return fullType
                    end,
                }
            end
            return true, "visual_added"
        end,
    },
}

WeaponType = {
    FIREARM = {},
    HANDGUN = {},
    SPEAR = {},
    HEAVY = {},
    TWO_HANDED = {},
    ONE_HANDED = {},
}
WeaponType.getWeaponType = function()
    return WeaponType.ONE_HANDED
end

ISHotbarAttachDefinition = {
    Back = {
        type = "Back",
        attachments = { BigWeapon = "Back" },
    },
}

T.load(ROOT .. "Equipment/PNC_Equipment_Items.lua")
T.load(ROOT .. "Equipment/PNC_Equipment_Slots.lua")
T.load(ROOT .. "Equipment/PNC_Equipment.lua")

local capturedColor = {
    getRedFloat = function() return 0.15 end,
    getGreenFloat = function() return 0.25 end,
    getBlueFloat = function() return 0.35 end,
}
local capturedVisual = {
    getBaseTexture = function() return 2 end,
    getTextureChoice = function() return 5 end,
    getDecal = function() return "SpiffoLogo" end,
    getTint = function() return capturedColor end,
}
local capturedItem = {
    getFullType = function() return "Base.Shirt_FormalWhite" end,
    getVisual = function() return capturedVisual end,
    getClothingItem = function() return {} end,
}
PNC.Registry = {
    GetLiveZombie = function()
        return {
            getWornItems = function()
                return {
                    size = function() return 1 end,
                    get = function()
                        return {
                            getLocation = function() return "Shirt" end,
                            getItem = function() return capturedItem end,
                        }
                    end,
                }
            end,
        }
    end,
}
local visualRecord = {
    id = "visual",
    equipment = {
        worn = {
            Shirt = "Base.Shirt_FormalWhite",
        },
        attached = {},
    },
}
local capturedSummary =
    PNC.Equipment.BuildWornVisualSummary(visualRecord)
T.equal(capturedSummary.Shirt.baseTexture, 2,
    "server inventory base texture capture")
T.equal(capturedSummary.Shirt.textureChoice, 5,
    "server inventory texture choice capture")
T.equal(capturedSummary.Shirt.decal, "SpiffoLogo",
    "server inventory decal capture")
T.equal(capturedSummary.Shirt.tint.b, 0.35,
    "server inventory tint capture")
T.equal(
    visualRecord.equipment.wornVisuals.Shirt.textureChoice,
    5,
    "captured visual was not retained by equipment"
)

local normalizedVisualEquipment =
    PNC.Equipment.NormalizeLoadoutSpec({
        worn = {
            Shirt = "Base.Shirt_FormalWhite",
        },
        wornVisuals = {
            Shirt = capturedSummary.Shirt,
        },
    })
T.equal(
    normalizedVisualEquipment.wornVisuals.Shirt.baseTexture,
    2,
    "equipment normalization discarded visual state"
)

PNC.Inventory = {
    Internal = {
        normalizeLegacyBagSlot = function() end,
    },
}
T.load(ROOT
    .. "Inventory/PNC_Inventory/Equipment/"
    .. "PNC_Inventory_EquipmentSync.lua")
local syncRecord = {
    equipment = normalizedVisualEquipment,
    inventory = {
        equipped = {},
        worn = { Shirt = "shirt_visual" },
        attached = {},
        items = {
            shirt_visual = {
                type = "Base.Shirt_FormalWhite",
            },
        },
    },
}
PNC.Inventory.SyncEquipmentFromInventory(syncRecord)
T.equal(
    syncRecord.equipment.wornVisuals.Shirt.textureChoice,
    5,
    "inventory synchronization discarded matching visual state"
)
T.equal(
    syncRecord.inventory.items.shirt_visual.itemState.visualTextureChoice,
    5,
    "slot visual was not migrated onto its inventory item"
)
T.equal(
    syncRecord.inventory.items.shirt_visual.itemState.visualDecal,
    "SpiffoLogo",
    "shirt decal was not migrated onto its inventory item"
)
syncRecord.inventory.items.shirt_visual.type =
    "Base.Tshirt_DefaultTEXTURE_TINT"
PNC.Inventory.SyncEquipmentFromInventory(syncRecord)
T.equal(
    syncRecord.equipment.wornVisuals.Shirt,
    nil,
    "inventory synchronization retained visual state for a new item"
)

local weapon = {
    modelIndex = 1,
    IsWeapon = function() return true end,
    isRequiresEquippedBothHands = function() return false end,
    getAttachmentType = function() return "BigWeapon" end,
    getModelIndex = function(self) return self.modelIndex end,
    setModelIndex = function(self, value) self.modelIndex = value end,
}
PNC.Equipment.CreateItem = function()
    return weapon, "test_item"
end

local primarySet = 0
local handModelsReset = 0
local zombie = {
    attached = {},
    setVariable = function() end,
    setPrimaryHandItem = function(self, item)
        self.primary = item
        primarySet = primarySet + 1
    end,
    getPrimaryHandItem = function(self)
        return self.primary
    end,
    setSecondaryHandItem = function(self, item)
        self.secondary = item
    end,
    setAttachedItem = function(self, location, item)
        self.attached[location] = item
    end,
    resetEquippedHandsModels = function()
        handModelsReset = handModelsReset + 1
    end,
    getWornItems = function()
        error("hands-only refresh touched worn items")
    end,
    getItemVisuals = function()
        error("hands-only refresh touched clothing visuals")
    end,
}
local record = {
    equipment = {
        primaryFullType = "Base.Axe",
        worn = { Shirt = "Base.Shirt_FormalWhite" },
        attached = {},
    },
}

local applied = PNC.Equipment.ApplyHands(zombie, record)
T.equal(applied, true, "idle equipment apply")
T.equal(zombie.primary, nil, "idle primary hand cleared")
T.equal(zombie.attached.Back, weapon, "idle primary implicitly holstered")
T.equal(record.equipment.primaryVisual.modelIndex, 1,
    "primary weapon model variant was not captured")

record.runtime = { target = { kind = "zombie" } }
weapon.modelIndex = 0
applied = PNC.Equipment.ApplyCombatState(zombie, record, true)
T.equal(applied, true, "combat equipment apply")
T.equal(zombie.primary, weapon, "combat primary hand")
T.equal(weapon.modelIndex, 1,
    "new primary weapon ignored its persisted model variant")
T.equal(zombie.attached.Back, nil, "combat holster cleared")

zombie.primary = nil
applied = PNC.Equipment.ApplyCombatState(zombie, record, true)
T.equal(applied, true, "combat hand repair")
T.equal(zombie.primary, weapon,
    "cached combat presentation did not restore a discarded weapon")

record.runtime.target = nil
applied = PNC.Equipment.ApplyCombatState(zombie, record, false)
T.equal(applied, true, "idle combat-state equipment apply")
T.equal(zombie.primary, nil, "idle primary leaves hand")
T.equal(zombie.attached.Back, weapon, "idle primary returns to holster")
T.truthy(primarySet >= 3, "primary hand state was not refreshed")
T.truthy(handModelsReset > 0, "hand models were not refreshed")
T.truthy(refreshCount > 0, "equipment presentation did not refresh the model")

local appliedCondition
local shirtBodyLocation = {}
local liveBaseTexture = -1
local liveTextureChoice = -1
local liveTint
local liveDecal
ImmutableColor = {
    new = function(r, g, b)
        return {
            getRedFloat = function() return r end,
            getGreenFloat = function() return g end,
            getBlueFloat = function() return b end,
        }
    end,
}
local liveClothingVisual = {
    setBaseTexture = function(_, value) liveBaseTexture = value end,
    getBaseTexture = function() return liveBaseTexture end,
    setTextureChoice = function(_, value) liveTextureChoice = value end,
    getTextureChoice = function() return liveTextureChoice end,
    setDecal = function(_, value) liveDecal = value end,
    getDecal = function() return liveDecal end,
    setTint = function(_, value) liveTint = value end,
    getTint = function() return liveTint end,
}
local clothing = {
    setCondition = function(_, value) appliedCondition = value end,
    getConditionMax = function() return 10 end,
    getBodyLocation = function() return shirtBodyLocation end,
    getFullType = function() return "Base.Shirt_FormalWhite" end,
    getVisual = function() return liveClothingVisual end,
    getClothingItem = function() return {} end,
}
PNC.Equipment.CreateItem = function()
    return clothing, "test_clothing"
end
local worn = { clear = function() end }
local visuals = { clear = function() end }
local dressedZombie = {
    attached = {},
    getWornItems = function() return worn end,
    getItemVisuals = function() return visuals end,
    setWornItem = function(_, location, item)
        T.equal(location, shirtBodyLocation, "typed worn item location")
        T.equal(item, clothing, "worn item instance")
    end,
    getAttachedItems = function()
        return { size = function() return 0 end }
    end,
    setVariable = function() end,
    setPrimaryHandItem = function() end,
    setSecondaryHandItem = function() end,
    resetEquippedHandsModels = function() end,
}
local dressedRecord = {
    equipment = { worn = { Shirt = "Base.Shirt_FormalWhite" }, attached = {} },
    inventory = {
        worn = { Shirt = "shirt_1" },
        items = { shirt_1 = {
            id = "shirt_1",
            type = "Base.Shirt_FormalWhite",
            cond = 3,
            itemState = {
                visualFullType = "Base.Shirt_FormalWhite",
                visualBaseTexture = 6,
                visualTextureChoice = 8,
                visualDecal = "PizzaWhirled",
                visualTintR = 0.9,
                visualTintG = 0.8,
                visualTintB = 0.1,
            },
        } },
    },
    runtime = {},
}
local visualCountBeforeWear = #clothingVisuals
applied = PNC.Equipment.Apply(dressedZombie, dressedRecord)
T.equal(applied, true, "full clothing apply")
T.equal(appliedCondition, 3, "virtual condition copied to live worn item")
T.equal(liveBaseTexture, 6, "inventory item base texture was not restored")
T.equal(liveTextureChoice, 8, "inventory item texture choice was not restored")
T.equal(liveDecal, "PizzaWhirled",
    "inventory item shirt decal was not restored")
T.equal(liveTint:getGreenFloat(), 0.8,
    "inventory item tint was not restored")
T.equal(#clothingVisuals, visualCountBeforeWear + 1,
    "single-player clothing did not create its required item visual")
T.equal(clothingVisualStates[#clothingVisualStates].tint.r, 0.9,
    "single-player synthetic visual lost inventory tint")

local bagLocation = {}
local bag = {
    getBodyLocation = function() return nil end,
    canBeEquipped = function() return bagLocation end,
}
PNC.Equipment.CreateItem = function()
    return bag, "test_bag"
end
local bagZombie = {
    attached = {},
    getWornItems = function() return worn end,
    getItemVisuals = function() return visuals end,
    setWornItem = function(_, location, item)
        T.equal(location, bagLocation, "container canBeEquipped location")
        T.equal(item, bag, "worn container instance")
    end,
    getAttachedItems = function()
        return { size = function() return 0 end }
    end,
    setVariable = function() end,
    setPrimaryHandItem = function() end,
    setSecondaryHandItem = function() end,
    resetEquippedHandsModels = function() end,
}
local bagRecord = {
    equipment = { worn = { Back = "Base.Bag_Test" }, attached = {} },
    inventory = {
        worn = { ["base:back"] = "bag_1" },
        items = { bag_1 = { id = "bag_1", type = "Base.Bag_Test" } },
    },
    runtime = {},
}
T.equal(PNC.Equipment.Apply(bagZombie, bagRecord), true,
    "container equipment apply")

local replicaVariables = {}
local replicaVisualClears = 0
local replicaWornClears = 0
local replicaVisualTypes = {}
local replicaModData = {}
local replicaPrimarySets = 0
local replicaSecondarySets = 0
local replicaZombie = {
    visualTypes = replicaVisualTypes,
    setVariable = function(_, key, value)
        replicaVariables[key] = value
    end,
    setWornItem = function()
        error("replica touched worn-item packets")
    end,
    setAttachedItem = function(self, location, item)
        self.attached = self.attached or {}
        self.attached[location] = item
    end,
    setPrimaryHandItem = function(self, item)
        self.primary = item
        replicaPrimarySets = replicaPrimarySets + 1
    end,
    getPrimaryHandItem = function(self)
        return self.primary
    end,
    setSecondaryHandItem = function(self, item)
        self.secondary = item
        replicaSecondarySets = replicaSecondarySets + 1
    end,
    resetEquippedHandsModels = function() end,
    getItemVisuals = function()
        return {
            clear = function()
                replicaVisualClears = replicaVisualClears + 1
                for index = #replicaVisualTypes, 1, -1 do
                    replicaVisualTypes[index] = nil
                end
            end,
            size = function()
                return #replicaVisualTypes
            end,
            get = function(_, index)
                return replicaVisualTypes[index + 1]
            end,
        }
    end,
    getWornItems = function()
        return {
            clear = function()
                replicaWornClears = replicaWornClears + 1
            end,
        }
    end,
    getModData = function()
        return replicaModData
    end,
}
PNC.Equipment.CreateItem = function()
    return weapon, "test_replica_weapon"
end
local replicaRecord = {
    equipment = {
        primaryFullType = "Base.Axe",
        secondaryFullType = "Base.Torch",
        worn = { Shirt = "Base.Shirt_FormalWhite" },
        wornVisuals = {
            Shirt = {
                fullType = "Base.Shirt_FormalWhite",
                baseTexture = 2,
                textureChoice = 4,
                decal = "SpiffoLogo",
                tint = { r = 0.2, g = 0.3, b = 0.4 },
            },
        },
        attached = { Back = "Base.Axe" },
    },
    runtime = { attackMode = true },
}
T.equal(
    PNC.Equipment.ApplyReplicaVisuals(
        replicaZombie,
        replicaRecord
    ),
    true,
    "replica visual equipment apply"
)
T.equal(
    PNC.Equipment.ApplyReplicaVisuals(
        replicaZombie,
        replicaRecord
    ),
    true,
    "matching replica visual integrity check"
)
T.equal(
    PNC.Equipment.ApplyReplicaHands(
        replicaZombie,
        replicaRecord
    ),
    true,
    "replica hand variables apply"
)
T.equal(
    replicaVariables.PNCPrimary,
    "Base.Axe",
    "replica primary animation variable"
)
T.equal(
    replicaVariables.PNCSecondary,
    "Base.Torch",
    "replica secondary animation variable"
)
T.equal(replicaZombie.primary, weapon,
    "client replica did not materialize its primary hand model")
T.equal(replicaZombie.secondary, weapon,
    "client replica did not materialize its secondary hand model")
T.equal(replicaPrimarySets, 2,
    "unchanged replica primary hand was rebuilt per update")
T.equal(replicaSecondarySets, 2,
    "unchanged replica secondary hand was rebuilt per update")
replicaZombie.primary = nil
T.equal(
    PNC.Equipment.ApplyReplicaHands(
        replicaZombie,
        replicaRecord
    ),
    true,
    "discarded replica hand model repair"
)
T.equal(replicaZombie.primary, weapon,
    "replica hand latch did not repair an engine-discarded model")
T.equal(replicaPrimarySets, 4,
    "replica hand repair did not perform exactly one rebuild")
T.equal(replicaVisualClears, 1,
    "replica did not repair exactly one missing visual set")
T.equal(replicaWornClears, 0,
    "replica cleared server-owned worn items")
local appliedReplicaVisual =
    clothingVisualStates[#clothingVisualStates]
T.equal(appliedReplicaVisual.baseTexture, 2,
    "replica lost persisted inventory base texture")
T.equal(appliedReplicaVisual.textureChoice, 4,
    "replica lost persisted inventory texture choice")
T.equal(appliedReplicaVisual.decal, "SpiffoLogo",
    "replica lost persisted shirt decal")
T.equal(appliedReplicaVisual.tint.g, 0.3,
    "replica lost persisted inventory tint")
replicaRecord.equipment.wornVisuals.Shirt.tint.g = 0.8
T.equal(PNC.Equipment.ApplyReplicaVisuals(
    replicaZombie,
    replicaRecord
), true, "tint-only replica refresh")
T.equal(replicaVisualClears, 2,
    "tint-only change did not invalidate replica visuals")
T.equal(clothingVisualStates[#clothingVisualStates].tint.g, 0.8,
    "tint-only replica refresh used stale color")
replicaRecord.equipment.wornVisuals.Shirt.decal = "PizzaWhirled"
T.equal(PNC.Equipment.ApplyReplicaVisuals(
    replicaZombie,
    replicaRecord
), true, "decal-only replica refresh")
T.equal(replicaVisualClears, 3,
    "decal-only change did not invalidate replica visuals")
T.equal(clothingVisualStates[#clothingVisualStates].decal,
    "PizzaWhirled",
    "decal-only replica refresh used stale shirt design")
replicaRecord.equipment.worn = {}
replicaRecord.equipment.wornVisuals = {}
T.equal(PNC.Equipment.ApplyReplicaVisuals(
    replicaZombie,
    replicaRecord
), true, "removed replica clothing refresh")
T.equal(replicaVisualClears, 4,
    "removed garment left a stale replica visual")
T.equal(#replicaVisualTypes, 0,
    "removed garment remained visible on replica")
replicaRecord.equipment.worn = {
    Shirt = "Base.Shirt_FormalWhite",
}
replicaRecord.equipment.wornVisuals = {
    Shirt = appliedReplicaVisual,
}
isServer = function() return true end
local serverWornSets = 0
local serverBody = {
    setVariable = function() end,
    getItemVisuals = function()
        return { clear = function() end }
    end,
    getWornItems = function()
        return { clear = function() end }
    end,
    setWornItem = function()
        serverWornSets = serverWornSets + 1
    end,
    setAttachedItem = function()
        error("network server attached a live weapon")
    end,
    setPrimaryHandItem = function()
        error("network server equipped a live weapon")
    end,
    setSecondaryHandItem = function()
        error("network server equipped a secondary item")
    end,
}
T.equal(
    PNC.Equipment.Apply(serverBody, replicaRecord),
    true,
    "network authority routed through packet-safe equipment"
)
T.equal(serverWornSets, 1,
    "network authority lost mechanical worn clothing")
T.equal(
    PNC.Equipment.ApplyCombatState(
        serverBody,
        replicaRecord,
        true,
        true
    ),
    true,
    "network combat routed through packet-safe equipment"
)
isServer = nil

local calls = {
    appearance = 0,
    fullEquipment = 0,
    hands = 0,
    broadcast = 0,
}
local apiRecord = {
    id = "npc_visual",
    runtime = {},
    equipment = { worn = { Shirt = "Base.Shirt_FormalWhite" }, attached = {} },
}
PNC = {
    API = {},
    Core = {
        LogRecordDebug = function() end,
    },
    Types = {},
    Registry = {
        Get = function() return apiRecord end,
        GetLiveZombie = function() return {} end,
    },
    OrderSystem = {},
    Presence = {},
    Health = {},
    Visuals = {
        ApplyHumanVisuals = function()
            calls.appearance = calls.appearance + 1
        end,
    },
    Equipment = {
        SetPrimary = function(target, fullType)
            target.equipment.primaryFullType = fullType
        end,
        ResolveWeaponMode = function() return "melee" end,
        Apply = function()
            calls.fullEquipment = calls.fullEquipment + 1
            return true, "full"
        end,
        ApplyHands = function()
            calls.hands = calls.hands + 1
            return true, "hands"
        end,
        Describe = function()
            return { combatModeResolved = "melee", weaponStatus = "melee_ready" }
        end,
    },
    Inventory = {
        SyncFromEquipment = function() end,
    },
    Network = {
        BroadcastRecord = function()
            calls.broadcast = calls.broadcast + 1
        end,
    },
}

T.load(ROOT .. "API/PNC_API.lua")
T.truthy(PNC.API.DebugCommand("npc_visual", "copy_held_weapon", {
    weaponFullType = "Base.Axe",
}), "copy held weapon failed")
T.equal(calls.hands, 1, "API hands-only apply count")
T.equal(calls.appearance, 0, "API rebuilt appearance")
T.equal(calls.fullEquipment, 0, "API rebuilt full equipment")
T.equal(calls.broadcast, 1, "API equipment broadcast count")
T.finish("pnc_equipment_visual_smoke")

T.finish("pnc_equipment_visual_smoke")

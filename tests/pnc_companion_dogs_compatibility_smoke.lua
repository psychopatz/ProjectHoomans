local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local adapterFile = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Adapter.lua"
)

local adapterModules = {
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Adapter",
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Access",
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Presentation",
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Feed",
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Interaction",
    "PNC/Core/Compatibility/Mods/CompanionDogs/PNC_CompanionDogs_Runtime",
}

local function loadAdapter()
    for index = 1, #adapterModules do
        package.loaded[adapterModules[index]] = nil
    end
    return T.load(adapterFile)
end

local function makeEvent()
    local event = { callbacks = {} }
    function event.Add(callback)
        event.callbacks[#event.callbacks + 1] = callback
    end
    function event.Remove(callback)
        local i
        for i = #event.callbacks, 1, -1 do
            if event.callbacks[i] == callback then
                table.remove(event.callbacks, i)
            end
        end
    end
    function event.Fire()
        local callbacks = {}
        local i
        for i = 1, #event.callbacks do
            callbacks[i] = event.callbacks[i]
        end
        for i = 1, #callbacks do
            callbacks[i]()
        end
    end
    return event
end

local function makeBody(managed, friendly)
    return {
        managed = managed == true,
        friendly = friendly == true,
    }
end

PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return body and body.managed == true
        end,
    },
    Compatibility = {},
}
CompanionDogs = {
    isFriendlyNPC = function(body)
        return body and body.friendly == true
    end,
}
loadAdapter()

local Bridge = PNC.Compatibility.CompanionDogs
local managedBody = makeBody(true, false)
local vanillaBody = makeBody(false, false)
local friendlyBody = makeBody(false, true)

T.truthy(Bridge.IsInstalled(), "installs when Companion Dogs is ready")
T.truthy(CompanionDogs.isFriendlyNPC(managedBody), "Hoomans body is friendly")
T.falsy(CompanionDogs.isFriendlyNPC(vanillaBody), "vanilla body stays hostile")
T.truthy(CompanionDogs.isFriendlyNPC(friendlyBody), "native friendly body stays friendly")
T.truthy(Bridge.TryInstall(), "installation is idempotent")

Events = {
    OnGameBoot = makeEvent(),
    OnGameStart = makeEvent(),
    OnTick = makeEvent(),
}
PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return body and body.managed == true
        end,
    },
    Compatibility = {},
}
CompanionDogs = nil
loadAdapter()
local delayedBridge = PNC.Compatibility.CompanionDogs
T.falsy(delayedBridge.IsInstalled(), "waits for late Companion Dogs load")

CompanionDogs = {
    isFriendlyNPC = function()
        return false
    end,
}
Events.OnGameStart.Fire()
T.truthy(delayedBridge.IsInstalled(), "installs after Companion Dogs load")
T.truthy(
    CompanionDogs.isFriendlyNPC(makeBody(true, false)),
    "late-installed wrapper recognizes Hoomans body"
)

-- The interaction remains adapter-owned: gender selects the flavor, hunger
-- gates feeding, and the bark is emitted once for the throttled event.
Events = nil
CharacterStat = { HUNGER = "hunger", THIRST = "thirst" }
local consumed = 0
local barked = 0
local ate = 0
local sent = 0
local lastPayload
local npcHunger = 0.05
local dogHunger = 0.80
local nativeFood = {
    getHungerChange = function() return -20 end,
    isRotten = function() return false end,
}
local stats = {
    set = function(_, stat, value)
        if stat == CharacterStat.HUNGER then dogHunger = value end
    end,
}
local dog = {
    getAnimalType = function() return "dogmale" end,
    getHunger = function() return dogHunger end,
    getThirst = function() return 0 end,
    getStats = function() return stats end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 44 end,
    isDead = function() return false end,
}
local body = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}
local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}
local record = { id = "npc-one", alive = true }

PNC = {
    Core = {
        IsManagedNPCBody = function() return true end,
        IsAuthority = function() return true end,
        Now = function() return 1000 end,
        ForEachPlayer = function(callback) callback(player) end,
    },
    Compatibility = {},
    IndividualNeeds = {
        Get = function() return npcHunger end,
    },
    Registry = {
        ForEachLive = function(callback)
            callback(record, body, record.id)
        end,
    },
    SupplyInventory = {
        Queries = {
            FindPersonal = function()
                return { {
                    itemID = "food-one",
                    item = { type = "Base.Apple", stack = 1 },
                } }
            end,
        },
        Commands = {
            Consume = function()
                consumed = consumed + 1
                return true, "consumed", { undo = function() return true end }
            end,
        },
    },
    SupplyInventoryInternal = {
        NativeCandidates = function() return { { item = nativeFood } } end,
    },
    Network = {
        SendSocialGreeting = function(_, payload)
            sent = sent + 1
            lastPayload = payload
            return true
        end,
    },
}
CompanionDogs = {
    isFriendlyNPC = function() return false end,
    isDog = function() return true end,
    isCompanion = function() return true end,
    animalSex = function() return "male" end,
    ensureUid = function() return "dog-one" end,
    regDogs = function() return { dog } end,
    HUNGER_WARN = 0.60,
    isBadDogFood = function() return false end,
    computeBite = function() return { hunger = -0.20, thirst = 0 } end,
    pulseEatAnim = function() ate = ate + 1 end,
    barkOnce = function() barked = barked + 1 end,
    transmit = function() end,
}
loadAdapter()
local interactionBridge = PNC.Compatibility.CompanionDogs

T.equal(interactionBridge.GetDogSex(dog), "male", "reads male dog sex")
T.equal(
    interactionBridge.GetFlavorID(dog, false),
    "companion_dogs_good_boy",
    "selects boy flavor"
)
CompanionDogs.animalSex = function() return "female" end
T.equal(
    interactionBridge.GetFlavorID(dog, false),
    "companion_dogs_good_girl",
    "selects girl flavor"
)
CompanionDogs.animalSex = function() return nil end
T.equal(
    interactionBridge.GetFlavorID(dog, false),
    "companion_dogs_good_dog",
    "selects neutral flavor"
)
CompanionDogs.animalSex = function() return "male" end
T.truthy(interactionBridge.IsDogHungry(dog), "detects hungry dog")
T.truthy(interactionBridge.IsNPCNotHungry(record), "detects fed NPC")
local fed, feedReason = interactionBridge.FeedDog(record, body, dog)
T.truthy(fed, "feeds dog: " .. tostring(feedReason))
T.equal(consumed, 1, "feeding consumes one NPC food item")
T.equal(ate, 1, "feeding starts dog eat animation")
T.near(dogHunger, 0.60, 0.0001, "feeding reduces dog hunger")
T.near(npcHunger, 0.05, 0.0001, "feeding does not reduce NPC hunger")

dogHunger = 0.20
T.falsy(interactionBridge.FeedDog(record, body, dog), "does not feed a satisfied dog")
npcHunger = 0.25
dogHunger = 0.80
T.falsy(interactionBridge.FeedDog(record, body, dog), "does not feed a hungry NPC")
npcHunger = 0.05
interactionBridge.RollFeedChance = function() return true end
interactionBridge._lastInteractionAt = {}
T.truthy(PNC.Core.IsAuthority(), "pump authority")
T.truthy(interactionBridge.IsDogEligible(dog), "pump dog is eligible")
T.truthy(interactionBridge.IsDogHungry(dog), "pump dog is hungry")
T.truthy(interactionBridge.IsNPCNotHungry(record), "pump NPC is fed")
T.equal(interactionBridge.GetDogKey(dog), "dog-one", "pump dog key")
T.equal(interactionBridge.Pump(true), 1, "pumps one dog interaction")
T.equal(sent, 1, "sends one flavor event")
T.equal(barked, 1, "barks once for the interaction")
T.equal(
    lastPayload.flavorID,
    "companion_dogs_feed_boy",
    "feed event uses male flavor"
)
T.equal(interactionBridge.Pump(true), 0, "pair cooldown prevents flooding")
T.equal(barked, 1, "pair cooldown prevents repeated bark")

interactionBridge._lastInteractionAt = {}
record.runtime = { target = {} }
T.equal(interactionBridge.Pump(true), 0,
    "combat-busy NPC does not scan or interact with the dog")
record.runtime = nil

local originalSend = PNC.Network.SendSocialGreeting
PNC.Network.SendSocialGreeting = function() return false end
dogHunger = 0.20
interactionBridge._lastInteractionAt = {}
T.equal(interactionBridge.Pump(true), 0,
    "undelivered flavor is not counted as an interaction")
T.falsy(interactionBridge._lastInteractionAt["npc-one:dog-one"],
    "undelivered flavor remains retryable")
PNC.Network.SendSocialGreeting = originalSend

T.finish("pnc_companion_dogs_compatibility_smoke")

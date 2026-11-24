local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 10000
local worldDays = 2.4
local deliveredBarks = {}
local recordedSocialEvents = {}

isClient = function() return false end
isServer = function() return true end
getTimeInMillis = function() return nowMs end
getTimestampMs = function() return nowMs end
getCurrentSaveName = function() return "assault-smoke" end
getText = function(k) return k end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return worldDays end,
        getWorldAgeHours = function() return worldDays * 24 end,
        getTimeOfDay = function() return 13 end,
    }
end
getClimateManager = function()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getTemperature = function() return 20 end,
    }
end
instanceof = function(obj, className)
    return type(obj) == "table" and obj._class == className
end

Events = {
    OnWeaponHitCharacter = { Add = function() end },
    OnTick = { Add = function() end },
    OnResetLua = { Add = function() end },
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

PNC = PNC or {}
PNC.CombatResolution = PNC.CombatResolution or {}
PNC.Config = { EnableDamage = true, EnablePlayerDamage = true }
local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

T.load(SHARED .. "Base/PNC_Core.lua")
T.load(SHARED .. "Base/PNC_Constants.lua")
T.load(SHARED .. "Base/PNC_Types.lua")
T.load(SHARED .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED .. "Relationships/PNC_RelationshipTypes.lua")
T.load(SHARED .. "Relationships/PNC_SocialEventDefinitions.lua")

-- Minimal player/registry/network bridges compatible with PlayerDamage & Semantics
local function makePlayer(opts)
    opts = opts or {}
    return {
        _class = "IsoPlayer",
        _onlineID = opts.onlineID or 11,
        _username = opts.username or "SurvivorPat",
        _forename = opts.forename or "Pat",
        _backpack = opts.backpack,
        _weapon = opts.weapon,
        _hasMoney = opts.hasMoney == true,
        _shove = opts.shove == true,
        getOnlineID = function(self) return self._onlineID end,
        getUsername = function(self) return self._username end,
        getDisplayName = function(self) return self._forename end,
        getDescriptor = function(self)
            local name = self._forename
            return { getForename = function() return name end }
        end,
        isLocalPlayer = function() return true end,
        isDoShove = function(self) return self._shove end,
        getX = function() return 10 end,
        getY = function() return 10 end,
        getZ = function() return 0 end,
        getClothingItem_Back = function(self) return self._backpack end,
        getWornItem = function(self, slot)
            return slot == "Back" and self._backpack or nil
        end,
        getPrimaryHandItem = function(self) return self._weapon end,
        getInventory = function(self)
            local hasMoney = self._hasMoney
            return {
                containsTypeRecurse = function(_, ft)
                    return ft == "Base.Money" and hasMoney
                end,
                getFirstType = function(_, ft)
                    return (ft == "Base.Money" and hasMoney) and {} or nil
                end,
                getItemCount = function(_, ft)
                    return (ft == "Base.Money" and hasMoney) and 5 or 0
                end,
            }
        end,
    }
end

local activePlayer = makePlayer({ shove = true })
local npcStore = {}

PNC.Core.Now = function() return nowMs end
PNC.Core.IsAuthority = function() return true end
PNC.Core.IsClientOnly = function() return false end
PNC.Core.Distance = function(x1, y1, x2, y2)
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return math.sqrt(dx * dx + dy * dy)
end
PNC.Core.DistanceSq = function(x1, y1, x2, y2)
    local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end
PNC.Core.ResolvePlayerByOnlineID = function(id)
    return tonumber(id) == 11 and activePlayer or nil
end
PNC.Core.ResolvePlayerByUsername = function(name)
    return tostring(name) == "SurvivorPat" and activePlayer or nil
end
PNC.Core.ForEachPlayer = function(cb)
    if activePlayer then cb(activePlayer) end
end
PNC.Registry = {
    Data = npcStore,
    Get = function(id) return npcStore[tostring(id)] end,
    MarkDirty = function() return true end,
}
PNC.Network = {
    BroadcastRemoval = function() end,
    SendConversationRelationshipForNPC = function(_, npcID, eventType, payload)
        deliveredBarks[#deliveredBarks + 1] = {
            npcID = tostring(npcID),
            eventType = tostring(eventType),
            payload = payload,
            ambientFlavor = payload and payload.ambientFlavor or nil,
        }
        return true
    end,
}
PNC.SocialEventHooks = {
    ResolvePlayerKey = function(player)
        return "player:" .. tostring(player:getUsername())
    end,
}
PNC.SocialEvents = {
    Emit = function(spec)
        recordedSocialEvents[#recordedSocialEvents + 1] = spec
        return { accepted = true, id = spec.id }
    end,
}
PNC.Factions = {
    Peek = function(id)
        if id == "fac_raiders" then
            return { id = id, archetype = "raider", name = "Highway Raiders" }
        end
        return nil
    end,
}
PNC.NPCWounds = {
    ApplyCombatDamage = function(record, _, hit)
        record.health.current = math.max(1, (tonumber(record.health.current) or 100) - (tonumber(hit.amount) or 10))
        return true, { outcome = "wounded", targetAlive = true }
    end,
}
PNC.LiveBodyControl = { RecoverGroundedBody = function() end }

-- Load Core + ProjectHoomans ConvoEngine stack
T.load("PsychopatzCore", "common", "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/Semantics/PsychopatzSemantic.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueState.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/DialogueRouter.lua")
T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/SpeechRealization.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/ResponseCatalog/Generated/Init.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/ResponseCatalog/Generated/Init.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")

-- Load damage, relationships & semantic assault stack
T.load(SHARED .. "Relationships/PNC_Relationships.lua")
T.load(SHARED .. "Combat/CombatResolution/PNC_CombatResolution_NPC.lua")
T.load(SHARED .. "Health/PlayerDamage/PNC_PlayerDamage_Runtime.lua")
T.load(SHARED .. "Health/PlayerDamage/PNC_PlayerDamage_ReportContract.lua")
T.load(SHARED .. "Health/PlayerDamage/PNC_PlayerDamage_Policy.lua")
T.load(SHARED .. "Health/PlayerDamage/PNC_PlayerDamage_Application.lua")
T.load(SERVER .. "Semantics/PNC_SemanticCombatReactionService.lua")
T.load(SERVER .. "Semantics/PNC_SemanticCombatTargetCallouts.lua")
local Assault = T.load(SERVER .. "Semantics/PNC_SemanticPlayerAssaultReactions.lua")

local function assertCleanLine(text, label)
    T.truthy(type(text) == "string" and text ~= "", label .. " non-empty")
    T.falsy(string.find(text, "{", 1, true), label .. " has no unexpanded brace placeholders: " .. tostring(text))
    T.falsy(string.find(text, "%%s"), label .. " has no raw %s format specifiers: " .. tostring(text))
end

-- 1. Friendly push/shove escalation + daily relationship penalty + next-day reset
local colonist = {
    id = "npc_colonist_1",
    name = "Meredith",
    alive = true,
    tacticalClass = "colonist",
    recruited = true,
    ownerUsername = "SurvivorPat",
    x = 10, y = 10, z = 0,
    runtime = {},
    health = { state = "normal", current = 100, max = 100 },
}
npcStore[colonist.id] = colonist
local colonistBody = {
    _hp = 1000,
    setHealth = function(self, v) self._hp = v end,
    getHealth = function(self) return self._hp end,
}

T.equal(PNC.PlayerDamage.Internal.Runtime.IsShove(activePlayer, nil, 0), true, "Runtime.IsShove detects isDoShove")

local ok1, r1 = PNC.PlayerDamage.Apply(colonist, colonistBody, activePlayer, nil, 0, "player_weapon_event", { isShove = true })
T.equal(ok1, false, "friendly colonist damage blocked")
T.equal(r1, "colonist_protected", "friendly protection preserved")
T.equal(#deliveredBarks, 1, "first friendly shove emits dialogue")
T.equal(#recordedSocialEvents, 0, "first shove does not apply penalty")
T.equal(deliveredBarks[1].ambientFlavor.realizationFamily, "semantic.combat.assault.friendly_fire", "uses friendly_push family")
T.equal(deliveredBarks[1].ambientFlavor.realizationID, "semantic.combat.assault.friendly_fire.first", "push 1 selects first variant")
T.equal(deliveredBarks[1].ambientFlavor.context.friendlyPushTier, "first", "push 1 tier is first")
assertCleanLine(deliveredBarks[1].ambientFlavor.text, "push 1 line")

nowMs = nowMs + 2000
PNC.PlayerDamage.Apply(colonist, colonistBody, activePlayer, nil, 0, "player_weapon_event", { isShove = true })
T.equal(#deliveredBarks, 2, "second friendly shove emits warning dialogue")
T.equal(#recordedSocialEvents, 0, "second shove still warns without penalty")
T.equal(deliveredBarks[2].ambientFlavor.realizationID, "semantic.combat.assault.friendly_fire.warn", "push 2 selects warn variant")
T.equal(deliveredBarks[2].ambientFlavor.context.friendlyPushTier, "warn", "push 2 tier is warn")
assertCleanLine(deliveredBarks[2].ambientFlavor.text, "push 2 line")

-- Rapid push under 650 ms debounce does not count as push 3
nowMs = nowMs + 200
PNC.PlayerDamage.Apply(colonist, colonistBody, activePlayer, nil, 0, "player_weapon_event", { isShove = true })
T.equal(#recordedSocialEvents, 0, "debounced shove does not increment push count or trigger penalty")

-- Push 3 on same day triggers relationship penalty
nowMs = nowMs + 2500
PNC.PlayerDamage.Apply(colonist, colonistBody, activePlayer, nil, 0, "player_weapon_event", { isShove = true })
T.equal(#deliveredBarks, 3, "third shove emits penalty dialogue")
T.equal(#recordedSocialEvents, 1, "third shove same day records player_harassed_friendly_npc")
T.equal(recordedSocialEvents[1].type, "player_harassed_friendly_npc", "emits player_harassed_friendly_npc")
T.equal(deliveredBarks[3].ambientFlavor.realizationID, "semantic.combat.assault.friendly_fire.penalty", "push 3 selects penalty variant")
T.equal(deliveredBarks[3].ambientFlavor.context.friendlyPushTier, "penalty", "push 3 tier is penalty")
assertCleanLine(deliveredBarks[3].ambientFlavor.text, "push 3 line")

-- Daily penalty cap at 4 events
for step = 4, 8 do
    nowMs = nowMs + 2500
    PNC.PlayerDamage.Apply(colonist, colonistBody, activePlayer, nil, 0, "player_weapon_event", { isShove = true })
end
T.equal(#recordedSocialEvents, 4, "daily harassment relationship penalties cap at 4 per day")

-- Next day resets daily push counter back to first warning without immediate penalty
worldDays = 3.1
nowMs = nowMs + 2500
PNC.PlayerDamage.Apply(colonist, colonistBody, activePlayer, nil, 0, "player_weapon_event", { isShove = true })
T.equal(#recordedSocialEvents, 4, "next-day first push resets count without immediate penalty")
T.equal(deliveredBarks[#deliveredBarks].ambientFlavor.context.friendlyPushTier, "first", "next-day push resets tier to first")

-- 2. Neutral NPC turned hostile gets provoked dialogue (not looter taunt)
local neutral = {
    id = "npc_neutral_1",
    name = "Dante",
    alive = true,
    tacticalClass = "neutral",
    x = 12, y = 10, z = 0,
    runtime = {},
    social = { personality = { bravery = 0.25, aggression = 0.2 } },
    health = { state = "normal", current = 100, max = 100 },
}
npcStore[neutral.id] = neutral
local neutralBody = { isDead = function() return false end }

nowMs = nowMs + 10000
local bCountBefore = #deliveredBarks
local hitApplied = PNC.CombatResolution.ApplyNPCDamage(neutral, neutralBody, {
    attackerKind = "player",
    attackerOnlineID = 11,
    amount = 15,
    attackType = "melee",
    attackKind = "player_weapon_event",
    woundType = "cut",
})
T.truthy(hitApplied, "neutral assault damage applies")
T.equal(neutral.tacticalClass, "hostile", "neutral transitions to hostile")
T.equal(neutral.hostility.originTacticalClass, "neutral", "hostility preserves originTacticalClass=neutral")
T.equal(neutral.hostility.provokedByPlayer, true, "hostility records provokedByPlayer=true")
T.equal(Assault.ResolveHostileArchetype(neutral), "neutral_turned_hostile", "archetype identifies provoked neutral")
T.equal(#deliveredBarks, bCountBefore + 1, "neutral-turned-hostile emits assault line")
local neutralLine = deliveredBarks[#deliveredBarks].ambientFlavor
T.equal(neutralLine.realizationFamily, "semantic.combat.assault.react", "uses combat.assault.react family")
T.equal(neutralLine.context.assaultKind, "neutral_turned_hostile", "carries assaultKind=neutral_turned_hostile")
T.truthy(string.find(tostring(neutralLine.realizationID), "betrayal", 1, true), "selects betrayal variant")
assertCleanLine(neutralLine.text, "neutral turned hostile line")

-- Further hit or target acquisition on provoked neutral STILL avoids looter taunt
nowMs = nowMs + 10000
local reBefore = #deliveredBarks
local reOk = PNC.Semantics.CombatTargetCallouts.OnTargetChanged({
    target = { kind = "player", onlineID = 11, x = 10, y = 10, z = 0 },
    at = nowMs,
}, neutral)
T.truthy(reOk, "provoked neutral re-acquire emits reaction")
T.equal(#deliveredBarks, reBefore + 1, "provoked neutral re-acquire emits new bark")
local reLine = deliveredBarks[#deliveredBarks].ambientFlavor
T.equal(reLine.context.assaultKind, "neutral_turned_hostile", "provoked neutral never switches to looter taunt")
assertCleanLine(reLine.text, "provoked neutral re-acquire line")

-- 3. Born-hostile looter taunts targeting player's backpack, weapon, money, and general gear
local looter = {
    id = "npc_looter_1",
    name = "Spike",
    alive = true,
    tacticalClass = "hostile",
    archetype = "looter",
    factionID = "fac_raiders",
    x = 14, y = 10, z = 0,
    runtime = {},
    social = { personality = { bravery = 0.7, aggression = 0.85 } },
    health = { state = "normal", current = 100, max = 100 },
}
npcStore[looter.id] = looter

local function testLootCategory(playerOpts, expectedCategory, expectedSubstring)
    Assault.ResetRuntime()
    if PNC.Semantics.CombatReactionService.ResetRuntime then
        PNC.Semantics.CombatReactionService.ResetRuntime()
    end
    activePlayer = makePlayer(playerOpts)
    nowMs = nowMs + 30000
    local before = #deliveredBarks
    PNC.Semantics.CombatTargetCallouts.OnTargetChanged({
        target = { kind = "player", onlineID = 11, player = activePlayer, x = 10, y = 10, z = 0 },
        at = nowMs,
    }, looter)
    T.equal(#deliveredBarks, before + 1, "looter taunt emitted for " .. expectedCategory)
    local flav = deliveredBarks[#deliveredBarks].ambientFlavor
    T.equal(flav.realizationFamily, "semantic.combat.assault.hostile_taunt", "uses hostile_taunt family")
    T.equal(flav.realizationID, "semantic.combat.assault.hostile_taunt." .. expectedCategory,
        "selects hostile_taunt variant for " .. expectedCategory)
    T.equal(flav.context.lootCategory, expectedCategory, "selects loot category " .. expectedCategory)
    assertCleanLine(flav.text, "looter " .. expectedCategory .. " line")
    if expectedSubstring then
        T.truthy(string.find(string.lower(flav.text), string.lower(expectedSubstring), 1, true),
            "looter line mentions loot item '" .. expectedSubstring .. "': " .. tostring(flav.text))
    end
end

testLootCategory({
    backpack = { getDisplayName = function() return "Large Alice Pack" end },
}, "backpack", "Large Alice Pack")

testLootCategory({
    weapon = {
        getFullType = function() return "Base.BaseballBat" end,
        getDisplayName = function() return "Spiked Bat" end,
    },
}, "weapon", "Spiked Bat")

testLootCategory({
    hasMoney = true,
}, "money", "cash")

testLootCategory({}, "general", nil)

T.finish("pnc_player_assault_and_looter_dialogue_smoke")

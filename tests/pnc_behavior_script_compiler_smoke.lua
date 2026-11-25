-- End-to-end Behavior Script Compiler + ClauseSplitter + Unified PickupProvider smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;" .. package.path

local T = require "support.test"

_G.PNC = {
    Types = {
        IsColonist = function(rec) return rec and rec.tacticalClass == "colonist" end,
    },
}

local Registry = require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
Registry.Reset()

local Compiler = require "PNC/ConvoEngine/BehaviorScriptCompiler"
local PickupProvider = require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPickupProvider"

local colonist = { id = "npc_meghan", name = "Meghan patz", alive = true, tacticalClass = "colonist", x = 10, y = 10, z = 0 }
local stranger = { id = "npc_stranger", name = "Bob", alive = true, tacticalClass = "neutral", x = 10, y = 10, z = 0 }
local player = { getOnlineID = function() return 1 end, getUsername = function() return "Rick" end }
local participants = {
    { id = "npc_meghan", name = "Meghan patz", firstName = "Meghan" },
    { id = "npc_rory", name = "Rory patz", firstName = "Rory" },
}

-- 1) Strict colonist-only gate
local deniedPlan, deniedReason = Compiler.CompileFromText("pick up that food", stranger, player, { groupParticipants = participants })
T.equal(deniedPlan, nil, "non-colonist cannot execute behavior script")
T.equal(deniedReason, "colonist_control_required", "returns colonist_control_required")

-- 2) "pick up that food" -> unified PICKUP(filter="food", includeGround=true)
local p1, e1 = Compiler.CompileFromText("pick up that food", colonist, player, { groupParticipants = participants })
T.truthy(p1 ~= nil, "pick up that food compiles: " .. tostring(e1))
T.equal(p1.stepCount, 1, "1 primitive step")
T.equal(p1.steps[1].kind, "PICKUP", "step 1 is unified PICKUP")
T.equal(p1.steps[1].filter, "food", "filter normalized to food")

-- 3) "pick up all food in this kitchen" -> room-scoped unified PICKUP (ground + room containers!)
local p2 = Compiler.CompileFromText("pick up all food in this kitchen", colonist, player, { groupParticipants = participants })
T.truthy(p2 ~= nil, "kitchen-scoped pickup compiles")
T.equal(p2.steps[1].kind, "PICKUP", "step 1 is unified PICKUP")
T.equal(p2.steps[1].includeContainers, true, "room-scoped PICKUP also checks room containers")
T.truthy(p2.steps[1].areaScope ~= nil and p2.steps[1].areaScope.room == "kitchen", "captures kitchen room scope")

-- 4) "loot all items at nearby pantry" -> MOVE_TO(pantry) + unified PICKUP(pantry, all)
local p3 = Compiler.CompileFromText("loot all items at nearby pantry", colonist, player, { groupParticipants = participants })
T.truthy(p3 ~= nil, "loot all items at nearby pantry compiles via unified PICKUP")
T.equal(p3.stepCount, 2, "2 primitive steps")
T.equal(p3.steps[1].kind, "MOVE_TO", "step 1 MOVE_TO")
T.equal(p3.steps[1].target.text, "pantry", "step 1 target pantry")
T.equal(p3.steps[2].kind, "PICKUP", "step 2 is unified PICKUP (LOOT retired)")
T.equal(p3.steps[2].filter, "all", "step 2 filter all")

-- 5) Chained script with anaphora ("it" -> "food") + dance emote
local p4 = Compiler.CompileFromText(
    "Meghan, loot all food from the pantry, put it in the fridge, then dance",
    colonist, player, { groupParticipants = participants }
)
T.truthy(p4 ~= nil, "chained 3-clause script compiles")
T.equal(p4.isChained, true, "marked as chained script")
T.equal(p4.audienceScope.scope, "INDIVIDUAL", "INDIVIDUAL scope")
T.equal(p4.audienceScope.targetIDs[1], "npc_meghan", "targets Meghan")
T.equal(p4.stepCount, 5, "5 primitive steps in exact order")
T.equal(p4.steps[1].kind, "MOVE_TO", "step 1 MOVE_TO pantry")
T.equal(p4.steps[2].kind, "PICKUP", "step 2 unified PICKUP pantry")
T.equal(p4.steps[2].filter, "food", "step 2 filter food")
T.equal(p4.steps[3].kind, "MOVE_TO", "step 3 MOVE_TO fridge")
T.equal(p4.steps[4].kind, "STORE", "step 4 STORE fridge")
T.equal(p4.steps[4].filter, "food", "anaphora 'it' resolved to food")
T.equal(p4.steps[5].kind, "EMOTE", "step 5 EMOTE")
T.equal(p4.steps[5].emote, "dance", "step 5 emote is dance")

-- 6) Execute unified PICKUP in kitchen (grabs food from BOTH floor AND kitchen pantry, skips hammer & hallway!)
local function makeItem(name, cat, isFood)
    return {
        getDisplayName = function() return name end,
        getName = function() return name end,
        getCategory = function() return cat end,
        getFullType = function() return "Base." .. name end,
        IsFood = function() return isFood == true end,
    }
end

local kitchenRoom = { getName = function() return "kitchen" end }
local hallRoom = { getName = function() return "hallway" end }
local beans = makeItem("CannedBeans", "Food", true)
local apple = makeItem("Apple", "Food", true)
local soup = makeItem("Soup", "Food", true)
local hammer = makeItem("Hammer", "Tool", false)
local hallChips = makeItem("Chips", "Food", true)

local pantryItems = { soup }
local pantryContainer = {
    getItems = function() return pantryItems end,
    Remove = function(_, it)
        for i = #pantryItems, 1, -1 do if pantryItems[i] == it then table.remove(pantryItems, i) end end
    end,
}
local kitchenTileObjs = { { getContainer = function() return pantryContainer end } }
local kitchenFloorObjs = {
    { getItem = function() return beans end },
    { getItem = function() return hammer end },
    { getItem = function() return apple end },
}
local hallFloorObjs = { { getItem = function() return hallChips end } }

local function makeSquare(room, floorObjs, tileObjs)
    return {
        getRoom = function() return room end,
        getWorldObjects = function() return floorObjs end,
        getObjects = function() return tileObjs or {} end,
        removeWorldObject = function(_, target)
            for i = #floorObjs, 1, -1 do
                if floorObjs[i] == target then table.remove(floorObjs, i) end
            end
        end,
    }
end
local kitchenSq = makeSquare(kitchenRoom, kitchenFloorObjs, kitchenTileObjs)
local hallSq = makeSquare(hallRoom, hallFloorObjs, {})
local mockCell = {
    getGridSquare = function(_, x, y)
        if x == 10 and y == 10 then return kitchenSq end
        if x == 11 and y == 10 then return hallSq end
        return nil
    end,
}

local npcBag = {}
local npcBody = {
    getX = function() return 10 end, getY = function() return 10 end, getZ = function() return 0 end,
    getInventory = function()
        return {
            getItems = function() return npcBag end,
            AddItem = function(_, it) npcBag[#npcBag + 1] = it end,
            Remove = function(_, it)
                for i = #npcBag, 1, -1 do if npcBag[i] == it then table.remove(npcBag, i) end end
            end,
        }
    end,
}

local okPick, reasonPick, countPick = PickupProvider.ExecutePickup(
    colonist, npcBody, p2.steps[1], { player = player, cell = mockCell }
)
T.equal(okPick, true, "unified kitchen PICKUP succeeded: " .. tostring(reasonPick))
T.equal(countPick, 3, "picked up 2 floor foods + 1 pantry soup in kitchen")
T.equal(#npcBag, 3, "NPC bag has 3 food items")
T.equal(#pantryItems, 0, "kitchen pantry soup taken")
T.equal(#kitchenFloorObjs, 1, "hammer left on kitchen floor")
T.equal(#hallFloorObjs, 1, "hallway chips untouched")

-- Store all 3 foods into fridge
local fridgeItems = {}
local fridgeContainer = {
    getItems = function() return fridgeItems end,
    AddItem = function(_, it) fridgeItems[#fridgeItems + 1] = it end,
    Remove = function(_, it)
        for i = #fridgeItems, 1, -1 do if fridgeItems[i] == it then table.remove(fridgeItems, i) end end
    end,
}
local okStore, _, countStore = PickupProvider.ExecuteStore(
    colonist, npcBody, p4.steps[4], { player = player, container = fridgeContainer }
)
T.equal(okStore, true, "stored food in fridge")
T.equal(countStore, 3, "stored all 3 food items")
T.equal(#npcBag, 0, "NPC bag emptied")

-- Non-colonist blocked at execution layer
local okDeny, rDeny = PickupProvider.ExecutePickup(stranger, npcBody, p3.steps[2], { player = player, container = fridgeContainer })
T.equal(okDeny, false, "non-colonist blocked at PickupProvider")
T.equal(rDeny, "colonist_control_required", "returns colonist_control_required")

-- 7) Full 12-Primitive ISA multi-step chains
local ActionsProvider = require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanWorldInteractProvider"

-- Chain A: "close the curtains in this room, turn off the tv, then sit down"
local pA = Compiler.CompileFromText(
    "close the curtains in this room, turn off the tv, then sit down",
    colonist, player, { groupParticipants = participants }
)
T.truthy(pA ~= nil, "Chain A compiles")
T.equal(pA.steps[1].kind, "INTERACT", "Chain A step 1 INTERACT curtains")
T.equal(pA.steps[1].op, "close", "Chain A step 1 op=close")
T.equal(pA.steps[2].kind, "MOVE_TO", "Chain A step 2 MOVE_TO tv")
T.equal(pA.steps[3].kind, "INTERACT", "Chain A step 3 INTERACT tv")
T.equal(pA.steps[3].op, "turn_off", "Chain A step 3 op=turn_off")
T.equal(pA.steps[4].kind, "POSTURE", "Chain A step 4 POSTURE")
T.equal(pA.steps[4].pose, "sit", "Chain A step 4 pose=sit")

-- Execute INTERACT on curtain & TV
local curtainOpen = true
local mockCurtain = {
    getObjectName = function() return "Curtain" end,
    IsOpen = function() return curtainOpen end,
    ToggleDoor = function() curtainOpen = not curtainOpen end,
}
local okCurt = ActionsProvider.ExecuteInteract(colonist, npcBody, pA.steps[1], { player = player, targetObject = mockCurtain })
T.equal(okCurt, true, "ExecuteInteract closes curtain")
T.equal(curtainOpen, false, "curtain is now closed")

local tvOn = true
local mockTV = {
    getObjectName = function() return "Television" end,
    getDeviceData = function()
        return {
            getIsTurnedOn = function() return tvOn end,
            setIsTurnedOn = function(_, v) tvOn = v end,
        }
    end,
}
local okTV = ActionsProvider.ExecuteInteract(colonist, npcBody, pA.steps[3], { player = player, targetObject = mockTV })
T.equal(okTV, true, "ExecuteInteract turns off TV")
T.equal(tvOn, false, "TV is now off")

-- Chain B: "grab a bandage from the bathroom, heal Rory, then follow me"
local pB = Compiler.CompileFromText(
    "grab a bandage from the bathroom, heal Rory, then follow me",
    colonist, player, { groupParticipants = participants }
)
T.truthy(pB ~= nil, "Chain B compiles")
T.equal(pB.steps[1].kind, "MOVE_TO", "Chain B step 1 MOVE_TO bathroom")
T.equal(pB.steps[2].kind, "PICKUP", "Chain B step 2 PICKUP bandage")
T.equal(pB.steps[3].kind, "MOVE_TO", "Chain B step 3 MOVE_TO Rory")
T.equal(pB.steps[4].kind, "USE_ITEM", "Chain B step 4 USE_ITEM medical")
T.equal(pB.steps[4].filter, "medical", "Chain B step 4 filter=medical")
T.equal(pB.steps[5].kind, "FOLLOW", "Chain B step 5 FOLLOW")

-- Chain C: "equip your rifle, guard the door, and hold fire"
local pC = Compiler.CompileFromText(
    "equip your rifle, guard the door, and hold fire",
    colonist, player, { groupParticipants = participants }
)
T.truthy(pC ~= nil, "Chain C compiles")
T.equal(pC.steps[1].kind, "EQUIP", "Chain C step 1 EQUIP rifle")
T.equal(pC.steps[1].filter, "rifle", "Chain C step 1 filter=rifle")
T.equal(pC.steps[2].kind, "MOVE_TO", "Chain C step 2 MOVE_TO door")
T.equal(pC.steps[3].kind, "GUARD", "Chain C step 3 GUARD door")
T.equal(pC.steps[4].kind, "ENGAGE", "Chain C step 4 ENGAGE")
T.equal(pC.steps[4].mode, "hold_fire", "Chain C step 4 mode=hold_fire")

-- Execute EQUIP + ENGAGE + POSTURE + EMOTE
local equippedItem = nil
local rifle = makeItem("AssaultRifle", "Weapon", false)
npcBag[#npcBag + 1] = rifle
npcBody.setPrimaryHandItem = function(_, it) equippedItem = it end
local okEq = ActionsProvider.ExecuteEquip(colonist, npcBody, pC.steps[1], { player = player })
T.equal(okEq, true, "ExecuteEquip equips rifle")
T.equal(equippedItem, rifle, "primary hand item set to rifle")

local okHF = ActionsProvider.ExecuteEngage(colonist, npcBody, pC.steps[4], { player = player })
T.equal(okHF, true, "ExecuteEngage hold_fire succeeds")
T.equal(colonist.runtime.holdFire, true, "holdFire runtime flag set")

local okDance = ActionsProvider.ExecuteEmote(colonist, npcBody, p4.steps[5], { player = player })
T.equal(okDance, true, "ExecuteEmote dance succeeds")
T.equal(colonist.runtime.scriptEmote.name, "dance", "scriptEmote recorded as dance")

-- 8) Player-room context + Spoken Plan Affirmation + Stop Words + Follow Override + Restart Safety
local spokenLog = {}
_G.PNC.Core = { Now = function() return 10000 end }
_G.PNC.Semantics = {
    SpeechTransport = {
        ResolveLine = function(rec, opts)
            local summary = opts.tokens and opts.tokens["slot.plan.summary"] or ""
            return tostring(opts.role) .. ":" .. tostring(summary), {
                poolID = opts.poolID,
                realizationID = "test." .. tostring(opts.role),
                presentationClass = "BARK",
            }
        end,
        Deliver = function(rec, now, payload)
            spokenLog[#spokenLog + 1] = payload
            return 1
        end,
    },
}

local playerInKitchen = {
    getOnlineID = function() return 1 end,
    getUsername = function() return "Rick" end,
    getCurrentSquare = function()
        return {
            getRoom = function() return kitchenRoom end,
            getX = function() return 10 end,
            getY = function() return 10 end,
            getZ = function() return 0 end,
        }
    end,
}

local Runner = require "PNC/Semantics/ActionPlanProviders/PNC_BehaviorScriptRunner"

-- 8a) "lets scavenge this room" resolves player's room (kitchen) + pure primitive coords + natural summary
local pRoom, eRoom = Compiler.CompileFromText("lets scavenge this room", colonist, playerInKitchen, { groupParticipants = participants })
T.truthy(pRoom ~= nil, "lets scavenge this room compiles: " .. tostring(eRoom))
T.equal(pRoom.steps[1].kind, "PICKUP", "scavenge this room compiles to PICKUP")
T.equal(pRoom.steps[1].areaScope.room, "kitchen", "player current room (kitchen) injected into areaScope")
T.equal(pRoom.steps[1].areaScope.roomX, 10, "roomX stored as primitive")
T.equal(pRoom.steps[1].areaScope.roomY, 10, "roomY stored as primitive")
T.equal(pRoom.steps[1].areaScope.roomZ, 0, "roomZ stored as primitive")
T.equal(pRoom.summary, "search the kitchen for supplies", "grounded plan summary describes the player's room")

-- 8b) Runner.Start suspends follow, stores ephemeral script, and speaks ack_script_plan with summary
colonist.runtime = colonist.runtime or {}
colonist.runtime.followOrderActive = true
spokenLog = {}
local started, startReason = Runner.Start(colonist, npcBody, pRoom, playerInKitchen, 10000)
T.equal(started, true, "Runner.Start succeeds: " .. tostring(startReason))
T.equal(colonist.runtime.followOrderActive, false, "follow temporarily suspended while executing script")
T.truthy(Runner.IsActive(colonist, 10000), "behaviorScript is active on colonist.runtime")
T.equal(#spokenLog, 1, "colonist speaks plan verification line")
T.equal(spokenLog[1].context.beatRole, "ack_script_plan", "uses ack_script_plan beat role")
T.equal(spokenLog[1].text, "ack_script_plan:search the kitchen for supplies", "summary passed into ConvoDSL token")

-- 8c) Stop word ("okay that's enough") cancels active script cleanly and speaks ack_script_cancelled
local pCancel = Compiler.CompileFromText("okay that's enough", colonist, playerInKitchen, { groupParticipants = participants })
T.truthy(pCancel ~= nil and pCancel.isCancel == true, "stop phrase compiles to cancel plan")
spokenLog = {}
local okCancel, cancelReason = Runner.Start(colonist, npcBody, pCancel, playerInKitchen, 11000)
T.equal(okCancel, true, "stop phrase cancels active script")
T.equal(cancelReason, "script_cancelled", "script_cancelled reason returned")
T.equal(Runner.IsActive(colonist, 11000), false, "behaviorScript cleared after stop phrase")
T.equal(#spokenLog, 1, "colonist speaks cancellation acknowledgment")
T.equal(spokenLog[1].context.beatRole, "ack_script_cancelled", "uses ack_script_cancelled beat role")

-- 8d) "follow me" while script is active cancels script and restores followOrderActive = true
Runner.Start(colonist, npcBody, pRoom, playerInKitchen, 12000)
T.equal(Runner.IsActive(colonist, 12000), true, "script restarted before follow override")
T.equal(colonist.runtime.followOrderActive, false, "follow suspended again")
local pFollow = Compiler.CompileFromText("follow me", colonist, playerInKitchen, { groupParticipants = participants })
spokenLog = {}
local okFol, folReason = Runner.Start(colonist, npcBody, pFollow, playerInKitchen, 13000)
T.equal(okFol, true, "follow override succeeds")
T.equal(folReason, "follow_resumed", "returns follow_resumed reason")
T.equal(Runner.IsActive(colonist, 13000), false, "active script cleared by follow override")
T.equal(colonist.runtime.followOrderActive, true, "followOrderActive restored to true")
T.equal(spokenLog[1].context.beatRole, "ack_follow", "speaks ack_follow on follow override")

-- 8e) Restart safety: stale sessionEpoch cleared immediately on Reconcile
Runner.Start(colonist, npcBody, pRoom, playerInKitchen, 14000)
colonist.runtime.behaviorScript.sessionEpoch = "previous_boot_epoch"
local recRestart, whyRestart = Runner.Reconcile(colonist, npcBody, 14500)
T.equal(recRestart, false, "Reconcile clears stale post-restart script")
T.equal(whyRestart, "restart_reconcile", "reason is restart_reconcile")
T.equal(Runner.IsActive(colonist, 14500), false, "behaviorScript nil after restart reconcile")

-- 8f) Combat interruption safety: runtime.target clears script cleanly on Reconcile
Runner.Start(colonist, npcBody, pRoom, playerInKitchen, 15000)
colonist.runtime.target = { id = "zombie_1" }
local recCombat, whyCombat = Runner.Reconcile(colonist, npcBody, 15500)
T.equal(recCombat, false, "Reconcile yields immediately to combat")
T.equal(whyCombat, "interrupted", "reason is interrupted")
T.equal(Runner.IsActive(colonist, 15500), false, "behaviorScript nil after combat interrupt")
colonist.runtime.target = nil

-- 9) Open-ended "wait here" grounded to player-relative nearby seat (reusing shared NearbyResourceLocator)
local ellise = { id = "npc_ellise", name = "Ellise patz", alive = true, tacticalClass = "colonist", x = 10, y = 10, z = 0 }
local groupWithEllise = {
    { id = "npc_meghan", name = "Meghan patz", firstName = "Meghan" },
    { id = "npc_ellise", name = "Ellise patz", firstName = "Ellise" },
}
local mockSeatResult = nil
_G.PNC.Semantics.WorldTargetResolver = {
    FindNearbySeat = function() return mockSeatResult end,
}

-- 9a) "Ellise wait here" near a wooden chair -> MOVE_TO(chair) + POSTURE(sit) + WAIT + grounded speech
mockSeatResult = { kind = "seat", seatType = "wooden chair", label = "wooden chair", x = 11, y = 10, z = 0, resourceKey = "seat:11:10:0" }
local pWaitChair, eWaitChair = Compiler.CompileFromText("Ellise wait here", ellise, playerInKitchen, { groupParticipants = groupWithEllise })
T.truthy(pWaitChair ~= nil, "Ellise wait here compiles: " .. tostring(eWaitChair))
T.equal(pWaitChair.audienceScope.scope, "INDIVIDUAL", "targets individual colonist Ellise")
T.equal(pWaitChair.audienceScope.targetIDs[1], "npc_ellise", "targets npc_ellise")
T.equal(pWaitChair.stepCount, 3, "expands open-ended wait near chair into 3 steps")
T.equal(pWaitChair.steps[1].kind, "MOVE_TO", "step 1 MOVE_TO chair")
T.equal(pWaitChair.steps[1].target.text, "wooden chair", "step 1 target is wooden chair")
T.equal(pWaitChair.steps[2].kind, "POSTURE", "step 2 POSTURE sit")
T.equal(pWaitChair.steps[2].pose, "sit", "step 2 pose is sit")
T.equal(pWaitChair.steps[3].kind, "WAIT", "step 3 WAIT anchored at chair")
T.equal(pWaitChair.summary, "just sit on the wooden chair and wait here", "spoken verification mentions the wooden chair")

spokenLog = {}
local okWaitStart = Runner.Start(ellise, npcBody, pWaitChair, playerInKitchen, 16000)
T.equal(okWaitStart, true, "Runner.Start succeeds for seat-aware wait")
T.equal(spokenLog[1].text, "ack_script_plan:just sit on the wooden chair and wait here", "Ellise speaks seat-aware plan verification")

-- 9b) "Ellise, wait here" near an armchair -> uses "in the armchair"
mockSeatResult = { kind = "seat", seatType = "armchair", label = "armchair", x = 12, y = 10, z = 0, resourceKey = "seat:12:10:0" }
local pWaitArmchair = Compiler.CompileFromText("Ellise, wait here", ellise, playerInKitchen, { groupParticipants = groupWithEllise })
T.truthy(pWaitArmchair ~= nil, "Ellise, wait here near armchair compiles")
T.equal(pWaitArmchair.summary, "just sit in the armchair and wait here", "armchair uses natural 'in the armchair' phrasing")

-- 9c) "Ellise wait here" with NO nearby seat -> anchors WAIT to player's relative spot
mockSeatResult = nil
local pWaitSpot = Compiler.CompileFromText("Ellise wait here", ellise, playerInKitchen, { groupParticipants = groupWithEllise })
T.truthy(pWaitSpot ~= nil, "Ellise wait here without seat compiles")
T.equal(pWaitSpot.stepCount, 1, "stays single WAIT step when no seat nearby")
T.equal(pWaitSpot.steps[1].kind, "WAIT", "step 1 is WAIT")
T.equal(pWaitSpot.steps[1].anchor.x, 10, "anchored to player X")
T.equal(pWaitSpot.steps[1].anchor.y, 10, "anchored to player Y")
T.equal(pWaitSpot.summary, "wait right here", "fallback summary says wait right here")

print("pnc_behavior_script_compiler_smoke: OK")

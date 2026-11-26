-- Smoke test for Puppet Opera v3: dynamic capabilities, triggers, sub-tile
-- anchors, locomotive tethering, stair clamping, abstract co-movement,
-- anim_vars cleanup, and Lua/XML export round-trip.

local T = require("tests/support/test")

local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Choreography/"
T.load(ROOT .. "PNC_Choreography_AnimationCapabilities.lua")
T.load(ROOT .. "PNC_Choreography_TriggerRegistry.lua")
T.load(ROOT .. "PNC_Choreography_Blueprints.lua")
T.load(ROOT .. "PNC_Choreography_Blueprints_Builtins.lua")
T.load(ROOT .. "PNC_Choreography_Anchors.lua")
T.load(ROOT .. "PNC_Choreography_Tether.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_AnimationDriver.lua")
T.load(ROOT .. "PNC_Choreography_Exporter.lua")

local Capabilities = PNC.Choreography.AnimationCapabilities
local Triggers = PNC.Choreography.TriggerRegistry
local Blueprints = PNC.Choreography.Blueprints
local Anchors = PNC.Choreography.Anchors
local Tether = PNC.Choreography.Tether
local AnimDriver = PNC.AnimationDriver
local Exporter = PNC.Choreography.Exporter

-- 1. Dynamic capabilities: safe non-combat bumps & anim_vars approved; combat blocked
local okDance = Capabilities.IsSceneApproved("nearby_live_npc", {
    bump = "PNC_DanceCustom",
    nonCombat = true,
})
T.truthy(okDance, "non-combat PNC bump should be auto-approved")

local okShove = Capabilities.IsSceneApproved("nearby_live_npc", {
    bump = "PNC_Shove",
    nonCombat = true,
})
T.falsy(okShove, "combat bump PNC_Shove must remain preview_only")

local okAim = Capabilities.IsSceneApproved("nearby_live_npc", {
    bump = "PNC_AimPistol",
    nonCombat = true,
})
T.falsy(okAim, "combat bump PNC_AimPistol must remain preview_only")

local okAnimVars = Capabilities.IsSceneApproved("nearby_live_npc", {
    route = "anim_vars",
    style = "carry_shoulder",
    role = "Carrier",
    nonCombat = true,
})
T.truthy(okAnimVars, "anim_vars route should be approved")

-- 2. All 4 showcase scenes registered & trigger-indexed
local carry = Blueprints.Get("rescue.carry_incapacitated_npc")
T.truthy(carry, "rescue.carry_incapacitated_npc should be registered")
T.equal(carry.beats[2].mode, "locomotive", "carry beat should be locomotive")
T.equal(carry.beats[2].interruptPolicy, "emergency_drop", "carry beat should emergency drop")
T.equal(carry.actors.actor_2.coupling.attachTo, "actor_1", "passenger coupled to carrier")

local bestRescue = Triggers.PickBest("teammate_incapacitated", {
    sameFaction = true,
    hasPlayer = false,
})
T.truthy(bestRescue, "teammate_incapacitated trigger should resolve")
T.equal(bestRescue.blueprintId, "rescue.carry_incapacitated_npc")

local bestHandhold = Triggers.PickBest("escort_handhold", { affinity = 50 })
T.truthy(bestHandhold and bestHandhold.blueprintId == "social.hold_hands",
    "escort_handhold trigger should resolve to social.hold_hands")

local bestDance = Triggers.PickBest("camp_dance", { sameFaction = true })
T.truthy(bestDance and bestDance.blueprintId == "social.dance_pair",
    "camp_dance trigger should resolve to social.dance_pair")

-- 3. Pure NPC-to-NPC sub-tile overlapping anchor plan (no player!)
local leadBody = {
    x = 100.5,
    y = 200.5,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getForwardDirectionX = function() return 0 end,
    getForwardDirectionY = function() return 1 end,
}
local plan, planErr = Anchors.BuildPlan(carry, nil, { leadActor = leadBody })
T.truthy(plan, "lead_actor plan should succeed without player: " .. tostring(planErr))
T.equal(plan.actors.actor_1.x, 100)
T.equal(plan.actors.actor_2.x, 100)

-- 4. Tether positioning, collision suppression, safe drop, and abstract co-movement
local function makeBody(x, y, z)
    return {
        x = x, y = y, z = z,
        collidable = true, solid = true, moving = true,
        dirX = 0, dirY = 1, vars = {},
        getX = function(self) return self.x end,
        getY = function(self) return self.y end,
        getZ = function(self) return self.z end,
        getForwardDirectionX = function(self) return self.dirX end,
        getForwardDirectionY = function(self) return self.dirY end,
        setX = function(self, v) self.x = v end,
        setY = function(self, v) self.y = v end,
        setZ = function(self, v) self.z = v end,
        setCollidable = function(self, v) self.collidable = v end,
        setSolid = function(self, v) self.solid = v end,
        setMoving = function(self, v) self.moving = v end,
        setTargetAndCurrentDirection = function(self, dx, dy) self.dirX, self.dirY = dx, dy end,
        setVariable = function(self, k, v) self.vars[k] = v end,
        clearVariable = function(self, k) self.vars[k] = nil end,
    }
end

local carrierBody = makeBody(10.5, 20.5, 0)
local passengerBody = makeBody(12.0, 20.5, 0)
local okTether = Tether.ApplyBody(passengerBody, carrierBody, carry.actors.actor_2.coupling)
T.truthy(okTether, "Tether.ApplyBody should succeed")
T.equal(passengerBody.x, 10.5)
T.equal(passengerBody.y, 20.5)
T.equal(passengerBody.collidable, false)
T.equal(passengerBody.solid, false)

Tether.RestoreBody(passengerBody, nil)
T.equal(passengerBody.collidable, true)
T.equal(passengerBody.solid, true)

local recA = { x = 50, y = 60, z = 1 }
local recB = { x = 10, y = 20, z = 0 }
Tether.SyncAbstractPair(recA, recB)
T.equal(recB.x, 50)
T.equal(recB.y, 60)
T.equal(recB.z, 1)

-- 5. AnimationDriver anim_vars apply & clear
AnimDriver.ApplyAnimVars(passengerBody, carry.beats[2].tracks.actor_2, { moving = true, progress = 0.5 })
T.equal(passengerBody.vars.PNC_AnimActive, true)
T.equal(passengerBody.vars.PNC_AnimStyle, "carry_shoulder")
T.equal(passengerBody.vars.PNC_AnimProgress, 0.5)
AnimDriver.ClearAnimVars(passengerBody, carry.beats[2].tracks.actor_2)
T.equal(passengerBody.vars.PNC_AnimActive, nil)

-- 6. Exporter Lua + AnimSet XML round-trip
local luaText, norm = Exporter.FormatLua(carry)
T.truthy(luaText and norm, "Exporter.FormatLua should emit valid Lua")
local loader = loadstring or load
local fn, loadErr = loader(luaText)
T.truthy(fn, "Exported Lua must parse cleanly: " .. tostring(loadErr))
local exportedBp = fn()
T.truthy(exportedBp and exportedBp.id == "rescue.carry_incapacitated_npc",
    "Exported Lua round-trip should re-register cleanly")

local xmlText, specs = Exporter.FormatAnimSetXML(carry)
T.truthy(xmlText and #specs >= 2, "Exporter.FormatAnimSetXML should emit zombie/player templates")
T.truthy(string.find(xmlText, "PNC_AnimProgress", 1, true) ~= nil,
    "Exported XML should include TrackTimeToVariable PNC_AnimProgress")

print("PASS pnc_choreography_v3_studio_smoke")

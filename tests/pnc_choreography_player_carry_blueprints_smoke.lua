local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local Blueprints = T.load("ProjectHoomans", "shared",
    "PNC/Core/Choreography/PNC_Choreography_Blueprints.lua")
local AnimDriver = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationDriver.lua")

local expectedStyles = {
    { id = "carry.princess", style = "carry_princess", grounded = false },
    { id = "carry.piggyback", style = "carry_piggyback", grounded = false },
    { id = "carry.shoulder", style = "carry_shoulder", grounded = false },
    { id = "carry.handhold", style = "carry_handhold", grounded = true },
    { id = "carry.drag", style = "carry_drag", grounded = false },
    { id = "carry.assist", style = "carry_assist", grounded = true },
}

for _, spec in ipairs(expectedStyles) do
    local bp = Blueprints.Get(spec.id)
    T.truthy(bp, spec.id .. " blueprint is registered")
    local valid, reason = Blueprints.ValidateRuntime(bp)
    T.equal(valid, true, spec.id .. " passes ValidateRuntime: " .. tostring(reason))
    T.equal(#bp.beats, 3, spec.id .. " has 3 beats (lift, carry, lower)")
    T.equal(bp.beats[1].id, "lift", spec.id .. " beat 1 is lift")
    T.equal(bp.beats[2].id, "carry", spec.id .. " beat 2 is carry")
    T.equal(bp.beats[2].mode, "locomotive", spec.id .. " carry beat is locomotive")
    T.equal(bp.beats[3].id, "lower", spec.id .. " beat 3 is lower")
    T.equal(bp.anchorFrame.allowOverlap, true, spec.id .. " allows actor overlap")
    T.equal(bp.actors.actor_2.coupling.disableCollision, true,
        spec.id .. " disables collision on tethered partner")
    T.equal(bp.actors.actor_2.coupling.groundedCheck, spec.grounded,
        spec.id .. " preserves groundedCheck=" .. tostring(spec.grounded))
    local track = Blueprints.GetTrack(bp.beats[2], "actor_1", "local_player")
    T.equal(track.style, spec.style, spec.id .. " uses native PNC_AnimStyle")
    T.equal(bp.actors.actor_2.stationary, true, spec.id .. " holds target NPC stationary")
    T.equal(bp.anchorFrame.originActor, "actor_2", spec.id .. " anchors on target actor_2")

    local npcID = string.gsub(spec.id, "^carry%.", "carry_npc.")
    local npcBp = Blueprints.Get(npcID)
    T.truthy(npcBp, npcID .. " NPC-to-NPC blueprint is registered")
    local npcValid, npcReason = Blueprints.ValidateRuntime(npcBp)
    T.equal(npcValid, true, npcID .. " passes ValidateRuntime: " .. tostring(npcReason))
    T.equal(npcBp.actors.actor_1.kind, "nearby_live_npc", npcID .. " carrier is nearby_live_npc")
    T.equal(npcBp.actors.actor_2.kind, "nearby_live_npc", npcID .. " partner is nearby_live_npc")
    T.equal(npcBp.actors.actor_2.stationary, true, npcID .. " holds target NPC stationary")
    T.equal(npcBp.anchorFrame.originActor, "actor_2", npcID .. " anchors on target actor_2")
end

-- Verify AnimationDriver drives canonical PNC_Anim* variables cleanly.
local vars = {}
local body = {
    setVariable = function(_, name, val) vars[name] = val end,
    clearVariable = function(_, name) vars[name] = nil end,
    getVariableString = function(_, name) return tostring(vars[name] or "") end,
}

local handhold = Blueprints.Get("carry.handhold")
local carrierTrack = Blueprints.GetTrack(handhold.beats[2], "actor_1", "local_player")
local okApply = AnimDriver.ApplyAnimVars(body, carrierTrack, { phase = "carry", moving = false, progress = 0 })
T.equal(okApply, true, "AnimationDriver applies handhold carrier track")
T.equal(vars.PNC_AnimActive, true, "PNC_AnimActive set to true")
T.equal(vars.PNC_AnimRole, "Carrier", "PNC_AnimRole set to Carrier")
T.equal(vars.PNC_AnimStyle, "carry_handhold", "PNC_AnimStyle set to carry_handhold")
T.equal(vars.PNC_AnimPhase, "carry", "PNC_AnimPhase set to carry")

AnimDriver.UpdateAnimVars(body, 0.5, true)
T.equal(vars.PNC_AnimProgress, 0.5, "PNC_AnimProgress updated")
T.equal(vars.PNC_AnimMoving, true, "PNC_AnimMoving updated")

AnimDriver.ClearAnimVars(body, carrierTrack)
T.equal(vars.PNC_AnimActive, nil, "PNC_AnimActive cleared on stop")
T.equal(vars.PNC_AnimRole, nil, "PNC_AnimRole cleared on stop")
T.equal(vars.PNC_AnimStyle, nil, "PNC_AnimStyle cleared on stop")
T.equal(vars.PNC_AnimPhase, nil, "PNC_AnimPhase cleared on stop")
T.equal(vars.PNC_AnimProgress, nil, "PNC_AnimProgress cleared on stop")

-- Verify PlayerAnimationAdapter natively handles anim_vars (no PsychopatzCore playerAction required).
local clockNow = 1000
PNC.Core = PNC.Core or {}
PNC.Core.Now = function() return clockNow end
local playerMoving = false
local playerBody = {
    vars = {},
    setVariable = function(self, name, val) self.vars[name] = val end,
    clearVariable = function(self, name) self.vars[name] = nil end,
    isDead = function() return false end,
    isPlayerMoving = function() return playerMoving end,
}
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Animation = PsychopatzCore.Animation or {}
PsychopatzCore.Animation.Player = {
    ResolveLocalPlayer = function() return playerBody end,
    Play = function() return false, "selected_entry_has_no_player_action" end,
    Stop = function() return true end,
    Runtime = function() return {} end,
}

local PlayerAnim = T.load("ProjectHoomans", "client",
    "PNC/Choreography/PNC_Choreography_PlayerAnimationAdapter.lua")
local shoulder = Blueprints.Get("carry.shoulder")
local liftTrack = Blueprints.GetTrack(shoulder.beats[1], "actor_1", "local_player")
local okStart, startReason = PlayerAnim.Start("sess_1", shoulder.beats[1], liftTrack)
T.equal(okStart, true, "PlayerAnimation.Start accepts anim_vars lift beat: " .. tostring(startReason))
T.equal(playerBody.vars.PNC_AnimActive, true, "Player PNC_AnimActive set")
T.equal(playerBody.vars.PNC_AnimStyle, "carry_shoulder", "Player PNC_AnimStyle set")
T.equal(playerBody.vars.PNC_AnimPhase, "lift", "Player PNC_AnimPhase set")

clockNow = 1500
local okObs1, st1 = PlayerAnim.Observe("sess_1")
T.equal(okObs1, true)
T.equal(st1, "playing", "Timed lift beat stays playing before durationMs")

clockNow = 3000
local okObs2, st2 = PlayerAnim.Observe("sess_1")
T.equal(okObs2, true)
T.equal(st2, "finished", "Timed lift beat finishes after durationMs")
PlayerAnim.Clear("sess_1")
T.equal(playerBody.vars.PNC_AnimActive, nil, "Player PNC_AnimActive cleared on Clear")

local carryTrack = Blueprints.GetTrack(shoulder.beats[2], "actor_1", "local_player")
local okCarry = PlayerAnim.Start("sess_2", shoulder.beats[2], carryTrack)
T.equal(okCarry, true, "PlayerAnimation.Start accepts locomotive carry beat")
playerMoving = true
clockNow = 20000
local okObs3, st3 = PlayerAnim.Observe("sess_2")
T.equal(okObs3, true)
T.equal(st3, "playing", "Locomotive carry beat stays playing indefinitely past durationMs")
T.equal(playerBody.vars.PNC_AnimMoving, true, "Player PNC_AnimMoving reflects isPlayerMoving()")
local okStop = PlayerAnim.Stop("sess_2")
T.equal(okStop, true, "PlayerAnimation.Stop succeeds for anim_vars")
T.equal(playerBody.vars.PNC_AnimActive, nil, "Player PNC_AnimActive cleared on Stop")

print("PASS pnc_choreography_player_carry_blueprints_smoke")

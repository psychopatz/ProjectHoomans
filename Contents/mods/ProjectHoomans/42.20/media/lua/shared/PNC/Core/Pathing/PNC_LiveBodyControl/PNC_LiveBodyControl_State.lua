-- Shared body-state classification and low-level intent/position control.

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}
PNC.LiveBodyControl.Internal = PNC.LiveBodyControl.Internal or {}

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
Internal.VANILLA_PASSAGE_GUARD_LOGGED = setmetatable({}, { __mode = "k" })

Internal.NATIVE_PASSAGE_STATES = {
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["climbwall"] = true,
}

-- A managed body must not retain a native zombie movement/alert state after a
-- stationary presentation has become the owner. Keep this narrower than
-- SUPPRESSED_STATES: turnalerted is still meaningful to ordinary movement,
-- but it is an unsafe native handoff while the body is seated or sleeping.
Internal.PRESENTATION_NATIVE_RESET_STATES = {
    ["turnalerted"] = true,
    ["pathfind"] = true,
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
    ["lunge"] = true,
    ["lungenetwork"] = true,
}

Internal.GROUNDED_STATES = {
    ["falldown"] = true,
    ["onground"] = true,
    ["onground-ragdoll"] = true,
    ["staggerback-knockeddown"] = true,
}
Internal.GETUP_STATES = {
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
}
Internal.SUPPRESSED_STATES = {
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["lunge"] = true,
    ["onground"] = true,
    ["onground-ragdoll"] = true,
    ["pathfind"] = true,
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
    ["sitonground"] = true,
    ["staggerback"] = true,
    ["staggerback-knockeddown"] = true,
    ["thump"] = true,
}
Internal.IDLE_RESET_STATES = {
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["lunge"] = true,
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
    ["pathfind"] = true,
    ["thump"] = true,
}

require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Core"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Presentation"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Passage_Probe"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_HeavyItems"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Passage_Guard"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Passage_Recovery"

--[[
    PNC animation scenes

    Stable entry point for the animation-scene registry and runtime. Project
    Zomboid loads this file from the shared composition; implementation roles
    live in the matching subfolder so their load order remains explicit.
]]

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
PNC.AnimationScenes.Internal = PNC.AnimationScenes.Internal or {}

require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Normalization"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Registry"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Playback"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Lifecycle"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Safety"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Idle"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Tick"

return PNC.AnimationScenes

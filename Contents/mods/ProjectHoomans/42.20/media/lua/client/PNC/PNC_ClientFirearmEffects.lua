--[[
    PNC Client Firearm Effects
    Replays authoritative firearm-shot events as short-lived local effects.
    It never applies damage or changes ammunition.

    Alignment methodology: every barrel-anchored effect (muzzle flash, tracer,
    and the muzzle square used for the light) starts at the world-space barrel
    tip, resolved from the shot bearing the payload already carries -- never
    from the animation facing and never from the nameplate anchor. Origin and
    direction therefore come from one world line, which is what keeps a flying
    round on the bore; this matches Project A-Life's tracer methodology.

    Deliberately unchanged by that path: the tracer/flash/light colors, the
    light radius and lifetime, the textures, and the screen-space tracer
    renderer are Hoomans' own design.
]]

PNC = PNC or {}
PNC.ClientFirearmEffects = PNC.ClientFirearmEffects or {}

local Effects = PNC.ClientFirearmEffects
local Diagnostics = PNC.PerformanceScalingDiagnostics

Effects.ActiveLights = Effects.ActiveLights or {}
Effects.ActiveTracers = Effects.ActiveTracers or {}
Effects.ActiveMuzzleFlashes = Effects.ActiveMuzzleFlashes or {}
Effects.SeenShots = Effects.SeenShots or {}
Effects.DrawAuditState = Effects.DrawAuditState or {}
Effects.DebugShotSequence = tonumber(Effects.DebugShotSequence) or 0
Effects.DebugSimulation = Effects.DebugSimulation
Effects.LightWindowAt = tonumber(Effects.LightWindowAt) or 0
Effects.LightsInWindow = tonumber(Effects.LightsInWindow) or 0
Effects.Texture = Effects.Texture or (getTexture and getTexture("media/textures/mask_white.png") or nil)
local NativeEffects = require "PNC/PNC_ClientNativeFirearmEffects"
Effects.Native = NativeEffects
local NameplateAnchor = PNC.NameplateFirearmAnchor

local MAX_FALLBACK_TRACERS = 96
local MAX_VISIBLE_TRACERS_PER_SHOT = 5
local MAX_MUZZLE_FLASHES = 48
local MAX_LIGHTS_PER_WINDOW = 2
local LIGHT_BUDGET_WINDOW_MS = 100
local TRACER_TTL = 12
local TRACER_SCREEN_LENGTH = 180
local DEBUG_SIMULATION_INTERVAL_MS = 500
local MUZZLE_FLASH_TTL = 2
local MUZZLE_FLASH_LENGTH = 42
local SCREEN_CULL_MARGIN = 96
local MUZZLE_FLASH_COLOR = { r = 1.0, g = 0.28, b = 0.02 }
local MUZZLE_CORE_COLOR = { r = 1.0, g = 0.88, b = 0.32 }
local TRACER_COLOR = { r = 1.0, g = 0.76, b = 0.18 }
local SHELL_TRACER_COLOR = { r = 1.0, g = 0.56, b = 0.06 }

-- Bore-line geometry. A tracer leaves the barrel, so the muzzle offset is
-- applied along the *shot bearing* and lifted to barrel height. The defaults
-- match Project A-Life's proven muzzle values so both mods draw the same line.
local BORE_MUZZLE_TILES = 0.55
local BORE_HEIGHT_TILES = 0.45
local BORE_SIDE_TILES = 0.05
local BORE_MIN_MODEL_LENGTH = 0.15
local BORE_MAX_MODEL_LENGTH = 2.5

local function nowMs()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return 0
end

local function reserveLightSlot()
    local now = nowMs()
    local windowAt = tonumber(Effects.LightWindowAt) or 0
    if now < windowAt or now - windowAt >= LIGHT_BUDGET_WINDOW_MS then
        Effects.LightWindowAt = now
        Effects.LightsInWindow = 0
    end
    if (tonumber(Effects.LightsInWindow) or 0) >= MAX_LIGHTS_PER_WINDOW then
        return false
    end
    Effects.LightsInWindow = (tonumber(Effects.LightsInWindow) or 0) + 1
    return true
end

local function logFirearmAudit(eventName, payload, ...)
    local fields
    local i
    if not Diagnostics
        or Diagnostics.FirearmAuditEnabled ~= true
        or type(Diagnostics.LogFirearmAudit) ~= "function"
    then
        return false
    end
    fields = {
        "side=client",
        "shotId=" .. tostring(payload and payload.shotId or ""),
        "npc=" .. tostring(payload and payload.npcId or ""),
        "class=" .. tostring(payload and payload.tacticalClass or "unknown"),
        "faction=" .. tostring(payload and payload.factionID or ""),
        "hostility=" .. tostring(payload and payload.hostilityMode or ""),
        "t=" .. tostring(nowMs()),
    }
    for i = 1, select("#", ...) do
        fields[#fields + 1] = tostring(select(i, ...))
    end
    return Diagnostics.LogFirearmAudit(eventName, fields)
end

local function logDrawBlocked(reason)
    local effect
    local tracer
    local key = tostring(reason or "unknown")
    if (#Effects.ActiveTracers <= 0 and #Effects.ActiveMuzzleFlashes <= 0)
        or Effects.DrawAuditState[key]
    then
        return
    end
    tracer = Effects.ActiveTracers[#Effects.ActiveTracers]
    effect = tracer or Effects.ActiveMuzzleFlashes[#Effects.ActiveMuzzleFlashes]
    logFirearmAudit("draw_blocked", effect and effect.auditPayload or nil,
        "reason=" .. key,
        "activeTracers=" .. tostring(#Effects.ActiveTracers),
        "activeMuzzleFlashes=" .. tostring(#Effects.ActiveMuzzleFlashes))
    Effects.DrawAuditState[key] = true
end

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    return method(target, ...)
end

local function recordNativeFailure(reason)
    if NativeEffects and NativeEffects.RecordFailure then
        NativeEffects.RecordFailure(reason)
    end
end

local UIDraw = {}

function Effects.OnPreUIDraw()
    return UIDraw.render()
end

Effects.Internal = Effects.Internal or {}
Effects.Internal.SimulationDeps = {
    nowMs = nowMs,
    readMethod = readMethod,
    DEBUG_SIMULATION_INTERVAL_MS = DEBUG_SIMULATION_INTERVAL_MS,
}
Effects.Internal.ResolutionDeps = {
    NativeEffects = NativeEffects,
    readMethod = readMethod,
    BORE_MUZZLE_TILES = BORE_MUZZLE_TILES,
    BORE_HEIGHT_TILES = BORE_HEIGHT_TILES,
    BORE_SIDE_TILES = BORE_SIDE_TILES,
    BORE_MIN_MODEL_LENGTH = BORE_MIN_MODEL_LENGTH,
    BORE_MAX_MODEL_LENGTH = BORE_MAX_MODEL_LENGTH,
}
require "PNC/PNC_ClientFirearmEffects_Resolution"
local Resolution = Effects.Internal.Resolution
Effects.Internal.AudioVisualDeps = {
    readMethod = readMethod,
    reserveLightSlot = reserveLightSlot,
}
require "PNC/PNC_ClientFirearmEffects_AudioVisual"
local AudioVisual = Effects.Internal.AudioVisual
Effects.Internal.ProjectileVisualDeps = {
    readMethod = readMethod,
    NameplateAnchor = NameplateAnchor,
    MAX_FALLBACK_TRACERS = MAX_FALLBACK_TRACERS,
    MAX_VISIBLE_TRACERS_PER_SHOT = MAX_VISIBLE_TRACERS_PER_SHOT,
    MAX_MUZZLE_FLASHES = MAX_MUZZLE_FLASHES,
    TRACER_TTL = TRACER_TTL,
    MUZZLE_FLASH_TTL = MUZZLE_FLASH_TTL,
    MUZZLE_FLASH_LENGTH = MUZZLE_FLASH_LENGTH,
    TRACER_COLOR = TRACER_COLOR,
    SHELL_TRACER_COLOR = SHELL_TRACER_COLOR,
}
require "PNC/PNC_ClientFirearmEffects_ScreenGeometry"
require "PNC/PNC_ClientFirearmEffects_ProjectileQueue"
local ProjectileVisual = Effects.Internal.ProjectileVisual
Effects.Internal.PlayDeps = {
    NativeEffects = NativeEffects,
    nowMs = nowMs,
    readMethod = readMethod,
    logFirearmAudit = logFirearmAudit,
    recordNativeFailure = recordNativeFailure,
    resolveBody = Resolution.resolveBody,
    resolveWeapon = Resolution.resolveWeapon,
    hasLiveAnchor = ProjectileVisual.hasLiveAnchor,
    getMuzzlePosition = Resolution.getMuzzlePosition,
    addMuzzleFlash = ProjectileVisual.addMuzzleFlash,
    spawnLight = AudioVisual.spawnLight,
    playShotAudio = AudioVisual.playShotAudio,
    addTracer = ProjectileVisual.addTracer,
    playImpact = ProjectileVisual.playImpact,
}
require "PNC/PNC_ClientFirearmEffects_Play"
require "PNC/PNC_ClientFirearmEffects_Simulation"
require "PNC/PNC_ClientFirearmEffects_Lifecycle"
Effects.Internal.UIDraw = UIDraw
Effects.Internal.UIDrawDeps = {
    Diagnostics = Diagnostics,
    SCREEN_CULL_MARGIN = SCREEN_CULL_MARGIN,
    TRACER_SCREEN_LENGTH = TRACER_SCREEN_LENGTH,
    MUZZLE_FLASH_LENGTH = MUZZLE_FLASH_LENGTH,
    MUZZLE_FLASH_COLOR = MUZZLE_FLASH_COLOR,
    MUZZLE_CORE_COLOR = MUZZLE_CORE_COLOR,
    logFirearmAudit = logFirearmAudit,
    logDrawBlocked = logDrawBlocked,
    readMethod = readMethod,
}
require "PNC/PNC_ClientFirearmEffects_UIDraw"

if Events and Events.OnTick then
    Events.OnTick.Add(Effects.OnTick)
end
if Events and Events.OnPreUIDraw then
    Events.OnPreUIDraw.Add(Effects.OnPreUIDraw)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Effects.Reset)
end

return Effects

--[[
    PNC Body Lifecycle
    Stable public entry point for body leases, corpse supervision, audits, and
    lifecycle diagnostics. Focused implementation modules live under the
    PNC_BodyLifecycle directory.
]]

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}

local Lifecycle = PNC.BodyLifecycle
Lifecycle.Internal = Lifecycle.Internal or {}

require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_State"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_World"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseWornItems"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_LiveBodies"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Corpses"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAudit"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Audit"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Diagnostics"

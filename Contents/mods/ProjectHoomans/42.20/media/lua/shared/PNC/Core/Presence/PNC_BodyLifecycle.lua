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
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_BodyFactory"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_IdentityAudit"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskLedger"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_LiveShellToken"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAwareness"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseWornItems"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_LiveBodies"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_HuskReaper"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Corpses"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Reanimation"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseAudit"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Audit"
require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Diagnostics"

-- Public engine boundary for authoritative corpse work. Keep the exact owner
-- functions: square membership, rollback, inert stamping and MP packet choice
-- remain BodyLifecycle policy. Tasking owns haul orders, never body internals.
-- Mutations are called only by authority-owned lifecycle/task execution.
Lifecycle.Corpses = Lifecycle.Corpses or {}
Lifecycle.Corpses.ForEach = Lifecycle.Internal.forEachCorpse
Lifecycle.Corpses.Move = Lifecycle.Internal.moveCorpse
Lifecycle.Corpses.Follow = Lifecycle.Internal.followCorpse
Lifecycle.Corpses.Remove = Lifecycle.Internal.removeCorpse
Lifecycle.Corpses.Stamp = Lifecycle.Internal.stampCorpse
Lifecycle.Corpses.Transmit = Lifecycle.Internal.transmitCorpseState

-- Read-only lease/identity proof shared with native pathing.
Lifecycle.MatchesRecordBody = Lifecycle.Internal.matchesRecordBody

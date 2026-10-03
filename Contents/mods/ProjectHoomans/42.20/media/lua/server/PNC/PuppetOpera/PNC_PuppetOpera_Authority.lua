-- Server-authoritative Puppet Opera session coordinator.
--
-- This module deliberately does not reuse the ordinary AnimationScenes
-- lifecycle. Puppet Opera owns a separate lease and only releases state that
-- carries the current session id.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Blueprints = Opera.Blueprints
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints"
local Anchors = Opera.Anchors
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors"
local Trace = Opera.Trace
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace"
local NPCMovement = Opera.NPCMovement
    or require "PNC/PuppetOpera/PNC_PuppetOpera_NPCMovementAdapter"
local NPCAnimation = Opera.NPCAnimation
    or require "PNC/PuppetOpera/PNC_PuppetOpera_NPCAnimationAdapter"
local NPCOverride = Opera.Override
    or require "PNC/PuppetOpera/PNC_PuppetOpera_OverrideAdapter"

local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal

Authority.Sessions = Authority.Sessions or {}
Authority.ByOwner = Authority.ByOwner or {}
Authority.ByActor = Authority.ByActor or {}
Authority.LastSnapshots = Authority.LastSnapshots or {}
Authority.Serial = tonumber(Authority.Serial) or 0

local Const = PNC.Const or {}
local Registry = PNC.Registry
local Core = PNC.Core

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Context"

-- Composition handoff for the runtime and request spokes. These references
-- are intentionally internal; the public surface remains Authority.
Internal.Opera = Opera
Internal.Blueprints = Blueprints
Internal.Anchors = Anchors
Internal.Trace = Trace
Internal.NPCMovement = NPCMovement
Internal.NPCAnimation = NPCAnimation
Internal.NPCOverride = NPCOverride
Internal.Registry = Registry
Internal.Core = Core
Internal.Const = Const

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Guards"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Lifecycle"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Admission"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Runtime"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Requests"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Acknowledgements"

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Bootstrap"

return Authority

-- Server-authoritative Puppet Opera session coordinator.
--
-- This module deliberately does not reuse the ordinary AnimationScenes
-- lifecycle. Puppet Opera owns a separate lease and only releases state that
-- carries the current session id.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Opera = PNC.Choreography
local Blueprints = Opera.Blueprints
    or require "PNC/Core/Choreography/PNC_Choreography_Blueprints"
local Anchors = Opera.Anchors
    or require "PNC/Core/Choreography/PNC_Choreography_Anchors"
local Trace = Opera.Trace
    or require "PNC/Core/Choreography/PNC_Choreography_Trace"
local NPCMovement = Opera.NPCMovement
    or require "PNC/Choreography/PNC_Choreography_NPCMovementAdapter"
local NPCAnimation = Opera.NPCAnimation
    or require "PNC/Choreography/PNC_Choreography_NPCAnimationAdapter"
local NPCOverride = Opera.Override
    or require "PNC/Choreography/PNC_Choreography_OverrideAdapter"

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

require "PNC/Choreography/PNC_Choreography_Authority_Context"

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

require "PNC/Choreography/PNC_Choreography_Authority_Guards"
require "PNC/Choreography/PNC_Choreography_Authority_VisualSync"
require "PNC/Choreography/PNC_Choreography_Authority_Lifecycle"
require "PNC/Choreography/PNC_Choreography_Authority_Admission"
require "PNC/Choreography/PNC_Choreography_Authority_Runtime"
require "PNC/Choreography/PNC_Choreography_Authority_Requests"
require "PNC/Choreography/PNC_Choreography_Authority_Acknowledgements"

require "PNC/Choreography/PNC_Choreography_Authority_Bootstrap"

return Authority

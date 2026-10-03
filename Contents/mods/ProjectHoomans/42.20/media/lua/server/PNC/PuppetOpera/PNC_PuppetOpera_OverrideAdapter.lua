-- Temporary Puppet Opera ownership composition root.
--
-- The public Override table remains stable while readiness, reservation
-- maintenance, and ownership lifecycle live in focused providers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Override = PNC.PuppetOpera.Override or {}

local Override = PNC.PuppetOpera.Override
local Internal = Override.Internal or {}
Override.Internal = Internal
Internal.Core = PNC.Core
Internal.Scenes = PNC.AnimationScenes
Internal.MoveIntent = PNC.BehaviorMoveIntent
Internal.PathService = PNC.PathService
Internal.Common = PNC.BehaviorCommon
Internal.Scheduler = PNC.Scheduler
Internal.ThreatGuard = PNC.BehaviorThreatGuard
Internal.ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

require "PNC/PuppetOpera/PNC_PuppetOpera_Override_Context"
require "PNC/PuppetOpera/PNC_PuppetOpera_Override_Readiness"
require "PNC/PuppetOpera/PNC_PuppetOpera_Override_Maintenance"
require "PNC/PuppetOpera/PNC_PuppetOpera_Override_Lifecycle"

return Override

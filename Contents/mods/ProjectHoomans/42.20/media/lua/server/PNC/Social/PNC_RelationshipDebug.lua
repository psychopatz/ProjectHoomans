-- Developer snapshots plus guarded named-event dispatch for relationships.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_Context"
require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_SnapshotParts"
require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_SnapshotBuilder"
require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_Pacification"
require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_Requests"
require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_SocialEvents"
require "PNC/Social/RelationshipDebug/PNC_RelationshipDebug_Formatting"

return PNC.RelationshipDebug

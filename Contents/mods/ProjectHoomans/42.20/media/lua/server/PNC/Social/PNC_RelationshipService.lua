-- Server-authoritative mutation API for directed personal relationships.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

require "PNC/Social/RelationshipService/PNC_RelationshipService_Context"
require "PNC/Social/RelationshipService/PNC_RelationshipService_Commit"
require "PNC/Social/RelationshipService/PNC_RelationshipService_InteractionJournal"
require "PNC/Social/RelationshipService/PNC_RelationshipService_Queries"
require "PNC/Social/RelationshipService/PNC_RelationshipService_MemoryCommands"
require "PNC/Social/RelationshipService/PNC_RelationshipService_EventMutation"
require "PNC/Social/RelationshipService/PNC_RelationshipService_Maintenance"
require "PNC/Social/RelationshipService/PNC_RelationshipService_PersonalBoundary"

return PNC.Relationships

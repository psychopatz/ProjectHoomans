-- Defensive relationship constructors and canonical normalizers.
-- Primitive, interaction, and public type providers load in order.

PNC = PNC or {}
PNC.RelationshipTypes = PNC.RelationshipTypes or {}

require "PNC/Core/Relationships/PNC_RelationshipTypes_Core"
require "PNC/Core/Relationships/PNC_RelationshipTypes_Interactions"
require "PNC/Core/Relationships/PNC_RelationshipTypes_Public"

return PNC.RelationshipTypes

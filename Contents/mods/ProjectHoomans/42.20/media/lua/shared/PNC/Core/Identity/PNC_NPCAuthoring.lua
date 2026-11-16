-- Public shared NPC authoring pipeline.

PNC = PNC or {}

require "PNC/Core/Identity/PNC_NPCAuthoringRegistry"
require "PNC/Core/Identity/PNC_NPCAuthoringBlueprint"
require "PNC/Core/Identity/PNC_NPCAuthoringResolver"

PNC.NPCAuthoring = PNC.NPCAuthoring or {}
PNC.NPCAuthoring.Registry = PNC.NPCAuthoringFieldRegistry
PNC.NPCAuthoring.Blueprint = PNC.NPCAuthoringBlueprint
PNC.NPCAuthoring.Resolver = PNC.NPCAuthoringResolver

return PNC.NPCAuthoring

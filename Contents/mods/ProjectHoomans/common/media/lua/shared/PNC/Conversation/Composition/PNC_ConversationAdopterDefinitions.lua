-- Shared adopter composition for the current PNC conversation surface.
-- PSDL owns migrated social check-in blocks; remaining domains stay on their
-- existing authorities until their own parity/caller-zero migration gate.

require "PNC/Conversation/PSDL/PNC_ConversationPSDLBlocks"
require "PNC/Conversation/Definitions/21_PNC_ConversationSettlementAdmission"
require "PNC/Conversation/Definitions/70_PNC_ConversationNeeds"
require "PNC/Conversation/Definitions/90_PNC_ConversationWorkOrders"
require "PNC/Conversation/Definitions/91_PNC_ConversationPersonal"
require "PNC/Conversation/Definitions/92_PNC_ConversationRelationship"
require "PNC/Conversation/Definitions/93_PNC_ConversationSetTerritory"
require "PNC/Conversation/Definitions/Memory/00_PNC_ConversationMemoryDefinitions"

return true

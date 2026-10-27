-- Stable response-catalog entry point.
-- Selection stays deterministic while pool providers remain independently
-- loadable and the public ResponseCatalog object remains unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog or {}
PNC.Semantics.ResponseCatalog = Catalog
local GeneratedDialogue = require
    "PNC/Semantics/Generated/Dialogue/CommonInteractions"
local GeneratedPersonalDialogue = require
    "PNC/Semantics/Generated/Dialogue/GroundedPersonalDialogue"
local GeneratedDefinitions = require
    "PNC/Semantics/Generated/SemanticAuthoring/Catalog"

local Core = require
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Core"
local registerCatalog = require
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Registration"
local installSelection = require
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Selection"
local registerGenerated = require
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Generated"

Core.install(Catalog)
registerCatalog(Catalog, Core)
installSelection(Catalog, Core)

-- Built-in pools are grouped by semantic responsibility. The entry owns
-- catalog mechanics and loads providers before generated extensions.
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Situational"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_FlowGreeting"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_FlowWeather"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Questions"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Social"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_ToolReplies"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Compatibility"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_PlayerEmote"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_CompanionCommands"
require "PNC/Semantics/SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_Navigation"

registerGenerated(Catalog, {
    GeneratedDialogue,
    GeneratedPersonalDialogue,
}, GeneratedDefinitions)

return Catalog

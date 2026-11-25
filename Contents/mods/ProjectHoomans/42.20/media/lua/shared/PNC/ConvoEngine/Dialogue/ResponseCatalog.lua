-- Stable response-catalog entry point.
-- Selection stays deterministic while pool providers remain independently
-- loadable and the public ResponseCatalog object remains unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Catalog = PNC.ConvoEngine.ResponseCatalog or {}
PNC.ConvoEngine.ResponseCatalog = Catalog
local ConversationRegistry = require
    "PNC/ConvoEngine/Registry"

local Core = require
    "PNC/ConvoEngine/Dialogue/ResponseCatalog_Core"
local registerCatalog = require
    "PNC/ConvoEngine/Dialogue/ResponseCatalog_Registration"
local installSelection = require
    "PNC/ConvoEngine/Dialogue/ResponseCatalog_Selection"
local registerConversationPools = require
    "PNC/ConvoEngine/Dialogue/ResponseCatalog_Conversation"

Core.install(Catalog)
registerCatalog(Catalog, Core)
installSelection(Catalog, Core)

-- Runtime .convo language packs in media/translation/ConvoBlocks/<LANG>/
-- are the single authored response authority (no offline codebuilder needed).
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
ConvoDSL.EnsureActiveLanguage()

registerConversationPools(
    Catalog,
    ConversationRegistry and ConversationRegistry.RESPONSE_POOLS
)

return Catalog

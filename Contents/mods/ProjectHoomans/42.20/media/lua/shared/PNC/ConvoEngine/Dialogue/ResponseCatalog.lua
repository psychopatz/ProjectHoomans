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

-- Built-in pools are grouped by semantic responsibility. The entry owns
-- catalog mechanics and loads providers before generated extensions.
require "PNC/ConvoEngine/ResponseCatalog/Situational"
-- Install Core-compiled PSDL wording before providers normalize response
-- variants. Existing semantic providers use the shared content fallback seam
-- during registration; load order must not make that fallback depend on the
-- retired generated Content modules.
require "PNC/ConvoEngine/ResponseCatalog/SocialContent_Core"
require "PNC/ConvoEngine/ResponseCatalog/FlowGreeting"
require "PNC/ConvoEngine/ResponseCatalog/FlowWeather"
require "PNC/ConvoEngine/ResponseCatalog/Questions"
require "PNC/ConvoEngine/ResponseCatalog/Social"
require "PNC/ConvoEngine/ResponseCatalog/ToolReplies"
require "PNC/ConvoEngine/ResponseCatalog/Compatibility"
require "PNC/ConvoEngine/ResponseCatalog/PlayerEmote"
require "PNC/ConvoEngine/ResponseCatalog/CompanionCommands"
require "PNC/ConvoEngine/ResponseCatalog/Navigation"

registerConversationPools(
    Catalog,
    ConversationRegistry and ConversationRegistry.RESPONSE_POOLS
)

return Catalog

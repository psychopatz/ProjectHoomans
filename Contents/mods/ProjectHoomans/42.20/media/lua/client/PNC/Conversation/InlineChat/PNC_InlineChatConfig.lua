-- Shared constants for the compact inline chat adapter.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config or {}
Internal.Config = Config

Config.MAX_INPUT_LENGTH = Config.MAX_INPUT_LENGTH or 4000
Config.WIDTH = Config.WIDTH or 320
Config.HEIGHT = Config.HEIGHT or 108
Config.PLAYER_Y_OFFSET = Config.PLAYER_Y_OFFSET or 36
Config.LIFECYCLE_INTERVAL_MS = Config.LIFECYCLE_INTERVAL_MS or 100
Config.CONTEXT_REFRESH_INTERVAL_MS = Config.CONTEXT_REFRESH_INTERVAL_MS or 500
Config.CONTROLS_REFRESH_INTERVAL_MS = Config.CONTROLS_REFRESH_INTERVAL_MS or 250
Config.RECOVERY_INTERVAL_MS = Config.RECOVERY_INTERVAL_MS or 250
Config.RECOVERY_GRACE_MS = Config.RECOVERY_GRACE_MS or 4000
Config.MODE_NEAREST = "nearest"
Config.MODE_NEARBY = "nearby"
Config.DEFAULT_MODE = Config.MODE_NEARBY
Config.SCOPE_COLONISTS = "colonists"
Config.SCOPE_OTHER = "other"
Config.SCOPE_SOCIAL = "social"
Config.HIGHLIGHT_COLOR = { r = 0.0, g = 1.0, b = 1.0, a = 0.85 }
Config.TITLE = {
    key = "UI_PsychopatzConversation_Panel_LLMInlineInput",
    fallback = "TALK TO",
}
Config.MODE_BUTTONS = {
    {
        id = Config.MODE_NEAREST,
        mode = Config.MODE_NEAREST,
        title = { key = "UI_PsychopatzConversation_LLM_ModeNearest", fallback = "SINGLE NPC" },
        image = "media/ui/MP/mp_ui_emptyServer.png",
    },
    {
        id = Config.MODE_NEARBY,
        mode = Config.MODE_NEARBY,
        title = { key = "UI_PsychopatzConversation_LLM_ModeNearby", fallback = "NEARBY NPCS" },
        image = "media/ui/MP/mp_ui_playerCount.png",
    },
}
Config.SCOPE_TOGGLE = {
    id = "npcScope",
    title = { key = "llm.scope.colonists", fallback = "COLONISTS" },
    alternateTitle = { key = "llm.scope.other", fallback = "OTHER NPCS" },
}

return Config

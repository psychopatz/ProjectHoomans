-- Shared constants for the compact inline chat adapter.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Internal = PNC.PBrainZ.Internal
local Config = Internal.InlineChatConfig or {}
Internal.InlineChatConfig = Config

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
Config.SCOPE_COLONISTS = "colonists"
Config.SCOPE_OTHER = "other"
Config.SCOPE_SOCIAL = "social"
Config.HIGHLIGHT_COLOR = {
    r = 0.0, g = 1.0, b = 1.0, a = 0.85,
}
Config.TITLE = {
    key = "panel.llm_inline_input",
    domain = "pnc.system.shared.categories",
    fallback = "TALK TO",
}
Config.MODE_BUTTONS = {
    {
        id = Config.MODE_NEAREST,
        mode = Config.MODE_NEAREST,
        title = { key = "llm.mode.nearest", fallback = "SINGLE NPC" },
        image = "media/ui/MP/mp_ui_emptyServer.png",
    },
    {
        id = Config.MODE_NEARBY,
        mode = Config.MODE_NEARBY,
        title = { key = "llm.mode.nearby", fallback = "NEARBY NPCS" },
        image = "media/ui/MP/mp_ui_playerCount.png",
    },
}
Config.SCOPE_TOGGLE = {
    id = "npcScope",
    title = { key = "llm.scope.colonists", fallback = "COLONISTS" },
    alternateTitle = { key = "llm.scope.other", fallback = "OTHER NPCS" },
}

return Config

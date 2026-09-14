local T = require "tests/support/test"

PNC = {}
getText = function(key)
    if type(key) ~= "string" then
        error("getText received a non-string key")
    end
    return "translated:" .. key
end

local Shared = T.load(
    "ProjectHoomans", "client",
    "PNC/UI/CharacterWindow/PNC_CharacterWindow_Shared.lua")

T.equal(Shared.Text(nil, "trait fallback"), "trait fallback",
    "missing translation key uses fallback without calling the engine")
T.equal(Shared.Text("", "empty fallback"), "empty fallback",
    "empty translation key uses fallback")
T.equal(Shared.Text("UI_Test_Trait", "fallback"),
    "translated:UI_Test_Trait",
    "valid translation key remains available")

T.finish("pnc_character_window_text_smoke")

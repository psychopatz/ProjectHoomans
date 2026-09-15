-- Project Hoomans custom catalogs.
-- The manager itself belongs to PsychopatzCore so future mods can reuse it;
-- this file only declares which Hoomans catalogs exist.
require "CustomTranslationManager"

PNC = PNC or {}
PNC.Translation = PNC.Translation or {}

local Translations = CustomTranslationManager.forMod("ProjectHoomans")

PNC.Translation.Traits = Translations
    and Translations.registerSystem("Traits", "media/translation")

return PNC.Translation.Traits

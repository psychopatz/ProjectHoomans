-- Project Hoomans custom catalogs.
-- The manager itself belongs to PsychopatzCore so future mods can reuse it;
-- this file only declares which Hoomans catalogs exist.
require "PsychopatzCore/Translation/PsychopatzCustomTranslationManager"

PNC = PNC or {}
PNC.Translation = PNC.Translation or {}

local Manager = CustomTranslationManager

PNC.Translation.Traits = Manager.registerSystem({
    modID = "ProjectHoomans",
    systemName = "Traits",
    basePath = "media/translation",
})

return PNC.Translation.Traits

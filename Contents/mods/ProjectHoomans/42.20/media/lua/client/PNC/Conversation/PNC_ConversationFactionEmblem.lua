-- Build 42.20 conversation faction-emblem renderer integration.
-- Project Hoomans presentation extension for PsychopatzCore conversations.
-- Persistent conversation data carries only the serialization-safe emblem
-- specification. Vanilla map-symbol textures are resolved by the client
-- renderer at draw time.

require "PNC/UI/Factions/PNC_FactionPresentation"

PNC = PNC or {}
PNC.ConversationFactionEmblem =
    PNC.ConversationFactionEmblem or {}

local Extension = PNC.ConversationFactionEmblem

local function renderFactionSubtitle(portrait)
    if PNC.FactionPresentation and PNC.FactionPresentation.RenderPortraitPlate then
        PNC.FactionPresentation.RenderPortraitPlate(portrait)
    end
end

function Extension.Install()
    local portraitClass = PsychopatzConversationPortrait
    if type(portraitClass) ~= "table"
        or type(portraitClass.render) ~= "function"
    then
        return false
    end
    if portraitClass.render
        == Extension.InstalledRender
    then
        return true
    end

    local originalRender = portraitClass.render
    local function patchedRender(self)
        originalRender(self)
        renderFactionSubtitle(self)
    end

    Extension.OriginalRender = originalRender
    Extension.InstalledRender = patchedRender
    portraitClass.render = patchedRender
    return true
end

Extension.RenderFactionSubtitle = renderFactionSubtitle
Extension.Install()

return Extension

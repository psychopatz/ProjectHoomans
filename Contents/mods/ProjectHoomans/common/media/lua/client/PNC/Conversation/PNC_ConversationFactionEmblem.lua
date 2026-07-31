-- Project Hoomans presentation extension for PsychopatzCore conversations.
-- Persistent conversation data carries only the serialization-safe emblem
-- specification. Vanilla map-symbol textures are resolved by the client
-- renderer at draw time.

require "PNC/UI/Factions/PNC_FactionEmblemRenderer"

PNC = PNC or {}
PNC.ConversationFactionEmblem =
    PNC.ConversationFactionEmblem or {}

local Extension = PNC.ConversationFactionEmblem

local function getContext(portrait)
    return portrait
        and portrait.owner
        and portrait.owner.spec
        and portrait.owner.spec.context
        or nil
end

local function renderFactionSubtitle(portrait)
    if (portrait.reveal or 0) <= 0.18 then return end

    local context = getContext(portrait)
    if type(context) ~= "table"
        or type(context.factionEmblem) ~= "table"
        or tostring(context.factionName or "") == ""
    then
        return
    end

    local renderer = PNC.FactionEmblemRenderer
    if not renderer or not renderer.Draw then return end

    local alpha = portrait:getContentOpacity()
    local accent = portrait:getAccentColor()
    local bright = PsychopatzCore.Conversation.Theme.Brighten(
        accent,
        0.34
    )
    local plateHeight = math.max(
        48,
        math.min(62, portrait.height * 0.18)
    )
    local plateY = portrait.height - plateHeight - 3
    local iconSize = 18
    local iconX = 12
    local iconY = plateY + 25

    -- Replace only PsychopatzCore's subtitle row, leaving the NPC name and
    -- portrait plate intact.
    portrait:drawRect(
        3,
        plateY + 23,
        portrait.width - 7,
        plateHeight - 23,
        alpha * 0.91,
        0.012,
        0.030,
        0.025
    )
    renderer.Draw(
        portrait,
        context.factionEmblem,
        iconX,
        iconY,
        iconSize,
        {
            alpha = alpha * 0.96,
        }
    )

    local subtitle = tostring(context.factionName)
        .. "  /  "
        .. tostring(context.factionRole or "Member")
    portrait:drawText(
        string.upper(subtitle),
        iconX + iconSize + 7,
        plateY + 28,
        bright.r,
        bright.g,
        bright.b,
        alpha * 0.92,
        UIFont.Small
    )
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

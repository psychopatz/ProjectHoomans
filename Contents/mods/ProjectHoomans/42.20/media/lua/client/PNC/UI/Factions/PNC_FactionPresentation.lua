-- Build 42.20 unified presentation gateway and renderer for faction emblems & identities.
-- Shared between Map Hover Cards, Map Layers, and Conversation UI.

require "PNC/UI/Factions/PNC_FactionEmblemRenderer"

PNC = PNC or {}
PNC.FactionPresentation = PNC.FactionPresentation or {}

local FactionPresentation = PNC.FactionPresentation
local EmblemRenderer = PNC.FactionEmblemRenderer

local function sanitizeString(val)
    if val == nil then return nil end
    local str = tostring(val)
    if str == "" or str == "nil" or str == "NIL" then return nil end
    return str
end

local function getContext(target)
    if type(target) ~= "table" then return nil end
    if target.owner and target.owner.spec and target.owner.spec.context then
        return target.owner.spec.context
    end
    return target.spec and target.spec.context or target.context or target
end

function FactionPresentation.Resolve(targetOrEntry)
    if type(targetOrEntry) ~= "table" then return nil end

    local context = getContext(targetOrEntry)
    local entry = context and context.entry or targetOrEntry
    local Identity = PNC.NPCIdentityPresentation

    local name = Identity and Identity.GetName and Identity.GetName(entry) or nil
    if not name and context then
        name = sanitizeString(context.npcName)
    end

    local isNameKnown = false
    if context and context.identityState == "known" then
        isNameKnown = true
    elseif context and (context.identityState == "unknown" or context.identityState == "loading") then
        isNameKnown = false
    elseif Identity and Identity.IsNameKnown then
        isNameKnown = Identity.IsNameKnown(entry)
    elseif name and string.upper(name) ~= "STRANGER" and string.upper(name) ~= "UNKNOWN SURVIVOR" then
        isNameKnown = true
    end

    local factionObj = nil
    if Identity and Identity.GetFaction then
        factionObj = Identity.GetFaction(entry)
    end
    if not factionObj and context then
        if type(context.factionEmblem) == "table" or sanitizeString(context.factionName) then
            factionObj = {
                name = context.factionName,
                role = context.factionRole,
                id = context.factionID,
                emblem = context.factionEmblem,
            }
        end
    end

    if type(factionObj) ~= "table" then
        local source = entry and (entry.snapshot or entry.record or entry.source or entry)
        if type(source) == "table" and source.organizationalFaction then
            factionObj = source.organizationalFaction
        end
    end

    if type(factionObj) ~= "table" then
        return {
            isKnown = false,
            isNameKnown = isNameKnown,
            npcName = name or "STRANGER",
            factionName = nil,
            factionRole = nil,
            subtitle = nil,
            emblem = nil,
        }
    end

    local factionName = sanitizeString(factionObj.name or factionObj.factionName)
    local factionRole = sanitizeString(factionObj.role or factionObj.rank or factionObj.factionRole)
    local emblem = type(factionObj.emblem) == "table" and factionObj.emblem or nil
    local factionID = sanitizeString(factionObj.id or factionObj.factionID)

    local subtitle = nil
    if factionName then
        subtitle = factionName
        if factionRole then
            subtitle = subtitle .. "  /  " .. factionRole
        end
    end

    return {
        isKnown = isNameKnown and (factionName ~= nil or emblem ~= nil),
        isNameKnown = isNameKnown,
        npcName = name or "STRANGER",
        factionID = factionID,
        factionName = factionName,
        factionRole = factionRole,
        subtitle = subtitle,
        emblem = emblem,
    }
end

function FactionPresentation.DrawBadge(targetUI, emblem, x, y, size, options)
    if not targetUI then return false end
    options = type(options) == "table" and options or {}
    size = math.max(8, tonumber(size) or 24)

    if type(emblem) == "table" and EmblemRenderer and EmblemRenderer.Draw then
        return EmblemRenderer.Draw(targetUI, emblem, x, y, size, options)
    end

    if targetUI.drawRect then
        targetUI:drawRect(x, y, size, size, options.alpha or 0.8, 0.1, 0.1, 0.1)
    end
    return false
end

function FactionPresentation.RenderPortraitPlate(portraitUI, rawContext)
    if not portraitUI or (portraitUI.reveal or 0) <= 0.18 then return end

    local presentation = FactionPresentation.Resolve(rawContext or portraitUI)
    if not presentation then return end

    -- Only render the emblem & faction plate when player knows identity and faction exists
    if not presentation.isNameKnown or not presentation.isKnown or not presentation.emblem then
        return
    end

    local alpha = portraitUI:getContentOpacity()
    local accent = portraitUI:getAccentColor()
    local bright = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Theme
        and PsychopatzCore.Conversation.Theme.Brighten(accent, 0.34)
        or accent

    local plateHeight = math.max(48, math.min(62, portraitUI.height * 0.18))
    local plateY = portraitUI.height - plateHeight - 3

    local iconSize = math.max(28, math.min(36, math.floor(plateHeight * 0.65)))
    local iconX = 10
    local iconY = plateY + math.floor((plateHeight - iconSize) / 2)
    local textX = iconX + iconSize + 10

    -- OPAQUE (1.0 alpha) background overdraw to completely erase core's default text/box underneath
    portraitUI:drawRect(
        3,
        plateY + 2,
        portraitUI.width - 7,
        plateHeight - 2,
        1.0,
        0.012,
        0.030,
        0.025
    )

    -- Draw Emblem Icon
    FactionPresentation.DrawBadge(portraitUI, presentation.emblem, iconX, iconY, iconSize, {
        alpha = alpha * 0.96,
    })

    -- Draw NPC Name
    portraitUI:drawText(
        string.upper(tostring(presentation.npcName or "")),
        textX,
        plateY + 7,
        bright.r or 1,
        bright.g or 1,
        bright.b or 1,
        alpha,
        UIFont.Small
    )

    -- Draw Faction Subtitle (only if subtitle exists)
    if presentation.subtitle then
        portraitUI:drawText(
            string.upper(tostring(presentation.subtitle)),
            textX,
            plateY + 27,
            bright.r or 1,
            bright.g or 1,
            bright.b or 1,
            alpha * 0.92,
            UIFont.Small
        )
    end
end

return FactionPresentation

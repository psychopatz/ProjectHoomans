local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual")
            .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local emblemDraw
local originalRenderCount = 0

PNC = {
    FactionEmblemRenderer = {
        Draw = function(target, emblem, x, y, size, options)
            emblemDraw = {
                target = target,
                emblem = emblem,
                x = x,
                y = y,
                size = size,
                alpha = options and options.alpha,
            }
            return true
        end,
    },
}
PsychopatzCore = {
    Conversation = {
        Theme = {
            Brighten = function(color)
                return color
            end,
        },
    },
}
UIFont = {
    Small = "small",
}
PsychopatzConversationPortrait = {
    render = function()
        originalRenderCount = originalRenderCount + 1
    end,
}

package.loaded["PNC/UI/Factions/PNC_FactionEmblemRenderer"] = nil
package.preload["PNC/UI/Factions/PNC_FactionEmblemRenderer"] =
    function()
        return PNC.FactionEmblemRenderer
    end

package.loaded["PNC/UI/Factions/PNC_FactionPresentation"] = nil
package.preload["PNC/UI/Factions/PNC_FactionPresentation"] =
    function()
        return PNC.FactionPresentation
    end

dofile(
    ROOT
        .. "PNC/UI/Factions/PNC_FactionPresentation.lua"
)
dofile(
    ROOT
        .. "PNC/Conversation/PNC_ConversationFactionEmblem.lua"
)

local drawnTexts = {}
local portrait = {
    reveal = 1,
    width = 460,
    height = 360,
    owner = {
        spec = {
            context = {
                identityState = "known",
                npcName = "Darrel Driscoll",
                factionName = "The Cold Crows",
                factionRole = "Scavenger",
                factionEmblem = {
                    backgroundColorID = "black",
                    layers = {},
                },
            },
        },
    },
    getContentOpacity = function()
        return 1
    end,
    getAccentColor = function()
        return { r = 1, g = 0.25, b = 0.18 }
    end,
    drawRect = function() end,
    drawText = function(_, text, x, y)
        table.insert(drawnTexts, {
            text = text,
            x = x,
            y = y,
        })
    end,
}
setmetatable(
    portrait,
    {
        __index = PsychopatzConversationPortrait,
    }
)

portrait:render()
assertEqual(originalRenderCount, 1, "core portrait render preserved")
assertEqual(emblemDraw.target, portrait, "emblem target")
assertEqual(emblemDraw.size, 36, "conversation emblem size is larger (36)")
assertEqual(emblemDraw.x, 10, "emblem x position on far left")
assertEqual(#drawnTexts, 2, "two text elements drawn (name and faction)")
assertEqual(drawnTexts[1].text, "DARREL DRISCOLL", "npc name rendered")
assertEqual(drawnTexts[1].x, 56, "npc name offset to right of emblem")
assertEqual(
    drawnTexts[2].text,
    "THE COLD CROWS  /  SCAVENGER",
    "faction subtitle rendered"
)
assertEqual(drawnTexts[2].x, 56, "faction subtitle aligned under name")

PNC.ConversationFactionEmblem.Install()
portrait:render()
assertEqual(
    originalRenderCount,
    2,
    "idempotent install does not wrap portrait twice"
)

emblemDraw = nil
drawnTexts = {}
portrait.owner.spec.context.identityState = "unknown"
portrait:render()
assertEqual(emblemDraw, nil, "unknown name suppresses emblem rendering")

emblemDraw = nil
drawnTexts = {}
portrait.owner.spec.context.identityState = "known"
portrait.owner.spec.context.factionEmblem = nil
portrait:render()
assertEqual(emblemDraw, nil, "missing emblem suppresses faction rendering")

print("pnc_conversation_faction_emblem_smoke: ok")

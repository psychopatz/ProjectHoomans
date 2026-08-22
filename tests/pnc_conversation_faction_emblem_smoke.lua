local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "client", "")

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

T.load(
    ROOT
        .. "PNC/UI/Factions/PNC_FactionPresentation.lua"
)
T.load(
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
T.equal(originalRenderCount, 1, "core portrait render preserved")
T.equal(emblemDraw.target, portrait, "emblem target")
T.equal(emblemDraw.size, 36, "conversation emblem size is larger (36)")
T.equal(emblemDraw.x, 10, "emblem x position on far left")
T.equal(#drawnTexts, 2, "two text elements drawn (name and faction)")
T.equal(drawnTexts[1].text, "DARREL DRISCOLL", "npc name rendered")
T.equal(drawnTexts[1].x, 56, "npc name offset to right of emblem")
T.equal(
    drawnTexts[2].text,
    "THE COLD CROWS  /  SCAVENGER",
    "faction subtitle rendered"
)
T.equal(drawnTexts[2].x, 56, "faction subtitle aligned under name")

PNC.ConversationFactionEmblem.Install()
portrait:render()
T.equal(
    originalRenderCount,
    2,
    "idempotent install does not wrap portrait twice"
)

emblemDraw = nil
drawnTexts = {}
portrait.owner.spec.context.identityState = "unknown"
portrait:render()
T.equal(emblemDraw, nil, "unknown name suppresses emblem rendering")

emblemDraw = nil
drawnTexts = {}
portrait.owner.spec.context.identityState = "known"
portrait.owner.spec.context.factionEmblem = nil
portrait:render()
T.equal(emblemDraw, nil, "missing emblem suppresses faction rendering")
T.finish("pnc_conversation_faction_emblem_smoke")

T.finish("pnc_conversation_faction_emblem_smoke")

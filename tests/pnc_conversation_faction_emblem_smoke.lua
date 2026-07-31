local ROOT =
    "Contents/mods/ProjectHoomans/common/media/lua/client/"

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

dofile(
    ROOT
        .. "PNC/Conversation/PNC_ConversationFactionEmblem.lua"
)

local drawnText
local portrait = {
    reveal = 1,
    width = 460,
    height = 360,
    owner = {
        spec = {
            context = {
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
        drawnText = {
            text = text,
            x = x,
            y = y,
        }
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
assertEqual(emblemDraw.size, 18, "conversation emblem size")
assertEqual(
    drawnText.text,
    "THE COLD CROWS  /  SCAVENGER",
    "faction subtitle"
)
assertEqual(drawnText.x > emblemDraw.x, true, "text follows emblem")

PNC.ConversationFactionEmblem.Install()
portrait:render()
assertEqual(
    originalRenderCount,
    2,
    "idempotent install does not wrap portrait twice"
)

emblemDraw = nil
portrait.owner.spec.context.factionEmblem = nil
portrait:render()
assertEqual(emblemDraw, nil, "missing emblem keeps core subtitle")

print("pnc_conversation_faction_emblem_smoke: ok")

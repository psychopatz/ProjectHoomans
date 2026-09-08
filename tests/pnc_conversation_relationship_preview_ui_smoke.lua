local T = require "tests/support/test"

T.addPackagePaths()

local Parent = {}
Parent.__index = Parent

function Parent:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end

function Parent:new(x, y, width, height, options)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        options = options or {},
    }, self)
end

function Parent:initialise() end
function Parent:createChildren() end
function Parent:prerender() end
function Parent:render() end
function Parent:setVisible() end
function Parent:setCapture() end
function Parent:getParent() return self.parent end
function Parent:getX() return self.x or 0 end
function Parent:getY() return self.y or 0 end
function Parent:getHeight() return self.height or 0 end
function Parent:setX(value) self.x = value end
function Parent:setY(value) self.y = value end
function Parent:setWidth(value) self.width = value end
function Parent:setHeight(value) self.height = value end
function Parent:drawRect() end
function Parent:drawRectBorder() end
function Parent:drawText(text) self.lastDrawText = text end
function Parent:drawTextCentre() end
function Parent:isMouseOver() return false end
function Parent:getMouseX() return self.mouseX or 0 end
function Parent:getMouseY() return self.mouseY or 0 end
function Parent:getContentOpacity() return 1 end
function Parent:getAccentColor()
    return { r = 0.2, g = 0.86, b = 0.68 }
end

ISPanel = Parent
PsychopatzConversationPart = Parent
UIFont = { Small = 1 }

PNC = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_RelationshipGraph.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_RelationshipPresentation.lua"
)

local originalRequire = require
require = function(name)
    if name == "ISUI/ISPanel" then return Parent end
    return originalRequire(name)
end
local RelationshipGraphPanel = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Relationships/PNC_RelationshipGraphPanel.lua"
)
require = originalRequire

require = function(name)
    if name == "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
    then
        return Parent
    end
    if name == "ISUI/ISPanel" then
        return Parent
    end
    if name == "PNC/UI/Relationships/PNC_RelationshipGraphPanel" then
        ISPNCRelationshipGraphPanel = {
            new = function(_, x, y, width, height)
                return setmetatable({
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                }, Parent)
            end,
        }
        return ISPNCRelationshipGraphPanel
    end
    return originalRequire(name)
end

local RelationshipPanel = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationRelationshipPanel.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationRelationship.lua"
)
require = originalRequire

local capturedEvaluation
local panel = RelationshipPanel:new(0, 0, 300, 300, {
    relationship = {
        exists = true,
        approval = 50,
        respect = 50,
    },
})
panel.graph = {
    setEvaluation = function(_, evaluation)
        capturedEvaluation = evaluation
    end,
    getEvaluation = function()
        return capturedEvaluation
    end,
}

local view = {
    spec = { npcID = "npc-preview" },
    extensionParts = { relationship = panel },
}
PsychopatzCore = { Conversation = { instance = view } }

local ok, reason = PNC.Conversation.Relationship.SetPreviewRequirement(
    "npc-preview",
    "recruit"
)
T.truthy(ok, "recruit hover reaches the relationship panel")
T.equal(reason, nil, "recruit hover has no routing error")
T.equal(panel.requirement, "recruit", "panel stores recruit preview")
T.equal(capturedEvaluation.requirement.id, "recruit",
    "panel rebuilds a recruit evaluation")
T.equal(capturedEvaluation.requirement.enabled, true,
    "recruit threshold is enabled")
T.equal(capturedEvaluation.threshold, 35,
    "recruit threshold reaches the graph evaluator")
T.truthy(PNC.RelationshipGraph.BoundaryApprovalAtRespect(
    0,
    capturedEvaluation.requirement,
    capturedEvaluation.contextBonus
),
    "recruit evaluation exposes a visible boundary")
panel:prerender()
T.contains(panel.lastDrawText, "REQ RECRUIT >= +35.0",
    "relationship header exposes the active recruit threshold")

PsychopatzCore.Conversation.Text = {
    Resolve = function(value)
        if type(value) == "table" then
            return value.text or value.fallback or ""
        end
        return value
    end,
}
require = function(name)
    if name == "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
    then
        return Parent
    end
    return originalRequire(name)
end
local Choices = T.load(
    "PsychopatzCore",
    "common_client",
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices.lua"
)
require = originalRequire
local choices = Choices:new(0, 0, 300, 180, {})
choices:setChoices({
    {
        id = "recruit",
        text = "Recruit",
        onHighlightChanged = function(_, highlighted)
            PNC.Conversation.Relationship.SetPreviewRequirement(
                "npc-preview",
                highlighted and "recruit" or "inspect"
            )
        end,
    },
})
choices.mouseX = 20
choices.mouseY = 40
T.truthy(choices:onMouseMove(),
    "live Core choice hover is consumed")
T.equal(panel.requirement, "recruit",
    "live Core choice hover reaches the relationship panel")
T.equal(capturedEvaluation.requirement.id, "recruit",
    "live Core choice hover rebuilds the recruit evaluation")

local graphPanel = RelationshipGraphPanel:new(0, 0, 200, 200)
graphPanel:setGraphOnly(true)
graphPanel:setEvaluation(capturedEvaluation)
local successRects = 0
local originalDrawColorRect = graphPanel.drawColorRect
graphPanel.drawColorRect = function(self, x, y, width, height, color)
    if color and color[2] == 0.05 and color[3] == 0.82 then
        successRects = successRects + 1
    end
    return originalDrawColorRect(self, x, y, width, height, color)
end
graphPanel:render()
T.truthy(successRects > 0,
    "graph-only UI renders the recruit acceptance region")

choices:onMouseMoveOutside()
T.equal(panel.requirement, "inspect",
    "live Core choice leave clears the recruit preview")

local cleared, clearReason = PNC.Conversation.Relationship
    .ClearPreviewRequirement("npc-preview")
T.truthy(cleared, "leaving recruit clears the preview")
T.equal(clearReason, nil, "clearing preview has no routing error")
T.equal(panel.requirement, "inspect", "panel returns to relationship inspection")
T.equal(capturedEvaluation.requirement.enabled, false,
    "inspection disables the acceptance region")
panel:prerender()
T.equal(panel.lastDrawText, "INSPECT",
    "relationship header returns to inspection state")

successRects = 0
graphPanel:setEvaluation(capturedEvaluation)
graphPanel:render()
T.equal(successRects, 0,
    "inspection UI removes the recruit acceptance region")

print("pnc_conversation_relationship_preview_ui_smoke: ok")

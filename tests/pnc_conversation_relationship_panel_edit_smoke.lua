local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common_client" },
})

local Panel = {}
Panel.__index = Panel

function Panel:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end

function Panel:new(x, y, width, height)
    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
        children = {},
        visible = true,
    }, self)
end

function Panel:initialise() end
function Panel:createChildren() end
function Panel:instantiate()
    if self.createChildren then self:createChildren() end
end
function Panel:addChild(child)
    child.parent = self
    self.children[#self.children + 1] = child
end
function Panel:getParent() return self.parent end
function Panel:getX() return self.x end
function Panel:getY() return self.y end
function Panel:getWidth() return self.width end
function Panel:getHeight() return self.height end
function Panel:setX(value) self.x = value end
function Panel:setY(value) self.y = value end
function Panel:setWidth(value) self.width = value end
function Panel:setHeight(value) self.height = value end
function Panel:setVisible(value) self.visible = value end
function Panel:setCapture(value) self.nativeCapture = value end
function Panel:setAnchorLeft() end
function Panel:setAnchorRight() end
function Panel:setAnchorTop() end
function Panel:setAnchorBottom() end
function Panel:drawRect() end

ISPanel = Panel

local Graph = Panel:derive("TestRelationshipGraphPanel")
function Graph:new(x, y, width, height)
    local o = Panel.new(self, x, y, width, height)
    o.originalMouseDownCount = 0
    return o
end
function Graph:onMouseDown()
    self.originalMouseDownCount = self.originalMouseDownCount + 1
    return true
end
function Graph:onMouseMove() return true end
function Graph:onMouseMoveOutside() return true end
function Graph:onMouseUp() return true end
function Graph:onMouseUpOutside() return true end
function Graph:setGraphOnly(value) self.graphOnly = value end
function Graph:setEvaluation(value) self.evaluation = value end

PsychopatzCore = {
    Conversation = {
        Text = { Resolve = function(_, fallback) return fallback end },
        Theme = {
            Resolve = function() return { r = 1, g = 1, b = 1 } end,
            Brighten = function(_, color) return color end,
        },
        Settings = { Get = function(_, fallback) return fallback end },
    },
}

PNC = {
    Conversation = {},
    RelationshipPresentation = {
        Summarize = function(summary) return summary or {} end,
        BuildEvaluation = function() return {} end,
    },
}

package.preload["ISUI/ISPanel"] = function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"] =
    function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationText"] =
    function() return true end
package.preload["PsychopatzCore/UI/Conversation/PsychopatzConversationTheme"] =
    function() return true end
package.preload["PNC/UI/Relationships/PNC_RelationshipGraphPanel"] =
    function()
        ISPNCRelationshipGraphPanel = Graph
        return Graph
    end

getMouseX = function() return 100 end
getMouseY = function() return 100 end

T.load("ProjectHoomans", "client",
    "PNC/Conversation/PNC_ConversationRelationshipPanel.lua")

local root = {
    getWidth = function() return 800 end,
    getHeight = function() return 600 end,
    savePartLayout = function() end,
}
local panel = ISPNCConversationRelationshipPanel:new(
    10, 50, 200, 223, { owner = root, relationship = {} }
)
panel:initialise()
panel:createChildren()
panel.parent = root

local graph = panel.graph
graph:onMouseDown(10, 10)
T.equal(graph.originalMouseDownCount, 1,
    "graph keeps its normal pointer handler outside edit mode")

panel:setEditMode(true)
T.equal(panel.resizeGrip.visible, true,
    "relationship resize grip becomes visible in edit mode")
T.equal(panel.children[#panel.children], panel.resizeGrip,
    "relationship resize grip is the topmost child")

-- The graph child covers the parent's bottom-right corner. Its local point
-- must be translated through the graph's (5, header + 4) offset first.
graph:onMouseDown(177, 177)
T.equal(graph.originalMouseDownCount, 1,
    "edit-mode graph click bypasses graph interaction")
T.equal(panel.capture, true, "graph click starts part capture")
T.equal(panel.resizing, true, "graph click reaches the resize corner")
T.equal(graph.nativeCapture, true, "graph keeps native capture for drag events")
graph:onMouseUp(177, 177)
T.equal(panel.capture, false, "graph mouse-up finishes part capture")
T.equal(graph.nativeCapture, false, "graph native capture is released")

panel:setWidth(240)
panel:onPartResize()
T.equal(panel.resizeGrip.x, 226, "resize grip follows relationship width")
T.equal(panel.resizeGrip.y, 249, "resize grip follows relationship height")

panel.resizeGrip:onMouseDown(1, 1)
T.equal(panel.resizing, true, "topmost relationship grip starts resizing")
panel.resizeGrip:onMouseUp(1, 1)
T.equal(panel.capture, false, "topmost relationship grip finishes resizing")

panel:setEditMode(false)
T.equal(panel.resizeGrip.visible, false,
    "relationship resize grip hides outside edit mode")

T.finish("pnc_conversation_relationship_panel_edit_smoke")

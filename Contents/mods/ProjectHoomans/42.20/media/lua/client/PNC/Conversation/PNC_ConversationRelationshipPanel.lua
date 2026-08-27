-- Conversation adapter for the shared relationship graph.  The graph itself
-- is also used by the relationship inspector; this only supplies the
-- draggable conversation-panel framing and current-player data.

require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
require "PNC/UI/Relationships/PNC_RelationshipGraphPanel"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

ISPNCConversationRelationshipPanel = PsychopatzConversationPart:derive(
    "ISPNCConversationRelationshipPanel"
)

local Conversation = PNC.Conversation
local Presentation = PNC.RelationshipPresentation

local function partCoordinate(part, panel, value, axis)
    local coordinate = tonumber(value) or 0
    local current = panel
    local getter
    local parent
    local offset
    while current and current ~= part do
        getter = axis == "x" and current.getX or current.getY
        offset = getter and getter(current) or current[axis]
        coordinate = coordinate + (tonumber(offset) or 0)
        parent = current.getParent and current:getParent() or current.parent
        current = parent
    end
    return coordinate
end

local function routeLayoutPointer(part, original, method, panel, x, y)
    if part and part.editMode then
        local result
        if method == "onMouseDown" then
            result = part[method](
                part,
                partCoordinate(part, panel, x, "x"),
                partCoordinate(part, panel, y, "y")
            )
            if result and panel.setCapture then
                pcall(panel.setCapture, panel, true)
            end
            part.layoutPointerPanel = panel
            return result
        end
        result = part[method](part, x, y)
        if method == "onMouseUp" or method == "onMouseUpOutside" then
            if panel.setCapture then pcall(panel.setCapture, panel, false) end
            if part.layoutPointerPanel == panel then
                part.layoutPointerPanel = nil
            end
        end
        return result
    end
    return original and original(panel, x, y) or false
end

local function installLayoutPointerBridge(part, panel)
    if not panel or panel.layoutPointerBridgeInstalled then return end
    panel.layoutPointerBridgeInstalled = true
    local originalMouseDown = panel.onMouseDown
    local originalMouseMove = panel.onMouseMove
    local originalMouseMoveOutside = panel.onMouseMoveOutside
    local originalMouseUp = panel.onMouseUp
    local originalMouseUpOutside = panel.onMouseUpOutside
    panel.onMouseDown = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseDown, "onMouseDown", element, x, y
        )
    end
    panel.onMouseMove = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseMove, "onMouseMove", element, x, y
        )
    end
    panel.onMouseMoveOutside = function(element, x, y)
        return routeLayoutPointer(
            part,
            originalMouseMoveOutside,
            "onMouseMoveOutside",
            element,
            x,
            y
        )
    end
    panel.onMouseUp = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseUp, "onMouseUp", element, x, y
        )
    end
    panel.onMouseUpOutside = function(element, x, y)
        return routeLayoutPointer(
            part,
            originalMouseUpOutside,
            "onMouseUpOutside",
            element,
            x,
            y
        )
    end
end

local ResizeGrip = ISPanel:derive("ISPNCConversationRelationshipResizeGrip")

function ResizeGrip:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0, g = 0, b = 0, a = 0 }
end

function ResizeGrip:prerender()
    if not self.owner or not self.owner.editMode then return end
    self:drawRect(0, 0, self.width, self.height,
        0.85, 0.30, 0.82, 1.0)
end

function ResizeGrip:onMouseDown(x, y)
    if not self.owner or not self.owner.editMode then return false end
    local accepted = self.owner:onMouseDown(self.x + x, self.y + y)
    if accepted and self.setCapture then
        pcall(self.setCapture, self, true)
    end
    if accepted then self.owner.layoutPointerPanel = self end
    return accepted
end

function ResizeGrip:onMouseMove(dx, dy)
    if not self.owner or not self.owner.editMode then return false end
    return self.owner:onMouseMove(dx, dy)
end

function ResizeGrip:onMouseMoveOutside(dx, dy)
    if not self.owner or not self.owner.editMode then return false end
    return self.owner:onMouseMoveOutside(dx, dy)
end

function ResizeGrip:onMouseUp(x, y)
    if not self.owner then return false end
    local accepted = self.owner:onMouseUp(self.x + x, self.y + y)
    if self.setCapture then pcall(self.setCapture, self, false) end
    if self.owner.layoutPointerPanel == self then
        self.owner.layoutPointerPanel = nil
    end
    return accepted
end

function ResizeGrip:onMouseUpOutside(x, y)
    if not self.owner then return false end
    local accepted = self.owner:onMouseUpOutside(self.x + x, self.y + y)
    if self.setCapture then pcall(self.setCapture, self, false) end
    if self.owner.layoutPointerPanel == self then
        self.owner.layoutPointerPanel = nil
    end
    return accepted
end

function ResizeGrip:new(x, y, width, height, owner)
    local o = ISPanel.new(self, x, y, width, height)
    o.owner = owner
    return o
end

function ISPNCConversationRelationshipPanel:createChildren()
    PsychopatzConversationPart.createChildren(self)
    self.graph = ISPNCRelationshipGraphPanel:new(
        5,
        self.headerHeight + 4,
        self.width - 10,
        self.height - self.headerHeight - 9
    )
    self.graph:initialise()
    self.graph:instantiate()
    self.graph:setGraphOnly(true)
    installLayoutPointerBridge(self, self.graph)
    self:addChild(self.graph)
    self.resizeGrip = ResizeGrip:new(
        self.width - 14, self.height - 14, 14, 14, self
    )
    self.resizeGrip:initialise()
    self.resizeGrip:instantiate()
    self.resizeGrip:setVisible(self.editMode == true)
    self:addChild(self.resizeGrip)
    self:setRelationship(self.relationship)
end

function ISPNCConversationRelationshipPanel:prerender()
    -- Keep the same frame, scanlines, and layout affordances as the other
    -- conversation windows. Graph-only applies to the graph's inspector
    -- footer, not to this conversation-window presentation.
    PsychopatzConversationPart.prerender(self)
end

function ISPNCConversationRelationshipPanel:setRelationship(summary)
    self.relationship = Presentation.Summarize(
        summary,
        type(summary) == "table" and summary.exists == true
    )
    if self.graph then
        self.graph:setEvaluation(
            Presentation.BuildEvaluation(
                self.relationship,
                self.requirement or "inspect",
                self.requirementContext
            )
        )
    end
end

function ISPNCConversationRelationshipPanel:syncResizeGrip()
    if not self.resizeGrip then return end
    self.resizeGrip:setX(math.max(0, self.width - 14))
    self.resizeGrip:setY(math.max(0, self.height - 14))
end

function ISPNCConversationRelationshipPanel:setEditMode(enabled)
    if not enabled and self.layoutPointerPanel
        and self.layoutPointerPanel.setCapture
    then
        pcall(self.layoutPointerPanel.setCapture,
            self.layoutPointerPanel, false)
        self.layoutPointerPanel = nil
    end
    PsychopatzConversationPart.setEditMode(self, enabled)
    if self.resizeGrip then
        self.resizeGrip:setVisible(enabled == true)
    end
end

function ISPNCConversationRelationshipPanel:setRequirement(requirement, context)
    self.requirement = requirement or "inspect"
    self.requirementContext = type(context) == "table" and context or {}
    if self.graph then
        self.graph:setEvaluation(
            Presentation.BuildEvaluation(
                self.relationship or {},
                self.requirement,
                self.requirementContext
            )
        )
    end
end

function ISPNCConversationRelationshipPanel:onPartResize()
    local desiredHeight = self.width + (self.headerHeight or 24) - 1
    local rootHeight = self.parent and self.parent:getHeight() or nil
    if rootHeight then
        desiredHeight = math.min(desiredHeight, rootHeight - self:getY())
    end
    if desiredHeight > 0 and self.height ~= desiredHeight then
        self:setHeight(desiredHeight)
    end
    if self.graph then
        self.graph:setX(5)
        self.graph:setY(self.headerHeight + 4)
        self.graph:setWidth(math.max(120, self.width - 10))
        self.graph:setHeight(math.max(
            150,
            self.height - self.headerHeight - 9
        ))
    end
    self:syncResizeGrip()
end

function ISPNCConversationRelationshipPanel:new(x, y, width, height, options)
    options = options or {}
    options.partID = "relationship"
    options.minimumWidth = options.minimumWidth or 200
    options.minimumHeight = options.minimumHeight or 200
    options.title = options.title or {
        key = "panel.current_relation",
        domain = "pnc.system.shared.categories",
    }
    local object = PsychopatzConversationPart.new(
        self,
        x,
        y,
        width,
        width + 23,
        options
    )
    object.relationship = options.relationship
    object.requirement = options.requirement or "inspect"
    object.requirementContext = options.requirementContext or {}
    return object
end

function Conversation.CreateRelationshipPanel(bounds, options)
    options = options or {}
    local definition = options.definition or {}
    return ISPNCConversationRelationshipPanel:new(
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height,
        {
            owner = options.owner,
            relationship = definition.relationship,
            title = definition.title,
            editLabel = definition.editLabel,
        }
    )
end

return ISPNCConversationRelationshipPanel

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
    local graph = self.graph
    local originalMouseDown = graph.onMouseDown
    local originalMouseMove = graph.onMouseMove
    local originalMouseMoveOutside = graph.onMouseMoveOutside
    local originalMouseUp = graph.onMouseUp
    local originalMouseUpOutside = graph.onMouseUpOutside
    graph.onMouseDown = function(panel, x, y)
        if self.editMode then return self:onMouseDown(x, y) end
        return originalMouseDown and originalMouseDown(panel, x, y) or false
    end
    graph.onMouseMove = function(panel, x, y)
        if self.editMode then return self:onMouseMove(x, y) end
        return originalMouseMove and originalMouseMove(panel, x, y) or false
    end
    graph.onMouseMoveOutside = function(panel, x, y)
        if self.editMode then return self:onMouseMoveOutside(x, y) end
        return originalMouseMoveOutside
            and originalMouseMoveOutside(panel, x, y) or false
    end
    graph.onMouseUp = function(panel, x, y)
        if self.editMode then return self:onMouseUp(x, y) end
        return originalMouseUp and originalMouseUp(panel, x, y) or false
    end
    graph.onMouseUpOutside = function(panel, x, y)
        if self.editMode then return self:onMouseUpOutside(x, y) end
        return originalMouseUpOutside
            and originalMouseUpOutside(panel, x, y) or false
    end
    self:addChild(self.graph)
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
            Presentation.BuildEvaluation(self.relationship, "inspect")
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

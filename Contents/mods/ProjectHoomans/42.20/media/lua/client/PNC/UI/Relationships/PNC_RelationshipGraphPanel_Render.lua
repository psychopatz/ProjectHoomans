local Panel = PNC.RelationshipGraphPanel
local Internal = Panel.Internal
local Graph = PNC.RelationshipGraph
local COLORS = Internal.Colors
local drawGraphSurface = Internal.DrawGraphSurface
local drawGraphSummary = Internal.DrawGraphSummary

function ISPNCRelationshipGraphPanel:render()
    ISPanel.render(self)
    local contentOpacity = self:getContentOpacity()
    local evaluation = self.evaluation or Graph.Evaluate(
        0,
        0,
        "inspect"
    )
    local graphOnly = self.graphOnly == true
    local top = graphOnly and 0 or 28
    local graphSize = graphOnly
        and math.max(2, math.min(self.width, self.height))
        or math.max(120, math.min(self.width - 24, self.height - 154))
    local graphX = math.floor((self.width - graphSize) / 2)
    local graphY = top
    local half = graphSize / 2
    self:drawColorRect(
        0, 0, self.width, self.height, COLORS.background, "content"
    )
    if not graphOnly then
        self:drawTextCentre(
            tostring(evaluation.requirement.label),
            self.width / 2,
            6,
            0.90,
            0.93,
            0.95,
            contentOpacity,
            UIFont.Small
        )
    end
    local markerX, markerY = drawGraphSurface(
        self, graphX, graphY, graphSize, half, evaluation, contentOpacity
    )
    drawGraphSummary(
        self, graphY, graphSize, evaluation, contentOpacity, graphOnly
    )
    -- Conversation panels use graphOnly to save space, but the hover
    -- explanation is still the only direct way to inspect why a point is in
    -- the green acceptance region. Keep it available in that presentation.
    self:drawHover(
        graphX,
        graphY,
        graphSize,
        markerX,
        markerY,
        evaluation
    )
end

function ISPNCRelationshipGraphPanel:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.evaluation = Graph.Evaluate(0, 0, "inspect")
    object.graphOnly = false
    object.opacity = 1
    object.contentOpacity = 1
    return object
end


return Panel

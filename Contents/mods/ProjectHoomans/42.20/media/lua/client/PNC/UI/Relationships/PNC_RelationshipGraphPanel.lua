-- Reusable approval/respect map. Conversation UIs can supply any normalized
-- requirement plus contextual modifiers without duplicating graph logic.

require "ISUI/ISPanel"

PNC = PNC or {}

ISPNCRelationshipGraphPanel =
    ISPanel:derive("ISPNCRelationshipGraphPanel")
PNC.RelationshipGraphPanel = ISPNCRelationshipGraphPanel

local Graph = PNC.RelationshipGraph

local COLORS = {
    background = { 0.96, 0.055, 0.055, 0.055 },
    pity = { 0.90, 0.42, 0.22, 0.25 },
    admire = { 0.90, 0.16, 0.32, 0.20 },
    despise = { 0.90, 0.12, 0.31, 0.34 },
    fear = { 0.90, 0.16, 0.26, 0.32 },
    success = { 0.56, 0.05, 0.82, 0.20 },
    grid = { 0.72, 0.62, 0.68, 0.72 },
    text = { 1, 0.88, 0.91, 0.94 },
    muted = { 1, 0.62, 0.68, 0.73 },
    border = { 0.95, 0.34, 0.76, 0.48 },
}

local function signed(value)
    return string.format("%+.1f", tonumber(value) or 0)
end

local function capitalize(value)
    value = tostring(value or "indifferent")
    return string.upper(string.sub(value, 1, 1))
        .. string.sub(value, 2)
end

function ISPNCRelationshipGraphPanel:initialise()
    ISPanel.initialise(self)
    self.background = false
end

function ISPNCRelationshipGraphPanel:setView(
    approval,
    respect,
    requirement,
    context
)
    self.evaluation = Graph.Evaluate(
        approval,
        respect,
        requirement,
        context
    )
end

function ISPNCRelationshipGraphPanel:getEvaluation()
    return self.evaluation
end

function ISPNCRelationshipGraphPanel:setEvaluation(evaluation)
    if type(evaluation) == "table" then
        self.evaluation = evaluation
    end
end

function ISPNCRelationshipGraphPanel:drawColorRect(
    x,
    y,
    width,
    height,
    color
)
    self:drawRect(
        x,
        y,
        math.max(0, width),
        math.max(0, height),
        color[1],
        color[2],
        color[3],
        color[4]
    )
end

function ISPNCRelationshipGraphPanel:drawSuccessRegion(
    x,
    y,
    size,
    evaluation
)
    local requirement = evaluation.requirement
    if not requirement or requirement.enabled == false then return end
    local strips = math.max(24, math.floor(size / 6))
    local stripWidth = size / strips
    local approvalWeight = requirement.approvalWeight
    for index = 0, strips - 1 do
        local normalizedX = (index + 0.5) / strips
        local respect = -100 + normalizedX * 200
        local boundary = Graph.BoundaryApprovalAtRespect(
            respect,
            requirement,
            evaluation.contextBonus
        )
        local drawY
        local drawHeight
        if boundary then
            boundary = math.max(-100, math.min(100, boundary))
            local boundaryY = y
                + ((100 - boundary) / 200) * size
            if approvalWeight > 0 then
                drawY = y
                drawHeight = boundaryY - y
            else
                drawY = boundaryY
                drawHeight = y + size - boundaryY
            end
        else
            local probe = Graph.Evaluate(
                0,
                respect,
                requirement,
                { bonus = evaluation.contextBonus }
            )
            if probe.insideSuccessRegion then
                drawY = y
                drawHeight = size
            end
        end
        if drawY and drawHeight and drawHeight > 0 then
            self:drawColorRect(
                x + index * stripWidth,
                drawY,
                stripWidth + 1,
                drawHeight,
                COLORS.success
            )
        end
    end
end

function ISPNCRelationshipGraphPanel:drawDiamond(x, y)
    local rows = {
        { -1, 2 }, { -3, 6 }, { -5, 10 },
        { -3, 6 }, { -1, 2 },
    }
    for index, row in ipairs(rows) do
        self:drawRect(
            x + row[1],
            y - 3 + index,
            row[2],
            1,
            1,
            1,
            1,
            1
        )
    end
end

function ISPNCRelationshipGraphPanel:drawHover(
    graphX,
    graphY,
    graphSize,
    markerX,
    markerY,
    evaluation
)
    if not self:isMouseOver() then return end
    local mouseX = self:getMouseX()
    local mouseY = self:getMouseY()
    local lines
    if math.abs(mouseX - markerX) <= 10
        and math.abs(mouseY - markerY) <= 10
    then
        lines = {
            "Current relationship",
            "Approval: " .. signed(evaluation.approval),
            "Respect: " .. signed(evaluation.respect),
            "Attitude: " .. capitalize(evaluation.attitude),
        }
    elseif evaluation.requirement.enabled
        and mouseX >= graphX
        and mouseX <= graphX + graphSize
        and mouseY >= graphY
        and mouseY <= graphY + graphSize
    then
        local respect = -100
            + ((mouseX - graphX) / graphSize) * 200
        local approval = 100
            - ((mouseY - graphY) / graphSize) * 200
        local hovered = Graph.Evaluate(
            approval,
            respect,
            evaluation.requirement,
            { bonus = evaluation.contextBonus }
        )
        if hovered.insideSuccessRegion then
            lines = {
                "Acceptance region",
                "This action meets its normal threshold here.",
                "Context may still affect authoritative resolution.",
            }
        end
    end
    if not lines then return end
    local width = 300
    local height = 12 + #lines * 18
    local x = math.min(
        self.width - width - 6,
        math.max(6, mouseX + 14)
    )
    local y = math.min(
        self.height - height - 6,
        math.max(6, mouseY + 14)
    )
    self:drawRect(x, y, width, height, 0.96, 0.03, 0.03, 0.03)
    self:drawRectBorder(x, y, width, height, 0.9, 0.4, 0.8, 0.55)
    for index, line in ipairs(lines) do
        self:drawText(
            line,
            x + 8,
            y + 5 + (index - 1) * 18,
            0.94,
            0.96,
            0.97,
            1,
            UIFont.Small
        )
    end
end

function ISPNCRelationshipGraphPanel:render()
    ISPanel.render(self)
    local evaluation = self.evaluation or Graph.Evaluate(
        0,
        0,
        "inspect"
    )
    local top = 28
    local graphSize = math.max(
        120,
        math.min(self.width - 24, self.height - 154)
    )
    local graphX = math.floor((self.width - graphSize) / 2)
    local graphY = top
    local half = graphSize / 2
    self:drawColorRect(
        0, 0, self.width, self.height, COLORS.background
    )
    self:drawTextCentre(
        tostring(evaluation.requirement.label),
        self.width / 2,
        6,
        0.90,
        0.93,
        0.95,
        1,
        UIFont.Small
    )
    self:drawColorRect(graphX, graphY, half, half, COLORS.pity)
    self:drawColorRect(
        graphX + half, graphY, half, half, COLORS.admire
    )
    self:drawColorRect(
        graphX, graphY + half, half, half, COLORS.despise
    )
    self:drawColorRect(
        graphX + half,
        graphY + half,
        half,
        half,
        COLORS.fear
    )
    self:drawSuccessRegion(
        graphX,
        graphY,
        graphSize,
        evaluation
    )
    self:drawRect(
        graphX,
        graphY + half,
        graphSize,
        1,
        COLORS.grid[1],
        COLORS.grid[2],
        COLORS.grid[3],
        COLORS.grid[4]
    )
    self:drawRect(
        graphX + half,
        graphY,
        1,
        graphSize,
        COLORS.grid[1],
        COLORS.grid[2],
        COLORS.grid[3],
        COLORS.grid[4]
    )
    self:drawRectBorder(
        graphX,
        graphY,
        graphSize,
        graphSize,
        COLORS.border[1],
        COLORS.border[2],
        COLORS.border[3],
        COLORS.border[4]
    )
    local labels = {
        { "PITY", graphX + half * 0.5, graphY + 9 },
        { "ADMIRE", graphX + half * 1.5, graphY + 9 },
        { "DESPISE", graphX + half * 0.5, graphY + graphSize - 22 },
        { "FEAR", graphX + half * 1.5, graphY + graphSize - 22 },
    }
    for _, label in ipairs(labels) do
        self:drawTextCentre(
            label[1],
            label[2],
            label[3],
            0.88,
            0.91,
            0.93,
            0.92,
            UIFont.Small
        )
    end
    self:drawTextCentre(
        "RESPECT  -100                                      +100",
        self.width / 2,
        graphY + graphSize + 7,
        0.62,
        0.68,
        0.73,
        1,
        UIFont.Small
    )
    local markerX, markerY = Graph.RelationshipToScreen(
        evaluation.approval,
        evaluation.respect,
        graphX,
        graphY,
        graphSize,
        graphSize
    )
    self:drawDiamond(markerX, markerY)
    local summaryY = graphY + graphSize + 29
    self:drawText(
        "Attitude: " .. capitalize(evaluation.attitude)
            .. "   Approval " .. signed(evaluation.approval)
            .. "   Respect " .. signed(evaluation.respect),
        10,
        summaryY,
        0.90,
        0.93,
        0.95,
        1,
        UIFont.Small
    )
    local resultText = evaluation.requirement.enabled
        and (
            "Score " .. signed(evaluation.finalScore)
            .. " / threshold "
            .. signed(evaluation.threshold)
            .. " / inside green: "
            .. tostring(evaluation.insideSuccessRegion)
        ) or "Green region disabled for relationship-only inspection"
    self:drawText(
        resultText,
        10,
        summaryY + 20,
        evaluation.insideSuccessRegion and 0.35 or 0.72,
        evaluation.insideSuccessRegion and 0.90 or 0.74,
        evaluation.insideSuccessRegion and 0.45 or 0.76,
        1,
        UIFont.Small
    )
    self:drawText(
        "Context " .. signed(evaluation.contextBonus)
            .. "   Base " .. signed(evaluation.baseScore),
        10,
        summaryY + 40,
        0.62,
        0.68,
        0.73,
        1,
        UIFont.Small
    )
    local modifierY = summaryY + 60
    for index = 1, math.min(2, #(evaluation.modifiers or {})) do
        local modifier = evaluation.modifiers[index]
        self:drawText(
            signed(modifier.value) .. " " .. modifier.label,
            10,
            modifierY + (index - 1) * 18,
            modifier.value >= 0 and 0.42 or 0.93,
            modifier.value >= 0 and 0.82 or 0.52,
            modifier.value >= 0 and 0.48 or 0.45,
            1,
            UIFont.Small
        )
    end
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
    return object
end

return ISPNCRelationshipGraphPanel

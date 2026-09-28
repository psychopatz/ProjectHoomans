-- Compact, server-aware timeline flow player for the Puppet Opera editor.

require "ISUI/ISPanel"

PNC = PNC or {}

ISPNCPuppetOperaTimelinePanel = ISPanel:derive(
    "ISPNCPuppetOperaTimelinePanel"
)

local Panel = ISPNCPuppetOperaTimelinePanel

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function labelText(value, maximum)
    value = tostring(value or "")
    if #value <= maximum then return value end
    return string.sub(value, 1, math.max(1, maximum - 3)) .. "..."
end

function Panel:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function Panel:createChildren()
    ISPanel.createChildren(self)
end

function Panel:setModel(model)
    self.model = model
    self:refresh()
end

function Panel:refresh()
    if not self.model then return end
    local snapshot = self.model.GetSnapshot
        and self.model.GetSnapshot() or nil
    self.snapshot = snapshot
    self.rows = self.model.GetTimelineRows
        and self.model.GetTimelineRows(snapshot) or {}
    self.durationMs = self.model.GetTimelineDuration
        and self.model.GetTimelineDuration() or 900
    self.phase = snapshot and snapshot.phase or "draft"
    self.error = snapshot
        and (snapshot.lastError or snapshot.stopReason)
        or nil
    if not snapshot and self.model.GetPreflight then
        local preflight = self.model.GetPreflight()
        if preflight and preflight.ready == false then
            self.error = preflight.reason
        end
    end
    self.playheadMs = nil
    if snapshot and snapshot.beatStartedAt and PNC.Core
        and PNC.Core.Now
    then
        self.playheadMs = clamp(
            PNC.Core.Now() - snapshot.beatStartedAt,
            0,
            self.durationMs
        )
    end
end

function Panel:timelineGeometry()
    local labelWidth = math.max(54, math.min(92, self:getWidth() * 0.34))
    local left = labelWidth + 8
    local right = math.max(left + 24, self:getWidth() - 8)
    local top = 43
    return left, right, top, math.max(1, right - left)
end

function Panel:nodeAt(x, y)
    local left, right, top, width = self:timelineGeometry()
    local rowHeight = 38
    local rowIndex = math.floor((y - top) / rowHeight) + 1
    local row = self.rows and self.rows[rowIndex]
    if not row then return nil end
    local laneTop = top + (rowIndex - 1) * rowHeight + 15
    local laneBottom = laneTop + 18
    if y < laneTop or y > laneBottom then return nil end
    for _, node in ipairs(row.nodes or {}) do
        local start = tonumber(node.startMs) or 0
        local duration = tonumber(node.durationMs) or 0
        local nodeLeft = left + start / self.durationMs * width
        local nodeWidth = math.max(8, duration / self.durationMs * width)
        if x >= nodeLeft and x <= nodeLeft + nodeWidth then
            return row, node
        end
    end
    return nil
end

function Panel:onMouseDown(x, y)
    local row, node = self:nodeAt(x, y)
    if not row or not node then return false end
    self.dragRow = row
    self.dragNode = node
    self.dragNodeID = node.id
    self.dragVertical = 0
    self:setCapture(true)
    return true
end

function Panel:onMouseMove(dx, dy)
    if not self.dragRow or not self.dragNode then return false end
    self.dragVertical = self.dragVertical + (tonumber(dy) or 0)
    if math.abs(self.dragVertical) >= 19
        and self.model.ReorderTimelineNode
    then
        local currentIndex
        for index, node in ipairs(self.dragRow.nodes or {}) do
            if node.id == self.dragNodeID then
                currentIndex = index
                break
            end
        end
        if currentIndex then
            local targetIndex = currentIndex
                + (self.dragVertical > 0 and 1 or -1)
            local reordered = self.model.ReorderTimelineNode(
                self.dragRow.id,
                self.dragNodeID,
                targetIndex
            )
            if reordered then
                self.dragVertical = 0
                self:refresh()
                for _, candidate in ipairs(self.rows or {}) do
                    if candidate.id == self.dragRow.id then
                        for _, current in ipairs(candidate.nodes or {}) do
                            if current.id == self.dragNodeID then
                                self.dragNode = current
                            end
                        end
                    end
                end
            end
        end
    end
    local left, right, top, width = self:timelineGeometry()
    local deltaMs = (tonumber(dx) or 0) / width * self.durationMs
    local nextStart = (tonumber(self.dragNode.startMs) or 0) + deltaMs
    local accepted = self.model
        and self.model.SetTimelineNodeOffset
        and self.model.SetTimelineNodeOffset(
            self.dragRow.id,
            self.dragNodeID,
            math.floor(nextStart + 0.5)
        )
    if accepted then
        self:refresh()
        for _, candidate in ipairs(self.rows or {}) do
            if candidate.id == self.dragRow.id then
                for _, current in ipairs(candidate.nodes or {}) do
                    if current.id == self.dragNodeID then
                        self.dragNode = current
                    end
                end
            end
        end
    end
    return true
end

function Panel:onMouseUp(x, y)
    if self.dragRow or self.dragNode then
        self:setCapture(false)
        self.dragRow = nil
        self.dragNode = nil
        self.dragNodeID = nil
        self.dragVertical = nil
        if self.ownerWindow then self.ownerWindow:refreshViews() end
        return true
    end
    return false
end

Panel.onMouseUpOutside = Panel.onMouseUp

function Panel:render()
    ISPanel.render(self)
    local width = self:getWidth()
    local height = self:getHeight()
    local left, right, top, timelineWidth = self:timelineGeometry()
    local duration = math.max(1, tonumber(self.durationMs) or 900)
    local phase = tostring(self.phase or "draft")
    local status = self.snapshot and phase
        or self.error and "blocked" or "editor"

    self:drawRect(0, 0, width, height, 0.92, 0.04, 0.06, 0.08)
    self:drawRect(0, 0, width, 28, 0.96, 0.07, 0.10, 0.13)
    self:drawText("ANIMATION FLOW", 8, 5,
        0.88, 0.94, 1.00, 1, UIFont.Small)
    self:drawTextRight(
        labelText(status .. "  " .. tostring(duration) .. "ms", 24),
        width - 8, 5, 0.55, 0.84, 0.66, 1, UIFont.Small
    )

    self:drawRect(left, top - 8, timelineWidth, 1,
        0.60, 0.34, 0.42, 0.48)
    for _, fraction in ipairs({ 0, 0.25, 0.5, 0.75, 1 }) do
        local x = left + timelineWidth * fraction
        self:drawRect(x, top - 10, 1, math.max(1, height - top),
            0.16, 0.36, 0.43, 0.50)
        self:drawText(
            tostring(math.floor(duration * fraction)) .. "ms",
            x + 2, top - 22, 0.48, 0.60, 0.66, 1, UIFont.Small
        )
    end

    for index, row in ipairs(self.rows or {}) do
        local y = top + (index - 1) * 38
        local laneY = y + 15
        if index % 2 == 0 then
            self:drawRect(0, y, width, 38, 0.10, 0.12, 0.16, 0.18)
        end
        self:drawText(labelText(row.label, 13), 6, y + 3,
            0.86, 0.90, 0.96, 1, UIFont.Small)
        self:drawText(labelText(row.flow, 13), 6, y + 21,
            row.owned and 0.54 or 0.62,
            row.owned and 1.00 or 0.72,
            row.owned and 0.66 or 0.80,
            1, UIFont.Small)
        self:drawRect(left, laneY, timelineWidth, 18,
            0.65, 0.08, 0.10, 0.13)
        for _, node in ipairs(row.nodes or {}) do
            local start = tonumber(node.startMs) or 0
            local nodeDuration = tonumber(node.durationMs) or 0
            local x = left + start / duration * timelineWidth
            local nodeWidth = math.max(8,
                nodeDuration / duration * timelineWidth)
            local active = node.active == true
            local isDelay = node.type == "delay"
            self:drawRect(x, laneY + 1, nodeWidth, 16,
                active and 0.90 or 0.82,
                isDelay and 0.40 or (active and 0.18 or 0.16),
                isDelay and 0.44 or (active and 0.74 or 0.38),
                isDelay and 0.52 or (active and 0.92 or 0.48))
            self:drawText(labelText(node.label, 12), x + 3, laneY + 3,
                0.92, 0.94, 0.98, 1, UIFont.Small)
        end
    end

    if self.playheadMs then
        local x = left + self.playheadMs / duration * timelineWidth
        self:drawRect(x, top - 10, 2, math.max(1, height - top),
            0.95, 0.98, 0.80, 0.24)
    end
    if self.error then
        local footerHeight = 20
        self:drawRect(0, height - footerHeight, width, footerHeight,
            0.86, 0.35, 0.10, 0.10)
        self:drawText(
            labelText("BLOCKED: " .. tostring(self.error), 34),
            6, height - footerHeight + 4,
            1.00, 0.72, 0.62, 1, UIFont.Small
        )
    end
    self:drawRectBorder(0, 0, width, height,
        0.70, 0.24, 0.34, 0.40)
end

return ISPNCPuppetOperaTimelinePanel

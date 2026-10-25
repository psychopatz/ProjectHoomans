-- Block list refresh and inspection detail projection.

local DebugUI = PNC.ConversationDebugUI
local Internal = DebugUI.Internal
local Model = Internal.Model
local UI = Internal.UI

function ISPNCConversationDebugWindow:addField(label, value, options)
    UI.AddKeyValue(self.details, label, Internal.textValue(value), options)
end

function ISPNCConversationDebugWindow:refreshBlocks()
    local old = Internal.selected(self.blocks)
    local query = self.search and self.search:getText() or ""
    self.blocks:clear()
    for _, item in ipairs(Model.List({ query = query }, self.context)) do
        self.blocks:addItem(item.id, item)
    end
    for index, entry in ipairs(self.blocks.items or {}) do
        if old and old.id == entry.item.id then self.blocks.selected = index end
    end
    if (self.blocks.selected or 0) < 1 and #self.blocks.items > 0 then
        self.blocks.selected = 1
    end
    self:refreshDetails()
end

function ISPNCConversationDebugWindow:refreshDetails(sandbox)
    self.details:clear()
    local item = Internal.selected(self.blocks)
    if not item then return end
    local inspection = Model.Inspect(item.id, self.context)
    local tr = Internal.tr
    local booleanText = Internal.booleanText
    local statusTone = Internal.statusTone
    self:addField(tr("detail.label.id"), item.id)
    self:addField(tr("detail.label.owner"), item.block.ownerModID)
    self:addField(tr("detail.label.category"), item.block.category)
    self:addField(tr("detail.label.source"), item.block.textSource.pathPattern)
    self:addField(tr("detail.label.registry"), booleanText(item.valid), {
        tone = statusTone(item.valid),
    })
    self:addField(tr("detail.label.translation"), booleanText(item.translationValid), {
        tone = statusTone(item.translationValid),
    })
    self:addField(tr("detail.label.fallback"), booleanText(item.translationFallback), {
        tone = item.translationFallback and "warning" or "text",
    })
    local eligible = inspection and inspection.eligible == true
    self:addField(tr("detail.label.eligibility"), booleanText(eligible), {
        tone = statusTone(eligible),
    })
    if inspection and inspection.reason then
        self:addField(tr("detail.label.reason"), inspection.reason, {
            tone = "warning",
        })
    end
    self:addField(tr("detail.label.seed"), inspection and inspection.seed)
    for _, errorValue in ipairs(item.errors or {}) do
        self:addField(tr("detail.label.error"), errorValue, { tone = "danger" })
    end
    for _, errorValue in ipairs(item.translationErrors or {}) do
        self:addField(tr("detail.label.text_error"), errorValue, { tone = "danger" })
    end
    local nodes = inspection and inspection.nodes or {}
    table.sort(nodes, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    for _, node in ipairs(nodes) do
        self:addField(tr("detail.label.node"), node.id, { tone = "accent" })
        self:addField(tr("detail.label.node_text"),
            node.textKey or table.concat(node.textKeys or {}, ","))
        for _, choice in ipairs(node.choices or {}) do
            local choiceEligible = choice.eligible == true
            self:addField(tr("detail.label.choice"), choice.id, {
                tone = "accent",
            })
            self:addField(tr("detail.label.choice_status"), booleanText(choiceEligible), {
                tone = statusTone(choiceEligible),
            })
            if choice.reason then
                self:addField(tr("detail.label.reason"), choice.reason, {
                    tone = "warning",
                })
            end
            for _, outcome in ipairs(choice.outcomes or {}) do
                local outcomeEligible = outcome.eligible == true
                self:addField(tr("detail.label.outcome"), outcome.id, {
                    tone = "accent",
                })
                self:addField(tr("detail.label.outcome_status"),
                    booleanText(outcomeEligible), {
                        tone = statusTone(outcomeEligible),
                    })
                self:addField(tr("detail.label.weight"), outcome.weight)
                self:addField(tr("detail.label.next"),
                    outcome.next or outcome.close and "close" or "none")
                self:addField(tr("detail.label.response"), outcome.responseKey)
                if outcome.reason then
                    self:addField(tr("detail.label.reason"), outcome.reason, {
                        tone = "warning",
                    })
                end
                for _, effect in ipairs(outcome.effects or {}) do
                    self:addField(tr("detail.label.effect"), effect.type, {
                        tone = "success",
                    })
                end
            end
        end
    end
    if sandbox then
        self:addField(tr("detail.label.sandbox_outcome"), sandbox.outcomeID, {
            tone = "success",
        })
        self:addField(tr("detail.label.sandbox_roll"), table.concat({
            Internal.textValue(sandbox.roll), Internal.textValue(sandbox.totalWeight),
        }, " / "))
        local axes = {}
        for key in pairs(sandbox.after.relationship or {}) do
            axes[#axes + 1] = key
        end
        table.sort(axes)
        for _, key in ipairs(axes) do
            self:addField(tr("detail.label.relationship"), key)
            self:addField(tr("detail.label.before_after"), table.concat({
                Internal.textValue(sandbox.before.relationship[key]),
                Internal.textValue(sandbox.after.relationship[key]),
            }, " -> "))
        end
        self:addField(tr("detail.label.persistence"), tr("status.no"), {
            tone = "success",
        })
        self:addField(tr("detail.label.networked"), tr("status.no"), {
            tone = "success",
        })
    end
end

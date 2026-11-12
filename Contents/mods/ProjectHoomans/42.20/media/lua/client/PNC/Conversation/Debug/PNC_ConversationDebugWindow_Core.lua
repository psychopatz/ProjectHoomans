-- Window construction and responsive layout for the conversation debugger.

local DebugUI = PNC.ConversationDebugUI
local Internal = DebugUI.Internal
local Model = Internal.Model
local UI = Internal.UI
local Layout = Internal.Layout

ISPNCConversationDebugWindow =
    PsychopatzWindow:derive("ISPNCConversationDebugWindow")

function ISPNCConversationDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCConversationDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.context = Model.DefaultContext()
    self.search = UI.CreateSearchEntry(self, {
        clearButton = true,
        width = 260,
        height = 26,
    })
    self.blocks = UI.CreateList(self, {
        itemHeight = 44,
        doDrawItem = Internal.drawBlock,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 24,
        labelX = 8,
        valueX = 178,
        valueRightPadding = 8,
    })
    self.controls = {}
    local actions = {
        { id = "refresh", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_Refresh") },
        { id = "audience", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_Audience", {
            audience = "neutral",
        }) },
        { id = "time", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_Hour", { hour = 12 }) },
        { id = "approval_down", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_ApprovalDown") },
        { id = "approval_up", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_ApprovalUp") },
        { id = "respect_down", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_RespectDown") },
        { id = "respect_up", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_RespectUp") },
        { id = "familiarity_down", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_FamiliarityDown") },
        { id = "familiarity_up", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_FamiliarityUp") },
        { id = "skill", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_Skill") },
        { id = "personality", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_Personality") },
        { id = "history", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_History", { uses = 0 }) },
        { id = "simulate", title = Internal.tr("UI_PsychopatzConversation_Debugger_Button_Simulate"), variant = "success" },
    }
    for _, action in ipairs(actions) do
        self.controls[#self.controls + 1] = UI.CreateButton(self, {
            id = action.id,
            title = action.title,
            target = self,
            onclick = ISPNCConversationDebugWindow.onAction,
            variant = action.variant or "quiet",
        })
    end
    self:requestResponsiveLayout(true)
    self:refreshBlocks()
end

function ISPNCConversationDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 34, bottom = 10 })
    Layout.SetBounds(self.search, rect.x, rect.y, math.min(340, rect.width), 26)
    local flow = Layout.Flow(self.controls, {
        x = rect.x, y = rect.y + 34, width = rect.width,
    }, { scale = self.uiScale, minWidth = 105 })
    local top = flow.bottom + 26
    local gap = 8
    local left = math.floor(rect.width * 0.43)
    Layout.SetBounds(self.blocks, rect.x, top, left,
        rect.height - (top - rect.y))
    Layout.SetBounds(self.details, rect.x + left + gap, top,
        rect.width - left - gap, rect.height - (top - rect.y))
end

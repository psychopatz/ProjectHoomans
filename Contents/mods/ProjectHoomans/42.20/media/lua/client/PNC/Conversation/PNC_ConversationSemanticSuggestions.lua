-- Player-facing semantic suggestions for the existing Core conversation view.
-- This part renders typed frames only; it never parses text or owns effects.
require "ISUI/ISPanel"
require "PsychopatzCore/UI/Components/PsychopatzUIControls"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Layout = PsychopatzCore.Conversation.Layout
local UI = PsychopatzCore.UI
local Text = PsychopatzCore.Conversation.Text

-- Keep the extension below the authored choices and above the text input.
-- Core's layout resolver already persists and applies extension-part bounds.
Layout.defaults.semanticSuggestions = Layout.defaults.semanticSuggestions or {
    x = 0.26,
    y = 0.745,
    w = 0.43,
    h = 0.16,
}

local MAX_BUTTONS = 5
local COLUMNS = 3
local GAP = 6
local BUTTON_HEIGHT = 32
local HEADER_GAP = 5

local Part = PsychopatzConversationPart:derive(
    "PNCConversationSemanticSuggestions"
)

local function titleFor(row)
    local display = row and row.display or {}
    return tostring(
        display.label
            or display.labelFallback
            or display.utterance
            or display.utteranceFallback
            or row and (row.id or row.action)
            or ""
    )
end

local function tooltipFor(row)
    local status = row and row.status or ""
    if status == "requires_destination"
        or status == "selected_requires_destination"
    then
        return Text.Resolve({
            key = "UI_PNC_Conversation_Suggestion_NeedsDestination_Tooltip",
            fallback = "Choose a destination first.",
        })
    end
    if status ~= "" and string.sub(status, 1, 12) == "unavailable_" then
        return Text.Resolve({
            key = "UI_PNC_Conversation_Suggestion_Unavailable_Tooltip",
            fallback = "Unavailable in the current situation.",
        })
    end
    return nil
end

local function interactive(part)
    return part.owner
        and type(part.owner.isConversationInteractive) == "function"
        and part.owner:isConversationInteractive() == true
end

function Part:onSuggestionPressed(row)
    if not row or row.enabled == false or not interactive(self) then
        return false, "suggestion_unavailable"
    end
    local frame = row.frame
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    if not input or type(input.SubmitSemanticFrame) ~= "function" then
        return false, "semantic_input_unavailable"
    end
    local accepted, reason = input.SubmitSemanticFrame(self.owner, frame)
    self.lastSubmitReason = reason
    return accepted, reason
end

function Part:refreshControls()
    for index = 1, #self.buttons do
        local entry = self.buttons[index]
        local row = entry.row
        local button = entry.button
        local enabled = row and row.enabled == true and interactive(self)
        button:setEnable(enabled)
        if button.setTooltip then
            button:setTooltip(tooltipFor(row))
        else
            button.tooltip = tooltipFor(row)
        end
    end
end

function Part:layoutButtons()
    local padding = 8
    local available = math.max(1, self.width - padding * 2)
    local width = math.floor((available - GAP * (COLUMNS - 1)) / COLUMNS)
    local y = (self.headerHeight or 24) + HEADER_GAP
    for index = 1, #self.buttons do
        local entry = self.buttons[index]
        local column = (index - 1) % COLUMNS
        local row = math.floor((index - 1) / COLUMNS)
        local button = entry.button
        button:setX(padding + column * (width + GAP))
        button:setY(y + row * (BUTTON_HEIGHT + GAP))
        button:setWidth(width)
        button:setHeight(BUTTON_HEIGHT)
    end
end

function Part:setSuggestions(projection)
    projection = type(projection) == "table" and projection or {}
    self.projection = projection
    local rows = {}
    local candidates = projection.candidates or {}
    local capabilities = projection.permittedCapabilities or {}
    local candidateLimit = #capabilities > 0
        and math.max(0, MAX_BUTTONS - #capabilities)
        or MAX_BUTTONS
    for index = 1, math.min(#candidates, candidateLimit) do
        rows[#rows + 1] = {
            id = candidates[index].id,
            frame = candidates[index].frame,
            display = candidates[index].display,
            status = "eligible",
            enabled = true,
            source = candidates[index].source,
        }
    end
    for index = 1, math.min(#capabilities, MAX_BUTTONS - #rows) do
        local capability = capabilities[index]
        rows[#rows + 1] = {
            id = capability.id,
            action = capability.action,
            frame = capability.frame,
            display = capability.display,
            status = capability.status,
            enabled = capability.status == "eligible"
                or capability.status == "selected_for_preflight",
            source = capability.source,
            eligibility = capability.eligibility,
        }
    end
    self.rows = rows
    for index = 1, #self.buttons do
        local entry = self.buttons[index]
        local row = rows[index]
        entry.row = row
        if row then
            entry.button:setTitle(titleFor(row))
            entry.button:setVisible(true)
        else
            entry.button:setTitle("")
            entry.button:setVisible(false)
        end
    end
    self:setVisible(#rows > 0)
    self:refreshControls()
    return rows
end

function Part:createChildren()
    PsychopatzConversationPart.createChildren(self)
    self.buttons = {}
    for index = 1, MAX_BUTTONS do
        local button = UI.CreateButton(self, {
            id = "semantic-suggestion-" .. tostring(index),
            title = "",
            target = self,
            onclick = function(target)
                local entry = target.buttons[index]
                return target:onSuggestionPressed(entry and entry.row)
            end,
            variant = "quiet",
        })
        self.buttons[index] = { button = button }
        button:setVisible(false)
    end
    self:layoutButtons()
    self:setSuggestions(self.projection or {})
end

function Part:prerender()
    PsychopatzConversationPart.prerender(self)
    self:refreshControls()
end

function Part:onPartResize()
    PsychopatzConversationPart.onPartResize(self)
    self:layoutButtons()
end

function Part:new(x, y, width, height, options)
    options = options or {}
    options.partID = "semanticSuggestions"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 76
    options.title = options.title or {
        key = "UI_PNC_Conversation_SemanticSuggestions_Title",
        fallback = "CONTEXTUAL SUGGESTIONS",
    }
    local object = PsychopatzConversationPart.new(
        self, x, y, width, height, options
    )
    object.rows = {}
    object.buttons = {}
    object.projection = nil
    return object
end

function Conversation.CreateSemanticSuggestionsPart(bounds, options)
    options = options or {}
    local definition = options.definition or {}
    return Part:new(
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height,
        {
            owner = options.owner,
            title = definition.title,
            editLabel = definition.editLabel,
        }
    )
end

return Part

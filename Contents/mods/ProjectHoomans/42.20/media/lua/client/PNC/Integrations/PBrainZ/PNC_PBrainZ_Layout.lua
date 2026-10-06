-- Layout registration for the full-conversation LLM input panel.
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"

local Layout = PsychopatzCore.Conversation.Layout

-- Hoomans owns the full-conversation input placement.  Core supplies a
-- generic fallback, but leaving that fallback in place would ignore the
-- user's saved choice-panel layout and put TYPE TO TALK at the screen edge.
local choices = Layout.GetNormalized("choices")
local inputHeight = 0.085
local inputY = (choices.y or 0.64) + (choices.h or 0.27) + 0.008
if inputY + inputHeight > 0.985 then
    inputY = 0.985 - inputHeight
end
Layout.defaults.llmInput = {
    x = choices.x or 0.26,
    y = inputY,
    w = choices.w or 0.43,
    h = inputHeight,
}

return Layout

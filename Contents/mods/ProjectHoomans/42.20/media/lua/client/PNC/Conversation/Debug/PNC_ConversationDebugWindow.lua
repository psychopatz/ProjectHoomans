-- Stable conversation debugger entry point.
-- Keep this path and ConversationDebugUI namespace compatible with callers.
require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"
require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"
require "PNC/Conversation/Debug/PNC_ConversationDebugModel"

PNC.ConversationDebugUI = PNC.ConversationDebugUI or {}
local DebugUI = PNC.ConversationDebugUI
local Internal = DebugUI.Internal or {}
DebugUI.Internal = Internal
Internal.Model = PNC.ConversationDebugModel
Internal.UI = PsychopatzCore.UI
Internal.Theme = Internal.UI.Theme
Internal.Layout = Internal.UI.Layout

require "PNC/Conversation/Debug/PNC_ConversationDebugWindow_Support"
require "PNC/Conversation/Debug/PNC_ConversationDebugWindow_Core"
require "PNC/Conversation/Debug/PNC_ConversationDebugWindow_Details"
require "PNC/Conversation/Debug/PNC_ConversationDebugWindow_Actions"
require "PNC/Conversation/Debug/PNC_ConversationDebugWindow_Lifecycle"

return DebugUI

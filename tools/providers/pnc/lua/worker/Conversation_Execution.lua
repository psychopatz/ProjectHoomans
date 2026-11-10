-- Execution exports for the semantic conversation façade.

local Execution = {}
local Turn = require "worker/Conversation_Turn"
local Click = require "worker/Conversation_Click"
local Preview = require "worker/Conversation_Preview"

Execution.turn = Turn.run
Execution.semanticClick = Click.run
Execution.preview = Preview.run

return Execution

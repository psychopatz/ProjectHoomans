-- Private state shared by the HoomansLLM integration spokes.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Internal = PNC.HoomansLLM.Internal
local State = Internal.State or {}
Internal.State = State

-- These values were local to the original entry file. Keep them in one
-- internal data module so every spoke observes the same limits and queues.
State.MAX_INPUT_LENGTH = State.MAX_INPUT_LENGTH or 4000
State.MAX_LOG_TEXT = State.MAX_LOG_TEXT or 900
State.PendingQueue = State.PendingQueue or {}
State.ActiveSpeech = State.ActiveSpeech or {}
State.serial = State.serial or 0

return State

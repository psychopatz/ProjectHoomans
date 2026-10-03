-- PNC NPC Voice Triggers composition root.
-- Client snapshot state, trigger playback, observation, and terminal events.

PNC = PNC or {}
PNC.NPCVoice = PNC.NPCVoice or {}
PNC.NPCVoice.Triggers = PNC.NPCVoice.Triggers or {}

require "PNC/Audio/PNC_NPCVoiceTriggers_Core"
require "PNC/Audio/PNC_NPCVoiceTriggers_Playback"
require "PNC/Audio/PNC_NPCVoiceTriggers_Observe"
require "PNC/Audio/PNC_NPCVoiceTriggers_Terminal"

return PNC.NPCVoice.Triggers

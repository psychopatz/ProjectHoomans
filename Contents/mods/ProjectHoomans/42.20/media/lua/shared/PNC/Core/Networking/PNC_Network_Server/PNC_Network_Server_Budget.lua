-- Stable payload-budget entry point. Estimation, chunking, and the global
-- server-send guard load in dependency order and preserve the original API.
PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Budget_Core"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Budget_Chunking"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Budget_Guard"

return PNC.Network.PayloadBudget

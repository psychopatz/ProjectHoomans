-- Client request composition hub.
--
-- Public PNC.Client request methods live in role-based spokes. This file is
-- intentionally limited to namespace setup and explicit load order so the
-- legacy entry path remains stable for Project Zomboid and existing callers.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

require "PNC/Networking/ClientRequests/PNC_ClientRequests_Internal"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Bootstrap"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_World"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Knowledge"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Identity"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_SemanticCognition"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Semantic"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Debug"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_DebugSocial"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_DebugServices"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Colony"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_ColonyActions"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_ColonyStorage"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Character"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_InitialStateTick"

return PNC.Client

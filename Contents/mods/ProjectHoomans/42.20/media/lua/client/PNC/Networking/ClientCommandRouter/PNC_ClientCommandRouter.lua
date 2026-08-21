-- Inbound command router hub. Providers load before domain registrations.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Registry"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Diagnostics"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Knowledge"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Exploration"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Colony"
require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_InteractionResults"

return PNC.Client

-- Stable entry point for the authoritative travel lifecycle.

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Service = PNC.Travel.Service or {}
PNC.Travel.Service.Internal = PNC.Travel.Service.Internal or {}

require "PNC/Core/Travel/PNC_Travel_Service/PNC_Travel_Service_Core"
require "PNC/Core/Travel/PNC_Travel_Service/PNC_Travel_Service_Control"
require "PNC/Core/Travel/PNC_Travel_Service/PNC_Travel_Service_Progression"
require "PNC/Core/Travel/PNC_Travel_Service/PNC_Travel_Service_Live"
require "PNC/Core/Travel/PNC_Travel_Service/PNC_Travel_Service_Projection"

return PNC.Travel.Service

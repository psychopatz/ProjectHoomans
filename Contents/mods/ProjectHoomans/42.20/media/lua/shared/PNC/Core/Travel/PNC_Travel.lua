-- Canonical shared Travel entry. Dependency order is contractual.
require "PNC/Core/Travel/PNC_Travel_Route"
require "PNC/Core/Travel/PNC_Travel_Providers"
require "PNC/Core/Travel/PNC_Travel_Arrivals"
require "PNC/Core/Travel/PNC_Travel_Model"
require "PNC/Core/Travel/PNC_Travel_Projection"
require "PNC/Core/Travel/PNC_Travel_Service"

return PNC.Travel

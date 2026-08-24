-- Stable mobile-group director entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}

require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Core"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Sites"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Members"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Generation"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Relocation"
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Pump"

return PNC.MobileGroupDirector

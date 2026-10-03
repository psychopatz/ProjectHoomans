require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"
require "PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"
require "PNC/UI/NPCMonitor/PNC_NPCTracking"
require "PNC/UI/SettlementManagement/PNC_SettlementManagement_ProvisionDiagnosticsModal"
require "ISUI/ISContextMenu"

PNC = PNC or {}
PNC.NPCMonitor = PNC.NPCMonitor or {}

-- Compatibility contracts: function ISPNCNPCMonitor:onEquipment(button)
-- and the "Back / bag" control remain implemented by the action provider.
require "PNC/UI/NPCMonitor/PNC_NPCMonitor_Core"
require "PNC/UI/NPCMonitor/PNC_NPCMonitor_Actions"
require "PNC/UI/NPCMonitor/PNC_NPCMonitor_Runtime"

return PNC.NPCMonitor

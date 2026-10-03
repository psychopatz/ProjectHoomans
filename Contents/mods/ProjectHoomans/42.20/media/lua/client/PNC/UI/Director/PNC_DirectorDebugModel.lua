-- Stable director debug model entry. Summary, group-detail, and final row
-- composition providers retain the original public model path.
require "PNC/UI/Director/PNC_DirectorDebugModel_Core"
require "PNC/UI/Director/PNC_DirectorDebugModel_Summary"
require "PNC/UI/Director/PNC_DirectorDebugModel_Groups"
require "PNC/UI/Director/PNC_DirectorDebugModel_Detail"

return PNC.DirectorDebugModel

-- Stable entry point for firearm state, ammunition, and reload actions.

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}
PNC.Firearms = PNC.Firearms or {}
PNC.Combat.Internal = PNC.Combat.Internal or {}

require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Descriptors"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Magazine"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_ReloadOps"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_State"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Actions"
require "PNC/Core/Combat/PNC_Combat_Firearms/PNC_Combat_Firearms_Debug"

return PNC.Firearms

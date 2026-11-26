-- Compatibility and load-order hub for Puppet Opera draft responsibilities.
--
-- Keep this existing model spoke path stable. The draft catalog, construction,
-- persistence, and validation contracts are loaded in explicit order while
-- continuing to attach the same public methods to the shared Model table.

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Drafts_Catalog"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Drafts_Creation"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Drafts_Persistence"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Drafts_Validation"

return Model

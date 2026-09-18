-- Compatibility and load-order hub for Puppet Opera draft responsibilities.
--
-- Keep this existing model spoke path stable. The draft catalog, construction,
-- persistence, and validation contracts are loaded in explicit order while
-- continuing to attach the same public methods to the shared Model table.

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
Model.Internal = Model.Internal or {}

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Drafts_Catalog"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Drafts_Creation"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Drafts_Persistence"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Drafts_Validation"

return Model

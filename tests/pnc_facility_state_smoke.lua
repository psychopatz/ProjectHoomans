local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

PNC = {}
local State = T.load("ProjectHoomans", "shared",
    "PNC/Core/Settlement/PNC_FacilityState.lua")

T.truthy(State.IsBuilt({}), "legacy facility without lifecycle is not built")
T.falsy(State.IsBuilt(nil), "missing facility is recognized as built")
T.truthy(State.IsBuilt({ constructionState = "" }),
    "empty lifecycle state is not treated as built")
T.truthy(State.IsBuilt({ constructionState = "BUILT" }),
    "built facility is not recognized")
T.falsy(State.IsBuilt({ constructionState = "PLANNED" }),
    "planned facility is recognized as built")
T.falsy(State.IsBuilt({ constructionState = "UNDER_CONSTRUCTION" }),
    "under-construction facility is recognized as built")
T.falsy(State.IsBuilt({ constructionState = "RECONSTRUCTING" }),
    "reconstructing facility is recognized as built")
T.equal(State.DisplayState({ cachedState = "OPERATIONAL" }), "OPERATIONAL",
    "legacy operational display state was lost")
T.equal(State.DisplayState({ constructionState = "PLANNED",
    cachedState = "OPERATIONAL" }), "PLANNED",
    "lifecycle state did not take display precedence")

T.finish("pnc_facility_state_smoke")

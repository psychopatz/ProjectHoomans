local T = require "tests/support/test"

local deathSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Health/PNC_Health_Death.lua"
)
local auditSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Audit.lua"
)
local corpseSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Corpses.lua"
)

T.contains(deathSource, "PNC.BodyLifecycle.CreateVanillaCorpse",
    "death uses the canonical corpse conversion entry point")
T.falsy(deathSource:find("CreateInertCorpse", 1, true),
    "death has no removed corpse compatibility alias")
T.contains(auditSource, "Lifecycle.CreateVanillaCorpse",
    "body audit uses the canonical corpse conversion entry point")
T.falsy(auditSource:find("CreateInertCorpse", 1, true),
    "body audit has no removed corpse compatibility alias")
T.contains(corpseSource, "IsoDeadBody.new",
    "corpse conversion uses the Build 42 engine constructor")
T.falsy(corpseSource:find("becomeCorpseSilently", 1, true),
    "corpse conversion does not call an unavailable engine method")
T.contains(corpseSource, "Internal.announceCorpse(corpse)",
    "corpse conversion explicitly owns multiplayer corpse replication")
T.falsy(corpseSource:find("CreateInertCorpse", 1, true),
    "body lifecycle exposes no removed compatibility alias")

T.finish("pnc_corpse_lifecycle_boundary_smoke")

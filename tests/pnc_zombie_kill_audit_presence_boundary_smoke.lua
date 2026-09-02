local T = require "tests/support/test"

local composition = T.read("ProjectHoomans", "client",
    "PNC/Composition/PNC_ClientComposition.lua")
local audit = T.read("ProjectHoomans", "client",
    "PNC/PNC_ClientZombieKillAudit.lua")
local serverHooks = T.read("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter.lua")

T.contains(composition, 'require "PNC/PNC_ClientZombieKillAudit"',
    "client composition does not load zombie-kill audit")
T.contains(audit, "Detector.RegisterConsumer",
    "client audit does not activate the core detector")
T.contains(audit, "onClientHit = onClientHit",
    "client audit does not observe weapon-hit attribution")
T.contains(audit, "onClientKill = onClientKill",
    "client audit does not observe zombie deaths")
T.contains(audit, "nativeZombieKills",
    "client audit does not report the native kill counter")
T.contains(serverHooks, "function H.OnWeaponHitCharacter",
    "server combat callback is not available to the core detector")
T.contains(serverHooks, 'phase=relationship_dispatch',
    "server relationship dispatch result is not auditable")

T.finish("pnc_zombie_kill_audit_presence_boundary_smoke")

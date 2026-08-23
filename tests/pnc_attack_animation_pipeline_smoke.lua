local T = require "tests/support/test"

local ANIMATION =
    T.path("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_Animation.lua")
local ANIMATION_PROVIDERS =
    T.path("ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_Animation/")
local CLIENT_ATTACK =
    T.path("ProjectHoomans", "client", "PNC/PresenceSync/")
    .. "PresenceVisuals/PNC_ClientPresenceVisuals_Attack.lua"
local CLIENT_MOTION =
    T.path("ProjectHoomans", "client", "PNC/PresenceSync/")
    .. "PresenceVisuals/PNC_ClientPresenceVisuals_ActionMotion.lua"
local PATH_MOTION =
    T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")
    .. "PNC_PathService/PNC_PathService_Motion.lua"
local PATH_MOTION_PUMP =
    T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")
    .. "PNC_PathService/Motion/PNC_PathService_MotionPump.lua"
local ATTACK_XML =
    T.path("ProjectHoomans", "common", "AnimSets/zombie/bumped/PNC_Attack1H1.xml")
local ATTACK_VARIANT_XML =
    T.path("ProjectHoomans", "common", "AnimSets/zombie/bumped/PNC_Attack1H2.xml")
local SHOVE_VARIANT_XML =
    T.path("ProjectHoomans", "common", "AnimSets/zombie/bumped/PNC_ShoveBat.xml")

local bumpPlayback = T.read(
    ANIMATION_PROVIDERS .. "PNC_Animation_BumpPlayback.lua"
)
local animation = T.read(ANIMATION)
    .. T.read(ANIMATION_PROVIDERS .. "PNC_Animation_BumpState.lua")
    .. bumpPlayback
    .. T.read(ANIMATION_PROVIDERS .. "PNC_Animation_BumpLifecycle.lua")
local clientSync = T.read(CLIENT_ATTACK) .. T.read(CLIENT_MOTION)
local pathMotion = T.read(PATH_MOTION) .. T.read(PATH_MOTION_PUMP)
local attackXML = T.read(ATTACK_XML)
local attackVariantXML = T.read(ATTACK_VARIANT_XML)
local shoveVariantXML = T.read(SHOVE_VARIANT_XML)
local combat = T.read(
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/")
        .. "PNC_Combat.lua"
)
local melee = T.read(
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/")
        .. "PNC_Combat_Melee.lua"
)
local attackActions = T.read(
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/AttackExecution/")
        .. "PNC_AttackExecution_Pump.lua"
)
local unarmed = T.read(
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/")
        .. "PNC_Combat_Unarmed.lua"
)
local firearms = T.read(
    T.path("ProjectHoomans", "shared", "PNC/Core/Combat/")
        .. "PNC_Combat_Firearms.lua"
)
T.contains(
    bumpPlayback,
    "function Animation.PlayBump",
    "bump playback provider"
)
local playBump = bumpPlayback

T.contains(
    playBump,
    'zombie:setVariable("BumpDone", false)',
    "known-good bump completion mirror"
)
T.contains(
    playBump,
    'zombie:setVariable("BumpFall", false)',
    "known-good bump fall mirror"
)
T.contains(
    playBump,
    'zombie:setVariable("BumpFallType", "")',
    "known-good bump fall type"
)
T.contains(
    playBump,
    'zombie:setVariable("PNCAttackVariationX", "1.0")',
    "private melee X blend scalar"
)
T.contains(
    playBump,
    'zombie:setVariable("PNCAttackVariationY", "0.0")',
    "private melee Y blend scalar"
)
T.contains(
    playBump,
    'zombie:setVariable("BumpAnimFinished", false)',
    "stale bump completion latch reset"
)
T.truthy(
    not string.find(
        playBump,
        'zombie.reportEvent',
        1,
        true
    ),
    "manual reportEvent must not replace the setter-driven transition"
)
T.truthy(
    not string.find(
        playBump,
        'zombie.changeState',
        1,
        true
    ),
    "PlayBump must not force the legacy state machine"
)
T.contains(
    playBump,
    "zombie:setBumpType(resolvedBumpType)",
    "setter-driven action-group handoff"
)
T.contains(
    playBump,
    "applyBumpLeaseBodyMode(zombie)",
    "bumped action-context lease"
)
T.contains(
    clientSync,
    "Animation.PlayBump(zombie, recordView, anim)",
    "client attack presentation uses shared trigger"
)
T.truthy(
    not string.find(
        clientSync,
        "attack_anim_retry",
        1,
        true
    ),
    "client attack presentation must not restart Bandits-style bumps"
)
T.contains(
    clientSync,
    "observeClientAttackBump(zombie, modData)",
    "client records the live action graph without replaying it"
)
T.contains(
    attackXML,
    "<m_StringValue>PNC_Attack1H1</m_StringValue>",
    "PNC-namespaced Bandits attack node bump type"
)
T.contains(
    attackXML,
    "<m_Scalar>PNCAttackVariationX</m_Scalar>",
    "PNC-private attack blend scalar"
)
T.contains(
    attackXML,
    "<m_Scalar2>PNCAttackVariationY</m_Scalar2>",
    "PNC-private secondary attack blend scalar"
)
T.truthy(
    not string.find(attackXML, "Bandit", 1, true),
    "Bandits identifier leaked into canonical PNC combat XML"
)
T.contains(
    attackXML,
    "<m_ParameterValue>BumpAnimFinished=true</m_ParameterValue>",
    "attack node completion"
)
T.contains(
    attackVariantXML,
    "<m_AnimName>Bob_Attack1Hand01_HitB</m_AnimName>",
    "Bandits-compatible second one-handed melee animation"
)
T.contains(
    shoveVariantXML,
    "<m_Name>PNCPrimaryType</m_Name>",
    "Bandits shove weapon selector renamed for PNC"
)
T.truthy(
    not string.find(shoveVariantXML, "BanditPrimaryType", 1, true),
    "Bandits-only shove selector leaked into PNC XML"
)
T.contains(
    combat,
    'onehanded = { "PNC_Attack1H1", "PNC_Attack1H2" }',
    "namespaced network melee vocabulary"
)
T.contains(
    animation,
    "PNC_Attack1H1 = true",
    "namespaced combat bump ownership"
)
T.truthy(
    not string.find(combat, "Animation.PlayBump", 1, true),
    "server animation selector still renders attack bumps"
)
T.truthy(
    not string.find(melee, "Animation.PlayBump", 1, true),
    "server melee commit still renders attack bumps"
)
T.truthy(
    not string.find(attackActions, "Animation.FinishBump", 1, true),
    "server attack completion still owns the client bump"
)
T.truthy(
    not string.find(unarmed, "Animation.PlayBump", 1, true),
    "server unarmed combat still renders attack bumps"
)
T.truthy(
    not string.find(firearms, "Animation.PlayBump", 1, true),
    "server reload action still renders attack bumps"
)
T.contains(
    pathMotion,
    "holdAttackLease(record, zombie, lane, now)",
    "path service attack animation lease"
)
local pathPump = T.read(PATH_MOTION_PUMP)
local actionLockAt = T.truthy(string.find(
    pathPump,
    "holdAttackLease(record, zombie, lane, now)",
    1,
    true
))
local consumeIntentAt = T.truthy(string.find(
    pathPump,
    "Internal.consumeMoveIntent(record, lane, zombie)",
    1,
    true
))
T.truthy(
    actionLockAt < consumeIntentAt,
    "movement intent mutates locomotion before the body action lease"
)
T.finish("pnc_attack_animation_pipeline_smoke")

T.finish("pnc_attack_animation_pipeline_smoke")

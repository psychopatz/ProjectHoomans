local ANIMATION =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Visuals/PNC_Animation.lua"
local CLIENT_SYNC =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PresenceSync/PNC_ClientPresenceVisuals.lua"
local PATH_MOTION =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/"
    .. "PNC_PathService/PNC_PathService_Motion.lua"
local ATTACK_XML =
    "Contents/mods/ProjectHoomans/common/media/AnimSets/zombie/bumped/PNC_Anim_Attack1H1.xml"
local ATTACK_VARIANT_XML =
    "Contents/mods/ProjectHoomans/common/media/AnimSets/zombie/bumped/PNC_Anim_Attack1H2.xml"

local function readAll(path)
    local file = assert(io.open(path, "rb"))
    local value = file:read("*a")
    file:close()
    return value
end

local function assertContains(value, needle, label)
    if not string.find(value, needle, 1, true) then
        error((label or "assertContains") .. ": missing " .. needle)
    end
end

local animation = readAll(ANIMATION)
local clientSync = readAll(CLIENT_SYNC)
local pathMotion = readAll(PATH_MOTION)
local attackXML = readAll(ATTACK_XML)
local attackVariantXML = readAll(ATTACK_VARIANT_XML)
local clientAttackPresentation = assert(string.match(
    clientSync,
    "    attackKey =.-\n    specialKey ="
))
local combat = readAll(
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/"
        .. "PNC_Combat.lua"
)
local melee = readAll(
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/"
        .. "PNC_Combat_Melee.lua"
)
local attackActions = readAll(
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/"
        .. "PNC_Combat_AttackActions.lua"
)
local unarmed = readAll(
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/"
        .. "PNC_Combat_Unarmed.lua"
)
local firearms = readAll(
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Combat/"
        .. "PNC_Combat_Firearms.lua"
)
local playBump = assert(string.match(
    animation,
    "function Animation%.PlayBump.-\nend\n\nfunction Animation%.FinishBump"
))

assertContains(
    playBump,
    'zombie:setVariable("BumpDone", false)',
    "known-good bump completion mirror"
)
assertContains(
    playBump,
    'zombie:setVariable("BumpFall", false)',
    "known-good bump fall mirror"
)
assertContains(
    playBump,
    'zombie:setVariable("BumpFallType", "")',
    "known-good bump fall type"
)
assert(
    not string.find(
        playBump,
        'zombie.reportEvent',
        1,
        true
    ),
    "manual reportEvent must not replace the setter-driven transition"
)
assert(
    not string.find(
        playBump,
        'zombie.changeState',
        1,
        true
    ),
    "PlayBump must not force the legacy state machine"
)
assertContains(
    playBump,
    "zombie:setBumpType(resolvedBumpType)",
    "setter-driven action-group handoff"
)
assertContains(
    playBump,
    "setManagedUseless(zombie, false, true)",
    "bumped action-context lease"
)
assertContains(
    clientSync,
    "Animation.PlayBump(zombie, recordView, anim)",
    "client attack presentation uses shared trigger"
)
assertContains(
    attackXML,
    "<m_StringValue>Attack1H1</m_StringValue>",
    "Bandits-compatible attack node bump type"
)
assertContains(
    attackXML,
    "<m_ParameterValue>BumpAnimFinished=true</m_ParameterValue>",
    "attack node completion"
)
assertContains(
    attackVariantXML,
    "<m_AnimName>Bob_Attack1Hand01_HitB</m_AnimName>",
    "Bandits-compatible second one-handed melee animation"
)
assertContains(
    combat,
    'onehanded = { "PNC_Attack1H1", "PNC_Attack1H2" }',
    "namespaced network melee vocabulary"
)
assertContains(
    animation,
    'PNC_Attack1H1 = "Attack1H1"',
    "network-to-engine attack bump translation"
)
assert(
    not string.find(combat, "Animation.PlayBump", 1, true),
    "server animation selector still renders attack bumps"
)
assert(
    not string.find(melee, "Animation.PlayBump", 1, true),
    "server melee commit still renders attack bumps"
)
assert(
    not string.find(attackActions, "Animation.FinishBump", 1, true),
    "server attack completion still owns the client bump"
)
assert(
    not string.find(unarmed, "Animation.PlayBump", 1, true),
    "server unarmed combat still renders attack bumps"
)
assert(
    not string.find(firearms, "Animation.PlayBump", 1, true),
    "server reload action still renders attack bumps"
)
assertContains(
    pathMotion,
    "if Internal.hasActiveAttack(record, now, zombie) then",
    "path service attack animation lease"
)
local pathPump = assert(string.match(
    pathMotion,
    "function PathService%.Pump.-\nend\n\nfunction PathService%.AdvanceAbstract"
))
local actionLockAt = assert(string.find(
    pathPump,
    "Internal.hasActiveAttack(record, now, zombie)",
    1,
    true
))
local consumeIntentAt = assert(string.find(
    pathPump,
    "Internal.consumeMoveIntent(record, lane, zombie)",
    1,
    true
))
assert(
    actionLockAt < consumeIntentAt,
    "movement intent mutates locomotion before the body action lease"
)

print("pnc_attack_animation_pipeline_smoke: ok")

local ANIMATION =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Visuals/PNC_Animation.lua"
local CLIENT_SYNC =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PresenceSync/PNC_ClientPresenceVisuals.lua"
local ATTACK_XML =
    "Contents/mods/ProjectHoomans/common/media/AnimSets/zombie/bumped/PNC_Attack1H1.xml"

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
local attackXML = readAll(ATTACK_XML)
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
    clientSync,
    "Animation.PlayBump(zombie, recordView, visualState.attackAnim)",
    "multiplayer attack replay uses shared trigger"
)
assertContains(
    attackXML,
    "<m_StringValue>PNC_Attack1H1</m_StringValue>",
    "attack node bump type"
)
assertContains(
    attackXML,
    "<m_ParameterValue>BumpAnimFinished=true</m_ParameterValue>",
    "attack node completion"
)

print("pnc_attack_animation_pipeline_smoke: ok")

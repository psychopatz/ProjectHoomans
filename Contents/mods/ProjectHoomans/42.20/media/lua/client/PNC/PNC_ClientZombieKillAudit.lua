-- Project Hoomans consumer for the reusable PsychopatzCore detector.

PNC = PNC or {}
PNC.ClientZombieKillAudit = PNC.ClientZombieKillAudit or {}

local Audit = PNC.ClientZombieKillAudit
local PNC_Core = PNC.Core
local Detector = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"
local Internal = Detector.Internal

if Audit.HooksRegistered then
    return Audit
end

local function log(fields)
    local message = "[ZombieKillAudit] " .. table.concat(fields, " ")
    if PNC_Core and PNC_Core.LogInfo then
        PNC_Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
end

local function onClientHit(player, zombie, context)
    local fields = {
        "luaSide=client",
        "runtime=" .. tostring(context and context.runtime or "unknown"),
        "event=OnWeaponHitCharacter",
        "result=observed",
    }
    local playerFields = Internal.CharacterFields("attacker", player)
    local zombieFields = Internal.CharacterFields("zombie", zombie)
    for i = 1, #playerFields do fields[#fields + 1] = playerFields[i] end
    for i = 1, #zombieFields do fields[#fields + 1] = zombieFields[i] end
    log(fields)
end

local function onClientKill(player, zombie, context)
    local fields = {
        "luaSide=client",
        "runtime=" .. tostring(context and context.runtime or "unknown"),
        "event=OnZombieDead",
        "result=observed",
        "playerKillCandidate=true",
        "killerSource=" .. tostring(context and context.killerSource or "nil"),
        "nativeZombieKills="
            .. tostring(context and context.nativeZombieKills or "nil"),
        "zombieDead=" .. tostring(context and context.zombieDead or "nil"),
        "zombieOnKillDone="
            .. tostring(context and context.zombieOnKillDone or "nil"),
        "clientReport=" .. tostring(context and context.clientReport or false),
        "clientReportReason="
            .. tostring(context and context.clientReportReason or "nil"),
    }
    local zombieFields = Internal.CharacterFields("zombie", zombie)
    local playerFields = Internal.CharacterFields("killer", player)
    for i = 1, #zombieFields do fields[#fields + 1] = zombieFields[i] end
    for i = 1, #playerFields do fields[#fields + 1] = playerFields[i] end
    log(fields)
end

local registered, reason = Detector.RegisterConsumer(
    "ProjectHoomans.SocialCombat",
    {
        onClientHit = onClientHit,
        onClientKill = onClientKill,
    }
)

Audit.HooksRegistered = registered == true
log({
    "luaSide=client",
    "event=consumer_registration",
    "consumer=ProjectHoomans.SocialCombat",
    "result=" .. tostring(registered),
    "reason=" .. tostring(reason or "nil"),
})

return Audit

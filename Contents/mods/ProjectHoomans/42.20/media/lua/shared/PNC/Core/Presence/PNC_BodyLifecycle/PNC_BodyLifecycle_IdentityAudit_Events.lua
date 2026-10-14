-- Event-boundary hooks for the body identity probe.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}

local Lifecycle = PNC.BodyLifecycle
local Audit = Lifecycle.IdentityAudit

local function isZombie(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoZombie") == true
    end
    return character.getPersistentOutfitID ~= nil
        or character.getVariableBoolean ~= nil
end

function Audit.OnZombieCreate(zombie)
    Audit.Capture(zombie, "on_zombie_create", nil, true)
end

function Audit.OnCreateLivingCharacter(character)
    if isZombie(character) then
        Audit.Capture(character, "on_create_living_character", nil, true)
    end
end

function Audit.OnZombieUpdate(zombie)
    Audit.Capture(zombie, "on_zombie_update", nil, false)
end

if Events and Events.OnZombieCreate and Events.OnZombieCreate.Add then
    if Events.OnZombieCreate.Remove then
        Events.OnZombieCreate.Remove(Audit.OnZombieCreate)
    end
    Events.OnZombieCreate.Add(Audit.OnZombieCreate)
end

if Events and Events.OnCreateLivingCharacter
    and Events.OnCreateLivingCharacter.Add
then
    if Events.OnCreateLivingCharacter.Remove then
        Events.OnCreateLivingCharacter.Remove(Audit.OnCreateLivingCharacter)
    end
    Events.OnCreateLivingCharacter.Add(Audit.OnCreateLivingCharacter)
end

if Events and Events.OnZombieUpdate and Events.OnZombieUpdate.Add then
    if Events.OnZombieUpdate.Remove then
        Events.OnZombieUpdate.Remove(Audit.OnZombieUpdate)
    end
    Events.OnZombieUpdate.Add(Audit.OnZombieUpdate)
end

return Audit

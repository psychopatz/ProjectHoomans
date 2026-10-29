-- Owner identity, motion/combat state, and presentation interruption for
-- live FollowOwner ticks.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.FollowOwnerStateHandoff
if type(H) ~= "table" then return Companion end

local Registry = H.Registry
local AnimationScenes = H.AnimationScenes
local Diagnostics = H.Diagnostics
local EncounterIntent = PNC.Semantics
    and PNC.Semantics.CombatEncounterIntent or nil

function H.Prepare(record, zombie, owner, now)
    local ownerCharacterUUID = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetCharacterUUID
        and PNC.PlayerCharacters.GetCharacterUUID(owner) or nil
    local ownerChanged = false
    if record.ownerUsername ~= owner:getUsername() then
        record.ownerUsername = owner:getUsername()
        ownerChanged = true
    end
    record.ownerOnlineID = owner:getOnlineID()
    if ownerCharacterUUID ~= nil
        and tostring(record.ownerCharacterUUID or "")
            ~= tostring(ownerCharacterUUID)
    then
        record.ownerCharacterUUID = tostring(ownerCharacterUUID)
        ownerChanged = true
    end
    if record.orderSpec
        and tostring(record.orderSpec.kind or "")
            == tostring(PNC.Const.ORDER_FOLLOW or "follow")
    then
        record.orderSpec.ownerUsername = record.ownerUsername
        record.orderSpec.ownerOnlineID = record.ownerOnlineID
        record.orderSpec.ownerCharacterUUID = record.ownerCharacterUUID
    end
    if ownerChanged and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "owner")
    end
    local followState = Internal.UpdateOwnerMotionState(record, owner, now)
    local ownerEngaged = Internal.UpdateOwnerCombatState(record, owner, now)
    if EncounterIntent
        and type(EncounterIntent.ObserveOwnerEngaged) == "function"
    then
        EncounterIntent.ObserveOwnerEngaged(
            record, ownerEngaged == true, now
        )
    end
    local followStateChanged = followState.ownerMovingChanged == true
    -- A follower may still be inside its formation tolerance when the owner
    -- first moves. End ambient presentation immediately instead of waiting
    -- for MoveRecord to be requested several ticks later.
    if followState.ownerMoving == true
        and AnimationScenes
        and AnimationScenes.Interrupt
        and followStateChanged
    then
        if Diagnostics and Diagnostics.LogSeatingState
            and Diagnostics.IsSeatingRuntime
            and Diagnostics.IsSeatingRuntime(
                record.runtime,
                record.runtime and record.runtime.animationScene
            )
        then
            Diagnostics.LogSeatingState(
                "follow_movement_interrupt",
                record,
                zombie,
                record.runtime and record.runtime.animationScene,
                "follow_owner_moving",
                {
                    "followOwnerMovingChanged="
                        .. tostring(followStateChanged),
                }
            )
        end
        AnimationScenes.Interrupt(record, zombie, "movement")
    end
    return followState, ownerEngaged
end

return Companion

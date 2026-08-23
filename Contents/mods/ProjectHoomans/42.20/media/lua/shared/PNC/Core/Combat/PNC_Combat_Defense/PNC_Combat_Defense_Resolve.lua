local Defense = PNC.CombatDefense
local Internal = Defense.Internal
local Core = PNC.Core

function Defense.ResolveZombieAttack(record, npcBody, zombie, now)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return true, {
            outcome = "not_authority",
            damageModel = Internal.DamageModelEnabled(),
        }
    end
    now = tonumber(now) or Core.Now()
    if Internal.DamageModelEnabled() then
        return Internal.ResolveDamageModelAttack(
            record, npcBody, zombie, now
        )
    end
    return Internal.ResolveLegacyAttack(record, npcBody, zombie, now)
end

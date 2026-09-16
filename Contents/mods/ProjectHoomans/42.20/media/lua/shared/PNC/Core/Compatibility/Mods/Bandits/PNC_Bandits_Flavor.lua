-- Bandits native presentation bridge.
--
-- Hoomans only asks the adapter to present a phrase. Bandits remains the
-- owner of speech cooldowns, captions, audio, and audience/range rules.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
PNC.Compatibility.Bandits.Flavor =
    PNC.Compatibility.Bandits.Flavor or {}

local Flavor = PNC.Compatibility.Bandits.Flavor

function Flavor.Say(actor, phrase, force)
    if not actor or not Bandit or type(Bandit.Say) ~= "function"
        or not Bandit.SoundTab
        or not Bandit.SoundTab[phrase]
    then
        return false
    end
    Bandit.Say(actor, phrase, force)
    return true
end

return Flavor

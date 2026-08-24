-- Server-authoritative persistent player-character identity entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.PlayerCharacters = PNC.PlayerCharacters or {}
PNC.PlayerContext = PNC.PlayerContext or {}
PNC.PlayerCharacters.Internal = PNC.PlayerCharacters.Internal or {}

require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_Core"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_MirrorsAndIndexes"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_RecoveryBindings"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_Persistence"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_SocialProfiles"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_StatusValidation"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_IdentityCreation"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_EnsureIdentity"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_Resolution"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_Lifecycle"
require "PNC/Player/PlayerCharacterService/PNC_PlayerCharacterService_PlayerContext"

return PNC.PlayerCharacters

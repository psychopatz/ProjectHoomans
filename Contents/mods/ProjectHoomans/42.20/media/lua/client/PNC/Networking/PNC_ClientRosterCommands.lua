-- Client roster commands are composed from snapshot storage and command groups.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

require "PNC/Networking/PNC_ClientRosterCommands_Snapshots"
require "PNC/Networking/PNC_ClientRosterCommands_Sync"
require "PNC/Networking/PNC_ClientRosterCommands_Deltas"

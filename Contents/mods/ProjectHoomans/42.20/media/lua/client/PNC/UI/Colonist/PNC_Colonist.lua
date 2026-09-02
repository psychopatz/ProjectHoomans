-- Unified Colonist menu composition root.  The tab registry is deliberately
-- loaded before the window so other client modules can inject tabs safely.
require "PNC/UI/Colonist/PNC_ColonistRegistry"
require "PNC/UI/Colonist/PNC_ColonistTabs"
require "PNC/UI/Colonist/PNC_ColonistLayout"
require "PNC/UI/Colonist/PNC_ColonistController"
require "PNC/UI/Colonist/PNC_ColonistWindow"

return PNC.ColonistUI

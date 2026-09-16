-- Backward-compatible load path. New integrations live in a provider-owned
-- subfolder so adding Necroa does not grow one shared compatibility file.
return require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_Adapter"

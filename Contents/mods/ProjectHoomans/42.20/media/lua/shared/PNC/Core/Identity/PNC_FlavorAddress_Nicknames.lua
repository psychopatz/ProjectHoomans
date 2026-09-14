PNC = PNC or {}
PNC.FlavorAddress = PNC.FlavorAddress or {}

local Address = PNC.FlavorAddress
Address.Nicknames = Address.Nicknames or {
    female = {
        { id = "babe", key = "UI_PNC_FlavorAddress_Female_Babe", fallback = "Babe" },
        { id = "darling", key = "UI_PNC_FlavorAddress_Female_Darling", fallback = "Darling" },
        { id = "sweetheart", key = "UI_PNC_FlavorAddress_Female_Sweetheart", fallback = "Sweetheart" },
        { id = "stranger", key = "UI_PNC_FlavorAddress_Female_Stranger", fallback = "Stranger" },
    },
    default = {
        { id = "buddy", key = "UI_PNC_FlavorAddress_Default_Buddy", fallback = "Buddy" },
        { id = "friend", key = "UI_PNC_FlavorAddress_Default_Friend", fallback = "Friend" },
        { id = "stranger", key = "UI_PNC_FlavorAddress_Default_Stranger", fallback = "Stranger" },
        { id = "pal", key = "UI_PNC_FlavorAddress_Default_Pal", fallback = "Pal" },
    },
}

return Address.Nicknames

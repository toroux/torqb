Config = Config or {}

Config.Webhook = "https://canary.discord.com/api/webhooks/1449223748128477275/i2_8XosZJjiixQx5FTdb2nkITmoA8WgqIWGXmjb4Hto2JfeFZ0ri1JxUjqfCQ2GX-5Uz"

Config.License = {
    -- Example: "license:34d7609d1afd81cef89d575515a04928a582415f",
    "license:957cb5f500d458864c8b289f5de661f8f695662a", --pluto
    "license:f0c3cb003da3c540c20f308d4322bd2c910875a8", --fadi
    "license:aebbb764f3a14913eb37a0a0c657dbec781ea670", --kevkev
    "license:1ecaf7ed201ea59618aa66279bd74308e95e5316", --dior
    "license:49f22c802560619a3e4800d88880d55b1ec10b41", --grace
    "license:29b1f5a678b2759e0c29a7dc4e4cf1e580fc0457", --jae
    "license:f40e5e6bd4a2dc12121aa93b82b59202dcbf047b", --reyna
    "license:cee05af2b8cccb4f7c6f7cca07ebe6d94beebac2", --torou
    "license:cd79326b527b4a58a85931a6485559226f9f5d86", --nate
}

-- UI Configuration
Config.UI = {
    LogoURL = "https://r2.fivemanage.com/sGzHhtqV5EyInZxxopmj5/TRANSPARENT.gif", -- Logo image URL
    BaseColor = "#4B0082", -- Base color in hex format (dark purple)
    RGB = false, -- Enable RGB holographic border effect (true/false)
    RGBBorders = true, -- Enable RGB borders on buttons, dropdowns, and tabs (defaults to RGB value if not set)
}

-- Tuning Configuration
Config.Tuning = { -- DO NOT TOUCH THIS!!!
    MinDamage = 0.1,  -- Minimum damage multiplier
    MaxDamage = 2.0,  -- Maximum damage multiplier
    MinRecoil = 0.0,  -- Minimum recoil (lower = less recoil)
    MaxRecoil = 2.0,  -- Maximum recoil (higher = more recoil)
    DefaultDamage = 1.0,  -- Default damage multiplier
    DefaultRecoil = 1.0,  -- Default recoil value
}
Config = {}

Config.Locales = {
    ["drop-coming"] = "A normal KOS drop is coming!",
    ["drop-coming-gang"] = "A Gang-Only Airdrop has been launched!",
    ["drop-coming-green"] = "A No-Rob Airdrop has been launched!",
    ["crate-name"] = "AirDrop",
    ["open-crate"] = "[E] - Open Crate",
    ["time-is-not-up"] = "Time is not up yet!",
    ["no-weapon"] = "You must have a gun in your hand to open the crate!",
    ["cant-while-dead"] = "You cant open the crate because you are dead",
    ["cant-while-prone"] = "You cant open the crate while you're down",
    ["cant-open-in-vehicle"] = "You cant open the crate while in the vehicle",
    ["drop-not-found"] = "Airdrop not found!",
    ["collected-item"] = "You got ~g~%s~w~ %s from the airdrop",
}

Config.crateModel = "prop_mil_crate_01"
Config.parachuteModel = "p_cargo_chute_s"
Config.crateBlips = {
    sprite = 94,
    color = 5
}

Config.ShowSphere = true
Config.SphereRadius = 75.0
Config.SphereDrawDistance = 500.0

Config.DropTypes = {
    normal = {
        sphereColor = {r = 255, g = 105, b = 180, a = 100},
    },
    green = {
        sphereColor = {r = 0, g = 255, b = 0, a = 100},
    },
    gold = {
        sphereColor = {r = 255, g = 215, b = 0, a = 100},
    },
}

Config.DiscordWebhook = {
    enabled = true,
    url = "https://canary.discord.com/api/webhooks/1424976763267711070/dlJZxqEg2xrndb2TlhbbFAKUBFuRNoLNX84fsqitrdKvJFcLQhXegd5GabR-vQVxIqz-",
    botName = "Adele Lover",
    botAvatar = "https://cdn.discordapp.com/attachments/1234567890/bot_avatar.png",
}

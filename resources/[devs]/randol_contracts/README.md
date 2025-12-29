# Randolio: Bounty Contracts

**ESX/QB support with bridge**

Inspired from the GTA Online bounty contracts, this script uses a queue system with the cycle scaled around the number of players on the server combined with the configurable times in the sv_config. Each cycle will remove the player who is first in the queue and assign them a contract. If the player is offline, it will still assign them one and store it on the server side for them to complete when they log back in. 

Contracts assign a random ped/location with a random name/occupation. The ped has a chance to run/shoot or surrender when you close the distance. Upon killing the ped, you will use your target eye/key press to snap a photo and receive a photograph item with metadata attached to it with your set payout. Return the photo, get paid and get put back into the queue. 

Contracts are not persistent over server restarts, thus making your photograph item useless if you don't hand it in before restart occurs.

Current inventories supported are ox_inventory (ESX/QB) and qb-inventory along with it's variations like ps-inventory/lj-inventory.
The bridge may allow for other inventories providing they support item metadata.

If using a different inventory, you will have to cater to this yourself by editing the bridge, I can't support every inventory known to man so purchase at your own risk or open a support ticket before hand and I may be able to assist with questions.

Current supported target systems are ox_target and qb-target. By default it will call a qb-target export which it will either use or ox_target will do the conversion.
The other alternative is to use ox lib points. Upon death of the target, it will create a point around the target where you can use 'E' to take the picture instead.

# Showcase
https://streamable.com/k9pwwb

# Items/Images

-- ox_inventory/data/items.lua
["photograph"] = {
    label = "Photograph",
    weight = 100,
    stack = false,
    close = true,
    description = "A photograph.",
    client = {
        image = "photograph.png",
    }
},

-- qb-core/shared/items.lua
photograph = { name = 'photograph', label = 'Photograph', weight = 100, type = 'item', image = 'photograph.png', unique = true, useable = false, shouldClose = true, combinable = nil, description = 'A photograph.' },

Placed the photograph image in your inventory images folder.

## Requirements

* [ox_lib](https://github.com/overextended/ox_lib/releases/tag/v3.16.2)


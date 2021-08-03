# ElectrumZ

ElectrumZ is a mod for Minetest of monetary economics.

The official currency is the "Electrum", which is an alloy of gold, silver and copper in different proportions. The electrum symbol is: ê.

1 crafting = 100 electrums.

## Commands

### For administrators

- /add_money <player_name> <amount>
Amount: Can be positive or negative

- /get_money <player_name>
It retrieves info about the player's account.

### For players

- /money
Gets the info about your account

- /save_money
Saves to your account all electrums in your inventory.

- /give_money <player_name> <amount>
Gives money to another player.

## Easy management

### Piggy bank

Create this cute piggy bank to store your electrums without command.
Right-click on it to save them.
Note that ALL electrums in your inventory will be saved, not just the ones you wield.
Note that the electrums will be deposited in your bank account, not physically inside the piggy bank. No matter if the piggy is stolen or broken, your money will be safe.

### ElectrumPay Card

View your account status and make quick transfers to other players.

Just use it. It has a technology that identifies you by your fingerprint. It doesn't matter if it gets stolen. Your bank account will be safe.

## API

- elez.get_money(player)
- elez.add_money(player, amount)
- elez.save_money(player)
- elez.transfer_money(src_name, dst_name, amount)

## License

- Source code: GPLv3.
- Textures: CC BY-SA 4.0

## Dependencies

- default, moreores, basic_materials, dye

## Download

https://github.com/runsy/elez/archive/refs/heads/main.zip


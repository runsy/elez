elez = {}
local coin_name = "elez:electrum"
local ingots_to_coins = 99
local withdraw_max = 99
local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

--Electrum
minetest.register_craftitem(coin_name, {
	description = S("Electrum"),
	inventory_image = "elez_electrum.png",
	wield_image = "elez_electrum.png",
	stack_max = 99,
})

minetest.register_craft({
	type = "shaped",
	output = coin_name.." "..tostring(ingots_to_coins),
	recipe = {
		{"", "moreores:silver_ingot", ""},
		{"moreores:silver_ingot", "default:gold_ingot", "moreores:silver_ingot"},
		{"", "default:copper_ingot", ""},
	}
})

--Credit Card
minetest.register_craftitem("elez:credit_card", {
	description = S("ElectrumPay Card"),
	inventory_image = "elez_credit_card.png",
	wield_image = "elez_credit_card.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		elez.electrumpay(user, "", nil, false)
		return nil
	end,
})

minetest.register_craft({
	type = "shaped",
	output = "elez:credit_card",
	recipe = {
		{"", "", ""},
		{"", "", ""},
		{"basic_materials:ic", "basic_materials:plastic_sheet", "elez:electrum"},
	}
})

--Piggy Bank
minetest.register_node("elez:piggy_bank", {
	description = S("Piggy Bank"),
	drawtype = "nodebox",
	tiles = {
		"elez_piggy_bank_top.png",
		"elez_piggy_bank_bottom.png",
		"elez_piggy_bank_right.png",
		"elez_piggy_bank_left.png",
		"elez_piggy_bank_back.png",
		"elez_piggy_bank_front.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.25, -0.375, -0.25, 0.25, -0.0625, 0.25},
			{-0.1875, -0.5, -0.1875, -0.125, -0.375, -0.125},
			{0.125, -0.5, -0.1875, 0.1875, -0.375, -0.125},
			{0.125, -0.5, 0.125, 0.1875, -0.375, 0.1875},
			{-0.1875, -0.5, 0.125, -0.125, -0.375, 0.1875},
			{-0.125, -0.3125, -0.3125, 0.125, -0.1875, -0.25},
		}
	},
	groups = {crumbly = 2},
	sounds = default.node_sound_glass_defaults(),
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		elez.save_money(player)
	end,
})

minetest.register_craft({
	type = "shaped",
	output = "elez:piggy_bank",
	recipe = {
		{"", coin_name, ""},
		{"", "dye:pink", ""},
		{"", "default:clay", ""},
	}
})

--Automatic Teller Machine
minetest.register_node("elez:teller_machine", {
	description = S("Automatic Teller Machine"),
	drawtype = "mesh",
	mesh = "elez_teller_machine.b3d",
	tiles = {"elez_teller_machine.png"},
	paramtype2 = "facedir",
	param2 = 5,
	physical = true,
	groups = {cracky = 3},
	sounds = default.node_sound_metal_defaults(),
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		elez.electrumpay(player, "", nil, true)
	end,
})

minetest.register_craft({
	type = "shaped",
	output = "elez:teller_machine",
	recipe = {
		{"", "elez:credit_card", ""},
		{"", "basic_materials:ic", ""},
		{"", "default:steelblock", ""},
	}
})

--Helper Functions
local function is_numeric(x)
    if tonumber(x) ~= nil then
        return true
    end
    return false
end

--Basic Money functions

local function check_amount(amount)
	if not amount then
		return false, S("Error: You have to specify an amount of money.")
	end
	if not is_numeric(amount) then
		return false, S("Error: The amount has to be numeric.")
	end
	if amount == 0 then
		return false, S("Error: Type an amount greater than 0.")
	end
	return true
end

function elez.add_money(player, amount)
	if amount < -32768 then
		amount = -32768
	elseif amount > 32767 then
		amount = 32767
	end
	player:get_meta():set_int("elez:money", (player:get_meta():get_int("elez:money") + amount))
end

function elez.get_money(player)
	return player:get_meta():get_int("elez:money")
end

function elez.save_money(player)
	local inv = player:get_inventory()
	local inv_list = inv:get_list("main")
	local player_name = player:get_player_name()
	if not inv:contains_item("main", coin_name) then
		minetest.chat_send_player(player_name, S("You have no electrums in your inventory."))
		return false
	end
	local amount = 0
	for i = 1, #inv_list do
		local item_stack = inv_list[i]
		if item_stack:get_name() == coin_name then
			amount = amount + item_stack:get_count()
			inv:set_stack("main", i, ItemStack(nil))
		end
	end
	elez.add_money(player, amount)
	minetest.chat_send_player(player_name, tostring(amount).." "..S("electrums saved"))
	return true
end

function elez.transfer_money(src_name,dst_name,amount)
	local ok, msg = check_amount(amount)
	if not ok then
		return ok, msg
	end
	amount = math.abs(amount)
	if amount > 32767 then
		amount = 32767
	end
	local src = minetest.get_player_by_name(src_name)
	local dst = minetest.get_player_by_name(dst_name)
	if not dst then
		return false, S("Error: The player does not exist or not online.")
	end
	if src_name == dst_name then
		return false, S("Error: You cannot send money to yourself.")
	end
	if (elez.get_money(src) < amount) then
		return false, S("Error: You has not").." "..tostring(amount).." "..S("of money to give.")
	end
	elez.add_money(dst, amount)
	elez.add_money(src, -amount)
	minetest.chat_send_player(src_name, S("You've given").." "..tostring(amount).." "
		..S("of money to").." "..dst_name)
	minetest.chat_send_player(dst_name, S("You've received").." "..tostring(amount).." "
		..S("of money from").." "..src_name)
	return true, S("Transfer successfully completed.")
end

function elez.withdraw_money(player, amount)
	local ok, msg = check_amount(amount)
	if not ok then
		return ok, msg
	end
	amount = math.abs(amount)
	if amount > withdraw_max then
		amount = withdraw_max
	end
	if amount > elez.get_money(player) then
		return false, S("Error: You has not").." "..tostring(amount).." "..S("of money to withdraw.")
	end
	local inv = player:get_inventory()
	local money_stack = ItemStack(coin_name.." "..tostring(amount))
	if not inv:room_for_item("main", money_stack) then
		return false, S("No space in your inventory for the money.")
	else
		inv:add_item("main", money_stack)
		elez.add_money(player, -amount)
		return true, S("Money successfully withdrawn.")
	end
end

--ElectrumPay

local _contexts = {}

local function get_context(name)
    local context = _contexts[name] or {}
    _contexts[name] = context
    return context
end

minetest.register_on_leaveplayer(function(player)
    _contexts[player:get_player_name()] = nil
end)

local function compose_formspec(user, title, msg, default_fields, withdraw)
	local formspec = [[
		formspec_version[4]
		size[6,5]
		label[2.25,0.25;]]..title..[[]
		label[0.25,0.75;]]..S("Account Balance")..": "..
			tostring(elez.get_money(user)).." ê"..[[]
		field[0.25,1.25;2,1;fld_name;]]..S("Name")..[[:;]]..default_fields["name"]..[[]
		field_close_on_enter[fld_name;false]
		field[2.25,1.25;1,1;fld_amount;]]..S("Amount")..[[:;]]..default_fields["amount"]..[[]
		field_close_on_enter[fld_amount;false]
		button_exit[1.75,2.25;1,1;btn_transfer;]]..S("Transfer")..[[]
		label[0.25,3.5;]]..msg..[[]
		button_exit[2.5,3.75;1,1;btn_close;]]..S("Close")..[[]
	]]
	if withdraw then
		formspec = formspec..
			"field[3.75,1.25;1,1;fld_withdraw;"..S("Amount")..":;"..default_fields["withdraw"].."]"..
			"field_close_on_enter[fld_withdraw;false]"..
			"button_exit[3.75,2.25;2,1;btn_withdraw;"..S("Withdraw").." "..tostring(withdraw_max)
				.." "..S("max").."]"
	end
	return formspec
end

local function get_default_fields(fields, success)
	if success then
		return {name="", amount="", withdraw=""}
	else
		return {name=fields.fld_name, amount=fields.fld_amount, withdraw=fields.fld_withdraw}
	end
end

function elez.electrumpay(user, msg, default_fields, withdraw)
	local user_name = user:get_player_name()
	local context = get_context(user_name)
	local title
	if withdraw then
		context.withdraw = true
		title = S("Automatic Teller Machine")
	else
		context.withdraw = false
		title = S("ElectrumPay Card")
	end
	if not default_fields then
		default_fields = {name = "", amount = "", withdraw = ""}
	end
    minetest.show_formspec(user_name, "elez:electrumpay", compose_formspec(user, title, msg, default_fields, withdraw))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "elez:electrumpay" then
        return
    end
    local player_name = player:get_player_name()
    local context = get_context(player_name)
    if fields.btn_transfer then
		local transfer, msg = elez.transfer_money(player_name, fields.fld_name, fields.fld_amount)
		elez.electrumpay(player, msg, get_default_fields(fields, transfer), context.withdraw)
	elseif fields.btn_withdraw then
		local withdraw, msg = elez.withdraw_money(player, fields.fld_withdraw)
		elez.electrumpay(player, msg, get_default_fields(fields, withdraw), context.withdraw)
    end
end)

--COMMANDS

minetest.register_chatcommand("add_money", {
	privs = {
        server = true,
    },
	description = S("Add an amount of money (+ or -)"),
    func = function(name, param)
		if param == "" then
			return true, S("Error: You have to specify a player and an amount of money.")
		end
		local player_name, amount = string.match(param, "([%a%d_-]+) ([%a%d_-]+)")
		local ok, msg = check_amount(amount)
		if not ok then
			return true, msg
		end
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return true, S("Error: The player does not exist or not online.")
		end
		elez.add_money(player, tonumber(amount))
		minetest.chat_send_player(name, S("You've added").." "..tostring(amount).." "
			..S("of money to").." "..player_name)
    end,
})

minetest.register_chatcommand("money", {
	description = S("Get the info about your money"),
    func = function(name, param)
		local you = minetest.get_player_by_name(name)
		minetest.chat_send_player(name, S("You has").." "
			..tostring(elez.get_money(you)).." "..S("of money."))
    end,
})

minetest.register_chatcommand("get_money", {
	privs = {
        server = true,
    },
	description = S("Get the info about a player's money"),
    func = function(name, param)
		if param == "" then
			return true, S("Error: You have to specify a player.")
		end
		local player_name = string.match(param, "([%a%d_-]+)")
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return true, S("Error: The player does not exist or not online.")
		end
		minetest.chat_send_player(name, player_name.." "..S("has").." "
			..tostring(elez.get_money(player)).." "..S("of money."))
    end,
})

minetest.register_chatcommand("save_money", {
	description = S("Save your electrums from your inventory"),
    func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return true, S("Error: The player does not exist or not online.")
		end
		elez.save_money(player)
    end,
})

minetest.register_chatcommand("give_money", {
	description = S("Give of your money to a player"),
    func = function(name, param)
		if param == "" then
			return true, S("Error: You have to specify a player and an amount of money.")
		end
		local player_name, amount = string.match(param, "([%a%d_-]+) ([%a%d_-]+)")
		elez.transfer_money(name, player_name, amount)
    end,
})

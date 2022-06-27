
local storage = minetest.get_mod_storage()

function is_ipv4(ip)
	if not ip then return false end

	octets = 0
	for octet in ip:gmatch('[^.%s]+') do
		octets = octets + 1
		octet = tonumber(octet)

		if not octet or octet < 0 or octet > 255 then return false end
	end

	return octets == 4
end

local function yellow(message) return minetest.colorize("#ffff00", message) end
local function red   (message) return minetest.colorize("#ff0000", message) end

local function revoke_interact(name)
	local pri = minetest.get_player_privs(name)
	pri["interact"] = false
	minetest.set_player_privs(name, pri)

	if minetest.settings:get_bool('no_touch_griefer_joinmessage', true) then
		minetest.chat_send_player(name, red("You have been interact-banned and can only look, not touch."))
	end
end

local function interact_ban(ip)
	storage:set_int(ip, 1)
end

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	local ip = minetest.get_player_ip(playername)
	if storage:get(ip, false) then
		revoke_interact(playername)
	end
end)

minetest.register_chatcommand("interactban", {
	params = "<ip | playername>",
	description = "Interact-ban the given IP (or a player's IP if they are online)",
	privs = { ban = true },
	func = function(name, param)
		if not param then return end

		if is_ipv4(param) then -- IP
			interact_ban(param)
			minetest.chat_send_player(name, yellow("Successfully interact-banned the IP "..red(param).."."))
		else -- Player's IP
			local playerip = minetest.get_player_ip(param)
			if playerip then
				interact_ban(playerip)
				minetest.chat_send_player(name, yellow("Successfully interact-banned the player ")..red(param)..yellow(". (IP: ")..red(playerip)..yellow(")"))
				-- Since they're online, revoke their interact privs right heckin' now
				revoke_interact(param)
			else
				minetest.chat_send_player(name, red("Invalid IP address or player isn't online."))
			end
		end
	end
})

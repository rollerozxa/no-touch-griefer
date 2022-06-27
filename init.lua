
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

local function interact_unban(ip)
	storage:set_string(ip, "")
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

minetest.register_chatcommand("ib_bulk", {
	description = "Bulk process a list of IP addresses from /interactban.txt",
	privs = { ban = true },
	func = function(name, param)
		local st = {
			lines = 0,
			processed = 0,
			invalid = 0}

		local file = io.open(minetest.get_worldpath().."/interactban.txt", "r")
		for ip in file:lines() do
			if ip ~= '' and string.sub(ip,1,1) ~= "#" then -- Ignore blank lines and comments prepended with #
				st.lines = st.lines + 1
				if is_ipv4(ip) then
					interact_ban(ip)
					st.processed = st.processed + 1
				else
					st.invalid = st.invalid + 1
				end
			end
		end

		local chatmsg = yellow("Successfully processed ")..red(st.processed)..yellow(" lines")

		if st.invalid == 0 and st.lines == st.processed then
			chatmsg = chatmsg..yellow(".")
		else
			chatmsg = chatmsg..yellow(" out of ")..red(st.lines)..yellow(" (")..red(st.invalid)..yellow(" invalid)")
		end

		minetest.chat_send_player(name, chatmsg)
	end
})

minetest.register_chatcommand("interactunban", {
	params = "<ip>",
	description = "Remove an interact-banned IP.",
	privs = { ban = true },
	func = function(name, param)
		if not param then return end

		if is_ipv4(param) then -- IP
			interact_unban(param)
			minetest.chat_send_player(name, yellow("Successfully unbanned the IP "..red(param).."."))
		else
			minetest.chat_send_player(name, red("Invalid IP address."))
		end
	end
})

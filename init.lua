no_touch_griefer = {}

local storage = core.get_mod_storage()

local function is_ipv4(ip)
	if not ip then return false end

	local octets = 0
	for octet in ip:gmatch('[^.%s]+') do
		octets = octets + 1
		octet = tonumber(octet)

		if not octet or octet < 0 or octet > 255 then return false end
	end

	return octets == 4
end

local function yellow(message) return core.colorize("#ffff00", message) end
local function red   (message) return core.colorize("#ff0000", message) end

local function revoke_interact(name)
	local pri = core.get_player_privs(name)
	pri["interact"] = nil
	core.set_player_privs(name, pri)

	if core.settings:get_bool('no_touch_griefer_joinmessage', true) then
		core.chat_send_player(name, red("You have been interact-banned and can only look, not touch."))
	end
end

core.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	local ip = core.get_player_ip(playername)
	if storage:get(ip, false) then
		revoke_interact(playername)
	end
end)

-- Public API

function no_touch_griefer.check_ban(ip)
	return storage:get_int(ip) == 1
end

function no_touch_griefer.ban(ip)
	storage:set_int(ip, 1)
end

function no_touch_griefer.unban(ip)
	storage:set_string(ip, "")
end


-- Admin commands

core.register_chatcommand("interactban", {
	params = "<ip | playername>",
	description = "Interact-ban the given IP (or a player's IP if they are online)",
	privs = { ban = true },
	func = function(name, param)
		if not param then return end

		if is_ipv4(param) then -- IP
			no_touch_griefer.ban(param)
			core.chat_send_player(name, yellow("Successfully interact-banned the IP "..red(param).."."))
		else -- Player's IP
			local playerip = core.get_player_ip(param)
			if playerip then
				no_touch_griefer.ban(playerip)
				core.chat_send_player(name, yellow("Successfully interact-banned the player ")..red(param)..yellow(". (IP: ")..red(playerip)..yellow(")"))
				-- Since they're online, revoke their interact privs right heckin' now
				revoke_interact(param)
			else
				core.chat_send_player(name, red("Invalid IP address or player isn't online."))
			end
		end
	end
})

core.register_chatcommand("ib_bulk", {
	description = "Bulk process a list of IP addresses from /interactban.txt",
	privs = { ban = true },
	func = function(name, param)
		local st = {
			lines = 0,
			processed = 0,
			invalid = 0}

		local file = io.open(core.get_worldpath().."/interactban.txt", "r")

		if file == nil then
			core.chat_send_player(name, red("Could not find an interactban.txt file in your world folder."))
			return
		end

		for ip in file:lines() do
			if ip ~= '' and string.sub(ip,1,1) ~= "#" then -- Ignore blank lines and comments prepended with #
				st.lines = st.lines + 1
				if is_ipv4(ip) then
					no_touch_griefer.ban(ip)
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

		core.chat_send_player(name, chatmsg)
	end
})

core.register_chatcommand("interactunban", {
	params = "<ip>",
	description = "Remove an interact-banned IP.",
	privs = { ban = true },
	func = function(name, param)
		if not param then return end

		if is_ipv4(param) then -- IP
			no_touch_griefer.unban(param)
			core.chat_send_player(name, yellow("Successfully unbanned the IP "..red(param).."."))
		else
			core.chat_send_player(name, red("Invalid IP address."))
		end
	end
})

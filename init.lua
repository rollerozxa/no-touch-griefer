
local storage = minetest.get_mod_storage()

minetest.register_on_joinplayer(function(player)
	local playername = player:get_player_name()
	local ip = minetest.get_player_ip(playername)
	if storage:get(ip, false) then
		local pri = minetest.get_player_privs(playername)
		pri["interact"] = false
		minetest.set_player_privs(playername, pri)

		if minetest.settings:get_bool('no_touch_griefer_joinmessage', true) then
			minetest.chat_send_player(playername, minetest.colorize("#ff0000", "You have been interact-banned and can only look, not touch."))
		end
	end
end)

minetest.register_chatcommand("interactban", {
	params = "<ip>",
	description = "Interact ban the given IP",
	privs = { ban = true },
	func = function(name, param)
		storage:set_int(param, 1)
		minetest.chat_send_player(name, minetest.colorize("#ffff00", "Successfully interact banned the IP "..minetest.colorize("#ff0000", param).."."))
	end
})

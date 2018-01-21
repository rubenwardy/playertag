local nametags = {}
local show_tag = {}
local ATTACH_POSITION = minetest.rgba and {x=0,y=18,z=0} or {x=0,y=9,z=0}

local function add_tag(player)
	local ent = minetest.add_entity(player:get_pos(), "playertag:tag")

	-- Build name from font texture
	local color = "W"
	local texture = "npcf_tag_bg.png"
	local x = math.floor(134 - ((player:get_player_name():len() * 11) / 2))
	local i = 0
	player:get_player_name():gsub(".", function(char)
		if char:byte() > 64 and char:byte() < 91 then
			char = "U"..char
		end
		texture = texture.."^[combine:84x14:"..(x+i)..",0="..color.."_"..char..".png"
		i = i + 11
	end)
	ent:set_properties({ textures={texture} })

	-- Attach to player
	ent:set_attach(player, "", ATTACH_POSITION, {x=0,y=0,z=0})
	ent:get_luaentity().wielder = player:get_player_name()

	-- Store
	nametags[player:get_player_name()] = ent

	-- Hide fixed nametag
	player:set_nametag_attributes({
		color = {a = 0, r = 0, g = 0, b = 0}
	})

	show_tag[player:get_player_name()] = true
end

local function remove_tag(player)
	show_tag[player:get_player_name()] = nil
	local tag = nametags[player:get_player_name()]
	if tag then
		tag:remove()
		tag = nil
	end
end

local nametag = {
	npcf_id = "nametag",
	physical = false,
	collisionbox = {x=0, y=0, z=0},
	visual = "sprite",
	textures = {"default_dirt.png"},--{"npcf_tag_bg.png"},
	visual_size = {x=2.16, y=0.18, z=2.16},--{x=1.44, y=0.12, z=1.44},
}

function nametag:on_activate(staticdata, dtime_s)
	if staticdata == "expired" then
		local name = self.wielder and self.wielder:get_player_name()
		if name and nametags[name] == self.object then
			nametags[name] = nil
		end

		self.object:remove()
	end
end

function nametag:get_staticdata()
	return "expired"
end

function nametag:on_step(dtime)
	local name = self.wielder
	local wielder = name and minetest.get_player_by_name(name)
	if not wielder then
		self.object:remove()
	elseif not show_tag[name] then
		if name and nametags[name] == self.object then
			nametags[name] = nil
		end

		self.object:remove()
	end
end

minetest.register_entity("playertag:tag", nametag)

local function step()
	for _, player in pairs(minetest.get_connected_players()) do
		local show = show_tag[player:get_player_name()]
		if show then
			local ent = nametags[player:get_player_name()]
			if not ent or ent:get_luaentity() == nil then
				add_tag(player)
			else
				ent:set_attach(player, "", ATTACH_POSITION, {x=0,y=0,z=0})
			end
		end
	end

	minetest.after(10, step)
end
minetest.after(10, step)

minetest.register_globalstep(function(player)
	for _, player in pairs(minetest.get_connected_players()) do
		player:set_nametag_attributes({
			color = {a = 0, r = 0, g = 0, b = 0}
		})
	end
end)

minetest.register_on_joinplayer(function(player)
	add_tag(player)
end)

minetest.register_on_leaveplayer(function (player)
	remove_tag(player)
end)

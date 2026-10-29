pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- gold dungeon: weight of greed (8x8 player edition)

function _init()
	state = 0
	menu_sel = 1
	menu_ops = {"play", "instructions"}

	-- sprite configuration
	player_spr = 0   -- slot 1 in sprite tab (8x8 sprite)
	player_size = 1  -- 1x1 tile (8x8 pixels)
	chest_spr = 5    -- slot 5: 8x8 chest sprite
	enemy_spr = 7    -- slot 7: 8x8 enemy sprite
	exit_spr = 9     -- slot 9: 8x8 exit hatch sprite

	init_game()
end

function init_game()
	-- player stats
	p = {
		x = 60,
		y = 60,
		base_spd = 1.2,
		gold = 0,
		hp = 3
	}

	-- enemy setup
	enemy = {
		x = 10,
		y = 10,
		base_spd = 0.5
	}

	-- explicit gold chest positions (x, y pixels and active status)
	gold_chests = {
		{x = 20,  y = 20, active = true},
		{x = 100, y = 20, active = true},
		{x = 20,  y = 100, active = true},
		{x = 100, y = 100, active = true},
		{x = 60,  y = 25,  active = true},
		{x = 60,  y = 105, active = true}
	}

	-- exit door position
	exit_door = {x = 110, y = 110}
end

function _update()
	-- start screen --
	if state == 0 then
		if btnp(4) or btnp(5) then state = 1 end

	-- menu --
	elseif state == 1 then
		if btnp(2) then menu_sel = max(1, menu_sel - 1) end
		if btnp(3) then menu_sel = min(#menu_ops, menu_sel + 1) end

		if btnp(4) or btnp(5) then
			if menu_sel == 1 then
				init_game()
				state = 3 -- gameplay state --
			elseif menu_sel == 2 then
				state = 2 -- instructions --
			end
		end

	-- instructions --
	elseif state == 2 then
		if btnp(4) or btnp(5) then state = 1 end

	-- gameplay --
	elseif state == 3 then
		update_gameplay()

	-- game over --
	elseif state == 4 then
		if btnp(4) or btnp(5) then state = 1 end

	-- victory --
	elseif state == 5 then
		if btnp(4) or btnp(5) then state = 1 end
	end
end

function update_gameplay()
	-- greed formula
	local p_speed = max(0.3, p.base_spd - (p.gold * 0.012))

	-- player movement --
	if btn(0) then p.x -= p_speed end
	if btn(1) then p.x += p_speed end
	if btn(2) then p.y -= p_speed end
	if btn(3) then p.y += p_speed end

	-- boundary stuff
	p.x = mid(11, p.x, 110)
	p.y = mid(18, p.y, 110)

	-- enemy speed logic => faster as player gets more gold
	local e_speed = enemy.base_spd + (p.gold * 0.003)
	if enemy.x < p.x then enemy.x += e_speed end
	if enemy.x > p.x then enemy.x -= e_speed end
	if enemy.y < p.y then enemy.y += e_speed end
	if enemy.y > p.y then enemy.y -= e_speed end

	-- check collision with player (bounding box check 8x8)
	if abs((p.x + 4) - (enemy.x + 4)) < 6 and abs((p.y + 4) - (enemy.y + 4)) < 6 then
		p.hp -= 1
		if p.hp <= 0 then
			state = 4 -- game over
		else
			-- knockback player slightly when hit
			p.x += (p.x < enemy.x) and -10 or 10
		end
	end

	-- check gold chest collection --
	for chest in all(gold_chests) do
		if chest.active then
			-- distance between player center and chest center checked
			if abs((p.x + 4) - (chest.x + 4)) < 8 and abs((p.y + 4) - (chest.y + 4)) < 8 then
				chest.active = false
				p.gold += 25
			end
		end
	end

	-- how to win? (very hard lol) --
	if abs((p.x + 4) - (exit_door.x + 4)) < 8 and abs((p.y + 4) - (exit_door.y + 4)) < 8 then
		state = 5 -- victory!
	end

	-- drop gold mechanic (x button) to lighten load --
	if btnp(5) and p.gold >= 25 then
		p.gold -= 25
	end
end

function _draw()
	cls(0)

	-- start screen --
	if state == 0 then
		rect(4, 4, 123, 123, 7)
		print("gold dungeon", 40, 20, 10)
		print("greed the fifth sin...", 20, 45, 7)
		print("press (z) to continue", 20, 105, 6)

	-- menu --
	elseif state == 1 then
		print("main menu", 46, 25, 10)

		for i = 1, #menu_ops do
			local col = (i == menu_sel) and 10 or 6
			local prefix = (i == menu_sel) and "> " or "  "
			print(prefix .. menu_ops[i], 42, 50 + (i * 14), col)
		end

	-- instructions --
	elseif state == 2 then
		print("how to play", 42, 12, 10)
		print("more gold = slower speed", 12, 35, 8)
		print("more gold = faster monster!", 10, 47, 9)
		print("collect chests & reach exit", 10, 65, 11)
		print("press (x) to drop gold (25g)", 8, 80, 7)
		print("press (z) for menu", 28, 110, 6)

	-- gameplay --
	elseif state == 3 then
		-- draw room boundary box
		rect(10, 16, 118, 118, 5)

		-- active gold chests
		for chest in all(gold_chests) do
			if chest.active then
				spr(chest_spr, chest.x, chest.y)
			end
		end

		-- exit hatch
		spr(exit_spr, exit_door.x, exit_door.y)

		-- chaser enemy
		spr(enemy_spr, enemy.x, enemy.y)

		-- player sprite
		spr(player_spr, p.x, p.y, player_size, player_size)

		-- hud bar background --
		rectfill(0, 0, 127, 14, 0)
		line(0, 14, 127, 14, 6)

		-- live hud stats --
		print("gold:" .. p.gold, 4, 4, 10)
		print("hp:" .. p.hp, 54, 4, 8)
		local cur_spd = flr(max(0.3, p.base_spd - (p.gold * 0.012)) * 10) / 10
		print("spd:" .. cur_spd, 88, 4, 11)

	-- game over --
	elseif state == 4 then
		print("you were consumed by greed", 16, 40, 8)
		print("final gold: " .. p.gold, 32, 55, 10)
		print("press (z) to try again", 24, 85, 6)

	-- victory --
	elseif state == 5 then
		print("escaped with your fortune!", 14, 40, 11)
		print("final loot: " .. p.gold, 32, 55, 10)
		print("press (z) to play again", 24, 85, 6)
	end
end
__gfx__
aaaaaaaa00000000000000000000000000000000ddaa33dd00000000111111110000000000000000000000000000000000000000000000000000000000000000
0cffffc000000000000000000000000000000000da22233d000000001bccccb10000000000444400000000000000000000000000000000000000000000000000
0ffeeff0000000000000000000000000000000009a2a9993000000001cccccc10000000000400400000000000000000000000000000000000000000000000000
00cccc0000000000000000000000000000000000a22aa993000000001cccccc10000000000444400000000000000000000000000000000000000000000000000
cccccccc00000000000000000000000000000000aaa9aaa3000000001c8888c10000000000444400000000000000000000000000000000000000000000000000
c0cccc0c00000000000000000000000000000000a2a9a9a9000000001cccccc10000000000444400000000000000000000000000000000000000000000000000
00b00b000000000000000000000000000000000099222229000000001c1111c10000000000000000000000000000000000000000000000000000000000000000
08b00b8000000000000000000000000000000000aa99999900000000001001000000000000000000000000000000000000000000000000000000000000000000

pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--oni
--by astra

function config()	
	--game state configurations
	g={
		state=0,
		upgrade_delay=5,
		upgrade_delay_raise=5,
		enemy_rate_upgrade=0.92,
	}
	
	--map limits
	m={
		startx=0,
		starty=0,
		endx=63,
		endy=63,
		pumpkin_prob=0.01
	}

	--player configurations
	p={
		speed=4,
		walk_timer=10,
		clip_size=6,
		bullet_speed=8,
		shoot_delay=0.5*30,
		dash_speed=0.5*30,
		dash_duration=0.2*30,
		dash_cooldown=0.8*30,
		max_rage=20
	}
	
	--enemy configurations
	e={
		speed=3,
		spawn_delay=30
	}
	
	--game state data
	game={
		upgrade_timer=g.upgrade_delay,
	}
end

function _init()
	config()
	generate_map()
	setup_player()
	setup_enemy()
end

function _update()
	if g.state==0 then
		update_welcome()
	elseif g.state==1 then
		update_player()
		check_dash()
		spawn_enemy()
		update_enemy()
		check_shooting()
		update_bullets()
		update_ui()
		
		update_game()
	elseif g.state==2 then
		_update_game_over()
	end
end

function _draw()
	cls()
	if g.state==0 then
		draw_welcome()
	elseif g.state==1 then
		camera(player.x-64,player.y-64)
		map(0,0,m.startx,m.starty,m.endx-m.startx+1,m.endy-m.starty+1)
		draw_bullets()
		draw_player()
		draw_enemy()
		draw_ui()
	elseif g.state==2 then
		_draw_game_over()
	end
end

function update_game()
	game.upgrade_timer-=1
	
	if game.upgrade_timer==0 then
		g.upgrade_delay+=g.upgrade_delay_raise
		game.upgrade_timer=g.upgrade_delay
		
		e.spawn_delay*=g.enemy_rate_upgrade
	end
end

function game_over()
	g.state=2
	go_r=0 --wipe radius starting at 0
end

function _update_game_over()
    -- 1. expand the circle radius until it covers the screen corners (approx 92px)
    if go_r < 95 then
        go_r += 7  -- adjust speed of fill here (2 px/frame = ~1.5s)
    end

    -- 2. restart game when x is pressed (after fill starts)
    if btnp(❎) then
        _init()    -- resets player, enemies, bullets, and game_state back to 1
    end
end

function _draw_game_over()
    -- 1. reset camera to screen space so coordinates stay 0..127
    camera()

    -- 2. expand red fill (color 8) outwards from center (64, 64)
    if go_r > 0 then
        circfill(64, 64, go_r, 8)
    end

    -- 3. draw text once the screen is largely covered
    if go_r >= 85 then
        -- big letters: pico-8 special control codes "\#" or "\^w\^t" scale text
        -- "\^w\^t" doubles text width & height
        print("\^w\^tgame over", 28, 38, 7)
        
        -- kills counter (skull icon = shift+s or chr(139))
        local kill_txt = "kills: "..chr(139).." "..player.kills
        local tx = 64 - (#kill_txt * 4) / 2
        print(kill_txt, tx, 62, 0)
        print(kill_txt, tx, 61, 7) -- shadowed white text

        -- flashing "press x to restart"
        if time() % 1 < 0.6 then
            print("press ❎ to restart", 24, 88, 10) -- yellow text
        end
    end
end

-->8
--map code

function generate_map()
	for i=m.startx+1,m.endx-1 do
		mset(i,m.starty,16)
		mset(i,m.endy,16)
	end
	for j=m.starty+1,m.endy-1 do
		mset(m.startx,j,18)
		mset(m.endx,j,17)
	end
	mset(m.startx,m.starty,22)
	mset(m.startx,m.endy,21)
	mset(m.endx,m.starty,19)
	mset(m.endx,m.endy,20)
	
	decorate_map()
end

function decorate_map()
	for i=m.startx+1,m.endx-1 do
		for j=m.starty+1,m.endy-1 do
			if rnd(1)<0.2 then
				local sprite_id
				
				--probabilities
				if rnd(1)<m.pumpkin_prob then
					sprite_id=37
				else
					sprite_id=32+rnd(1)\0.25
				end
				mset(i,j,sprite_id)
			end
		end
	end
end
-->8
--player code

function setup_player()
	player={
		walk_timer=p.walk_timer,
		x=(m.startx+m.endx)*4,
		y=(m.starty+m.endy)*4,
		sprite=60,
		sprite_offset=0,
		rage=2,
		shoot_timer=0,
		dash_timer=0,
		dash_cd=0,
		dash_dx=1,
		dash_dy=0,
		facing_x=1,
		facing_y=0,
		kills=0
	}
	bullets={}
end

function update_player()
	if (player.shoot_timer>0)	player.shoot_timer-=1
	if (player.dash_cd>0) player.dash_cd-=1

	--handle active dash
	if player.dash_timer>0 then
		_dash_update_player()
		return
	end

	local step=p.speed*8/30
	local dx=0
	local dy=0
	
	if (btn(⬅️)) dx-=step
	if (btn(➡️)) dx+=step
	if (btn(⬆️)) dy-=step
	if (btn(⬇️)) dy+=step
	
	if dx!=0 and dy!=0 then
		dx*=0.7071
		dy*=0.7071
	end
	
	-- save facing direction if moving
	if dx!=0 or dy!=0 then
		player.facing_x=dx
		player.facing_y=dy
	end
	
	player.x=mid((m.startx+1)*8,player.x+dx,(m.endx-1)*8)
	player.y=mid((m.starty+1)*8,player.y+dy,(m.endy-1)*8)
end

function check_dash()
	if btnp(❎) and player.dash_cd<=0 then
		player.dash_timer=p.dash_duration
		player.dash_cd=p.dash_cooldown

		player.dash_dx=player.facing_x
		player.dash_dy=player.facing_y
	end
end

function _dash_update_player()
		player.dash_timer-=1
		
		local d_step=p.dash_speed*8/30
		player.x=mid((m.startx+1)*8,player.x+player.dash_dx*d_step,(m.endx-1)*8)
		player.y=mid((m.starty+1)*8,player.y+player.dash_dy*d_step,(m.endy-1)*8)

		--kill enemies in dash path
		for enemy in all(enemies) do
			if abs(player.x-enemy.x)<8 and abs(player.y-enemy.y)<8 then
				kill_enemy(enemy,true,false)
			end
		end
end

function check_shooting()
	if player.shoot_timer>0 then
		return
	elseif player.rage==0 then
		return
	end
	
	if btnp(🅾️) then
		local dx,dy
		
		if(closest_enemy.dist==nil) then
			dx=1
			dy=0
		else
			dx=closest_enemy.x-player.x
			dy=closest_enemy.y-player.y
			d=sqrt(dx*dx+dy*dy)
			dx/=d
			dy/=d
		end
		
		add(bullets,{
			x=player.x+4,
			y=player.y+4,
			dx=dx*p.bullet_speed*8/30,
			dy=dy*p.bullet_speed*8/30
		})
		player.shoot_timer=p.shoot_delay
		player.rage-=1
	end
end

function update_bullets()
	for b in all(bullets) do
  b.x+=b.dx
  b.y+=b.dy
  
  for en in all(enemies) do
  	if(
  		(b.x-en.x>=-1 and b.x-en.x<=9) and
  		(b.y-en.y>=-1 and b.y-en.y<=9)
  	) then
  		kill_enemy(en,true,true)
  		del(bullets,b)
  		break
  	end
  end
  
  if(b.x<m.startx*8 or
  		 b.x>(m.endx+1)*8 or
  		 b.y<m.starty*8 or
  		 b.y>(m.endy+1)*8) then
  	del(bullets,b)
  end
 end
end

function draw_bullets()
	for b in all(bullets) do
  pset(b.x,b.y,12)
 end
end

function draw_player()
	player.walk_timer-=1
	if player.walk_timer==0 then
		player.sprite_offset+=1
		player.sprite_offset%=4
		player.walk_timer=p.walk_timer
	end
	
	--trail effect when dashing
	if player.dash_timer>0 then
		if player.dash_dy==0 then
			if player.dash_dx>0 then
				spr(3,player.x-8,player.y)
			else
				spr(4,player.x+8,player.y)
			end
		elseif player.dash_dx==0 then
			if player.dash_dy>0 then
				spr(5,player.x,player.y-8)
			else
				spr(6,player.x,player.y+8)
			end
		end
	end

	local flipx=false
	if closest_enemy.dist!=nil then
		if closest_enemy.x<player.x then
			flipx=true
		else
			flipx=false
		end
	end	

	spr(player.sprite+player.sprite_offset, player.x, player.y, 1, 1, flipx)
end

function enrage_player(rage_amount)
	player.rage+=rage_amount
	
	if player.rage>p.max_rage then
		game_over()
	end
end
-->8
--enemy code

function setup_enemy()
	spawn_timer=e.spawn_delay
	enemies={}
	closest_enemy={x=nil,y=nil,dist=nil}
end

function spawn_enemy()
	spawn_timer-=1
	
	if(spawn_timer<=0) then
		spawn_timer=e.spawn_delay
		
		local min_x=(m.startx+1)*8
		local max_x=(m.endx-1)*8
		local min_y=(m.starty+1)*8
		local max_y=(m.endy-1)*8
		
		local ex,ey
		local attempts=20
		-- safety cap to prevent an infinite loop freeze
		
		repeat
			local offset=flr(rnd(544))
			if(offset<136) then
				ex=player.x-72+offset
				ey=player.y-72
			elseif(offset<272) then
				ex=player.x+64
				ey=player.y-72+offset-136
			elseif(offset<408) then
				ex=player.x+64-offset+272
				ey=player.y+64
			else
				ex=player.x-72
				ey=player.y+64-offset+408
			end
			attempts-=1
		until (ex>=min_x and ex<=max_x and ey>=min_y and ey<=max_y) or attempts<=0
		
		if(ex>=min_x and ex<=max_x and ey>=min_y and ey<=max_y) then
			add_enemy(ex,ey)
		end
	end
end

function add_enemy(x,y)
	add(enemies,{x=x,y=y,sprite=12+16*flr(rnd(3)),sprite_offset=0,sprite_timer=10})
end

function update_enemy()
	closest_enemy={x=nil,y=nil,dist=nil}

	for enemy in all(enemies) do
		local dx=player.x-enemy.x+4
		local dy=player.y-enemy.y+4
		local dist=sqrt(dx*dx+dy*dy)

		if(closest_enemy.dist==nil)then
			closest_enemy={x=enemy.x+4,y=enemy.y+4,dist=dist}
		elseif(dist<closest_enemy.dist) then
			closest_enemy={x=enemy.x,y=enemy.y,dist=dist}
		end
		
		--collision distance = 4px
		if dist>4 then
			local step=(e.speed*8)/30
			
			enemy.x+=(dx/dist)*step
			enemy.y+=(dy/dist)*step
		else
			-- if player is currently dashing, kill the enemy instead of taking damage
			if player.dash_timer>0 then
				kill_enemy(enemy,true)
			else
				kill_enemy(enemy,false,true)
			end
		end
	end
end

function draw_enemy()
	for enemy in all(enemies) do
		enemy.sprite_timer-=1
		if enemy.sprite_timer==0 then
			enemy.sprite_offset+=1
			enemy.sprite_offset%=4
			enemy.sprite_timer=10
		end
		
		if enemy.x<player.x then
			spr(enemy.sprite+enemy.sprite_offset,enemy.x,enemy.y,1,1,true)
		else
			spr(enemy.sprite+enemy.sprite_offset,enemy.x,enemy.y)
		end
	end
end

function kill_enemy(target, player_killed, player_enrage)
 if not target then return end

 if player_killed != false then
  player.kills += 1
 end

 if player_enrage != false then
  local dx=(player.x+4) - (target.x+4)
  local dy=(player.y+4) - (target.y+4)
  local dist_sq=dx*dx + dy*dy

  if dist_sq <= 256 then --16 px
   enrage_player(2)
  elseif dist_sq <= 1024 then --32 px
   enrage_player(1)
  end
 end

 del(enemies, target)
end
-->8
--ui code

function update_ui()
end

function draw_ui()
	_draw_dash_indicator()
	
	camera()
	_draw_rage_bar()
	print("="..player.kills,60,4,7)
	spr(48,51,2)
end

function _draw_rage_bar()
	-- 2. bar dimensions and position
	local bx = 34  -- start x
 local by = 121 -- start y (near bottom)
 local bw = 60  -- total bar width in pixels
 local bh = 4   -- bar height in pixels

 -- 3. calculate fill width clamped between 0 and bw
 local fill_pct = mid(0, player.rage / p.max_rage, 1)
 local fill_w = flr(fill_pct * bw)

 -- 4. draw background (dark gray/maroon 5) and border (dark purple 1 or white 7)
 if fill_pct<0.80 then
	 rectfill(bx, by, bx + bw, by + bh, 1) -- deep blue background
	else
		rectfill(bx, by, bx + bw, by + bh, 9)  -- deep pink background inside
	end
 
 -- 5. draw active rage fill (red 8 or orange 9)
 if fill_w > 0 then
		rectfill(bx, by, bx + fill_w, by + bh, 8)
 end

 -- 6. outline border (color 5 or 6)
 rect(bx - 1, by - 1, bx + bw + 1, by + bh + 1, 5)

 -- optional: label next to or above the bar
 print("rage", bx - 18, by, 7)                 -- 3x5 text fits right beside it
end

function _draw_dash_indicator()
 -- only draw when the dash is currently recharging
 if player.dash_cd > 0 then
  local by = player.y + 9  -- 1 pixel below the 8x8 sprite
  local bw = 7            -- spans 8 pixels wide (matching sprite width)

  -- progress ratio from 0 to 1 as cooldown recovers
  local fill_w = flr((1 - player.dash_cd / p.dash_cooldown) * bw)

  -- 2px-thick background track (dark gray 5 or black 0)
  rectfill(player.x, by, player.x + bw, by, 0)

  -- 2px-thick active fill (bright cyan 11 or yellow 10)
  if fill_w > 0 then
   rectfill(player.x, by, player.x + fill_w, by, 11)
  end
 end
end
-->8
-- welcome / title screen code

function update_welcome()
 -- press ❎ (x key) to start the game
 if btnp(❎) then
  g.state = 1
 end
end

function draw_welcome()
 camera() -- reset camera to screen coordinates (0..127)

 -- 1. game title ("\^w\^t" doubles font width and height)
 -- "wraith" is 6 chars * 8px = 48px wide -> centered at x = 40
 print("\^w\^twraith", 40, 28, 8) -- red title

 -- 2. subtitle
 -- 31 characters * 4px = 124px wide -> centered at x = 2
 print("do not let the wrath", 24, 48, 5) -- dark gray/maroon
 print("consume you", 42, 54, 5)

 -- decorative divider line
 line(16, 62, 112, 62, 1)

 -- 3. controls guide
 print("controls:", 48, 70, 6)
 print("❎ to fire", 44, 80, 7)
 print("🅾️ to dash", 44, 90, 7)

 -- 4. flashing start prompt
 if time() % 1 < 0.6 then
  print("press ❎ to start", 30, 110, 10) -- flashing yellow
 end
end
-->8
--todo

--x.improve config and setup files
--2.fix movement jitter
--3.improve enemy spawn logic
--4.add enemy kill logic
--5.add player kill logic
--6.smoothen bullet movement
__gfx__
00000000011110000111000000700000000007000000700000707070000000000000000000000000000000000000000000000000000000000077770000777700
00000000001111001011100000077777777770007770700000707070000000000000000000000000000000000000000000000000007777000777777000777700
00700700111111110011110000000000000000007070700700707070000000000000000000000000000000000000000000777700077777700876877008768770
000770000f0ff0001111111177777777777777777070707000707070000000000000000000000000000000000000000007777770087687700757776008768770
00077000011111cc0f0ff0c000000000000000000070707070707070000000000000000000000000000000000000000008768770087687700077660008568770
007007001111111c0111111c07777777777777700070707070707007000000000000000000000000000000000000000008768770075777600077600007577760
00000000011111001111110c07000000000000700070707077707000000000000000000000000000000000000000000007577760007766000000000000776600
00000000010001000111110007770000000077700070707000007000000000000000000000000000000000000000000000776600007760000000000000776000
00000000060060000066666600000000060060000006006000000000000000000000000000000000000000000000000000007770000777000777000007777000
00006000666666000006006000000000666666000066666600000000000000000000000000000000000000000000000000077776007777607777700077777700
06066606060060000066666606000000060060000006006000000060000000000000000000000000000000000000000000077776007777607777700077777700
66666666666666000666666666660000666666000066666600006666000000000000000000000000000000000000000007087786708778608878800087787600
06066606666666600066666606066000066060000006066000066060000000000000000000000000000000000000000000770767077077667007600070076600
0606660666666600000600600600600006066000000660600006006000000000000000000000000000000000000000000007076d007776d6677d660070076660
6666666606006000006666666666660066660000000066660066666600000000000000000000000000000000000000000007766000077660d776d00007776d00
06066606666666000006006006006000060000000000006000060060000000000000000000000000000000000000000000077660000066660066666000666600
00000000000000000000000000010000000000000003b0000000000000000000000000000000000000000000000000000000000000bbbb0000bbbb0000bbbb00
00100000001000000000000000000000010000100003000000000000000000000000000000000000000000000000000000bbbb00bbbbbbbbbb8b8bbbbb8b8bbb
000000000000010000000100010001000000000009aaaa90000000000000000000000000000000000000000000000000bb8b8bbb0b8b8bb00bbbbbb00b8b8bb0
0000010001000000001000000000000000000000909aa9090000000000000000000000000000000000000000000000000b8b8bb000b2bb0000b22b0000b2bb00
01000000000000000000000000000000000000009009900900000000000000000000000000000000000000000000000000b2bb0000b2bb0000b22b0000b2bb00
0000000000000000001001000001001000000000a999999a00000000000000000000000000000000000000000000000003bbbbb003bbbbb000bbbb0000bbbb00
00000100010001000000000001000000000100009900009a0000000000000000000000000000000000000000000000003022220b032222b0002222000022b200
00000000000000000000000000000100000000000a09909000000000000000000000000000000000000000000000000000b00300000b30000003b00000300b00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110001111100000000000
00fffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111100000111001011110000011110
0fffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100001111000111111100111110
0f11f11f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111111111110080800011111111
0f11f11f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080880cc080880cc011111cc008080c0
0f17f17f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111c0111111c0111111c011111cc
00fffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111110c0111110c0111110c0111111c
00f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111000111110c0111110c01111100
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd


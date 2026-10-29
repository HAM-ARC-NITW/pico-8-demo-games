pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- lustydusty: levels 1 & 2
-- the sin of lust

function _init()
  level = 1
  game_state = "title"

  -- sinner (player)
  p = {
    x = 36, y = 64,
    spd = 1.1,
    facing_x = 1, facing_y = 0,
    state = "stand",
    hp = 3,
    invuln = 0,
    shoot_cd = 0,
    shoot_rate = 7,
    ammo = 8,
    max_ammo = 8,
    reloading = 0,
    reload_time = 15,
    has_key = false
  }


  gf = {
    x = 24, y = 64,
    hp = 3,
    invuln = 0,
    attached = true,
    facing_x = 1,
    state = "stand"
  }

  -- round 1 sirens
  sirens = {
    {type = "a", base_x = 140, base_y = 26, x = 140, y = 26, off = 0},
    {type = "c", base_x = 154, base_y = 20, x = 154, y = 20, off = 3.14}
  }

  -- round 1 switch & door
  sw_x1 = 12 * 8
  sw_y1 = 12 * 8
  sw_x2 = 15 * 8
  sw_y2 = 14 * 8
  switch_active = false
  door_open = false
  set_door(false)
  set_switch(false)

  -- round 2 variables
  r2_state = "intro"
  r2_timer = 0
  souls = 0
  souls_needed = 15
  chest_open = false
  door_a_open = false
  door_b_open = false
  chosen_door = nil
  seduce_siren = nil
  witch = nil
  flash_fx = 0
  dark_bolts = {}
  souls_items = {}
  killed_by_witch = false

  -- combat entities
  ghosts = {}
  flames = {}
  particles = {}
  spawn_timer = 0
  spawn_rate = 14

  cam_x = 0
  cam_y = 0
  music(0)
end

function start_level_2()
  level = 2
  p.x = 268
  p.y = 112
  p.facing_x = 0
  p.facing_y = -1
  p.ammo = p.max_ammo
  p.reloading = 0
  p.has_key = false

  r2_state = "intro"
  r2_timer = 70
  souls = 0
  chest_open = false
  door_a_open = false
  door_b_open = false
  chosen_door = nil
  witch = nil
  flash_fx = 0
  killed_by_witch = false

  set_r2_door("a", false)
  set_r2_door("b", false)
  mset(33, 8, 26) -- closed chest

  -- sirens run to their doors
  siren_a = {x = 260, y = 96, spr = 0}
  siren_b = {x = 276, y = 96, spr = 32}

  ghosts = {}
  flames = {}
  dark_bolts = {}
  souls_items = {}
  particles = {}
end

function set_door(open)
		if open and not door_open then sfx(7) end
  door_open = open
  local dt = open and {6, 7, 22, 23, 38, 39} or {8, 9, 24, 25, 40, 41}
  mset(18, 3, dt[1]) mset(19, 3, dt[2])
  mset(18, 4, dt[3]) mset(19, 4, dt[4])
  mset(18, 5, dt[5]) mset(19, 5, dt[6])
end

function set_r2_door(door_id, open)
  local dt = open and {6, 7, 22, 23, 38, 39} or {8, 9, 24, 25, 40, 41}
  if door_id == "a" then
  		if open and not door_a_open then sfx(7) end
    door_a_open = open
    mset(27, 2, dt[1]) mset(28, 2, dt[2])
    mset(27, 3, dt[3]) mset(28, 3, dt[4])
    mset(27, 4, dt[5]) mset(28, 4, dt[6])
  else
  		if open and not door_b_open then sfx(7) end
  		door_b_open = open
    mset(38, 2, dt[1]) mset(39, 2, dt[2])
    mset(38, 3, dt[3]) mset(39, 3, dt[4])
    mset(38, 4, dt[5]) mset(39, 4, dt[6])
  end
end

function set_switch(pressed)
  switch_active = pressed
  local sw_tile = pressed and 37 or 21
  mset(13, 12, sw_tile)
  mset(13, 13, sw_tile)
end

function is_solid(x, y)
  local tx = flr(x / 8)
  local ty = flr(y / 8)
  if level == 1 then
    if tx < 0 or tx > 21 or ty < 0 or ty > 15 then return true end
  else
    if tx < 24 or tx > 42 or ty < 0 or ty > 15 then return true end
  end

  local tile = mget(tx, ty)
  if tile == 118 or tile == 12 or tile == 10 or tile == 13 then return true end
  if tile == 26 and not chest_open then return true end

  -- round 1 gate
  if level == 1 and not door_open and (tile == 8 or tile == 9 or tile == 24 or tile == 25 or tile == 40 or tile == 41) then
    return true
  end

  -- round 2 doors
  if level == 2 then
    if not door_a_open and (tx == 27 or tx == 28) and (ty >= 2 and ty <= 4) then return true end
    if not door_b_open and (tx == 38 or tx == 39) and (ty >= 2 and ty <= 4) then return true end
  end

  return false
end

function move_char(e, dx, dy)
  if dx != 0 then
    local test_x = (dx > 0) and (e.x + 3 + dx) or (e.x - 3 + dx)
    if not is_solid(test_x, e.y - 1) and not is_solid(test_x, e.y + 3) then
      e.x += dx
    end
  end
  if dy != 0 then
    local test_y = (dy > 0) and (e.y + 4 + dy) or (e.y - 2 + dy)
    if not is_solid(e.x - 2, test_y) and not is_solid(e.x + 2, test_y) then
      e.y += dy
    end
  end
end

function _update()
  if flash_fx > 0 then flash_fx -= 1 end

  if game_state == "title" then
    if btnp(4) then sfx(10) game_state = "banner_r1" end
    return
  elseif game_state == "banner_r1" then
    if btnp(4) then sfx(10) game_state = "play" end
    return
  elseif game_state == "banner_r2" then
    if btnp(4) then sfx(10) game_state = "play" end
    return
  elseif game_state != "play" then
    if btnp(4) then sfx(10) _init() end
    return
  end

  -- ================= LEVEL 1 =================
  if level == 1 then
    update_level_1()
  else
    update_level_2()
  end
end

function update_level_1()
  -- 1. player input & movement
  local dx, dy = 0, 0
  if btn(0) then dx -= 1 end
  if btn(1) then dx += 1 end
  if btn(2) then dy -= 1 end
  if btn(3) then dy += 1 end

  if dx != 0 or dy != 0 then
    p.facing_x = dx
    p.facing_y = dy
    p.state = (dy < 0) and "up" or "run"
  else
    p.state = "stand"
  end

  move_char(p, dx * p.spd, dy * p.spd)

  if p.invuln > 0 then p.invuln -= 1 end
  if gf.invuln > 0 then gf.invuln -= 1 end

  -- 2. reload cooldown
  if p.reloading > 0 then
    p.reloading -= 1
    if p.reloading <= 0 then p.ammo = p.max_ammo end
  end

   if gf.attached then
    local g_dx = p.x - gf.x
    local g_dy = p.y - gf.y
    local dist = abs(g_dx) + abs(g_dy)
    if dist > 11 then
      local mx = (abs(g_dx) > 6) and sgn(g_dx) * 1.0 or 0
      local my = (abs(g_dy) > 6) and sgn(g_dy) * 1.0 or 0
      move_char(gf, mx, my)
      if mx != 0 then gf.facing_x = mx end
      gf.state = (my < 0) and "up" or "run"
    else
      gf.state = "stand"
    end

    if btnp(4) then sfx(5) gf.attached = false end
  else
    gf.state = "stand"
    local dist = abs(p.x - gf.x) + abs(p.y - gf.y)
    if dist < 12 and btnp(4) then sfx(5) gf.attached = true end
  end


  local p_on_sw = (p.x >= sw_x1 and p.x <= sw_x2 and p.y >= sw_y1 and p.y <= sw_y2)
  local gf_on_sw = (gf.x >= sw_x1 and gf.x <= sw_x2 and gf.y >= sw_y1 and gf.y <= sw_y2)
  local on_switch = p_on_sw or gf_on_sw

  if on_switch then
    if not switch_active then
    		sfx(4)
      set_switch(true)
      set_door(true)
    end
  else
    if switch_active then
      set_switch(false)
      set_door(false)
    end
  end

   if door_open and p.x >= 140 and p.x <= 164 and p.y <= 42 then
    start_level_2()
    game_state = "banner_r2"
    return
  end

  -- sirens hovering near door
  for s in all(sirens) do
    local t = time() * 1.5 + s.off
    s.x = s.base_x + cos(t * 0.4) * 10
    s.y = s.base_y + sin(t * 0.6) * 7
  end

  handle_shooting()
  update_ghosts(p.x, p.y, gf.x, gf.y, gf.attached)

  cam_x = mid(0, flr(p.x - 60), 48)
  cam_y = 0
end

function update_level_2()
  if r2_state == "intro" then
    r2_timer -= 1
    siren_a.x += (224 - siren_a.x) * 0.08
    siren_a.y += (24 - siren_a.y) * 0.08
    siren_b.x += (304 - siren_b.x) * 0.08
    siren_b.y += (24 - siren_b.y) * 0.08

    if r2_timer <= 0 then
      r2_state = "play"
      set_r2_door("a", false)
      set_r2_door("b", false)
    end
    cam_x = mid(192, flr(p.x - 60), 216)
    cam_y = 0
    return
  end

  if r2_state == "seduce" then
    r2_timer -= 1
    seduce_siren.y += (p.y - 8 - seduce_siren.y) * 0.05
    seduce_siren.x += (p.x - seduce_siren.x) * 0.05

    if rnd(4) < 1 then
      add(particles, {x = seduce_siren.x + rnd(6)-3, y = seduce_siren.y + rnd(6)-3, col = 12, life = 14, vy = -0.3})
    end


    if r2_timer <= 0 then
      r2_state = "transform"
      r2_timer = 150 -- 5 seconds gap before killing sinner!
    		sfx(8)
    end
    return
  end

  if r2_state == "transform" then
    r2_timer -= 1

    if rnd(3) < 1 then
      add(particles, {x = p.x + rnd(10)-5, y = p.y + rnd(10)-5, col = 8, life = 10, vy = -0.2})
      add(particles, {x = seduce_siren.x + rnd(12)-6, y = seduce_siren.y + rnd(12)-6, col = 12, life = 12, vy = -0.3})
    end

    if r2_timer <= 0 then
      flash_fx = 20 -- screen flash
      p.hp = 0
      p.state = "dead"
      game_state = "p_dead"
      killed_by_witch = true
      music(-1)
    		sfx(9)
    end
    return
  end

  local dx, dy = 0, 0
  if btn(0) then dx -= 1 end
  if btn(1) then dx += 1 end
  if btn(2) then dy -= 1 end
  if btn(3) then dy += 1 end

  if dx != 0 or dy != 0 then
    p.facing_x = dx
    p.facing_y = dy
    p.state = (dy < 0) and "up" or "run"
  else
    p.state = "stand"
  end

  move_char(p, dx * p.spd, dy * p.spd)

  if p.invuln > 0 then p.invuln -= 1 end

  if p.reloading > 0 then
    p.reloading -= 1
    if p.reloading <= 0 then p.ammo = p.max_ammo end
  end

  handle_shooting()

  -- souls pickup collection
  for s in all(souls_items) do
    s.life -= 1
    if abs(p.x - s.x) < 8 and abs(p.y - s.y) < 8 then
      souls += 1
      del(souls_items, s)
      sfx(2)
      for i = 1, 4 do
        add(particles, {x = s.x, y = s.y, col = 12, life = 8, vy = -0.3})
      end
    elseif s.life <= 0 then
      del(souls_items, s)
    end
  end

  if souls >= souls_needed and not p.has_key and not chest_open then
    if abs(p.x - 264) < 14 and abs(p.y - 64) < 14 and btnp(4) then
      chest_open = true
      p.has_key = true
      sfx(6)
      mset(33, 8, 27) -- open chest sprite

      for g in all(ghosts) do
        for i = 1, 3 do
          add(particles, {x = g.x, y = g.y, col = 14, life = 10, vy = -0.3})
        end
      end
      ghosts = {}
      for i = 1, 10 do
        add(particles, {x = 264 + rnd(10) - 5, y = 64 + rnd(10) - 5, col = 10, life = 14, vy = -0.4})
      end
    end
  end

  -- unlock Door A
  if p.has_key then
    -- door a
    if abs(p.x - 224) < 16 and abs(p.y - 32) < 16 and btnp(4) then
      p.has_key = false
      chosen_door = "a"
      set_r2_door("a", true)
      sfx(7)
      r2_state = "seduce"
      r2_timer = 60
      seduce_siren = {x = 224, y = 20, spr = 0}
    -- door b
    elseif abs(p.x - 304) < 16 and abs(p.y - 32) < 16 and btnp(4) then
      p.has_key = false
      chosen_door = "b"
      set_r2_door("b", true)
      sfx(7)
      r2_state = "seduce"
      r2_timer = 60
      seduce_siren = {x = 304, y = 20, spr = 32}
    end
  end

  if r2_state == "play" then
    local t = time() * 1.5
    siren_a.x = 224 + cos(t * 0.4) * 4
    siren_a.y = 28 + sin(t * 0.6) * 3
    siren_b.x = 304 + cos(t * 0.4 + 3.14) * 4
    siren_b.y = 28 + sin(t * 0.6 + 3.14) * 3

    if rnd(15) < 1 then
      add(particles, {x = siren_a.x + rnd(8)-4, y = siren_a.y + rnd(6)-3, col = 14, life = 14, vy = -0.3})
    end
    if rnd(15) < 1 then
      add(particles, {x = siren_b.x + rnd(8)-4, y = siren_b.y + rnd(6)-3, col = 14, life = 14, vy = -0.3})
    end

    if not p.has_key and not chest_open then
      update_ghosts(p.x, p.y, p.x, p.y, true)
    end
  elseif r2_state == "witch_boss" and witch then
    update_witch_boss()
  end

  cam_x = mid(192, flr(p.x - 60), 216)
  cam_y = 0
end

function handle_shooting()
  if p.shoot_cd > 0 then p.shoot_cd -= 1 end

  if btn(5) and p.shoot_cd <= 0 and p.reloading <= 0 then
    if p.ammo > 0 then
      p.ammo -= 1
      p.shoot_cd = p.shoot_rate
      if p.ammo <= 0 then p.reloading = p.reload_time end

      local target_x, target_y = nil, nil
      local min_dist = 90

      if level == 2 and r2_state == "witch_boss" and witch then
        target_x = witch.x
        target_y = witch.y
      else
        for g in all(ghosts) do
          local d = abs(g.x - p.x) + abs(g.y - p.y)
          if d < min_dist then
            min_dist = d
            target_x = g.x
            target_y = g.y
          end
        end
      end

      local f_dx, f_dy = 0, 0
      if target_x != nil then
        local ang = atan2(target_x - p.x, target_y - p.y)
        f_dx = cos(ang) * 3.4
        f_dy = sin(ang) * 3.4
      else
        local len = sqrt(p.facing_x^2 + p.facing_y^2)
        f_dx = (len > 0) and ((p.facing_x / len) * 3.4) or 3.4
        f_dy = (len > 0) and ((p.facing_y / len) * 3.4) or 0
      end

      add(flames, {x = p.x, y = p.y, dx = f_dx, dy = f_dy, life = 26})
   			sfx(0)
    end
  end

  for f in all(flames) do
    f.x += f.dx
    f.y += f.dy
    f.life -= 1
    if rnd(2) < 1 then
      add(particles, {x = f.x, y = f.y, col = flr(rnd(3)) + 8, life = 6, vy = 0})
    end
    if is_solid(f.x, f.y) or f.life <= 0 then del(flames, f) end
  end

  for prt in all(particles) do
    prt.life -= 1
    if prt.vy then prt.y += prt.vy end
    if prt.life <= 0 then del(particles, prt) end
  end
end

function update_ghosts(tx1, ty1, tx2, ty2, gf_safe)
  spawn_timer += 1
  if spawn_timer > spawn_rate and #ghosts < 18 then
    spawn_timer = 0
    local sx, sy = 0, 0
    local side = flr(rnd(4))
    if level == 1 then
      if side == 0 then sx = 10 sy = flr(rnd(90)) + 20
      elseif side == 1 then sx = 160 sy = flr(rnd(50)) + 40
      elseif side == 2 then sx = flr(rnd(100)) + 20 sy = 18
      else sx = flr(rnd(100)) + 20 sy = 110 end
    else
      if side == 0 then sx = 202 sy = flr(rnd(80)) + 20
      elseif side == 1 then sx = 330 sy = flr(rnd(80)) + 20
      elseif side == 2 then sx = flr(rnd(100)) + 215 sy = 18
      else sx = flr(rnd(100)) + 215 sy = 110 end
    end

    local is_fast = (rnd(4) < 1)
    add(ghosts, {
      x = sx, y = sy,
      hp = is_fast and 1 or 2,
      spd = is_fast and (1.3 + rnd(0.2)) or (0.9 + rnd(0.25)),
      is_fast = is_fast,
      seed = rnd(10)
    })
  end

  for g in all(ghosts) do
    local target_x, target_y = tx1, ty1
    if level == 1 and not gf_safe then
      if abs(g.x - tx2) + abs(g.y - ty2) < abs(g.x - tx1) + abs(g.y - ty1) then
        target_x, target_y = tx2, ty2
      end
    end

    local ang = atan2(target_x - g.x, target_y - g.y)
    g.x += cos(ang) * g.spd
    g.y += sin(ang) * g.spd

    for f in all(flames) do
      if abs(g.x - f.x) < 6 and abs(g.y - f.y) < 6 then
        g.hp -= 1
        g.x += f.dx * 1.5
        g.y += f.dy * 1.5
        del(flames, f)

        for i = 1, 4 do
          add(particles, {x = g.x, y = g.y, col = flr(rnd(3)) + 8, life = 8, vy = -0.2})
        end

        if g.hp <= 0 then
        		sfx(1)
          if level == 2 and r2_state == "play" then
            add(souls_items, {x = g.x, y = g.y, life = 450})
          end
          del(ghosts, g)
        end
      end
    end

    if p.invuln <= 0 and abs(g.x - p.x) < 5 and abs(g.y - p.y) < 5 then
      p.hp -= 1
      p.invuln = 30
      del(ghosts, g)
      sfx(3)
      if p.hp <= 0 then
        p.state = "dead"
        game_state = "p_dead"
        killed_by_witch = false
        music(-1)
        sfx(11)
      end
    end

    if level == 1 and gf.invuln <= 0 and abs(g.x - gf.x) < 5 and abs(g.y - gf.y) < 5 then
      gf.hp -= 1
      gf.invuln = 30
      del(ghosts, g)
      if gf.hp <= 0 then game_state = "gf_dead" music(-1) sfx(11) end
    end
  end
end

function update_witch_boss()
  if not witch then return end
  if witch.invuln > 0 then witch.invuln -= 1 end

  local ang = atan2(p.x - witch.x, p.y - witch.y)
  witch.x += cos(ang) * witch.spd + sin(time() * 3) * 0.8
  witch.y += sin(ang) * witch.spd + cos(time() * 3) * 0.8

  witch.atk_cd += 1
  if witch.atk_cd > 40 then
    witch.atk_cd = 0
    local b_ang = atan2(p.x - witch.x, p.y - witch.y)
    add(dark_bolts, {x = witch.x, y = witch.y, dx = cos(b_ang) * 2.2, dy = sin(b_ang) * 2.2, life = 50})
  end

  for b in all(dark_bolts) do
    b.x += b.dx
    b.y += b.dy
    b.life -= 1
    if p.invuln <= 0 and abs(b.x - p.x) < 5 and abs(b.y - p.y) < 5 then
      p.hp -= 1
      p.invuln = 30
      del(dark_bolts, b)
      sfx(3)
      if p.hp <= 0 then
        p.state = "dead"
        game_state = "p_dead"
        killed_by_witch = true
      		music(-1)
      		sfx(11)
      end
    elseif b.life <= 0 then
      del(dark_bolts, b)
      sfx(3)
    end
  end

  for f in all(flames) do
    if abs(witch.x - f.x) < 8 and abs(witch.y - f.y) < 8 then
      witch.hp -= 1
      witch.invuln = 10
      del(flames, f)
      sfx(1)
      for i = 1, 6 do
        add(particles, {x = witch.x, y = witch.y, col = 8, life = 10, vy = -0.3})
      end
      if witch.hp <= 0 then
        -- victory!
        game_state = "won_game"
        music(-1)
        sfx(6)
      end
    end
  end

  if p.invuln <= 0 and abs(witch.x - p.x) < 7 and abs(witch.y - p.y) < 7 then
    p.hp -= 1
    p.invuln = 30
    if p.hp <= 0 then
      p.state = "dead"
      game_state = "p_dead"
      killed_by_witch = true
      music(-1)
      sfx(11)
    end
  end
end

function _draw()
  if flash_fx > 0 then
    cls((flash_fx % 2 == 0) and 7 or 14)
    return
  end

  if game_state == "title" then
    camera(0, 0)
    draw_title()
    return
  elseif game_state == "banner_r1" then
    camera(0, 0)
    draw_banner_r1()
    return
  elseif game_state == "banner_r2" then
    camera(0, 0)
    draw_banner_r2()
    return
  end

  cls(0)

  camera(cam_x, cam_y)

  map(0, 0, 0, 0, 44, 16)

  if level == 1 then
    draw_level_1()
  else
    draw_level_2()
  end

  -- flames
  for f in all(flames) do spr(20, f.x - 4, f.y - 4) end

  -- particles
  for prt in all(particles) do pset(prt.x, prt.y, prt.col) end

  for g in all(ghosts) do
    local float_y = g.y + sin(time() * 2 + g.seed) * 2
    spr(4, g.x - 4, float_y - 4)
    if g.is_fast then
      pset(g.x - 1, float_y - 2, 8)
      pset(g.x + 1, float_y - 2, 8)
    end
  end

  if p.state == "dead" or p.hp <= 0 then
    spr(52, p.x - 4, p.y - 4, 1, 1, p.facing_x < 0)
    pset(p.x - 6, p.y + 3, 8) pset(p.x - 5, p.y + 2, 8)
    pset(p.x + 5, p.y + 3, 8) pset(p.x + 6, p.y + 2, 8)
  else
    local p_spr = 48
    local p_flip = (p.facing_x < 0)
    if p.state == "stand" then p_spr = 48
    elseif p.state == "run" then p_spr = (flr(time() * 8) % 2 == 0) and 48 or 49
    elseif p.state == "up" then p_spr = (flr(time() * 8) % 2 == 0) and 50 or 51 end
    if p.invuln % 4 < 2 then spr(p_spr, p.x - 4, p.y - 4, 1, 1, p_flip) end
  end

  camera(0, 0)
  draw_hud()

  if game_state == "won_game" then
    rectfill(10, 36, 118, 92, 0)
    rect(10, 36, 118, 92, 10)
    print("witch vanquished!", 24, 44, 10)
    print("you broke the curse of lust!", 8, 56, 7)
    print("you survived the sirens!", 12, 66, 14)
    print("press z to play again", 20, 78, 6)
  elseif game_state == "p_dead" then

    if killed_by_witch then
      rectfill(0, 3, 128, 29, 0)
      rect(0, 3, 128, 29, 8)
      line(0, 4, 128, 4, 8)
      line(0, 28, 128, 28, 8)
      print("game over", 46, 6, 8)
      print("the sinner must die", 26, 13, 8)
      print("press z to replay", 30, 21, 7)
    else
      rectfill(0, 3, 128, 22, 0)
      rect(0, 3, 128, 22, 8)
      line(0, 4, 128, 4, 8)
      line(0, 21, 128, 21, 8)
      print("game over", 46, 6, 8)
      print("press z to retry", 32, 14, 7)
    end
  elseif game_state == "gf_dead" then
    rectfill(16, 44, 112, 84, 0)
    rect(16, 44, 112, 84, 8)
    print("your gf was killed!", 24, 52, 8)
    print("the gate locked forever.", 18, 62, 7)
    print("press z to retry", 28, 72, 6)
  end
end

function draw_level_1()
  for s in all(sirens) do
    local spr_id = (s.type == "a") and 0 or 32
    spr(spr_id, s.x - 4, s.y - 4)
    print("~come~", s.x - 10, s.y - 11, 10)
  end

  -- gf
  local gf_spr = 16
  local gf_flip = (gf.facing_x < 0)
  if gf.state == "stand" then gf_spr = 16
  elseif gf.state == "run" then gf_spr = (flr(time() * 8) % 2 == 0) and 16 or 17
  elseif gf.state == "up" then gf_spr = (flr(time() * 8) % 2 == 0) and 18 or 19 end
  if gf.invuln % 4 < 2 then spr(gf_spr, gf.x - 4, gf.y - 4, 1, 1, gf_flip) end
end

function draw_level_2()
  for s in all(souls_items) do
    spr(15, s.x - 4, s.y - 4)
  end

  for b in all(dark_bolts) do
    circfill(b.x, b.y, 2, 8)
  end

  if r2_state == "intro" then
    spr(siren_a.spr, siren_a.x - 4, siren_a.y - 4)
    spr(siren_b.spr, siren_b.x - 4, siren_b.y - 4)
    print("~catch us!~", siren_a.x - 14, siren_a.y - 10, 10)
  elseif r2_state == "play" then
    spr(siren_a.spr, siren_a.x - 4, siren_a.y - 4)
    spr(siren_b.spr, siren_b.x - 4, siren_b.y - 4)


    local cyc = flr(time() * 0.4) % 3
    local txt_a = "~open me!~"
    local txt_b = "~pick me!~"
    if cyc == 0 then
      txt_a = "~open me!~"
      txt_b = "~pick me!~"
    elseif cyc == 1 then
      txt_a = "~pure bliss~"
      txt_b = "~ecstasy~"
    else
      txt_a = "~satisfy me~"
      txt_b = "~pleasure~"
    end
    if p.has_key then
      txt_a = "~unlock me!~"
      txt_b = "~satisfaction~"
    end
    print(txt_a, siren_a.x - 14, siren_a.y - 9, 10)
    print(txt_b, siren_b.x - 14, siren_b.y - 9, 10)
  elseif r2_state == "seduce" and seduce_siren then
    spr(seduce_siren.spr, seduce_siren.x - 4, seduce_siren.y - 4)
    print("~satisfaction...~", seduce_siren.x - 16, seduce_siren.y - 10, 10)
  elseif r2_state == "transform" or (game_state == "p_dead" and level == 2 and seduce_siren) then
    local w_spr = (flr(time() * 6) % 2 == 0) and 29 or 30

    circfill(seduce_siren.x, seduce_siren.y, 8, 0)
    circ(seduce_siren.x, seduce_siren.y, 8, 8)
    spr(w_spr, seduce_siren.x - 4, seduce_siren.y - 4)

    if r2_state == "transform" then

      rectfill(seduce_siren.x - 24, seduce_siren.y - 24, seduce_siren.x + 24, seduce_siren.y - 9, 0)
      rect(seduce_siren.x - 24, seduce_siren.y - 24, seduce_siren.x + 24, seduce_siren.y - 9, 8)
      print("\^w\^tFOOL!", seduce_siren.x - 20, seduce_siren.y - 22, 8)
    end
  elseif r2_state == "witch_boss" and witch then
    local w_spr = (flr(time() * 6) % 2 == 0) and 29 or 30
    spr(w_spr, witch.x - 4, witch.y - 4)
    -- boss health bar
    rectfill(witch.x - 8, witch.y - 8, witch.x + 8, witch.y - 6, 0)
    local hp_w = (witch.hp / witch.max_hp) * 16
    rectfill(witch.x - 8, witch.y - 8, witch.x - 8 + hp_w, witch.y - 6, 8)
  end
end

function draw_hud()
  -- player hearts
  print("p:", 2, 2, 7)
  for i = 1, 3 do
    local col = (i <= p.hp) and 8 or 5
    print("♥", 6 + i * 6, 2, col)
  end

  if level == 1 then
    print("gf:", 32, 2, 12)
    for i = 1, 3 do
      local col = (i <= gf.hp) and 12 or 5
      print("♥", 40 + i * 6, 2, col)
    end
    if gf.attached then print("z:drop", 104, 2, 6) else print("z:pick", 104, 2, 6) end
  else
    -- round 2 HUD
    local soul_col = (souls >= souls_needed) and 11 or 12
    print("souls:" .. souls .. "/" .. souls_needed, 32, 2, soul_col)
    if p.has_key then
      spr(28, 92, 1)
      print("key!", 102, 2, 10)
    elseif souls >= souls_needed and not chest_open then
      print("chest(z)!", 88, 2, 10)
    end
  end

end

function draw_title()
  cls(0)

  rect(3, 3, 124, 124, 5)
  rect(5, 5, 122, 122, 1)


  spr(20, 8, 8)
  spr(20, 112, 8)
  spr(20, 8, 112)
  spr(20, 112, 112)


  local sy_a = 16 + sin(time() * 0.5) * 3
  local sy_b = 16 + cos(time() * 0.5) * 3
  spr(0, 10, sy_a)
  spr(32, 110, sy_b, 1, 1, true, false)

  print("\^w\^tLUSTYDUSTY", 25, 17, 8)
  print("\^w\^tLUSTYDUSTY", 24, 16, 14)

  print("♥", 18, 31, 8)
  print("~ TEMPLE OF DESIRE ~", 25, 31, 10)
  print("♥", 104, 31, 8)

  -- play button box
  rectfill(36, 43, 92, 59, 1)
  rect(36, 43, 92, 59, 7)
  line(37, 44, 91, 44, 10)
  local p_col = (flr(time() * 4) % 2 == 0) and 10 or 7
  print("▶  PLAY  ◀", 44, 48, p_col)
  print("press z to play", 34, 63, 6)

  -- controls guide box
  rectfill(12, 73, 115, 117, 1)
  rect(12, 73, 115, 117, 5)
  rectfill(40, 70, 87, 78, 0)
  rect(40, 70, 87, 78, 5)
  print("CONTROLS", 47, 72, 10)

  spr(48, 18, 84)
  print("x : shoot fire", 32, 85, 7)

  spr(16, 18, 98)
  print("z : pick / drop objects", 32, 98, 7)
end

function draw_banner_r1()
  cls(0)
  rect(3, 3, 124, 124, 5)
  rect(5, 5, 122, 122, 1)

  spr(20, 8, 8)
  spr(20, 112, 8)
  spr(20, 8, 112)
  spr(20, 112, 112)

  rectfill(32, 12, 95, 25, 0)
  rect(32, 12, 95, 25, 10)
  print("~ PROLOGUE ~", 40, 16, 10)

  rectfill(10, 32, 117, 98, 0)
  rect(10, 32, 117, 98, 7)
  rect(12, 34, 115, 96, 5)

  spr(48, 18, 40)
  spr(16, 102, 40)

  print("\"lust is good or bad?", 20, 52, 7)
  print(" my views: good,", 20, 64, 14)
  print(" but you figure out...\"", 20, 76, 10)

  local pcol = (flr(time() * 4) % 2 == 0) and 11 or 7
  print("press z to begin", 32, 106, pcol)
end

function draw_banner_r2()
  cls(0)
  rect(3, 3, 124, 124, 5)
  rect(5, 5, 122, 122, 1)

  spr(20, 8, 8)
  spr(20, 112, 8)

  rectfill(34, 10, 93, 23, 0)
  rect(34, 10, 93, 23, 11)
  print("~ ROUND 2 ~", 42, 14, 11)

  rectfill(10, 28, 117, 104, 0)
  rect(10, 28, 117, 104, 12)
  rect(12, 30, 115, 102, 1)

  spr(26, 26, 36)
  print("+", 42, 38, 7)
  spr(15, 56, 36)
  print("->", 72, 38, 7)
  spr(28, 92, 36)

  print("to open a chest,", 28, 52, 7)
  print("you need 15 souls.", 26, 62, 11)
  print("inside the chest,", 27, 74, 7)
  print("there is a key to", 27, 84, 10)
  print("open the door!", 36, 92, 10)

  local pcol = (flr(time() * 4) % 2 == 0) and 10 or 7
  print("press z to enter", 32, 111, pcol)
end

__gfx__
00000000088888880000000000000000007777000000000030000000000000033000000000000003000800002a8888a2007770000055000000000000001cc100
08888888888899980008880000088800077777700000000001111106601111100111110660111110008980002a8888a2077677000005000000dee00001c77c10
8888999888990908008888800088888077717177007007001000000dd00000011000000dd0000001089a98002a8888a20077700000500000000e0001c7777c10
8899898888998988008888800088888077717177000770000551550dd05515500551550dd0551550008980002a8888a20777770000050000000ed0001c7777c1
8899999808833338008888800088888077788877000770005dd5dd0550dd5dd55dd5dd0550dd5dd5005550002a8888a200777000005000000dee00001c77c100
088333380073330008088800080888006777777600700700dd000000000000dddd000000000000dd000500002a8888a2055555000555500000eedd00001cc100
008333000000007000038300000383006707707600000000d04444444444440dd04444444444440d000500002a8888a200565000050050000000ed0000011000
00070700000000000007007000700700070000700000000050444444444444055049999949999405000000002a8888a205555500000000000000000000000000
000000000011111000000000000000000008000024444142d04444444444440dd04999994999940d055555505555555500aaa000708888079708807900000000
001111100114444100011100000111000089800042222024d04444444444440dd04999994999940d544444455aaaaaa50a000a00879889789879978900000000
01144441114404010011110000111100089a9800421001246044444444444406604999994999940654aaaa450a7777a00a000a00988aa889888aa88800000000
114454511aa45451011111100111111089a7a9804201012460444444444444066044444444444406550aa05554aaaa4500aaa000988778890887788000000000
1aa444411a0aa210011111100111111089a7a98010110024604444444444440660499999499994065444444554444445000a0000898888988988889800000000
1a0aa2100072220000a2aa0000a2aa00089a980042110101d04444444444440dd04999994999940d54a00a4554a00a45000aaa00089889808098890800000000
00022200000000700a0222000a0222000089800042220224604444444444440660499999499994065444444554444445000a0000008778000087780000000000
000707000000000000070070007007000008000024444142604444444444440660499999499994060555555005555550000aa000080000800070070000000000
000000000055555000000000000000000000000044442421d04444444444440dd04999994999940d000000000000000000000000000000000000000000000000
00555550055999950005550000055500000000004000002170444444444444077044444444444407000000000000000000000000000000000000000000000000
05599995559909050055550000555500000000004011112160444444444444066049999949999406000000000000000000000000000000000000000000000000
5599a9a50559a9a505555550055555500000000040100121d04444444444440dd04999994999940d000000000000000000000000000000000000000000000000
05599995505ebe500555555005555550000000002010112170000000000000077040000040000407000000000000000000000000000000000000000000000000
005ebe50007eee00005ebe00005ebe00000000004011012160000000000000066040000040000406000000000000000000000000000000000000000000000000
000eee0000000070050eee00050eee00000000002222222160000000000000066040000040000406000000000000000000000000000000000000000000000000
00070700000000000007007000700700000000001111111100444444444444000049999949999400000000000000000000000000000000000000000000000000
04444000044440000444400004444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444400444444004444440044444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999400499994004444440044444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09191900091919004444440044444400008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999900099999000444400004444000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666000966669000666600006666000491966100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111000001100000111100001111000899868110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00101000010001000100010010001000088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004100000000003300410000001240000000000000000000000000144444410333333309a9944030000003001110000220212099999f9f99494499fff0000f
2009210400044410300221040001129000000000000000000000000042112112503333330494444000a9aa0000000000011011104249f9fff999944244fffff4
2042210200142210001221020000122000000000000000000000000042002002603333330a9444200a2222900100001000000000444499f9f9994944494fff44
00221001001211100012100100011200000000000000000000000000422222226033333309aaa9400a21129000111000000000009499499f9ff9949494f9ff9f
00210000001100000011000001112000000000000101011000000000411211227033333304aa94200920024000000000111111119999999999fff9f99ff99f49
410004410100041101000441000114a00000001111111111110000004002002270333333014942100a2102900000000094449444f99494424249f9fff9999999
221042220110421101104222000112a00000011224442444211000001222222170333333000000000a200290000000009ff94949f9f9494444449999f99ff9f9
221001210110011101100121000012900000012400000000421000000000000033333333200000020a2102900000000099ff949999ff94949494499999999999
330000000500005501000000092100000000124000000000092100000111011000001011101100000920024033333333000000001999922199fff92112999999
33500b3350bb3305011009440a21100000011290000000000a2110000000000001000000000001100a2102903333333300000000022220004249942112449442
3350b3330b355550011042220921000000001290000000000a2100000000000000001000000100000a2102903333333300000000000000009444442112424944
3550333503555050011022210041100000011290000000000a2110000000000000000111111000000a2002903333333300000000111000019494421001249494
55000550305505030100011000021110000012400000000009210000000000000000000000000000092102403333333300000000000011009944421001249f9f
000bb000550550b5000240000a91100000011290000000000a2110000000000000000000000000000a21029033333333000000000000000099994410012499ff
b0b3330b55500b55001222040921100000011290000000000a2110000000000000000000000000000a200290333333330000000000000000f9994421124299ff
3003350350500355000221020921000000001290000000000a2100000000000000000000000000000a2102903333333300000000000000009ff994211249499f
210002220100000000002103010000010000012900000000a2100000d5105d1030000000000000030a2102904244242442442424042424244244421033333333
2109401110d51000200921001051000100000112aaa9aaa9211000005110111000aa9aaaaaa9aa000a2102904414444444144444044144444414444033333333
210421000d511100204221000d110000000000112222222211000000100010000a222222222222900a20029099499999a94aaa9904949999a94aa94033333333
1011100005111110002210000111000000000000111111110000000005100d100a211111111112900921024099499999944aa999029499999449942033333333
00000420501101000021000050100001000000000110101000000000d110511009210010010012400a2102904414144444141444044114444414414033333333
00042210110110004100021011000010000000000000000000000000111011100a211000000112900a200290a9a94aa9aaa94aa9049a4aa9aaa9944033333333
40011100111001102210211011100101000000000000000000000000000000000a210000000012900422224099994999aa99499902994999aa99442033000033
21000004101051002210011010100511000000000000000000000000000000000a21100000011290004444004444144444441444094414444444414000ffff00
000041000000001122000000000000000500005505000100d5105d10000000000a2110000001129004244210aa99aaaa9944aaa909a9aaaaaa4a944030eee033
21092104000d550122100210a9400a9950000305510d501051101110110011000a21000000001290044144409994aa999442aa990494aa99a94944400e888803
1100110200d111102210211022120a220000b5505051110011101110111011100a211000000112900494a94049444449442244490a94944944144420e8787820
004200010d111010211021101121a2110000b550005110000000000000000000092100000000124002949420aaaaa9aaaaaaa9aa09aaa9aaaaaaa940e8878820
002104200111010511000110010111005053550300010101d1101d101d10d1100a2100000000129004414140aaa999aaaaa999aa04aa99aaaaaa9420e8787820
41000210000010d10004200000001000500550b50d01105151105110511051100a21111111111290049a94409999999999999999014999999999421008888200
2210000000d50d11404222000000100050000b550d10051111101110111011100044244444424400029944200000000000000000000000000000000030222003
22100441001105112002110000001000500003550111011000000000000000000100000000000010094441400000000000000000300000000000000033300003
__map__
7676767676767676767676767676767676000000000000007676767676767676767676767676767676767600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76500d500a5051500a5050500a500d50760000000000000076500d505050500a5050500a505050500d507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76505050505050505050505050505050760000000000000076500c08090c505050505050500c08090c507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76505051505050505050515050505150760c08090c0000007650501819505050500e50505050181950507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76505050505050505050500e5050505076001819000000007650502829505050505050505050282950507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76505050500c5051500c505050505050760a28290a760000765050500b5050505050505050500b5050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7650505050505050505050505050505050500b0b50760000765050500b5050505050505050500b5050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7650500e51505050505050505050505050500b0b50760000765050500c5050505050505050500c5050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76505050505150505051505050500b0b0b0b0b0b50760000760a50500b0b0b0b0b0b0b0b0b0b0b50500a7600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76505050500c5050500c50505050505050505050507600007650505050500e50500b50500e50505050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7650505050505050505150505050505050505050507600007650505050505050500b50505050505050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
765050515050500e50505050505050507676767676760000765050500c505050500b505050500c5050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7650505050505050505050507425745076000000000000007650505050505050500b50505050505050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7650505050505150505050507425745076000000000000007650505050505050500b50505050505050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7650505050505050505050505050505076000000000000007650505050505050500b50505050505050507600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7676767676767676767676767676767676000000000000007676767676767676765050767676767676767600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000226631e6631a25116241126350e6250a61500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001c6651835514645103350c625080150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000024050280602b5703057530545305250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000016273122730e6630a64506225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000124600c470086550663500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000014150181601c1450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000185501c5501f56024560285722b5750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001254115551195611e56124575000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000024262282722c6723027220663182531024500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002e67328273226731c263146550c2450662500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001c15024165000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001c0651b055180551754514545100350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000f0c1500c1450f1500f14508150081450a1500a1450c1500c1450f1500f1451115011145131501314500000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000f185421b5421f5521b5451d5421f552225521f54524552225421f5521b5451d5421b542185550000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0c0d4243

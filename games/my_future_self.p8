pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- MY FUTURE SELF
-- five moves. infinite excuses.
-- a time-travel puzzle game for pico-8
--
-- controls:
--   arrows: queue move directions
--   space / . / z+x: queue wait (.)
--   x (btn5): play / proceed
--   z (btn4): undo / erase echo / back
--   h / z+up: toggle hint letter
--   r / z+down: reset room

-- ============================================================
-- constants & palette aliases
-- ============================================================
tks=5        -- moves per tape
max_eco=3    -- max echo recordings
gw,gh=12,8   -- room grid width/height

local blk,nvy,pur,grn=0,1,2,3
local brn,dkn,gry,wht=4,5,6,7
local red,org,yel,lmn=8,9,10,11
local sky,lav,pnk,pch=12,13,14,15

-- ============================================================
-- tiny 3x5 pixel font
-- ============================================================
fnt={
 a="010101111101101",b="110101110101110",c="011100100100011",
 d="110101101101110",e="111100110100111",f="111100110100100",
 g="011100101101011",h="101101111101101",i="111010010010111",
 j="001001001101010",k="101101110101101",l="100100100100111",
 m="101111111101101",n="101111111111101",o="010101101101010",
 p="110101110100100",q="010101101111011",r="110101110101101",
 s="011100010001110",t="111010010010010",u="101101101101111",
 v="101101101101010",w="101101111111101",x="101101010101101",
 y="101101010010010",z="111001010100111",
 ["0"]="111101101101111",["1"]="010110010010111",
 ["2"]="110001010100111",["3"]="110001010001110",
 ["4"]="101101111001001",["5"]="111100110001110",
 ["6"]="011100111101111",["7"]="111001010010010",
 ["8"]="111101111101111",["9"]="111101111001110",
 ["."]="000000000000010",[","]="000000000010100",
 [":"]="000010000010000",["!"]="010010010000010",
 ["?"]="110001010000010",["'"]="010010000000000",
 ["-"]="000000111000000",["/"]="001001010100100",
 ["+"]="000010111010000",["("]="001010010010001",
 [")"]="100010010010100",["="]="000111000111000",
 [" "]="000000000000000",
}

for k,v in pairs(fnt) do
 local o=ord(k)
 if o>=97 and o<=122 then fnt[chr(o-32)]=v end
end

function lcase(s)
 s=tostr(s)
 local res=""
 for i=1,#s do
  local c=sub(s,i,i)
  local o=ord(c)
  if o>=65 and o<=90 then c=chr(o+32) end
  res=res..c
 end
 return res
end

function dtxt(s,x,y,c,sc,shd)
 c=c or wht sc=sc or 1
 s=tostr(s)
 if shd then dtxt(s,x,y+1,shd,sc) end
 for i=1,#s do
  local ch=sub(s,i,i)
  local px=fnt[ch]
  if px then
   for k=1,15 do
    if sub(px,k,k)=="1" then
     local bx=x+((k-1)%3)*sc
     local by=y+(flr((k-1)/3))*sc
     rectfill(bx,by,bx+sc-1,by+sc-1,c)
    end
   end
  end
  x+=4*sc
 end
end

function ctxt(s,y,c,sc,shd)
 sc=sc or 1
 s=tostr(s)
 local tw=(#s*4-1)*sc
 dtxt(s,flr((128-tw)/2),y,c,sc,shd)
end

-- ============================================================
-- level data builder
-- ============================================================
function mkroom(cells)
 local g={}
 for row=1,gh do
  g[row]={}
  for col=1,gw do g[row][col]="#" end
 end
 for _,c in ipairs(cells) do
  g[c[2]+1][c[1]+1]=c[3]
 end
 local rows={}
 for row=1,gh do
  local s=""
  for col=1,gw do s=s..g[row][col] end
  rows[row]=s
 end
 return rows
end

function corridor(ext,sx,sy,gx,gy,gate_xy)
 sx=sx or 3 sy=sy or 3 gx=gx or 7 gy=gy or 3
 local cells={}
 for cx=3,7 do cells[#cells+1]={cx,3,"."} end
 cells[#cells+1]={sx,sy,"S"}
 cells[#cells+1]={gx,gy,"T"}
 if gate_xy then cells[#cells+1]={gate_xy[1],gate_xy[2],"A"} end
 if ext then
  for _,e in ipairs(ext) do cells[#cells+1]=e end
 end
 return mkroom(cells)
end

lvs={
 {nm="GET UP",
  pt=mkroom({{3,4,"S"},{4,4,"."},{5,4,"."},{6,4,"T"}}),
  gt={},ini={},sol={"RRR"},
  hi={"THREE STEPS TO THE LETTER.","RIGHT RIGHT RIGHT.","THEN X TO PLAY."},
  nt="THE FLOOR IS NOT LAVA.",wn="A SMALL THING. DONE."},

 {nm="THE DETOUR",
  pt=mkroom({{3,4,"S"},{3,3,"."},{4,3,"."},{5,3,"."},{5,4,"."},{6,4,"T"}}),
  gt={},ini={},sol={"URRDR"},
  hi={"THE WALL WONT NEGOTIATE.","UP RIGHT RIGHT","DOWN RIGHT."},
  nt="FIVE STEPS. NO EXCUSES.",wn="YOU WENT AROUND IT."},

 {nm="THE PROMISE",
  pt=corridor({{3,4,"a"}},3,3,7,3,{5,3}),
  gt={{"A","a"}},ini={},sol={"D","RRRR"},
  hi={"FIRST DOWN. PLAY.","FAIL? X=TOMORROW.","THEN FOUR RIGHTS.","YESTERDAY HOLDS THE PLATE."},
  nt="A JOB FOR YESTERDAY.",wn="TEAMWORK WITH YOURSELF."},

 {nm="WRONG WAY",
  pt=corridor({{3,2,"a"}},3,3,7,3,{5,3}),
  gt={{"A","a"}},ini={"RRR"},sol={"erase","U","RRRR"},
  hi={"EMPTY TAPE? Z ERASES ECHO.","ERASE THE BAD RECORDING.","RECORD UP. POSTPONE.","THEN FOUR RIGHTS."},
  nt="YOUR OLD PLAN IS IN THE WAY.",wn="CHANGING YOUR MIND HELPS."},

 {nm="BOTH HANDS",
  pt=corridor({{3,2,"a"},{3,4,"b"}},3,3,7,3,{5,3}),
  gt={{"A","ab"}},ini={},sol={"U","D","RRRR"},
  hi={"RECORD UP. POSTPONE.","RECORD DOWN. POSTPONE.","BOTH PLATES OPEN A.","THEN FOUR RIGHTS."},
  nt="TWO PLATES. TWO PROMISES.",wn="MANY HANDS. ONE LETTER."},

 {nm="OLD FOOTSTEPS",
  pt=corridor({{4,4,"a"}},3,3,6,3,{5,3}),
  gt={{"A","a"}},ini={"RD"},sol={"..RRR"},
  hi={"YESTERDAY NEEDS SPACE.","WAIT TWICE (SPACE OR Z+X)","THEN RIGHT RIGHT RIGHT.","WAITING CAN BE A PLAN."},
  nt="LET YOUR PAST GO FIRST.",wn="REST WAS PART OF THE PLAN."},

 {nm="SHIFT CHANGE",
  pt=corridor({{3,2,"a"},{4,2,"."}},3,3,7,3,{5,3}),
  gt={{"A","a"}},ini={"URD"},sol={"RRRR"},
  hi={"THE PLATE IS HELD AT ONE.","ENTER THE GATE AT TWO.","FOUR RIGHTS. NO DELAY.","A GATE HOLDS WHILE INSIDE."},
  nt="A PROMISE HAS A WINDOW.",wn="YOU SHOWED UP ON TIME."},

 {nm="CHOKEPOINT",
  pt=mkroom({{3,4,"S"},{4,4,"."},{5,4,"."},{6,4,"T"},{3,3,"."},{4,3,"."},{5,3,"A"},{6,3,"."},{3,5,"a"}}),
  gt={{"A","a"}},ini={"RR"},sol={"D","URRRD"},
  hi={"OLD ECHO BLOCKS BELOW.","RECORD DOWN. POSTPONE.","TAKE THE UPPER ROUTE:","UP RIGHT RIGHT RIGHT DOWN."},
  nt="SOME HABITS TAKE UP SPACE.",wn="YOU FOUND ANOTHER WAY."},

 {nm="THE BACKLOG",
  pt=corridor({{3,2,"."},{4,2,"a"},{3,4,"."},{4,4,"b"}},3,3,7,3,{5,3}),
  gt={{"A","ab"}},ini={"UR","DR"},sol={"RRRRR"},
  hi={"PLATES ARRIVE AT TICK TWO.","THE GATE OPENS AT THREE.","FIVE RIGHTS: ONE WILL FAIL.","A FAILED STEP STILL COUNTS."},
  nt="EVERYTHING IS ALMOST READY.",wn="ALMOST BECAME ENOUGH."},

 {nm="FOUR OF ME",
  pt=corridor({{3,2,"a"},{3,4,"b"},{2,3,"c"}},3,3,7,3,{5,3}),
  gt={{"A","abc"}},ini={},sol={"U","D","L","RRRR"},
  hi={"RECORD UP THEN DOWN","THEN LEFT. POSTPONE EACH.","THREE ECHOES HOLD A B C.","YOU TAKE FOUR RIGHTS."},
  nt="THREE HELPERS. STILL YOUR JOB.",wn="ONLY YOU CAN FINISH IT."},

 {nm="LET GO",
  pt=corridor({{3,2,"a"},{4,2,"."}},3,3,7,3,{6,3}),
  gt={{"A","a"}},ini={"URD"},sol={"erase","U","RRRR"},
  hi={"THAT OLD TAPE LEAVES EARLY.","ERASE IT WITH AN EMPTY Z.","RECORD ONLY UP. POSTPONE.","THEN FOUR RIGHTS."},
  nt="IT HELPED ONCE. LET IT GO.",wn="YOU ARE ALLOWED TO CHANGE."},

 {nm="TODAY",
  pt=mkroom({{5,4,"S"},{6,4,"."},{7,4,"A"},{7,3,"B"},{7,2,"."},{8,2,"T"},{5,5,"a"},{4,4,"b"},{5,3,"c"}}),
  gt={{"A","ab"},{"B","c"}},ini={},sol={"D","L","U","RRUUR"},
  hi={"RECORD DOWN LEFT UP.","POSTPONE EACH RECORDING.","THEN RIGHT RIGHT","UP UP RIGHT. TODAY."},
  nt="ITS ADDRESSED TO YOU.",wn="TODAY."},
}

-- ============================================================
-- simulation engine (bug-proofed collision & chain solver)
-- ============================================================
local ddx={u=0,d=0,l=-1,r=1,["."]=0}
local ddy={u=-1,d=1,l=0,r=0,["."]=0}

function mktape(s)
 local t={}
 for i=1,tks do
  local ch=sub(s,i,i)
  t[i]=(ch=="" or ch==" ") and "." or lcase(ch)
 end
 return t
end

function lvcell(lv,x,y)
 if x<0 or x>=gw or y<0 or y>=gh then return "#" end
 return sub(lv.pt[y+1],x+1,x+1)
end

function lvfind(lv,sym)
 for row=1,gh do
  for col=1,gw do
   if sub(lv.pt[row],col,col)==sym then return col-1,row-1 end
  end
 end
 return 0,0
end

function gate_st(lv,pos)
 local occ={} local plates={}
 for _,p in ipairs(pos) do
  occ[p[1]..","..p[2]]=true
  plates[lvcell(lv,p[1],p[2])]=true
 end
 local gs={}
 for _,g in ipairs(lv.gt) do
  local lt=g[1] local nd=g[2]
  local gx,gy=lvfind(lv,lt)
  local ok=occ[gx..","..gy]
  if not ok then
   ok=true
   for i=1,#nd do
    if not plates[sub(nd,i,i)] then ok=false break end
   end
  end
  gs[lt]=ok
 end
 return gs,plates,occ
end

function simstep(lv,pos,cmds,gs)
 local n=#pos
 local prop={}
 local blk={}
 -- 1. initial proposals & wall/gate checks
 for i=1,n do
  prop[i]={pos[i][1],pos[i][2]}
  local cmd=lcase(cmds[i] or ".")
  local ex=ddx[cmd] or 0
  local ey=ddy[cmd] or 0
  if ex~=0 or ey~=0 then
   local nx=pos[i][1]+ex
   local ny=pos[i][2]+ey
   local cell=lvcell(lv,nx,ny)
   if cell=="#" then
    blk[i]={ex,ey}
   elseif cell>="A" and cell<="Z" and cell~="S" and cell~="T" then
    if not gs[cell] then blk[i]={ex,ey}
    else prop[i]={nx,ny} end
   else
    prop[i]={nx,ny}
   end
  end
 end

 -- 2. iterative fixed-point actor collision resolution
 local chg=true
 while chg do
  chg=false
  -- head-on swap prevention
  for i=1,n do
   for j=i+1,n do
    if prop[i][1]==pos[j][1] and prop[i][2]==pos[j][2]
     and prop[j][1]==pos[i][1] and prop[j][2]==pos[i][2]
     and (pos[i][1]~=pos[j][1] or pos[i][2]~=pos[j][2]) then
     blk[i]={prop[i][1]-pos[i][1],prop[i][2]-pos[i][2]}
     blk[j]={prop[j][1]-pos[j][1],prop[j][2]-pos[j][2]}
     prop[i]={pos[i][1],pos[i][2]}
     prop[j]={pos[j][1],pos[j][2]}
     chg=true
    end
   end
  end
  -- same-tile occupancy (includes stationary echoes blocking paths)
  local dc={}
  for i=1,n do
   local k=prop[i][1]..","..prop[i][2]
   dc[k]=(dc[k] or 0)+1
  end
  for i=1,n do
   if prop[i][1]~=pos[i][1] or prop[i][2]~=pos[i][2] then
    local k=prop[i][1]..","..prop[i][2]
    if dc[k]>1 then
     blk[i]={prop[i][1]-pos[i][1],prop[i][2]-pos[i][2]}
     prop[i]={pos[i][1],pos[i][2]}
     chg=true
    end
   end
  end
 end
 return prop,blk
end

function simulate(lv,ecos,pres)
 local progs={}
 for _,e in ipairs(ecos) do progs[#progs+1]=mktape(e) end
 progs[#progs+1]=mktape(pres)
 local n=#progs
 local sx,sy=lvfind(lv,"S")
 local pos={}
 for i=1,n do pos[i]={sx,sy} end
 local hist={pos}
 local tx,ty=lvfind(lv,"T")
 local ok=false
 for tick=1,tks do
  local cmds={}
  for i=1,n do cmds[i]=progs[i][tick] end
  local gs=gate_st(lv,pos)
  local np,_=simstep(lv,pos,cmds,gs)
  pos=np
  hist[#hist+1]=pos
  if pos[n][1]==tx and pos[n][2]==ty then ok=true break end
 end
 return ok,hist
end

-- ============================================================
-- game state variables
-- ============================================================
local gstate   -- "title","select","plan","run","fail","win","ending"
local rid      -- room index (1-12)
local ecos     -- echo recordings list
local queue    -- current move queue string
local day      -- current day number
local pos      -- positions table
local prev     -- previous positions
local dirs     -- facing direction (-1 left, 1 right)
local blend    -- animation blend factor
local tickn    -- current simulation tick
local rtimer   -- run timer
local progs    -- programs being run
local blkset   -- blocked actors table
local prev_gs  -- previous gate states for sfx trigger
local overlay  -- "hint" or nil
local toast    -- notification string
local ttimer   -- toast timer
local parts    -- particles list
local stars    -- ambient background motes
local tf       -- time float (seconds)
local anim     -- animation counter (frames)
local shake    -- screen shake magnitude
local wipe     -- screen transition timer
local unlkd    -- highest unlocked room
local compl    -- set of completed rooms
local endtime  -- ending scene timer
local sel      -- selected room in select screen
local z_hold   -- z button chord state
local z_used   -- whether a z+btn combo was used
local eco_cols={sky,pnk,yel}

-- ============================================================
-- helpers & particle spawners
-- ============================================================
function add_burst(x,y,c,n,spd,life)
 n=n or 8 spd=spd or 12 life=life or 0.5
 for i=1,n do
  local a=(i/n)+rnd(0.08)
  local v=spd*(0.6+rnd(0.6))
  parts[#parts+1]={x,y,cos(a)*v,sin(a)*v,life*(0.7+rnd(0.5)),c,life}
 end
end

function reset_pos()
 local lv=lvs[rid]
 local sx,sy=lvfind(lv,"S")
 pos={} prev={} dirs={}
 local n=#ecos+1
 for i=1,n do
  pos[i]={sx,sy} prev[i]={sx,sy} dirs[i]=1
 end
 blkset={} blend=1
 prev_gs=gate_st(lv,pos)
end

function load_lv(num)
 rid=num
 local lv=lvs[rid]
 ecos={}
 for _,e in ipairs(lv.ini) do ecos[#ecos+1]=e end
 queue=""
 day=1+#ecos
 reset_pos()
 gstate="plan"
 overlay=nil
 parts={}
 tickn=0
 rtimer=0
 z_hold=false z_used=false
 wipe=0.35
end

function notify(s)
 toast=s ttimer=2.2
end

function do_erase()
 if #ecos>0 then
  ecos[#ecos]=nil
  day=max(1,day-1)
  reset_pos()
  sfx(2)
  shake=2
  notify("ONE LESS PROMISE.")
 else
  sfx(3)
  shake=2
  notify("NO ECHOES TO ERASE.")
 end
end

function do_exec()
 reset_pos()
 progs={}
 for _,e in ipairs(ecos) do progs[#progs+1]=mktape(e) end
 progs[#progs+1]=mktape(queue)
 gstate="run"
 tickn=0 rtimer=0.14 blend=1
 sfx(0)
end

function do_postpone()
 if #ecos<max_eco then
  ecos[#ecos+1]=queue
  queue="" day+=1
  gstate="plan"
  reset_pos()
  sfx(1)
  local sx,sy=lvfind(lvs[rid],"S")
  add_burst(16+sx*8+4,18+sy*8+4,eco_cols[#ecos],12,16,0.5)
  local msgs={"TOMORROW.","AGAIN?","STILL HERE.","TODAY MAYBE."}
  notify(msgs[flr((rid-1)/3)+1])
 else
  notify("MAX ECHOES. RETRY OR ERASE.") sfx(3) shake=3
 end
end

-- ============================================================
-- input handlers
-- ============================================================
function act_x()
 if overlay then overlay=nil sfx(2) return end
 if gstate=="title" then
  load_lv(rid) sfx(1)
 elseif gstate=="select" then
  if sel<=unlkd then load_lv(sel) sfx(1)
  else sfx(3) shake=2 notify("ROOM LOCKED.") end
 elseif gstate=="plan" then
  do_exec()
 elseif gstate=="fail" then
  do_postpone()
 elseif gstate=="win" then
  if rid==12 then
   gstate="ending" endtime=0 wipe=0.5 sfx(4)
  else
   compl[rid]=true
   rid+=1
   unlkd=max(unlkd,rid)
   load_lv(rid)
   sfx(1)
  end
 elseif gstate=="ending" and endtime>2.5 then
  gstate="title" wipe=0.4 sfx(2)
 end
end

function act_z()
 if overlay then overlay=nil sfx(2) return end
 if gstate=="title" then
  gstate="select" sel=rid wipe=0.25 sfx(0)
 elseif gstate=="select" then
  gstate="title" wipe=0.25 sfx(2)
 elseif gstate=="plan" then
  if queue~="" then
   queue=sub(queue,1,#queue-1) sfx(2)
  else
   do_erase()
  end
 elseif gstate=="fail" then
  gstate="plan" reset_pos() sfx(2)
 end
end

function add_dir(d)
 if overlay then return end
 if gstate=="plan" then
  if #queue<tks then
   queue=queue..d sfx(0)
  else
   sfx(3) shake=2
   notify("FIVE MOVES. THAT IS ALL.")
  end
 elseif gstate=="select" then
  local sdx={l=-1,r=1,u=0,d=0}
  local sdy={l=0,r=0,u=-1,d=1}
  local nsel=mid(1,sel+(sdx[d] or 0)+(sdy[d] or 0)*3,12)
  if nsel~=sel then sel=nsel sfx(0) end
 end
end

-- ============================================================
-- _init
-- ============================================================
function _init()
 -- enable keyboard devkit input for space/./h/r keys
 poke(0x5f2d,1)

 -- register pause menu shortcuts for 100% controller accessibility
 menuitem(1,"insert wait (.)",function()
  if gstate=="plan" and not overlay then add_dir(".") end
 end)
 menuitem(2,"read hint",function()
  if gstate=="plan" or overlay=="hint" then
   overlay=(overlay=="hint") and nil or "hint" sfx(1)
  end
 end)
 menuitem(3,"reset room",function()
  if gstate=="plan" or gstate=="fail" then load_lv(rid) sfx(2) end
 end)
 menuitem(4,"room select",function()
  overlay=nil gstate="select" sel=rid wipe=0.25 sfx(0)
 end)

 unlkd=1 compl={} tf=0 anim=0
 toast="" ttimer=0 parts={}
 shake=0 wipe=0 z_hold=false z_used=false
 stars={}
 for i=1,28 do
  stars[i]={rnd(128),rnd(128),0.15+rnd(0.35),i%3==0 and sky or dkn}
 end
 load_lv(1)
 gstate="title" sel=1 endtime=0
end

-- ============================================================
-- _update
-- ============================================================
function _update()
 tf+=1/30 anim+=1
 if ttimer>0 then ttimer-=1/30 end
 if wipe>0 then wipe=max(0,wipe-1/30) end
 if shake>0 then shake=max(0,shake-0.4) end

 -- update ambient background stars
 for _,st in ipairs(stars) do
  st[2]=(st[2]-st[3])%128
 end

 -- update particles
 local lp={}
 for _,p in ipairs(parts) do
  p[1]+=p[3]/30 p[2]+=p[4]/30
  p[3]*=0.92 p[4]*=0.92
  p[5]-=1/30
  if p[5]>0 then lp[#lp+1]=p end
 end
 parts=lp

 -- keyboard shortcuts (space/./w for wait, h for hint, r for reset)
 while stat(30) do
  local k=lcase(stat(31))
  if k==" " or k=="." or k=="w" then
   if gstate=="plan" and not overlay then add_dir(".") end
  elseif k=="h" then
   if gstate=="plan" or overlay=="hint" then
    overlay=(overlay=="hint") and nil or "hint"
    sfx(1)
   end
  elseif k=="r" then
   if gstate=="plan" or gstate=="fail" then
    load_lv(rid) sfx(2) notify("FRESH START.")
   end
  end
 end

 -- controller input with z-chord support in plan mode
 if gstate=="plan" and not overlay then
  if btnp(4) then z_hold=true z_used=false end
  if z_hold and btn(4) then
   if btnp(5) then add_dir(".") z_used=true end
   if btnp(2) then overlay="hint" sfx(1) z_used=true end
   if btnp(3) then load_lv(rid) sfx(2) notify("FRESH START.") z_used=true end
   if btnp(0) then gstate="select" sel=rid wipe=0.25 sfx(0) z_used=true end
   if btnp(1) then do_erase() z_used=true end
  else
   if z_hold and not btn(4) then
    z_hold=false
    if not z_used then act_z() end
   end
   if btnp(0) then add_dir("l") end
   if btnp(1) then add_dir("r") end
   if btnp(2) then add_dir("u") end
   if btnp(3) then add_dir("d") end
   if btnp(5) then act_x() end
  end
 else
  z_hold=false z_used=false
  if btnp(0) then add_dir("l") end
  if btnp(1) then add_dir("r") end
  if btnp(2) then add_dir("u") end
  if btnp(3) then add_dir("d") end
  if btnp(5) then act_x() end
  if btnp(4) then act_z() end
 end

 if overlay then return end

 -- simulation runner
 if gstate=="run" then
  rtimer-=1/30
  blend=min(1,blend+1/30/0.24)
  if rtimer<=0 then
   local lv=lvs[rid]
   local tx,ty=lvfind(lv,"T")
   -- check victory
   if tickn>0 and pos[#pos][1]==tx and pos[#pos][2]==ty then
    gstate="win" compl[rid]=true
    unlkd=max(unlkd,min(12,rid+1))
    sfx(4)
    local bpx=16+tx*8+4 local bpy=18+ty*8+4
    add_burst(bpx,bpy,yel,16,22,0.75)
    add_burst(bpx,bpy,lmn,10,14,0.55)
    return
   end
   if tickn>=tks then
    gstate="fail" sfx(3) shake=2.5 return
   end
   local cmds={}
   for i=1,#progs do cmds[i]=progs[i][tickn+1] end
   local gs=gate_st(lv,pos)
   -- check if any gate newly opened
   for k,v in pairs(gs) do
    if v and not prev_gs[k] then
     sfx(5)
     local gx,gy=lvfind(lv,k)
     add_burst(16+gx*8+4,18+gy*8+4,lmn,8,12,0.4)
    end
   end
   prev_gs=gs
   -- copy current positions to prev
   prev={}
   for i=1,#pos do prev[i]={pos[i][1],pos[i][2]} end
   pos,blkset=simstep(lv,pos,cmds,gs)
   -- update facing directions & step dust
   for i=1,#pos do
    local dx=pos[i][1]-prev[i][1]
    local dy=pos[i][2]-prev[i][2]
    if dx<0 then dirs[i]=-1 elseif dx>0 then dirs[i]=1 end
    if dx~=0 or dy~=0 then
     parts[#parts+1]={16+prev[i][1]*8+4,18+prev[i][2]*8+7,(rnd(4)-2),-rnd(3),0.25,gry,0.25}
    end
   end
   local hb=false
   for i,b in pairs(blkset) do
    if b then
     hb=true
     local bpx=16+pos[i][1]*8+4+b[1]*3
     local bpy=18+pos[i][2]*8+4+b[2]*3
     add_burst(bpx,bpy,red,5,10,0.3)
    end
   end
   if hb then sfx(3) shake=2 else sfx(0) end
   tickn+=1 rtimer=0.40 blend=0
  end
 elseif gstate=="ending" then
  endtime+=1/30
 end
end

-- ============================================================
-- drawing primitives & room renderer
-- ============================================================
function fr(x,y,w,h,c)
 rectfill(x,y,x+w-1,y+h-1,c)
end

function draw_box(x,y,w,h,bg,bdr,shd)
 if shd then fr(x+2,y+2,w,h,shd) end
 fr(x,y,w,h,bdr)
 fr(x+1,y+1,w-2,h-2,bg)
end

function draw_arrow(cmd,x,y,c)
 cmd=lcase(cmd)
 if cmd=="." then
  circ(x+2,y+2,1,c)
  return
 end
 local pts={
  u={{3,1},{2,2},{3,2},{4,2},{1,3},{2,3},{3,3},{4,3},{5,3},{3,4},{3,5}},
  d={{3,5},{2,4},{3,4},{4,4},{1,3},{2,3},{3,3},{4,3},{5,3},{3,2},{3,1}},
  r={{1,3},{2,2},{2,3},{2,4},{3,1},{3,2},{3,3},{3,4},{3,5},{4,2},{4,3},{4,4},{5,3}},
  l={{5,3},{4,2},{4,3},{4,4},{1,3},{2,2},{2,3},{2,4},{3,1},{3,2},{3,3},{3,4},{3,5}},
 }
 local pat=pts[cmd]
 if pat then
  for _,pt in ipairs(pat) do pset(x+pt[1]-1,y+pt[2]-1,c) end
 end
end

-- check if a wall cell is adjacent to any walkable floor cell
function is_room_wall(lv,col,row)
 for dy=-1,1 do
  for dx=-1,1 do
   if lvcell(lv,col+dx,row+dy)~="#" then return true end
  end
 end
 return false
end

-- draw a player/echo actor (8x8 area at px,py)
function draw_actor(px,py,eco_i,walking,dir,is_blk)
 dir=dir or 1
 local bob=(not walking and (anim%24<12)) and 0 or 0
 -- drop shadow
 fr(px+1,py+7,6,1,blk)
 -- legs
 local leg_c=eco_i and nvy or dkn
 if walking and (anim%6<3) then
  fr(px+2,py+6,1,1,leg_c) fr(px+5,py+6,1,1,leg_c)
 else
  fr(px+2,py+6,2,1,leg_c) fr(px+4,py+6,2,1,leg_c)
 end
 -- torso / hoodie
 local bc=eco_i and eco_cols[eco_i] or org
 local scf=eco_i and wht or red
 fr(px+1,py+3+bob,6,3,bc)
 line(px+1,py+3+bob,px+6,py+3+bob,scf)
 -- head
 local hc=eco_i and lav or pch
 fr(px+2,py+0+bob,4,3,hc)
 -- hair / cap
 fr(px+2,py-1+bob,4,1,eco_i and eco_cols[eco_i] or brn)
 -- directional eyes
 local ex=(dir>=0) and (px+4) or (px+2)
 pset(ex,py+1+bob,blk)
 pset(ex+1,py+1+bob,blk)
 -- echo badge or blocked indicator
 if is_blk then
  dtxt("!",px+3,py-7,red,1,blk)
 elseif eco_i then
  pset(px+3,py-3,eco_cols[eco_i])
  pset(px+4,py-3,eco_cols[eco_i])
 end
end

local act_pal={
 {wc=brn,tc=org,fc=pch,sc=brn,bg=nvy},
 {wc=dkn,tc=lav,fc=gry,sc=dkn,bg=nvy},
 {wc=pur,tc=sky,fc=dkn,sc=blk,bg=blk},
 {wc=nvy,tc=yel,fc=dkn,sc=blk,bg=blk},
}

function draw_room()
 local lv=lvs[rid]
 local ap=act_pal[flr((rid-1)/3)+1]
 local ox,oy=16,18

 local gs,plates,occ=gate_st(lv,pos)

 -- pass 1: wall shadows & 2.5d floor/wall tiles
 for row=0,gh-1 do
  for col=0,gw-1 do
   local cell=lvcell(lv,col,row)
   local px2=ox+col*8
   local py2=oy+row*8
   if cell=="#" then
    if is_room_wall(lv,col,row) then
     -- drop shadow into void
     fr(px2+1,py2+1,8,8,blk)
     -- wall body
     fr(px2,py2,8,8,ap.wc)
     -- top highlight bevel
     line(px2,py2,px2+7,py2,ap.tc)
     -- brick texture detail
     line(px2,py2+4,px2+7,py2+4,blk)
     local bx=px2+((row%2)*4)+2
     line(bx,py2+1,bx,py2+3,blk)
     -- bottom front-face if floor is below
     if lvcell(lv,col,row+1)~="#" then
      fr(px2,py2+6,8,2,blk)
      line(px2,py2+5,px2+7,py2+5,ap.tc)
     end
    end
   else
    -- walkable floor tile
    fr(px2,py2,8,8,ap.fc)
    -- subtle tile grid & texture
    pset(px2+7,py2+7,ap.sc)
    pset(px2+((col*3+row)%5)+1,py2+((col+row*2)%5)+2,ap.sc)
    -- cast shadow from wall above
    if lvcell(lv,col,row-1)=="#" then
     fr(px2,py2,8,2,ap.sc)
    end
   end
  end
 end

 -- pass 2: circuit wires connecting plates to gates
 for _,g in ipairs(lv.gt) do
  local gx,gy=lvfind(lv,g[1])
  local nd=g[2]
  for i=1,#nd do
   local pl=sub(nd,i,i)
   local px,py=lvfind(lv,pl)
   local active=plates[pl]
   local wc=active and lmn or ap.sc
   local x1,y1=ox+px*8+4,oy+py*8+4
   local x2,y2=ox+gx*8+4,oy+gy*8+4
   line(x1,y1,x2,y1,wc)
   line(x2,y1,x2,y2,wc)
   if active then
    local t=(anim*2)%16/16
    local mx=x1+(x2-x1)*t
    pset(mx,y1,yel)
   end
  end
 end

 -- pass 3: interactive objects (start, target, plates, gates)
 for row=0,gh-1 do
  for col=0,gw-1 do
   local cell=lvcell(lv,col,row)
   local px2=ox+col*8
   local py2=oy+row*8
   if cell=="S" then
    fr(px2+1,py2+1,6,6,red)
    rect(px2+1,py2+1,px2+6,py2+6,org)
    fr(px2+3,py2+3,2,2,(anim%16<8) and yel or org)
   elseif cell=="T" then
    local bob=(anim%16<8) and 0 or -1
    -- shadow
    fr(px2+1,py2+6,6,1,ap.sc)
    -- glowing aura
    rect(px2,py2+1+bob,px2+7,py2+6+bob,yel)
    -- envelope
    fr(px2+1,py2+2+bob,6,4,wht)
    line(px2+1,py2+2+bob,px2+3,py2+4+bob,gry)
    line(px2+6,py2+2+bob,px2+4,py2+4+bob,gry)
    -- red wax seal
    fr(px2+3,py2+4+bob,2,1,red)
    if anim%10==0 then
     parts[#parts+1]={px2+2+rnd(4),py2+2,0,-6,0.35,yel,0.35}
    end
   elseif cell>="a" and cell<="z" then
    local active=occ[col..","..row]
    fr(px2+1,py2+1,6,6,blk)
    local dy=active and 1 or 0
    fr(px2+2,py2+1+dy,4,5,active and lmn or org)
    dtxt(cell,px2+2,py2+1+dy,blk)
   elseif cell>="A" and cell<="Z" and cell~="S" and cell~="T" then
    local opened=gs[cell]
    fr(px2,py2,8,8,blk)
    -- side emitters
    fr(px2,py2,2,8,dkn)
    fr(px2+6,py2,2,8,dkn)
    if not opened then
     line(px2+1,py2,px2+1,py2+7,sky)
     line(px2+6,py2,px2+6,py2+7,sky)
     local bc=(anim%6<3) and lav or pnk
     line(px2+3,py2+1,px2+3,py2+6,bc)
     line(px2+4,py2+1,px2+4,py2+6,bc)
     dtxt(cell,px2+3,py2+2,wht,1,blk)
    else
     pset(px2+1,py2+1,lmn) pset(px2+6,py2+1,lmn)
     pset(px2+1,py2+6,lmn) pset(px2+6,py2+6,lmn)
     line(px2+2,py2+7,px2+5,py2+7,dkn)
    end
   end
  end
 end

 -- pass 4: plan trajectory preview
 if gstate=="plan" and queue~="" then
  local win_ok,hist=simulate(lv,ecos,queue)
  local pcol=win_ok and lmn or sky
  local steps=min(#queue+1,#hist)
  for ti=2,steps do
   local p1=hist[ti-1][#hist[ti-1]]
   local p2=hist[ti][#hist[ti]]
   line(ox+p1[1]*8+4,oy+p1[2]*8+5,ox+p2[1]*8+4,oy+p2[2]*8+5,pcol)
   circfill(ox+p2[1]*8+4,oy+p2[2]*8+5,1,wht)
  end
  local last=hist[steps][#hist[steps]]
  if anim%10<5 then
   rect(ox+last[1]*8+1,oy+last[2]*8+1,ox+last[1]*8+6,oy+last[2]*8+6,pcol)
  end
 end

 -- pass 5: sort & draw actors (with stack fan-out at start)
 local order={}
 for i=1,#pos do order[i]=i end
 for i=1,#order-1 do
  for j=i+1,#order do
   if pos[order[i]][2]>pos[order[j]][2] then
    order[i],order[j]=order[j],order[i]
   end
  end
 end

 local stack_ofs={{-2,-1},{2,-1},{0,-2},{0,0}}
 for _,i in ipairs(order) do
  local cx,cy=pos[i][1],pos[i][2]
  local ox2,oy2=prev[i][1],prev[i][2]
  local sm=1-(1-min(1,blend))^3
  local rx=ox2+(cx-ox2)*sm
  local ry=oy2+(cy-oy2)*sm
  -- bump animation if blocked
  local b=blkset[i]
  if b and gstate=="run" and blend<0.6 then
   local bmp=sin(blend/0.6*0.5)*0.32
   rx+=b[1]*bmp ry+=b[2]*bmp
  end
  local eco_i=(i<#pos) and i or nil
  local sx_ofs,sy_ofs=0,0
  if gstate=="plan" and eco_i then
   sx_ofs=stack_ofs[eco_i][1]
   sy_ofs=stack_ofs[eco_i][2]
  end
  local walking=(gstate=="run") and (blend<1) and (cx~=ox2 or cy~=oy2)
  draw_actor(flr(ox+rx*8+sx_ofs),flr(oy+ry*8-1+sy_ofs),eco_i,walking,dirs[i],b~=nil and gstate=="run")
 end

 -- pass 6: particles
 for _,p in ipairs(parts) do
  local r=(p[5]/p[7])>0.5 and 1 or 0
  if r>0 then circfill(flr(p[1]),flr(p[2]),1,p[6])
  else pset(flr(p[1]),flr(p[2]),p[6]) end
 end
end

-- ============================================================
-- _draw
-- ============================================================
local acts={"I'LL DO IT TODAY","SOMEONE ELSE WILL","TOO MANY TOMORROWS","NOT TOMORROW"}

function _draw()
 local sx=shake>0 and (rnd(shake*2)-shake) or 0
 local sy=shake>0 and (rnd(shake*2)-shake) or 0
 camera(sx,sy)
 cls(blk)

 -- ambient starfield background
 for _,st in ipairs(stars) do
  pset(st[1],st[2],st[4])
 end

 if gstate=="title" then
  -- decorative clock/time rings
  circ(64,64,54,nvy)
  circ(64,64,42,nvy)
  local ha=tf*0.05
  line(64,64,64+cos(ha)*34,64+sin(ha)*34,nvy)
  line(64,64,64+cos(ha*12)*24,64+sin(ha*12)*24,nvy)

  -- title logo with drop shadow
  ctxt("MY FUTURE",10,wht,2,blk)
  ctxt("SELF",24,org,3,brn)
  ctxt("FIVE MOVES.",47,wht,1,blk)
  ctxt("INFINITE EXCUSES.",55,sky,1,blk)

  -- stage platform
  draw_box(16,66,96,24,nvy,dkn,blk)
  line(18,86,110,86,dkn)
  for i=0,2 do
   draw_actor(24+i*18+flr(sin(tf*0.4+i*0.3)*2),76,i+1,true,1,false)
  end
  draw_actor(88,76,nil,anim%8<4,-1,false)

  -- buttons
  draw_box(24,94,80,11,brn,org,blk)
  ctxt("X: BEGIN DAY",97,wht,1,blk)

  draw_box(28,107,72,10,nvy,sky,blk)
  ctxt("Z: THE DAYS",110,sky,1,blk)

  ctxt("ARROWS+Z+X  SPACE:WAIT  H:HINT",121,dkn)

 elseif gstate=="select" then
  ctxt("THE DAYS",6,wht,2,nvy)
  ctxt("CHOOSE A ROOM TO REVISIT",20,sky)
  for i=1,12 do
   local lx=14+((i-1)%3)*35
   local ly=30+(flr((i-1)/3))*18
   local is_sel=(i==sel)
   local is_unlk=(i<=unlkd)
   local bg=is_unlk and nvy or blk
   local bdr=is_sel and yel or (is_unlk and sky or dkn)
   draw_box(lx,ly,30,14,bg,bdr,blk)
   dtxt(tostr(i),lx+5,ly+5,is_unlk and wht or dkn)
   -- initial echo dots preview
   local ini_n=#lvs[i].ini
   for e=1,ini_n do
    pset(lx+16+e*2,ly+10,eco_cols[e])
   end
   if compl[i] then
    fr(lx+23,ly+3,4,4,lmn)
    pset(lx+24,ly+5,blk)
   end
  end
  draw_box(8,103,112,11,nvy,dkn,blk)
  local rtitle=sel<=unlkd and (sel..". "..lvs[sel].nm) or "LOCKED MEMORY"
  ctxt(rtitle,106,sel<=unlkd and org or dkn)
  dtxt("Z:TITLE",8,119,sky)
  dtxt("X:ENTER",88,119,yel)

 elseif gstate=="ending" then
  ctxt("TODAY.",10,org,3,brn)
  -- cozy room & window
  draw_box(18,36,92,46,brn,org,blk)
  fr(20,72,88,8,dkn)
  -- window with night sky
  draw_box(76,40,26,30,nvy,wht,blk)
  line(89,40,89,69,wht)
  line(76,54,101,54,wht)
  pset(81,45,yel) pset(95,48,wht) pset(83,61,sky)
  -- desk & letter
  fr(32,66,26,12,org)
  fr(34,70,22,8,brn)
  fr(40,63,8,3,wht) pset(43,64,red)
  draw_actor(58,64,nil,endtime<3,-1,false)

  draw_box(8,86,112,28,nvy,sky,blk)
  dtxt("DEAR FUTURE ME,",14,90,wht)
  dtxt("PLEASE DONT LEAVE",14,98,pch)
  dtxt("EVERYTHING FOR ME.",14,106,pch)
  if endtime>2.5 and anim%20<12 then
   ctxt("X: RETURN TO TITLE",119,yel)
  end

 else
  -- top header bar (clean 2-row spacing)
  fr(0,0,128,16,nvy)
  line(0,16,127,16,dkn)
  dtxt(tostr(rid)..". "..lvs[rid].nm,3,2,wht,1,blk)
  -- act progress pips top-right
  for i=0,3 do
   fr(101+i*6,3,4,3,(i==flr((rid-1)/3)) and org or dkn)
  end
  dtxt("DAY "..day,3,9,sky)
  -- echo slots indicator
  dtxt("ECHO",62,9,sky)
  for i=1,max_eco do
   local ec=(i<=#ecos) and eco_cols[i] or dkn
   fr(82+(i-1)*6,10,4,4,ec)
  end
  -- gate requirement legend
  local lv=lvs[rid]
  if #lv.gt>0 then
   local gstr=lv.gt[1][1]..":"..lv.gt[1][2]
   if #lv.gt>1 then gstr=gstr.." "..lv.gt[2][1]..":"..lv.gt[2][2] end
   dtxt(gstr,126-#gstr*4,9,lav)
  end

  -- main room viewport
  draw_room()

  -- act theme subtitle
  ctxt(acts[flr((rid-1)/3)+1],85,dkn)

  -- bottom cassette tape deck
  fr(0,92,128,36,blk)
  line(0,92,127,92,dkn)

  -- echo timeline row (shows each echo's move per tick!)
  local tp=mktape(queue)
  for i=1,tks do
   local sx2=18+(i-1)*21
   local is_cur=(gstate=="run") and (i==tickn)
   -- echo mini-indicators above slot
   for e=1,#ecos do
    local et=mktape(ecos[e])
    local ex=sx2+1+(e-1)*6
    fr(ex,94,5,5,nvy)
    draw_arrow(et[i],ex,94,eco_cols[e])
   end
   -- main player tape slot
   local sbg=is_cur and yel or (i<=#queue and nvy or blk)
   local sbdr=is_cur and wht or (i<=#queue and sky or dkn)
   draw_box(sx2,101,18,13,sbg,sbdr)
   local cmd=tp[i]
   local cc=is_cur and blk or (i<=#queue and wht or dkn)
   draw_arrow(cmd,sx2+6,105,cc)
  end

  -- left deck label
  if gstate=="run" then
   dtxt("T"..tickn,3,105,yel)
  else
   dtxt("YOU",2,105,wht)
   if #ecos>0 then dtxt("ECO",2,94,sky) end
  end

  -- bottom status / controls bar
  fr(0,117,128,11,nvy)
  if gstate=="plan" then
   if z_hold and btn(4) then
    ctxt("Z+ X:WAIT UP:HINT DN:RST L:MAP",120,yel)
   else
    local slot=flr(anim/90)%3
    if slot==0 then ctxt(lvs[rid].nt,120,pch)
    elseif slot==1 then ctxt("X:PLAY  Z:UNDO  SPACE/Z+X:WAIT",120,sky)
    else ctxt("H/Z+UP:HINT  R/Z+DN:RESET",120,lav) end
   end
  elseif gstate=="run" then
   ctxt("WATCHING THE TAPE...",120,wht)
  elseif gstate=="fail" then
   draw_box(12,34,104,36,nvy,org,blk)
   ctxt("NOT YET.",41,pch,2,blk)
   ctxt("THE LETTER IS STILL WAITING.",57,wht)
   ctxt("Z: RETRY   X: RECORD ECHO",120,yel)
  elseif gstate=="win" then
   draw_box(8,32,112,40,nvy,yel,blk)
   ctxt("DELIVERED.",39,yel,2,blk)
   ctxt(lvs[rid].wn,57,wht)
   ctxt(rid==12 and "X: FINISH TODAY" or "X: NEXT DAY",120,lmn)
  end

  -- hint letter overlay
  if overlay=="hint" then
   draw_box(6,18,116,92,nvy,org,blk)
   line(10,31,117,31,org)
   ctxt("A LETTER FROM TOMORROW",23,yel,1,blk)
   local hh=lvs[rid].hi
   for i,hl in ipairs(hh) do
    ctxt(hl,34+i*10,wht)
   end
   line(10,94,117,94,dkn)
   ctxt("WAIT(.) = SPACE OR Z+X",97,sky)
   ctxt("X OR Z: CLOSE",103,org)
  end
 end

 -- toast banner
 if ttimer>0 then
  draw_box(8,82,112,11,nvy,org,blk)
  ctxt(toast,85,yel)
 end

 -- screen transition wipe
 if wipe>0 then
  local h=flr((wipe/0.4)*64)
  fr(0,0,128,h,blk)
  fr(0,128-h,128,h,blk)
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00030000182401c220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000183411c3411f3412433100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001c24017230122200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500000c64009630076200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000182401c2401f2402425024230242100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000024340283302b3200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
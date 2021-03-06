pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- sandbox-8 1.0
-- by cveinnt
-- originally by blokatt
-- @cveinnt | cveinnt.github.io

-- game
palette = {8, 14, 9, 10, 15, 11, 3, 12, 13, 5, 4, 6, 7, 2, 1} 
sand = {} 
cur_x = 64
cur_y = 64
last_x = 64
last_y = 64
any_moved = true 
colour = 1 
lmbp = 0
lmbp2 = 0
brush = 1
sine = 0

-- buttons
do_function = false
b_function = nil

-- intro and fading
fallspeed = 0
state = 0
fade = 1
fadestate = 0
timer = 60

-- mouse support
poke(0x5f2d, 1)

function _init()
	cls()
	sfx(6)
end

-- detect 1-frame button push 
function push()
	if (lmbp == 1) return true
	return false
end


function add_sand(x, y, col)
	x = x - 1 + flr(rnd(3))
	x = max(0, min(x, 127))
	y = y - 1 + flr(rnd(3))
	y = max(9, min(y, 119))

 	-- y-climbing
	local pass = true
	while not is_free(x, y+1) or (y == 119 and not is_free(x, y - 1)) do
		y -= 1
		if (y <= 8) break
	end

	if (y <= 4) pass = false
	if pass then
		local a = {}
		a.x = x
		a.y = y
		a.vy = 1
		a.first = true
		a.col = col
		a.move = 200
		add(sand, a)
	end
end

function is_free(x, y)
	if (sget(x, y) == 0) return true
	return false
end

function sand_update(a) 
	-- clear last position 
	sset(a.x, a.y, 0)

	-- deactivation timer
	if (a.x < last_x - 4 or a.x > last_x + 4 or a.y < last_y - 5 or a.y > last_y + 15) a.move -= 1

	-- physics
	local side = false
	for i = 1, a.vy do
		if is_free(a.x,a.y+1) and a.y < 119 then
			a.y += 1
			if (a.move < 100) a.move = 100
			any_moved = true
		else
			if (a.first) then
				last_x = a.x
 				last_y = a.y 
 				a.first = false
			end
 			if (a.y < 119) side = true
			break
		end
	end
	a.vy += rnd(.5)
	if side then
 		local right = true
		local air = is_free(a.x, a.y + 1)
	 	if (is_free(a.x-1, a.y) and is_free(a.x-1, a.y+1) and a.x > 0 and not air) then
	 		a.x -= 1
	 		a.y += 1
	 		a.move = 140
	 		any_moved = true
		else
			if (is_free(a.x+1, a.y) and is_free(a.x+1, a.y+1) and a.x < 127 and not air) then
	 			a.x += 1
	 			a.y += 1
	 			a.move = 140
	 			any_moved = true
	 		end	
		end
 	end

 	-- draw grain
 	sset(a.x, a.y, a.col)

 	-- sand deactivation
 	if (a.move <= 0 or a.y == 119) then
 		if (a.y != 119) then
	 		del(sand, a)
	 	else
	 		del(sand, a)
	 	end
	end	     	
end

function _update()
	if (fadestate == 0) then
		fade -= fade / 5
	end

	-- intro
	if (state == 0) then
		timer -= 1
		if (timer <= 0) then
			local pass = true
			local nexty, v, offset, multiplier, suboffset, yto
			for x = 8127, 0, -1 do
				offset = 0x6000 + x
				v = peek(offset)
				if (v != 0) then
					pass = false
					multiplier = 1
					suboffset = offset + 64
					if (peek(suboffset) == 0) then
						yto = flr(fallspeed)
						while multiplier < yto do
							if (suboffset + 64 < 0x6000) break
							if (peek(suboffset + 64) != 0) then
								sfx(flr(7 + rnd(1) + .5))
								break
							else
								multiplier += 1
								suboffset += 64 
							end	
						end
						if (rnd(50) <= 1) v = 0
						poke(suboffset, v)
						poke(offset, 0)
					end
				end
			end

			for x = 0, 50 do
				poke(0x7f00 + flr(rnd(0x100)), 0)
				pset(rnd(128), 120 + rnd(8), 0)
			end
			fallspeed += .25
			if (timer <= -60) then
				state = 1
				fade = 1
			end
		end
	end

	-- game
	if (state == 1) then
		sine += .1
		-- ui single button fire 
		if (not btn(4) and stat(34) == 0 and lmbp == 2) then
			lmbp = 0
		end
		if (lmbp == 1) then
			lmbp = 2
		end
		
		if ((btn(4) or stat(34) == 1) and lmbp == 0) then
			lmbp = 1
		end

		-- sand button ui slide fix
		if ((btn(4) or stat(34) == 1) and lmbp2 == 0 and cur_y > 8 and cur_y < 120 and lmbp != 2) then
			lmbp2 = 1
		end
		if (not btn(4) and stat(34) == 0 and lmbp2 == 1) then
			lmbp2 = 0
		end

		if (stat(32) != mx or stat(33) != my) then
			cur_x = stat(32)
			cur_y = stat(33)
		end

		mx = stat(32)
		my = stat(33)

		-- button controls
		local sp = 0
		if (btn(5) and cur_y > 8 and cur_y < 120) sp = 1
		if (btn(1)) cur_x += 1 + sp
		if (btn(0)) cur_x -= 1 + sp
		if (btn(3)) cur_y += 1 + sp
		if (btn(2)) cur_y -= 1 + sp

		-- y-boundary while sanding
		if (lmbp2 == 1) then
			cur_y = min(max(cur_y, 9), 119)
		end

		-- makin sand		
		if ((btn(4) or stat(34) == 1) and lmbp2 == 1 and cur_y > 8) then
		 	local c = palette[colour]
		 	if (colour == 16) c = palette[1 + flr(rnd(8))]
		 	for i = 0, brush do
		 		add_sand(cur_x, cur_y, c)
		 	end
		 	if (push()) music(0, 5000 - brush * 2000)
		else
			music(-1, 100)
		end

		-- colour selection
		if (cur_y <= 8 and push()) then
			for i = 0, 16 do
				if (cur_x >= i*8 and cur_x <= i*8 + 7) then
			 		sfx(1)
			 		colour = i+1 
				end
			end
		end

		-- cursor boundaries
	 	cur_x = max(1, min(128, cur_x))
		cur_y = max(0, min(127, cur_y))

		any_moved = false
		foreach(sand, sand_update)
		if (not any_moved) then
			destroy_sand()
		end
	end
end

function add_button(x, y, str, func)
	local x0 = x
	local y0 = y
	local x1 = x + 4 * #str
	local y1 = y + 5 * #str
	local hover = false

	if (cur_x >= x0 and cur_y >= y0 and cur_x <= x1 and cur_y <= y1) hover = true	
	if (hover) then
		print_fat(x, y, str, 13, 7)
		if (push()) then
			b_function = func
			do_function = true
			sfx(3)
		end
	else
		print_fat(x, y, str, 13, 6)
	end
end

function print_fat(x, y, str, c0, c1)
	print(str, x - 1, y, c0)
	print(str, x - 1, y - 1, c0)
	print(str, x - 1, y + 1, c0)
	print(str, x + 1, y - 1, c0)
	print(str, x + 1, y + 1, c0)
	print(str, x + 1, y, c0)
	print(str, x, y - 1, c0)
	print(str, x, y + 1, c0)
	print(str, x, y, c1)
end

function print_fat_center(x, y, str, c0, c1)
	local xoff = (#str * 4) / 2
	print(str, x - 1 - xoff, y, c0)
	print(str, x - 1 - xoff, y - 1, c0)
	print(str, x - 1 - xoff, y + 1, c0)
	print(str, x + 1 - xoff, y - 1, c0)
	print(str, x + 1 - xoff, y + 1, c0)
	print(str, x + 1 - xoff, y, c0)
	print(str, x - xoff, y - 1, c0)
	print(str, x - xoff, y + 1, c0)
	print(str, x - xoff, y, c1)
end

function _draw()
	
	-- intro
	if (state == 0) then
		if (timer > 0) then
			cls()
			print_fat_center(64 - fade * 150, 55, "sandbox-9.0.0", 13, 6)
			print_fat_center(64 + fade * 150, 63, "by @cveinnt", 2, 13)
			print_fat_center(64 - fade * 150, 71, "august 2020", 2, 13)
		end
	end

	-- game
	if (state == 1) then
		cls()

		-- draw canvas
		sspr(0, 8, 128, 119, 0, 8)

		-- colour selection
		rectfill(0, 120, 127, 127, 2)
		rectfill(0, 0, 127, 8, 2)
		palt(0, false)
		spr(3, 120, 0)

		for i = 0, 15 do
			local xo = i * 8
			if (i < 15) then
		 		spr(0, xo, 0)
		 		rectfill(2+xo, 2, 5+xo, 5, palette[i+1])
			end	
			if (colour - 1 == i) then
				rect(1+xo, 1, 6+xo, 6, 6+flr(sin(sine) + .5))
			end
		end
		
		palt()

		line(0, 8, 127, 8, 1)
		line(0, 120, 127, 120, 1)

		-- bottom bar 
		do_function = false
		add_button(3, 122, "-new-", clear_canvas)
		add_button(26, 122, "-save-", save_canvas)
		add_button(54, 122, "-load-", load_canvas)
		add_button(82, 122, "-brush: " .. brush+1 .. "x-", function() brush = (brush + 1) % 3 end)
		
		-- execute selected action
		if (do_function) b_function()

		-- cursor sprites
		if (cur_y <= 8 or cur_y >= 120) then
			spr(2, cur_x-1, cur_y-1)
		else	
			spr(1, cur_x-3, cur_y-3)
		end

		-- fading
		if (fade > .15) then
			palt(7, true)
			palt(0, false)
			for x = 0, 16 do
				for y = 0, 16 do
					spr(4 + 10 * fade, x * 8, y * 8)
				end
			end
			palt()
		end
	end
end

function destroy_sand()
	for a in all(sand) do
		del(sand, a)
	end
end

function save_canvas() 
	sfx(5)
	for a in all(sand) do
		sset(a.x, a.y, 0)
		del(sand, a)
	end
	cstore(0, 0, 0x2000, "sandbox-8")
end

function load_canvas() 
	destroy_sand() 
	reload(0, 0, 0x2000, "sandbox-8")
	sfx(4)
end

function clear_canvas() 
	destroy_sand() 
	sfx(2)
	local done = false
	palt(7, true)
	
	local frame = 0
	while (frame < 12) do
		palt(0, false)
		done = true
		
		for y = 0, 127 do
			for x = 0, 127 do
				sset(x, y + 8, sget(32 + x % 8 + 8 * frame, y % 8))
			end
		end
		
		sspr(0, 9, 128, 111, 0, 9)
		flip()
	
		frame += 1
	end
	palt()
end

__gfx__
dddddddd0002000002000000dddddddd077707770777077707070707070707070707070707070707000700070007000700000000000000000000000000000000
d000000d0007000027200000d000000d777777777777777777777777707770777077707770707070707070707070707070707070707070707000700000000000
d000000d0027200027720000d08abc0d770777070707070707070707070707070707070707070707070707070700070007000700000000000000000000000000
d000000d2770772027772000d08abc0d777777777777777777777777777777777770777070707070707070707070707070707070707070700070007000000000
d000000d0027200027777200d08abc0d077707770777077707070707070707070707070707070707000700070007000700000000000000000000000000000000
d000000d0007000027722000d08abc0d777777777777777777777777707770777077707770707070707070707070707070707070707070707000700000000000
d000000d0002000002272000d000000d770777070707070707070707070707070707070707070707070707070700070007000700000000000000000000000000
dddddddd0000000000020000dddddddd777777777777777777777777777777777770777070707070707070707070707070707070707070700070007000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
d000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd555555d
d088880dd0eeee0dd099990dd0aaaa0dd0ffff0dd0bbbb0dd033330dd0cccc0dd0dddd0dd055550dd044440dd066660dd077770dd022220dd011110dd58abc5d
d088880dd0eeee0dd099990dd0aaaa0dd0ffff0dd0bbbb0dd033330dd0cccc0dd0dddd0dd055550dd044440dd066660dd077770dd022220dd011110dd58abc5d
d088880dd0eeee0dd099990dd0aaaa0dd0ffff0dd0bbbb0dd033330dd0cccc0dd0dddd0dd055550dd044440dd066660dd077770dd022220dd011110dd58abc5d
d088880dd0eeee0dd099990dd0aaaa0dd0ffff0dd0bbbb0dd033330dd0cccc0dd0dddd0dd055550dd044440dd066660dd077770dd022220dd011110dd58abc5d
d000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd000000dd555555d
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
67777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
66677777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777766666
66667777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777666666
66666777777777777776677777777777777777777777777777777777777777777777777777777777777777777777777777777777667777777777777776666666
66666677777777777766667777777777777777777777777777777777777777777777777777777777777777777777777777777776666777777777777766666666
66666667777777666666666677677777777777777777777777777777777777777777777777777777777777777777777777777666666677777777777666666666
66666666776676666666666666667777777777777777777777777777777777777777776777777777777777777777777777776666666667777777776666666611
16666666666666666666666666666777777777777777777777777777777777777777766667777777777776777777777777766666666666777777766666666111
11666666666666666666666666666677777766677667777777777777777777777777666666777777776666667777777776666666666666667667666666611111
51116666666666666666666666666667776666666666677777777777777777777766666666677676666666666667777766666666111166666666666611115111
55111666666611666666666666666666666666666666666677777666666667777666666666666666666611166666766666666661115116666666666111555551
55511111116111161116666666666666666166111166666666776666666666766666666666666666666111116666666666666611155511666666611155555555
55551111111111111111111666666666661111111116666666666666666666666666666666666666611111111666666666661111555551116116115555555555
55555511115511111111111116161116611111511111166666666666111666666666666666661116111511111166666666111155555555111111155555ccc555
5555555155555111115111151111111111111555551111166666666111116666666666666661111155555511111666611111555555555551111155cc5ccccc55
555555555555555555555555511111111551555555551111166611155155116666666661611115155555555511111111111555555555c5551555cccccccccccc
555555555555555555555c5555555511555555555555515111611155555551111166611111115555cc5555555555111111555555ccccccc5555ccccccccccccc
5555555555555555555ccccc55555555555555ccc555555511115555ccc55555111611111155555cccc55cc5555555555555555ccccccccc55cccccccccccccc
c55555555555555555ccccccccc555555555cccccc5555555155555cccccc55551115555555555cccccccccc5555c555555555cccccccccccccccccccccccccc
cc55555cccc555555ccccccccccc5555555cccccccc55555555555cccccccc55551555555555cccccccccccccccccc555555cccccccccccccccccccccccccccc
ccc55ccccccc55cccccccccccccccc5555cccccccccc555555555cccccccccc555555555c55cccccccccccccccccccc5555ccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc555555cccccccccccc55555ccccccccccccccccccccccccccc55cccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc555ccccccccccccccc555cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc7766cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccfff766ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccfffff766cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccffffff7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccffffffff7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccffffffffff7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccffffffffffff7777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccffffffffffffff7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccffffffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cffffffffffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
fffffffffffffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
fffffffffffffffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
fffffffffffffffffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
fffffffffffffffffffffffffffffffffffffff7677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ffffffffffffffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
fffffffffffffffffffffffffffffffffffffffff7677cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaccccccccccccccc
fffffffffffffffffffffffffffffffffffffffffff677ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaccccccccccccc
ffffffffffffffffffffffaafffffffffffffffffffff77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaacccccccccccc
ffffffffffffffffffffaaaaaaafffffffffffffffffff77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaccccccccc
aaaffffffffffffffaaaaaaaaaaaffffffffffffffffff7776ccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaacccccccc
aaaaaaffffffffffaaaaaaaaaaaaaaffaffffffffffffff7777cccccacaacccccaccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaccccccc
aaaaaaaaaafffafaaaaaaaaaaaaaaaaaaaaaffffffffaaaaa677cccaaaaaaaaaaaaaccccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacc
aaaaaaaaaaaaaaaaaaaaa9999aaaaaaaaaaaaaaaaaaaaaaaaaa77aaaaaaaaaaaaaaaacccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9a
aaaaaaaa9aaaaaaaaaaa999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaa99999a9999
9aaaaaa999aaaaaaaaa9999999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaccacccccccaaaccaaaaaaaaaaaaaaaaaaaaaaaaaa999999999999
99aaaa999999aaaaaa999999999999aa9aaaaaa9a99aaa99aaaaaaaaaa99aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99999aaaaaaaaaaa9999999999999999
99999999999999a9999999999999999999999a99999999999a99aa99999999aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99999999aaa9aaaa999999999999999999
999999999999999999999999999999999999999999999999999999999999999999999aa99aaaaaa9aaaaaa9999a99999999999999999a9999999999999999994
999999999999999999999999999999999999999999999999999999999999999999999999999aaa9999aaa9999999999999999999999999999999999999999944
99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999444
49999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994444
44999999999999999999999999999999999499999999999999999999999999999999999999999999999999999999999999999999999999999999999999444444
44499999999999999999999999999999944449999999999999999999999999999999999999999999999999999999999999999999999999999999999994444444
44444999999999999999999999999999444444999999999999999999999999444944999999999999999999999999999999999999999999449999994444444444
44444499994444999999999944999944444444449499999999994444499994444444444999999999999999949999999999444944499944444949944444444444
44444449444444444444499444494444444444444449999999444444449944444444444499999994999994444494499944444444449444444444444444554444
44444444444444444444444444444444444444444444499494444444444444444444444449999444499444444444444444454444444444444444444455555444
55544444444444444444444444444444544444444444444444444444444444444554444444944444444445444454454445555544444444444444445555555544
55555544444445444454444445444455555555455454444444454544545444545555554444444445455555555555555555555555454444555444455555555554
55555555445555555555455555544555555555555555555545555555555545555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222ddddddddddddd22222222222dddddddddddddddd22222222222ddd22ddddddddddd222222222222ddddddddddddddddddddd2222222ddddddddd222222
222222d77dd777d7d7d2222222222dd66d666d6d6d666d22222222222d6d2dd66d666d66dd22222222222d666d666d6d6dd66d6d6dddd2222d666d6d6d222222
22ddddd7d7d7ddd2d7ddddd22ddddd6ddd6d6d6d6d6ddddddd222ddddd6d2d6d6d6d6d6d6ddddd222ddddd6d6d6d6d6d6d6ddd6d6dd6d2222ddd6d6d6ddddd22
22d777d7d7d77d2727d777d22d666d666d666d6d6d66dd666d222d666d6d2d6d6d666d6d6d666d222d666d66dd66dd6d6d666d666dddd22222d66dd6dd666d22
22ddddd7d7d7dd2772ddddd22ddddddd6d6d6d666d6ddddddd222ddddd6ddd6d6d6d6d6d6ddddd222ddddd6d6d6d6d6d6ddd6d6d6dd6d2222ddd6d6d6ddddd22
222222d7d7d777277722222222222d66dd6d6dd6dd666d22222222222d666d66dd6d6d666d22222222222d666d6d6dd66d66dd6d6dddd2222d666d6d6d222222
222222dddddddd277772222222222ddddddddddddddddd22222222222ddddddddddddddddd22222222222ddddddddddddddddddddd2222222ddddddddd222222

__sfx__
00030020136101e6101a6101f6101961018610106101961021610206101b61014610156101d610156100f610116101d6101d610166101e61021610196101c610286101e610166101b61022610186101c6101c610
00010000194101b4101b31020300083002341025410293102a3100630007300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000010100451006010075100b0100c5200e0200f530110401454015040165401704018540180401754016040165401604015540140401454013040115400f0400d5400a0400853006020045200102001500
0001000005320053101b3000663005620026102b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000009570095700957020300117701157011770322002b7702b5702b7602b5502b7302b5202b7102b5102b7002b7002b7002b7002b7002c7002d7002c7002c7002b700067000570004700047000470004700
000200002c5702c5702c570203001f7701f5701f7703220025570257702556025750335303372033510337102b7002b7002b7002b7002b7002c7002d7002c7002c7002b700067000570004700047000470004700
0003000003610066200d6300f630136401a66020650276402e630326303863029620206201a6201762013610116100c6000960006600056000360001600066000560004600046000460003600036000360003600
000400000142001400394003a400394003640034400324002e40029400224001d40018400104000e4000c400094000540003400024000140002400024001340011400104000b4000000006400044000140000000
000400000242002000394003a400394003640034400324002e40029400224001d40018400104000e4000c400094000540003400024000140002400024001340011400104000b4000000006400044000140000000
__music__
03 00424344


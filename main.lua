require 'cairo'

-- this is the function used for printing single line of text
-- @ text : the text to print
-- @ x, y : the coordinated to print the text
-- @ size : the size of font to use
-- @ family : the font-family to use
-- @ extents : the cairo text-extents object
-- @ options : the table of options specifying everything that need to layout the text this include
-- 			@ valign : the legal values are 0(for baseline which is the default), 1(for top) and 2(for center)
-- 			@ halign : the legal values are 0(for left which is the default), 1(for right) and 2(for center)
--			@ width : required in case of center and right halign
--			@ height : required in case of center and top valign
--			@ bold, italic : same as cairo_show_text
-- # final_x, final_y : the position where the text was printed
function lineText(text, x, y, size, family, extents, options)

	-- if the options are not provided use the defalut
	if options == nil then
		options = {}
		options.valign = 0
		options.halign = 0
		options.bold = 0
		options.italic = 0
	end

	-- if bold in not given get default
	if options.bold == nil then
		options.bold = 0
	end

	-- if italic is not passed use default
	if options.italic == nil then
		options.italic = 0
	end

	-- set the font family and size of text
	cairo_set_font_size(cr, size)
	cairo_select_font_face(cr, family, options.bold, options.italic)

	-- get the extents of the text
	cairo_text_extents(cr, text, extents)

	-- align the text horizontally
	local final_x = x
	if options.halign == 0 then		-- for left align
		final_x = x
	elseif options.halign == 1 then		-- for right align
		final_x = x + options.width - extents.width
	elseif options.halign == 2 then		-- for center align
		final_x = x + options.width/2 - extents.width/2
	end

	-- vertically align the text
	local final_y = y
	if options.valign == 0 then		-- for baseline
		final_y = y
	elseif options.valign == 1 then		-- for top
		final_y = y + extents.height
	elseif options.valign == 2 then		-- for center
		final_y = y + extents.height/2 + options.height/2
	end

	-- show the text finally
	cairo_move_to(cr, final_x, final_y)
	cairo_show_text(cr, text)

	-- return the final printing position
	return final_x, final_y

end


--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup()

end



-- this function trims spaces from both side a string
-- @ s : the string to trim
-- # s : the trimed string
function trim1(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end



-- this function prints a progress bar style meter
-- @ start_x, start_y : starting cordinate of the line
-- @ width : width of the meter
-- @ value : the percentage of meter to fill
function lineMeter(start_x, start_y, width, value)

	-- thin line
	cairo_stroke(cr)
	cairo_set_line_width(cr, 1)
	cairo_set_source_rgba(cr, 0.7, 0.7, 0.7, 0.5)
	cairo_move_to(cr, start_x, start_y)
	cairo_line_to(cr, start_x+width, start_y)
	cairo_stroke(cr)

	-- thick line
	cairo_set_source_rgba(cr, 1, 1, 1,1)
	cairo_move_to(cr, start_x, start_y)
	cairo_line_to(cr, start_x+width*(value/100), start_y)
	cairo_set_line_width(cr, 5)
	cairo_stroke(cr)

end


-- this function prints a circular meter
-- @ center_x, center_y : starting cordinate of the line
-- @ radius : radius of the meter
-- @ value : the percentage of meter to fill
-- @ suffix : to be added to the value prited in the center if any
function meter(center_x, center_y, radius, value, suffix)

	-- thin circle
	cairo_stroke(cr)
	cairo_set_line_width(cr, 1)
	cairo_set_source_rgba(cr, 0.7, 0.7, 0.7, 0.5)
	cairo_arc (cr, center_x, center_y, radius, 0, 2*math.pi)
	cairo_stroke(cr)

	-- fixing the value
	if value == nil then
		value = 0
	end

	-- thick cirlce
	cairo_set_source_rgba(cr, 1, 1, 1,1)
	cairo_arc (cr, center_x, center_y, radius-2, -math.pi/2, 2*math.pi*(value/100) -math.pi/2)
	cairo_set_line_width(cr, 5)
	cairo_stroke(cr)

	-- value in the center
	local extents = cairo_text_extents_t:create()
	local text = ""
	text = value..suffix
	cairo_set_font_size(cr, radius/2)
	cairo_select_font_face(cr, "Poiret One", 0, 0)
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, center_x-extents.width/2, center_y + extents.height/2)
	cairo_show_text(cr, text)
end


-- the function that is called by conky every interval
function conky_main(  )

	-- if no conky window then exit
	if conky_window == nil then return end

	-- the number of update
	local updates = tonumber(conky_parse("${updates}"))
	-- if not third update exit
	if updates < 1 then return end

	-- prepare cairo drawing surface
	local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
	cr = cairo_create(cs)

	-- for positioning text
	local extents = cairo_text_extents_t:create()
	local text = ""


	-- for finding out the internet connection
	local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'")
	internet = tonumber(file:read("*a"))
	io.close(file)

	-- options for printing text
	local options = {}
	options.valign = 0
	options.halign = 0
	options.width = 0
	options.height = 0
	options.bold = 0
	options.italic = 0

	-- scaling varible
	local scale = 1

	-- variables for layout
	local total_width = conky_window.width*(scale) - conky_window.width/15
	local total_height = conky_window.height*(scale) - conky_window.height/8
	local box_width = total_width
	local box_height = total_height



	-- variables positioning
	local start_x = conky_window.width/30
	local  start_y = 0
	-- cairo_rectangle(cr, start_x, start_y, box_width, box_height)
	-- cairo_stroke(cr)

	local x = start_x
	local y  = start_y



	-- ################################################################################
	-- DATE TIME
	-- ################################################################################
	start_x = conky_window.width/40
	start_y = 40
	box_width = total_width/2
	box_height = total_height/2.8
	cairo_set_source_rgba(cr, 1,1,1,1)



	-- date and time variables
	local hour = conky_parse('${time %I}')
	local minute = conky_parse('${time %M}')
	local second = conky_parse('${time %S}')
	local part = conky_parse('${time %p}')
	local day = conky_parse('${time %d}')
	local month = conky_parse('${time %B}')
	local year = conky_parse('${time %G}')

	-- clock
	options.halign = 2
	options.width = box_width
	x, y = lineText(hour..":"..minute.." "..part, start_x, start_y + box_height/2, box_height/3, "Text Me One", extents, options)

	-- date
	options.halign = 0
	options.valign = 1
	lineText(month.." "..day..", "..year, x + box_width/50, start_y + box_height/2 + box_height/25, box_height/7, "Poiret One", extents, options)



	-- ################################################################################
	-- CPU
	-- ################################################################################

	start_x = conky_window.width/40
	start_y = total_height*(0.55)
	box_width = total_width*(0.22)
	box_height = total_height*(0.45)
	cairo_set_source_rgba(cr, 1,1,1,1)

	-- get the percentage cpu use
	local cpu_value = conky_parse("${cpu}")
	if cpu_value == nil then
		cpu_value = 0
	end

	-- usage meter
	meter(start_x + box_width - box_width/20 - box_height/8 , start_y + box_height/20 + box_height/8, box_height/8, tonumber(conky_parse("${cpu}")), '%')

	-- heading
	options.valign = 1
	options.halign = 0
	x, y = lineText("CPU", start_x + box_width/20, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- cores percentage usage
	local no_of_cores = 2
	for i = 1,no_of_cores do
		local name = "core "..i
		local value = trim1(conky_parse("${top cpu "..i.."}"))
		if value == nil then
			value = 0
		end
		x, y = lineText(name..": "..value.."%", start_x + box_width/14, y + box_height/50, box_height/20, "Text Me One", extents, options)
	end

	-- top ten processes
	y = y + box_height/18
	for i = 1,10 do
		options.halign = 0
		options.valign = 0
		_, _ = lineText(trim1(conky_parse("${top name "..i.."}")), start_x + box_width/20, y + box_height/22 + box_height/120, box_height/24, 'Roboto Light', extents, options)
		options.halign = 1
		options.width = box_width - box_width/18
		x, y = lineText(trim1(conky_parse("${top cpu "..i.."}")).."%", start_x, y + box_height/22 + box_height/120, box_height/24, 'Roboto Light', extents, options)
	end



	-- ################################################################################
	-- Network
	-- ################################################################################

	start_x = conky_window.width/40 + total_width*(0.26)
	start_y = total_height*(0.55)
	box_width = total_width*(0.22)
	box_height = total_height*(0.45)
	cairo_set_source_rgba(cr, 1,1,1,1)

	-- heading
	options.valign = 1
	options.halign = 0
	x, y = lineText("Network", start_x + box_width/20, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- values
	y = y + box_height/120
	-- download speed
	options.halign = 0
	options.valign = 0
	_, _ = lineText('download:', start_x + box_width/20, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)
	local download = trim1(conky_parse("${downspeed eth0}"))
	options.halign = 1
	options.width = box_width - box_width/18
	x, y = lineText(download.."/s", start_x, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)

	-- upload speed
	options.halign = 0
	options.valign = 0
	_, _ = lineText('upload:', start_x + box_width/20, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)
	local download = trim1(conky_parse("${upspeed eth0}"))
	options.halign = 1
	options.width = box_width - box_width/18
	x, y = lineText(download.."/s", start_x, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)



	-- ################################################################################
	-- File System
	-- ################################################################################

	start_x = conky_window.width/40 + total_width*(0.26)
	start_y = y + box_height/15
	box_width = total_width*(0.22)
	box_height = total_height*(0.45)
	cairo_set_source_rgba(cr, 1,1,1,1)

	-- heading
	options.valign = 1
	options.halign = 0
	x, y = lineText("Filesystem", start_x + box_width/20, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- root filesystem
	y = y + box_height/40
	options.halign = 0
	options.valign = 0
	_, _ = lineText('/', start_x + box_width/20, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)
	local used = trim1(conky_parse("${fs_used /}"))
	local total = trim1(conky_parse("${fs_size /}"))
	options.halign = 1
	options.width = box_width - box_width/18
	x, y = lineText(trim1(used).."/"..trim1(total), start_x, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)

	-- root meter
	lineMeter(start_x+box_width/20, y + box_height/30, box_width - box_width/10, tonumber(conky_parse("${fs_used_perc /}")))

	-- home filesystem
	--y = y + box_height/20
	--options.halign = 0
	--options.valign = 0
	--_, _ = lineText('/home', start_x + box_width/20, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)
	--local used = trim1(conky_parse("${fs_used /home}"))
	--local total = trim1(conky_parse("${fs_size /home}"))
	--options.halign = 1
	--options.width = box_width - box_width/18
	--x, y = lineText(trim1(used).."/"..trim1(total), start_x, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)

	-- home meter
	--lineMeter(start_x+box_width/20, y + box_height/30, box_width - box_width/10, tonumber(conky_parse("${fs_used_perc /home}")))



	-- ################################################################################
	-- Power
	-- ################################################################################

	--start_x = conky_window.width/40 + total_width*(0.52)
	--start_y = total_height*(0.55)
	--box_width = total_width*(0.22)
	--box_height = total_height*(0.45)
	--cairo_set_source_rgba(cr, 1,1,1,1)

	-- heading
	--options.valign = 1
	--options.halign = 0
	--x, y = lineText("Power", start_x + box_width/20, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- battery status
	--options.halign = 1
	--options.valign = 0
	--options.width = box_width - box_width/18
	--x, y = lineText(trim1(conky_parse("${battery}")), start_x, y + box_height/18 + box_height/120, box_height/18, 'Text Me One', extents, options)

	-- battery meter
	--lineMeter(start_x+box_width/20, y + box_height/30, box_width - box_width/10, tonumber(conky_parse("${battery_percent}")))



	-- ################################################################################
	-- Disk
	-- ################################################################################

	start_x = conky_window.width/40 + total_width*(0.52)
	start_y = total_height*(0.55)
	box_width = total_width*(0.22)
	box_height = total_height*(0.45)
	cairo_set_source_rgba(cr, 1,1,1,1)

	-- heading
	options.valign = 1
	options.halign = 0
	x, y = lineText("Disk", start_x + box_width/20, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- values
	y = y + box_height/120
	-- write speed
	options.halign = 0
	options.valign = 0
	_, _ = lineText('write:', start_x + box_width/20, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)
	options.halign = 1
	options.width = box_width - box_width/18
	x, y = lineText(trim1(conky_parse("${diskio_write}"))..'/s', start_x, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)

	-- read speed
	options.halign = 0
	options.valign = 0
	_, _ = lineText('read:', start_x + box_width/20, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)
	local download = trim1(conky_parse("${diskio_read}"))
	options.halign = 1
	options.width = box_width - box_width/18
	x, y = lineText(trim1(conky_parse("${diskio_read}"))..'/s', start_x, y + box_height/20 + box_height/120, box_height/20, 'Text Me One', extents, options)



	-- ################################################################################
	-- Uptime
	-- ################################################################################

	start_x = conky_window.width/40 + total_width*(0.52)
	start_y = y + box_height/36
	box_width = total_width*(0.22)
	box_height = total_height*(0.45)
	cairo_set_source_rgba(cr, 1,1,1,1)

	-- heading
	options.valign = 1
	options.halign = 0
	x, y = lineText("Uptime", start_x + box_width/20, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- uptime value
	options.halign = 1
	options.valign = 0
	options.width = box_width - box_width/18
	x, y = lineText(trim1(conky_parse("${uptime}")), start_x, y + box_height/18 + box_height/120, box_height/18, 'Text Me One', extents, options)



	-- ################################################################################
	-- Memory
	-- ################################################################################

	start_x = conky_window.width/40 + total_width*(0.78)
	start_y = total_height*(0.55)
	box_width = total_width*(0.22)
	box_height = total_height*(0.45)
	cairo_set_source_rgba(cr, 1,1,1,1)

	-- usage meter
	meter(start_x + box_width/20 + box_height/8 , start_y + box_height/20 + box_height/8, box_height/8, tonumber(conky_parse("${memperc}")), '%')

	-- heading
	options.valign = 1
	options.halign = 1
	options.width = box_width - box_height/20
	x, y = lineText('Memory', start_x, start_y + box_height/15, box_height/10, "Poiret One", extents, options)

	-- swap percent usage
	local name = "swap "
	local value = trim1(conky_parse("${swapperc}"))
	options.width = box_width - box_width/15
	x, y = lineText(name..": "..value.."%", start_x, y + box_height/50, box_height/20, "Text Me One", extents, options)

	-- top ten processes
	y = y + box_height/18 + box_height/20
	for i = 1,10 do
		options.halign = 0
		options.valign = 0
		_, _ = lineText(trim1(conky_parse("${top_mem name "..i.."}")), start_x + box_width/20, y + box_height/22 + box_height/120, box_height/24, 'Roboto Light', extents, options)
		options.halign = 1
		options.width = box_width - box_width/18
		x, y = lineText(trim1(conky_parse("${top_mem mem_res "..i.."}")), start_x, y + box_height/22 + box_height/120, box_height/24, 'Roboto Light', extents, options)
	end

	-- destroying the cairo surface
	cairo_destroy(cr);
	cairo_surface_destroy(cs);
	cr=nil;

end

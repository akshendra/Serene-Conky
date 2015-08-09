require 'cairo'


-- the funtion which paints the image passed
-- @ ir : cairo context
-- @ startx, starty : top left co-ordinates of image
-- @ width, height : dimensions of image
-- @ path : path of the image file (should be png)
function drawImage (ir, startx, starty, width, height, path)

	-- create the surface and get the dimensions
	local w, h;
	local image = cairo_image_surface_create_from_png (path);
	w = cairo_image_surface_get_width (image);
	h = cairo_image_surface_get_height (image);
	cairo_new_path (ir);


	-- scale to appropriate size, ie the given dimensions
	cairo_scale(ir, width/w, height/h);
	w = cairo_image_surface_get_width (image);
	h = cairo_image_surface_get_height (image);

	-- paint the surface
	cairo_set_source_surface (ir, image, startx*(1/(width/w)), starty*(1/(height/h)));
	cairo_paint (ir);

	print('Drawing Image : ' .. path)

	-- all done destroy the surface
	cairo_surface_destroy (image);
	cairo_destroy(ir);

	return startx + width, starty + height

end


-- this is the function used for printing single line of text
-- @ text : the text to print
-- @ x, y : the coordinated to print the text
-- @ size : the size of font to use
-- @ family : the font-family to use
-- @ text_ext, font_ext : the cairo text-extents and font_extents objects
-- @ options : the table of options specifying everything that need to layout the text this include
--      @ valign : the legal values are 0(for baseline which is the default), 1(for top) and 2(for center)
--      @ halign : the legal values are 0(for left which is the default), 1(for right) and 2(for center)
--      @ width : required in case of center and right halign
--      @ height : required in case of center and top valign
--      @ bold, italic : same as cairo_show_text
-- # final_x, final_y : the position where the text was printed
function lineText(text, x, y, size, family, text_ext, font_ext, options)

  -- if the options are not provided use the defalut
  if options == nil then
    options = {};
    options.valign = 0;
    options.halign = 0;
    options.bold = 0;
    options.italic = 0;
  end

  -- if bold in not given get default
  if options.bold == nil then
    options.bold = 0;
  end

  -- if italic is not passed use default
  if options.italic == nil then
    options.italic = 0;
  end

  -- if halign is not passed use default
  if options.halign == nil then
    options.halign = 0;
  end

  -- if halign is not passed use default
  if options.valign == nil then
    options.valign = 0;
  end

  -- set the font family and size of text
  cairo_set_font_size(cr, size);
  cairo_select_font_face(cr, family, options.bold, options.italic);

  -- get the extents of the text
  cairo_text_extents(cr, text, text_ext);
  cairo_font_extents(cr, font_ext);

  -- align the text horizontally
  local final_x = x;
  if options.halign == 0 then   -- for left align
    final_x = x;
  elseif options.halign == 1 then   -- for right align
    final_x = x + options.width - text_ext.width;
  elseif options.halign == 2 then   -- for center align
    final_x = x + options.width/2 - text_ext.width/2;
  end

  -- vertically align the text
  local final_y = y;
  if options.valign == 0 then   -- for baseline
    final_y = y;
  elseif options.valign == 1 then   -- for top
    final_y = y + font_ext.height;
  elseif options.valign == 2 then   -- for center
    final_y = y + options.height/2 + font_ext.height/2;
  end

  -- show the text finally
  cairo_move_to(cr, final_x, final_y - font_ext.descent);
  cairo_show_text(cr, text);

  -- return the final printing position
  return final_x + text_ext.width, final_y;

end


-- thanks to dasblinkenlight (stackoverflow)
-- function explode slipts the string at spaces and put them into a table
-- @ s : string to explode
-- # words : a table of words
-- # count : the mumber of words
function explode(s)

  local words = {};
  local count = 0;

  -- split the string
  for value in string.gmatch(s,"[%S]+") do
    count = count + 1;
    words[count] = value;
  end

  return count, words;

end

-- a function to print multiline text propery layout with word wrapping ofcourse
-- @ text : the text to print
-- @ x, y : the coordinated to print the text
-- @ width : the extent to which every line can be extended
-- @ size : the size of font to use
-- @ family : the font-family to use
-- @ text_ext, font_ext : the cairo text-extents and font_extents objects
-- @ options : the table of options specifying everything that need to layout the text this include
--      @ halign : the legal values are 0(for left which is the default), 1(for right) and 2(for center)
--      @ bold, italic : same as cairo_show_text
-- # final_x, y : the position where the text was printed
function multiText(text, x, y, width, height, size, family, text_ext, font_ext, options)

  -- first use explode to convert the text into array of words
  local count, words = explode(text);

  -- if the options are not provided use the defalut
  if options == nil then
    options = {};
    options.valign = 1;
    options.halign = 0;
    options.width = width;
    options.bold = 0;
    options.italic = 0;
  end

  -- if bold in not given get default
  if options.bold == nil then
    options.bold = 0;
  end

  -- if italic is not passed use default
  if options.italic == nil then
    options.italic = 0;
  end

  -- set up the options width anyways
  if options ~= nil then
    options.width = width;
  end


  -- set the font family and size of text
  cairo_set_font_size(cr, size);
  cairo_select_font_face(cr, family, options.bold, options.italic);

  -- now get the extents
  cairo_text_extents(cr, text, text_ext);
  cairo_font_extents(cr, font_ext);

  -- now find out the lines
  local no_of_lines = 1;
  local lines = {};
  lines[no_of_lines] = words[1];
  for i = 2, count do
    -- check if adding the next words will cross the width available
    cairo_text_extents(cr, lines[no_of_lines]..' '..words[i], text_ext);
    -- if not then add the word
    if text_ext.width <= width then
      lines[no_of_lines] =lines[no_of_lines]..' '..words[i];
    else
      no_of_lines = no_of_lines + 1;
      lines[no_of_lines] = words[i];
    end
  end

  local final_x;
  for i = 1, no_of_lines do
    final_x, y = lineText(lines[i], x, y , size, family, text_ext, font_ext, options);
  end

  return final_x, y, no_of_lines;

end


-- see if the file exists
-- @file : path of the file to check
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end


-- get all lines from a file, returns an empty
-- list/table if the file does not exist
-- @file : path of the file to read lines from
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end


-- reads the weather from Downloads/weather.txt
function readWeather()
	-- read the weather file
	print('Reading the weather:')
	weather_file = lines_from('Downloads/weather.cml')
	-- print the line
	for index, line in pairs(weather_file) do
		_,_,key, value = line:find('([%a%d_]+):(.+)')
		print(key..value)
		weather[key] = value
	end
end


--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup()

	-- global variables to hold the data
	weather = {}
	weather['status'] = 'EMPTY'

	-- a global to tell if the script is running for the first time
	start_weather = true

end

-- function main that is called everty time the script is run
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
	local font_ext = cairo_font_extents_t:create();

    local text = ""

    -- date and time variables
	local hour = tonumber(conky_parse('${time %I}'))
	local minute = tonumber(conky_parse('${time %M}'))
	local second = tonumber(conky_parse('${time %S}'))

    -- if the weather is to be update this time
    local update_weather = false

    -- update the weather every nine minutes
    if (hour * 3600 + minute * 60 + second) % 555  <= 3 then
        update_weather = true
    end

    -- if this the first time
    if start_weather then
        update_weather = true
        start_weather = false
    end


    print('Time since last update (update at 555): ' .. (hour * 3600 + minute * 60 + second) % 555)

    -- read the weather
    if update_weather then
        readWeather()
    end

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
    local x = start_x
	local y  = start_y

	-- lets print the weather
	start_x = conky_window.width/2
	start_y = 0;
	box_width = total_width/2
	box_height = total_height/2.8
	cairo_set_source_rgba(cr, 1,1,1,1)

	print('Weather data status: ' .. weather['status'])

	-- if the status is FILLED that means we have the data
	if weather['status'] == 'FILLED' then

		-- draw the icon
		local image_path = 'Icons/' .. weather['icon'] .. '.png'
		if file_exists == false then
			image_path = 'Icons/default.png'
		end
		local ir = cairo_create(cs);
		x, y = drawImage(ir, start_x + box_width*(0.02), start_y + box_height*(0.05), box_height*(0.30), box_height*(0.30), image_path)

		-- cairo_rectangle(cr, start_x + box_width*(0.02), start_y + box_height*(0.05), box_height*(0.30), box_height*(0.30))
		-- cairo_stroke(cr)

		-- print the current temperature
		options.valign = 1
		_, _ = lineText(weather['temperature'] .. '°' .. weather['temp_unit'], x + box_width*(0.01), start_y + box_height*(0.05), box_height*(0.20), 'Text Me One', extents, font_ext, options)


		-- print the apparent temprature
		options.valign = 0
		_, y = lineText('Feels like ' .. weather['feel'] .. '°' .. weather['temp_unit'] , x + box_width*(0.01), y , box_height*(0.07), 'Roboto Thin', extents, font_ext, options)

		-- print summary
        options.valign = 1
        _, y = lineText(weather['1_summary'] , start_x + box_width*(0.05), y , box_height*(0.06), 'Roboto Light', extents, font_ext, options)

		-- print min and max temperatures
		options.valign = 1
		_, y =  lineText('Minimum ' .. weather['1_minTemp'] .. '°' .. weather['temp_unit'], start_x + box_width*(0.05), y + box_height*(0.01) , box_height*(0.06), 'Text Me One', extents, font_ext, options)
		_, y =  lineText('Maximum ' .. weather['1_maxTemp'] .. '°' .. weather['temp_unit'], start_x + box_width*(0.05), y , box_height*(0.06), 'Text Me One', extents, font_ext, options)
		_, y =  lineText('Humidity ' .. tonumber(weather['humidity'])*100 .. '%', start_x + box_width*(0.05), y , box_height*(0.06), 'Text Me One', extents, font_ext, options)
		_, y =  lineText('Wind ' .. weather['wind'] .. weather['speed_unit'] , start_x + box_width*(0.05), y , box_height*(0.06), 'Text Me One', extents, font_ext, options)


		-- print a forecast for the coming days
		x = start_x + box_width*(0.53)
		y = start_y + box_height * (0.05)
		_, y = multiText(weather['forecast_summery'], x  , y + box_height*(0.03), box_width*(0.45), box_height, box_height*(0.06), 'Roboto Light', extents, font_ext);

		-- print next three days
		y = y + box_height*(0.05)

		-- day 1
		-- placeholder for the image
		local image_path = 'Icons/' .. weather['2_icon'] .. '.png'
		if file_exists == false then
			image_path = 'Icons/default.png'
		end
		local ir = cairo_create(cs);
		x, tempy = drawImage(ir, x, y, box_height*(0.15), box_height*(0.15), image_path)
		x = x + box_height*(0.05)
		-- min and max
		_, y = lineText(weather['2_minTemp'] .. '°' .. weather['temp_unit'] .. ' / ' .. weather['2_maxTemp'] .. '°' .. weather['temp_unit'] , x, y , box_height*(0.06), 'Text Me One', extents, font_ext, options)
		-- summary
		_, y = multiText(weather['2_summary'], x  , y, box_width*(0.35), box_height, box_height*(0.05), 'Roboto Light', extents, font_ext);
		-- check for y
		if y < tempy then
			y = tempy
		end

		-- day 2
		-- placeholder for the image
		x = start_x + box_width*(0.53)
		y = y + box_height*(0.05)
		local image_path = 'Icons/' .. weather['3_icon'] .. '.png'
		if file_exists == false then
			image_path = 'Icons/default.png'
		end
		local ir = cairo_create(cs);
		x, tempy = drawImage(ir, x, y, box_height*(0.15), box_height*(0.15), image_path)
		x = x + box_height*(0.05)
		-- min and max
		_, y = lineText(weather['3_minTemp'] .. '°' .. weather['temp_unit'] .. ' / ' .. weather['3_maxTemp'] .. '°' .. weather['temp_unit'] , x, y , box_height*(0.06), 'Text Me One', extents, font_ext, options)
		-- summary
		_, y = multiText(weather['3_summary'], x  , y, box_width*(0.35), box_height, box_height*(0.05), 'Roboto Light', extents, font_ext);
		-- check for y
		if y < tempy then
			y = tempy
		end

		-- day 3
		-- placeholder for the image
		x = start_x + box_width*(0.53)
		y = y + box_height*(0.05)
		local image_path = 'Icons/' .. weather['4_icon'] .. '.png'
		if file_exists == false then
			image_path = 'Icons/default.png'
		end
		local ir = cairo_create(cs);
		x, tempy = drawImage(ir, x, y, box_height*(0.15), box_height*(0.15), image_path)
		x = x + box_height*(0.05)
		-- min and max
		_, y = lineText(weather['4_minTemp'] .. '°' .. weather['temp_unit'] .. ' / ' .. weather['4_maxTemp'] .. '°' .. weather['temp_unit'] , x, y , box_height*(0.06), 'Text Me One', extents, font_ext, options)
		-- summary
		_, y = multiText(weather['4_summary'], x  , y, box_width*(0.35), box_height, box_height*(0.05), 'Roboto Light', extents, font_ext);
		-- check for y
		if y < tempy then
			y = tempy
		end

        print('Updated At: ' .. weather['update_at'])




	end


    -- destroying the cairo surface
	cairo_destroy(cr)
	cairo_surface_destroy(cs)
	cr=nil
end

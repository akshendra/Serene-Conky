require 'cairo'

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

  -- set the default to topline text
  options.valign = 1;

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
    -- print(value);
    words[count] = value;
  end

  return count, words;

end

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
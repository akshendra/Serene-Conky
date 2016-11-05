require 'cairo'
require 'common'

-- reads the weather from Downloads/weather.txt
function readQuote()
    -- read the weather file
    print('Reading the quote:')
    quote_file = lines_from('Downloads/quote.cml')
    -- print the line
    for index, line in pairs(quote_file) do
        _,_,key, value = line:find('([%a%d_]+):(.+)')
        print(key..value)
        quote[key] = value
    end
end


--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup_quote()

    -- global variables to hold the data
    quote = {}
    quote['status'] = 'EMPTY'

    -- a global to tell if the script is running for the first time
    start_quote = true

end

-- function main that is called everty time the script is run
function conky_main_quote(  )

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
    local update_quote = false

    -- update the weather every nine minutes
    if (hour * 3600 + minute * 60 + second) % 555  <= 3 then
        update_quote = true
    end

    -- if this the first time
    if start_quote then
        update_quote = true
        start_quote = false
    end


    print('Time since last update (update at 555): ' .. (hour * 3600 + minute * 60 + second) % 555)

    -- read the weather
    if update_quote then
        readQuote()
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

    -- lets print the quotes
    start_y = conky_window.height/2.8;
    box_width = total_width
    box_height = total_height/6
    cairo_set_source_rgba(cr, 1,1,1,1)
    y = start_y

    -- cairo_rectangle(cr, start_x, start_y, box_width, box_height)
    -- cairo_stroke(cr)

    print('Quote data status: ' .. quote['status'])


    -- if the status is FILLED that means we have the data
    if quote['status'] == 'FILLED' then
      -- decide which quote to print
      local which_quote = (minute*60 + second)/720
      which_quote = which_quote - which_quote%1 + 1
      -- print the quote
      options.halign = 2
      _, y, _ = multiText(quote[which_quote..'_quote'], start_x + box_width*(0.02) , y + box_height*(0.1), box_width*(0.46), box_height, box_height*(0.15), 'Text Me One', extents, font_ext, options);
      -- print the author name
      options.halign = 1
      options.width = box_width*(0.46)
      x, y = lineText(quote[which_quote..'_author'], start_x + box_width*(0.02) , y + box_height*(0.05), box_height*(0.15), 'Roboto Light', extents, font_ext, options)

    end


    -- destroying the cairo surface
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    cr=nil
end

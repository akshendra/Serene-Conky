require 'cairo'
require 'Core/system'
require 'Core/fact'
require 'Core/quote'
require 'Core/weather'
require 'Core/common'

-- will be used to get flags from config file
function read_config()

    config_file = 'config'

    -- global variables to hold the data
    config = {}
    
    for line in io.lines(config_file) do 
        local module
        local elements
        module, elements = line:match("(%w+)(.*)")
        config[module] = elements
    end 
    --for k, v in pairs( config ) do
    --    print(k, v)
    --end
end

--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup()

    read_config()

    -- setup modules
    if config["system"] then
        conky_setup_system()
    end
    if config["fact"] then
        conky_setup_fact()
    end
    if config["quote"] then
        conky_setup_quote()
    end
    if config["weather"] then
        conky_setup_weather()
    end
end

-- function main that is called everty time the script is run
function conky_main()
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
    extents = cairo_text_extents_t:create()
    font_ext = cairo_font_extents_t:create();

    cairo_set_source_rgba(cr, 1,1,1,1)

    -- run modules
    if config["system"] then
        local home_element
        local battery_element
        if string.find(config["system"], "home") then home_element = true else home_element = false end
        if string.find(config["system"], "battery") then battery_element = true else battery_element = false end
        print(home_element, battery_element)
        conky_main_system(home_element, battery_element)
    end
    if config["fact"] then
        conky_main_fact()
    end
    if config["quote"] then
        conky_main_quote()
    end
    if config["weather"] then
        conky_main_weather()
    end

    -- destroying the cairo surface
	cairo_destroy(cr);
	cairo_surface_destroy(cs);
	cr=nil;
end

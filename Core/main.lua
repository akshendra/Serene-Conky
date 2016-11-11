require 'cairo'
require 'Core/system'
require 'Core/fact'
require 'Core/quote'
require 'Core/weather'

--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup()
    -- setup modules
    conky_setup_system(false, false)
    conky_setup_fact()
    conky_setup_quote()
    --conky_setup_weather()
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
    conky_main_system()
    conky_main_fact()
    conky_main_quote()
    --conky_main_weather()

    -- destroying the cairo surface
	cairo_destroy(cr);
	cairo_surface_destroy(cs);
	cr=nil;

end

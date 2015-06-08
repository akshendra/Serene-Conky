require "cairo" -- cairo graphic library
local cjson = require "cjson" -- for parsing json data


-- This function prints the text on the screen
-- @text : the text to be printed
-- @x
-- @y
-- @extents : a reference to the cairo_text_extent
-- @size: font size
-- @family
-- @options: lua table defining the following funtions:
-- 	@bold (defalts to normal)
-- 	@italic (defaluts to normal)
-- 	@align: horizontal alignment of text (defaults to left) [valid values are "left", "right", "center"]
-- 	@valign: vertcal alignment of text (defaults to top) [valid values are "top", "baseline", "center"]
--  @widht: when center align must be given, providing x to be the left of the centering field
--  @height: when using center valign it must be given, using y to provide to top of the centering field
function printText(text, x, y, extents, size, family, options)

	-- print(options.align, options.width);

	-- using default options if options is not passed
	if options == nil then
		-- print("NO")
		options = {};
		options.bold = 0;
		options.italic = 0;
		options.align = 'left';
		options.valign = 'baseline';
	end

	-- set the font properties
	cairo_set_font_size(cr, size);
	cairo_select_font_face(cr, family, options.bold, options.italic);

	-- get the dimensions of the text
	cairo_text_extents(cr, text, extents);

	-- align the text horizontally
	local print_x = x;
	if(options.align == 'right') then
		print_x = x - extents.width;
	elseif (options.align == 'center') then
		print_x = x + options.width/2 - extents.width/2;
	end

	-- align the text vertically
	local print_y = y;
	if(options.valign == 'top') then
		print_y = y + extents.height;
	elseif(options.valign == 'center') then
		print_y = y + options.height/2 - extents.height/2;
	end

	-- print the text
	cairo_move_to(cr, print_x, print_y);
	cairo_show_text(cr, text);

	-- return printing co-ordinates
	return print_x, print_y;

end


--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup(  )
	-- checking for internet connection
	local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
	internet = tonumber(file:read("*a"));
	io.close(file);

	-- handling the weather icons
	weather_icon = {};
	weather_icon["01d"] = "/"; weather_icon["01n"] = "+";
	weather_icon["02d"] = "R"; weather_icon["02n"] = "A";
	weather_icon["03d"] = "a"; weather_icon["03n"] = "a";
	weather_icon["04d"] = "1"; weather_icon["04n"] = "1";
	weather_icon["09d"] = "b"; weather_icon["09n"] = "b";
	weather_icon["10d"] = "h"; weather_icon["10n"] = "g";
	weather_icon["11d"] = "G"; weather_icon["11n"] = "G";
	weather_icon["13d"] = "N"; weather_icon["13n"] = "N";
	weather_icon["50d"] = "k"; weather_icon["50n"] = "k";

	-- globals for handling api's data and updating data
	-- true when the scripts run for the first time
	start = true;
	-- handles to data
	weather = "ERROR";
	forecast = "ERROR";
	quote = "ERROR";
	-- boolean to represent the updation of weather, forecast and quote data
	update_weather = true;
	update_forecast = true;
	update_quote = true;

end


-- trims the spaces from trailing ends of a string
-- @s : the string to trim
function trim1(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


-- draw a progress bar type widget
-- @cr : cario handle
-- @start_x : the starting x prosition of line
-- @stary_y
-- @widht : the length of line
-- @value : the percentage completed ie to fill
-- @suffix : any suffix to be added to the value while printing it
function lineMeter(cr, start_x, start_y, width, value, suffix)

	-- the thin line
	cairo_stroke(cr);
	cairo_set_line_width(cr, 1);
	cairo_set_source_rgba(cr, 0.7, 0.7, 0.7, 0.5);
	cairo_move_to(cr, start_x, start_y);
	cairo_line_to(cr, start_x+width, start_y);
	cairo_stroke(cr);

	-- the thick line to show the fill
	cairo_set_source_rgba(cr, 1, 1, 1,1);
	cairo_move_to(cr, start_x, start_y);
	cairo_line_to(cr, start_x+width*(value/100), start_y);
	cairo_set_line_width(cr, 5);
	cairo_stroke(cr);

end


-- this function prints a circle meter
-- @cr : cairo handle
-- @center_x, @center_y : the centre of the circle
-- @radius
-- @value : percentage value to fill
-- @suffix : any suffix to add to string that will be concatenated before printing
function meter(cr, center_x, center_y, radius, value, suffix)

	-- the thin circle
	cairo_stroke(cr);
	cairo_set_line_width(cr, 1);
	cairo_set_source_rgba(cr, 0.7, 0.7, 0.7, 0.5);
	cairo_arc (cr, center_x, center_y, radius, 0, 2*math.pi);
	cairo_stroke(cr);

	-- the thick arc
	cairo_set_source_rgba(cr, 1, 1, 1,1);
	cairo_arc (cr, center_x, center_y, radius-2, -math.pi/2, 2*math.pi*(value/100) -math.pi/2);
	cairo_set_line_width(cr, 5);
	cairo_stroke(cr);
	-- cairo_fill(cr);

	-- value
	local extents = cairo_text_extents_t:create();
	local text = "";
	text = value..suffix;
	cairo_set_font_size(cr, radius/2);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, center_x-extents.width/2, center_y + extents.height/2);
	cairo_show_text(cr, text);

end


-- openweathermap.org api data fetch
-- this function gets fetchs the data form the sever or return the stored data
-- @to_update_weahther : ask to a data fetch current weather
-- @to_update_forecast : ask to a data fetch weather forecast
function getWeather(to_update_weather, to_update_forecast)

	------------------------------------------------------------------
	-- ##################### WEATHER #################################
	------------------------------------------------------------------
	-- look for internet connection if available then set for updating weather
	if(to_update_weather) then
		print("NEED TO fetch weather");
		-- checking for internet connection
		local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
		internet = tonumber(file:read("*a"));
		io.close(file);
		if tonumber(internet) == 1 then
			update_weather = true;
		else
			update_weather = false;
			weather = "NO INTERNET";
		end
	end

	-- if this is the start of the time to update
	if update_weather then
		print("UPDATING weather....")
		update_weather = false;

		if(tonumber(internet) == 1) then
			local file = io.popen("curl -m 100  api.openweathermap.org/data/2.5/weather?id=1270454");
			output = file:read("*a");
			io.close(file);
		end

		if (output == "" and output ~= nil) then
				weather = "ERROR";
		else
			weather = cjson.decode(output);
		end
	end

	------------------------------------------------------------------
	-- ##################### FORECAST #################################
	------------------------------------------------------------------

	-- update every hour if there is internet
	if(to_update_forecast) then
		-- checking for internet connection
		local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
		internet = tonumber(file:read("*a"));
		io.close(file);
		if tonumber(internet) == 1 then
			update_forecast = true;
		else
			update_forecast = false;
		end
	end

	-- for the first time and the time of forecast update
	if update_forecast then
		print("UPDATING forecast...")
		update_forecast = false;
		if(tonumber(internet) == 1) then
			local file = io.popen("curl -m 100 'api.openweathermap.org/data/2.5/forecast/daily?id=1270454&mode=json'");
			output = file:read("*a");
			io.close(file);
		end

		if internet ~= 1 then
			forecast = "NO INTERNET";
		end

		if (output == "" and output ~= nil) then
				print("Could not read");
				forecast = "ERROR";
		else
			forecast = cjson.decode(output)["list"];
		end
	end

end


-- prints the weather and also handle and make request for data in case of error
-- @cr : cairo drawing handle
function printWeather(cr)

	local min = tonumber(conky_parse('${time %M}'));
	local extents = cairo_text_extents_t:create();
	local text = "";
	local options = {};
	options.bold = 0;
	options.italic = 0;
	options.align = 'left';
	options.valign = 'baseline';
	options.width = 0;
	options.height = 0;


	-- ask for data at the start
	if(start == true) then
		getWeather(true, true);
	end

	-- if we do not have weather then ask for it every ten minutes other wise ask for it every 30 minutes
	if((weather == 'ERROR' or weather == 'NO INTERNET') and (min % 51) == 0) then
		getWeather(true, false);
	elseif min%30 == 0 then
		getWeather(true, false);
	end

	-- if we do not have forecast then ask for it every ten minutes other wise ask for it every hour
	if((forecast == 'ERROR' or forecast == 'NO INTERNET') and (min % 9) == 0) then
		getWeather(false, true);
	elseif min%60 == 0 then
		getWeather(false, true);
	end

	-----------------------------------------------------------------------------------
	-- print weather
	-----------------------------------------------------------------------------------
	local start_x = 733;
	local start_y = 0;

	print(weather);
	-- if there is not internet connection
	if weather == "NO INTERNET" then

		text = 'no internet connection';
		options.align = "center";
		options.valign = 'baseline';
		options.width = 625;
		x, y = printText(text, start_x, start_y + 125, extents, 30, 'Poiret One', options);

		text = 'will fetch again soon';
		options.align = "center";
		options.valign = 'top';
		options.width = 625;
		printText(text, start_x, y+10, extents, 20, 'Nixie One', options);

	elseif(weather == "ERROR") then

	else

		text = weather["name"]..", "..weather["sys"]["country"];
		-- print(text);
		cairo_select_font_face(cr, "Text Me One", 0, 0);
		cairo_set_font_size(cr, 36);
		cairo_text_extents(cr, text, extents);
		cairo_set_source_rgba(cr, 1, 1, 1, 1);


		-- cairo_set_source_rgba(cr, 1,1,1,0.3);
		-- cairo_rectangle(cr, start_x, 20, 610, 210);
		-- cairo_fill(cr);

		start_x = start_x + 25;
		start_y = start_y + 15;
		local current_x = start_x;
		local current_y = start_y;


		cairo_set_source_rgba(cr, 1,1,1,1);
		cairo_move_to(cr, current_x, current_y + extents.height);
		cairo_show_text(cr, text);

		current_y = current_y + extents.height;
		current_x = current_x + 10;
		local move_x = current_x + extents.width;



		-- print(weather["weather"][1]["icon"]);
		local icon = weather_icon[weather["weather"][1]["icon"]];
		cairo_set_font_size(cr, 54);
		cairo_select_font_face(cr, "dripicons-weather", 0, 0);
		cairo_text_extents(cr, icon, extents);
		cairo_move_to(cr, current_x-10, current_y + 25 + extents.height);
		cairo_show_text(cr, icon);
		current_y = current_y + 15;
		current_x = current_x + extents.width;
		-- cairo_show_text(cr, 'abcdefghijklmnopqrstuvwxyz');
		-- cairo_move_to(cr, 40, 450);
		-- cairo_show_text(cr, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
		-- cairo_move_to(cr, 40, 500);
		-- cairo_show_text(cr, '0123456789-=[];\,./');
		-- cairo_move_to(cr, 40, 550);
		-- cairo_show_text(cr, '_+{}:"|<>?')
		-- cairo_move_to(cr, 40, 600);
		-- cairo_show_text(cr, ')!@#$%^&*(')

		local temp = tonumber(weather["main"]["temp"]) - 273;
		temp = temp - temp%1;
		text = temp.."°C";
		cairo_set_font_size(cr, 34);
		cairo_select_font_face(cr, "Poiret One", 0, 0);
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x + 10, current_y + 5 + extents.height);
		cairo_show_text(cr, text);
		current_y = current_y + 5 + extents.height;

		text = weather["weather"][1]["description"]
		cairo_set_font_size(cr, 20);
		cairo_select_font_face(cr, "Poiret One", 0, 0);
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x + 6, current_y + extents.height);
		cairo_show_text(cr, text);

		current_y = current_y + extents.height + 16;

		current_x = start_x;
		value = tonumber(weather["main"]["temp_min"]) - 273;
		value = value - value%1;
		text = "min: "..value.."°C";
		value = tonumber(weather["main"]["temp_max"]) - 273;
		value = value - value%1;
		text = text.."  max: "..value.."°C";

		cairo_set_font_size(cr, 16);
		cairo_select_font_face(cr, "Text Me One", 0, 0);
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x + 6, current_y + extents.height);
		cairo_show_text(cr, text);

		current_y = current_y + extents.height;

		-- current_x = 703;
		value = tonumber(weather["main"]["pressure"]);
		value = value - value%1;
		text = "pressure: "..value.."hpa";
		cairo_set_font_size(cr, 16);
		cairo_select_font_face(cr, "Text Me One", 0, 0);
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
		cairo_show_text(cr, text);
		current_y = current_y + extents.height + 3;

		value = tonumber(weather["main"]["humidity"]);
		text = "humidity: "..value.."%";
		cairo_set_font_size(cr, 16);
		cairo_select_font_face(cr, "Text Me One", 0, 0);
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
		cairo_show_text(cr, text);
	end

	-- forecating
	-- start_x = move_x + 50;
	-- cairo_set_source_rgba(cr, 1, 1, 1, 0.3);
	-- cairo_move_to(cr, start_x - 25, start_y);
	-- cairo_line_to(cr, start_x - 25, start_y+180);
	-- cairo_stroke(cr);
	-- current_x = move_x + 50;
	-- current_y = start_y + 15;
	-- local day = tonumber(conky_parse('${time %d}'));
	-- local month = conky_parse('${time %B}');

	-- cairo_set_source_rgba(cr, 1, 1, 1, 1);
	-- day = day + 1;
	-- text = day..' '..month;
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	-- cairo_show_text(cr, text);

	-- current_x = current_x + 5;
	-- current_y = current_y + 15;
	-- local icon = weather_icon[forecast[2]["weather"][1]["icon"]];
	-- cairo_set_font_size(cr, 40);
	-- cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	-- cairo_text_extents(cr, icon, extents);
	-- cairo_move_to(cr, current_x, current_y + 15 + extents.height);
	-- cairo_show_text(cr, icon);
	-- current_y = current_y + 10;
	-- current_x = current_x + extents.width;

	-- text = forecast[2]["weather"][1]["description"]
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height);
	-- cairo_show_text(cr, text);

	-- current_y = current_y + extents.height;
	-- move_x = current_x + extents.width + 6;
	-- -- current_x = start_x;
	-- value = tonumber(forecast[2]["temp"]["min"]) - 273;
	-- value = value - value%1;
	-- text = value.."°C";
	-- value = tonumber(forecast[2]["temp"]["max"]) - 273;
	-- value = value - value%1;
	-- text = text.." / "..value.."°C";
	-- cairo_set_font_size(cr, 16);
	-- -- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	-- cairo_show_text(cr, text);


	-- day = day + 1;
	-- text = day..' '..month;
	-- current_x = move_x + 50;
	-- current_y = start_y + 15;
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	-- cairo_show_text(cr, text);

	-- current_x = current_x + 5;
	-- current_y = current_y + 15;
	-- local icon = weather_icon[forecast[3]["weather"][1]["icon"]];
	-- cairo_set_font_size(cr, 40);
	-- cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	-- cairo_text_extents(cr, icon, extents);
	-- cairo_move_to(cr, current_x, current_y + 15 + extents.height);
	-- cairo_show_text(cr, icon);
	-- current_y = current_y + 10;
	-- current_x = current_x + extents.width;

	-- text = forecast[3]["weather"][1]["description"]
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height);
	-- cairo_show_text(cr, text);

	-- current_y = current_y + extents.height;

	-- -- current_x = start_x;
	-- value = tonumber(forecast[3]["temp"]["min"]) - 273;
	-- value = value - value%1;
	-- text = value.."°C";
	-- value = tonumber(forecast[3]["temp"]["max"]) - 273;
	-- value = value - value%1;
	-- text = text.." / "..value.."°C";

	-- cairo_set_font_size(cr, 16);
	-- -- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	-- cairo_show_text(cr, text);
	-- local move_y = current_y + extents.height + 6;


	-- day = day + 1;
	-- text = day..' '..month;
	-- current_x = start_x;
	-- current_y = move_y + 20;
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	-- cairo_show_text(cr, text);

	-- current_x = current_x + 5;
	-- current_y = current_y + 15;
	-- local icon = weather_icon[forecast[4]["weather"][1]["icon"]];
	-- cairo_set_font_size(cr, 40);
	-- cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	-- cairo_text_extents(cr, icon, extents);
	-- cairo_move_to(cr, current_x, current_y + 15 + extents.height);
	-- cairo_show_text(cr, icon);
	-- current_y = current_y + 10;
	-- current_x = current_x + extents.width;

	-- text = forecast[4]["weather"][1]["description"]
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height);
	-- cairo_show_text(cr, text);

	-- current_y = current_y + extents.height;

	-- -- current_x = start_x;
	-- value = tonumber(forecast[4]["temp"]["min"]) - 273;
	-- value = value - value%1;
	-- text = value.."°C";
	-- value = tonumber(forecast[4]["temp"]["max"]) - 273;
	-- value = value - value%1;
	-- text = text.." / "..value.."°C";

	-- cairo_set_font_size(cr, 16);
	-- -- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	-- cairo_show_text(cr, text);



	-- day = day + 1;
	-- text = day..' '..month;
	-- current_x = move_x + 50;
	-- current_y = move_y + 20;
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	-- cairo_show_text(cr, text);

	-- current_x = current_x + 5;
	-- current_y = current_y + 15;
	-- local icon = weather_icon[forecast[5]["weather"][1]["icon"]];
	-- cairo_set_font_size(cr, 40);
	-- cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	-- cairo_text_extents(cr, icon, extents);
	-- cairo_move_to(cr, current_x, current_y + 25 + extents.height);
	-- cairo_show_text(cr, icon);
	-- current_y = current_y + 10;
	-- current_x = current_x + extents.width+10;

	-- text = forecast[5]["weather"][1]["description"]
	-- cairo_set_font_size(cr, 20);
	-- cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height);
	-- cairo_show_text(cr, text);

	-- current_y = current_y + extents.height;

	-- -- current_x = start_x;
	-- value = tonumber(forecast[5]["temp"]["min"]) - 273;
	-- value = value - value%1;
	-- text = value.."°C";
	-- value = tonumber(forecast[5]["temp"]["max"]) - 273;
	-- value = value - value%1;
	-- text = text.." / "..value.."°C";

	-- cairo_set_font_size(cr, 16);
	-- -- cairo_select_font_face(cr, "Text Me One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	-- cairo_show_text(cr, text);
	-- local move_y = current_y + extents.height + 6;

end


function printQuote(cr)

	local extents = cairo_text_extents_t:create();
	local text = "";

	-- cairo_set_source_rgba(cr, 0,0,0,0.25);
	-- cairo_rectangle(cr, 53, 250, 1260, 100);
	-- cairo_fill(cr);

	cairo_set_source_rgba(cr, 1, 1, 1, 0.3);
	cairo_move_to(cr, 53, 250);
	cairo_line_to(cr, 1333, 250);
	cairo_stroke(cr);
	cairo_move_to(cr, 53, 350);
	cairo_line_to(cr, 1333, 350);
	cairo_stroke(cr);

	cairo_set_source_rgba(cr, 1,1,1,1);
	text = quote['contents']['quote'];
	-- print(text);

	cairo_set_font_size(cr, 24);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	if extents.width > 1250 then
		cairo_set_font_size(cr, 18);
	end
	cairo_text_extents(cr, text, extents);
	if extents.width > 1250 then
		cairo_set_font_size(cr, 14);
	end
	cairo_text_extents(cr, text, extents);

	cairo_move_to(cr, 33 + 650 - extents.width/2, 260 + extents.height + 6);
	cairo_show_text(cr, text);

	local move_y = 260 + extents.height + 6;
	local move_x = 33 + 650 + extents.width/2
	text = quote['contents']['author'];
	-- print(text);

	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, move_x - extents.width,  move_y + extents.height + 10);
	cairo_show_text(cr, text);

end

function conky_main(  )

	-- if no conky window then exit
	if conky_window == nil then return end

	-- the number of update
	local updates = tonumber(conky_parse("${updates}"));
	-- if not third update exit
	if updates < 3 then return end

	-- prepare cairo drawing surface
	local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height);
	cr = cairo_create(cs);
	local cj = cjson.new();

	-- for position text
	local extents = cairo_text_extents_t:create();
	local text = "";
	local options = {};
	options.bold = 0;
	options.italic = 0;
	options.align = 'left';
	options.valign = 'baseline';
	options.width = 0;
	options.height = 0;
	-- for finding out the internet connection
	local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
	internet = tonumber(file:read("*a"));
	io.close(file);


	-- for text extents
	-- local content = cjson.decode('{"id": "1"}');
	-- for k, v in pairs(content) do
 -- 		print(k, content[k])
	-- end

	-- date and time
	local hour = conky_parse('${time %I}');
	local minute = conky_parse('${time %M}');
	local second = conky_parse('${time %S}');
	local part = conky_parse('${time %p}');
	local day = conky_parse('${time %d}');
	local month = conky_parse('${time %B}');
	local year = conky_parse('${time %G}');


	-- grids
	-- cairo_move_to(cr,33,0);
	-- cairo_line_to(cr, 33, 700);
	-- cairo_line_to(cr, 1333, 700);
	-- cairo_line_to(cr, 1333, 0);
	-- cairo_line_to(cr, 33, 0);
	-- cairo_move_to(cr, 683, 0);
	-- cairo_line_to(cr, 683, 700);
	-- cairo_move_to(cr, 33, 250);
	-- cairo_line_to(cr, 1333, 250);
	-- cairo_move_to(cr, 33, 350);
	-- cairo_line_to(cr, 1333, 350);
	-- -- cairo_stroke(cr);
	-- cairo_fill_preserve(cr);

	cairo_set_source_rgba(cr, 1,1,1,0.3);
	cairo_rectangle(cr, 53, 20, 610, 210);
	cairo_fill(cr);
	-- Diplomata,Leckerli One,Limelight,Modak,Sacramento


	-- setting the color this is uses throughout
	cairo_set_source_rgba(cr, 1,1,1,1);
	local x, y;

	------------------------------------------------------------------
	-- ##################### CLOCK AND DATE ##########################
	------------------------------------------------------------------

	text = hour..":"..minute.." "..part;
	options.align = 'center';
	options.width = 650;
	x, y = printText(text, 33, 125, extents, 96, "Text Me One", options);
	-- print(y);

	local current_x = x;
	local current_y  = y;

	text = month.." "..day..", "..year;
	options.align = 'left';
	options.valign = 'top';
	x, y = printText(text, current_x, current_y + 20, extents, 36, "Poiret One", options);
	-- print(extents.height, y)

	--------------------------------------------------------------------------

	local start_x = 53;
	local start_y = 370;

	------------------------------------------------------------------
	-- ##################### CPU #####################################
	------------------------------------------------------------------

	-- meter
	local cpu = tonumber(conky_parse("${cpu}"));
	meter(cr, start_x + 285 - 65, start_y + 15 + 45, 45, cpu, '%');

	-- heading
	text = "CPU";
	options.valign = 'top';
	x, y = printText(text, start_x+20, start_y+20, extents, 36, 'Poiret One', options);

	-- cores
	current_y = y + 10;
	current_x = start_x+25;

	local no_of_cores = 2;
	for i = 1,no_of_cores do
		local name = "core "..i;
		local value = conky_parse("${top cpu "..i.."}");
		text = name..":"..value.."%";
		x, y = printText(text, current_x, current_y, extents, 18, 'Text Me One', options);
		current_y = y + 5;
	end

	-- top ten processes
	current_y = current_y + 40;
	current_x = start_x + 20;
	options.valign = 'baseline';
	for i = 1,10 do
		local name = trim1(conky_parse("${top name "..i.."}"));
		local value = trim1(conky_parse("${top cpu "..i.."}"));

		options.align = 'left';
		x, y = printText(name, current_x, current_y, extents, 15, 'Nixie One', options);

		text = value.."%";
		options.align = 'right';
		x, y = printText(text, start_x + 285 - 25, current_y, extents, 15, 'Nixie One', options);

		current_y = current_y + 17;
	end


	--------------------------------------------------------------------------

	start_x = start_x + 285 + 40;
	cairo_set_source_rgba(cr, 1,1,1,1);

	------------------------------------------------------------------
	-- ##################### NETWORK #################################
	------------------------------------------------------------------

	-- heading
	text = "Network";
	options.valign = 'top';
	options.align = 'left'
	x, y = printText(text, start_x+20, start_y+20, extents, 36, 'Poiret One', options);

	-- download/upload speed
	current_y = y + 3;

	local download = conky_parse("${downspeed eth0}");
	text = "download: ";
	options.valign = 'baseline';
	x, y = printText(text, start_x+20, current_y+20, extents, 16, 'Nixie One', options);

	text = trim1(download).."/s";
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y + 20, extents, 16, 'Nixie One', options);

	current_y = y;

	options.align = 'left';
	local upload = conky_parse("${upspeed eth0}");
	text = "upload: ";
	x, y = printText(text, start_x+20, current_y + 20, extents, 16, 'Nixie One', options);

	text = trim1(upload).."/s";
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y + 20, extents, 16, 'Nixie One', options);

	--------------------------------------------------------------------------

	current_y = current_y + 50;

	------------------------------------------------------------------
	-- ##################### FILESYSTEM ##############################
	------------------------------------------------------------------

	-- heading
	text = "Filesystem";
	options.valign = 'top';
	options.align = 'left'
	x, y = printText(text, start_x+20, current_y, extents, 36, 'Poiret One', options);
	current_y = y + 13;

	-- root filesystem
	options.valign = 'baseline';
	x, y = printText("/", start_x+20, current_y + 16, extents, 16, 'Nixie One', options);

	local used = conky_parse("${fs_used /}");
	local total = conky_parse("${fs_size /}");
	text = trim1(used).."/"..trim1(total);

	options.valign = 'baseline';
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y + 16, extents, 16, 'Nixie One', options);

	current_y = y + 13;
	local value = conky_parse("${fs_used_perc /}");
	lineMeter(cr, start_x+20, current_y, 245, value, "%");

	-- /home
	current_y = current_y+15;

	text = "/home";
	options.align = 'left';
	options.valign = 'baseline';
	x, y = printText(text, start_x+20, current_y + 16, extents, 16, 'Nixie One', options);

	local used = conky_parse("${fs_used /home}");
	local total = conky_parse("${fs_size /home}");
	text = trim1(used).."/"..trim1(total);

	options.valign = 'baseline';
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y + 16, extents, 16, 'Nixie One', options);

	current_y = y + 13;
	local value = conky_parse("${fs_used_perc /home}");
	lineMeter(cr, start_x+20, current_y, 245, value, "%");

	--------------------------------------------------------------------------

	start_x = start_x + 285 + 40;

	------------------------------------------------------------------
	-- ##################### POWER #################################
	------------------------------------------------------------------

	-- heading
	text = "Power";
	options.valign = 'top';
	options.align = 'left'
	x, y = printText(text, start_x+20, start_y+20, extents, 36, 'Poiret One', options);
	current_y = y;

	-- battery
	local bat = conky_parse("${battery}");
	options.align = 'right';
	x, y = printText(trim1(bat), start_x+285-20, current_y, extents, 16, 'Nixie One', options);

	current_y = y + 15;
	value = tonumber(conky_parse("${battery_percent}"));
	lineMeter(cr, start_x+20, current_y, 245, value, '%');

	--------------------------------------------------------------------------

	current_y = current_y + 30;

	------------------------------------------------------------------
	-- ##################### DISK #################################
	------------------------------------------------------------------

	-- heading
	text = "Disk";
	options.valign = 'top';
	options.align = 'left'
	x, y = printText(text, start_x+20, current_y + 20, extents, 36, 'Poiret One', options);
	current_y = y;

	-- write
	text = "write: ";
	options.valign = 'baseline';
	x, y = printText(text, start_x+20, current_y + 22, extents, 16, 'Nixie One', options);

	local write = conky_parse("${diskio_write}");
	text = trim1(write).."/s";
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y + 22, extents, 16, 'Nixie One', options);

	-- read
	current_y = y;
	options.align = 'left';
	text = "read: ";
	options.valign = 'baseline';
	x, y = printText(text, start_x+20, current_y + 22, extents, 16, 'Nixie One', options);

	local write = conky_parse("${diskio_read}");
	text = trim1(write).."/s";
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y + 20, extents, 16, 'Nixie One', options);

	--------------------------------------------------------------------------

	current_y = current_y + 30;

	------------------------------------------------------------------
	-- ##################### UPTIME #################################
	------------------------------------------------------------------

	-- heading
	text = "Uptime";
	options.valign = 'top';
	options.align = 'left'
	x, y = printText(text, start_x+20, current_y + 20, extents, 36, 'Poiret One', options);
	current_y = y + 5;

	-- value
	local uptime = conky_parse("${uptime}");
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);

	text = trim1(uptime);
	cairo_text_extents(cr, text, extents);
	options.align = 'right';
	x, y = printText(text, start_x+285-20, current_y, extents, 16, 'Nixie One', options);

	---------------------------------------------------------------------

	start_x = start_x + 285 + 40;

	------------------------------------------------------------------
	-- ##################### RAM #################################
	------------------------------------------------------------------

	-- meter
	local ram = conky_parse("${memperc}");
	meter(cr, start_x + 65, start_y + 15 + 45, 45, ram, '%');

	-- heading
	text = "Memory";
	options.valign = 'top';
	options.align = 'right'
	x, y = printText(text, start_x-20+285, start_y+20, extents, 36, 'Poiret One', options);
	current_y = y + 10;
	current_x = start_x + 25;

	-- swap
	cairo_set_font_size(cr, 18);
	cairo_select_font_face(cr, "Text Me One", 0, 0);

	local swap = conky_parse("${swapperc}");
	text = "swap: "..swap.."%";
	x, y = printText(text, start_x-40+285, current_y, extents, 18, 'Text Me One', options);
	cairo_move_to(cr, current_x + 285 - 60 - extents.width, current_y + extents.height + 5);

	current_y = y + 40;


	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,15);
	for i = 1,10 do
		local name = trim1(conky_parse("${top_mem name "..i.."}"));
		local value = trim1(conky_parse("${top_mem mem_res "..i.."}"));

		options.align = 'left';
		x, y = printText(name, current_x, current_y, extents, 15, 'Nixie One', options);

		text = value.."%";
		options.align = 'right';
		x, y = printText(text, start_x + 285 - 20, current_y, extents, 15, 'Nixie One', options);

		current_y = current_y + 17;
	end

	---------------------------------------------------------------------

	cairo_set_line_width(cr, 1);


	-- this will handle errors as well and call for update more frequetly if weather not available
	printWeather(cr);


	------------------------------------------------------------------
	-- ##################### QUOTE #################################
	------------------------------------------------------------------

	-- update the quotes if there is a internet connection
	if( minute % 60 == 59) then
		-- checking for internet connection
		local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
		internet = tonumber(file:read("*a"));
		io.close(file);
		if tonumber(internet) == 1 then
			update_quote = true;
		else
			update_quote = false;
		end
	end

	if((update_quote and minute%60 == 0) or start == true) then
		update_quote = false;
		start = false;
		if(tonumber(internet) == 1) then
			local file = io.popen("curl -m 100 http://api.theysaidso.com/qod");
			output = file:read("*a");
			io.close(file);
			if (output == "") then
				print("Could not read");
				quote = "ERROR";
			else
				quote = cjson.decode(output);
			end
		end

		if internet ~= 1 then
			quote = "NO INTERNET";
		end


	end

	-- this will print the quote and if they are not availabe will call for updates more frequently
	-- printQuote(cr);
	start = false;

	-- destroying the cairo surface
	cairo_destroy(cr);
	cairo_surface_destroy(cs);
	cr=nil;
end
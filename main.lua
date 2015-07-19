require "cairo" -- cairo graphic library
local cjson = require "cjson"


--  the funtion which will be called at the beginning of the run, used to setup a few global values
function conky_setup(  )
	-- checking for internet connection
	local file = io.popen("/sbin/route -n | grep -c '^0\.0\.0\.0'");
	internet = tonumber(file:read("*a"));
	io.close(file);

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

	weather = "ERROR";
	forecast = "ERROR";
	update_weather = true;
	start = true;
	update_forecast = true;

	quote = "ERROR";
	update_quote = true;

end


function trim1(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function lineMeter(cr, start_x, start_y, width, value, suffix)
	cairo_stroke(cr);
	cairo_set_line_width(cr, 1);
	cairo_set_source_rgba(cr, 0.7, 0.7, 0.7, 0.5);
	cairo_move_to(cr, start_x, start_y);
	cairo_line_to(cr, start_x+width, start_y);
	cairo_stroke(cr);

	cairo_set_source_rgba(cr, 1, 1, 1,1);
	cairo_move_to(cr, start_x, start_y);
	cairo_line_to(cr, start_x+width*(value/100), start_y);
	cairo_set_line_width(cr, 5);
	cairo_stroke(cr);
	-- cairo_fill(cr);

	-- local extents = cairo_text_extents_t:create();
	-- local text = "";
	-- text = value..suffix;
	-- cairo_set_font_size(cr, radius/2);
	-- cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- cairo_text_extents(cr, text, extents);
	-- cairo_move_to(cr, center_x-extents.width/2, center_y + extents.height/2);
	-- cairo_show_text(cr, text);
end



function meter(cr, center_x, center_y, radius, value, suffix)
	cairo_stroke(cr);
	cairo_set_line_width(cr, 1);
	cairo_set_source_rgba(cr, 0.7, 0.7, 0.7, 0.5);
	cairo_arc (cr, center_x, center_y, radius, 0, 2*math.pi);
	cairo_stroke(cr);

	cairo_set_source_rgba(cr, 1, 1, 1,1);
	cairo_arc (cr, center_x, center_y, radius-2, -math.pi/2, 2*math.pi*(value/100) -math.pi/2);
	cairo_set_line_width(cr, 5);
	cairo_stroke(cr);
	-- cairo_fill(cr);

	local extents = cairo_text_extents_t:create();
	local text = "";
	text = value..suffix;
	cairo_set_font_size(cr, radius/2);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, center_x-extents.width/2, center_y + extents.height/2);
	cairo_show_text(cr, text);


end


function printWeather(cr)
	local extents = cairo_text_extents_t:create();
	local text = "";

	text = weather["name"]..", "..weather["sys"]["country"];
	-- print(text);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_set_font_size(cr, 36);
	cairo_text_extents(cr, text, extents);
	cairo_set_source_rgba(cr, 1, 1, 1, 1);
	local start_x = 703;
	local start_y = 20;


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


	-- forecating
	start_x = move_x + 50;
	cairo_set_source_rgba(cr, 1, 1, 1, 0.3);
	cairo_move_to(cr, start_x - 25, start_y);
	cairo_line_to(cr, start_x - 25, start_y+180);
	cairo_stroke(cr);
	current_x = move_x + 50;
	current_y = start_y + 15;
	local day = tonumber(conky_parse('${time %d}'));
	local month = conky_parse('${time %B}');

	cairo_set_source_rgba(cr, 1, 1, 1, 1);
	day = day + 1;
	text = day..' '..month;
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	cairo_show_text(cr, text);

	current_x = current_x + 5;
	current_y = current_y + 15;
	local icon = weather_icon[forecast[2]["weather"][1]["icon"]];
	cairo_set_font_size(cr, 40);
	cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	cairo_text_extents(cr, icon, extents);
	cairo_move_to(cr, current_x, current_y + 15 + extents.height);
	cairo_show_text(cr, icon);
	current_y = current_y + 10;
	current_x = current_x + extents.width;

	text = forecast[2]["weather"][1]["description"]
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height);
	cairo_show_text(cr, text);

	current_y = current_y + extents.height;
	move_x = current_x + extents.width + 6;
	-- current_x = start_x;
	value = tonumber(forecast[2]["temp"]["min"]) - 273;
	value = value - value%1;
	text = value.."°C";
	value = tonumber(forecast[2]["temp"]["max"]) - 273;
	value = value - value%1;
	text = text.." / "..value.."°C";
	cairo_set_font_size(cr, 16);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	cairo_show_text(cr, text);


	day = day + 1;
	text = day..' '..month;
	current_x = move_x + 50;
	current_y = start_y + 15;
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	cairo_show_text(cr, text);

	current_x = current_x + 5;
	current_y = current_y + 15;
	local icon = weather_icon[forecast[3]["weather"][1]["icon"]];
	cairo_set_font_size(cr, 40);
	cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	cairo_text_extents(cr, icon, extents);
	cairo_move_to(cr, current_x, current_y + 15 + extents.height);
	cairo_show_text(cr, icon);
	current_y = current_y + 10;
	current_x = current_x + extents.width;

	text = forecast[3]["weather"][1]["description"]
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height);
	cairo_show_text(cr, text);

	current_y = current_y + extents.height;

	-- current_x = start_x;
	value = tonumber(forecast[3]["temp"]["min"]) - 273;
	value = value - value%1;
	text = value.."°C";
	value = tonumber(forecast[3]["temp"]["max"]) - 273;
	value = value - value%1;
	text = text.." / "..value.."°C";

	cairo_set_font_size(cr, 16);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	cairo_show_text(cr, text);
	local move_y = current_y + extents.height + 6;


	day = day + 1;
	text = day..' '..month;
	current_x = start_x;
	current_y = move_y + 20;
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	cairo_show_text(cr, text);

	current_x = current_x + 5;
	current_y = current_y + 15;
	local icon = weather_icon[forecast[4]["weather"][1]["icon"]];
	cairo_set_font_size(cr, 40);
	cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	cairo_text_extents(cr, icon, extents);
	cairo_move_to(cr, current_x, current_y + 15 + extents.height);
	cairo_show_text(cr, icon);
	current_y = current_y + 10;
	current_x = current_x + extents.width;

	text = forecast[4]["weather"][1]["description"]
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height);
	cairo_show_text(cr, text);

	current_y = current_y + extents.height;

	-- current_x = start_x;
	value = tonumber(forecast[4]["temp"]["min"]) - 273;
	value = value - value%1;
	text = value.."°C";
	value = tonumber(forecast[4]["temp"]["max"]) - 273;
	value = value - value%1;
	text = text.." / "..value.."°C";

	cairo_set_font_size(cr, 16);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	cairo_show_text(cr, text);



	day = day + 1;
	text = day..' '..month;
	current_x = move_x + 50;
	current_y = move_y + 20;
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 3);
	cairo_show_text(cr, text);

	current_x = current_x + 5;
	current_y = current_y + 15;
	local icon = weather_icon[forecast[5]["weather"][1]["icon"]];
	cairo_set_font_size(cr, 40);
	cairo_select_font_face(cr, "dripicons-weather", 0, 0);
	cairo_text_extents(cr, icon, extents);
	cairo_move_to(cr, current_x, current_y + 25 + extents.height);
	cairo_show_text(cr, icon);
	current_y = current_y + 10;
	current_x = current_x + extents.width+10;

	text = forecast[5]["weather"][1]["description"]
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height);
	cairo_show_text(cr, text);

	current_y = current_y + extents.height;

	-- current_x = start_x;
	value = tonumber(forecast[5]["temp"]["min"]) - 273;
	value = value - value%1;
	text = value.."°C";
	value = tonumber(forecast[5]["temp"]["max"]) - 273;
	value = value - value%1;
	text = text.." / "..value.."°C";

	cairo_set_font_size(cr, 16);
	-- cairo_select_font_face(cr, "Text Me One", 0, 0);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 6, current_y + extents.height + 6);
	cairo_show_text(cr, text);
	local move_y = current_y + extents.height + 6;


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
	-- cairo_stroke(cr);

	-- cairo_set_source_rgba(cr, 1,1,1,0.3);
	-- cairo_rectangle(cr, 53, 20, 610, 210);
	-- cairo_fill(cr);

	-- Diplomata,Leckerli One,Limelight,Modak,Sacramento
	cairo_set_source_rgba(cr, 1,1,1,1);
	cairo_select_font_face(cr, "Text Me One", 0 , 0);
	cairo_set_font_size(cr, 96);
	text = hour..":"..minute.." "..part;
	cairo_text_extents(cr, text, extents)
	local current_y = 80 + extents.height/2;
	local current_x = 33 + 325 - extents.width/2;
	cairo_move_to(cr, 33 + 325 - extents.width/2, 125);
	cairo_show_text(cr, text);


	-- cairo_set_source_rgba(cr, 0.9, 0.9, , 1);
	cairo_set_font_size(cr, 48);
	-- Poiret One, Nixie One
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	text = month.." "..day..", "..year;
	cairo_text_extents(cr, text, extents)
	cairo_move_to(cr, current_x, 125 + 36 + extents.height/2);
	cairo_show_text(cr, text);


	minute = tonumber(minute);
	hour = tonumber(hour);
	second = tonumber(second);

	if( minute % 30 == 29) then
		update_weather = true;
	end

	if((update_weather and minute%30 == 0) or start == true) then
		update_weather = false;

		if(tonumber(internet) == 1) then
			local file = io.popen("curl -m 100  api.openweathermap.org/data/2.5/weather?id=1270454");
			output = file:read("*a");
			io.close(file);
		end

		if internet ~= 1 then
			weather = "NO INTERNET";
		end

		if (output == "") then
				print("Could not read");
				weather = "ERROR";
		else
			weather = cjson.decode(output);
			for k, v in pairs(weather) do
	 			print(k, weather[k])
			end
		end
	end



	-- forecaster
	if( minute % 60 == 59) then
		update_forecast = true;
	end

	if((update_forecast and minute%60 == 0) or start == true) then
		update_forecast = false;
		-- start = false;
		if(tonumber(internet) == 1) then
			local file = io.popen("curl -m 100 'api.openweathermap.org/data/2.5/forecast/daily?id=1270454&mode=json'");
			output = file:read("*a");
			io.close(file);
		end

		if internet ~= 1 then
			forecast = "NO INTERNET";
		end

		if (output == "") then
				print("Could not read");
				forecast = "ERROR";
		else
			forecast = cjson.decode(output)["list"];
			for k, v in pairs(forecast) do
	 			print(k, forecast[k])
			end
		end
	end

	if weather ~= "NO INTERNET" and weather ~= "ERROR" then
		printWeather(cr);
	end


	-- quoter
	if( minute % 60 == 59) then
		update_quote = true;
	end

	if((update_quote and minute%60 == 0) or start == true) then
		update_quote = false;
		start = false;
		if(tonumber(internet) == 1) then
			local file = io.popen("curl -m 100 http://api.theysaidso.com/qod");
			output = file:read("*a");
			io.close(file);
		end

		if internet ~= 1 then
			quote = "NO INTERNET";
		end

		if (output == "") then
				print("Could not read");
				quote = "ERROR";
		else
			quote = cjson.decode(output);
			for k, v in pairs(quote) do
	 			print(k, quote[k])
			end
		end
	end

	printQuote(cr);


	local start_x = 53;
	local start_y = 370;

	-- cairo_set_source_rgba(cr, 0,0,0,1);
	-- cairo_rectangle(cr, start_x, start_y, 285, 310);
	-- cairo_fill(cr);

	local cpu = tonumber(conky_parse("${cpu}"));
	meter(cr, start_x + 285 - 65, start_y + 15 + 45, 45, cpu, '%');

	text = "CPU";
	cairo_set_font_size(cr, 40);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- text = month.." "..day..", "..year;
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, start_y + 20 + extents.height);
	cairo_show_text(cr, text);
	current_y = start_y + 25 + extents.height;
	current_x = start_x+25;

	local no_of_cores = 2;
	cairo_set_font_size(cr, 18);
	cairo_select_font_face(cr, "Text Me One", 0, 0);
	for i = 1,no_of_cores do
		local name = "core "..i;
		local value = conky_parse("${top cpu "..i.."}");
		text = name..":"..value.."%";
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x, current_y + extents.height + 5);
		cairo_show_text(cr, text);
		current_y = current_y + extents.height + 5;
	end


	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,15);
	for i = 1,10 do
		local addison = "                 ";
		local name = string.sub(conky_parse("${top name "..i.."}")..addison,1,10);
		local value = conky_parse("${top cpu "..i.."}");
		text = name;
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x, current_y + 25 + 17*i);
		cairo_show_text(cr,text);
		text = value.."%";
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, start_x + 285- 35 - extents.width, current_y + 25 + 17*i);
		cairo_show_text(cr,text);
	end



	start_x = start_x + 285 + 40;
	-- cairo_set_source_rgba(cr, 1,1,1,0.3);
	-- cairo_rectangle(cr, start_x, start_y, 285, 310);
	-- cairo_fill(cr);

	cairo_set_source_rgba(cr, 1,1,1,1);
	text = "Network";
	cairo_select_font_face(cr,"Poiret One",0,0);
	cairo_set_font_size(cr,36);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, start_y + 20 + extents.height);
	cairo_show_text(cr,text);
	current_y = start_y + 20 + extents.height;

	local download = conky_parse("${downspeed eth0}");
	text = "download: ";
	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,16);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y+extents.height+10);
	cairo_show_text(cr,text);
	text = trim1(download).."/s";
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+285-20-extents.width, current_y+extents.height+10);
	cairo_show_text(cr,text);
	current_y = current_y+extents.height + 5;

	local upload = conky_parse("${upspeed eth0}");
	text = "upload: ";
	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,16);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y+extents.height+10);
	cairo_show_text(cr,text);
	text = trim1(upload).."/s";
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+285-20-extents.width, current_y+extents.height+12);
	cairo_show_text(cr,text);
	current_y = current_y+extents.height + 5;


	current_y = current_y + 50;


	text = "Filesystem";
	cairo_select_font_face(cr,"Poiret One",0,0);
	cairo_set_font_size(cr,36);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y + extents.height);
	cairo_show_text(cr,text);
	current_y = current_y + extents.height + 5;


	text = "/";
	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,16);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y+extents.height+10);
	cairo_show_text(cr,text);
	local used = conky_parse("${fs_used /}");
	local total = conky_parse("${fs_size /}");
	text = trim1(used).."/"..trim1(total);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+285-20-extents.width, current_y+extents.height+10);
	cairo_show_text(cr,text);
	current_y = current_y+extents.height + 20;
	local value = conky_parse("${fs_used_perc /}");
	lineMeter(cr, start_x+20, current_y, 245, value, "%");

	current_y = current_y+10;

	text = "/home";
	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,16);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y+extents.height+10);
	cairo_show_text(cr,text);
	local used = conky_parse("${fs_used /home}");
	local total = conky_parse("${fs_size /home}");
	text = trim1(used).."/"..trim1(total);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+285-20-extents.width, current_y+extents.height+10);
	cairo_show_text(cr,text);
	current_y = current_y+extents.height + 20;
	local value = conky_parse("${fs_used_perc /home}");
	lineMeter(cr, start_x+20, current_y, 245, value, "%");




	start_x = start_x + 285 + 40;
	-- cairo_set_source_rgba(cr, 1,1,1,0.3);
	-- cairo_rectangle(cr, start_x, start_y, 285, 310);
	-- cairo_fill(cr);

	cairo_set_source_rgba(cr, 1,1,1,1);
	text = "Power";
	cairo_select_font_face(cr,"Poiret One",0,0);
	cairo_set_font_size(cr,36);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, start_y + 20 + extents.height);
	cairo_show_text(cr,text);
	current_y = start_y + 20 + extents.height;


	local bat = conky_parse("${battery}");
	-- print(bat);
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);

	text = trim1(bat);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x + 285 - 20 - extents.width, current_y + extents.height);
	cairo_show_text(cr, text);
	current_y = current_y + extents.height + 15;
	value = tonumber(conky_parse("${battery_percent}"));
	lineMeter(cr, start_x+20, current_y, 245, value, '%');


	current_y = current_y + 20;


	text = "Disk";
	cairo_select_font_face(cr,"Poiret One",0,0);
	cairo_set_font_size(cr,36);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y + 20 + extents.height);
	cairo_show_text(cr,text);
	current_y = current_y + 20 + extents.height;

	local write = conky_parse("${diskio_write}");
	text = "write: ";
	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,16);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y+extents.height+10);
	cairo_show_text(cr,text);
	text = trim1(write).."/s";
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+285-20-extents.width, current_y+extents.height+10);
	cairo_show_text(cr,text);
	current_y = current_y+extents.height + 5;

	local read = conky_parse("${diskio_read}");
	text = "read: ";
	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,16);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y+extents.height+10);
	cairo_show_text(cr,text);
	text = trim1(read).."/s";
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+285-20-extents.width, current_y+extents.height+12);
	cairo_show_text(cr,text);
	current_y = current_y+extents.height + 20;


	text = "Uptime";
	cairo_select_font_face(cr,"Poiret One",0,0);
	cairo_set_font_size(cr,36);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+20, current_y + 20 + extents.height);
	cairo_show_text(cr,text);
	current_y = current_y + 20 + extents.height;
	local uptime = conky_parse("${uptime}");
	-- print(bat);
	cairo_set_font_size(cr, 20);
	cairo_select_font_face(cr, "Text Me One", 0, 0);

	text = trim1(uptime);
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x + 285 - 20 - extents.width, current_y + extents.height);
	cairo_show_text(cr, text);




	-- RAM
	start_x = start_x + 285 + 40;
	-- cairo_set_source_rgba(cr, 1,1,1,0.3);
	-- cairo_rectangle(cr, start_x, start_y, 285, 310);
	-- cairo_fill(cr);


	local ram = conky_parse("${memperc}");
	meter(cr, start_x + 65, start_y + 15 + 45, 45, ram, '%');

	text = "Memory";
	cairo_set_font_size(cr, 40);
	cairo_select_font_face(cr, "Poiret One", 0, 0);
	-- text = month.." "..day..", "..year;
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, start_x+ 285 - 20 - extents.width, start_y + 20 + extents.height);
	cairo_show_text(cr, text);
	current_y = start_y + 25 + extents.height;
	current_x = start_x+25;

	cairo_set_font_size(cr, 18);
	cairo_select_font_face(cr, "Text Me One", 0, 0);

	local swap = conky_parse("${swapperc}");
	text = "swap: "..value.."%";
	cairo_text_extents(cr, text, extents);
	cairo_move_to(cr, current_x + 285 - 60 - extents.width, current_y + extents.height + 5);
	cairo_show_text(cr, text);
	current_y = current_y + extents.height + 5;


	cairo_select_font_face(cr,"Nixie One",0,0);
	cairo_set_font_size(cr,15);
	for i = 1,10 do
		local addison = "                 ";
			local name = string.sub(conky_parse("${top_mem name "..i.."}")..addison,1,10);
			local value = (conky_parse("${top_mem mem_res "..i.."}"));
		text = name;
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, current_x, current_y + 25 + 17*i);
		cairo_show_text(cr,text);
		text = value;
		cairo_text_extents(cr, text, extents);
		cairo_move_to(cr, start_x + 285- 20 - extents.width, current_y + 25 + 17*i);
		cairo_show_text(cr,text);
	end


	-- destroying the cairo surface
	cairo_destroy(cr);
	cairo_surface_destroy(cs);
	cr=nil;
end

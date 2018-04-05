require 'cairo'
require 'Core/common'

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
function conky_setup_weather()
	-- global variables to hold the data
	weather = {}
	weather['status'] = 'EMPTY'

	-- a global to tell if the script is running for the first time
	start_weather = true
end

-- function main that is called everty time the script is run
function conky_main_weather(  )

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
	--cairo_set_source_rgba(cr, 1,1,1,1)

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
		-- BUG ???
		--_, y =  lineText('Humidity ' .. tonumber(weather['humidity'])*100 .. '%', start_x + box_width*(0.05), y , box_height*(0.06), 'Text Me One', extents, font_ext, options)
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
end

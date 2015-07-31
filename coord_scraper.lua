local std = require('std')
local tfl_api = require('tfl_api')
local cjson = require('cjson')

function get_station_coords_for_line(line_name)
  local stem = string.format('line/%s/stoppoints?', line_name)
  local data = tfl_api.request(stem)
  
  local results = {}
  for station in std.elems(data) do
    results[station.commonName] = {station.lat, station.lon}
  end
  
  return results
end

function get_station_coords()
  local lines = tfl_api.get_lines_of_interest()
  
  local results = {}
  for line in std.elems(lines) do
    print(string.format('Processing %s', line))
    local stops = get_station_coords_for_line(line)
    for name, coord in pairs(stops) do
      results[name] = coord
    end
  end
  
  return results
end

function save_station_coords()
  local coords = get_station_coords()
  local text = cjson.encode(coords)
  local file = io.open('coords.json', 'w+')
  file:write(text)
  file:close()
end
  

save_station_coords()

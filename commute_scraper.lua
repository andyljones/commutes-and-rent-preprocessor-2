local std = require('std')
local tfl_api = require('tfl_api')
local torch = require('torch')

function get_timetables(line_name, station_name, direction)
  local stem = tfl_api.format_stem{
    query='Line/id/Timetable/fromStopPointId', 
    fromStopPointId=station_name, 
    id=line_name,
    direction=direction}

  return tfl_api.request(stem)
end

function get_intervals(timetable, stations)
  local routes = timetable.timetable.routes
  local results = {}
  for route_num, route in pairs(routes) do
    results[route_num] = {}
    for interval_num, intervals in pairs(route.stationIntervals) do
      results[route_num][interval_num] = {}
      for _, interval in pairs(intervals.intervals) do
          local station_name = stations[interval.stopId]
          results[route_num][interval_num][station_name] = interval.timeToArrival
      end
    end
  end
  return results
end
    

function get_intervals_for_line(line_name, ignores)
  local ignores = ignores or {}
  local stations = tfl_api.get_station_names(line_name)
    
  local results = {}
  for id, station_name in pairs(stations) do
    results[station_name] = {}
    for _, direction in pairs({'inbound', 'outbound'}) do
      local ignore_this = (ignores[station_name] and ignores[station_name][direction])
      
      if not ignore_this then
        local success, timetables = pcall(get_timetables, line_name, id, direction)
        
        if success then
          results[station_name][direction] = get_intervals(timetables, stations)
          print(string.format('Got results for %s in direction %s', station_name, direction))
        else
          print(string.format('Failed to get intervals for %s in direction %s', station_name, direction))
        end
      else
        print(string.format('Ignoring %s in direction %s', station_name, direction))
      end
    end
  end
    
  return results
end

function save_intervals_for_all_lines()
  local lines_ = tfl_api.get_lines_of_interest()
        
  for line in std.ielems(lines_) do
    print(string.format('Getting information for line %s', line))
    local intervals = get_intervals_for_line(line)
    
    local filename = string.format('lines/%s.t7', line)
    torch.save(filename, intervals)
  end
end

save_intervals_for_all_lines()


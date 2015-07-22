local std = require('std')

local https = require('ssl.https')
local cjson = require('cjson')

local API_ID = '64dd8f8c'
local API_KEY = '8f945b259bf29848031c8dbdb7abf4b3'

function request_api(stem)
    local url = string.format('https://api.tfl.gov.uk/%s&app_id=%s&app_key=%s', stem, API_ID, API_KEY)
    local body, code, _, _ = https.request(url)
    
    assert(code == 200, string.format('Invalid response to url %s. Code: %d', url, code))
        
    return cjson.decode(body)
end

function get_line_data()
    return request_api('Line?')
end
        
function get_lines_of_interest(line_data)
    local results = {}
    for k, v in pairs(line_data) do
        if v.modeName == 'tube' or v.modeName == 'overground' then table.insert(results, v.id) end
    end
    
    return results
end

function format_stem(...)
    local query = (...).query
    
    local stem = query .. '?'
    for k, v in pairs(...) do
        if k ~= 'query' then
            stem = string.format('%s&%s=%s', stem, k, v)
        end
    end
    
    return stem
end

function get_stations_for_line(name)
    local stem = format_stem{
        query='Line/ids/StopPoints',
        ids=name
    }

    return request_api(stem)
end

function get_station_names(station_data)
    local ids = {}
    for _, v in pairs(station_data) do
        ids[v.id] = v.commonName
    end
    return ids
end

function get_timetables(line_name, station_name, direction)
    stem = format_stem{
        query='Line/id/Timetable/fromStopPointId', 
        fromStopPointId=station_name, 
        id=line_name,
        direction=direction}
    
    return request_api(stem)
end

function get_intervals(timetable, stations)
    local routes = timetable.timetable.routes
    local results = {}
    for route_num, route in pairs(routes) do
        results[route_num] = {}
        for interval_num, intervals in pairs(route.stationIntervals) do
            results[route_num][interval_num] = {}
            for _, interval in pairs(intervals.intervals) do
                station_name = stations[interval.stopId]
                results[route_num][interval_num][station_name] = interval.timeToArrival
            end
        end
    end
    return results
end
    

function get_intervals_for_line(line_name, ignores)
    local ignores = ignores or {}
    local stations = get_station_names(get_stations_for_line(line_name))
    
    local results = {}
    for id, station_name in pairs(stations) do
        results[station_name] = {}
        for _, direction in pairs({'inbound', 'outbound'}) do
            ignore_this = (ignores[station_name] and ignores[station_name][direction])
            
            if not ignore_this then
                local success, timetables = pcall(get_timetables, line_name, id, direction)
            else
                print(string.format('Ignoring %s in direction %s', station_name, direction))
                local success = false
            end
                
            if success and not ignore_this then
                results[station_name][direction] = get_intervals(timetables, stations)
                print(string.format('Got results for %s in direction %s', station_name, direction))
            elseif not ignore_this then
                print(string.format('Failed to get intervals for %s in direction %s', station_name, direction))
            end
        end
    end
    
    return results
end

function save_intervals_for_all_lines()
    local lines_ = get_lines_of_interest(get_line_data())
        
    for line in std.ielems(lines_) do
        print(string.format('Getting information for line %s', line))
        local intervals = get_intervals_for_line(line)
        
        filename = string.format('lines/%s.t7', line)
        torch.save(filename, intervals)
    end
end

function update_intervals()
    local lines_ = get_lines_of_interest(get_line_data())

    for line in std.ielems(lines_) do
        print(string.format('Getting information for line %s', line))
        local filename = string.format('lines/%s.t7', line)
        local data = torch.load(filename)
        local new_data = get_intervals_for_line(line, data)
        for station_name, directions in pairs(new_data) do
            for direction_name, intervals in pairs(directions) do
                data[station_name][direction] = intervals
            end
        end
    
        torch.save(filename, data)
    end
end


local lfs = require('lfs')
local std = require('std')
local fn = require('std.functional')
local torch = require('torch')

function load_intervals()
    local results = {}
    for filename in lfs.dir('lines') do
        stem, extension = unpack(std.string.split(filename, '%.'))
        if extension == 't7' then
            results[stem] = torch.load('lines/' .. filename)
        end
    end
    
    return results
end

function flatten(t)
    local is_leaf = type(t) == 'table' and type(std.table.values(t)[1]) ~= 'table'
    
    if is_leaf then
        local results = {}
        for key, value in pairs(t) do
            results[key] = torch.Tensor{value}
        end
        return results
    else
        local results = {}
        for _, child in pairs(t) do
            for key, value in pairs(flatten(child)) do
                if results[key] == nil then
                    results[key] = value
                else
                    results[key] = torch.cat(results[key], value)
                end
            end
        end
    
        return results
    end    
end
  
function get_average_intervals_for_station(station_intervals)
  return fn.map(fn.lambda '=_1, torch.median(_2)[1]', flatten(station_intervals))
end
    
function get_average_intervals_for_line(line_intervals)
  return fn.map(fn.lambda '=_1, get_average_intervals_for_station(_2)', line_intervals)
end

function get_average_intervals(intervals)
  return fn.map(fn.lambda '=_1, get_average_intervals_for_line(_2)', intervals)
end

local intervals = load_intervals()
local average_intervals = get_average_intervals(intervals)

for k, v in pairs(average_intervals['bakerloo']['Paddington Underground Station']) do
  print(k, v)
end
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
  results = {}
  for node_type, path, value in std.tree.nodes(t) do
    if node_type == 'leaf' then
      key = path[#path]
      if results[key] then
        results[key] = torch.cat(results[key], torch.Tensor{value})
      else
        results[key] = torch.Tensor{value}
      end
    end
  end
  return results
end

function get_average_intervals(intervals)
  local results = {}
  for line, line_intervals in pairs(intervals) do
    for origin, origin_intervals in pairs(line_intervals) do
      for destination, destination_intervals in pairs(flatten(origin_intervals)) do
        if not results[origin] then results[origin] = {} end
        
        local median_interval = torch.median(destination_intervals)[1]
        local current_value = results[origin][destination]
        if current_value then
          results[origin][destination] = std.math.min(current_value, median_interval)
        else
          results[origin][destination] = median_interval
        end
      end
    end
  end
  return results
end

function calculate_shortest_paths(average_intervals)
  local results = std.tree.clone(average_intervals)
  for i, _ in pairs(results) do
    for j, _ in pairs(results) do
      if not results[i][j] and i ~= j then
        results[i][j] = math.huge
      elseif not results[i][j] and i == j then
        results[i][j] = 0
      end
    end
  end
  
  for k, _ in pairs(results) do
    for i, _ in pairs(results) do
      for j, _ in pairs(results) do
        results[i][j] = std.math.min(results[i][j], results[i][k] + results[k][j] + 5)
      end
    end
  end
  
  return results
end

local intervals = load_intervals()
local average_intervals = get_average_intervals(intervals)
local shortest_paths = calculate_shortest_paths(average_intervals)

for k, v in pairs(shortest_paths['Euston Underground Station']) do
  print(k, v)
end
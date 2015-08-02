local std = require('std')
local torch = require('torch')
local cjson = require('cjson')

local RENT_TOLERANCE = 1500
local COMMUTE_TOLERANCE = 30
local PERCENTILE = 75

function load_commute_lengths()
  return torch.load('commute_lengths.t7')
end

function load_rents()
  local file = io.open('listings-2-bed.json', 'r')
  local text = file:read('*all')
  file:close()
  return cjson.decode(text)
end

function percentile(a, p)
  local sorted = torch.sort(a)
  local index = math.max((p/100.)*a:size(1) + 1, 1)
  return sorted[index]
end

function short_name(name)
  return std.string.split(name, ' Underground Station')[1]
end

local commute_lengths = load_commute_lengths()
local rents = load_rents()

function get_data(destination)
  local relevant_data = {}
  for origin, commutes in pairs(commute_lengths) do
    if #rents[origin] > 10 then
      local commute = commutes[destination]
      local rent = percentile(torch.Tensor(rents[origin]), PERCENTILE)
      relevant_data[origin] = {['name']=origin, ['commute']=commute, ['rent']=rent, ['count']=#rents[origin]}
    end
  end
  return relevant_data
end

function filter_data(data)
  local filtered_data = {}
  for k, v in pairs(data) do
    if v.rent < RENT_TOLERANCE and v.commute < COMMUTE_TOLERANCE then
      filtered_data[k] = v
    end
  end
  return filtered_data
end

function get_filtered_data(destination)
  return filter_data(get_data(destination))
end

function print_data(data)
  local sorted = std.table.sort(std.table.keys(data), function (a,b) return data[a].commute < data[b].commute end)

  for _, k in pairs(sorted) do
    local v = data[k]
    print(string.format('%2.0f mins, £%4.0f, %3d listings total, %s', v.commute, v.rent, v.count, short_name(v.name)))
  end
end

function union(datasets)
  local results = {}
  for _, dataset in pairs(datasets) do
    for _, elem in pairs(dataset) do
      if results[elem.name] then
        results[elem.name].commute = std.math.min(results[elem.name].commute, elem.commute)
      else
        results[elem.name] = elem
      end
    end
  end
  return results
end

function intersection(datasets)
  local results = {}
  for _, A in pairs(datasets) do
    for _, elem in pairs(A) do
      local is_in_all = true
      for _, B in pairs(datasets) do
        is_in_all = is_in_all and B[elem.name]
      end

      if is_in_all and results[elem.name] then
        results[elem.name].commute = math.max(results[elem.name].commute, elem.commute)
      elseif is_in_all then
        results[elem.name] = elem
      end
    end
  end
  return results
end

function find_possibilities(A_targets, B_targets)
  std.functional.map(function (target) return filter_data(get_data(target)) end)
end

local E = get_filtered_data('Euston Underground Station')
local GP = get_filtered_data('Green Park Underground Station')
local combination = intersection{GP, E}

print_data(combination)

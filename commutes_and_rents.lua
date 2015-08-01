local std = require('std')
local torch = require('torch')
local cjson = require('cjson')

require('gnuplot')

function load_commute_lengths()
  return torch.load('commute_lengths.t7')
end

function load_rents()
  local file = io.open('listings-2-bed.json', 'r')
  local text = file:read('*all')
  file:close()
  return cjson.decode(text)
end

local commute_lengths = load_commute_lengths()
local rents = load_rents()

local destination = 'Euston Underground Station'
local relevant_data = {}
for origin, commutes in pairs(commute_lengths) do
  if #rents[origin] > 0 then
    local commute = commutes[destination]
    local rent = torch.median(torch.Tensor(rents[origin]))
    relevant_data[origin] = {['commute']=commute, ['rent']=rent[1]}
  end
end

-- function cmp(a, b)
--   return relevant_data[a].commute < relevant_data[b].commute
-- end
--
-- local commute_order = std.table.sort(std.table.keys(relevant_data), cmp)

-- for _, k in pairs(commute_order) do
--   local v = relevant_data[k]
--   print(string.format('%50s, %4.1f, %4d', k, v.commute, v.rent))
-- end

local xs = {}
local ys = {}
for _, v in pairs(relevant_data) do
  table.insert(xs, v.commute)
  table.insert(ys, v.rent)
end

gnuplot.setterm('aqua')
gnuplot.plot(torch.Tensor(xs), torch.Tensor(ys), '+')
gnuplot.figprint('out.png')

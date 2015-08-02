local https = require('ssl.https')
local cjson = require('cjson')

function load_keys()
  local file = io.open('keys.json', 'r')
  local keys = cjson.decode(file:read('*all'))
  file:close()
  return keys['tfl_id'], keys['tfl_key']
end

local API_ID, API_KEY = load_keys()

function request(stem)
  local url = string.format('https://api.tfl.gov.uk/%s&app_id=%s&app_key=%s', stem, API_ID, API_KEY)
  local body, code, _, _ = https.request(url)

  assert(code == 200, string.format('Invalid response to url %s. Code: %d', url, code))

  return cjson.decode(body)
end

function get_line_data()
  return request('Line?')
end

function get_lines_of_interest()
  line_data = get_line_data()

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
  return request(stem)
end

function get_station_names(name)
  local station_data = get_stations_for_line(name)

  local ids = {}
  for _, v in pairs(station_data) do
    ids[v.id] = v.commonName
  end
  return ids
end

return {
  request=request,
  format_stem=format_stem,
  get_station_names=get_station_names,
  get_lines_of_interest=get_lines_of_interest
  }

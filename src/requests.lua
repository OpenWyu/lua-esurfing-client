local json = require "json"
local http = require "socket.http"
local ltn12 = require "ltn12"

http.TIMEOUT = 3

requests = {}

local function merge_table(first, second)
  for k, v in pairs(second) do
    first[k] = v
  end
end

function requests.get(reqt)
  local request_body = reqt.body
  local response_body = {}
  local request_headers = {
    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
    ["Cookie"] = reqt.cookie
  }
  
  if reqt.headers then
    merge_table(request_headers, reqt.headers)
  end
  
  local res, code, response_headers = http.request {
    url = reqt.url,
    method = "GET",
    headers = request_headers,
    source  =ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body),
    redirect = false
  }
  
  if type(response_headers) ~= "table" or type(response_body) ~= "table" then
    return nil
  end
  
  return code, response_headers, table.concat(response_body)
end

function requests.post(reqt)
  local request_body = reqt.body
  local response_body = {}
  local request_headers = {
    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
    ["Cookie"] = reqt.cookie
  }
  
  if reqt.headers then
    merge_table(request_headers, reqt.headers)
  end
  
  local res, code, response_headers = http.request {
    url = reqt.url,
    method = "POST",
    headers = request_headers,
    source  =ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body),
    redirect = false
  }
  
  if type(response_headers) ~= "table" or type(response_body) ~= "table" then
    return nil
  end
  
  return code, response_headers, table.concat(response_body)
end

function requests.json(reqt)
  local request_body = json.encode(reqt.body)
  local response_body = {}
  local request_headers = {
    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
    ["Accept"] = "*/*",
    ["Content-Type"] = "application/json",
    ["Content-Length"] = #request_body,
    ["Cookie"] = reqt.cookie
  }
  
  if reqt.headers then
    merge_table(request_headers, reqt.headers)
  end
  
  local res, code, response_headers = http.request {
    url = reqt.url,
    method = "POST",
    headers = request_headers,
    source  =ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body),
    redirect = false
  }
  
  if type(response_headers) ~= "table" or type(response_body) ~= "table" then
    return nil
  end
  
  return code, response_headers, json.decode(table.concat(response_body))
end
    
    
return requests
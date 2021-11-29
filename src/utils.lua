local md5 = require "md5"
local socket = require "socket"

utils = {}

function utils.get_normal_authenticator(clientip, nasip, macaddr, timestamp, secretkey)
  return string.upper(md5.sumhexa(clientip .. nasip .. macaddr .. timestamp .. secretkey))
end

function utils.get_vcode_authenticator(version, clientip, nasip, macaddr, timestamp, secretkey)
  return string.upper(md5.sumhexa(version .. clientip .. nasip .. macaddr .. timestamp .. secretkey))
end

function utils.get_login_authenticator(clientip, nasip, macaddr, timestamp, vcode, secretkey)
  return string.upper(md5.sumhexa(clientip .. nasip .. macaddr .. timestamp .. vcode .. secretkey))
end

function utils.get_current_time()
  return os.date("%H:%M")
end

function utils.get_current_week()
  return tonumber(os.date("%w"))
end

local function parse_time(str)
  local hour, min = str:match("(%d+):(%d+)")
  return hour * 60 + min
end

function utils.is_time_between(time, start, stop)
  local _time = parse_time(time)
  local _start = parse_time(start)
  local _stop = parse_time(stop)
  
  if _stop < _start then
    return _start <= _time or _time <= _stop
  end
  return _start <= _time and _time <= _stop
end

function utils.is_array_contains(array, element)
  for _, value in ipairs(array) do
    if value == element then
      return true
    end
  end
  return false
end

function utils.sleep(sec)
  socket.select(nil, nil, sec)
end


return utils
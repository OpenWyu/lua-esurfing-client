#!/usr/bin/lua

local mime        = require "mime"

local requests    = require "requests"
local utils       = require "utils"
local log         = require "log"

log.outfile = "/tmp/esurfing-client/esurfing-client.log"
log.usecolor = false
log.level = "debug"

local unpack = unpack or table.unpack

-- 用户自定义参数 begin

-- 命令字符串 值只能是 "login" 或 "logout"
local command      = ""

-- 是否开启定时保活功能 默认开启 使用双路由器方法的用户无需开启
local keepalive_enabled = true
-- 保活协程检查周期(秒) 默认5分钟 实测应低于10分钟才不会断连
local keepalive_interval = 5 * 60

-- 免打扰模式 默认关闭
local donotdisturb = true
-- 免打扰模式启用的星期范围 [0 - 6 = 星期天 - 星期六]
-- 默认值适用于星期天到星期四晚上11点半断网, 第二天早上6点恢复
local dndweekrange = {0, 1, 2, 3, 4}
-- 免打扰模式开始时间(hh:mm)
local dndstarttime = "23:30"
-- 免打扰模式结束时间(hh:mm)
local dndstoptime  = "06:00"

local username     = ""
local password     = ""
local clientip     = ""
-- MAC地址格式为XX:XX:XX:XX:XX:XX
local macaddr      = ""
-- 以下三个变量对同一学校而言可认为是固定常数
local nasip        = "119.146.175.80"
local schoolid     = "1414"
local secretkey    = "Eshore!@#"

-- 用户自定义参数 end

local cookie       = ""
local vcode        = ""

function check_network_status()
  local code, _, _ = requests.get {
    url = "http://172.17.18.3:8080/portal/",
    headers = {
      ["Accept"] = "application/signed-exchange"
    }
  }
  
  if code == 200 or code == 302 then
    log.info("已连接到校园网")
    return true
  end
  
  log.failure("[-] 未连接到校园网, 请检查网络")
  return false
end

function portal_login()
  local code, _, _ = requests.post {
    url = "http://172.17.18.3:8080/portal/pws?t=li&ifEmailAuth=false",
    headers = {
      ["Accept"] = "application/signed-exchange"
    },
    body = string.format([[userName=%s&userPwd=%s]], username, mime.b64(password)) .. [[%3D&userDynamicPwd=&userDynamicPwdd=&serviceType=&isSavePwd=on&userurl=&userip=&basip=&language=Chinese&usermac=null&wlannasid=&wlanssid=&entrance=null&loginVerifyCode=&userDynamicPwddd=&customPageId=100&pwdMode=0&portalProxyIP=172.17.18.3&portalProxyPort=50200&dcPwdNeedEncrypt=1&assignIpType=0&appRootUrl=http%3A%2F%2F172.17.18.3%3A8080%2Fportal%2F&manualUrl=&manualUrlEncryptKey=]]
  }
  
  if code == 200 then
    log.info("已发包进行portal服务认证, 1秒后再次尝试登录")
    return true
  end
  
  log.failure("portal服务认证失败, 请检查网络")
  return false
end

function query_schoolid()
  local timestamp = os.time() * 1000
  local code, _, response_body = requests.json {
    url = "http://enet.10000.gd.cn:10001/client/queryschool",
    body = {
      clientip = clientip,
      nasip = nasip,
      mac = macaddr,
      timestamp = timestamp,
      authenticator = utils.get_normal_authenticator(clientip, nasip, macaddr, timestamp, secretkey)
    }
  }
  
  if code == 200 and response_body["rescode"] == "0" then
    schoolid = response_body["schoolid"]
    log.debug("schoolid: " .. schoolid)
    return true
  end
  
  log.failure("获取schoolid失败, 请检查网络")
  return false
end

function get_enet_cookie()
  local code, response_headers, _ = requests.get {
    url = "http://enet.10000.gd.cn:10001/advertisement.do",
    body = string.format([[schoolid=%s]], schoolid)
  }
  
  if code == 200 then
    cookie = response_headers["set-cookie"]
    log.debug("cookie: " .. cookie)
    return true
  end
  
  log.failure("获取认证cookie失败, 请检查网络")
  return false
end

function get_vcode()
  local timestamp = os.time() * 1000
  local code, _, response_body = requests.json {
    url = "http://enet.10000.gd.cn:10001/client/challenge",
    cookie = cookie,
    body = {
      username = username,
      clientip = clientip,
      nasip = nasip,
      mac = macaddr,
      timestamp = timestamp,
      authenticator = utils.get_normal_authenticator(clientip, nasip, macaddr, timestamp, secretkey)
    }
  }
  
  if code == 200 and response_body["rescode"] == "0" then
    vcode = response_body["challenge"]
    log.debug("vcode: " .. vcode)
    return true
  end
  
  log.failure("获取vcode失败, 请检查网络或确定登录信息是否正确")
  return false
end

function enet_login()
  local timestamp = os.time() * 1000
  local code, _, response_body = requests.json {
    url = "http://enet.10000.gd.cn:10001/client/login",
    cookie = cookie,
    body = {
      username = username,
      password = password,
      clientip = clientip,
      nasip = nasip,
      mac = macaddr,
      iswifi = "4060",
      timestamp = timestamp,
      authenticator = utils.get_login_authenticator(clientip, nasip, macaddr, timestamp, vcode, secretkey)
    }
  }
  
  if code == 200 and response_body["rescode"] == "0" then
    log.success("登录成功 - " .. response_body["resinfo"])
    return true
  end
  
  log.failure("登录失败, 请检查网络或确定登录信息是否正确")
  return false
end

function enet_logout()
  local timestamp = os.time() * 1000
  local code, _, response_body = requests.json {
    url = "http://enet.10000.gd.cn:10001/client/logout",
    cookie = cookie,
    body = {
      username = username,
      clientip = clientip,
      nasip = nasip,
      mac = macaddr,
      timestamp = timestamp,
      authenticator = utils.get_normal_authenticator(clientip, nasip, macaddr, timestamp, secretkey)
    }
  }
  
  if code == 200 and response_body["rescode"] == "0" then
    log.success("注销成功 - " .. response_body["resinfo"])
    return true
  end
  
  log.failure("注销失败, 请检查网络或确定登录信息是否正确")
  return false
end

function keepalive_coroutine()
  return coroutine.create(function()
    local i = 1
    while true do
      log.info("正在进行第" .. i .. "次保活操作")
      
      local status = check_network_status()
      
      if not status then
        return
      end
  
      login()
      
      coroutine.yield(status)
      utils.sleep(keepalive_interval)
      i = i + 1
    end
    
  end)
end

function keepalive()
  local co = keepalive_coroutine()
  repeat
    if donotdisturb then
      local current_week = utils.get_current_week()
      if utils.is_array_contains(dndweekrange, current_week) then
        local current_time = utils.get_current_time()
        if utils.is_time_between(current_time, dndstarttime, dndstoptime) then
          break
        end
      end
    end
    local _, status = coroutine.resume(co)
  until not status
end

function login()
  local code, response_headers, _ = requests.get {
    url = "http://www.qq.com"
  }
  
  if not code then
    log.failure("无法连接外网, 可能是退出登录后网络状态未刷新")
    return
  end

  if code == 302 then
    local location = response_headers["location"]
    if location == "https://www.qq.com/" then
      log.success("当前设备已登录")
      return
    end
    
    log.info("当前校园网环境为有线网络环境")
    
    if location:match("172.17.18.3:8080") then
      log.info("检测到需要portal服务认证")
      if portal_login() then
        login()
      end
      return
    end
    
    log.debug("获取到重定向地址为 " .. location)
    
    if clientip == "" or nasip == "" then
      clientip, nasip = location:match("wlanuserip=(.+)&wlanacip=(.+)")
    end

    log.debug("clientip: " .. clientip)
    log.debug("nasip: " .. nasip)
    log.debug("macaddr: " .. macaddr)
    
    if not query_schoolid() then
      return
    end
    
    if not get_enet_cookie() then
      return
    end
    
    if not get_vcode() then
      return
    end
    
    if not enet_login() then
      return
    end
    
    
  elseif code == 200 then
    log.info("当前校园网环境为无线WiFi环境")
    log.info("暂未实现该环境的登录, 请切换到有线宽带登录")
    return
  end
end

function help()
  print("<xxx>: 必选参数\n[xxx]: 可选项(一定要按照顺序)\n")
  print(
    [[Usage:
    main.lua login/logout <username> <password> <macaddr> [clientip] [nasip] [schoolid] [secretkey] - 登录/注销
    自行实现对应平台自动获取MAC地址的功能后:
    main.lua login <username> <password> - 简化登录
    main.lua logout <username> - 简化注销]]
  )
end

function main()
  print("======================")
  
  if donotdisturb then
    log.info("已开启免打扰模式")
    local current_week = utils.get_current_week()
    if utils.is_array_contains(dndweekrange, current_week) then
      local current_time = utils.get_current_time()
      if utils.is_time_between(current_time, dndstarttime, dndstoptime) then
        log.failure("免打扰时间段内脚本不会运行")
        return
      end
    end
    log.info("当前非免打扰时间段, 脚本将继续执行")
  end
  
  if #arg == 0 then
    if command == "" or username == "" then
      help()
      return
    end
  end
  
  if #arg == 1 or arg[1] == "-h" or arg[1] == "--help" then
    help()
    return
  end
  
  if #arg == 2 then
    command, username = unpack(arg)
    if command == "login" then
      log.failure("登录需要提供密码")
      return
    end
  elseif #arg == 3 then
    command, username, password = unpack(arg)
  elseif #arg == 4 then
    command, username, password, macaddr = unpack(arg)
  elseif #arg == 5 then
    command, username, password, macaddr, clientip = unpack(arg)
  elseif #arg == 6 then
    command, username, password, macaddr, clientip, nasip = unpack(arg)
  elseif #arg == 7 then
    command, username, password, macaddr, clientip, nasip, schoolid = unpack(arg)
  elseif #arg == 8 then
    command, username, password, macaddr, clientip, nasip, schoolid, secretkey = unpack(arg)
  end
  
  if macaddr == "" then
    local nwm = require "luci.model.network".init()
    local wandev = nwm:get_wandev()

    macaddr = wandev:mac():gsub(":", "-")

    if command == "logout" then
      clientip = wandev:get_network():ipaddr()
    end
  else
    macaddr = macaddr:gsub(":", "-")
  end
  
  local status = check_network_status()
  
  if not status then
    return
  end
  
  if command == "login" then
    log.info("正在尝试进行登录中...")
    login()
    if keepalive_enabled then
      keepalive()
    end
  elseif command == "logout" then
    log.info("正在尝试进行注销中...")
    enet_logout()
  end
end


main()
print("======================")
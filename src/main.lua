#!/usr/bin/lua

local mime        = require "mime"
local requests    = require "requests"
local utils       = require "utils"

local unpack = unpack or table.unpack

-- 用户自定义参数 begin
local command     = ""

local username    = ""
local password    = ""
local clientip    = ""
-- MAC地址格式为XX:XX:XX:XX:XX:XX
local macaddr     = ""
-- 以下三个变量对同一学校而言可认为是固定常数
local nasip       = "119.146.175.80"
local schoolid    = "1414"
local secretkey   = "Eshore!@#"
-- 用户自定义参数 end

local cookie      = ""
local vcode       = ""

function check_network_status()
  local code, response_headers, response_body = requests.get {
    url = "http://172.17.18.3:8080/portal/",
    headers = {
      ["Accept"] = "application/signed-exchange"
    }
  }
  
  if code == 200 or code == 302 then
    print("[*] 已连接到校园网")
    return true
  end
  
  print("[-] 未连接到校园网, 请检查网络")
  return false
end

function portal_login()
  local code, response_headers, response_body = requests.post {
    url = "http://172.17.18.3:8080/portal/pws?t=li&ifEmailAuth=false",
    headers = {
      ["Accept"] = "application/signed-exchange"
    },
    body = string.format([[userName=%s&userPwd=%s]], username, mime.b64(password)) .. [[%3D&userDynamicPwd=&userDynamicPwdd=&serviceType=&isSavePwd=on&userurl=&userip=&basip=&language=Chinese&usermac=null&wlannasid=&wlanssid=&entrance=null&loginVerifyCode=&userDynamicPwddd=&customPageId=100&pwdMode=0&portalProxyIP=172.17.18.3&portalProxyPort=50200&dcPwdNeedEncrypt=1&assignIpType=0&appRootUrl=http%3A%2F%2F172.17.18.3%3A8080%2Fportal%2F&manualUrl=&manualUrlEncryptKey=]]
  }
  
  if code == 200 then
    print("[*] 已发包进行portal服务认证, 1秒后再次尝试登录")
    return true
  end
  
  print("[-] portal服务认证失败, 请检查网络")
  return false
end

function query_schoolid()
  local timestamp = os.time() * 1000
  local code, response_headers, response_body = requests.json {
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
    print("[*] schoolid: " .. schoolid)
    return true
  end
  
  print("[-] 获取schoolid失败, 请检查网络")
  return false
end

function get_enet_cookie()
  local code, response_headers, response_body = requests.get {
    url = "http://enet.10000.gd.cn:10001/advertisement.do",
    body = string.format([[schoolid=%s]], schoolid)
  }
  
  if code == 200 then
    cookie = response_headers["set-cookie"]
    print("[*] cookie: " .. cookie)
    return true
  end
  
  print("[-] 获取认证cookie失败, 请检查网络")
  return false
end

function get_vcode()
  local timestamp = os.time() * 1000
  local code, response_headers, response_body = requests.json {
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
    print("[*] vcode: " .. vcode)
    return true
  end
  
  print("[-] 获取vcode失败, 请检查网络或确定登录信息是否正确")
  return false
end

function enet_login()
  local timestamp = os.time() * 1000
  local code, response_headers, response_body = requests.json {
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
    print("[+] 登录成功 - " .. response_body["resinfo"])
    return true
  end
  
  print("[-] 登录失败, 请检查网络或确定登录信息是否正确")
  return false
end

function enet_logout()
  local timestamp = os.time() * 1000
  local code, response_headers, response_body = requests.json {
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
    print("[+] 注销成功 - " .. response_body["resinfo"])
    return true
  end
  
  print("[-] 注销失败, 请检查网络或确定登录信息是否正确")
  return false
end

-- 未被使用
function enet_keepalive()
  local timestamp = os.time() * 1000
  local code, response_headers, response_body = requests.get {
    url = "http://enet.10000.gd.cn:8001/hbservice/client/active",
    body = string.format([[username=%s&clientip=%s&nasip=%s&mac=%s&timestamp=%s&authenticator=%s]], username, clientip, nasip, macaddr, timestamp, utils.get_normal_authenticator(clientip, nasip, macaddr, timestamp, secretkey))
  }
  
  if code == 200 and response_body["rescode"] == "0" then
    print("[*] 维持连接成功 - " .. response_body["resinfo"])
    return true
  end
  
  print("[-] 维持连接失败")
  return false
  
end

function login()
  local code, response_headers, response_body = requests.get {
    url = "http://www.qq.com"
  }
  
  if not code then
    print("[-] 无法连接外网, 可能是退出登录后网络状态未刷新")
    return
  end

  if code == 302 then
    local location = response_headers["location"]
    if location == "https://www.qq.com/" then
      print("[+] 当前设备已登录")
      return
    end
    
    print("[*] 当前校园网环境为有线网络环境")
    
    if location:match("172.17.18.3:8080") then
      print("[*] 检测到需要portal服务认证")
      if portal_login() then
        login()
      end
      return
    end
    
    print("[*] 获取到重定向地址为 " .. location)
    
    if clientip == "" or nasip == "" then
      clientip, nasip = location:match("wlanuserip=(.+)&wlanacip=(.+)")
    end

    print("[*] clientip: " .. clientip)
    print("[*] nasip: " .. nasip)
    print("[*] macaddr: " .. macaddr)
    
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
    print("[*] 当前校园网环境为无线WiFi环境")
    print("[*] 暂未实现该环境的登录, 请切换到有线宽带登录")
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
      print("[-] 登录需要提供密码")
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
    print("[-] 登录需要提供登录设备 WAN 接口的 MAC 地址")
    return
    --[[
    *可选*
    你可在此处自行实现相应平台获取对应WAN口的MAC地址和IP地址的功能
    这是防止某天从portal获取clientip失效的备用方案, 同时也是自动获取MAC地址的方案
    以下注释代码为OpenWrt平台下的Luci实现
    --]]
    -- local nwm = require "luci.model.network".init()
    -- local networks = nwm:get_wan_networks()
    -- for _, net in ipairs(networks) do
    --   local mac = net:get_interface():mac()
    --   macaddr = mac:gsub(":", "-")
          
    --   if command == "logout" then
    --     clientip = net:ipaddr()
    --   end
    -- end
  else
    macaddr = macaddr:gsub(":", "-")
  end
  
  local status = check_network_status()
  
  if not status then
    return
  end
  
  if command == "login" then
    print("[*] 正在尝试进行登录中...")
    login()
  elseif command == "logout" then
    print("[*] 正在尝试进行注销中...")
    enet_logout()
  end
end


main()
print("======================")
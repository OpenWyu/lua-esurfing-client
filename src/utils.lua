local md5 = require "md5"

utils = {}

function utils.get_normal_authenticator(clientip, nasip, macaddr, timestamp, secretkey)
  return string.upper(md5.sumhexa(clientip .. nasip .. macaddr .. timestamp .. secretkey))
end

function utils.get_login_authenticator(clientip, nasip, macaddr, timestamp, vcode, secretkey)
  return string.upper(md5.sumhexa(clientip .. nasip .. macaddr .. timestamp .. vcode .. secretkey))
end


return utils
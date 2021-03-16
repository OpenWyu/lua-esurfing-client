# Esurfing client for Lua

[luci-app-esurfing-client](https://github.com/OpenWyu/luci-app-esurfing-client)(暂未开源)的单文件版本, 可独立运行

## 依赖

- [luarocks](https://luarocks.org/)

### 如何解决依赖问题

#### 对于 Windows 用户

1. 安装 Lua for Windows
2. 安装 ZeroBrane Studio Lua IDE

#### 对于 Linux/Mac 用户

不解释

## 下载方法

1. 从[Releases](https://github.com/OpenWyu/lua-esurfing-client/releases)处下载客户端程序
2. clone 本项目

  ```shell
  git clone https://github.com/OpenWyu/lua-esurfing-client
  ```

## 用法

### 作为命令行程序

> `<xxx>`: 必选参数
> 
> `[xxx]`: 可选项(一定要按照顺序)

```shell
# 登录
lua esurfing-client.lua login <username> <password> <macaddr> [clientip] [nasip] [schoolid] [secretkey]
# 注销
lua esurfing-client.lua logout <username> <password> <macaddr> [clientip] [nasip] [schoolid] [secretkey]
```

自行实现对应平台自动获取MAC地址的功能后:

```shell
# 登录
lua esurfing-client.lua login <username> <password>
# 注销
lua esurfing-client.lua logout <username>
```

### 修改配置后直接运行

修改 `src` 目录下的 `main.lua` 文件里的**用户自定义参数**

然后可试执行:

```shell
lua ./main.lua
```

或直接[打包](#打包成单文件客户端)后运行:

```shell
lua ./bin/esurfing-client.lua
```

## 路由器上的使用建议(OpenWrt)

路由器有两种玩法, 详细步骤参考[此篇文章](https://jiayaoo3o.github.io/2019/01/29/%E5%B9%BF%E4%B8%9C%E6%B5%B7%E6%B4%8B%E5%A4%A7%E5%AD%A6%E4%B8%89%E7%A7%8D%E8%B7%AF%E7%94%B1%E5%99%A8%E4%B8%8A%E7%BD%91%E6%96%B9%E5%BC%8F/), 核心原理就是利用 MAC 地址伪装

由于本客户端的登录方式与使用官方客户端的方式不一样, 会造成以下几点不同:

1. 单路由器的方法实际上无需设置关闭 DHCP
2. 单路由器的方法若一段时间内没有任何设备连接上WiFi, 会导致该网络需要重新登录. 而双路由器的方法实际上主路由器是作为了一个连上了的终端设备存在的, 只需在同时, 你的主路由器每隔一段时间与外部进行通信, 比如使用`luci-app-bypass`之类的插件, 这样就可以一直保持登录状态了

### 其他建议

- **强烈建议**路由器的对应 WAN 口的 MAC 地址(对应配置项里的`macaddr`)改成 Android 手机的 MAC 地址, 这样你还能用[安卓端](https://github.com/OpenWyu/SchoolAuthentication)进行登录
- **强烈建议**在工作日恢复网络后(比如早上6点半)定时重启路由器(`luci-app-autoreboot`), 用以刷新网络状态
- 实测有的时候网络会莫名其妙地断开, 对于高级用户, 需要安装`luci-app-serverchan`这样的插件来监控网络状况, 无法联网时应当考虑通知用户重启路由器(路由器远程控制重启或者物理重启)

## 二次开发

只需修改在 `src` 文件夹下, 除了 `amalg.lua` 打包程序以外的程序文件

### 打包成单文件客户端

```shell
cd ./src
lua ./amalg.lua -o ../bin/esurfing-client.lua -s ./main.lua requests utils json md5
```

## TODO

- [ ] 加入定时保活功能
- [ ] 加入免打扰功能(免打扰时间段内不会进行发包保活的操作)

## 相关项目

- [Go实现的EsurfingClient](https://github.com/P1ay2win/TPClient)

## 参考文章/项目

- https://www.cnblogs.com/mayswind/p/3468124.html
- https://iyzm.net/openwrt/624.html
- https://github.com/6DDUU6/SchoolAuthentication
- https://github.com/Dire-CPU/lua_esurfing
- https://github.com/mayswind/luci-app-njitclient
- https://github.com/rufengsuixing/luci-app-adguardhome
- https://github.com/frainzy1477/luci-app-clash
- https://github.com/siffiejoe/lua-amalg


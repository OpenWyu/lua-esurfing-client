# Esurfing client for Lua

[luci-app-esurfing-client](https://github.com/OpenWyu/luci-app-esurfing-client)**(暂未开源)**的单文件版本, 可独立运行

## 依赖

- [luarocks](https://luarocks.org/)

### 如何解决依赖问题

#### 对于 Windows 用户

1. 安装 Lua for Windows
2. 安装 ZeroBrane Studio Lua IDE

#### 对于 Linux/Mac 用户

不解释

## 安装

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
lua ./bin/esurfing-client.lua login <username> <password> <macaddr> [clientip] [nasip] [schoolid] [secretkey]
# 注销
lua ./bin/esurfing-client.lua logout <username> <password> <macaddr> [clientip] [nasip] [schoolid] [secretkey]
```

自行实现对应平台自动获取MAC地址的功能后:

```shell
# 登录
lua ./bin/esurfing-client.lua login <username> <password>
# 注销
lua ./bin/esurfing-client.lua logout <username>
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

- 路由器的对应 WAN 口的 MAC 地址(对应配置项里的`macaddr`)改成 Android 手机的 MAC 地址, 这样你还能用[安卓端](https://github.com/OpenWyu/SchoolAuthentication)进行登录
- 一般而言, 需要在工作日恢复网络后(比如早上6点半)定时重启路由器(`luci-app-autoreboot`), 用以刷新网络状态
- 实测有的时候网络会莫名其妙地断开, 对于高级用户, 需要安装`luci-app-serverchan`这样的插件来监控网络状况, 无法联网时应当考虑通知用户重启路由器(路由器远程控制重启或者物理重启)

## 二次开发

只需修改在 `src` 文件夹下, 除了 `amalg.lua` 打包程序以外的程序文件

### 打包成单文件客户端

```shell
cd ./src
lua ./amalg.lua -o ../bin/esurfing-client.lua -s ./main.lua requests utils json md5
```

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


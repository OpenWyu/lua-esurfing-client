# Esurfing client for Lua

[luci-app-esurfing-client](https://github.com/OpenWyu/luci-app-esurfing-client)的可独立运行的主脚本程序

## 功能

- 一键登录/注销网络(提供命令行和配置文件两种方式)
- 定时保活(与外界通信进行保活)
- 免打扰模式(免打扰时间段内不会执行脚本, 一般结合定时保活功能使用)
  > **注意: 如果你的路由器支持定时关机的操作, 无需使用该功能**
- 较为详尽的日志记录(同时支持标准输出)
- 基本兼容[luci-app-esurfing-client](https://github.com/OpenWyu/luci-app-esurfing-client)的主脚本程序(仅需修改两处 [1](https://github.com/OpenWyu/lua-esurfing-client/compare/openwrt#diff-f10850f6cf7d31487b477962576376fe3d1a50d7a0f8b77724257fb51917ce04R9) [2](https://github.com/OpenWyu/lua-esurfing-client/compare/openwrt#diff-f10850f6cf7d31487b477962576376fe3d1a50d7a0f8b77724257fb51917ce04R358-R367))

## 依赖

- [luarocks](https://luarocks.org/)

### 如何解决依赖问题

#### 对于 Windows 用户

1. 安装 Lua for Windows
2. 安装 ZeroBrane Studio Lua IDE

#### 对于 Linux/Mac 用户

安装`lua`以及`luarocks`依赖

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

修改 `src` 目录下的 `main.lua` 文件里的**用户自定义参数**(直接搜索`用户自定义参数`即可找到)

然后可试执行:

```shell
lua ./main.lua
```

或直接[打包](#打包成单文件客户端)后运行:

```shell
lua ./bin/esurfing-client.lua
```

## 路由器上的使用建议(OpenWrt)

参考 [openwrt](https://github.com/OpenWyu/lua-esurfing-client/tree/openwrt#%E8%B7%AF%E7%94%B1%E5%99%A8%E4%B8%8A%E7%9A%84%E4%BD%BF%E7%94%A8%E5%BB%BA%E8%AE%AEopenwrt) 分支

## 二次开发

只需修改在 `src` 文件夹下, 除了 `amalg.lua` 打包程序以外的程序文件

### 打包成单文件客户端

```shell
cd ./src
lua ./amalg.lua -o ../bin/esurfing-client.lua -s ./main.lua requests utils json md5 log
```

## 目前存在的问题

- 某些时候网络会有问题, 保活协程应提供失败重试多次的子功能

## 相关项目

- [Go实现的EsurfingClient](https://github.com/P1ay2win/TPClient)

## 参考项目

- https://github.com/6DDUU6/SchoolAuthentication
- https://github.com/Dire-CPU/lua_esurfing
- https://github.com/siffiejoe/lua-amalg
- https://github.com/rxi/log.lua

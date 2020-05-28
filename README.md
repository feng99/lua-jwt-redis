用lua实现的基于redis的jwt校验功能

理论上可 拷贝直接使用.

提供接口白名单功能

[TOC]

# 版本说明

nginx version: openresty/1.15.8.3

# 代码逻辑说明




![](http://qa3sq0khl.bkt.clouddn.com/535DF905-8E16-431a-A9A6-34B67230D20D.png)


# 作用:

用 openresty 来实现 jwt 协议，在网关层实现登陆Token校验,提高系统整体负载能力.



# openresty安装jwt模块

 [lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt) 



### opm包管理器安装

> opm是openresty package manage的简写



```
//安装依赖组件
yum -y install perl-Digest-MD5

把openresty命令加到系统变量PATH里去
vim /etc/profile
在export PATH=这一行的最后面加上
:/usr/local/openresty/bin
然后执行下面这个命令,
source /etc/profile


//安装命令   在openresty目录下执行
opm get SkyLothar/lua-resty-jwt
//安装成功后会在
/usr/local/openresty/site/lualib/resty
```





# 代码实现

##  请看JWT.php

## /data/app_config/application.ini

```

[jwtAuth]

; JWT Secret Key 密钥
;注意这里的  要与jwt.lua脚本里配置的一致
secretKey = xxxxxxxxxxx

```

## 服务器代码

### 生成jwt token

> 只携带了userId参数

```

//生成jwt token 并保存到redis中,并设置过期时间

//在response对象中设置header属性Authorization: Basic token内容
//其实设置哪个字段都行 自定义一个名字 叫token都可以   和客户端约定好就行

public function jwtEncodeAction()
    {
        try {
            //$payload, $key, $alg = 'HS256', $keyId = null, $head = null
            $secretKey = DiHelper::getConfig()->jwtAuth->secretKey;
            $token = JWT::encode(["userId" => "123458"],$secretKey);
            //假设1个小时过期
            //$redis->setex(token,3600);
            $this->getFlash()->successJson(['token'=>$token]);
        } catch (CustomException $e) {
            throw new JsonFmtException($e->getMessage(), $e->getCode());
        }
    }
    
    //$response->setHeader("token",$data['token']);
```

### 解密jwt token

```
public function jwtDecodeAction()
    {
        try {
            $secretKey = DiHelper::getConfig()->jwtAuth->secretKey;
            $tokenb = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOiIxMjM0NTgifQ.-XLFdIggONBJsrUSpu16QLfWw6peaY1H-kwzeMbpKqc';
            $body = JWT::decode($tokenb,$secretKey);
            var_dump($body);
        } catch (CustomException $e) {
            throw new JsonFmtException($e->getMessage(), $e->getCode());
        }
    }
    
    浏览器输出信息为: 
    把userId打印出来
    object(stdClass)#98 (1) { ["userId"]=> string(6) "123458" }
```

## Nginx配置  nginx server.conf



## LUA脚本代码  jwt.lua  

代码中加了中文注释.

### 把nginx的error_log级别设成debug，错误日志里会有lua的错误信息



## key的时间过期策略

> app冷启动  访问初始化配置接口的时候   set 过期时间为 604800  
>
> 有效期7天    



# 效果

不传递jwt token  返回401

![image-20200526102152286](http://qa3sq0khl.bkt.clouddn.com/image-20200526102152286.png)

# 有疑问请提issues 
--接口地址白名单
arr = {}
arr["/index/login"]    = 1;
arr["/index/register"] = 1;
arr["/test/index"] = 1;
local requesturi = ngx.var.request_uri;
local ishit = arr[requesturi];
if ishit == 1 then
  ngx.exit(ngx.OK)
end


--从redis中查询数据的函数
local function redkey(kid, key)
    -- get key from redis
    -- nil  (something went wrong, let the request pass)
    -- null (no such key, reject the request)
    -- key  (the key)

    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(100) -- 100ms

    local ok, err = red:connect(ngx.var.redhost, ngx.var.redport)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to redis: ", err)
        return nil
    end

    if ngx.var.redauth then
        local ok, err = red:auth(ngx.var.redauth)
        if not ok then
            ngx.log("failed to authenticate: ", err)
            return nil
        end
    end

    if ngx.var.reddb then
        local ok, err = red:select(ngx.var.reddb)
        if not ok then
            ngx.log("failed to select db: ", ngx.var.reddb, " ", err)
            return nil
        end
    end

    --hash hget
    --存储为hash结构 时间计算比较麻烦 且官方不推荐使用自带的时间函数
--[[    local res, err = red:hget(kid, key)
    if not res then
        ngx.log(ngx.ERR, "failed to get kid: ", kid ,", ", err)
        return nil
    end
--]]

    --string get
    local res, err = red:get(kid..key)
    if not res then
        ngx.log(ngx.ERR, "failed to get kid: ", kid ,", ", err)
        return nil
    end

    if res == ngx.null then
        ngx.log(ngx.ERR, "key ", kid, " not found")
        return ngx.null
    end

    local ok, err = red:close()
    if not ok then
        ngx.log(ngx.ERR, "failed to close: ", err)
    end

    return res
end




local jwt = require "resty.jwt";
local cjson = require("cjson");

ngx.log(ngx.INFO,ngx.var.http_Authorization);
--获取http Authorization数据 get/post都需要传递
local auth_header = ngx.var.http_Authorization
if auth_header == nil then
    --ngx.exit(ngx.OK)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

--检查是否传递token
local _, _, token = string.find(auth_header, "Bearer%s+(.+)")
if token == nil then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.log(ngx.WARN, "Missing token")
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

--解析token  
local jwt_obj = jwt:load_jwt('R6v7TUC0Xj0nCPzZDwXXXXXXXXXX', token)
--ngx.say(cjson.encode(jwt_obj));
if not jwt_obj.valid then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("{error: 'invalid token (101)'}")
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

--解析userId数据
local userId = jwt_obj.payload['userId']
--从redis中根据userId查询token
if userId > 0 then
    local private_jwt = redkey('jwt', userId)
    if private_jwt == ngx.null then
        ngx.status = ngx.HTTP_UNAUTHORIZED
        ngx.say("{error: 'session not found'}")
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    else
	--修改请求头信息 增加自定义字段 向后传递给业务服务
        ngx.req.set_header('Authorization', "Bearer "..private_jwt)
        ngx.req.set_header('userId',userId)
    end
else
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say("{error: '"..jwt_obj.reason.."'}")
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

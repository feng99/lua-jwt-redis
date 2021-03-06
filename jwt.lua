--api白名单处理
arr = {}
arr["/index/index"]    = 1;
arr["/user/login/v1"]    = 1;
arr["/index/register"] = 1;
arr["/sms/getCode/v1"] = 1;
arr["/user/weChatLogin/v1"] = 1;
arr["/ryun/userStatus/v1"] = 1;
local requesturi = ngx.var.request_uri;
local testpath = string.find(requesturi, "test/", 1);

--跳过/test/测试接口
if testpath ~= nil then
   ngx.exit(ngx.OK)
end

local ishit = arr[requesturi];
if ishit == 1 then
  ngx.exit(ngx.OK)
end


--从redis中查询数据的函数
local function redkey(kid, key)

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

    --string get
    local res, err = red:get(kid..":"..key)
    --ngx.log(res)
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




--local jwt = require "resty.jwt";
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



local user_id = redkey('jwt', token)
if user_id == ngx.null then
   	ngx.status = ngx.HTTP_UNAUTHORIZED
   	ngx.say("{error: 'token not found'}")
   	ngx.exit(ngx.HTTP_UNAUTHORIZED)
else
	--修改请求头信息 增加自定义字段 向后传递给业务服务
  	--ngx.req.set_header('Authorization', "Bearer "..private_jwt)
    ngx.req.set_header('userId',user_id)
end


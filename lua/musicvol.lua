local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
    ngx.say("failed to instantiate mysql: ", err)
    return
end
db:set_timeout(1000) -- 1 sec
local ok, err, errcode, sqlstate = db:connect{
    host = "127.0.0.1",
    port = 3306,
    database = "logDB",
    user = "root",
    password = "",
    charset = "utf8",
    max_packet_size = 1024 * 1024,
}
if not ok then
    --ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
    ngx.say("{\"status\":-1,\"msg\":\"can't connect DB\"}") 
    return
end
--ngx.say("connected to mysql.")

local paramsModel = require("getparams")
local params = paramsModel:new()
local args = params.args

local mac_add = args["mac_add"]
local vol_value = args["vol_value"]
local operation_time = os.date("%Y-%m-%d %H:%M", os.time())
local operation_long_time = os.time()
local operation_type = args["operation_type"]
local nonce = args["nonce"]
local rkey = args["rkey"]

if (mac_add == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack mac\"}")
    return
end

if (vol_value == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack vol value\"}")
    return
end

if (operation_type == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack operation type\"}")
    return
end

if (nonce == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack nonce\"}")
    return
end

if (rkey == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack rkey\"}")
    return
end

local generationMD5 = paramsModel.createMD5(nonce)
if not generationMD5 then
    ngx.say("{\"status\":-3,\"msg\":\"encode error\"}") 
    return
end

if not (generationMD5 == rkey) then
    ngx.say("{\"status\":-2,\"msg\":\"rkey error\"}") 
    return
end

res, err, errcode, sqlstate = db:query("insert into Music_Vol (mac_add, vol_value, operation_time, operation_long_time, operation_type) "
                                        .. "values (" .. mac_add .."," 
                                        .. vol_value ..",\'"
                                        .. operation_time .."\',"
                                        .. operation_long_time ..","
                                        .. operation_type
                                        .. ")")
if not res then
    --ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    ngx.say("{\"status\":-1,\"msg\":\"insert DB fail. "..err.."\"}") 
    return
end

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    --ngx.say("failed to set keepalive: ", err)
    ngx.say("{\"status\":-1,\"msg\":\"keep alive fail. "..err.."\"}")
    return
else
    ngx.say("{\"status\":0,\"msg\":\"success insert to DB\"}") 
end

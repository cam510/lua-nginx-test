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
    ngx.say("{\"status\":-1,\"msg\":\"can't connect DB\"}") 
    return
end

local paramsModel = require("getparams")
local params = paramsModel:new()
local args = params.args

local mac_add = args["mac_add"]
local on_off = args["on_off"]
local boot_time = os.date("%Y-%m-%d %H:%M", os.time())
local boot_long_time = os.time()
local nonce = args["nonce"]
local rkey = args["rkey"]

if (mac_add == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack mac\"}")
    return
end

if (on_off == nil) then
    ngx.say("{\"status\":-4,\"msg\":\"lack on off\"}")
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

res, err, errcode, sqlstate = db:query("insert into Boot_Device (mac_add, on_off, boot_time, boot_long_time) "
                                        .. "values (" .. mac_add .. ","
                                        .. on_off .. ",\'"
                                        ..boot_time .."\',"
                                        .. boot_long_time .. ")")
                                        
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

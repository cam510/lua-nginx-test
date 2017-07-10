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
    ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
    return
end
--ngx.say("connected to mysql.")

local paramsModel = require("getparams")
local params = paramsModel:new()
local args = params.args

local mac_add = args["mac_add"]
local on_off = args["on_off"]
local boot_time = os.date("%Y-%m-%d %H:%M", os.time())
local boot_long_time = os.time()

res, err, errcode, sqlstate = db:query("insert into Boot_Device (mac_add, on_off, boot_time, boot_long_time) "
                                        .. "values (" .. mac_add .. ","
                                        .. on_off .. ",\'"
                                        ..boot_time .."\',"
                                        .. boot_long_time .. ")")
if not res then
    ngx.say("bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
    return
end

local ok, err = db:set_keepalive(10000, 100)
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
else
    ngx.say("{\"status\":0,\"msg\":\"success insert to DB\"}") 
end

local _M = {}
local mt = { __index = _M }
local args = nil
local secret = "c9fc36e6d0c9ba8bffbc62d44f49aad0"

function _M.new (self)
    local request_method = ngx.var.request_method

    if "GET" == request_method then
        args = ngx.req.get_uri_args()
    elseif "POST" == request_method then
        ngx.req.read_body()
        args = ngx.req.get_post_args()
    end
    
--    output = string.format("the test_a is %s the test_b is %s",test_a, test_b)
--    ngx.log(ngx.INFO, output)
    return setmetatable({args = args}, mt)
end

-- for test
function _M.createMD5(nonce)
    local md5 = require("md5")
    return md5.sumhexa(nonce)
end

return _M



--
-- A LUA module to handle swapping opaque access tokens for JWTs
--

local _M = {}
local http = require "resty.http"
local jwt = require 'resty.jwt'
local pl_stringx = require "pl.stringx"

--
-- Return a generic message for all three of these error categories
--
local function invalid_token_error_response(config)
    error_response(ngx.HTTP_UNAUTHORIZED, "unauthorized", "Missing, invalid or expired access token", config)
end

--
-- Introspect the access token
--
local function introspect_access_token(access_token, config)

    local httpc = http:new()
    local introspectCredentials = ngx.encode_base64(config.client_id .. ":" .. config.client_secret)
    local res, err = httpc:request_uri(config.introspection_endpoint, {
        method = "POST",
        body = "token=" .. access_token,
        headers = { 
            ["authorization"] = "Basic " .. introspectCredentials,
            ["content-type"] = "application/x-www-form-urlencoded",
            ["accept"] = "application/jwt"
        }
    })

    if err then
        local connectionMessage = "A connection problem occurred during access token introspection"
        ngx.log(ngx.WARN, connectionMessage .. err)
        return { status = 0 }
    end

    if not res then
        return { status = 0 }
    end

    if res.status ~= 200 then
        return { status = res.status }
    end

    if res.status == 200 then
        ngx.log(ngx.INFO, "The introspection request was successful")
    end

    return { status = res.status, body = res.body }
end

--
-- The public entry point to introspect the token then forward the JWT to the API
--
function _M.execute(config)

    if ngx.req.get_method() == "OPTIONS" then
        return
    end

    local access_token = ngx.req.get_headers()["Authorization"]
    if access_token then
        access_token = pl_stringx.replace(access_token, "Bearer ", "", 1)
    end

    if not access_token then
        ngx.log(ngx.WARN, "No access token was found in the Authorization bearer header")
        invalid_token_error_response(config)
    end

    local res = introspect_access_token(access_token, config)
    if res.status == 204 then
        ngx.log(ngx.WARN, "Received a " .. res.status .. " introspection response due to the access token being invalid or expired")
        invalid_token_error_response(config)
    end

    local jwt = res.body
    ngx.log(ngx.INFO, "The request was successfully authorized by the gateway")
    ngx.req.set_header("Authorization", "Bearer " .. jwt)
end

return _M

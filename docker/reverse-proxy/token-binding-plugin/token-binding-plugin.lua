--
-- A LUA module to verify that the JWT sent over a Mutual TLS matches that provided at authentication
--

local _M = {}
local jwt = require 'resty.jwt'
local pl_stringx = require "pl.stringx"
local resty_string = require 'resty.string'

--
-- Return errors due to invalid requests or server technical problems
--
local function error_response(status, code, message)

    local jsonData = '{"code":"' .. code .. '", "message":"' .. message .. '"}'
    ngx.status = status
    ngx.header['content-type'] = 'application/json'
    ngx.say(jsonData)
    ngx.exit(status)
end

--
-- Return an error message to indicate an unauthorized request
--
local function unauthorized_error_response(config)
    error_response(ngx.HTTP_UNAUTHORIZED, "unauthorized", "Missing, invalid or expired access token", config)
end

--
-- Parse the JWT and retrieve the cnf/x5t#S256 claim
--
local function read_token_thumbprint(jwt_text)
    
    local jwt = jwt:load_jwt(jwt_text)
    if jwt.valid and jwt.payload.cnf and jwt.payload.cnf['x5t#S256'] then
        return jwt.payload.cnf['x5t#S256']
    end
    
    return nil
end

--
-- The public entry point to verify sender constrained access token details
--
function _M.execute(config)

    if config.type ~= 'certificate-bound' then
        ngx.log(ngx.WARN, "An invalid or unsupported type parameter was received")
        error_response(ngx.HTTP_INTERNAL_SERVER_ERROR, "server_error", "Problem encountered processing the request")
    end

    -- By this time the access token should be available as a JWT
    local access_token = ngx.req.get_headers()["Authorization"]
    if access_token then
        access_token = pl_stringx.replace(access_token, "Bearer ", "", 1)
    end

    if not access_token then
        ngx.log(ngx.WARN, "No access token was found in the Authorization bearer header")
        unauthorized_error_response()
    end

    -- We should also have a client certificate
    if ngx.var.ssl_client_escaped_cert == nil then
        ngx.log(ngx.WARN, "The request did not contain a valid client certificate")
        unauthorized_error_response()
    end

    -- Read the thumbprint
    local thumbprint = read_token_thumbprint(access_token)
    if thumbprint == nil then
        ngx.log(ngx.WARN, "Unable to parse the x5t#S256 from the received JWT access token")
        unauthorized_error_response()
    end
    
    -- This gets a value of the following form and we need to create a SHA256 hash of it, so needs some manipulation
    -- -----BEGIN%20CERTIFICATE-----%0AMIIDJjC
    
    ngx.log(ngx.WARN, "CERTIFICATE: " .. ngx.var.ssl_client_escaped_cert)
    ngx.log(ngx.WARN, "CERTIFICATE HASH: " .. resty_string.sha256(ngx.var.ssl_client_escaped_cert))
    ngx.log(ngx.WARN, "THUMBPRINT: "  .. thumbprint)
end

return _M
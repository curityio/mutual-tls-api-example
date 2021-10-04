--
-- A LUA module to verify token binding for a JWT sent via a Mutual TLS connection
--

local _M = {}
local jwt = require 'resty.jwt'
local pl_stringx = require "pl.stringx"
local str = require 'resty.string'
local sha256 = require 'resty.sha256'
local b64 = require 'ngx.base64'
local ssl = require 'ngx.ssl'

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
local function unauthorized_error_response()
    error_response(ngx.HTTP_UNAUTHORIZED, 'unauthorized', 'Missing, invalid or expired access token')
end

--
-- Parse the JWT and retrieve the cnf/x5t#S256 claim issued at the time of authentication
--
local function read_token_thumbprint(jwt_text)
    
    local jwt = jwt:load_jwt(jwt_text)
    if jwt.valid and jwt.payload.cnf and jwt.payload.cnf['x5t#S256'] then
        return jwt.payload.cnf['x5t#S256']
    end
    
    return nil
end

--
-- Calculate the SHA256 hash of the client certificate received via Mutual TLS
-- https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.8
--
local function get_sha256_thumbprint(certificate)

    local der = ssl.cert_pem_to_der(certificate)
    local hash = sha256:new()
    hash:update(der)
    local digest = hash:final()
    return b64.encode_base64url(digest)
end

--
-- The public entry point to verify sender constrained access token details
--
function _M.execute(config)

    if config.type ~= 'certificate-bound' then
        ngx.log(ngx.WARN, 'An invalid or unsupported type parameter was received')
        error_response(ngx.HTTP_INTERNAL_SERVER_ERROR, 'server_error', 'Problem encountered processing the request')
    end

    -- By this time the access token should be available as a JWT
    local access_token = ngx.req.get_headers()['Authorization']
    if access_token then
        access_token = pl_stringx.replace(access_token, 'Bearer ', '', 1)
    end

    if not access_token then
        ngx.log(ngx.WARN, 'No access token was found in the Authorization bearer header')
        unauthorized_error_response()
    end

    -- We should also have a client certificate
    if ngx.var.ssl_client_escaped_cert == nil then
        ngx.log(ngx.WARN, 'The request did not contain a valid client certificate')
        unauthorized_error_response()
    end

    -- Read the thumbprint
    local jwtThumbprint = read_token_thumbprint(access_token)
    if jwtThumbprint == nil then
        ngx.log(ngx.WARN, 'Unable to parse the x5t#S256 from the received JWT access token')
        unauthorized_error_response()
    end

    -- Calculate the SHA256 hash of the certificate / ssl_client_escaped_cert
    local certThumbprint = get_sha256_thumbprint(ngx.var.ssl_client_raw_cert)
    if certThumbprint ~= jwtThumbprint then
        ngx.log(ngx.WARN, 'The client certificate details of the request and the JWT do not match')
        unauthorized_error_response()
    end
end

return _M
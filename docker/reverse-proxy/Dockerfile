FROM openresty/openresty:1.21.4.3-2-bionic

RUN luarocks install lua-resty-http
RUN luarocks install lua-resty-string
RUN luarocks install lua-resty-jwt

COPY dependencies/sender-constrained-token-plugin/plugin/sender-constrained-token-plugin.lua  /usr/local/openresty/lualib
COPY dependencies/lua-nginx-phantom-token-plugin/plugin/phantom-token-plugin.lua              /usr/local/openresty/lualib

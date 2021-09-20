FROM openresty/openresty:1.19.3.1-8-bionic

RUN luarocks install penlight
RUN luarocks install lua-resty-http
RUN luarocks install lua-resty-jwt

COPY phantom-token-plugin.lua /usr/local/openresty/lualib
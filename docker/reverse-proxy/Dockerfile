FROM openresty/openresty:1.19.3.1-8-bionic

RUN luarocks install penlight
RUN luarocks install lua-resty-http
RUN luarocks install lua-resty-string
RUN luarocks install lua-resty-jwt

COPY .deploy/token-binding-plugin/plugin/token-binding-plugin.lua           /usr/local/openresty/lualib
COPY .deploy/openresty-phantom-token-plugin/plugin/phantom-token-plugin.lua /usr/local/openresty/lualib
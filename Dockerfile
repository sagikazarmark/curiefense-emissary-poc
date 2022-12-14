FROM curiefense/curieproxy-envoy:v1.5.0 as curieproxy

FROM docker.io/emissaryingress/emissary:3.2.0

# Add Curiefense to entrypoint.sh
# TODO: Make this better by not copying the whole entrypoint (eg. wrap original entrypoint, insert into existing, etc)
COPY entrypoint.sh /buildroot/ambassador/python/

# Install Curiefense dependencies
RUN apk add jq lua lua-dev luarocks pcre2 pcre2-dev geoip geoip-dev vectorscan vectorscan-dev

# Are these really necessary?
RUN apk add python3 gcc g++ make unzip

RUN ln -s $(which luarocks-5.1) /usr/local/bin/luarocks

RUN luarocks install lrexlib-pcre2 && \
  luarocks install lua-cjson && \
  luarocks install lua-resty-string && \
  luarocks install luafilesystem && \
  luarocks install luasocket && \
  luarocks install redis-lua && \
  luarocks install compat53 && \
  luarocks install mmdblua && \
  luarocks install luaipc && \
  luarocks install lua-resty-injection

#COPY --from=curieproxy /lua /lua
COPY --from=curieproxy /lua /ambassador/lua
COPY --from=curieproxy /usr/local/lib/lua/5.1/*.so /usr/local/lib/lua/5.1/
# RUN ln -s /usr/lib/libhs.so.5 /usr/local/lib/lua/5.1/libhs.so.5
# RUN ln -s /usr/lib/libhs.so.5 /usr/local/lib/lua/5.1/libhs.so.4
# RUN ln -s /usr/lib/libhs.so.5 /usr/lib/libhs.so.4
# RUN ln -s /usr/lib/libhs.so.5 /ambassador/lua/libhs.so.4
RUN ln -s /usr/lib/libhs.so.5 /usr/glibc-compat/lib/libhs.so.5
RUN ln -s /usr/lib/libhs.so.5 /usr/glibc-compat/lib/libhs.so.4
COPY --from=curieproxy --chown=ambassador:root /bootstrap-config/config /bootstrap-config/config

RUN mkdir /cf-config && chmod a+rwxt /cf-config && chown ambassador.root /cf-config

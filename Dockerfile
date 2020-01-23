FROM alpine:latest as builder
RUN apk add alpine-sdk build-base openldap-dev lua5.1-dev lua5.2-dev lua5.3-dev openldap openldap-back-bdb \
 && adduser -D builder                  \
 && addgroup builder abuild             \
 && mkdir -p /var/cache/distfiles       \
 && chgrp abuild /var/cache/distfiles   \
 && chmod g+w /var/cache/distfiles      \
 && su builder -c 'abuild-keygen -an'   \
 && cp /home/builder/.abuild/builder*.rsa.pub /etc/apk/keys/
RUN su builder -c 'mkdir /tmp/lua-ldap'
COPY lua-ldap/* /tmp/lua-ldap
WORKDIR /tmp/lua-ldap
RUN su builder -c "abuild -r"
RUN mv /home/builder/packages/tmp/*/lua*-ldap-*.apk /tmp

FROM alpine:latest
ENV PROSODY_VERSION 0.11.4
ENV LUA_VERSION 5.2
COPY --from=builder /etc/apk/keys/builder*.rsa.pub /etc/apk/keys/
COPY --from=builder /tmp/lua*.apk /tmp/
COPY entrypoint.sh /usr/bin

RUN apk --update --no-progress add openssl lua${LUA_VERSION} libidn lua${LUA_VERSION}-filesystem lua${LUA_VERSION}-expat lua${LUA_VERSION}-socket lua${LUA_VERSION}-sec lua${LUA_VERSION}-lzlib lua${LUA_VERSION}-dbi-sqlite3 lua${LUA_VERSION}-dbi-postgresql lua${LUA_VERSION}-dbi-mysql lua${LUA_VERSION}-bitop lua${LUA_VERSION}-struct /tmp/lua${LUA_VERSION}-ldap*apk openldap-clients \
 && apk --update --no-progress add --virtual build-deps autoconf build-base lua${LUA_VERSION}-dev libidn-dev openssl-dev curl linux-headers mercurial \
 && curl -sL https://prosody.im/downloads/source/prosody-${PROSODY_VERSION}.tar.gz|tar -xz \
 && cd prosody-${PROSODY_VERSION} \
 && ./configure --prefix=/usr \
 && make && make install \
 && cd .. \
 && hg clone 'https://hg.prosody.im/prosody-modules/' prosody-modules \
 && rm -rf prosody-modules/mod_mam \
 && mv prosody-modules/mod* /usr/lib/prosody/modules/ \
 && rm -rf prosody-${PROSODY_VERSION} prosody-modules \
 && apk --purge del build-deps \
 && adduser -D prosody \
 && mkdir -p /var/run/prosody \
 && chown prosody:prosody /var/run/prosody \
 && chmod +x /usr/bin/entrypoint.sh \
 && cp /etc/prosody/prosody.cfg.lua /etc/prosody/prosody.cfg.lua.orig

ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
CMD ["/bin/su", "prosody", "-c", "/usr/bin/prosody"]
EXPOSE 5222
EXPOSE 5269
VOLUME /var/lib/prosody /etc/prosody/certs
ENV PROSODY_ADMINS ""
ENV PROSODY_HOST localhost
ENV PROSODY_CERTS_DIR "/etc/prosody/certs"

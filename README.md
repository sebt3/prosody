# Prosody docker image

This is based on alpine and feature ldap support

Suggested usage with compose :
```
version: '3.5'
volumes:
  data:
  certs:
    external:
      name: traefik_certs
networks:
  http:
  ldap_auth:
    external: true

services:
  prosody:
    image: sebt3/prosody:arm0.11.4
    environment:
      PROSODY_ADMINS: "{{ email|quote }}"
      PROSODY_HOST: "{{ domain }}"
      PROSODY_ALT_HOST: "prosody"
      ENABLE_BOSH: "yes"
      LDAP_SERVER: "ldap"
      LDAP_BASE: "{{ ldap_base }}"
      LDAP_FILTER: "(mail=$user)"
      LDAP_ROOT_DN: "cn=admin,{{ ldap_root }}"
      LDAP_ADMIN_PASSWORD: "{{ ldap_root_password }}"
    ports:
      - 5222:5222
      - 5269:5269
    volumes:
      - data:/var/lib/prosody
      - certs:/etc/prosody/certs:ro
    networks:
    - http
    - ldap_auth
```
Warning, this include jinja2 templates variables. You'll probably want to change that

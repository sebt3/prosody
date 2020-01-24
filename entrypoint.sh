#!/bin/sh

ADMS=''
for i in ${PROSODY_ADMINS};do
	[ ! -z "$ADM" ] && ADMS="$ADMS,"
	ADMS="$ADMS\"$i\""
done
MODS=""
CONFS=""
if [ "${ENABLE_BOSH:-"no"}" = "yes" ];then
	CONFS="cross_domain_bosh = { \"https://${PROSODY_HOST}\" }"
	MODS="$MODS                \"bosh\";
"
fi
if [ "${LDAP_BASE:-"no"}" != "no" ];then
	CONFS="$CONFS
authentication = \"ldap\"
ldap_base = \"${LDAP_BASE}\""
	if [ "${LDAP_SERVER:-"no"}" != "no" ];then
	CONFS="$CONFS
ldap_server = \"${LDAP_SERVER}\""
	fi
	if [ "${LDAP_ROOT_DN:-"no"}" != "no" ];then
	CONFS="$CONFS
ldap_rootdn = \"${LDAP_ROOT_DN}\"
ldap_password = \"${LDAP_ADMIN_PASSWORD}\""
	fi
	if [ "${LDAP_FILTER:-"no"}" != "no" ];then
	CONFS="$CONFS
ldap_filter = \"${LDAP_FILTER}\""
	fi
else
	CONFS="authentication = \"internal_hashed\""
fi
ALTS=""
if [ "${PROSODY_ALT_HOST:-"no"}" != "no" ];then
	ALTS="VirtualHost \"${PROSODY_ALT_HOST}\""
fi
cat > /etc/prosody/prosody.cfg.lua <<END
admins = { ${ADMS} }
daemonize = false;
modules_enabled = {
                "roster";
                "saslauth";
                "tls";
                "dialback";
                "disco";
                "carbons";
                "pep";
                "private";
                "blocklist";
                "vcard4";
                "vcard_legacy";
                "version";
                "uptime";
                "time";
                "ping";
                "register";
                "admin_adhoc";
$MODS
}
modules_disabled = {
}
hsts_header = "max-age=31556952"
consider_bosh_secure = true
-- certificates = "${PROSODY_CERTS_DIR:-"/etc/prosody/certs"}"
https_certificate = "${PROSODY_CERTS_DIR:-"/etc/prosody/certs"}/${PROSODY_HOST}.chain.crt"
ssl = {
        key = "${PROSODY_CERTS_DIR:-"/etc/prosody/certs"}/${PROSODY_HOST}.key";
        certificate = "${PROSODY_CERTS_DIR:-"/etc/prosody/certs"}/${PROSODY_HOST}.chain.crt";
        protocol = "tlsv1_2+";
}

allow_registration = false
c2s_require_encryption = true
s2s_require_encryption = true
s2s_secure_auth = false
$CONFS
archive_expires_after = "1w"
log = {
        info = "*console";
}
pidfile = "/var/run/prosody/prosody.pid"
VirtualHost "${PROSODY_HOST}"
$ALTS
END

chown -R prosody:prosody /var/lib/prosody

echo "Starting $@"
exec "$@"

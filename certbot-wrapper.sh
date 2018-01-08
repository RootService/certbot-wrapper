#!/bin/sh
#
#  **********************************************************************************
#  *                                certbot-wrapper                                 *
#  *                            -----------------------                             *
#  *                                                                                *
#  **********************************************************************************
#  *                                                                                *
#  * MIT License                                                                    *
#  *                                                                                *
#  * Copyright © 2016-2018 Markus Kohlmeyer <rootservice@gmail.com>                 *
#  *                                                                                *
#  * Permission is hereby granted, free of charge, to any person obtaining a copy   *
#  * of this software and associated documentation files (the "Software"), to deal  *
#  * in the Software without restriction, including without limitation the rights   *
#  * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      *
#  * copies of the Software, and to permit persons to whom the Software is          *
#  * furnished to do so, subject to the following conditions:                       *
#  *                                                                                *
#  * The above copyright notice and this permission notice shall be included in all *
#  * copies or substantial portions of the Software.                                *
#  *                                                                                *
#  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     *
#  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       *
#  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    *
#  * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         *
#  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  *
#  * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  *
#  * SOFTWARE.                                                                      *
#  *                                                                                *
#  **********************************************************************************

DIRSSL="/data/ssl"
DIRWWW="/data/www"

##########################################################
###### !!! DO NOT EDIT ANYTHING BELOW THIS LINE !!! ######
##########################################################

STAGING=1
ACMEPROT=1

CREATE=0
RENEW=0
CRON=0

HSTS=0
HPKP=0
APACHE=0

DOVECOT=0
POSTFIX=0

VERSION="0.0.6"
CUR_DATE_F="`/bin/date -j -u +%F`"
CUR_DATE_S="`/bin/date -j -u +%s`"

##############################
###### Global functions ######
##############################

black="\033[0m"
boldblack="\033[1;0m"
red="\033[31m"
boldred="\033[1;31m"
green="\033[32m"
boldgreen="\033[1;32m"
yellow="\033[33m"
boldyellow="\033[1;33m"
blue="\033[34m"
boldblue="\033[1;34m"
magenta="\033[35m"
boldmagenta="\033[1;35m"
cyan="\033[36m"
boldcyan="\033[1;36m"
white="\033[37m"
boldwhite="\033[1;37m"

cecho () {
  local default_msg="No message passed."
  local message="${1:-$default_msg}"
  local color="${2:-black}"
  case "$color" in
    black) /usr/bin/printf "$black";;
    boldblack) /usr/bin/printf "$boldblack";;
    red) /usr/bin/printf "$red";;
    boldred) /usr/bin/printf "$boldred";;
    green) /usr/bin/printf "$green";;
    boldgreen) /usr/bin/printf "$boldgreen";;
    yellow) /usr/bin/printf "$yellow";;
    boldyellow) /usr/bin/printf "$boldyellow";;
    blue) /usr/bin/printf "$blue";;
    boldblue) /usr/bin/printf "$boldblue";;
    magenta) /usr/bin/printf "$magenta";;
    boldmagenta) /usr/bin/printf "$boldmagenta";;
    cyan) /usr/bin/printf "$cyan";;
    boldcyan) /usr/bin/printf "$boldcyan";;
    white) /usr/bin/printf "$white";;
    boldwhite) /usr/bin/printf "$boldwhite";;
  esac
  /usr/bin/printf "%s\n" "$message"
  /usr/bin/tput sgr0
  /usr/bin/printf "$black"
  return
}

cechon () {
  local default_msg="No message passed."
  local message="${1:-$default_msg}"
  local color="${2:-black}"
  case "$color" in
    black) /usr/bin/printf "$black";;
    boldblack) /usr/bin/printf "$boldblack";;
    red) /usr/bin/printf "$red";;
    boldred) /usr/bin/printf "$boldred";;
    green) /usr/bin/printf "$green";;
    boldgreen) /usr/bin/printf "$boldgreen";;
    yellow) /usr/bin/printf "$yellow";;
    boldyellow) /usr/bin/printf "$boldyellow";;
    blue) /usr/bin/printf "$blue";;
    boldblue) /usr/bin/printf "$boldblue";;
    magenta) /usr/bin/printf "$magenta";;
    boldmagenta) /usr/bin/printf "$boldmagenta";;
    cyan) /usr/bin/printf "$cyan";;
    boldcyan) /usr/bin/printf "$boldcyan";;
    white) /usr/bin/printf "$white";;
    boldwhite) /usr/bin/printf "$boldwhite";;
  esac
  /usr/bin/printf "%s" "$message"
  /usr/bin/tput sgr0
  /usr/bin/printf "$black"
  return
}

tolower () {
  if [ -z "${1}" ]
  then
    return
  fi
  /bin/echo "${@}" | /usr/bin/tr "[[:upper:]]" "[[:lower:]]"
  return
}

toupper () {
  if [ -z "${1}" ]
  then
    return
  fi
  /bin/echo "${@}" | /usr/bin/tr "[[:lower:]]" "[[:upper:]]"
  return
}

read_prompt () {
  read -p "$(cechon "${1} " boldwhite >&2)" "${2:-REPLY}"
  until [ -z "$(/bin/echo "${2:-REPLY}" | /usr/bin/tr -d "[[:print:]]")" ]
  do
    cecho "non-printable char(s) detected! Please retry..." red
    read_prompt "${1}" "${2}"
  done
  return
}

read_passwd () {
  read -s -p "$(cechon "${1} " boldwhite >&2)" "${2:-REPLY}"
  until [ -z "$(/bin/echo "${2:-REPLY}" | /usr/bin/tr -d "[[:print:]]")" ]
  do
    cecho "non-printable char(s) detected! Please retry..." red
    read_prompt "${1}" "${2}"
  done
  return
}

show_usage () {
  /bin/echo "Usage: $(basename ${0}) [OPTIONS]

OPTIONS:
      --create      Create and install new certificates
      --renew       Renew all certificates valid for less than 10 days
      --cron        Same as --renew but without any prompts or output
      --help        Display this help and exit
      --version     Output version information and exit

Report any bugs to: https://github.com/RootService/certbot-wrapper

MIT License

Copyright (C) 2016-2018 Markus Kohlmeyer <rootservice@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
" >&2
  exit 1
}

show_version () {
  /bin/echo "$(basename ${0}) ${VERSION}" >&2
  exit 1
}

#############################
###### Local functions ######
#############################

create_keys () {
  local DOMAIN="${1}"
  /usr/local/bin/openssl rand -hex 16 | \
    /usr/local/bin/openssl passwd -1 -stdin | \
    /usr/bin/tr -cd "[[:alnum:]]" \
    > ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.pwd
  /usr/local/bin/openssl ecparam \
    -genkey -name secp384r1 -param_enc named_curve \
    -out ${DIRSSL}/${DOMAIN}/_params.00.ecc.pem
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_params.00.ecc.pem
  /usr/local/bin/openssl genpkey \
    -aes-256-cbc \
    -paramfile ${DIRSSL}/${DOMAIN}/_params.00.ecc.pem \
    -out ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key.enc \
    -pass file:${DIRSSL}/${DOMAIN}/_privkey.00.ecc.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key.enc
  /usr/local/bin/openssl pkey \
    -in ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key.enc \
    -out ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.00.ecc.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key
  /usr/local/bin/openssl rand -hex 16 | \
    /usr/local/bin/openssl passwd -1 -stdin | \
    /usr/bin/tr -cd "[[:alnum:]]" \
    > ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.pwd
  /usr/local/bin/openssl genpkey \
    -aes-256-cbc -algorithm RSA \
    -pkeyopt 'rsa_keygen_bits:2048' \
    -out ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key.enc \
    -pass file:${DIRSSL}/${DOMAIN}/_privkey.00.rsa.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key.enc
  /usr/local/bin/openssl pkey \
    -in ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key.enc \
    -out ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.00.rsa.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key
  /usr/local/bin/openssl rand -hex 16 | \
    /usr/local/bin/openssl passwd -1 -stdin | \
    /usr/bin/tr -cd "[[:alnum:]]" \
    > ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.pwd
  /usr/local/bin/openssl ecparam \
    -genkey -name secp384r1 -param_enc named_curve \
    -out ${DIRSSL}/${DOMAIN}/_params.01.ecc.pem
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_params.01.ecc.pem
  /usr/local/bin/openssl genpkey \
    -aes-256-cbc \
    -paramfile ${DIRSSL}/${DOMAIN}/_params.01.ecc.pem \
    -out ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.key.enc \
    -pass file:${DIRSSL}/${DOMAIN}/_privkey.01.ecc.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.key.enc
  /usr/local/bin/openssl pkey \
    -in ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.key.enc \
    -out ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.key \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.01.ecc.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.key
  /usr/local/bin/openssl rand -hex 16 | \
    /usr/local/bin/openssl passwd -1 -stdin | \
    /usr/bin/tr -cd "[[:alnum:]]" \
    > ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.pwd
  /usr/local/bin/openssl genpkey \
    -aes-256-cbc -algorithm RSA \
    -pkeyopt 'rsa_keygen_bits:2048' \
    -out ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.key.enc \
    -pass file:${DIRSSL}/${DOMAIN}/_privkey.01.rsa.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.key.enc
  /usr/local/bin/openssl pkey \
    -in ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.key.enc \
    -out ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.key \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.01.rsa.pwd
  /bin/chmod 0400 ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.key
  return
}

create_requests () {
  local DOMAIN="${1}"
  local SUBDOMAIN="${2}"
  local EMAIL="${3}"
  if [ "${SUBDOMAIN}" == "www" ]
  then
    /bin/cat > ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf << EOF
[ req ]
utf8                    = yes
prompt                  = no
digests                 = sha384
default_md              = sha384
default_bits            = 2048
encrypt_key             = yes
string_mask             = utf8only
distinguished_name      = req_distinguished_name
req_extensions          = v3_req
SET-ex3                 = SET extension number 3

[ req_distinguished_name ]
C                       = DE
ST                      = Hamburg
L                       = Hamburg
O                       = Organization
OU                      = Certification Authority
CN                      = __SUBDOMAIN__.__DOMAIN__
emailAddress            = __EMAIL__

[ v3_req ]
basicConstraints        = CA:FALSE
keyUsage                = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage        = serverAuth, clientAuth
subjectKeyIdentifier    = hash
subjectAltName          = @altNames
# 1.3.6.1.5.5.7.1.24      = DER:30:03:02:01:05

[ altNames ]
DNS.1                   = __DOMAIN__
EOF
  else
    /bin/cat > ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf << EOF
[ req ]
utf8                    = yes
prompt                  = no
digests                 = sha384
default_md              = sha384
default_bits            = 2048
encrypt_key             = yes
string_mask             = utf8only
distinguished_name      = req_distinguished_name
req_extensions          = v3_req
SET-ex3                 = SET extension number 3

[ req_distinguished_name ]
C                       = DE
ST                      = Hamburg
L                       = Hamburg
O                       = Organization
OU                      = Certification Authority
CN                      = __SUBDOMAIN__.__DOMAIN__
emailAddress            = __EMAIL__

[ v3_req ]
basicConstraints        = CA:FALSE
keyUsage                = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage        = serverAuth, clientAuth
subjectKeyIdentifier    = hash
# 1.3.6.1.5.5.7.1.24      = DER:30:03:02:01:05
EOF
  fi
  /usr/bin/sed \
    -e "s|__SUBDOMAIN__|${SUBDOMAIN}|g" \
    -e "s|__DOMAIN__|${DOMAIN}|g" \
    -e "s|__EMAIL__|${EMAIL}|g" \
    -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf
  /usr/local/bin/openssl req \
    -new -batch -sha384 \
    -config ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf \
    -out ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/request.00.ecc.csr \
    -key ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key.enc \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.00.ecc.pwd
  /usr/local/bin/openssl req \
    -new -batch -sha384 \
    -config ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf \
    -out ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/request.00.rsa.csr \
    -key ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key.enc \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.00.rsa.pwd
  /usr/local/bin/openssl req \
    -new -batch -sha384 \
    -config ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf \
    -out ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/request.00.ecc.csr \
    -key ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key.enc \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.00.ecc.pwd
  /usr/local/bin/openssl req \
    -new -batch -sha384 \
    -config ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/openssl.conf \
    -out ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/request.00.rsa.csr \
    -key ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key.enc \
    -passin file:${DIRSSL}/${DOMAIN}/_privkey.00.rsa.pwd
  return
}

create_acme_account () {
  local EMAIL="${1}"
  if [ "${STAGING}" -eq "1" ]
    local ACMESERV="acme-staging.api.letsencrypt.org"
    local STAGINGPARM="--staging"
  elif [ "${STAGING}" -eq "0" ]
    local STAGINGPARM=""
    if [ "${ACMEPROT}" -eq "1" ]
      local ACMESERV="acme-v01.api.letsencrypt.org"
    elif [ "${ACMEPROT}" -eq "2" ]
      local ACMESERV="acme-v02.api.letsencrypt.org"
    else
      cecho "ACMEPROT ${ACMEPROT} not supportet" boldred
    fi
  else
    cecho "STAGING ${STAGING} not supportet" boldred
  fi
  if [ ! -d "${DIRSSL}/acme/accounts/${ACMESERV}" ]
  then
    /usr/local/bin/certbot register ${STAGINGPARM} \
      --text --quiet --agree-tos --non-interactive \
      --user-agent-comment "RootService-Wrapper/${VERSION}" \
      --preferred-challenges tls-sni,http --config-dir ${DIRSSL}/acme \
      --no-eff-email --email ${EMAIL}
  fi
  return
}

create_acme_certificates () {
  local DOMAIN="${1}"
  local SUBDOMAIN="${2}"
  local EMAIL="${3}"
  if [ "${STAGING}" -eq "1" ]
    local STAGINGPARM="--staging"
  elif [ "${STAGING}" -eq "0" ]
    local STAGINGPARM=""
  else
    cecho "STAGING ${STAGING} not supportet" boldred
  fi
  if [ "${SUBDOMAIN}" == "www" ]
  then
    local BAREDOMAIN="--domain ${DOMAIN}"
  else
    local BAREDOMAIN=""
  fi
  /usr/local/bin/certbot certonly ${STAGINGPARM} \
    --text --quiet --agree-tos --non-interactive \
    --user-agent-comment "RootService-Wrapper/${VERSION}" \
    --preferred-challenges tls-sni,http --config-dir ${DIRSSL}/acme \
    --csr ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/request.00.ecc.csr \
    --key-path ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key.enc \
    --cert-path ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/cert.00.ecc.crt \
    --chain-path ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/chain.00.ecc.crt \
    --fullchain-path ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.ecc.crt \
    --email ${EMAIL} --webroot --webroot-path ${DIRWWW}/acme \
    --domain ${SUBDOMAIN}.${DOMAIN} ${BAREDOMAIN}
  /usr/local/bin/certbot certonly ${STAGINGPARM} \
    --text --quiet --agree-tos --non-interactive \
    --user-agent-comment "RootService-Wrapper/${VERSION}" \
    --preferred-challenges tls-sni,http --config-dir ${DIRSSL}/acme \
    --csr ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/request.00.rsa.csr \
    --key-path ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key.enc \
    --cert-path ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/cert.00.rsa.crt \
    --chain-path ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/chain.00.rsa.crt \
    --fullchain-path ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.rsa.crt \
    --email ${EMAIL} --webroot --webroot-path ${DIRWWW}/acme \
    --domain ${SUBDOMAIN}.${DOMAIN} ${BAREDOMAIN}
  return
}

create_apache24_conf () {
  local DOMAIN="${1}"
  local SUBDOMAIN="${2}"
  /bin/cat > ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf << EOF
    SSLCertificateFile "__CERT00ECC__"
    SSLCertificateKeyFile "__KEY00ECC__"
    SSLCertificateFile "__CERT00RSA__"
    SSLCertificateKeyFile "__KEY00RSA__"
#    Header set Strict-Transport-Security "max-age=15768000; includeSubdomains; preload"
#    Header set Public-Key-Pins "max-age=2592000; includeSubDomains; pin-sha256=\"__PIN00ECC__\"; pin-sha256=\"__PIN00RSA__\"; pin-sha256=\"__PIN01ECC__\"; pin-sha256=\"__PIN01RSA__\";"
EOF
  /usr/bin/sed \
    -e "s|__CERT00ECC__|${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.ecc.crt|" \
    -e "s|__KEY00ECC__|${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key|" \
    -e "s|__CERT00RSA__|${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.rsa.crt|" \
    -e "s|__KEY00RSA__|${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key|" \
    -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  /usr/local/bin/openssl pkey \
    -pubout -outform der \
    -in ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key | \
    /usr/local/bin/openssl dgst -sha256 -binary | \
    /usr/local/bin/openssl enc -base64 | \
    /usr/bin/xargs -I % /usr/bin/sed \
    -e "s|__PIN00ECC__|%|" \
    -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  /usr/local/bin/openssl pkey \
    -pubout -outform der \
    -in ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key | \
    /usr/local/bin/openssl dgst -sha256 -binary | \
    /usr/local/bin/openssl enc -base64 | \
    /usr/bin/xargs -I % /usr/bin/sed \
    -e "s|__PIN00RSA__|%|" \
    -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  /usr/local/bin/openssl pkey \
    -pubout -outform der \
    -in ${DIRSSL}/${DOMAIN}/_privkey.01.ecc.key | \
    /usr/local/bin/openssl dgst -sha256 -binary | \
    /usr/local/bin/openssl enc -base64 | \
    /usr/bin/xargs -I % /usr/bin/sed \
    -e "s|__PIN01ECC__|%|" \
    -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  /usr/local/bin/openssl pkey \
    -pubout -outform der \
    -in ${DIRSSL}/${DOMAIN}/_privkey.01.rsa.key | \
    /usr/local/bin/openssl dgst -sha256 -binary | \
    /usr/local/bin/openssl enc -base64 | \
    /usr/bin/xargs -I % /usr/bin/sed \
    -e "s|__PIN01RSA__|%|" \
    -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  if [ "${HSTS}" = 1 ]
  then
    /usr/bin/sed \
      -e "s|^#\(.*Strict-Transport-Security.*\)|\1|" \
      -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  fi
  HSTS=0
  if [ "${HPKP}" = 1 ]
  then
    /usr/bin/sed \
      -e "s|^#\(.*Public-Key-Pins.*\)|\1|" \
      -i "" ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf
  fi
  HPKP=0
  VHOST_CONF="`/usr/local/sbin/httpd -t -D DUMP_VHOSTS | \
               /usr/bin/awk \
                 -v h="${SUBDOMAIN}.${DOMAIN}" \
                 '/port 443/{if($4==h){print $NF}}; \
                 /^[^:]*:443/{if($2==h){print $NF}}' | \
               /usr/bin/sed -e "s|(\(.*\))|\1|" | \
               /usr/bin/cut -d : -f 1`"
  VHOST_NUM="`/usr/local/sbin/httpd -t -D DUMP_VHOSTS | \
              /usr/bin/awk \
                -v f="${VHOST_CONF}" \
                -v h="${SUBDOMAIN}.${DOMAIN}" \
                '/port 443/{if($NF~f){c+=1}{if($4==h){print c}}}; \
                /^[^:]*:443/{if($NF~f){c+=1}{if($2==h){print c}}}'`"
  /usr/bin/awk \
    -v n="${VHOST_NUM}" \
    'NR==FNR{i=i?i ORS $0:$0; next} \
    /^<VirtualHost[^>]*>/&&++c==n{p=1}p&& \
    /^<\/VirtualHost>/{print i; p=0}!p|| \
    !/SSLCertificate|Strict-Transport-Security|Public-Key-Pins/' \
    ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/apache24.conf \
    ${VHOST_CONF} > ${VHOST_CONF}.tmp
  /bin/mv -f ${VHOST_CONF}.tmp ${VHOST_CONF}
  return
}

create_dovecot_conf () {
  local DOMAIN="${1}"
  local SUBDOMAIN="${2}"
  DOVECOT_CONF="`/usr/local/sbin/dovecot -a | /usr/bin/awk 'NR==1{print $NF}'`"
  /usr/bin/sed \
    -e "s|^\(ssl_eccert\).*$|\1 = <${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.ecc.crt|" \
    -e "s|^\(ssl_eckey\).*$|\1 = <${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key|" \
    -e "s|^\(ssl_cert\).*$|\1 = <${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.rsa.crt|" \
    -e "s|^\(ssl_key\).*$|\1 = <${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key|" \
    -i "" ${DOVECOT_CONF}
  return
}

create_postfix_conf () {
  local DOMAIN="${1}"
  local SUBDOMAIN="${2}"
  POSTFIX_CONF="`/usr/local/sbin/postconf -p config_directory | /usr/bin/awk '{print $NF}'`/main.cf"
  /usr/bin/sed \
    -e "s|^\(smtpd_tls_eccert_file\).*$|\1 = ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.ecc.crt|" \
    -e "s|^\(smtpd_tls_eckey_file\).*$|\1 = ${DIRSSL}/${DOMAIN}/_privkey.00.ecc.key|" \
    -e "s|^\(smtpd_tls_cert_file\).*$|\1 = ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/fullchain.00.rsa.crt|" \
    -e "s|^\(smtpd_tls_key_file\).*$|\1 = ${DIRSSL}/${DOMAIN}/_privkey.00.rsa.key|" \
    -i "" ${POSTFIX_CONF}
  return
}

service_reload () {
  local SERVICE="${1}"
  /usr/sbin/service ${SERVICE} reload
  return
}

setup_domain () {
  local DOMAIN="${1}"
  local EMAIL="${2}"
  if [ ! -d "${DIRSSL}/${DOMAIN}" ]
  then
    /bin/mkdir -p ${DIRSSL}/${DOMAIN}
  else
    /bin/mkdir -p ${DIRSSL}/archives/${CUR_DATE_F}-${CUR_DATE_S}
    /bin/mv -f ${DIRSSL}/${DOMAIN} ${DIRSSL}/archives/${CUR_DATE_F}-${CUR_DATE_S}/${DOMAIN}
    /bin/mkdir -p ${DIRSSL}/${DOMAIN}
  fi
  cd ${DIRSSL}/${DOMAIN}
  create_keys ${DOMAIN}
  create_acme_account ${EMAIL}
  return
}

setup_subdomain () {
  local DOMAIN="${1}"
  local SUBDOMAIN="${2}"
  local EMAIL="${3}"
  if [ ! -d "${DIRSSL}/${DOMAIN}/${SUBDOMAIN}" ]
  then
    /bin/mkdir -p ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}
  else
    /bin/mkdir -p ${DIRSSL}/archives/${CUR_DATE_F}-${CUR_DATE_S}/${DOMAIN}
    /bin/mv -f ${DIRSSL}/${DOMAIN}/${SUBDOMAIN} ${DIRSSL}/archives/${CUR_DATE_F}-${CUR_DATE_S}/${DOMAIN}/${SUBDOMAIN}
    /bin/mkdir -p ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}
  fi
  cd ${DIRSSL}/${DOMAIN}
  create_requests ${DOMAIN} ${SUBDOMAIN} ${EMAIL}
  create_acme_certificates ${DOMAIN} ${SUBDOMAIN} ${EMAIL}
  return
}

##########################
###### Main section ######
##########################

if [ "`/usr/bin/whoami`" != "root" ]
then
  cecho "You must be root to run this script!" boldred
fi
if [ -z "${1}" ]
then
  show_usage
fi
until [ -z "${1}" ]
do
  case "${1}" in
    --create) CREATE=1;;
    --renew) RENEW=1;;
    --cron) CRON=1;;
    --version) show_version;;
    --help) show_usage;;
    *) show_usage;;
  esac
  shift
done
if [ ! -d "${DIRSSL}/configs" ]
then
  /bin/mkdir -p ${DIRSSL}/configs
fi
if [ ! -d "${DIRWWW}/acme/.well-known" ]
then
  /bin/mkdir -p ${DIRWWW}/acme/.well-known
fi
if [ "${CREATE}" = 1 ]
then
  NEXT_DOMAIN=1
  until [ "${NEXT_DOMAIN}" = 0 ]
  do
    if [ -z "${DOMAIN}" ]
    then
      read_prompt "Enter Domain:"
      DOMAIN="`tolower "${REPLY}"`"
    fi
    if [ -z "${EMAIL}" ]
    then
      read_prompt "Enter Mailadress:"
      EMAIL="`tolower "${REPLY}"`"
    fi
    /usr/bin/grep -q "^${DOMAIN}" ${DIRSSL}/configs/domains.txt >/dev/null 2>&1
    if [ "${?}" != 0 ]
    then
      /bin/echo "${DOMAIN} ${EMAIL}" >> ${DIRSSL}/configs/domains.txt
      setup_domain ${DOMAIN} ${EMAIL}
    fi
    NEXT_SUBDOMAIN=1
    until [ "${NEXT_SUBDOMAIN}" = 0 ]
    do
      if [ -z "${SUBDOMAIN}" ]
      then
        read_prompt "Enter Subdomain:"
        SUBDOMAIN="`tolower "${REPLY}"`"
      fi
      /usr/bin/grep -q "^${SUBDOMAIN}" ${DIRSSL}/configs/${DOMAIN}.txt >/dev/null 2>&1
      if [ "${?}" != 0 ]
      then
        /bin/echo "${SUBDOMAIN}" >> ${DIRSSL}/configs/${DOMAIN}.txt
        setup_subdomain ${DOMAIN} ${SUBDOMAIN} ${EMAIL}
      fi
      read_prompt "Automatically reconfigure apache24 for this subdomain? [y/n]"
      if [ "x${REPLY}" = "xy" ]
      then
        read_prompt "Activate HSTS for this subdomain? [y/n]"
        if [ "x${REPLY}" = "xy" ]
        then
          HSTS=1
        fi
        read_prompt "Activate HPKP for this subdomain? [y/n]"
        if [ "x${REPLY}" = "xy" ]
        then
          HPKP=1
        fi
        create_apache24_conf ${DOMAIN} ${SUBDOMAIN}
        service_reload apache24
      fi
      read_prompt "Automatically reconfigure postfix for this subdomain? [y/n]"
      if [ "x${REPLY}" = "xy" ]
      then
        create_postfix_conf ${DOMAIN} ${SUBDOMAIN}
        service_reload postfix
      fi
      read_prompt "Automatically reconfigure dovecot for this subdomain? [y/n]"
      if [ "x${REPLY}" = "xy" ]
      then
        create_dovecot_conf ${DOMAIN} ${SUBDOMAIN}
        service_reload dovecot
      fi
      read_prompt "Another Subdomain? [y/n]"
      if [ "x${REPLY}" = "xy" ]
      then
        NEXT_SUBDOMAIN=1
      else
        NEXT_SUBDOMAIN=0
      fi
      SUBDOMAIN=
    done
    read_prompt "Another Domain? [y/n]"
    if [ "x${REPLY}" = "xy" ]
    then
      NEXT_DOMAIN=1
    else
      NEXT_DOMAIN=0
    fi
    DOMAIN=
    EMAIL=
  done
elif [ "${RENEW}" = 1 ]
then
  cecho "This will renew all installed certificates," white
  cecho "if they are valid for less than 10 days." white
  read_prompt "Are you sure? [y/n]"
  if [ "x${REPLY}" = "xy" ]
  then
    cat ${DIRSSL}/configs/domains.txt | \
    while read DOMAIN EMAIL OFFSET
    do
      OFFSET=
      cat ${DIRSSL}/configs/${DOMAIN}.txt | \
      while read SUBDOMAIN OFFSET
      do
        OFFSET=
        cecho "Backups of your current certificates will be saved in" white
        cecho "${DIRSSL}/archives/${CUR_DATE_F}-${CUR_DATE_S}/${DOMAIN}/${SUBDOMAIN}" white
        CERT_DATE_ORIG="`/usr/local/bin/openssl x509 \
                       -inform pem -enddate -noout \
                       -in ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/cert.00.rsa.crt | \
                       /usr/bin/cut -d = -f 2-`"
        CERT_DATE_RENEW_S="`/bin/date -j -u -v-10d -f "%b %d %T %Y %Z" "${CERT_DATE_ORIG}" "+%s"`"
        if [ "${CUR_DATE_S}" -gt "${CERT_DATE_RENEW_S}" ]
        then
          setup_subdomain ${DOMAIN} ${SUBDOMAIN} ${EMAIL}
        fi
        SUBDOMAIN=
      done
      DOMAIN=
      EMAIL=
    done
  fi
  service_reload apache24
  service_reload dovecot
  service_reload postfix
elif [ "${CRON}" = 1 ]
then
  cat ${DIRSSL}/configs/domains.txt | \
  while read DOMAIN EMAIL OFFSET
  do
    OFFSET=
    cat ${DIRSSL}/configs/${DOMAIN}.txt | \
    while read SUBDOMAIN OFFSET
    do
      OFFSET=
      CERT_DATE_ORIG="`/usr/local/bin/openssl x509 \
                     -inform pem -enddate -noout \
                     -in ${DIRSSL}/${DOMAIN}/${SUBDOMAIN}/cert.00.rsa.crt | \
                     /usr/bin/cut -d = -f 2-`"
      CERT_DATE_RENEW_S="`/bin/date -j -u -v-10d -f "%b %d %T %Y %Z" "${CERT_DATE_ORIG}" "+%s"`"
      if [ "${CUR_DATE_S}" -gt "${CERT_DATE_RENEW_S}" ]
      then
        setup_subdomain ${DOMAIN} ${SUBDOMAIN} ${EMAIL}
      fi
      SUBDOMAIN=
    done
    DOMAIN=
    EMAIL=
  done
  service_reload apache24
  service_reload dovecot
  service_reload postfix
fi

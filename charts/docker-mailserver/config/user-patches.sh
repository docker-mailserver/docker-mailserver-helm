#!/bin/bash

{{- if .Values.proxy_protocol.enabled }}
# Make sure to keep this file in sync with https://github.com/docker-mailserver/docker-mailserver/blob/master/target/postfix/master.cf!
cat <<EOS >> /etc/postfix/master.cf

# Submission with proxy
10587     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_sasl_authenticated_header=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=\$mua_sender_restrictions
  -o smtpd_discard_ehlo_keywords=
  -o milter_macro_daemon_name=ORIGINATING
  -o cleanup_service_name=sender-cleanup
  -o smtpd_upstream_proxy_protocol=haproxy  

# Submissions with proxy
10465     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/submissions
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_sasl_type=dovecot
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_sasl_authenticated_header=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o smtpd_sender_restrictions=\$mua_sender_restrictions
  -o smtpd_discard_ehlo_keywords=
  -o milter_macro_daemon_name=ORIGINATING
  -o cleanup_service_name=sender-cleanup
  -o smtpd_upstream_proxy_protocol=haproxy
EOS
{{- end }}
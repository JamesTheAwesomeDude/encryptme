#!/bin/bash
# USAGE: ./register.sh ../../tls/example.com.pem example.com [www.example.com] [blog.example.com] [...]
file="${1%.pem}"
tld="${2}"
shift 2
SAN=("${@}")
openssl req -new\
 -outform pem\
 -out "${file}.csr"\
 -newkey ec\
  -pkeyopt ec_paramgen_curve:secp384r1\
  -nodes\
  -keyout "${file}.key"\
 -subj /CN="${tld}"\
 -reqexts SAN\
 -config <(
  (
   printf "[SAN]\nsubjectAltName=";(IFS=","; printf '%s\n' "${SAN[*]/#/DNS:}")
  )| cat /etc/ssl/openssl.cnf -
 )\
 -keyform pem &&\
openssl req -in "${file}.csr" -text -noout &&\
python acme-tiny/acme_tiny.py\
 --account-key /etc/ssh/ssh_host_rsa_key\
 --acme-dir "/var/www/${tld}/.well-known/acme-challenge/"\
 --csr "${file}.csr"\
 > "${file}.crt" &&\
openssl x509 -in "${file}.crt" -text -noout &&\
cat "${file}.key" "${file}.crt" > "${file}.pem"

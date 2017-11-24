#!/bin/bash
SAN=("${@}")
SAN=( "${SAN[@]/#/DNS:}" )
openssl req -new\
 -outform pem\
 -out "${1}.csr"\
 -newkey ec\
  -pkeyopt ec_paramgen_curve:secp384r1\
  -nodes\
  -keyout "${1}.key"\
 -subj /CN="${1}"\
 -reqexts SAN\
 -config <(
  (
   printf "[SAN]\nsubjectAltName=";(IFS=","; printf '%s\n' "${SAN[*]}")
  )| cat /etc/ssl/openssl.cnf -
 )\
 -keyform pem &&\
openssl req -in "${1}.csr" -text -noout &&\
python acme_tiny.py\
 --account-key /etc/ssh/ssh_host_rsa_key\
 --acme-dir "/var/www/${1}/.well-known/acme-challenge/"\
 --csr "${1}.csr"\
 > "${1}.crt" &&\
openssl x509 -in "${1}.crt" -text -noout &&\
cat "${1}.key" "${1}.crt" > "${1}.pem"
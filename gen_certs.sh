#!/bin/bash -e

if [[ $1 = "cleanup" ]]; then
  rm -rf dist
  exit 0
fi

if [[ $1 = "" ]]; then
  echo "please specify a domain: ./gen_certs.sh <domain> <password>"
  exit 1
fi

if [[ $2 = "" ]]; then
  echo "please specify a password for the private key: ./gen_certs.sh <domain> <password>"
  exit 1
fi

echo 
echo Generate the root key
echo ---
mkdir -p dist/1_root/private
openssl genrsa -aes256 -passout pass:$2 -out dist/1_root/private/ca.key.pem 4096
chmod 444 dist/1_root/private/ca.key.pem

echo 
echo Generate the root certificate
echo ---
mkdir -p dist/1_root/certs
mkdir -p dist/1_root/newcerts
touch dist/1_root/index.txt
echo "100212" > dist/1_root/serial
openssl req -config openssl/openssl.cnf \
      -key dist/1_root/private/ca.key.pem \
      -passin pass:$2 \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$1" \
      -out dist/1_root/certs/ca.cert.pem

echo 
echo Verify root key
echo ---
openssl x509 -noout -text -in dist/1_root/certs/ca.cert.pem

echo 
echo Generate the key for the intermediary certificate
echo ---
mkdir -p dist/2_intermediate/private
openssl genrsa -aes256 \
  -passout pass:$2 \
  -out dist/2_intermediate/private/intermediate.key.pem 4096
chmod 444 dist/2_intermediate/private/intermediate.key.pem

echo 
echo Generate the signing request for the intermediary certificate
echo ---
mkdir -p dist/2_intermediate/csr
openssl req -config openssl/openssl.cnf -new -sha256 \
      -passin pass:$2 \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$1" \
      -key dist/2_intermediate/private/intermediate.key.pem \
      -out dist/2_intermediate/csr/intermediate.csr.pem

echo 
echo Sign the intermediary
echo ---
mkdir -p dist/2_intermediate/certs
mkdir -p dist/2_intermediate/newcerts
touch dist/2_intermediate/index.txt
echo "100212" > dist/2_intermediate/serial
openssl ca -config openssl/openssl.cnf -extensions v3_intermediate_ca \
        -passin pass:$2 \
        -days 3650 -notext -md sha256 \
        -in dist/2_intermediate/csr/intermediate.csr.pem \
        -out dist/2_intermediate/certs/intermediate.cert.pem
chmod 444 dist/2_intermediate/certs/intermediate.cert.pem

echo 
echo Verify intermediary
echo ---
openssl x509 -noout -text \
      -in dist/2_intermediate/certs/intermediate.cert.pem
openssl verify -CAfile dist/1_root/certs/ca.cert.pem \
      dist/2_intermediate/certs/intermediate.cert.pem

echo 
echo Create the chain file
echo ---
cat dist/2_intermediate/certs/intermediate.cert.pem \
      dist/1_root/certs/ca.cert.pem > dist/2_intermediate/certs/ca-chain.cert.pem
chmod 444 dist/2_intermediate/certs/ca-chain.cert.pem

echo 
echo Create the application key
echo ---
mkdir -p dist/3_application/private
openssl genrsa \
      -passout pass:$2 \
    -out dist/3_application/private/$1.key.pem 2048
chmod 444 dist/3_application/private/$1.key.pem

echo 
echo Create the application signing request
echo ---
mkdir -p dist/3_application/csr
openssl req -config openssl/intermediate_openssl.cnf \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$1" \
      -passin pass:$2 \
      -key dist/3_application/private/$1.key.pem \
      -new -sha256 -out dist/3_application/csr/$1.csr.pem

echo 
echo Create the application certificate
echo ---
mkdir -p dist/3_application/certs
openssl ca -config openssl/intermediate_openssl.cnf \
      -passin pass:$2 \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in dist/3_application/csr/$1.csr.pem \
      -out dist/3_application/certs/$1.cert.pem
chmod 444 dist/3_application/certs/$1.cert.pem

echo 
echo Validate the certificate
echo ---
openssl x509 -noout -text \
      -in dist/3_application/certs/$1.cert.pem

echo 
echo Validate the certificate has the correct chain of trust
echo ---
openssl verify -CAfile dist/2_intermediate/certs/ca-chain.cert.pem \
      dist/3_application/certs/$1.cert.pem

echo
echo Generate the client key
echo ---
mkdir -p dist/4_client/private
openssl genrsa \
    -passout pass:$2 \
    -out dist/4_client/private/$1.key.pem 2048
chmod 444 dist/4_client/private/$1.key.pem

echo
echo Generate the client signing request
echo ---
mkdir -p dist/4_client/csr
openssl req -config openssl/intermediate_openssl.cnf \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$1" \
      -passin pass:$2 \
      -key dist/4_client/private/$1.key.pem \
      -new -sha256 -out dist/4_client/csr/$1.csr.pem

echo 
echo Create the client certificate
echo ---
mkdir -p dist/4_client/certs
openssl ca -config openssl/intermediate_openssl.cnf \
      -passin pass:$2 \
      -extensions usr_cert -days 375 -notext -md sha256 \
      -in dist/4_client/csr/$1.csr.pem \
      -out dist/4_client/certs/$1.cert.pem
chmod 444 dist/4_client/certs/$1.cert.pem

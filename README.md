<p align="center">
  <img src="https://raw.githubusercontent.com/ajgrande924/go-tls/main/assets/logo_readme.png" alt="Logo" width="100" height="100" />
</p>
<h2 align="center">ajgrande924/go-tls</h2>
<p align="center">
  <a href="https://goreportcard.com/report/github.com/ajgrande924/go-tls"><img alt="Go Report Card" src="https://goreportcard.com/badge/github.com/ajgrande924/go-tls" height="20"/></a>
  <a href="https://github.com/ajgrande924/go-tls/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/ajgrande924/go-tls.svg" height="20"/></a>
  <a href="https://github.com/ajgrande924/go-tls/graphs/commit-activity"><img alt="Maintained" src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" height="20"/></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="Maintained" src="http://img.shields.io/:license-MIT-yellow.svg" height="20"/></a>
</p>

## Overview

Simple example to demonstrate how to use Mutual Authentication with Golang HTTP servers.

## Getting Started

**Generating certificates**

Generating the necessary certificates for this example can be performed by running the `./gen_certs_.sh` command and providing the domain name to create the cert for and the password for the keys.
```bash
./gen_certs.sh localhost password
```

A certificate is only valid if the domain matches the hosted domain of the server, for example a certificate issue to the domain `www.example.com` would raise an exception if you attempted to run `curl https://localhost`.

The script generates a root certificate and key, an intermediary, application certificate and a client certificate. Both the application and client certificate are generated from the intermediary this would allow the client to authenticate any server which uses the intermediary chain. It is possible to lock a client certificate down to a particular application by signing it with the applications certificate rather than the intermediary.

**Running the server using a self signed certificate**

Start the server: 
```bash
$ go run main.go -domain localhost
```

When calling the endpoint it is requred to add the ca-chain cert to the curl command as this is a self signed certificate.
```bash
$ curl -v --cacert dist/2_intermediate/certs/ca-chain.cert.pem https://localhost:8443/

#...
Hello World% 
```

**Running the server with mutual TLS authentication and a self signed certifcate**

Start the server:
```bash
$ go run main.go -domain localhost -mtls true
```

Call the endpoint providing the certificates generated for the client, for the server to validate the request the user must provide its 
certifcate and private key.
```bash
$ curl -v --cacert dist/2_intermediate/certs/ca-chain.cert.pem --cert dist/4_client/certs/localhost.cert.pem --key dist/4_client/private/localhost.key.pem https://localhost:8443/

#...
Hello World% 
```

Calling the endpoint without providing the certificates:
```bash
$ curl -v --cacert dist/2_intermediate/certs/ca-chain.cert.pem https://localhost:8443/

#...
curl: (35) error:14094412:SSL routines:SSL3_READ_BYTES:sslv3 alert bad certificate
```

## License

`ajgrande924/go-tls` is under MIT license. See the [LICENSE](LICENSE) file for details.

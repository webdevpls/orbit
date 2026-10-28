#!/usr/bin/env bash
# Creates a self-signed "Orbit Local Signing" certificate in the login keychain.
# Signing every build with the same identity lets macOS remember the Accessibility permission
# across rebuilds (ad-hoc signatures change on every build, so macOS asks again).
# Remove it any time in Keychain Access → login → My Certificates.
set -euo pipefail
NAME="Orbit Local Signing"

if security find-certificate -c "$NAME" >/dev/null 2>&1; then
  echo "\"$NAME\" already exists."
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/cert.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
CNF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$TMP/cert.cnf" \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" 2>/dev/null
# The keychain only reads the legacy PKCS#12 format; OpenSSL 3 needs -legacy for it.
LEGACY=""
openssl version | grep -q "^OpenSSL 3" && LEGACY="-legacy"
openssl pkcs12 -export $LEGACY -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -name "$NAME" \
  -out "$TMP/orbit.p12" -passout pass:orbit 2>/dev/null
security import "$TMP/orbit.p12" -k "$HOME/Library/Keychains/login.keychain-db" -P orbit -T /usr/bin/codesign >/dev/null
echo "Created \"$NAME\". Builds will now be signed with it."

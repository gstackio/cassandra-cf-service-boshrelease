#!/usr/bin/env bash

set -e # exit immediately if a simple command exits with a non-zero status.
set -u # report the usage of uninitialized variables.

<%
  require "shellwords"

  def esc(x)
      Shellwords.shellescape(x)
  end
%>
CERTS_DIR=/var/vcap/jobs/cassandra/tls
keystore_password=<%= esc(p("keystore_password")) %>

openssl pkcs12 -export \
    -in "$CERTS_DIR/node.crt" \
    -inkey "$CERTS_DIR/node.key" \
    -name cassandra_node \
    \
    -CAfile "$CERTS_DIR/ca.crt" \
    -caname /internalCA \
    \
    -out "$CERTS_DIR/tmp-keystore.p12" \
    -passout "pass:$keystore_password"

/var/vcap/packages/openjdk/bin/keytool -importkeystore \
    -srckeystore "$CERTS_DIR/tmp-keystore.p12" \
    -srcstoretype PKCS12 \
    -srcstorepass "$keystore_password" \
    -alias cassandra_node \
    \
    -deststorepass "$keystore_password" \
    -destkeypass "$keystore_password" \
    -destkeystore "$CERTS_DIR/cassandra_keystore.jks"

chown vcap:vcap "$CERTS_DIR/cassandra_keystore.jks"
chmod 600 "$CERTS_DIR/cassandra_keystore.jks"

# rm "$CERTS_DIR/tmp-keystore.p12"

/var/vcap/packages/openjdk/bin/keytool -import -v \
    -trustcacerts \
    -alias /internalCA \
    -file "$CERTS_DIR/ca.crt" \
    -keystore "$CERTS_DIR/cassandra_truststore.jks" \
    -storepass "$keystore_password" \
    -keypass "$keystore_password" \
    -noprompt

chown vcap:vcap "$CERTS_DIR/cassandra_truststore.jks"
chmod 600 "$CERTS_DIR/cassandra_truststore.jks"

exit 0

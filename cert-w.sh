# /bin/bash
# set -eu
POD_NAME="${POD_NAME:-e4k}"
CA_CERT_NAME="${CA_CERT_NAME:-e4k-auth-ca}"
BROKER_CERT_NAME="${BROKER_CERT_NAME:-dmqtt-cert}"
CA_SECRET_NAME="${CA_SECRET_NAME:-e4k-custom-ca-cert}"
BROKER_SECRET_NAME="${BROKER_SECRET_NAME:-e4k-8883-cert}"

>extensions.conf cat <<-EOF
[ ca_cert ]
basicConstraints = critical, CA:TRUE
keyUsage = keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
[ dmqtt_cert ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
subjectAltName=@alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = azedge-dmqtt-frontend
DNS.3 = azedge-dmqtt-frontend-aks
EOF

################### CA CERT #######################
openssl ecparam -name prime256v1 -genkey -noout -out "$CA_CERT_NAME-key.pem"
openssl req -new -key "$CA_CERT_NAME-key.pem" -subj "//CN=TestCA" -out "$CA_CERT_NAME-req.pem"
openssl x509 -req -in "$CA_CERT_NAME-req.pem" -signkey "$CA_CERT_NAME-key.pem" -extfile extensions.conf -extensions ca_cert -out "$CA_CERT_NAME.pem" -days 35000
rm "$CA_CERT_NAME-req.pem"

################### DMQTT CERT #######################
openssl ecparam -name prime256v1 -genkey -noout -out "$BROKER_CERT_NAME-key.pem"
openssl req -new -key "$BROKER_CERT_NAME-key.pem" -subj "//CN=localhost" -out "$BROKER_CERT_NAME-req.pem"
openssl x509 -req -in "$BROKER_CERT_NAME-req.pem" -CA "$CA_CERT_NAME.pem" -CAkey "$CA_CERT_NAME-key.pem" -CAcreateserial -extfile extensions.conf -extensions dmqtt_cert -out "$BROKER_CERT_NAME.pem" -days 35000
rm "$BROKER_CERT_NAME-req.pem"
cat "$CA_CERT_NAME.pem" >> "$BROKER_CERT_NAME.pem"
openssl verify -CAfile "$CA_CERT_NAME.pem" "$BROKER_CERT_NAME.pem"

################### Kubectl Secret Create #######################
if kubectl get secret $CA_SECRET_NAME >/dev/null 2>&1; then
  # Delete the secret
  kubectl delete secret "$CA_SECRET_NAME" --ignore-not-found
  echo "Secret was present. '$CA_SECRET_NAME' deleted"
fi
if kubectl get secret $BROKER_SECRET_NAME >/dev/null 2>&1; then
  # Delete the secret
  kubectl delete secret "$BROKER_SECRET_NAME" --ignore-not-found
  echo "Secret was present. '$BROKER_SECRET_NAME' deleted"
fi
if kubectl get configmap client-ca >/dev/null 2>&1; then
  # Delete the secret
  kubectl delete configmap client-ca --ignore-not-found
  echo "Configmap was present. client-ca deleted"
fi
cp $CA_CERT_NAME.pem ca.pem
# kubectl create configmap client-ca --from-file ca.pem=ca.pem
# kubectl create secret tls e4k-custom-ca-cert --cert=e4k-auth-ca.pem --key=e4k-auth-ca-key.pem
# kubectl create secret tls e4k-8883-cert --cert=dmqtt-cert.pem --key=dmqtt-cert-key.pem
# /bin/bash
RELEASENAMESERVER="eosc-servers"
RELEASENAMEUI="eosc-webui"
RELEASENAMEDAEMONS="eosc-daemons"
RELEASENAMENOTEBOOK="eosc-notebook"

SERVERPROXIES="/root/clusters/eosc-cluster/certs_as_secrets/main/"
AUTHPROXIES="/root/clusters/eosc-cluster/certs_as_secrets/auth/"
WEBUIPROXIES="/root/clusters/eosc-cluster/certs_as_secrets/webui/"
NOTEBOOKPROXIES="/root/clusters/eosc-cluster/certs_as_secrets/notebook/"

echo "Creating " ${RELEASENAMESERVER}-server

kubectl create secret generic ${RELEASENAMESERVER}-server-hostcert --from-file=${SERVERPROXIES}/hostcert.pem -n rucio
kubectl create secret generic ${RELEASENAMESERVER}-server-hostkey --from-file=${SERVERPROXIES}/hostkey.pem -n rucio
kubectl apply -f ${SERVERPROXIES}eosc-servers-server-cafile.yaml

echo "Creating " ${RELEASENAMESERVER}-auth

kubectl create secret generic ${RELEASENAMESERVER}-auth-hostcert --from-file=${AUTHPROXIES}/hostcert.pem -n rucio
kubectl create secret generic ${RELEASENAMESERVER}-auth-hostkey --from-file=${AUTHPROXIES}/hostkey.pem -n rucio
kubectl apply -f ${AUTHPROXIES}eosc-servers-auth-cafile.yaml

echo "Creating TLS"

kubectl create secret tls eosc-rucio.tls-secret --key=${SERVERPROXIES}/eosc-rucio-tls.key --cert=${SERVERPROXIES}/eosc-rucio-tls.crt -n rucio

echo "Creating " ${RELEASENAMEUI}

kubectl create secret generic ${RELEASENAMEUI}-hostcert --from-file=${WEBUIPROXIES}hostcert.pem -n rucio
kubectl create secret generic ${RELEASENAMEUI}-hostkey --from-file=${WEBUIPROXIES}hostkey.pem -n rucio
kubectl apply -f ${WEBUIPROXIES}/eosc-webui-cafile.yaml

echo "Creating " ${RELEASENAMEDAEMONS}-rucio-ca-bundle

kubectl create secret generic ${RELEASENAMEDAEMONS}-rucio-ca-bundle --from-file=/etc/pki/tls/certs/CERN-bundle.pem -n rucio

echo "Creating " ${RELEASENAMEDAEMONS}-rucio-ca-bundle-reaper

export CERTDIR=${HOMEPATH}/tmp/reaper-certs/
mkdir ${CERTDIR}
cp /etc/grid-security/certificates/*.0 ${CERTDIR}
cp /etc/grid-security/certificates/*.signing_policy ${CERTDIR}

kubectl create secret generic ${RELEASENAMEDAEMONS}-rucio-ca-bundle-reaper --from-file=${CERTDIR} -n rucio

kubectl create secret generic ${RELEASENAMENOTEBOOK}-hostcert --from-file=${NOTEBOOKPROXIES}/hostcert.pem -n rucio
kubectl create secret generic ${RELEASENAMENOTEBOOK}-hostkey --from-file=${NOTEBOOKPROXIES}/hostkey.pem -n rucio

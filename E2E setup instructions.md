### Prerequisites

1. Install kubectl for windows.
    - https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
<br/><br>
2. Open docker desktop.
    - Go to settings -> Kubernetes tab.
    - Enable Kubernetes (might take a couple minutes)
    - Double check docker kubernetes is being used: ` kubectl config get-contexts`
<br/><br>    
3. Install E4K (If does not work on CMD/Powershell, using VS terminal or download Cmder: https://cmder.app/)
    - Install choco: https://docs.chocolatey.org/en-us/choco/setup
    - Install helm: `choco install kubernetes-helm`
    - `helm install e4k oci://edgebuilds.azurecr.io/helm/az-e4k   --version 0.6.0-dev`
    - `helm install e4k oci://edgebuilds.azurecr.io/helm/az-e4k   --version 0.6.0-dev`
        - <mark>Note:</mark> Incase installing E4K fails, uninstall first using: `helm uninstall e4k && kubectl get crds -o name | grep "az-edge.com" | xargs kubectl delete`
<br/><br>
4. Clone E4K hub-connector repo (https://github.com/Azure/e4k-iothub-connector)
    - `mkdir iothub-connector`
    - `cd iothub-connector`
    - `git init`
    - `git remote add -f origin https://github.com/Azure/e4k-iothub-connector/`
    - `git pull origin main`
<br/><br>
5. Execute 'cert-w.sh' script.(Available in the repo with this instructions file) 
    - `bash cert-w.sh`
    - `kubectl create configmap client-ca --from-file ca.pem=ca.pem`
    - `kubectl create secret tls e4k-custom-ca-cert --cert=e4k-auth-ca.pem  --key=e4k-auth-ca-key.pem`
    - `kubectl create secret tls e4k-8883-cert --cert=dmqtt-cert.pem --key=dmqtt-cert-key.pem`
    - `kubectl create serviceaccount azedge-dmqtt-module-client-sa`\
    The script will create config map `client-ca` and secrets `e4k-8883-cert` and `e4k-custom-ca-cert` in kubernetes. You can view them using commands `kubectl get configmap` and `kubectl get secrets`.
<br/><br>
6. Create an ACR (Azure container registry). 
    - Create token and retreive password and login command.\
    --  Repository Permissions -> Tokens -> Add -> Create
<br/><br>
7. Login to docker using the command retreived above.
<br/><br>
8. Create a kubernetes secret to keep the above info as a secret.
    - `kubectl create secret docker-registry e4kacr --docker-server=<your ACR>.azurecr.io --docker-username=<TOKEN USERNAME> --docker-password=<TOKEN PASSWORD>`
<br/><br>
9. Publish the hub-connector and leaf device as an image.
    - Open CMD/Powershell in e4k-iothub-connector repo.
    - `dotnet publish test/leaf-device/leaf-device.csproj /t:PublishContainer --os linux  --arch x64 /p:ContainerRepository="<your ACR>.azurecr.io" /p:ContainerImageName=<your ACR>.azurecr.io/<IMAGE NAME OF YOUR CHOICE> /p:ContainerImageTags=1.0.0`
    - `dotnet publish src/hub-connector/iothub-connector.csproj /t:PublishContainer --os linux  --arch x64 /p:ContainerRepository="<your ACR>.azurecr.io" /p:ContainerImageName=<your ACR>.azurecr.io/<IMAGE NAME OF YOUR CHOICE> /p:ContainerImageTags=1.0.0`
<br/><br>
10. Push the images (hub-connector & leaf-device).
    - `docker push <your ACR>.azurecr.io/<IMAGE NAME USED FOR hub connector>:1.0.0`
    - `docker push <your ACR>.azurecr.io/<IMAGE NAME USED FOR leaf device>:1.0.0`
<br/><br>
11. Go to deploy folder (within e4k-iothub-connector repo) and update the hub-connector.yaml with hub-connector image create above.
<br/><br>
12. Update leaf-device.yaml and leaf-device-e2e-x509.yaml with leaf-device image created above.
<br/><br>
13. Create an IoT hub, create an edge device (name: e4k-edge-1), create a non-edge leaf device (name: leaf-device-1) on the hub. Set the parent of the leaf device to be the edge device.
<br/><br>
14. Create kubernetes secret for both edge device and the leaf device.
    - `kubectl create secret generic e4k-gateway-secrets --from-literal=edgeDevice="<EDGE DEVICE CONNECTION STRING>;UseTls=true;ClientId=hub-connector;MqttVersion=5;CaFile=/certs/ca.pem" --from-literal=Broker=HostName=azedge-dmqtt-frontend`
    - `kubectl create secret generic leaf-device-secrets --from-literal=cs="<LEAF DEVICE CONNECTION STRING>;MqttGatewayHostName=azedge-dmqtt-frontend;CaFile=/certs/ca.pem"`
<br/><br>
15. Create certificate and secret for x509 device (within e4k-iothub-connector repo):
    - `openssl genrsa 2048 > x509-leaf-device-1-cert-key.pem`
    - `openssl req -new -key x509-leaf-device-1-cert-key.pem -out csr.pem`  
        <mark>-Note:</mark> set the value for __Common Name (e.g. server FQDN or YOUR name)__ as `X509-leaf-device-1`
    - `openssl x509 -req -days 365 -in csr.pem -signkey x509-leaf-device-1-cert-key.pem -out x509-leaf-device-1-cert.pem`
    - `openssl x509 -in X509-leaf-device-1-cert.pem -noout -fingerprint | cut -d "=" -f 2 | sed 's/://g'`
    - Go to portal and create a x509 self-signed device (name: x509-leaf-device-1) and use the value created in last step as primary and secondary thumbprint.
    - Set the parent of this x509 device to be e4k-edge-1.
<br/><br>
16. Create kubernetes secret for x509 device.
    - `kubectl create secret generic leaf-device-x509-secrets --from-file=device-x509-cert.pem=x509-leaf-device-1-cert.pem --from-file=device-x509-key.pem=x509-leaf-device-1-cert-key.pem --from-literal=cs="HostName=<YOUR HUB HOSTNAME>;DeviceId=x509-leaf-device-1;CertFile=/certs/device/secrets/device-x509-cert.pem;KeyFile=/certs/device/secrets/device-x509-key.pem;MqttGatewayHostName=azedge-dmqtt-frontend;CaFile=/certs/ca.pem`
<br/><br>
17. Create a leaf device (non edge device) on the Iot Hub. This leaf device will not have any parent and will be a direct leaf device.
    - `kubectl create secret generic direct-device-secrets --from-literal=cs="<LEAF DEVICE CONNECTION STRING>"`
<br/><br>
18. Deploy everything within /deploy/e4k folder. Also deploy the hub-connector and leaf device separately.
    - `kubectl apply -f deploy/e4k`
    - `kubectl apply -f deploy/hub-connector.yaml`
    - `kubectl apply -f deploy/leaf-device.yaml`
    - `kubectl apply -f deploy/leaf-device-e2e-x509.yaml`
<br/><br>
19. Execute `kubectl get pods` and make sure all pods are ready and in running state. (may take a couple minutes)
    - Troubleshoot any pod: `kubectl logs <POD NAME>`
20. Go to Azure portal and execute a direct method on the leaf device (method name: echo) and confirm that a response is received on portal. Similarly for x509 leaf device.

### Run E2E tests

21. Update test files (e.g: DirectDeviceTest.cs, E4KDeviceTest.cs etc) to use the respective device ids.
    - Execute E2E tests to make sure tests work as expected.

### Prerequisites
1. Install kubectl for windows.
    - https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
<br/><br>   
2. Open docker desktop.
    - Go to settings -> Kubernetes tab.
    - Enable Kubernetes (might take a couple minutes)
    - Double check docker kubernetes is being used: ` kubectl config get-contexts`
<br/><br>  
4. Create a new project in Visual Studio, on the Tools menu, select Options > NuGet Package Manager > Package Sources. Select the green plus in the upper-right corner and enter the name and source URL below:
    - Name: sdklite-previews
    - Soruce: https://pkgs.dev.azure.com/e4k-sdk/SdkLite/_packaging/sdklite-previews/nuget/v3/index.json
<br/><br>  
5. On the Tools menu, select Nuget Package Manager > Package Manager Console.
    - Execute `Install-Package MqttSdkLite -version 0.1.152-dev`
<br/><br>
3. Clone samples from e4k-iothub-connector repo.
    - Create test app directory: `mkdir hub-connector-samples`
    - Switch to test app directory: `cd hub-connector-samples`
    - Setup git: `git init`
    - Add test app repo: `git remote add -f origin https://github.com/Azure/e4k-iothub-connector/`
    - Enable sparse checkout: `git config core.sparseCheckout true`
    - Add leaf-device sample: `echo "test/leaf-device/" >> .git/info/sparse-checkout`
    - Add leaf-module sample: `echo "test/module-sample/" >> .git/info/sparse-checkout`
    - Add hub-connector.yaml: `echo "deploy/iothub-connector.yaml" >> .git/info/sparse-checkout`
    - Add e4k CRDs: `echo "deploy/e4k/" >> .git/info/sparse-checkout`
    - Pull the test app project files: `git pull origin main`
    - Now import these samples in the new VS solution you created and add dependency to MqttSdkLite package in both the samples.
<br/><br> 
6. Install E4K (If does not work on CMD/Powershell download Cmder: https://cmder.app/)
    - Install choco: https://docs.chocolatey.org/en-us/choco/setup
    - Install helm: `choco install kubernetes-helm`
    - `helm install e4k oci://edgebuilds.azurecr.io/helm/az-e4k   --version 0.6.0-dev`
        - <mark>Note:</mark> Incase installing E4K fails, uninstall first using: `helm uninstall e4k && kubectl get crds -o name | grep "az-edge.com" | xargs kubectl delete`
<br/><br>
7. Execute 'cert-w.sh' script (Available in the repo with this instructions file). 
    - `bash cert-w.sh`
    - `kubectl create configmap client-ca --from-file ca.pem=ca.pem`
    - `kubectl create secret tls e4k-custom-ca-cert --cert=e4k-auth-ca.pem  --key=e4k-auth-ca-key.pem`
    - `kubectl create secret tls e4k-8883-cert --cert=dmqtt-cert.pem --key=dmqtt-cert-key.pem`
    - `kubectl create serviceaccount azedge-dmqtt-module-client-sa`\
    The script will create config map `client-ca` and secrets `e4k-8883-cert` and `e4k-custom-ca-cert` in kubernetes. You can view them using commands `kubectl get configmap` and `kubectl get secrets`.
<br/><br>
8. Create an IoT hub, create an edge device (name: e4k-edge-1), create a non-edge leaf device (name: leaf-device-1) on the hub. Set the parent of the leaf device to be the edge device. Create module identity on the leaf device. (name: leaf-module-1)
<br/><br>
9. Create kubernetes secret for both edge device and the leaf device.
    - `kubectl create secret generic e4k-gateway-secrets --from-literal=edgeDevice="<EDGE DEVICE CONNECTION STRING>" --from-literal=Broker=HostName=azedge-dmqtt-frontend;UseTls=true;ClientId=hub-connector;MqttVersion=5;CaFile=/certs/ca.pem`
<br/><br>
10. Get token for EdgeBuilds ACR and create kubernetes secret.
    - Go to Portal and search for EdgeBuilds ACR. (You might need permissions for it. Subscription Id: 5ed2dcb6-29bb-40de-a855-8c24a8260343)
    - Create token and retreive password and login command.
        - Repository Permissions -> Tokens -> Add -> Create
        - Login to docker using the command retreived above.
        - Create a kubernetes secret to keep the above info as a secret.
        - `kubectl create secret docker-registry e4kacr --docker-server=edgebuilds.azurecr.io --docker-username=<TOKEN NAME> --docker-password=<TOKEN PASSWORD>`
<br/><br>        
11. Deploy the e4k CRDs and hub-connector as a kubernetes pod.
    - Open deploy/hub-connector.yaml in text editor and update value for 'image' as `edgebuilds.azurecr.io/hub-connector-v1:1.0.0`
    - `kubectl apply -f deploy/e4k/`
    - `kubectl apply -f deploy/hub-connector.yaml`
<br/><br>
12. Execute `kubectl get pods` and make sure all pods are ready and in running state. (may take a couple minutes)
    - Troubleshoot any pod: `kubectl logs <POD NAME>`
<br/><br>
13. Run leaf-device project.
    - Update the connection string in Device.cs to be as following:
        - `"<LEAF DEVICE CONNECTION STRING>;MqttGatewayHostName=localhost;UseTls=true;TcpPort=8883;CaFile=ca.pem"`
    - Run the leaf-device project and make sure device successfully sends telemetry messages and it received the Twin information.
14. Run the module-sample project.
    -  Update the connection string in Module.cs to be as following:
        - `"<LEAF MODULE CONNECTION STRING>;MqttGatewayHostName=localhost;UseTls=true;TcpPort=8883;CaFile=ca.pem"`
    - Run the module sample project and make sure module successfully sends telemetry messages and it received the Twin information. 
    - Updated desired properties for twin on portal and confirm that the update is received on the module, use pod logs to confirm using `kubectl logs <MODULE POD NAME>`

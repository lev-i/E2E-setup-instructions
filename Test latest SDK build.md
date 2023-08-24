### Prerequisites
- Install kubectl for windows.
    - https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
<br/><br>   
- Open docker desktop.
    - Go to settings -> Kubernetes tab.
    - Enable Kubernetes (might take a couple minutes)
    - Double check docker kubernetes is being used: ` kubectl config get-contexts`
<br/><br>  
- Create new visual studio project.
- In Visual Studio, on the Tools menu, select Options > NuGet Package Manager > Package Sources. Select the green plus in the upper-right corner and enter the name and source URL below:
    - Name: sdklite-previews
    - Soruce: https://pkgs.dev.azure.com/e4k-sdk/SdkLite/_packaging/sdklite-previews/nuget/v3/index.json
<br/><br>  
- On the Tools menu, select Nuget Package Manager > Package Manager Console.
    - Execute `Install-Package MqttSdkLite -version 0.1.152-dev`
<br/><br>     
- Copy-paste the files from leaf-device project and put them in this VS project.
    - https://github.com/Azure/e4k-iothub-connector/tree/main/test/leaf-device
<br/><br>
- Install E4K (If does not work on CMD/Powershell, using VS terminal or download Cmder: https://cmder.app/)
    - `helm install e4k oci://edgebuilds.azurecr.io/helm/az-e4k   --version 0.6.0-dev`
        - <mark>Note:</mark> Uninstall using: `helm uninstall e4k && kubectl get crds -o name | grep "az-edge.com" | xargs kubectl delete`
<br/><br>
-  Execute 'cert-w.sh' script. 
    - `bash cert-w.sh`
    - `kubectl create configmap client-ca --from-file ca.pem=ca.pem`
    - `kubectl create secret tls e4k-custom-ca-cert --cert=e4k-auth-ca.pem  --key=e4k-auth-ca-key.pem`
    - `kubectl create secret tls e4k-8883-cert --cert=dmqtt-cert.pem --key=dmqtt-cert-key.pem`
    - `kubectl create serviceaccount azedge-dmqtt-module-client-sa`\
    The script will create config map `client-ca` and secrets `e4k-8883-cert` and `e4k-custom-ca-cert` in kubernetes. You can view them using commands `kubectl get configmap` and `kubectl get secrets`.
<br/><br>
- Create an IoT hub, create an edge device (name: e4k-edge-1), create a non-edge leaf device (name: leaf-device-1) on the hub. Set the parent of the leaf device to be the edge device.
<br/><br>
- Create kubernetes secret for both edge device and the leaf device.
    - `kubectl create secret generic e4k-gateway-secrets --from-literal=edgeDevice="<EDGE DEVICE CONNECTION STRING>;UseTls=true;ClientId=hub-connector;MqttVersion=5;CaFile=/certs/ca.pem" --from-literal=Broker=HostName=azedge-dmqtt-frontend`
    - `kubectl create secret generic leaf-device-secrets --from-literal=cs="<LEAF DEVICE CONNECTION STRING>;MqttGatewayHostName=azedge-dmqtt-frontend;CaFile=/certs/ca.pem"`
<br/><br>
- Deploy everything within /deploy-SDK-build/e4k folder. Also deploy the hub-connector and leaf device separately.
    - `kubectl apply -f deploy-SDK-build/e4k`
    - `kubectl apply -f deploy-SDK-build/hub-connector.yaml`
<br/><br>
- Execute `kubectl get pods` and make sure all pods are ready and in running state. (may take a couple minutes)
- Troubleshoot any pod: `kubectl logs <POD NAME>`    
<br/><br>
- Run leaf-device project.
    - Update the connection string in Device.cs to be as following:
        - `"<LEAF_DEVICE CONNECTION STRING>;MqttGatewayHostName=localhost;UseTls=true;TcpPort=8883;CaFile=ca.pem"`
    - Run the leaf-device project and make sure device successfully sends telemetry messages and it received the Twin information.
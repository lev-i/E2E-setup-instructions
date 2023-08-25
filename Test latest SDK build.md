### Prerequisites
1. Install kubectl for windows.
    - https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
<br/><br>   
2. Open docker desktop.
    - Go to settings -> Kubernetes tab.
    - Enable Kubernetes (might take a couple minutes)
    - Double check docker kubernetes is being used: ` kubectl config get-contexts`
<br/><br>  
3. Copy-paste the files from leaf-device project and put them in a new VS project.
    - https://github.com/Azure/e4k-iothub-connector/tree/main/test/leaf-device
4. Similarly, copy files from module-sample project and create a project within the same solution.
    - https://github.com/Azure/e4k-iothub-connector/tree/main/test/module-sample     
4. In Visual Studio, on the Tools menu, select Options > NuGet Package Manager > Package Sources. Select the green plus in the upper-right corner and enter the name and source URL below:
    - Name: sdklite-previews
    - Soruce: https://pkgs.dev.azure.com/e4k-sdk/SdkLite/_packaging/sdklite-previews/nuget/v3/index.json
<br/><br>  
5. On the Tools menu, select Nuget Package Manager > Package Manager Console.
    - Execute `Install-Package MqttSdkLite -version 0.1.152-dev`
<br/><br>
7. Install E4K (If does not work on CMD/Powershell, using VS terminal or download Cmder: https://cmder.app/)
    - `helm install e4k oci://edgebuilds.azurecr.io/helm/az-e4k   --version 0.6.0-dev   --set global.quickstart=true`
        - <mark>Note:</mark> Incase installing E4K fails, uninstall first using: `helm uninstall e4k && kubectl get crds -o name | grep "az-edge.com" | xargs kubectl delete`
<br/><br>
8. Execute 'cert-w.sh' script. 
    - `bash cert-w.sh`
    - `kubectl create configmap client-ca --from-file ca.pem=ca.pem`
    - `kubectl create secret tls e4k-custom-ca-cert --cert=e4k-auth-ca.pem  --key=e4k-auth-ca-key.pem`
    - `kubectl create secret tls e4k-8883-cert --cert=dmqtt-cert.pem --key=dmqtt-cert-key.pem`
    - `kubectl create serviceaccount azedge-dmqtt-module-client-sa`\
    The script will create config map `client-ca` and secrets `e4k-8883-cert` and `e4k-custom-ca-cert` in kubernetes. You can view them using commands `kubectl get configmap` and `kubectl get secrets`.
<br/><br>
9. Create an IoT hub, create an edge device (name: e4k-edge-1), create a non-edge leaf device (name: leaf-device-1) on the hub. Set the parent of the leaf device to be the edge device. Create module identity on the leaf device. (name: leaf-module-1)
<br/><br>
10. Create kubernetes secret for both edge device and the leaf device.
    - `kubectl create secret generic e4k-gateway-secrets --from-literal=edgeDevice="<EDGE DEVICE CONNECTION STRING>;UseTls=true;ClientId=hub-connector;MqttVersion=5;CaFile=/certs/ca.pem" --from-literal=Broker=HostName=azedge-dmqtt-frontend`
<br/><br>
11. Deploy the hub-connector as a kubernetes pod.
    - `kubectl apply -f deploy-SDK-build/hub-connector.yaml`
<br/><br>
12. Execute `kubectl get pods` and make sure all pods are ready and in running state. (may take a couple minutes)
    - Troubleshoot any pod: `kubectl logs <POD NAME>`
<br/><br>
13. Run leaf-device project.
    - Update the connection string in Device.cs to be as following:
        - `"<LEAF_DEVICE CONNECTION STRING>;MqttGatewayHostName=localhost;UseTls=true;TcpPort=8883;CaFile=ca.pem"`
    - Run the leaf-device project and make sure device successfully sends telemetry messages and it received the Twin information.
14. Run the module-sample project.
    -  Update the connection string in Module.cs to be as following:
        - `"<MODULE CONNECTION STRING>;MqttGatewayHostName=localhost;UseTls=true;TcpPort=8883;CaFile=ca.pem"`
    - Run the module sample project and make sure module successfully sends telemetry messages and it received the Twin information. 
    - Updated desired properties for twin on portal and confirm that the update is received on the module, use pod logs to confirm using `kubectl logs <MODULE POD NAME>`
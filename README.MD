# MuleSoft Runtime - Automated Provisioning Guidelines

These assets and documentation enable automation of MuleSoft runtime provisioning for Hybrid deployments when not using the **Anypoint Runtime Fabric** for multi-cloud deployments (recommended option).

These are intended for devops team / developers working on automating MuleSoft Runtime Provisioning.

The first section *Dockerizing the Mule Runtime EE* provides information about the MuleSoft Runtime Dockerization.

The second section *Anypoint Runtime Manager - Hybrid Setup* provides information about hybrid servers automated registration in Anypoint Runtime Manager (ARM), and automated cluster creation.
The scripts provided can be used both for ARM registration in the US or EU management plane.

All assets are located in the ```mule-runtime-container``` folder.

## Components 
Software components and versions used.

* MuleSoft Runtime Version: 3.9.0
* MuleSoft Runtime Manager Agent Version: 1.9.4
* JDK Version: Oracle JDK 1.8

## Dockerizing the Mule Runtime EE

Information about Mule Runtime Docker image creation, container creation, execution and deletion.

### Pre-requisites

* Docker Version 17.12+
* Download the MuleSoft Runtime: 3.8.X / 3.9.x. https://docs.mulesoft.com/release-notes/mule-esb
    * If not using the latest 3.8/3.9 version Runtime Manager Agent (RMA) must be upgraded.
         * Unzip Mule Runtime and upgrade the RMA as per official documentation https://docs.mulesoft.com/runtime-manager/installing-and-configuring-runtime-manager-agent  
         * Zip back the upgraded runtime.
    * Rename the zip file to: *mule-ee-distribution-standalone-VERSION.zip* 
    * It must be placed at the Dockerfile label.
* MuleSoft Runtime Manager Agent Version: 1.9.4+
* Copy your runtime license to *muleLicenseKey.lic*

### Build Docker Image Of the Mule Runtime

1. Run:
```$> ./build_container.sh {image_tag} ```

    Console output example
    
        ```
        BA-JPORCEL-OSX:mule-runtime-container-385 juanporcel$ ./build-container.sh 1.0.5
        Docker version 17.12.0-ce, build c97c6d6
        Image Id: mule-runtime-3.9.0:1.0.5
        Sending build context to Docker daemon  381.1MB
        Step 1/21 : FROM ubuntu:16.04
        ---> 891c9734d5ab
        Step 2/21 : MAINTAINER MuleSoft
        ---> Using cache
        ---> 3ba5815e0acb
        Step 3/21 : ENV MULE_VERSION=3.9.0
        ---> Using cache
        ---> 3b51de035ecb
        Step 4/21 : COPY ./mule-ee-distribution-standalone-$MULE_VERSION.zip /opt/
        (...)
        ```
        
    2. Run ```docker image ls```  the new image should be listed.
   
    Example
    
        ```
        BA-JPORCEL-OSX:mule-runtime-container-385 juanporcel$ docker image ls
        REPOSITORY                            TAG                 IMAGE ID            CREATED             SIZE
        mule-runtime-3.9.0                    1.0.6               a65b9b5e523b        17 seconds ago      1.82GB
        ```

### Create the Container
1. Run: ```sudo ./run_container.sh {image_tag}```

    Example:
        ```
        BA-JPORCEL-OSX:mule-runtime-container-390 juanporcel$ sudo ./run-container.sh 1.0.7
        13ac1e2c66ba679abae7e0479a83d6225cfb8c3708bece46aa51f484b5edb2cf
        CONTAINER ID        IMAGE                         COMMAND                  CREATED                  STATUS                    PORTS                                                                                NAMES
        13ac1e2c66ba        mule-ee-runtime-3.9.0:1.0.7   "/opt/mule/bin/mule …"   Less than a second ago   Up Less than a second     443/tcp, 1098/tcp, 5000/tcp, 5701/tcp, 8091/tcp, 54327/tcp, 0.0.0.0:8081->8081/tcp   mule-ee-runtime-3.8.5-1.0.7
        ```
2. Start the Mule runtime the Container.

```docker exec -it {mule_container_name} /opt/mule/bin/mule start```

### Removing the Container
1. Look for the Container Name and Id to remove: ```docker ps -a```
2. Stop the runtime: ```docker exec -it {mule_container_name} /opt/mule/bin/mule stop```
2. Stop the container: ```docker container stop {container_id}```
3. Remove the container: ```docker container rm --force {container_id}```
    Example:
        ```docker container rm b25aabb8787c```
4. Verify the Container has been effectively removed: ```docker ps -a```

### Removing the Docker Image

1. List Docker images: ```$> docker image ls  ```
```
juan.porcel@BA-JPORCE-OSX:~/Documents/code/github/runtime-provisioning$ docker image ls
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
mule-ee-runtime-3.8.5   6.0.1               3364aa1d001e        3 hours ago         1.84GB
mule-ee-runtime-3.8.5   5.0.1               73e701c1401c        5 hours ago         1.84GB
node                    carbon              4635bc7d130c        4 weeks ago         673MB
openjdk                 8                   891c9734d5ab        6 weeks ago         726MB
```
2. Remove Docker Image: ```$> docker image rm --force {image_id} ```

    Example:
        ```$> docker image rm --force 73e701c1401c ```
        
### Anypoint Runtime Manager - Hybrid Setup

The following information is useful to automate hybrid servers registration in ARM, create clusters, add servers to clusters, and remove servers from clusters.

### Pre-requesites 
1. JQuery framework installed. https://jquery.com/download/

### ARM Server Registration (Script)

This steps will allow you to automate the Runtime Server registration to ARM, adding the server to the cluster, and creating the cluster if it does not exist. 

#### Steps

1. Make sure the Runtime is stopped before using the registration script.

```docker exec -it {mule_container_name} /opt/mule/bin/mule stop```

2. Register the Runtime

```docker exec -it {mule_container_name} /opt/mule/bin/arm_register_server.sh  -u {username} -p {password} -o {orgName} -e {envName} -s {serverName} -c {clusterName} --server-ip {server_ip_addr}```

**Important.** To register the server in the EU Management Plane (eu1 region), add the ```--region eu1``` parameter.

#### Example

```docker exec -it {mule_container_name} /opt/mule/bin/arm_register_server.sh --region eu1 -u {username} -p {password} -o {orgName} -e {envName} -s {serverName} -c {clusterName} --server-ip {server_ip_addr}```

**Important.** If your password contains special characters, these must be scaped using a backslash '\'. Example: Is your password is passw%rd! then it must be written like this passw\\%rd\\! and do not  use quotes or double quotes around it.
```docker exec -it {mule_container_name} /opt/mule/bin/arm_register_server.sh --region eu1 -u {username} -p passw\%rd\! -o {orgName} -e {envName} -s {serverName} -c {clusterName}```

#### Console output Example

```
[...] Communication between Anypoint Management Center and the Mule Agent is authorized by using two way SSL verification. In the following step we are 
going to create a keystore and request Anypoint Management Center to sign it. Your private key will never leave your machine.

Sending Sign request to Anypoint Management Center 

Mule Agent configured successfully
Starting Runtime.
MULE_HOME is set to /opt/mule
Starting Mule Enterprise Edition...
Waiting for Server to Start. This action may take some minutes, please wait.
.......................done
Setting Up Cluster...
Getting server details from https://eu1.anypoint.mulesoft.com/hybrid/api/v1/servers...
Server jmporcel-local-node-a-8 found ID: 99006
Getting cluster details from https://eu1.anypoint.mulesoft.com/hybrid/api/v1/clusters...
Server jmporcel-local-node-a-8 is not clustered, create Cluster: jmporcel-test-cluster-8
Create Cluster Payload: {"name": "jmporcel-test-cluster-8", "multicastEnabled": false, "servers": [ {"serverId" : 99006, "serverIp":"10.8.8.51"} ]}
{"data":{"id":99007,"timeCreated":1525295609350,"timeUpdated":1525295609350,"name":"jmporcel-test-cluster-8","type":"CLUSTER","status":"RUNNING","multicastEnabled":false,"primaryNodeId":null,"servers":[{"id":99006,"timeCreated":1525295580195,"timeUpdated":1525295609354,"name":"jmporcel-local-node-a-8","type":"SERVER","serverType":"GATEWAY","muleVersion":"3.9.0","gatewayVersion":"3.9.0","agentVersion":"1.9.4","licenseExpirationDate":1668470400000,"status":"RUNNING","addresses":[{"ip":"172.17.0.2","networkInterface":"eth0"}],"clusterId":99007,"clusterName":"jmporcel-test-cluster-8","serverIp":"10.8.8.51","runtimeInformation":{"jvmInformation":{"runtime":{"name":"Oracle JDK Environment","version":"1.8.0_162-8u162-b12-1~deb9u1-b12"},"specification":{"vendor":"Oracle Corporation","name":"Java Platform API Specification","version":"1.8"}},"osInformation":{"name":"Linux","version":"4.9.87-linuxkit-aufs","architecture":"amd64"},"muleLicenseExpirationDate":1668470400000}}],"visibilityMap":{"mapNodes":[{"serverId":99006,"visibleNodeIds":[],"unknownNodeIps":[]}]}}}Done.
juan.porcel@BA-JPORCE-OSX:~/Documents/code/bitbucket/mulesoftautomation/mule-runtime-container-385$
```

### ARM Server Deletion (Script)

Register the Runtime Server, add server to existing cluster, and create cluster if it does not exist. 

```docker exec -it {mule_container_name} /opt/mule/bin/arm_register_server.sh --remove -u {username} -p {password} -o {orgName} -e {envName} -s {serverName} -c {clusterName}```
    
**Important note**. If working with the EU Management plane, remember to add the  ```--region eu1``` parameter.

Example :      
```docker exec -it {mule_container_name} /opt/mule/bin/arm_register_server.sh --region eu1 --remove -u {username} -p {password} -o {orgName} -e {envName} -s {serverName} -c {clusterName}```

### ARM Server Registration (Manual)

1. Login to the Anypoin Account and obtain ```registration_token``` from ARM. Reference Documentation: https://docs.mulesoft.com/runtime-manager/servers-create 

2. Register the Runtime Server. ```docker exec -it {mule_container_name} /opt/mule/bin/amc_setup --hybrid {registration_token} {server_name}```

**Important note**. If working with the EU Management plane, remember to add the  ```--region eu1``` parameter.

Example:  ```docker exec -it {mule_container_name} /opt/mule/bin/amc_setup --region eu1 --hybrid {registration_token} {server_name}```

2. Restart the Runtime.  ```docker exec -it {mule_container_name} /opt/mule/bin/mule restart```

### Related assets
These assets are related to the following resources:
* https://wiki.corp.mulesoft.com/display/SVCS/Dockerizing+Mule+ESB
* https://wiki.corp.mulesoft.com/display/SVCS/Register+Mule+Runtime+to+ARM+Programatically
* https://docs.mulesoft.com/runtime-manager/runtime-manager-agent-architecture



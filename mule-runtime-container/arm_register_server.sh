#!/bin/bash

## Example: 
# $> ./arm_register_server.sh --region eu1 -u username -p password -o "My Anypoint Org" -e Sandbox -s test-server -c test-cluster --server-ip 127.0.0.1

## Default muleHome to be used when MULE_HOME env var is not set. Change this value as needed.
defaultMuleHome=/opt/mule

# Parse input parameters and set variables required 
init(){
    removeServer=false
    hybridAPI='https://anypoint.mulesoft.com/hybrid/api/v1'
    accAPI='https://anypoint.mulesoft.com/accounts'

    args="$@ --"
    echo "Args: $args"

    while [ $# -ge 1 ]; do
            case "$1" in
                    --)
                        # No more options left.
                        shift
                        break
                       ;;
                    -u|--username)
                            username="$2"
                            echo "username=$username"
                            shift
                            ;;
                    -p|--password)
                            password="$2"
                            echo "password=****"
                            shift
                            ;;
                    -o|--organization)
                            orgName="$2"
                            echo "organization=$orgName"
                            shift
                            ;;
                    -e|--environment)
                            envName="$2"
                            echo "environment=$envName" 
                            shift
                            ;;
                    -s|--server)
                            serverName="$2"
                            echo "server=$serverName" 
                            shift
                            ;;
                    -c|--cluster)
                            clusterName="$2"
                            echo "cluster=$clusterName" 
                            shift
                            ;;
                    --region)
                            region="$2"
                            echo "region=$region" 
                            shift
                            ;;
                    --server-ip)
                            serverIp="$2"
                            echo "serverIp=$serverIp"
                            shift
                            ;;
                    --remove)
                            removeServer=true
                            echo "REMOVE SERVER OPTION SELECTED." 
                            shift
                            ;;
                    -h|--help)
                            echo "########################################"
                            echo "### ARM Register Server script help  ###"
                            echo " $> ./arm_register_server.sh [ --region eu1 ] [ --remove] [ --server-ip {server_ip_addr} ] [--help] -u|--username {username} -p|--password {password} -o|--organization {orgName} -e|--environment {envName} -s|--server {serverName} -c|--cluster {clusterName}"
                            echo "### Example: "
                            echo " $> ./arm_register_server.sh --region eu1 -u username -p password -o \"My Anypoint Org\" -e \"Sandbox\" -s test-server -c test-cluster --server-ip 10.8.8.85"
                            echo "########################################"

                            exit 0
                            ;;
            esac
            shift
    done
    if [ "$region" == "eu1" ]; then
        hybridAPI='https://eu1.anypoint.mulesoft.com/hybrid/api/v1'
        accAPI='https://eu1.anypoint.mulesoft.com/accounts'
    fi
    if [ -z "$serverIp" ]; then
        serverIp=$(dig +short myip.opendns.com @resolver1.opendns.com)
    fi
    ## use MULE_HOME env var if defined.
    if [ -z "$MULE_HOME" ]; then
        echo "MULE_HOME Environment var not set. Using default: \"$defaultMuleHome\" "
        muleHome="$defaultMuleHome"
    else
        echo "using MULE_HOME Environment var: \"$MULE_HOME\" "
        muleHome="$MULE_HOME"
    fi
}
 
# username
# password
get_access_token() {
    # Authenticate with user credentials (Note the APIs will NOT authorize for tokens received from the OAuth call. A user credentials is essential)
    echo "Getting access token from $accAPI/login..."
    accessToken=$(curl -s $accAPI/login -X POST -d "username=$1&password=$2" | jq --raw-output .access_token)
    echo "Access Token: $accessToken"
}
 
# access_token
# org_name
get_organization_id() {
    # Pull org id from my profile info
    echo "Getting org ID from $accAPI/api/me..."
    echo "Org Name = $2"
    jqParam=".user.contributorOfOrganizations[] | select(.name==\"$2\").id"
    orgId=$(curl -s $accAPI/api/me -H "Authorization:Bearer $1" | jq --raw-output "$jqParam")
    echo "Organization ID: $orgId"
}
 
# access_token
# org_id
# env_name
get_environment_id() {
    # Pull env id from matching env name
    echo "Getting env ID from $accAPI/api/organizations/$2/environments..."
    echo "Environment Name: $3" 
    #echo "get_environment_id response: $(curl -s $accAPI/api/organizations/$orgId/environments -H "Authorization:Bearer $1")"
    jqParam=".data[] | select(.name==\"$3\").id"
    envId=$(curl -s $accAPI/api/organizations/$orgId/environments -H "Authorization:Bearer $1" | jq --raw-output "$jqParam")
    echo "Environment ID: $envId"
}
 
# amc_token
# server_name
# region
register_server() {
    # Register new mule
    echo "Registering $2 to Anypoint Platform..."
    echo "Using registration token: $1"

    if [ "$3" == "eu1" ]; then
         echo "Region: EU1"
        "$muleHome/bin/amc_setup" --region eu1 --hybrid $1 $2
    else
         echo "Region: US"
        "$muleHome/bin/amc_setup" --hybrid $1 $2
    fi
 }

 
# access_token
# org_id
# env_id
get_amc_token() {
    # Request amc token
    echo "Getting registration token from $hybridAPI/servers/registrationToken..."
    amcToken=$(curl -s $hybridAPI/servers/registrationToken -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1" | jq --raw-output .data)
    echo "AMC Token: $amcToken"
}
 
# access_token
# org_id
# env_id
# server_name
# cluster_name
# server_ip
create_or_extend_cluster() {
    # Get Server ID from AMC
    echo "Getting server details from $hybridAPI/servers..."
    serverData=$(curl -s $hybridAPI/servers/ -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1")
    jqParam=".data[] | select(.name==\"$4\").id"
    serverId=$(echo $serverData | jq --raw-output "$jqParam")
    jqParam=".data[] | select(.name==\"$4\").addresses[0].ip"
    serverIp=$(echo $serverData | jq --raw-output "$jqParam")
    if [ "$serverId" != "null" -a "$serverId" != "" ]
        then
            echo "Server $4 found ID: $serverId"
            # Get Cluster ID
            echo "Getting cluster details from $hybridAPI/clusters..."
            clusterData=$(curl -s $hybridAPI/clusters/ -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1")
            jqParam=".data[] | select(.name==\"$5\").id"
            clusterId=$(echo $clusterData | jq --raw-output "$jqParam")
            if [ "$clusterId" == "null" -o "$clusterId" == "" ]
                then
                    # Create cluster
                    echo "Server $4 is not clustered, create Cluster: $5"
                    payload="{\"name\": \"$5\", \"multicastEnabled\": false, \"servers\": [ {\"serverId\" : $serverId, \"serverIp\":\"$6\"} ]}"
                    echo "Create Cluster Payload: $payload"
                    curl -s -X POST $hybridAPI/clusters/ -H "Content-Type: application/json" -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1" -d "$payload"
                else
                    # Add to cluster
                    payload="{\"serverId\": $serverId, \"serverIp\":\"$6\"}"
                    echo "Add Cluster Payload: $payload"
                    curl -s -X POST $hybridAPI/clusters/$clusterId/servers -H "Content-Type: application/json" -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1" -d "$payload"
            fi
    fi
}
 
# access_token
# org_id
# env_id
# server_name
server_status() {
    # Get Server ID from AMC
    # echo "Getting server details from $hybridAPI/servers..."
    serverData=$(curl -s $hybridAPI/servers/ -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1")
    jqParam=".data[] | select(.name==\"$4\").status"
    serverStatus=$(echo $serverData | jq --raw-output "$jqParam")
    # echo "Server status: $serverStatus"
}

# access_token
# org_id
# env_id
# server_name
deregister_server() {
    echo "De-registering $4 from Anypoint Platform..."
 
    # Get Server ID from AMC
    echo "Getting server details from $hybridAPI/servers..."
    serverData=$(curl -s $hybridAPI/servers/ -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1")
    jqParam=".data[] | select(.name==\"$4\").id"
    if [ "$serverId" != "null" -a "$serverId" != "" ]
        then
            echo "Server $4 found ID: $serverId"
 
            # Get Cluster ID
            jqParam=".data[] | select(.name==\"$4\").clusterId"
            clusterId=$(echo $serverData | jq --raw-output "$jqParam")
            if [ "$clusterId" != "null" -a "$clusterId" != "" ]
                then
                    echo "Server $4 is found in Cluster ID: $clusterId"
 
                    # Removing mule server from the cluster
                    echo "Removing server from cluster at $hybridAPI/clusters/$clusterId/servers/$serverId..."
                    rmResponse=$(curl -s -X "DELETE" "$hybridAPI/clusters/$clusterId/servers/$serverId" -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1")
 
                    # If error response from removing last one mule server from the cluster
                    if [ "$rmResponse" != "" ]
                        then
                            echo "Looks like $serverName is the last server in the cluster."
                            echo "Removing cluster at $hybridAPI/clusters/$clusterId..."
                            curl -s -X "DELETE" "$hybridAPI/clusters/$clusterId" -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1"
                    fi
            fi
 
            # Deregister mule from ARM
            echo "Deregistering Server at $hybridAPI/servers/$serverId..."
            curl -s -X "DELETE" "$hybridAPI/servers/$serverId" -H "X-ANYPNT-ENV-ID:$3" -H "X-ANYPNT-ORG-ID:$2" -H "Authorization:Bearer $1"
    fi

    rm "$muleHome/conf/mule-agent.yml.bak"
    mv "$muleHome/conf/mule-agent.yml"  "$muleHome/conf/mule-agent.yml.bak" 
}

init "$@" 
if $removeServer ; then
        echo "Removing Server"
        "$muleHome/bin/mule" stop
        get_access_token "$username" "$password"
        get_organization_id $accessToken "$orgName"
        get_environment_id $accessToken $orgId "$envName"
        deregister_server $accessToken $orgId $envId "$serverName"
        echo "Done."
else
        echo "Registering Server"
        get_access_token "$username" "$password"
        get_organization_id $accessToken "$orgName"
        get_environment_id $accessToken $orgId "$envName"
        get_amc_token $accessToken $orgId $envId
        register_server $amcToken "$serverName" $region
          
        echo "Starting Runtime."
        # start mule
        "$muleHome/bin/mule" start
         
        # Create cluster when server started and RUNNING
        server_status $accessToken $orgId $envId "$serverName"
        echo "Waiting for Server to Start. This action may take some minutes, please wait."
        while true;do echo -n .;sleep 1;done &
            while [ "$serverStatus" != "RUNNING" ]
                do
                   sleep 10
                   server_status $accessToken $orgId $envId "$serverName"
                done            
            kill $!; trap 'kill $!' SIGTERM
        echo done
        echo "Setting Up Cluster..."
        create_or_extend_cluster $accessToken $orgId $envId "$serverName" "$clusterName" $serverIp
        echo "Done."
fi



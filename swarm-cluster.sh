#!/usr/bin/env bash


#
# A bash script to set up a simple Docker Swarm cluster using Docker Machine & VirtualBox
# Run using source ('$ . swarm-cluster.sh') so that DOCKER_* variables are exported
#
# Run `docker-machine rm -f swarm-{1..3}' if you need to tear down the cluster and create it once again
#

machines=$(docker-machine ls -q)
for i in {1..3}; do
        machine="swarm-$i"
        echo ">>  $machine"
        if [[ "$machines" == *"$machine"* ]]; then
                echo "    already exists"
                if [[ $(docker-machine ls -f {{.State}} \
                            --filter "name=$machine") != "Running" ]]; then
                        docker-machine start "$machine"
                fi
        else
                docker-machine create -d virtualbox swarm-$i
        fi
done

MANAGER_IP=$(docker-machine ip swarm-1)
eval $(docker-machine env swarm-1)

docker node ls  >> /dev/null 2>&1

if [[ $? -ne 0 ]]; then
        docker swarm init \
                --advertise-addr $MANAGER_IP
fi

WORKER_TOKEN=$(docker swarm join-token worker -q)
MANAGER_TOKEN=$(docker swarm join-token manager -q)

for i in 2 3; do
        machine="swarm-$i"
        eval $(docker-machine env swarm-$i)
        DOCKER_IP=$(docker-machine ip swarm-$i)
        docker node ls  >> /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
                echo "$machine is joining swarm"
                docker swarm join --token $MANAGER_TOKEN $MANAGER_IP:2377
        fi
done

eval $(docker-machine env swarm-1)

docker node ls

echo <<EOF
>> The Swarm Cluster is set up!
>> Execute 'eval $(docker-machine env swarm-1)' if script was not run with source
EOF
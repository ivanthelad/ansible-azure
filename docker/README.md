# Deploying Openshift Enterprise to Azure with container
Simple project to help installing HA setup of Openshift Enterprise to Azure. Installer will use https://github.com/ivanthelad/ansible-azure project to do actually installation.

Installation is done with Docker container and environmental variables that are passed to docker run command. This project is just a wrapper to actual OSE installation so check more info about the installation from above link.

## What you need to for the installation
* Azure AD account
* Enough quota for cores (by default 10 cores )
* Red Hat account and Openshift Enterprise subscription
* Docker

## Sample ALL config
The following configs are required

* resource_group_name: ivancloud     [This should be unique name ]

* ad_password: XXXXXXXXXXXXXXXXXXX   [Ansible User for azure ]

* subscriptionID: XXXXXXXXXXXXXX     [Ansible pwd for azure ]

* adminUsername: ivan                [User to log into jumphost with ]

* adminPassword: XXx_please_change_me_xXX  [User pwd to log into jumphost with ]

* rh_subcription_user: XXXXXXXXXXX   [RH subscription user ]

* rh_subcription_pass: XXXXXXXXXXX   [RH subscription pwd ]

* openshift_pool_id: XXXXXXXXXXX     [RH subscription pwd ]

```

#---
resource_group_name: pirates
##  Azure AD user.
ad_username: XXXXXXXXXXXXXXXXXXX
### Azure AD password
ad_password: XXXXXXXXXXXXXXXXXXX
#resource_group_name: oscp
#### Azure Subscription ID
subscriptionID: "XXXXXXXXXXXXXXXXXXX"
## user to login to the jump host. this user will only be created on the jumphost
adminUsername: ivan
## user pwd for jump host
## Password for the jump host
adminPassword: XXx_please_change_me_xXX
##### Public key for jump host. With the Docker installation this will be replaced dynamically
sshkey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCdC20wMbD9vmCPDD6VP6u3eYHCznqKOm+aPZi3EgUZIM7r91X7MFzuVS5U6gHXnOa4m7yh26zceh68T6FqIKby1WAGTShLFDCU6czEe0Pa5yMAV6Q4dQ34HyioTIu4HmXi4504ZxneLNJP2AHc+eJkV0ANcXIHSqoaleVyWt7HLNltFNO349GZMj01TSchBYzqZpYqSGIDsTIXwF6+/NosMLfmg6WF0J4M7A34Gn/YTXD8r2oWeSs3O+MdTMH2Zdt4j9Q8MPCgic6xDPiONpCvEdt5pkzrwaK9ZJEV4wZsV7CSy+5a+poOl/a/5F+Mj3qwqwqwFc2IRJiDkScuV07qWthKH


# see https://azure.microsoft.com/en-us/documentation/articles/cloud-services-sizes-specs/
### Size for the master
master_vmSize: Standard_DS3_v2
#master_vmSize: Standard_D2_v2
#master_vmSize: Standard_D1_v2

### Size for the nodes
node_vmSize: Standard_DS3_v2
#node_vmSize: Standard_D2_v2
#node_vmSize: Standard_D1_v2

#### Region to deploy in
region: northeurope

## docker info
docker_storage_device: /dev/sdc
create_vgname: docker_vg
filesystem: 'xfs'
create_lvsize: '80%FREE'
#create_lvsize: '2g'

#### subscription information
rh_subcription_user: XXXXXXXXXXX
rh_subcription_pass: XXXXXXXXXXX
openshift_pool_id: XXXXXXXXXXX

########### list of node  ###########
### Warning, you currently cannot create more infra nodes ####
### this will change in the future
### You can add as many nodes as you want
#####################################
jumphost:
  jumphost1:
    name: jumphost1
    tags:
      region: northeurope
      zone: jumphost
      stage: jumphost

masters:
  master1:
    name: master1
    tags:
      region: northeurope
      zone: infra
      stage: none
#  master2:
#    name: master2
#    tags:
#      region: northeurope
#      zone: infra
#      stage: none
#  master3:
#    name: master3
#    tags:
#      region: northeurope
#      zone: infra
#      stage: none

infranodes:
  infranode1:
    name: infranode1
    tags:
      region: northeurope
      zone: infra
      stage: dev
      type: core
      infratype: registry
      mbaas_id: mbaas1
  infranode2:
    name: infranode2
    tags:
      region: northeurope
      zone: infra
      stage: dev
      type: core
      mbaas_id: mbaas2
  infranode3:
    name: infranode3
    tags:
      region: northeurope
      zone: infra
      stage: dev
      type: core
      mbaas_id: mbaas3
nodes:
  node1:
    name: node1
    tags:
      region: northeurope
      zone: frontend
      stage: dev

```

## Setup

### Clone git repo
```
git clone https://github.com/tahonen/ansible-azure-docker.git
```
### Build Docker container
```
cd ansible-azure-docker
docker build -t ocpazure:latest .
```
Above build command will create an container with name ocpazure

## Installation

Installation will start right after you execute docker run command described below. If you just need to start container and check what it contains add "/bin/bash" at the end of the command. Also if you need to make modifications to number of VMs installed or other tuning, just start the container not the installation. When you are done with your changes just execute /ansible-azure/install.sh.



If you start installation directly you have to mount a local directory to container so that installer can export SSH key to you. Below example will export key to directory /tmp and the name of the file by default azurekey
- The installation outputs a newly created KEY  to /exports/azurekey.$resource_group_name


The docker container searches a directory /exports. It expects the following files to be present
  - all. This is the file describing you openshift installation. If this is not found then the script exits
  - azurekey.$resource_group_name: This file is the private key for your azure jumphost. where $resource_group_name is the based on property resource_group_name found in the provided 'all' file. If not present the docker installation will automatically generate it and save to exports directory. The reason it looks for it and not automatically generates all the time is because you may want to rerun the installation with the same key.  
  - azurekey.$resource_group_name.pub : related public key
  - inventory.$resource_group_name: Like the private and public key. you can supply a inventory file. This is required when rerunning a installation. this inventory file allows the ansible installer to connect to the jumphost ip. the inventory file is generated after the succesful installation of openshift and is based on a dynamic inventory.  This mechanism is provided so the scripts can reach the dynanmically created resources


To Perform a installation successfully the following is required
  - A volume, /exports ,to export the generated keys and inventory (this will allow you to ssh into your VMS ). And to supply a 'all configuration'
   - the container accepts a BRANCH env variable. if supplied it will download the latest version of the branch from the ansible azure install directory

in the below example. the folder  /Users/imckinle/Projects/openshift/azure-ansible/temp/mountexport contains the all directory

```
# start installation
 docker run -v /Users/imckinle/Projects/openshift/azure-ansible/temp/mountexport:/exports/ -it ocpazure
# start container
 docker run -v /Users/imckinle/Projects/openshift/azure-ansible/temp/mountexport:/exports/ -it ocpazure "/bin/bash"
 ## You can then start the install within the container by executing the ./install.sh script

## Start a installation based on 3.3 version of openshift.
 docker run -e BRANCH=master -v /Users/imckinle/Projects/openshift/azure-ansible/temp/mountexport:/exports/ -it

```


## Post install stuff

You need newly create SSH key to access jumphost. This key is exported to given host directory, /exports ,or you can read it from .ssh directory if you started installation manually. If you do not manage to get hold of the key you can change SSH key to jumphost vie Azure portal (https://portal.azure.com). Key is changed from VM settings via Set password.
   - ssh -i /Users/imckinle/Projects/openshift/azure-ansible/temp/mountexport/azurekey.$groupname

## TODO
* Define number of app and infra nodes thru envs.
* Export installation logs

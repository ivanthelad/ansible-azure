# ansible-azure
## install azure cli client
https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli

Or run azure client as docker image

```
docker run -v ${HOME}:/root -it azuresdk/azure-cli-python
```

## Configure setting  
The following outlines the settings that need to be configured. Please ensure that your groupname is unique as this is used as public dns name for the console

 resource_group_name: ivancloud

 ##  Azure AD user.
 ad_username: XXXXXXXXXXXXXXXXXXX

 ### Azure AD password

 ad_password: XXXXXXXXXXXXXXXXXXX

 ### this is  your azure subscription id

 subscriptionID:  XXXXXXXXXXXXXX

 ## user to login to the jump host. this user will only be created on the jumphost

 adminUsername: ivan

 ## user pwd for jump host

 ## Password for the jump host

 adminPassword: XXx_please_change_me_xXX

 ##### Public key for jump host

 sshkey: ssh-rsa XXXXXXXXXXXXX

 #### subscription information

 rh_subcription_user: XXXXXXXXXXX

 rh_subcription_pass: XXXXXXXXXXX

 openshift_pool_id: XXXXXXXXXXX



For the azure creditials, i recommend created a "ansible" user instead of using your existing adming user. The following steps can be followed to perform this
https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/
 - After creating a user as outlined in the above instructions. in the azure portal. go "settings"->"administrators", and then add user

 ### Creating a user principle
 It is recommended to user a user principle to provision the openshift infra.

 - az login
 - az account set --subscription="${SUBSCRIPTION_ID}"
 - az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"
 This will output your appId, password, name, and tenant. The name or appId may be used for the ClientId and the password is used for Secret. where app_id = ClientId

 add these properties from principal creation output to the config file "group_vars/all"
 - secret: "{{ password }}"
 - tenant: "{{ tenant }}"
 - client_id: "{{ appId }}"
 - principal: "{{ name }}"
Important, ensure ad_username and ad_password are empty when using principle

## Update ansible,
This ansible script uses features only found in the latest version on ansible (notable the azure plugin and the gatewayed feature )
 upgrade to ansible 2.1.0.0
http://docs.ansible.com/ansible/intro_installation.html

 Note: After upgrade to ansible 2.2 i encountered issues where the azure module attempts to pass two params to a function that expects one. this was resolved by upgrade the phyton msresrt module. " sudo pip install msrest --upgrade"

  this upgrade from msrest 0.4.0  to 0.4.1
    - pip install ansible
    - pip install  msrestazure --upgrade
    - pip install  msrest --upgrade


 See http://docs.ansible.com/ansible/azure_rm_deployment_module.html for info how to configure the module

## run script
Update the group_vars/all variable. The following params exist. The script will support more masters  in the future. For now the script installs 1 master, 1 infra, x number of nodes. the nodes and infra are get labels which corrospond the tags in azure (consistent)
 - ansible-playbook --forks=50 -i inventory playbooks/setupeverything.yml

## Script modules
The scripting has now been split into more granular operations. The playbook setupeverything inlcudes has 3 main playbooks

### provision_infrastructure.yml
Simply Provisions the basic infrastructure base on the Node Arrays defined in the group_vars/all file. This includes loadbalancer , availabilitySets and multiple subnets

 ### perform_prereqs.yml
 Configure all outline prereqs from the documention. Addition configures storage based on best practises to ensure if storage of logs, etc, openshift.volumes is exceeded it does not corrupt the rest of the node. Configures docker and installs required base packages
### install_openshift.yml
Creates dynamic ansible hosts file based on the contents of groups_var/all and the contents of the config under the prepare_multi roles


## scaling out
After the initial installation has been run and openshift is up and runnin it is possible to had extra node to the cluster. Add the additional node definition to the groups_var/all file and run the ansible script
  - ansible-playbook --forks=50    playbooks/provision_infrastructure.yml
This script is whats run in the playbook playbooks/setupeverything.yml



### configuration of nodes
Under the groups/all there is a  list of vms that will get created. This list also has a attribute called tag which. The values get set to azure tags and also openshift node labels  
  - jump node : this is required. all actions are performed via this node. This node needs to come up first before any of the other nodes can be created. this is because we generate a key on the jump node which is distributed to all subsequent nodes. For convience sake the LB infront of the master is also placed on this node.(opens port 8443 and 22). In the future this will be a azure loadbalancer
  - master: we create 3 of these. no ports facing the outside. Loadbalanced by the jump node
  - infra node: currently hosts the registry and the router. not tested with multiple infra nodes yet. should work
  - node: bunch of nodes to host applications

## Post install
  The installation of openshift is performed on the jump node. The local ansible script (setup_multimaster) execute another ansible script on the jump host(advanced install). The host file has already been placed under /etc/ansible/host by this stage and is dynamically build based on the template sitting under
   -  playbooks/roles/prepare_multi/templates/hosts.j2
 The execution of the advanced install is executed in async manner (to avoid timeouts as the advanced install can take time ). The local ansible script(setup_multimaster) polls the jump host for completion.

### Once installation is complete the following is configured
 - router ( is not deployed by default because the region=infra is not used)
 - Register: (is  not deployed by default because the region=infra is not used)
 - metrics,
 - logging : waits untils everything is ready before scaling out the fluentd nodes
 ### example node setup under groupvars/all
## Example group_vars/all file

The following snippet is a brief example of how the ansible scripts are configured to bring up a set of nodes

```

jumphost:
  jumphost1:
    name: jumphost1

    tags:
      region: "{{ region }}"
      zone: jumphost
      stage: jumphost
      type: jumphost

masters:
  master1:
    name: master1
    datadisksize: 80
    machinesize: Standard_DS2_v2
    storagtype: Premium_LRS
    tags:
      region: "{{ region }}"
      zone: zone1
      type: infra
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
    datadisksize: 64
    machinesize: Standard_DS2_v2
    storagtype: Premium_LRS
    tags:
      region: "{{ region }}"
      zone: zone1
      infra: "true"
      type: core
      infratype: registry
      mbaas_id: mbaas1
  infranode2:
    name: infranode2
    datadisksize: 64
    machinesize: Standard_DS2_v2
    storagtype: Premium_LRS
    tags:
      region: "{{ region }}"
      zone: zone2
      infra: "true"
      type: core
      mbaas_id: mbaas2
  infranode3:
    datadisksize: 64
    machinesize: Standard_DS2_v2
    storagtype: Premium_LRS
    name: infranode3
    tags:
      region: "{{ region }}"
      zone: zone3
      infra: "true"
      type: core
      mbaas_id: mbaas3
nodes:
  node1:
    name: node1
    datadisksize: 64
    machinesize: Standard_DS2_v2
    storagtype: Premium_LRS
    tags:
      region: "{{ region }}"
      zone: zone1
      infra: "false"
      stage: dev
      type: apps
  node2:
    name: node2
    datadisksize: 64
    machinesize: Standard_DS2_v2
    storagtype: Premium_LRS
    tags:
      region: "{{ region }}"
      zone: zone2
      infra: "false"
      stage: dev
      type: apps

```

### Required params

To setup the following params are required to be added to the group_vars/all file
 - resource_group_name: ose86
 - subscriptionID: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
 - adminUsername: userforjumphost
 - adminPassword: passwordforjumphost
 - sshkey : (public sshkey)
 - rh_subcription_user
 - rh_subcription_pass
 - openshift_pool_id

#### Example All Files

Under the directory all_example is a collection of sample all files. They are supplied as guidance on how to setup different variants of a openshift cluster
 - all_mega_cluster : A example of a production like cluster. wwith 3 masters, 3 infra nodes, 2 dev nodes and 2 production nodes
 - all_rhmap_core: A example demostrating a single master cluster that is labeled wit the expectation of RHMAP core been deployed ontoop (there is supplied playbooks to deploy RHMAP core, note you need relevent subscriptions )
 - all_multi_master: a example to demostration how to bring up a multi master cluster
 - all_single_master_small: A example of a bare-min cluster. with 1 master, 1 infra node, 1 application node  


### Debugging nodes
to debug stuff on nodes your first need to ssh to the jump node. ssh $adminUsername@jumpnodeip. The jump node ip should be written to groups/all file(only for later debugging purposes) but it is also writen to console as the ansible script is been executed. the jump nodes acts as a gateway for all vms created in azure. once logged into the jump node the user $adminUsername should have preconfigured ssh acces to all openshift nodes.  Simply execute  ``` ssh master1 ``` . The user $adminUsername also has sudo rights on all machines

#### monitoring openshift install
Since the openshift install is execute async on the jump node we cannot see the progress of the install.
To following the progress of the install, You can login using your user ivan@23.100.53.57 and tail the log file /tmp/ansible.log.
TODO: write ansible check to distinguish between failure and success of the install.

## GlusterFS storage
NOTE: Community version not yet supported and OCP & Gluster repos need to be in same subsctiption
Installer support single disk 3+ host GlusterFS installation. If you would like to install Gluster add following to all file.

Basic settings with 128Gi disk for storage
```
install_storage: true
storage_disks:
  - 128
storage_user_key: glusteruser
storage_admin_key: glusteruser
storage_api_user: admin
```

See storage hosts definition below. If you would like to SSD disk machinesize needs to be *DS* and then storagtype Premium_LRS.
 
```
storage:
  storage1:
    name: storage1
    datadisksize: 40
    machinesize: Standard_DS2_v2
    storagtype: Standard_LRS
    tags:
      region: "{{ region }}"
      infra: "false"
      stage: dev
      type: storage
      zone: 1
  storage2:
    name: storage2
    datadisksize: 40
    machinesize: Standard_DS2_v2
    storagtype: Standard_LRS
    tags:
      region: "{{ region }}"
      infra: "false"
      stage: dev
      type: storage
      zone: 2
  storage3:
    name: storage3
    datadisksize: 40
    machinesize: Standard_DS2_v2
    storagtype: Standard_LRS
    tags:
      region: "{{ region }}"
      infra: "false"
      stage: dev
      type: storage
      zone: 3
 ```

# Red Hat SSO (Keycloak). NOT FOR PRODUCTION
If you need test Red Hat's SSO product you can define installer to set it up for you. Setup is not for production and will contains self signed sertificates. If you would like to use Red Hat SSO for OCP authentication follow documentation from here https://access.redhat.com/documentation/en-us/red_hat_jboss_middleware_for_openshift/3/html/red_hat_jboss_sso_for_openshift/tutorials

Add following to all file if you would like to install SSO.
```
install_sso: true
sso_keypairdname: CN=jsmith,OU=IT,O=example.com,L=Somewhere,C=Country
sso_apptempalte: sso70-postgresql
sso_realm: azure
```

If you need persistance storage change sso_apptemplate to sso70-mysql-persistent or sso70-postgresql-persistent but then you need to provide 5Gi PV for SSO.

## Troubleshooting
If database doesn't start fast enough SSO server startup may fail due error creating database connection pool. In this case delete sso pod and let Openshift to spin it up again.

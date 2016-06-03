# ansible-azure
## install azure cli client
https://azure.microsoft.com/en-us/documentation/articles/xplat-cli-install/

## Configure azure creditals 
under the file  ~/.azure/credentials, insert the following (or create a principle)

* [default]
* ad_user=ansible@xxxxxxx.onmicrosoft.com
* password=XXXXXXX
* subscription_id=XXXXXXXX

For the above, i recommend created a "ansible" user instead of using your existing adming user. The following steps can be followed to perform this 
https://azure.microsoft.com/en-us/documentation/articles/resource-group-create-service-principal-portal/
 - After creating a user as outlined in the above instructions. in the azure portal. go "settings"->"administrators", and then add user

## Update ansible, 
This ansible script uses features only found in the latest version on ansible (notable the azure plugin and the gatewayed feature )
 upgrade to ansible 2.1.0.0
http://docs.ansible.com/ansible/intro_installation.html

## run script 
Update the group_vars/all variable. The following params exist. The script will support more masters  in the future. For now the script installs 1 master, 1 infra, x number of nodes. the nodes and infra are get labels which corrospond the tags in azure (consistent)
 - ansible-playbook -i inventory playbooks/setup.yml
 - 

### Required params 
 - resource_group_name: ose86
 - subscriptionID: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
 - adminUsername: userforjumphost
 - adminPassword: passwordforjumphost
 - sshkey : (public sshkey)
 - rh_subcription_user
 - rh_subcription_pass
 - openshift_pool_id






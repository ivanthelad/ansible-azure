#!/bin/bash
echo "Performing fresh build"
mkdir ~/.ssh
### The dir /export is used to accept key and inventory files

if [ -n "$BRANCH" ]; then
  echo "Discovered a value for environment variable BRANCH.  Performing a fresh checkout of branch '$BRANCH'. "
else
  echo "Using master branch"
  BRANCH=master
fi

if [ -n "$SOURCE" ]; then
  echo "Using source '$SOURCE' for install scripts. "
else
  echo "Using default source https://github.com/ivanthelad/ansible-azure."
  SOURCE=https://github.com/ivanthelad/ansible-azure
fi
rm -rf ansible-azure
git clone -b $BRANCH $SOURCE

if [ ! -f /exports/all  ]; then
 echo Expected a a file called 'all' under the path /exports/all exiting.
 exit 1
fi
temp=$(grep  '^resource_group_name:' /exports/all | awk '{ print $2}')
echo "Resource group name  $temp"
echo "copying found file /exports/all to /ansible-azure/group_vars/all"
cp /exports/all  /ansible-azure/group_vars/all
if [ ! -f /exports/azurekey.$temp ] && [ ! -f /exports/azurekey.$temp.pub ];  then
   echo "Files /exports/azurekey.$temp or /exports/azurekey.$temp.pub  not found!. Generating new key "
   ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""
    cp ~/.ssh/id_rsa /exports/azurekey.$temp
    cp ~/.ssh/id_rsa.pub /exports/azurekey.$temp.pub
    echo "Newly generated key can be found under directory /exports/, this directory should be mapped to a local mount point. if not done already then do this. "
    echo "WArning : if this is not done the key to access the openshift jumphost will be lost for good once the docker container shuts down "
#   cp ~/.ssh/id_rsa: /export/azurekey.$(grep  '^resource_group_name:' /ansible-azure/group_vars/all | awk '{ print $2}')
else
  if [ ! -f /exports/azurekey.$temp ]; then
     echo "Expected  public  key /exports/azurekey.$temp, please provide private and public key or none at all "
     exit 1
  fi
  if [ ! -f /exports/azurekey.$temp.pub ]; then
     echo "Expected  public  key /exports/azurekey.$temp.pub, please provide private and public key or none at all "
     exit 1
  fi
   echo public and private key found. reusing /exports/azurekey.$temp.pub, /exports/azurekey.$temp
   cp /exports/azurekey.$temp ~/.ssh/id_rsa
   cp /exports/azurekey.$temp.pub ~/.ssh/id_rsa.pub
fi

if [ -f /exports/inventory.$temp ]; then
 cp /exports/inventory.$temp /ansible-azure/inventory.$temp
fi

if [ -f /exports/known_hosts ]; then
 echo "found know_hosts file. copying to know_hosts. "
 cp /exports/known_hosts ~/.ssh/known_hosts
fi

touch ~/.ssh/known_hosts
sed -i "/sshkey: /c\sshkey: $(cat /root/.ssh/id_rsa.pub)" /ansible-azure/group_vars/all
ansible-playbook --forks=50 -i inventory.$temp  ansible-azure/playbooks/setupeverything.yml

echo "Ansible install succesful, copying content of dynamic inventory /ansible-azure/inventory.$temp to /export/"
cat /ansible-azure/ansible-azure/inventory.$temp
cp /ansible-azure/ansible-azure/inventory* /exports/
cp ~/.ssh/known_hosts /exports/

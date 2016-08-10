VMNAME="oscpvm"
GROUPNAME="oscp"
azure vm deallocate -g $GROUPNAME -n $VMNAME
azure vm generalize  -g $GROUPNAME -n $VMNAME
azure vm capture $GROUPNAME $VMNAME  oscpbase -t oscpbase.json

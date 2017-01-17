
#cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
STR_ACC="$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9'  | env LC_CTYPE=C tr '[:upper:]' '[:lower:]'  | fold -w 24 | head -n 1 )"
RSGROUP="temp2"
LOCATION="northeurope"
container="myimages"
#https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-upload-vhd
echo $STR_ACC
#azure group create $RSGROUP   $LOCATION
#sub="807fdc0-5705-4ceb-9129-3f5aac84b1f9"
#azure account set $sub
####  Create Storage account
azure storage account create $STR_ACC -l $LOCATION -g $RSGROUP --sku-name PLRS --kind Storage

## get key1 from storage account
key1="$(azure storage account keys list $STR_ACC  -g $RSGROUP  | grep key1  | awk '{ print $3}')"
echo "Gote key1 from storage account $key1 "
os="/Users/imckinle/Downloads/cfme-azure-5.7.0.17-1.x86_64fixed.vhd"
azure storage container create --account-name $STR_ACC  --account-key $key1 --container $container
azure storage blob upload --blobtype Page --account-name $STR_ACC --account-key $key1  --container $container  $os

#azure vm image create cloudforms --blob-url https://$STR_ACC.blob.core.windows.net/vhds/cloudforms.vhd  --os  $os

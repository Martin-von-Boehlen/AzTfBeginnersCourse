export AZUREHOST=<domain_prefix_from_azure>.cloudapp.azure.com
export AZUREUSR=adminuser@$AZUREHOST
export AZUREKP=~/.ssh/id_rsa_nginx
export AZPROJ=~/Projects/terraform/AzTfBeginnersCourse
cd $AZPROJ
alias aznxlogin="rm ~/.ssh/known_hosts; ssh -i $AZUREKP $AZUREUSR"

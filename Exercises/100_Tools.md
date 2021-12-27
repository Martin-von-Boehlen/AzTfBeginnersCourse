#
# Tools for your ~/bin can be found in ./100_Tools
#

## Setup
Last lines in .bash_profile
 + export PATH=$HOME/bin:$PATH

Last lines in ~/.bashrc
 + alias aznxlogin='rm ~/.ssh/known_hosts; ssh -i /home/mvb/.ssh/id_rsa_nginx <adminuser>@<fqdn_prefix>.<location>.cloudapp.azure.com'
 + export EDITOR=vi
 + . ~/bin/setNGINXhost.sh

## Tools list

Tool in ~/bin   | Purpose
--------------- | --------------------------------------
azmysql.sh      | Client login to remote MySQL database
aznxlogin       | Ssh into remote VM with nginx
gitlogin.sh     | Login to github
gitpush.sh      | Exec commit & push
login.tf        | Login to azure-cli. **Works only after login to GUI** 
setNGINXhost.sh | Source for variables


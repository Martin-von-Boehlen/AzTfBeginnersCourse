#
# Tools for your ~/bin can be dound in ./tools
#

# Setup tools

Last lines in .bash_profile
 + export PATH=$HOME/bin:$PATH

Last lines in ~/.bashrc
 + alias aznxlogin='rm ~/.ssh/known_hosts; ssh -i /home/mvb/.ssh/id_rsa_nginx <adminuser>@<fqdn_prefix>.<location>.cloudapp.azure.com'
 + export EDITOR=vi
 + . ~/bin/setNGINXhost.sh

Tool in ~/bin   | Purpose
--------------- | -------------
azmysql.sh      | Content Cell
aznxlogin       | Content Cell
gitlogin.sh     | Content Cell
gitpush.sh      | Content Cell
login.tf        | Content Cell
setNGINXhost.sh | Content Cell


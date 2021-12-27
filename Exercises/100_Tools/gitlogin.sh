#!/bin/bash
#
# only once per user do:
# git config --global user.name  <git_user_name>
# git config --global user.email <your_email_with_git>
#
# Use PRIVATE key id_rsa_github to match public key stored at github.com
git config --global core.sshcommand "ssh -i ~/.ssh/id_rsa_github -F /dev/null" 
#
# For each repo in local dir do: 
# git remote add origin git@github.com:Martin-von-Boehlen/AzTfBeginnersCourse.git
#
git config --list
#   
ssh -i ~/.ssh/id_rsa_github -T git@github.com
 

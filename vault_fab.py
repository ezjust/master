from fabric.operations import *
from fabric.contrib.console import confirm
from fabric.context_managers import * 
from fabric.operations import prompt

env.user = 'ez'
env.forward_agent = True
env.password="333333"

#Pay Attention!!!!! make sure that you have vault_conf_example and vault.conf, consul.conf supervisord files into your current directory


def vault_install():
    with shell_env(VAULT='0.9.1', CONSUL='1.0.2', main_conf="/etc/vault/main_conf"):
        sudo("apt-get update -y && apt-get install -y unzip")
	sudo("wget https://releases.hashicorp.com/vault -O vault_last_build.txt")
#If you'll need to setup the latest version just uncomment line below and the same line near consul installation, also comment hard version installation	
	#sudo("VAULT=$(cat vault_last_build.txt | grep -Eo 'vault/[0-9].[0-9].[0-9]' | cut -d '/' -f2 | sed -n 1p) && rm -rf vault_last_build.txt && wget https://releases.hashicorp.com/vault/\"$VAULT\"/vault_\"$VAULT\"_linux_amd64.zip -O /tmp/vault.zip")
        sudo("wget https://releases.hashicorp.com/vault/\"$VAULT\"/vault_\"$VAULT\"_linux_amd64.zip -O /tmp/vault.zip")
        sudo("cd /tmp/ && unzip -o vault.zip && chmod +x vault") 
        sudo("echo /usr/local/bin/ /usr/bin/ /sbin/ | xargs -n 1 cp /tmp/vault")
        sudo("mkdir -p /etc/vault/vault_files")
        cd("$PWD")  
        sudo("tail -n +2 vault_conf_example > \"$main_conf\" | chmod +x \"$main_conf\"")
        sudo("yes n | cp -i vault.conf /etc/supervisor/conf.d/")
#Here we install and run "consul" that uses in our scheme like vault storage
        sudo("wget https://releases.hashicorp.com/consul -O consul_last_build.txt")
        #sudo("CONSUL=$(cat consul_last_build.txt | grep -Eo 'consul/[0-9].[0-9].[0-9]' | cut -d '/' -f2 | sed -n 1p) && rm -rf consul_last_build.txt && wget https://releases.hashicorp.com/consul/\"$CONSUL\"/consul_\"$CONSUL\"_linux_amd64.zip -O /tmp/consul.zip")
        sudo("wget https://releases.hashicorp.com/consul/\"$CONSUL\"/consul_\"$CONSUL\"_linux_amd64.zip -O /tmp/consul.zip")
        sudo("cd /tmp/ && unzip -o consul.zip && chmod +x consul")
        sudo("echo /usr/local/bin/ /usr/bin/ /sbin/ | xargs -n 1 cp /tmp/consul")
	sudo("consul agent -server -bootstrap-expect 1 -data-dir /etc/vault/vault_files/ -bind 127.0.0.1 &")
        sudo("yes n | cp -i consul.conf /etc/supervisor/conf.d/")
def supervisor_update():
        sudo("supervisorctl reread")
        sudo("supervisorctl update") 
def vault_start():
    with shell_env(vault_var='grep -Fxq \"VAULT_ADDR = \'http://127.0.0.1:8200\'\" /etc/environment'):
        sudo ("if [ -z \"$vault_var\" ]; then echo \"VAULT_ADDR='http://127.0.0.1:8200'\" >> /etc/environment; else echo \"variable exist at /etc/environment\"; fi")
        sudo("vault server -config=\"$main_conf\"")

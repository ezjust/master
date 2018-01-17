from fabric.operations import *

#Pay Attention!!!!! make sure that you have vault_conf file into your current directory

def vault_install():
	local("apt-get update -y && apt-get install -y unzip | dpkg -l unzip")
	local("wget https://releases.hashicorp.com/vault -O vault_last_build.txt")
#If you'll need to setup the latest version just uncomment line below and the same line near consul installation, also comment hard version installation	
	#local("VAULT=$(cat vault_last_build.txt | grep -Eo 'vault/[0-9].[0-9].[0-9]' | cut -d '/' -f2 | sed -n 1p) && rm -rf vault_last_build.txt && wget https://releases.hashicorp.com/vault/\"$VAULT\"/vault_\"$VAULT\"_linux_amd64.zip -O /tmp/vault.zip")
	local("VAULT='0.9.1' && wget https://releases.hashicorp.com/vault/\"$VAULT\"/vault_\"$VAULT\"_linux_amd64.zip -O /tmp/vault.zip")
	local("cd /tmp/ && unzip -o vault.zip && chmod +x vault && echo /usr/local/bin/ /usr/bin/ /sbin/ | xargs -n 1 cp vault")
	local("main_conf='/etc/vault/main_conf' && mkdir -p /etc/vault/vault_files &&  tail -n +2 vault_conf_example > \"$main_conf\" | chmod +x \"$main_conf\"")
#Here we install and run "consul" that uses in our scheme like vault storage
	local("wget https://releases.hashicorp.com/consul -O consul_last_build.txt")
        #local("CONSUL=$(cat consul_last_build.txt | grep -Eo 'consul/[0-9].[0-9].[0-9]' | cut -d '/' -f2 | sed -n 1p) && rm -rf consul_last_build.txt && wget https://releases.hashicorp.com/consul/\"$CONSUL\"/consul_\"$CONSUL\"_linux_amd64.zip -O /tmp/consul.zip")
	local("CONSUL='1.0.2' && wget https://releases.hashicorp.com/consul/\"$CONSUL\"/consul_\"$CONSUL\"_linux_amd64.zip -O /tmp/consul.zip")
	local("cd /tmp/ && unzip -o consul.zip && chmod +x consul && echo /usr/local/bin/ /usr/bin/ /sbin/ | xargs -n 1 cp consul")
	local("consul agent -server -bootstrap-expect 1 -data-dir /etc/vault/vault_files/ -bind 127.0.0.1 &")
def vault_start():
	local("main_conf='/etc/vault/main_conf' && VAULT_ADDR='http://127.0.0.1:8200' && vault server -config=\"$main_conf\" & export VAULT_ADDR='http://127.0.0.1:8200' &")

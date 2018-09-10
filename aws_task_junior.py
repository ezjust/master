#BE SURE that you've install previously boto3, paramiko and awscli utilities
import boto3, os, botocore, sys, getpass
from time import sleep


#Insert credentials to AWS at the first time, for the nex times just check them
os.system("aws configure")

#Function to get dictionary values from keys
def find_key(obj, key):
    if key in obj:
        return obj[key]
    else:
        for k, v in obj.items():
            _key = None
            if isinstance(v, dict):
                _key = find_key(v, key)
            elif isinstance(v, list) and v:
                for v2 in v:
                    _key = find_key(v2, key)
                    if _key is not None:
                        return _key

#Create and save localy ssh key pair
ec2 = boto3.client('ec2')
users_path = "/USERS/"+getpass.getuser()+"/.ssh/test_key.pem"
if not os.path.exists(users_path):
    open(users_path, 'w').close()
outfile = open(users_path,'w+')
key_pair = ec2.create_key_pair(KeyName='test_key')
key_value = find_key(key_pair, 'KeyMaterial')
outfile.write(key_value)
os.system("chmod 400 %s") % users_path

#Create EC2 instance
ec2 = boto3.resource('ec2')
instances = ec2.create_instances(ImageId='ami-0bdb1d6c15a40392c', InstanceType='t2.micro', KeyName='test_key', MaxCount=1, MinCount=1)
instances[0].wait_until_running()
print("The new instance id = %s") % instances[0].id
in_id = instances[0].id

#If it doesn't exist, create security group
try:
   ec2 = boto3.client('ec2')
   sg = ec2.describe_security_groups(GroupNames=['2280group'])
   if sg:
    sg_id = find_key(sg, 'GroupId')
    print("The security group id = %s") % sg_id
except:
       ec2 = boto3.resource('ec2')
       newsg = ec2.create_security_group(GroupName="2280group", Description='test')
       newsg.authorize_ingress(IpProtocol="tcp", CidrIp="0.0.0.0/0", FromPort=80, ToPort=80)
       newsg.authorize_ingress(IpProtocol="tcp", CidrIp="0.0.0.0/0", FromPort=22, ToPort=22)
       print("The new security group id = %s") % newsg.id
       sg_id = newsg.id

#Change EC2 instance name and attach sg to it
ec2 = boto3.client('ec2')
ec2.modify_instance_attribute(InstanceId=in_id, Attribute='groupSet', Value=sg_id)
mach_name = raw_input('Enter machine name, in format Firstname/Lastname: ') #Specify custom name of the EC2 instance
ec2.create_tags(Resources=[in_id], Tags=[{'Key': 'Name', 'Value': mach_name}])

#Volume create and attach

vol = ec2.create_volume(AvailabilityZone='eu-west-1c', Size=1)

vol_id = find_key(vol, 'VolumeId')

#Loop for availability check

for i in range(0,5):
    vol_des = ec2.describe_volumes(VolumeIds=[vol_id])
    vol_st = find_key(vol_des, 'State')
    print vol_st
    if vol_st == 'available':
        att = ec2.attach_volume(InstanceId=in_id, Device='/dev/sde', VolumeId=vol_id)
        print("Volume has been attached")
        break
    elif i == 5:
        print("Waited for about 20 seconds, volume is not available to be attached, check the volume existance and state")
        exit(1)
    else:
        sleep(4)
        i = i+1

# ssh = paramiko.SSHClient()
# ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
# ssh.connect(, username='ubuntu', key_filename=os.path.expanduser('~/.ssh/test.pem'))
# stdin, stdout, stderr = ssh.exec_command('echo "TEST"')
# print stdout.readlines()
# ssh.close()




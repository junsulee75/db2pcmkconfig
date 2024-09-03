# DB2 HADR on pacemaker automated installation reference scripts  

These are fully automated scripts for creating DB2 HADR / pacemaker environment orignially on IBM internal provisioned test systems.  

Sharing these for users who are interested in automating the steps.

> Refer these for test systems only, not for production system configuration usage.    


> Tested for V11.5.5.0 ~ 11.5.8.0   

## Objectives 

These scripts on this repo had been my personal usage but sharing to public who might be interested in same purpose.   

The scripts assume the following things in advance. (In the fyre provisioned systems, these are already set.)   
- Passwordless ssh root user login is set between hosts.  
- For automated Db2 installation image download, I configured a web server containing donwloaded Db2 images to utilize curl.    
  You may use the same way with your own web server or just change config.ini and 2_db2_install.sh to set file path manually.   
   
- You know which VIP addess to use. (Need to figure out an unused IP)       

## Step

1. Prepare 3 Redhat 8.8 hosts.   
   
Example) Provision hosts from internal cloud environment such as fyre environment etc. [quickburn](https://fyre.svl.ibm.com/quick) .    
- Redhat 8.8    
- Size : Any   
- Quantaty : 3       

2. Download the script.    

By root user   

```
git clone https://github.com/junsulee75/db2pcmkconfig
```

> `git` command is installed in fyre VMs by default.
> If 'git' command does not exit, install manually by `yum -y install git`    

Or you can either download the files manually from the [git page](https://github.ibm.com/junsulee/purescale_on_fyre) and upload to the system.      

4. Edit the following line with the your hostnames and preferred VIP on `config.ini` file.    

```
##########################################################
## Must set area ! Only thing you need to configure manually in most cases
##########################################################

VIP=10.11.102.200     ## Virtual IP address to use. find an unused IP and set.
....

```    

> NOTE : Check the current IP addresses/subnet and specify VIP in the same subnet.  
> Also read config.ini and customize parameters as you preferred.   

5. Execute script

```
cd db2pcmkconfig
./0_osenv.sh   # install necessary packages including python
./setup.sh     # Full automated installation. 
```

Or either by one shot.  

```
cd db2pcmkconfig
./0_osenv.sh; ./setup.sh  
```

See the [terminal screen output](screen_output.md) how it looks like.      


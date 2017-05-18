# TOMCAT DEPLOY SCRIPT  
## HELP
Usage: deploy.sh -[OPTION]  
 ./deploy.sh -d [FRONT|AFTER]... Update the war file,front or after.  
 ./deploy.sh -r [FRONT|AFTER]... Restart tomcat services,front or after  
 ./deploy.sh -D ... Update the war file,front and after  
 ./deploy.sh -R ... Restart tomcat services,front and after  
 ./deploy.sh -[h|H]... Get help information.  
 
使用前需要确保各台tomcat服务器上已经安装zip  
脚本所在机器已经安装rsync、sshpass  
确保deylo.conf中定义的目录都已经创建并拥有读写权限  


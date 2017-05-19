# TOMCAT DEPLOY SCRIPT  
## HELP
Usage: deploy.sh -[OPTION]  
 ./deploy.sh -d [FRONT|AFTER]... Update the war file,front or after.  
 ./deploy.sh -r [FRONT|AFTER]... Restart tomcat services,front or after  
 ./deploy.sh -D ... Update the war file,front and after  
 ./deploy.sh -R ... Restart tomcat services,front and after  
 ./deploy.sh -[h|H]... Get help information.  
 
`-d`：发布war包；参数FRONT是发布前端war包，参数AFTER是发布后端war包。  
`-r`：重启tomcat服务；参数FRONT是重启前端节点的tomcat，参数AFTER是重启后端节点的tomcat。  
`-D`：发布war包；前端后端一起发布。  
`-R`：重启tomcat服务；前端后端都重启。  

## 使用需知：  

1. 使用前需要确保前端和后端节点服务器上已经安装`tar、gzip、rsync`等工具，可以使用语句`dpkg -s packet`检测  
2. 确保脚本所在机器已经安装`rsync`和`sshpass`  
如果未安装某工具，请使用语句`apt-get install packet`进行安装  
3. 确保`deylop.conf`中定义的目录都已经创建，并且`user`所指明的用户对`backup_dir`和`tomcat_base`拥有读写权限  
4. 运行脚本前，请先在发布节点执行ssh语句，登录各台前后端节点以更新host key，否则会在脚本使用过程中出现`Host key verification failed.`  

## deylop.conf
  
配置格式：`parameter="value" `  
使用`#`作为注释符  

各配置参数详解：  
`[FRONT]` --> 前端配置单元  
`[AFTER]` --> 后端配置单元  
`iplist` --> 节点IP列表   
`user` --> tomcat运行账户  
`password` --> tomcat运行账户的密码   
`tomcat_base` --> tomcat程序的安装目录路径  
`backup_dir` --> war文件的备份目录路径  
`src_dir` --> 要发布的war文件在当前机器上的目录路径



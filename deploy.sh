#!/bin/bash
NUM_TOTAL=$(egrep -v '^$|^#' deploy.conf|wc -l)
FRONT_NUM=$(egrep -v '^$|^#' deploy.conf|egrep -n '\[FRONT\]'|cut -d ':' -f 1)
AFTER_NUM=$(egrep -v '^$|^#' deploy.conf|egrep -n '\[AFTER\]'|cut -d ':' -f 1)

FRONT_S=`expr $FRONT_NUM + 1`
FRONT_E=`expr $AFTER_NUM - 1`
FRONT=$(egrep -v '^$|^#' deploy.conf|sed -n "$FRONT_S,$FRONT_E"p)

AFTER_S=`expr $AFTER_NUM + 1`
AFTER_E=$NUM_TOTAL
AFTER=$(egrep -v '^$|^#' deploy.conf|sed -n "$AFTER_S,$AFTER_E"p)


dependent(){
    if ! which $1 > /dev/null ;then
	echo "Please install [$1]!"
	exit 1
#    else
#	echo "[$1] is already installed."
    fi
}

argument(){
    NF_NUM=$(echo ""$1""|awk  '{print NF}');\
           for i in `seq 1 $NF_NUM`
           do
                           echo "$1"|awk "\$$i ~/$2/ {print \$$i}"
           done\
           |awk -F '[="]+' '{print $2}'
}

config(){
    USER=$(argument "$1" user)
    PASSWORD=$(argument "$1" password)
    IPLIST=$(argument "$1" iplist)
    TOMCAT_BASE=$(argument "$1" tomcat_base)
    BACKUP_DIR=$(argument "$1" backup_dir)
    SRC_DIR=$(argument "$1" src_dir)
}

bakcup(){
    for IP in $IPLIST
    do
	sshpass -p $PASSWORD ssh $USER@$IP "(
	    ZIPFILE_NUM=\$(ls $BACKUP_DIR/*.tar.gz 2> /dev/null |wc -l) ;
	    if [ \$ZIPFILE_NUM -ge 3 ]
	    then
		ls -t $BACKUP_DIR/*.tar.gz|tail -n \`expr \$ZIPFILE_NUM - 2\`|xargs rm -v
	    fi ;
	    cd $TOMCAT_BASE/webapps/ ;
	    echo -e '\nBEGIN BACKUP: ';
	    tar -czvf $BACKUP_DIR/Front-$(date +%Y%m%d%H%M).tar.gz *.war)";
	    echo -e '\nBEGIN RSYNC: '
    done
}

rsend(){
    for IP in $IPLIST
    do
	sshpass -p $PASSWORD rsync -avP $SRC_DIR/*.war $USER@$IP:$TOMCAT_BASE/webapps/
	#sshpass -p $PASSWORD|rsync -avP --delete $SRC_DIR/*.war $USER@$IP:$TOMCAT_BASE/webapps/
    done
}

details(){
    config "$1"
    IPLIST=$(echo $IPLIST|tr ',' ' ')
}

deploy(){
    details "$1"

    if [ ! -f $SRC_DIR/*.war ];then
	echo "No war files in the $SRC_DIR!"
	exit 1
    fi

    bakcup
    rsend
}

reboot(){
    details "$1"
    for IP in $IPLIST
    do
	#sshpass -p $PASSWORD ssh $USER@$IP "(source $TOMCAT_BASE/bin/cominfo_grsinfo_java_env.sh;$TOMCAT_BASE/bin/shutdown.sh)"
	#sshpass -p $PASSWORD ssh $USER@$IP "(source $TOMCAT_BASE/bin/cominfo_grsinfo_java_env.sh;$TOMCAT_BASE/bin/startup.sh)"
	sshpass -p $PASSWORD ssh $USER@$IP "(source $TOMCAT_BASE/bin/cominfo_grsinfo_java_env.sh;$TOMCAT_BASE/bin/shutdown.sh && sleep 5 && $TOMCAT_BASE/bin/startup.sh)"
    done
}

for packet in rsync sshpass 
do
    dependent $packet
done

if [ $# -eq 0 ];then
    echo "Usage: `basename $0` -[OPTION]"
    echo " ./`basename $0` -d [FRONT|AFTER]... Update the war file,front or after."
    echo " ./`basename $0` -r [FRONT|AFTER]... Restart tomcat services,front or after"
    echo " ./`basename $0` -D ... Update the war file,front and after"
    echo " ./`basename $0` -R ... Restart tomcat services,front and after"
    echo " ./`basename $0` -[h|H]... Get help information."

    exit 1
fi

while getopts 'd:Dr:RhH' OPTION
do
    case $OPTION in
    d)
        if [ $OPTARG = "FRONT" ];then
            deploy "$FRONT"
        elif [ $OPTARG = "AFTER" ];then
            deploy "$AFTER"
        else
            echo "The arguments error!"
	    echo "Can only choose the FRONT or AFTER."
            exit 1
        fi
        ;;
    D)
	echo -e '===================='
	echo -e '|BEGIN DEPLOY FRONT|'
	echo -e '===================='
	deploy "$FRONT"
	echo -e '\nEND DEPLOY FRONT'
	echo -e '\n\n=======================\n=======================\n\n'
	echo -e '===================='
	echo -e '|BEGIN DEPLOY AFTER|'
	echo -e '===================='
	deploy "$AFTER"
	echo -e '\nEND DEPLOY AFTER'
	;;
    r)
        if [ $OPTARG = "FRONT" ];then
	    reboot "$FRONT"
        elif [ $OPTARG = "AFTER" ];then
	    reboot "$AFTER"
        else
            echo "The arguments error!"
            echo "Can only choose the FRONT or AFTER."
            exit 1
        fi
        ;;
    R)
	reboot "$FRONT"
	reboot "$AFTER"
	;;
    h|H)
	echo "Usage: `basename $0` -[OPTION]"
	echo " ./`basename $0` -d [FRONT|AFTER]... Update the war file,front or after."
	echo " ./`basename $0` -r [FRONT|AFTER]... Restart tomcat services,front or after"
	echo " ./`basename $0` -D ... Update the war file,front and after"
	echo " ./`basename $0` -R ... Restart tomcat services,front and after"
	echo " ./`basename $0` -[h|H]... Get help information."
	;;
    *)
	echo "Usage: `basename $0` -[OPTION]"
	echo " ./`basename $0` -d [FRONT|AFTER]... Update the war file,front or after."
	echo " ./`basename $0` -r [FRONT|AFTER]... Restart tomcat services,front or after"
	echo " ./`basename $0` -D ... Update the war file,front and after"
	echo " ./`basename $0` -R ... Restart tomcat services,front and after"
	echo " ./`basename $0` -[h|H]... Get help information."
	exit 1
	;;
    esac
done

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

backup(){
    SRCWARFILE=$(cd $SRC_DIR/;ls *.war)

    sshpass -p $PASSWORD ssh $USER@$IP "(
    for i in $SRCWARFILE
    do
	BCKFILE_NUM=\$(ls $BACKUP_DIR/\$i-* 2> /dev/null |wc -l) ;
	    if [ \$BCKFILE_NUM -ge 3 ]
	    then
		ls -t $BACKUP_DIR/\$i-*|tail -n \`expr \$BCKFILE_NUM - 2\`|xargs rm -v
	    fi;
    done;


    for i in $SRCWARFILE
    do
	if [ -f $TOMCAT_BASE/webapps/\$i ];then
	    mv -v $TOMCAT_BASE/webapps/\$i $BACKUP_DIR/\$i-\$(date +%Y%m%d%H%M)
	    rm -rf $TOMCAT_BASE/webapps/\$(basename \$i .war)
	    #cp -v $TOMCAT_BASE/webapps/\$i $BACKUP_DIR/\$i-\$(date +%Y%m%d%H%M)
	fi
    done)"
}

rsend(){
    sshpass -p $PASSWORD rsync -avP $SRC_DIR/*.war $USER@$IP:$TOMCAT_BASE/webapps/
    #sshpass -p $PASSWORD|rsync -avP --delete $SRC_DIR/*.war $USER@$IP:$TOMCAT_BASE/webapps/
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

    for IP in $IPLIST
    do
	echo -e "\n================"
	echo -e "-\033[44;33m$IP\033[0m-"
	echo -e '\nBEGIN BACKUP: ';
	backup
	echo -e '\nBEGIN RSYNC: '
	rsend
    done

    echo -e '\n\n'
    read -p 'Whether to delete the source war file? (YES/NO): ' DECISION
    DECISION=${DECISION-"NO"}

    while [ ! $DECISION = 'YES' ] && [ ! $DECISION = 'NO' ]
    do
	read -p 'Whether to delete the source war file? (YES/NO): ' DECISION
    done

    case $DECISION in
    YES)
        rm -rvf $SRC_DIR/*.war
        ;;
    *)
        echo 'Didn'"'"'t do anything!'
        ;;
    esac
}

reboot(){
    details "$1"
    for IP in $IPLIST
    do
	echo -e "-\033[44;33m$IP\033[0m-"
	#sshpass -p $PASSWORD ssh $USER@$IP "(source $TOMCAT_BASE/bin/cominfo_grsinfo_java_env.sh;$TOMCAT_BASE/bin/shutdown.sh)"
	#sshpass -p $PASSWORD ssh $USER@$IP "(source $TOMCAT_BASE/bin/cominfo_grsinfo_java_env.sh;$TOMCAT_BASE/bin/startup.sh)"
	#sshpass -p $PASSWORD ssh $USER@$IP "(source $TOMCAT_BASE/bin/cominfo_grsinfo_java_env.sh;$TOMCAT_BASE/bin/shutdown.sh && sleep 5 && $TOMCAT_BASE/bin/startup.sh)"
        #sshpass -p $PASSWORD ssh $USER@$IP "($TOMCAT_BASE/bin/startup.sh; killall java && sleep 5 && $TOMCAT_BASE/bin/startup.sh)"
        sshpass -p $PASSWORD ssh $USER@$IP "(ps aux|grep cominfo|grep tomcat|grep java|awk '{print \$2}'|xargs -i kill {})"
	sleep 5
        sshpass -p $PASSWORD ssh $USER@$IP "$TOMCAT_BASE/bin/startup.sh"
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
	    echo -e '===================='
	    echo -e '|BEGIN DEPLOY \033[45;37mFRONT\033[0m|'
	    echo -e '===================='
            deploy "$FRONT"
	    echo -e '=================='
	    echo -e '|END DEPLOY \033[45;37mFRONT\033[0m|'
	    echo -e '=================='
        elif [ $OPTARG = "AFTER" ];then
	    echo -e '===================='
	    echo -e '|BEGIN DEPLOY \033[45;37mAFTER\033[0m|'
	    echo -e '===================='
	    deploy "$AFTER"
	    echo -e '=================='
	    echo -e '|END DEPLOY \033[45;37mFRONT\033[0m|'
	    echo -e '=================='
        else
            echo "The arguments error!"
	    echo "Can only choose the FRONT or AFTER."
            exit 1
        fi
        ;;
    D)
	echo -e '===================='
	echo -e '|BEGIN DEPLOY \033[45;37mFRONT\033[0m|'
	echo -e '===================='
	deploy "$FRONT"
	echo -e '=================='
	echo -e '|END DEPLOY \033[45;37mFRONT\033[0m|'
	echo -e '=================='
	echo -e '\n\n=======================\033[41;37mThe front end, start the backend!\033[0m=======================\n\n'
	echo -e '===================='
	echo -e '|BEGIN DEPLOY \033[45;37mAFTER\033[0m|'
	echo -e '===================='
	deploy "$AFTER"
	echo -e '=================='
	echo -e '|END DEPLOY \033[45;37mAFTER\033[0m|'
	echo -e '=================='
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

#!/bin/bash

OS=`uname`

if [[ "$OS" =~ "Darwin" ]]; then
    OS=2
else
    OS=1
fi

function kill_all()
{
  if [ $OS == 2 ]; then
    killall -9 $1
  else
    killall -9 -q $1
  fi
}

function netstat_port()
{
  if [ $OS == 2 ]; then
    netstat -anL
  else
    netstat -lpn
  fi
}

#公共函数
function LOG_ERROR()
{
	if (( $# < 1 ))
	then
		echo -e "\033[33m usesage: LOG_ERROR msg \033[0m";
	fi
	
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);

    msg="${msg} $@";

	echo -e "\033[31m $msg \033[0m";	
}

function LOG_WARNING()
{
	if (( $# < 1 ))
	then
		echo -e "\033[33m usesage: LOG_WARNING msg \033[0m";
	fi
	
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);

    msg="${msg} $@";

	echo -e "\033[33m $msg \033[0m";	
}

function LOG_DEBUG()
{
	if (( $# < 1 ))
	then
		LOG_WARNING "Usage: LOG_DEBUG logmsg";
	fi
	
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);

    msg="${msg} $@";

 	echo -e "\033[40;37m $msg \033[0m";	
}

function LOG_INFO()
{
	if (( $# < 1 ))
	then
		LOG_WARNING "Usage: LOG_INFO logmsg";
	fi
	
	local msg=$(date +%Y-%m-%d" "%H:%M:%S);
	
	for p in $@
	do
		msg=${msg}" "${p};
	done
	
	echo -e "\033[32m $msg \033[0m"  	
}

if (( $# < 8 ))
then
    echo "$0 MYSQL_IP MYSQL_PASSWORD  HOSTIP REBUILD(false[default]/true) SLAVE(false[default]/true) MYSQL_USER MYSQL_PORT TARS_PATH";
    exit 1
fi

MYSQLIP=$1
PASS=$2
HOSTIP=$3
REBUILD=$4
SLAVE=$5
USER=$6
PORT=$7
TARS_PATH=$8

if [ "${SLAVE}" != "true" ]; then
    SLAVE="false"
fi

if [ "${SLAVE}" != "true" ]; then
    TARS="tarsregistry tarsAdminRegistry tarsconfig tarsnode tarsnotify tarsproperty tarsqueryproperty tarsquerystat tarsstat tarslog tarspatch"
else
    TARS="tarsregistry tarsconfig tarsnode tarsnotify tarsproperty tarsqueryproperty tarsquerystat tarsstat"
fi

if [ "${TARS_PATH}" == "" ]; then
    TARS_PATH=/usr/local/app/tars
fi

mkdir -p ${TARS_PATH}

TARSALL="tarsregistry tarsAdminRegistry tarsconfig tarsnode tarslog tarsnotify  tarspatch  tarsproperty tarsqueryproperty tarsquerystat  tarsstat"

WORKDIR=$(cd $(dirname $0); pwd)

MYSQL_TOOL=${WORKDIR}/mysql-tool

LOG_INFO "====================================================================";
LOG_INFO "===**********************tars-install*****************************===";
LOG_INFO "====================================================================";

#输出配置信息
LOG_DEBUG "===>print config info >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>";
LOG_DEBUG "PARAMS:        "$*
LOG_DEBUG "MYSQLIP:       "$MYSQLIP 
LOG_DEBUG "USER:          "$USER
LOG_DEBUG "PASS:          "$PASS
LOG_DEBUG "PORT:          "$PORT
LOG_DEBUG "HOSTIP:        "$HOSTIP
LOG_DEBUG "WORKDIR:       "$WORKDIR
LOG_DEBUG "SLAVE:         "${SLAVE}
LOG_DEBUG "REBUILD:       "${REBUILD}
LOG_DEBUG "TARS_PATH:     "${TARS_PATH}
LOG_DEBUG "===<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< print config info finish.\n";

################################################################################
#killall all tars-servers
for var in $TARSALL;
do
    kill_all ${var}
done
for var in $TARSALL;
do
    kill_all ${var}
done

################################################################################
#check port
PORTS=(18993 18793 18693 18193 18593 18493 18393 18293 12000 19385 17890 17891 3000 3001)
for P in $PORTS;
do
    NETINFO=$(netstat_port)

    RESULT=`echo ${NETINFO} | grep ${HOSTIP}:${P}`
    if [ "$RESULT" != "" ]; then
        LOG_ERROR ${HOSTIP}:${P}" confict!!"
        exit 1
    fi

    RESULT=`echo ${NETINFO} | grep 127.0.0.1:${P}`
    if [ "$RESULT" != "" ]; then
        LOG_ERROR 127.0.0.1:${P}" confict!!"
        exit 1
    fi
done

################################################################################

function check_mysql()
{
    ${MYSQL_TOOL} --host=${MYSQLIP} --user="$1" --pass="$2" --port=${PORT} --check

    if [ $? == 0 ]; then
        LOG_INFO "mysql is alive"
        return
    fi

    LOG_ERROR "check mysql is not alive: ${MYSQL_TOOL} --host=${MYSQLIP} --user="$1" --pass="$2" --port=${PORT} --check"

    exit 1
}
################################################################################
#check mysql

check_mysql ${USER} ${PASS}

function exec_mysql_has()
{
    echo "${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --has=$1"
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --has=$1

    ret=$?
    LOG_DEBUG "exec_mysql_has $1, ret: $ret"

    return $ret
}

function exec_mysql_script()
{
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --sql="$1"

    ret=$?
    LOG_DEBUG "exec_mysql_script $1, ret: $ret"  

    return $ret
}

function exec_mysql_sql()
{
    echo "${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --db=$1 --file=$2"
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --db=$1 --file=$2

    ret=$?

    LOG_DEBUG "exec_mysql_sql $1 $2, ret: $ret"  

    return $ret
}

function exec_mysql_template()
{
    echo "${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --parent=$1 --template=$2 --profile=$3"
    ${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --charset=utf8 --db=db_tars --parent=$1 --template=$2 --profile=$3

    ret=$?

    LOG_DEBUG "exec_mysql_template $1 $2, ret: $ret"  

    return $ret
}

################################################################################
#check db_tars
cp -rf ${WORKDIR}/web/sql/*.sql ${WORKDIR}/framework/sql/
cp -rf ${WORKDIR}/web/demo/sql/*.sql ${WORKDIR}/framework/sql/

cp -rf ${WORKDIR}/framework/sql ${WORKDIR}/sql.tmp

if [ $OS == 2 ]; then
    #mac
    sed -i "" "s/localip.tars.com/$HOSTIP/g" `grep localip.tars.com -rl ${WORKDIR}/sql.tmp/*`
    sed -i "" "s/db.tars.com/${MYSQLIP}/g" `grep db.tars.com -rl ${WORKDIR}/sql.tmp/*`
    sed -i "" "s/3306/${PORT}/g" `grep 3306 -rl ${WORKDIR}/sql.tmp/*`
else
    sed -i "s/localip.tars.com/$HOSTIP/g" `grep localip.tars.com -rl ${WORKDIR}/sql.tmp/*`
    sed -i "s/db.tars.com/${MYSQLIP}/g" `grep db.tars.com -rl ${WORKDIR}/sql.tmp/*`
    sed -i "s/3306/${PORT}/g" `grep 3306 -rl ${WORKDIR}/sql.tmp/*`
fi

if [ "$REBUILD" == "true" ]; then
    exec_mysql_script "drop database if exists db_tars"
    exec_mysql_script "drop database if exists tars_stat"
    exec_mysql_script "drop database if exists tars_property"
    exec_mysql_script "drop database if exists db_tars_web"    
    exec_mysql_script "drop database if exists db_user_system"    
    exec_mysql_script "drop database if exists db_cache_web"
fi

cd ${WORKDIR}/sql.tmp

MYSQL_VER=`${MYSQL_TOOL} --host=${MYSQLIP} --user=${USER} --pass=${PASS} --port=${PORT} --version`
#MYSQL_VER=`echo $MYSQL_VER | cut -d' ' -f2`
MYSQL_GRANT="SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, PROCESS, REFERENCES, INDEX, ALTER, SHOW DATABASES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE"

echo "mysql version is: $MYSQL_VER"

if [ `echo $MYSQL_VER|grep ^8.` ]; then
    exec_mysql_script "CREATE USER 'tars'@'%' IDENTIFIED WITH mysql_native_password BY 'tars2015';"
    exec_mysql_script "GRANT ${MYSQL_GRANT} ON *.* TO 'tars'@'%' WITH GRANT OPTION;"
    exec_mysql_script "CREATE USER 'tars'@'localhost' IDENTIFIED WITH mysql_native_password BY 'tars2015';"
    exec_mysql_script "GRANT ${MYSQL_GRANT} ON *.* TO 'tars'@'localhost' WITH GRANT OPTION;"
    exec_mysql_script "CREATE USER 'tars'@'${HOSTIP}' IDENTIFIED WITH mysql_native_password BY 'tars2015';"
    exec_mysql_script "GRANT ${MYSQL_GRANT} ON *.* TO 'tars'@'${HOSTIP}' WITH GRANT OPTION;"
fi

if [ `echo $MYSQL_VER|grep ^5.7` ]; then
    exec_mysql_script "set global validate_password_policy=LOW;"
fi

if [ `echo $MYSQL_VER|grep ^5.` ]; then
    exec_mysql_script "grant ${MYSQL_GRANT} on *.* to 'tars'@'%' identified by 'tars2015' with grant option;"
    if [ $? != 0 ]; then
        LOG_DEBUG "grant error, exit." 
        exit 1
    fi

    exec_mysql_script "grant ${MYSQL_GRANT} on *.* to 'tars'@'localhost' identified by 'tars2015' with grant option;"
    exec_mysql_script "grant ${MYSQL_GRANT} on *.* to 'tars'@'$HOSTIP' identified by 'tars2015' with grant option;"
    exec_mysql_script "flush privileges;"
fi

################################################################################
#check mysql

check_mysql tars tars2015

################################################################################
exec_mysql_has "db_tars"
if [ $? != 0 ]; then

    LOG_INFO "no db_tars exists, begin build db_tars..."  

    LOG_INFO "modify ip in sqls:${WORKDIR}/framework/sql";

    LOG_INFO "create database (db_tars, tars_stat, tars_property, db_tars_web)";

    exec_mysql_script "create database db_tars"
    exec_mysql_script "create database tars_stat"
    exec_mysql_script "create database tars_property"
    exec_mysql_script "create database db_tars_web"

    exec_mysql_sql db_tars db_tars.sql
    exec_mysql_sql db_tars_web db_tars_web.sql
fi

exec_mysql_has "db_cache_web"
if [ $? != 0 ]; then
    LOG_INFO "no db_cache_web exists, begin build db_cache_web..."
    exec_mysql_script "create database db_cache_web"

    exec_mysql_sql db_cache_web db_cache_web.sql
fi

function update_template()
{
    LOG_INFO "create t_profile_template";

    # sqlFile="tmp.sql"

    # echo > $sqlFile
    echo "truncate t_profile_template;"

    function read_dir(){
        for template_name in $(ls template)
        do
            echo $template_name #在此处处理文件即可

            # profile=$(cat template/${template_name} | sed "s/'/\\\'/g" | sed "s/3306/${PORT}/g" )

            parent_template="tars.default"
            if [ "$template_name" == "tars.springboot" ]; then
                parent_template="tars.tarsjava.default"
            elif [ "$template_name" == "tars.tarsAdminRegistry" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsconfig" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsnotify" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsproperty" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsqueryproperty" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsstat" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsquerystat" ]; then
                parent_template="tars.framework-db"
            elif [ "$template_name" == "tars.tarsregistry" ]; then
                parent_template="tars.framework-db"
            fi

            exec_mysql_template $parent_template $template_name template/${template_name} 

        done
    }

    read_dir
}

update_template

exec_mysql_has "db_user_system"
if [ $? != 0 ]; then
    LOG_INFO "db_user_system not exists, begin build db_user_system..."  

    exec_mysql_script "create database db_user_system"

    exec_mysql_sql db_user_system db_user_system.sql
fi

if [ "$SLAVE" != "true" ]; then
    #current master server info
    LOG_INFO "create master servers";

    exec_mysql_sql db_tars tars_servers_master.sql
fi

#current server info
LOG_INFO "create inner servers";
exec_mysql_sql db_tars tars_servers.sql

#current node info
LOG_INFO "create node info";
exec_mysql_sql db_tars tars_node_init.sql

rm -rf ${WORKDIR}/sql.tmp

cd ${WORKDIR}

################################################################################
function update_path() {

    cd $2 

    LOG_INFO "update install path: [conf/tars.$1.config.conf]";

    if [ $OS == 2 ]; then
        #mac
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl conf/tars.$1.config.conf`
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/execute.sh`
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/start.sh`
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/stop.sh`
        if [ -f util/check.sh ]; then
            sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/check.sh`
        fi
    else
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl conf/tars.$1.config.conf`
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/execute.sh`
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/start.sh`
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/stop.sh`
        if [ -f util/check.sh ]; then
            sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl util/check.sh`
        fi
    fi

}

function update_script() {
    if [ $OS == 2 ]; then
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl ${TARS_PATH}/check.sh`
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl ${TARS_PATH}/tars-start.sh`
        sed -i "" "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl ${TARS_PATH}/tars-stop.sh`
    else
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl ${TARS_PATH}/check.sh`
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl ${TARS_PATH}/tars-start.sh`
        sed -i "s#TARS_PATH#${TARS_PATH}#g" `grep TARS_PATH -rl ${TARS_PATH}/tars-stop.sh`
    fi
}
################################################################################
#check framework

# LOG_INFO "copy ${WORKDIR}/framework/conf/ to tars path:${TARS_PATH}";
LOG_INFO "copy ${WORKDIR}/framework/util/ to tars path:${TARS_PATH}";

cp -rf ${WORKDIR}/framework/util-linux/*.sh ${TARS_PATH}
chmod a+x ${TARS_PATH}/*.sh

rm -rf ${WORKDIR}/framework-tmp
mkdir -p ${WORKDIR}/framework-tmp

for var in $TARSALL;
do
    cp -rf ${WORKDIR}/framework/servers/${var} ${WORKDIR}/framework-tmp
    cp -rf ${WORKDIR}/framework/conf/${var} ${WORKDIR}/framework-tmp
    cp -rf ${WORKDIR}/framework/util-linux/${var} ${WORKDIR}/framework-tmp
done

for var in $TARS;
do
    update_path ${var} "${WORKDIR}/framework-tmp/${var}"

    cp -rf ${WORKDIR}/framework-tmp/${var} ${TARS_PATH}
done

#update script
update_script

################################################################################

mkdir -p ${TARS_PATH}/../web/files/

cd ${WORKDIR}/framework-tmp

for var in $TARSALL;
do
    echo "tar czf ${var}.tgz ${var}"
    tar czf ${var}.tgz ${var}
    cp -rf ${var}.tgz ${TARS_PATH}/../web/files/
    rm -rf ${var}.tgz
done

cd ${WORKDIR}

rm -rf ${WORKDIR}/framework-tmp

cp ${WORKDIR}/tools/install.sh ${TARS_PATH}/../web/files/

################################################################################

function update_conf() {

    cd $2 
    LOG_INFO "update server config: [conf/tars.$1.config.conf]";

    if [ $OS == 2 ]; then
        #mac
        sed -i "" "s/localip.tars.com/$HOSTIP/g" `grep localip.tars.com -rl conf/tars.$1.config.conf`
        sed -i "" "s/db.tars.com/$MYSQLIP/g" `grep db.tars.com -rl conf/tars.$1.config.conf`
        sed -i "" "s/registry.tars.com/$HOSTIP/g" `grep registry.tars.com -rl conf/tars.$1.config.conf`
        sed -i "" "s/3306/$PORT/g" `grep 3306 -rl conf/tars.$1.config.conf`
        sed -i "" "s/registryAddress/tcp -h $HOSTIP -p 17890/g" `grep registryAddress -rl conf/tars.$1.config.conf`
        sed -i "" "s/localip.tars.com/$HOSTIP/g" `grep localip.tars.com -rl util/execute.sh`
    else
        sed -i "s/localip.tars.com/$HOSTIP/g" `grep localip.tars.com -rl conf/tars.$1.config.conf`
        sed -i "s/db.tars.com/$MYSQLIP/g" `grep db.tars.com -rl conf/tars.$1.config.conf`
        sed -i "s/registry.tars.com/$HOSTIP/g" `grep registry.tars.com -rl conf/tars.$1.config.conf`
        sed -i "s/3306/$PORT/g" `grep 3306 -rl conf/tars.$1.config.conf`
        sed -i "s/registryAddress/tcp -h $HOSTIP -p 17890/g" `grep registryAddress -rl conf/tars.$1.config.conf`
        sed -i "s/localip.tars.com/$HOSTIP/g" `grep localip.tars.com -rl util/execute.sh`
    fi

}

#start server
for var in $TARS;
do
   if [ ! -d ${TARS_PATH}/${var} ]; then
       LOG_ERROR "${TARS_PATH}/${var} not exist."
       exit 1 
   fi

    update_conf ${var} ${TARS_PATH}/${var}

    LOG_DEBUG "remove old version config: rm -rf ${TARS_PATH}/tarsnode/data/tars.${var}/conf/tars.${var}.config.conf"

    rm -rf ${TARS_PATH}/tarsnode/data/tars.${var}/conf/tars.${var}.config.conf

    LOG_DEBUG ${TARS_PATH}/${var}/util/start.sh
    sh ${TARS_PATH}/${var}/util/start.sh > /dev/null
done

################################################################################

${WORKDIR}/web-install.sh ${MYSQLIP} ${HOSTIP} ${SLAVE} ${PORT} ${TARS_PATH}


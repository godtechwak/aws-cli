#!/bin/sh

:<<'END'

==============================================================================
Description
-- Aurora MySQL Engine Upgrade to 8.0.mysql_aurora.3.03.01

==============================================================================

END

#password input function
function readPassword(){
    local PW_PROMPT="$1"
    local PW_TYPE="$2"
    local PW_INPUT=""
    local AUX_PROMPT=""
    while [ -z "${PW_INPUT}" ]; do
        if [ ${PW_TYPE} = 1 ]; then
	    read -p "${PW_PROMPT} (${AUX_PROMPT}) : "$'\n' -s PW_INPUT
	elif [ ${PW_TYPE} = 2 ]; then
	    read -p "${PW_PROMPT} (${AUX_PROMPT}) : "$'\n' PW_INPUT
	        case ${PW_INPUT} in
    	        "kr")
        	        PW_INPUT='ap-northeast-2'
        	        ;;
    		      "jp")
        		      PW_INPUT='ap-northeast-1'
        	        ;;
    		      "uk")
        		      PW_INPUT='eu-west-2'
        		      ;;
    		      "ca")
        		      PW_INPUT='ca-central-1'
        		      ;;
		      esac
	elif [ ${PW_TYPE} = 3 ]; then
	    read -p "${PW_PROMPT} (${AUX_PROMPT}) : "$'\n' PW_INPUT
	fi

    if [ -z "${PW_INPUT}" ]; then
        AUX_PROMPT="--> AGAIN !!, Password must be not empty string"
    else
        AUX_PROMPT=""
    fi

    echo ${PW_INPUT}
    done
}

## admin password
ADMIN_PASSWORD=$( readPassword "> ADMIN_PASSWORD" "1" )
REGION=$( readPassword "> REGION(kr/jp/uk/ca)" "2" )
ENVIRONMENT=$( readPassword "> ENVIRONMENT(prod/alpha)" "3" )

if [ ${ENVIRONMENT} = 'prod' ]; then
    db_cluster_list=`MYSQL_PWD=${ADMIN_PASSWORD} mysql -h{DB서버주소} -u{계정명} -e "{SQL쿼리}"`
elif [ ${ENVIRONMENT} = 'dev' ]; then
    db_cluster_list=`MYSQL_PWD=${ADMIN_PASSWORD} mysql -h{DB서버주소} -u{계정명} -e "{SQL쿼리}"`
fi

IFS=$'\n'

for rLIST in ${db_cluster_list};do
    if [ ${rLIST} = 'prod' ] || [ ${rLIST} = 'cluster_name' ]; then
        continue
    fi
    echo ${rLIST}

    #### alpha 작업할 때 주석 해제 ####
    #aws-vault exec {dir} -- aws rds modify-db-cluster --db-cluster-identifier ${rLIST} --engine-version 8.0.mysql_aurora.3.03.1 --apply-immediately > /tmp/${rLIST}_upgrade.log

    #### production 작업할 때 주석 해제 ####
    #aws-vault exec {dir} -- aws rds modify-db-cluster --db-cluster-identifier ${rLIST} --engine-version 8.0.mysql_aurora.3.03.1 --apply-immediately > /tmp/${rLIST}_upgrade.log

    if [ $? -eq 0 ]; then
        echo "${rLIST} --> Upgrade success"
    else
        echo "${rLIST} --> Upgrade ERROR: $?"
        break;
    fi
done

echo "All mysql cluster upgrade loop is done!!!"

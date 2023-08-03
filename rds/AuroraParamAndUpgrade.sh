#!/bin/sh

# Input the option
function readInput(){
    local PROMPT="$1"
    local INPUT_TYPE="$2"
    local REAL_INPUT=""
    local AUX_PROMPT=""
    while [ -z "${REAL_INPUT}" ]; do
        if [ ${INPUT_TYPE} = 1 ]; then ## REGION
            read -p "${PROMPT} (${AUX_PROMPT}) : "$'\n' REAL_INPUT
                case ${REAL_INPUT} in
                    "kr")
                        REAL_INPUT='ap-northeast-2'
                        ;;
                    "jp")
                        REAL_INPUT='ap-northeast-1'
                        ;;
                    "uk")
                        REAL_INPUT='eu-west-2'
                        ;;
                    "ca")
                        REAL_INPUT='ca-central-1'
                        ;;
                       *)
                        REAL_INPUT="error"
                        ;;
                esac

            if [ ${REAL_INPUT} = "error" ]; then
                REAL_INPUT=""
                AUX_PROMPT="--> AGAIN !!, Input the corrent region"
            fi
        elif [ ${INPUT_TYPE} = 2 ]; then ## WORK_TYPE
            read -p "${PROMPT} (${AUX_PROMPT}) : "$'\n' REAL_INPUT

            if [[ ${REAL_INPUT} != "param" ]] && [[ ${REAL_INPUT} != "upgrade" ]]; then
                REAL_INPUT=""
                AUX_PROMPT="--> AGAIN !!, Input the corrent work type"
            fi
        fi

        echo ${REAL_INPUT}
    done
}

# Enable an Aurora parameter
function enableAuroraParam(){
    local REAL_VAULT_REGION="$1"
    local REAL_DB_CLUSTER_LIST="$2"

    IFS=$'\n'

    ## Performance_schema 활성화
    for rREAL_DB_CLUSTER_LIST in ${REAL_DB_CLUSTER_LIST};do

        echo ${rREAL_DB_CLUSTER_LIST}
        ## 작업할 때 주석해제
        ## aws-vault exec ${REAL_VAULT_REGION} -- aws rds modify-db-cluster-parameter-group --db-cluster-parameter-group-name "${rREAL_DB_CLUSTER_LIST}-cluster-my80" --parameters "ParameterName=performance_schema,ParameterValue=1,ApplyMethod=pending-reboot" "ParameterName=performance_schema_accounts_size,ParameterValue=0,ApplyMethod=pending-reboot" "ParameterName=performance_schema_hosts_size,ParameterValue=0,ApplyMethod=pending-reboot" "ParameterName=performance_schema_users_size,ParameterValue=0,ApplyMethod=pending-reboot"

        if [ $? -eq 0 ]; then
            echo "${rREAL_DB_CLUSTER_LIST} --> Parameter modification SUCCESS"
        else
            echo "${rREAL_DB_CLUSTER_LIST} --> Parameter modification ERROR: $?"
            exit
        fi
    done

}

# Execute an Aurora upgrade
function execAuroraUpgrade(){
    local REAL_VAULT_REGION="$1"
    local REAL_DB_CLUSTER_LIST="$2"

    IFS=$'\n'

    ## Aurora MySQL Engine Upgrade
    for rREAL_DB_CLUSTER_LIST in ${REAL_DB_CLUSTER_LIST};do

        echo ${rREAL_DB_CLUSTER_LIST}
        ## 작업할 때 주석해제
        ## aws-vault exec ${REAL_VAULT_REGION} -- aws rds modify-db-cluster --db-cluster-identifier ${REAL_DB_CLUSTER_LIST} --engine-version 8.0.mysql_aurora.3.04.0 --apply-immediately > /tmp/${REAL_DB_CLUSTER_LIST}_upgrade.log

        if [ $? -eq 0 ]; then
            echo "${rREAL_DB_CLUSTER_LIST} --> Upgrade SUCCESS"
        else
            echo "${rREAL_DB_CLUSTER_LIST} --> Upgrade ERROR: $?"
            exit
        fi
    done
}

echo "==========================================================="
echo "** Aurora MySQL Performance_schema modifying & upgrading **"
echo "==========================================================="
REGION=$( readInput "> REGION(kr/jp/uk/ca)" "1" )
WORK_TYPE=$( readInput "> WORK_TYPE(param/upgrade)" "2" )

if [ ${REGION} = 'ap-northeast-2' ]; then
    VAULT_REGION='test/prod/kr'
    db_cluster_list=$(cat ./db_cluster_list_kr.txt)
    if [ ${WORK_TYPE} = 'param' ]; then
        enableAuroraParam "${VAULT_REGION}" "${db_cluster_list}"
    elif [ ${WORK_TYPE} = 'upgrade' ]; then
        execAuroraUpgrade "${VAULT_REGION}" "${db_cluster_list}"
    else
        exit
    fi
elif [ ${REGION} = 'ap-northeast-1' ]; then
    VAULT_REGION='test/prod/jp'
    db_cluster_list=$(cat ./db_cluster_list_jp.txt)
    if [ ${WORK_TYPE} = 'param' ]; then
        enableAuroraParam "${VAULT_REGION}" "${db_cluster_list}"
    elif [ ${WORK_TYPE} = 'upgrade' ]; then
        execAuroraUpgrade "${VAULT_REGION}" "${db_cluster_list}"
    else
        exit
    fi
elif [ ${REGION} = 'eu-west-2' ]; then
    VAULT_REGION='test/prod/uk'
    db_cluster_list=$(cat ./db_cluster_list_uk.txt)
    if [ ${WORK_TYPE} = 'param' ]; then
        enableAuroraParam "${VAULT_REGION}" "${db_cluster_list}"
    elif [ ${WORK_TYPE} = 'upgrade' ]; then
        execAuroraUpgrade "${VAULT_REGION}" "${db_cluster_list}"
    else
        exit
    fi
elif [ ${REGION} = 'ca-central-1' ]; then
    VAULT_REGION='test/prod/ca'
    db_cluster_list=$(cat ./db_cluster_list_ca.txt)
    if [ ${WORK_TYPE} = 'param' ]; then
        enableAuroraParam "${VAULT_REGION}" "${db_cluster_list}"
    elif [ ${WORK_TYPE} = 'upgrade' ]; then
        execAuroraUpgrade "${VAULT_REGION}" "${db_cluster_list}"
    else
        exit
    fi
fi

#########
## 한국 ##
#########
#!/bin/sh

read -p "Do you execute Aurora Snapshot in Seoul?(y or n) :"$'\n' SNAPSHOT_INPUT

if [ ${SNAPSHOT_INPUT} = 'y' ]; then
    IFS=$'\n'

    db_cluster_list=$(cat ./db_cluster_list.txt)

    ## DB 스냅샷
    for rCLUSTER_SNAPSHOT_LIST in ${db_cluster_list};do
        ## 작업할 때 주석해제
        ## aws-vault exec test/prod/kr -- aws rds create-db-cluster-snapshot --region ap-northeast-2 --db-cluster-snapshot-identifier "${rCLUSTER_SNAPSHOT_LIST}-2023-08-14" --db-cluster-identifier ${rCLUSTER_SNAPSHOT_LIST} > ./${rCLUSTER_SNAPSHOT_LIST}_snapshot.log
        if [ $? -eq 0 ]; then
            echo "${rCLUSTER_SNAPSHOT_LIST} --> Snapshot SUCCESS"
        else
            echo "${rCLUSTER_SNAPSHOT_LIST} --> Snapshot ERROR: $?"
            exit
        fi
    done
elif [ ${SNAPSHOT_INPUT} = 'n' ]; then
    exit
else
    exit
fi

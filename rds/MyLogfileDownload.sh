#!/bin/sh

export red="\033[1;31m"
export green="\033[1;32m"
export yellow="\033[1;33m"
export blue="\033[1;34m"
export purple="\033[1;35m"
export cyan="\033[1;36m"
export grey="\033[0;37m"
export reset="\033[m"

:<<'END'

- $1: DB 인스턴스명
- $2: Down 받으려는 로그파일명에 포함된 문자(contain the specified string)
- $3: Down 받으려는 로그파일 사이즈(larger than the specified size)
- $4: 로그 데이터 합친 통합파일명(consolidate file)

command ex1) sh MyLogfileDownload.sh prod-test-main-2 mysql-slowquery.log.2023-01-03 700 slowquerylog
command ex2) sh MyLogfileDownload.sh prod-test-main-2 mysql-slowquery.log.2023-01 700 slowquerylog
command ex3) sh MyLogfileDownload.sh prod-test-main-2 mysql-error.log.2023-01-03 700 errorlog
command ex3) sh MyLogfileDownload.sh prod-test-main-2 mysql-error.log.2023-01 700 errorlog

END

if [ -f ./$4.total.log ]; then
        echo /dev/null > ./$4.total.log
fi

logfile_list=`aws-vault exec test/prod -- aws rds describe-db-log-files --db-instance-identifier $1 --filename-contains $2 --file-size $3 | grep -i LogFileName | sed s'/,//'g | awk '{print $2}' | xargs`

if [[ ${logfile_list} == "" ]]; then
        echo "\n"
        echo ${red}
        echo "Not exists LogFile in condition !!"
        echo "Check parameter."
        echo ${reset}
        echo "\n"
        exit 1;
fi

for rLINE in ${logfile_list};do
        echo "**Downloading files...${rLINE}"
        aws-vault exec test/prod -- aws rds download-db-log-file-portion --db-instance-identifier $1 --log-file-name ${rLINE} --output text >> $4.total.log
done

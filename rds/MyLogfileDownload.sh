#!/bin/sh

:<<'END'

=======================================================================================================

Decription
- 슬로우로그 파일 또는 에러로그 파일을 내려받아서 1개 파일로 통합하는 스크립트

Parameter
- $1) DB 인스턴스명
- $2) Down 받으려는 로그파일명에 포함된 문자(contain the specified string)
- $3) Down 받으려는 로그파일 사이즈(larger than the specified size)
- $4) 로그 데이터 합친 통합파일명(consolidate file)

Command
- ex1) sh MyLogfileDownload.sh prod-test-main-2 mysql-slowquery.log.2023-01-03 700 slowquerylog
- ex2) sh MyLogfileDownload.sh prod-test-main-2 mysql-slowquery.log.2023-01 700 slowquerylog
- ex3) sh MyLogfileDownload.sh prod-test-main-2 mysql-error.log.2023-01-03 700 errorlog
- ex4) sh MyLogfileDownload.sh prod-test-main-2 mysql-error.log.2023-01 700 errorlog

=======================================================================================================

END

export ERR_PARAM_EMPTY=100
export ERR_PARAM_VALUE=200
export ERR_BAD=99

FILE_NAME=$4

export red="\033[1;31m"
export green="\033[1;32m"
export yellow="\033[1;33m"
export blue="\033[1;34m"
export purple="\033[1;35m"
export cyan="\033[1;36m"
export grey="\033[0;37m"
export reset="\033[m"

function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

function catch()
{
    export exception_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $exception_code
}


try
(
	# Filename Default
        if [[ -z $FILE_NAME ]]; then
                FILE_NAME=$(date +"%Y-%m-%d-%H-%M-%S")
        fi

	# Clear file contents
	if [ -f ./${FILE_NAME}.total.log ]; then
		echo ${green}
		echo "Clear file contents(./${FILE_NAME}.total.log)"
        	echo /dev/null > ./${FILE_NAME}.total.log
		echo ${reset}
	fi

	# Parameter Check
	if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then
		exit 100;
	fi

	# Logfile List
	logfile_list=`aws-vault exec test/prod -- aws rds describe-db-log-files --db-instance-identifier $1 --filename-contains $2 --file-size $3 | grep -i LogFileName | sed s'/,//'g | awk '{print $2}' | xargs`

	if [[ -z ${logfile_list} ]]; then
		exit 200;
	fi

	# Download file and aggregate
	echo ${green}
	for rLINE in ${logfile_list};do
        	echo "**Downloading files...${rLINE}"
        	aws-vault exec test/prod -- aws rds download-db-log-file-portion --db-instance-identifier $1 --log-file-name ${rLINE} --output text >> ${FILE_NAME}.total.log
	done

	echo "File creation is complete. ${reset}${purple}(${FILE_NAME}.total.log)"
	echo ${reset}
)
catch || {
	case $exception_code in
		$ERR_PARAM_EMPTY)
			echo ${yellow}
			echo "\n\tERR_PARAM_EMPTY(error no: 100): check empty parameter. \n"
			echo ${reset}
			echo "\tcommand:"
		 	echo "\t\tex1) sh MyLogfileDownload.sh prod-test-main-2 mysql-slowquery.log.2023-01-03 700 slowquerylog"
			echo "\t\tex2) sh MyLogfileDownload.sh prod-test-main-2 mysql-slowquery.log.2023-01 700 slowquerylog"
			echo "\t\tex3) sh MyLogfileDownload.sh prod-test-main-2 mysql-error.log.2023-01-03 700 errorlog"
			echo "\t\tex4) sh MyLogfileDownload.sh prod-test-main-2 mysql-error.log.2023-01 700 errorlog\n\n"
		;;
		$ERR_PARAM_VALUE)
			echo ${red}
			echo "\n\tERR_PARAM_VALUE(error no: 200): check parameter value."
			echo "\tex) file date or file size or something else.. \n"
			echo ${reset}
		;;
		*)
			echo "something wrong.."
		;;
	esac
}

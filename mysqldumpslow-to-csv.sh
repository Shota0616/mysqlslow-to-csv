#!/bin/bash
set -e

###########################################################
# 集計対象ファイル設定
TARGET_FILE_NAME=mysql-slow.log
TARGET_FILE_DIR=/var/log/mysql/
TARGET_FILE_PATH=${TARGET_FILE_DIR}${TARGET_FILE_NAME}
# 集計結果の出力ディレクトリ
OUTPUT_FILE_PATH=/var/log/mysql/mysqldumpslow/
# 本シェルのログ出力設定
OUTPUT_LOG_FILE_NAME=mysqldumpslow-to-csv.log
OUTPUT_LOG_FILE_DIR=/var/log/mysql/
OUTPUT_LOG_FILE_PATH=${OUTPUT_LOG_FILE_DIR}${OUTPUT_LOG_FILE_NAME}
# 集計識別用のuuid生成
UUID=`uuidgen`
###########################################################

# ログ出力ディレクトリの存在チェック
if [ ! -d ${OUTPUT_LOG_FILE_DIR} ]; then
    mkdir -p ${OUTPUT_LOG_FILE_DIR}
fi
if [ ! -e ${TARGET_FILE_PATH} ]; then
    touch ${OUTPUT_LOG_FILE_PATH}
fi
# log start
echo `date '+%y/%m/%d %H:%M:%S'` "INFO[${UUID}]" "[start] - mysqldumpslow-to-csv.sh" >> ${OUTPUT_LOG_FILE_PATH}

# 引数チェック処理
if [ $# != 2 ]; then
    echo `date '+%y/%m/%d %H:%M:%S'` "ERROR[${UUID}]" "[argument] - argument errer" >> ${OUTPUT_LOG_FILE_PATH}
    echo "引数の数が合いません。引数は2つだけ指定してください。"
    exit 1
fi

# 各種ディレクトリ存在チェック
# 対象ファイル
if [ -e ${TARGET_FILE_PATH} ]; then
    echo `date '+%y/%m/%d %H:%M:%S'` "INFO[${UUID}]" "[target_file_check_ok] - mysqldumpslow-to-csv.sh" >> ${OUTPUT_LOG_FILE_PATH}
else
    echo `date '+%y/%m/%d %H:%M:%S'` "ERROR[${UUID}]" "[target_file_check_failed] - target_file_check errer" >> ${OUTPUT_LOG_FILE_PATH}
    echo "対象ファイルが存在しません。"
    exit 1
fi
# 集計結果の出力ディレクトリ
if [ ! -d ${OUTPUT_FILE_PATH} ]; then
    echo `date '+%y/%m/%d %H:%M:%S'` "INFO[${UUID}]" "[make_output_file_dir] - mysqldumpslow-to-csv.sh" >> ${OUTPUT_LOG_FILE_PATH}
    mkdir -p ${OUTPUT_FILE_PATH}
fi

###########################################################
# 取得件数
COUNT=${1:-30}
# 集計オプション
OPTION=${2:-at}
###########################################################





echo `date '+%y/%m/%d %H:%M:%S'` "INFO[${UUID}]" "[start] - mysqldumpslow-cmd-start" >> ${OUTPUT_LOG_FILE_PATH}

# 総実行時間
mysqldumpslow -t ${COUNT} -s ${OPTION} ${TARGET_FILE_PATH} | sed '/^$/d' | awk '/^Count:/ {if (query) print query; query=""; printf $0","; next} {query=query" "$0} END {print query}' | awk '/^Count:/ {if (match($0, /Count: ([0-9]+)  Time=([0-9.]+)s \(([0-9]+)s\)  Lock=([0-9.]+)s \(([0-9]+)s\)  Rows=([0-9.]+) \(([0-9]+)\), (\S+@\S+),   (.*)/, item)) print item[1]","item[2]","item[3]","item[4]","item[5]","item[6]","item[7]","item[8]",\""item[9]"\""}' | sed -e "1i count,time-avg,time-total,lock-avg,lock-total,rows-avg,rows-total,host,statement" > mysqldumpslow-${OPTION}-`date '+%y%m%d-%H%M%S'`.csv

echo `date '+%y/%m/%d %H:%M:%S'` "INFO[${UUID}]" "[finish] - mysqldumpslow-cmd-finish" >> ${OUTPUT_LOG_FILE_PATH}

echo `date '+%y/%m/%d %H:%M:%S'` "INFO[${UUID}]" "[finish] - mysqldumpslow-to-csv.sh" >> ${OUTPUT_LOG_FILE_PATH}

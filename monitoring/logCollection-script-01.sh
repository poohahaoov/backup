#! /bin/bash
SEARCH_DATE=`date -d yesterday '+%Y-%m-%d'`
DATE_F1=`date -d yesterday '+%Y/%m/%d'`
DATE_F2=`date -d yesterday '+%Y%m%d'`
DATE_YEAR=`echo $SEARCH_DATE | awk -F '-' '{print $1}'`
DATE_MONTH=`echo $SEARCH_DATE | awk -F '-' '{print $2}'`
DATE_DAY=`echo $SEARCH_DATE | awk -F '-' '{print $3}'`
HOSTNAME=`hostname`

LOG_PATH="/root/dellemc/log_data"
BMC_PATH="$LOG_PATH/BMClog"
DMI_PATH="$LOG_PATH/dmidecode"
UPTIME_PATH="$LOG_PATH/uptime"
TMPLOGFILE="$LOG_PATH/DELL-TMP-log.txt"
LOGFILE="$BMC_PATH/$HOSTNAME-BMClog-$DATE_F2.log"

echo "HOSTNAME=$HOSTNAME"

#dmidecode log
echo "$HOSTNAME" >> $DMI_PATH/$HOSTNAME'_dmidecode-'$DATE_F2.log
echo ` date -d yesterday '+%Y-%m-%d %H:%M:%S' ` >> $DMI_PATH/$HOSTNAME'_dmidecode-'$DATE_F2.log
/usr/sbin/dmidecode >> $DMI_PATH/$HOSTNAME'_dmidecode-'$DATE_F2.log

#uptime log
echo "$HOSTNAME" >> $UPTIME_PATH/$HOSTNAME'_uptime-'$DATE_F2.log
echo ` date -d yesterday '+%Y-%m-%d %H:%M:%S' ` >> $UPTIME_PATH/$HOSTNAME'_uptime-'$DATE_F2.log
/usr/bin/last reboot >> $UPTIME_PATH/$HOSTNAME'_uptime-'$DATE_F2.log

#BMC log
/opt/dell/srvadmin/sbin/racadm lclog view -c storage,system -s Warning,Critical -r "$SEARCH_DATE 00:00:00" -e "$SEARCH_DATE 23:59:59" | egrep 'Message ID|Severity|Timestamp|Message' | sed '/Message Arg/d' > $TMPLOGFILE
#racadm lclog view -c storage,system | egrep 'Message ID|Severity|Timestamp|Message' | sed '/Message Arg/d' > $TMPLOGFILE

LOGCNT=` cat $TMPLOGFILE | wc -l `
#echo "LOGCNT=$LOGCNT"
if [ $LOGCNT = 0 ] ; then
        echo "$HOSTNAME | $DATE_F1 | Not Found Logging" >> $LOGFILE

else
        for (( i=1; i<=$LOGCNT; i=i+4 )) ; do
                CNT=$(( $i+3 ))
                CHK=` cat $TMPLOGFILE | sed -n $i','$CNT'p' `

                #echo "CNT=$CNT"
                #echo "$CHK" | grep 'Timestamp' | awk -F '=' '{print $2}'

                TIMESTAMP=` echo "$CHK" | grep 'Timestamp' | awk -F '=' '{print $2}' | sed 's/^ //g' | sed "s/-/\//g" `
                TIMESTAMP_1=` echo "$TIMESTAMP" | awk -F ' ' '{print $1}' `
                TIMESTAMP_2=` echo "$TIMESTAMP" | awk -F ' ' '{print $2}' `
                COMPONENT=` echo "$CHK" | grep 'Message ID' | awk -F '=' '{print $2}' | sed 's/^ //g' ` #| sed 's/[^A-Z]//g' `
                SEVERITY=` echo "$CHK" | grep 'Severity' | awk -F '=' '{print $2}' | sed 's/^ //g' `
                MESSAGE=` echo "$CHK" | grep 'Message' | awk -F '=' '{print $2}' | tail -1 | sed 's/^ //g' `

                echo "$HOSTNAME | $TIMESTAMP_1 | $TIMESTAMP_2 | $COMPONENT | $SEVERITY | $MESSAGE" >> $LOGFILE

                unset TIMESTAMP TIMESTAMP_1 TIMESTAMP_2 COMPONENT SEVERITY MESSAGE
        done
fi




#scp connect file upload
MGMT1_IP="202.20.162.253"
REMOTE_BMC_DIR="$BMC_PATH"
REMOTE_DMI_DIR="$DMI_PATH"
REMOTE_UPTIME_DIR="$UPTIME_PATH"

#MGMT1_IP="202.20.164.79"
#REMOTE_BMC_DIR="/data/log_data/repo/server/BMClog/$DATE_F2/DELL"
#REMOTE_DMI_DIR="/data/log_data/repo/server/dmidecode/$DATE_F2/DELL"
#REMOTE_UPTIME_DIR="/data/log_data/repo/server/uptime/$DATE_F2/DELL"

scp $LOGFILE root@$MGMT1_IP:$REMOTE_BMC_DIR
scp $DMI_PATH/*.log root@$MGMT1_IP:$REMOTE_DMI_DIR
scp $UPTIME_PATH/*.log root@$MGMT1_IP:$REMOTE_UPTIME_DIR


#temp file delete
rm -f $BMC_PATH/*.*
rm -f $DMI_PATH/*.*
rm -f $UPTIME_PATH/*.*

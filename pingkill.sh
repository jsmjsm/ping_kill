#!/bin/bash
ipaddress=$1
isIPError=1
FailTimes=0

check_ipaddr()
{
    echo $1|grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$" > /dev/null;
    if [ $? -ne 0 ]
    then
        echo "IP is invalid!"
        isIPError=1
        return 1
    fi
    ipaddr=$1
    a=`echo $ipaddr|awk -F . '{print $1}'`  #以"."分隔，取出每个列的值
    b=`echo $ipaddr|awk -F . '{print $2}'`
    c=`echo $ipaddr|awk -F . '{print $3}'`
    d=`echo $ipaddr|awk -F . '{print $4}'`
    for num in $a $b $c $d
    do
        if [ $num -gt 255 ] || [ $num -lt 0 ]    #每个数值必须在0-255之间
        then
            echo $ipaddr "->"\'$num\'" is invalid!"
    isIPError=1
            return 1
        fi
   done
   echo $ipaddr "IP is valid"
    isIPError=0
   return 0
}

fPing(){
    # ping 1.2.3.4 -c 5 >> /tmp/ping.txt 2>&1 &
    ping $1 -c 5 >> /tmp/TempPingKill.log 2>&1 &
}

fCheck(){
    failTimes=0
    # sleep 600
    pingTimes=$(grep "statistics" /tmp/TempPingKill.log -c)
    if [ $pingTimes -gt 0 ]
    then
        FailTimes=$(grep "100.0\% packet loss" /tmp/TempPingKill.log -c)
    else
        echo "wait 10s to grep"
        sleep 10
        FailTimes=$(grep "100.0\% packet loss" /tmp/TempPingKill.log -c)
    fi
    #echo $failTimes
}

fPingTool(){
    mycount=0
    rm -f /tmp/TempPingKill.log
    # > ping 10 times
    while (( $mycount < 10))
    do
        echo "ping time: $mycount on $(date)"
        fPing $ipaddress
        sleep 60
        let "mycount++"
    done
    echo "ping done on $(date) "
    # MARK: run fCheck
    fCheck
}

fShutdown(){

    # MARK: run fPingTool
    fPingTool

    num=$FailTimes
    echo "=== $(date) ==="
    echo "Ping IP: $ipaddress"
    echo "Fail Times: $num"

    if [ $num -gt 5 ];
    then
        echo "Shutdown in 120s"
        sleep 120
        echo "Shutdown now!"
        # MARK: Shutdown
        shutdown
    else
        echo "Continue to next ping"
    fi
}


# -- main -- #
rm -f /tmp/TempPingKill.log
rm -f /tmp/PingKill.log

if [ $# -ne 1 ];
then            #判断传参数量
        echo "Usage: $0 ipaddress."
        echo "Plese enter target IP!"
        exit
else
check_ipaddr $ipaddress
fi
# echo "ip result: $isIPError"

if [ $isIPError == 0 ]
then
    echo "Start to endlessly ping! If FailTimes of ping meet to 6, shutdown after 2 minutes!"

    while :
    do
        fShutdown >> /tmp/PingKill.log 2>&1 &
    done

else
    echo "IP is invalid, exit now!"
    exit 0
fi






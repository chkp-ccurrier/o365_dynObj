#!/bin/bash
# Version 3
# Date 01/07/2019 8:51:40

url="https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7"

timeout=43200
LOG_FILE="$FWDIR/log/o365_dynObj.log"

x=0
y=0
z=0

#is_fw_module=$($CPDIR/bin/cpprod_util FwIsFirewallModule)
is_fw_module=1

IS_FW_MODULE=$($CPDIR/bin/cpprod_util FwIsFirewallModule)

MY_PROXY=$(clish -c 'show proxy address'|awk '{print $2}'| grep  '\.')
MY_PROXY_PORT=$(clish -c 'show proxy port'|awk '{print $2}'| grep -E '[0-9]+')
if [ ! -z "$MY_PROXY" ]; then
        HTTPS_PROXY="$MY_PROXY:$MY_PROXY_PORT"
fi

function log_line {
        # add timestamp to all log lines
        message=$1
        local_log_file=$2
        echo "$(date) $message" >> $local_log_file
}
function convert {
        for ip in ${addrs[@]} ; do
		first=$(ipcalc -n $ip | awk -F"=" '{print $2}')
		last=$(ipcalc -b $ip | awk -F"=" '{print $2}')
#		echo $first"-"$last"\n"
                todo[$y]+=" $first $last"
                if [ $z -eq 2000 ]
                        then
                                z=0
                                let y=$y+1
                        else
                                let z=$z+1
                        fi
        done


        for i in "${todo[@]}" ;
        do
                ok=$( dynamic_objects -o "$objName" -r $i -a )
        done
	unset todo
	unset addrs
}
function check_url {
        if [ ! -z $url ]; then
                test_url=$url

                #verify curl is working and the internet access is avaliable
                if [ -z "$HTTPS_PROXY" ]
                then

                        test_curl=$(curl_cli --head -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 2 --retry-delay 20 $test_url | grep HTTP)
                else
                        test_curl=$(curl_cli --head -k -s --cacert $CPDIR/conf/ca-bundle.crt $test_url --proxy $HTTPS_PROXY | grep HTTP)
                fi

                if [ -z "$test_curl" ]
               then
                        echo "Warning, cannot connect to $test_url"
                        exit 1
                fi
                log_line "done testing http connection" $LOG_FILE
        fi
}

if [[ "$is_fw_module" -eq 1 && /etc/appliance_config.xml ]]; then
                check_url
                if [ -z "$HTTPS_PROXY" ]
                then
#			oipaddresses=$(curl_cli -k -s https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7 -o /var/tmp/O365IPAddresses.json)
                        $(curl_cli -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 10 --retry-delay 60 $url -o /var/tmp/O365IPAddresses.json )
                else
                        oipaddresses=`curl_cli -k -s --cacert $CPDIR/conf/ca-bundle.crt --retry 10 --retry-delay 60 $url --proxy $HTTPS_PROXY `
		fi

			getproducts=$( jq '.[] |.serviceArea' /var/tmp/O365IPAddresses.json |sort | uniq )
			logProds=''
			for m in $getproducts
			do
				echo $m
				addrs=($( jq '.[] | {"Addresses":.ips ,"Service":.serviceArea } |select(.Service =='$m') | with_entries( select( . != null ) )' /var/tmp/O365IPAddresses.json | awk -F"\n" '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip}'|sed '/^[[:space:]]*$/d' | sort -n ))
				objName=$( sed -e 's/^"//' -e 's/"$//' <<<"$m" )
				echo $objName
				addrsLen=${#addrs[@]}
				if [[ "$addrsLen" -ne 0 ]]; then
        			  ok=$( dynamic_objects -do "$objName" )
        			  ok=$( dynamic_objects -n "$objName" )
				  convert
				  logProds+=$objName" "$addrsLen" ranges updated\n"
				fi
                		log_line "update of dynamic object $objName completed" $LOG_FILE
			done

fi
#	rmfile=$(rm -rf /var/tmp/O365IPAddresses.json)
echo -e $logProds

#!/bin/bash
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

DOMAINS=(
'amazon.com 443'
'facebook.com 443'
'twitter.com 443'
'google.de 443'
'google.com 443'
'gmail.com 443'
'gmail-smtp-in.l.google.com. 25 smtp'
)

function check_ssl_cert()
{
    host=$1
    port=$2
    proto=$3

    if [ -n "$proto" ]
    then
        starttls="-starttls $proto"
    else
        starttls=""
    fi

    cert=`openssl s_client -servername $host -host $host -port $port -showcerts $starttls -prexit </dev/null 2>/dev/null |
              sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |
              openssl x509 -text 2>/dev/null`
    end_date=`echo "$cert" | sed -n 's/ *Not After : *//p'`

    end_date_seconds=`date '+%s' --date "$end_date"`
    now_seconds=`date '+%s'`
    end_date=$(echo "($end_date_seconds-$now_seconds)/24/3600" | bc)

    issue_dn=`echo "$cert" | sed -n 's/ *Issuer: *//p'`
    issuer=`echo $issue_dn | sed -n 's/.*CN=*//p'`

    serial=`echo "$cert" | openssl x509 -serial -noout`
    serial=`echo $serial | sed -n 's/.*serial=*//p'`

    printf "| %30s | %5s | %-13s | %-40s | %-50s |\n" "$host" "$port" "$end_date" "$serial" "${issuer:0:50}"
}


printf "%s\n" "/--------------------------------------------------------------------------------------------------------------------------------------------------------\\"
printf "| %30s | %5s | %-13s | %-40s | %-50s |\n" "Domain" "Port" "Expire (days)" "Serial" "Issuer"
printf "%s\n" "|--------------------------------|-------|---------------|------------------------------------------|----------------------------------------------------|"
for domain in "${DOMAINS[@]}"; do
    check_ssl_cert $domain
done
printf "%s\n" "\\--------------------------------------------------------------------------------------------------------------------------------------------------------/"

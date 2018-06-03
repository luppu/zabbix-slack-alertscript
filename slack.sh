#!/bin/bash

# Slack incoming web-hook URL and user name
url='CHANGEME'		# example: https://hooks.slack.com/services/QW3R7Y/D34DC0D3/BCADFGabcDEF123
username='Zabbix'

## Values received by this script:
# To = $1 (Slack channel or user to send the message to, specified in the Zabbix web interface; "@username" or "#channel")
# Subject = $2 (usually either PROBLEM or RECOVERY/OK)
# Message = $3 (whatever message the Zabbix action sends, preferably something like "Zabbix server is unreachable for 5 minutes - Zabbix server (127.0.0.1)")

# Get the Slack channel or user ($1) and Zabbix subject ($2 - hopefully either PROBLEM or RECOVERY/OK)
to="$1"
subject="$2"

# Change message emoji depending on the subject - smile (RECOVERY/OK), frowning (PROBLEM), or ghost (for everything else)
recoversub='^RECOVER(Y|ED)?$'
if [[ "$subject" =~ ${recoversub} ]]; then
        emoji=':smile:'
        color='3aa3e3'
elif [[ "$subject" =~ 'OK' ]]; then
        emoji=':smile:'
        color='good'
elif [[ "$subject" =~ 'PROBLEM' ]]; then
        emoji=':frowning:'
        color='danger'
else
        emoji=':ghost:'
        color='cee3e5'
fi

# The message that we want to send to Slack is the "subject" value ($2 / $subject - that we got earlier)
#  followed by the message that Zabbix actually sent us ($3)
subject="${subject}: ${emoji}"

# Read alert message line by line
hostname=`echo -e "$3" | sed -n 1p`
ip=`echo -e "$3" | sed -n 2p`
check_result=`echo -e "$3" | sed -n '3,$p'`

# Build our JSON payload and send it as a POST request to the Slack incoming web-hook URL
payload="payload={\"channel\": \"${to//\"/\\\"}\", \"username\": \"${username//\"/\\\"}\", \"attachments\": [ { \"title\": \"${subject//\"/\\\"}\", \"fields\": [ { \"title\": \"Check Result\", \"value\": \"${check_result//\"/\\\"}\", \"short\": false }, { 
\"title\": \"Host\", \"value\": \"${hostname//\"/\\\"}\", \"short\": true }, { \"title\": \"IPAddress\", \"value\": \"${ip//\"/\\\"}\", \"short\": true }, ], \"color\": \"${color}\" } ] }"

curl -m 5 --data-urlencode "${payload}" $url -A 'zabbix-slack-alertscript / https://github.com/ericoc/zabbix-slack-alertscript'

#!/bin/bash

# Publish a CloudWatch metric to report whether this instance should be considered active or not.
# We consider it active when there are any open SSH or Session Manager connections to it or if it
# was recently booted.

availabilityZone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$(echo "${availabilityZone}" | sed 's/[a-z]$//')
instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
stackName=$(aws --region "${region}" ec2 describe-instances --instance-id "${instanceId}" --query 'Reservations[*].Instances[*].Tags[?Key==`aws:cloudformation:stack-name`].Value' | jq -r '.[0][0][0]')
uptimeSeconds=$(cat /proc/uptime | awk -F '.' '{print $1}')
uptimeMinutes=$((uptimeSeconds / 60))
ssmConnectionCount=$(aws ssm describe-sessions --filters "key=Target,value=${instanceId}" --state Active --region "${region}" | jq '.Sessions | length')
sshConnectionCount=$(/usr/sbin/ss -o state established '( sport = :ssh )' | grep -i ssh | wc -l)
((totalConnectionCount = ssmConnectionCount + sshConnectionCount))

# note that "ssh over ssm" connections are double counted

isActive=0
if [ "${totalConnectionCount}" -gt 0 ] || [ "${uptimeMinutes}" -lt 15 ]; then
    isActive=1
fi

metricNameSpace="${stackName}"
aws --region "${region}" cloudwatch put-metric-data --metric-name "ConnectionCount" --dimensions InstanceId="${instanceId}" --namespace "${metricNameSpace}" --value "${totalConnectionCount}"
aws --region "${region}" cloudwatch put-metric-data --metric-name "UptimeMinutes" --dimensions InstanceId="${instanceId}" --namespace "${metricNameSpace}" --value "${uptimeMinutes}"
aws --region "${region}" cloudwatch put-metric-data --metric-name "Active" --dimensions InstanceId="${instanceId}" --namespace "${metricNameSpace}" --value "${isActive}"

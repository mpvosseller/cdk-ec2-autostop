#!/bin/bash
availabilityZone=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=$(echo "${availabilityZone}" | sed 's/[a-z]$//')
instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
stackName=$(aws --region "${region}" ec2 describe-instances --instance-id "${instanceId}" --query 'Reservations[*].Instances[*].Tags[?Key==`aws:cloudformation:stack-name`].Value' | jq -r '.[0][0][0]')
uptimeSeconds=$(cat /proc/uptime | awk -F '.' '{print $1}')
uptimeMinutes=$((uptimeSeconds / 60))

# count the ssm and ssh connections
# note that an "ssh over ssm" connecton will be counted twice (once as an ssm connection and once as an ssh connection)
ssmSessionCount=$(aws ssm describe-sessions --filters "key=Target,value=${instanceId}" --state Active --region "${region}" | jq '.Sessions | length')
sshSessionCount=$(/usr/sbin/ss -o state established '( sport = :ssh )' | grep -i ssh | wc -l)
((sessionCount = ssmSessionCount + sshSessionCount))

# consider this host active if there are any sessions OR if it was booted less than 15 minutes ago
bastionActive=0
if [ "${sessionCount}" -gt 0 ] || [ "${uptimeMinutes}" -lt 15 ]; then
    bastionActive=1
fi

# Ideally a CloudWatch Alarm would decide for itself whether a host is active or not
# by using a math expression metric with sessionCount & uptimeSeconds. Unfortunately
# EC2 alarm actions do not currently work with expression metrics.
# https://github.com/aws/aws-cdk/blob/master/packages/%40aws-cdk/aws-cloudwatch/lib/alarm.ts#L249
# Instead we calculate Active in this script and publish that for the alarm to use.
aws --region "${region}" cloudwatch put-metric-data --metric-name SessionCount --dimensions InstanceId="${instanceId}" --namespace "${stackName}" --value "${sessionCount}"
aws --region "${region}" cloudwatch put-metric-data --metric-name UptimeMinutes --dimensions InstanceId="${instanceId}" --namespace "${stackName}" --value "${uptimeMinutes}"
aws --region "${region}" cloudwatch put-metric-data --metric-name Active --dimensions InstanceId="${instanceId}" --namespace "${stackName}" --value "${bastionActive}"

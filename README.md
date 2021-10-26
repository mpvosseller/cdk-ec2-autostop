# cdk-ec2-autostop

This project demonstrates how to use the CDK to create an EC2 instance
that automatically stops when there are no more active SSH or Session
Manager connections to it. This can be useful for an instance that
is only used occasionally to remotely access an RDS cluster.

When you deploy this stack and EC2 instance is provisioned that 
automatically stops after running for about 15-30 minutes without an 
SSH or Session Manager connection. It can be manually re-started at 
any time and will again be automatically stopped after running for 
about 15-30 minutes without an SSH or Session Manager connection.

This project implements the following solution:

1) Install a bash script `report-metrics.sh` that publishes a CloudWatch
metric named `Active` that indicates whether the current instance is
"active" or not. We consider an instance to be active if it has any incoming
SSH or Session Manager connections or if it was recently booted.

2) Configure a cronjob to run `report-metrics.sh` on the instance once
a minute.

3) Configure a CloudWatch Alarm that stops the instance once it
remains inactive over a 15 minute period.

NOTES:
- As currently implemented you can only use Session Manager to connect to this instance.
- If you want to connect directly with SSH you must do the following:
    - Create an [EC2 Key Pair](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs)
    - Edit `cdk-ec2-autostop-stack.ts` to set `keyName` to the name of your key
    - Edit `cdk-ec2-autostop-stack.ts` to uncomment the line that allows SSH connections

## Useful commands

 * `npm run build`   compile typescript to js
 * `npm run watch`   watch for changes and compile
 * `npm run test`    perform the jest unit tests
 * `cdk deploy`      deploy this stack to your default AWS account/region
 * `cdk diff`        compare deployed stack with current state
 * `cdk synth`       emits the synthesized CloudFormation template

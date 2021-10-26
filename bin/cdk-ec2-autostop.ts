#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { CdkEc2AutostopStack } from '../lib/cdk-ec2-autostop-stack';

const app = new cdk.App();
new CdkEc2AutostopStack(app, 'CdkEc2AutostopStack');

import * as amplify from '@aws-cdk/aws-amplify';
import * as cdk from '@aws-cdk/core';
import * as codebuild from '@aws-cdk/aws-codebuild';
import * as elbv2 from '@aws-cdk/aws-elasticloadbalancingv2';
import * as ecs from '@aws-cdk/aws-ecs';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as logs from '@aws-cdk/aws-logs';
import * as ssm from '@aws-cdk/aws-ssm';

export class CdkStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const amplifyApp = new amplify.App(this, 'functional-vote-amplify', {
      sourceCodeProvider: new amplify.GitHubSourceCodeProvider({
        owner: 'maxrchung',
        repository: 'FunctionalVote',
        oauthToken: cdk.SecretValue.plainText(ssm.StringParameter.valueForStringParameter(this, 'github-personal-access-token'))
      }),
      buildSpec: codebuild.BuildSpec.fromObjectToYaml({
        version: '1.0',
        appRoot: 'frontend',
        frontend: {
          phases: {
            build: {
              commands: [
                'npm install',
                'npm run build'
              ]
            }
          },
          artifacts: {
            baseDirectory: 'build',
            files: [
              '**/*'
            ]
          },
          cache: {
            paths: [
              'node_modules/**/*'
            ]
          }
        }
      })
    });
    const branch = amplifyApp.addBranch('master');
    const domain = amplifyApp.addDomain('maxrchung.com')
    domain.mapSubDomain(branch, 'functionalvote');

    const taskDefinition = new ecs.TaskDefinition(this, 'functional-vote-task', {
      family: 'functional-vote-task',
      compatibility: ecs.Compatibility.FARGATE,
      cpu: '256',
      memoryMiB: '512',
    });

    const logGroup = new logs.LogGroup(this, 'functional-vote-log-group', {
      logGroupName: 'functional-vote-log-group',
      retention: logs.RetentionDays.ONE_MONTH,
    });

    const container = taskDefinition.addContainer('functional-vote-container', {
      containerName: 'functional-vote-container',
      image: ecs.ContainerImage.fromRegistry('maxrchung/functional-vote'),
      environment: {
        DATABASE_URL: ssm.StringParameter.valueForStringParameter(this, 'functional-vote-database-url'),
        SECRET_KEY_BASE: ssm.StringParameter.valueForStringParameter(this, 'functional-vote-secret-key-base'),
        RECAPTCHA_PUBLIC_KEY: ssm.StringParameter.valueForStringParameter(this, 'functional-vote-recaptcha-public-key'),
        RECAPTCHA_PRIVATE_KEY: ssm.StringParameter.valueForStringParameter(this, 'functional-vote-recaptcha-private-key'),
      },
      logging: ecs.LogDriver.awsLogs({
        logGroup: logGroup,
        streamPrefix: 'functional-vote-log',
      })
    });

    container.addPortMappings({ containerPort: 4000 });

    const vpc = ec2.Vpc.fromLookup(this, 'cloud-vpc', {
      vpcName: 'cloud-vpc',
    });

    // https://github.com/aws/aws-cdk/issues/11146#issuecomment-943495698
    const cluster = ecs.Cluster.fromClusterAttributes(this, 'cloud-cluster', {
      clusterName: 'cloud-cluster',
      vpc,
      securityGroups: [],
    });

    const fargate = new ecs.FargateService(this, 'functional-vote-fargate', {
      serviceName: 'functional-vote-fargate',
      cluster,
      desiredCount: 1,
      taskDefinition,
      assignPublicIp: true,
    });

    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'functional-vote-target-group', {
      targetGroupName: 'functional-vote-target-group',
      port: 4000,
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
    });

    targetGroup.addTarget(fargate);

    const listener = elbv2.ApplicationListener.fromLookup(this, 'cloud-balancer-listener-https', {
      loadBalancerTags: {
        'balancer-identifier': 'cloud-balancer'
      },
      listenerProtocol: elbv2.ApplicationProtocol.HTTPS,
    });

    listener.addTargetGroups('add-functional-vote-target-group', {
      priority: 300,
      targetGroups: [
        targetGroup
      ],
      conditions: [
        elbv2.ListenerCondition.hostHeaders([
          'functionalvote.api.maxrchung.com',
        ]),
      ],
    });
  }
}

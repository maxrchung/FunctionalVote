import * as amplify from '@aws-cdk/aws-amplify'
import * as cdk from '@aws-cdk/core'
import * as codebuild from '@aws-cdk/aws-codebuild'
import * as ssm from '@aws-cdk/aws-ssm'

export class CdkStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props)

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
              commands: ['npm install', 'npm run build']
            }
          },
          artifacts: {
            baseDirectory: 'build',
            files: ['**/*']
          },
          cache: {
            paths: ['node_modules/**/*']
          }
        }
      })
    })
    const branch = amplifyApp.addBranch('master')
    const domain = amplifyApp.addDomain('maxrchung.com')
    domain.mapSubDomain(branch, 'functionalvote')

    // Redirect traffic to index.html to have correct SPA routing
    // https://docs.aws.amazon.com/amplify/latest/userguide/redirects.html
    // https://github.com/aws-amplify/amplify-console/issues/59
    amplifyApp.addCustomRule(amplify.CustomRule.SINGLE_PAGE_APPLICATION_REDIRECT)
  }
}

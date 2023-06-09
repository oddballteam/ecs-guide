# 🏖️ Sandbox 

<details><summary>Get AWS access from CloudTamer</summary>

1. login at [CloudTamer](https://cloudtamer.cms.gov)
2. Go to the [projects page](https://cloudtamer.cms.gov/portal/project)
3. access `wdsops-dev` by clicking on the cloud icon.
4. select `Cloud Access Roles`
5. select `wdsops-developer-admin` role
6. first click on `Web Access` to open AWS in another tab
7. navigate back to the CloudTamer browser tab and follow steps 3-5 again. 
8. now click on `Short-term Access Keys`. This will show temporary AWS keys.
9. Select the tab for your OS and follow option 1 then paste the copied export lines into your terminal.
10. You are all set, let's get started 😎

You now have a AWS Management console open and a terminal with AWS keys available.

Make sure to use this same terminal when running commands. The exported AWS keys will not apply to new terminals and will need to be reexported if a new session is started.

</details>

--- 

The best way to familiarize yourself with Fargate is to get some real experience with it.

While the modules involved in Fargate are in an early state there is enough to get a basic example deployed.

1. navigate your terminal to this file directory.
2. run `terraform init`
3. (replace `YOUR_FIRST_NAME_HERE` with your first name then) run `terraform apply -var "name=YOUR_FIRST_NAME_HERE"`
<details><summary>4. take a look at the resources that will be created. Here is a full list of what will be created:</summary>

- cluster.aws_ecs_cluster.cluster
- cluster.aws_ecs_cluster_capacity_providers.capacity
- dns.aws_route53_zone.zone
- service.aws_alb.main
- service.aws_alb_listener.http
- service.aws_alb_target_group.ecs_tg
- service.aws_appautoscaling_policy.cpu
- service.aws_appautoscaling_policy.memory
- service.aws_appautoscaling_target.main
- service.aws_cloudwatch_log_group.log_group
- service.aws_ecr_repository.ecr
- service.aws_ecs_service.service
- service.aws_ecs_task_definition.task
- service.aws_iam_policy.task_execution_policy
- service.aws_iam_policy.task_policy
- service.aws_iam_role.fargate
- service.aws_iam_role.task_execution_role
- service.aws_iam_role.task_role
- service.aws_iam_role_policy_attachment.fargate
- service.aws_iam_role_policy_attachment.task_execution_role_policy_attachment
- service.aws_iam_role_policy_attachment.task_role_policy_attachment
- service.aws_route53_record.site_record
- service.aws_s3_bucket_policy.s3_access_log_policy
- service.aws_security_group.alb
- service.aws_security_group.service
- service.module.access_logs_bucket.aws_s3_bucket.bucket
- service.module.access_logs_bucket.aws_s3_bucket_public_access_block.restrict_access
- service.module.access_logs_bucket.aws_s3_bucket_server_side_encryption_configuration.encryption
- service.module.access_logs_bucket.aws_s3_bucket_versioning.versioning
</details>

5. enter `yes` to create the resources

# 🥾Ready
We now have a Fargate environment bootstrapped.

Currently no tasks are running since no task definitions have been written.

Writing task definitions and running tasks will be handled by a Python deploy script.

Before we get started with the deploy script let's do a brief history lesson on Deployer.

### 🏺 History
Previously deploying resources was done using a Go script called [Deployer](https://github.com/CMSgov/deployer).

After personally doing an investigation on the Deployer I would consider it a massive success. 

> [pdf](https://jira.cms.gov/secure/attachment/1144434/Deployer.pdf) of my presentation on Deployer 

<img src="https://raw.githubusercontent.com/oddballteam/ecs-guide/main/img/overview.jpg" width=40%>

App teams have all successfully been able to interface with it using devops pipelines. 

Part of the magic that makes deployer a great tool is that it **abstracts** away many of the complexities. 

I was surprised to find that the vast majority of app teams members have no understanding of how the tool works (besides the top level input) despite it being in use for the last 6 years.

I found that there was 3 layers which led to the success of Deployer. 

These same layers can be applied to the new deployer as shown in this diagram.

<img src="https://raw.githubusercontent.com/oddballteam/ecs-guide/main/img/layers.jpg" width=40%>

- The **App** layer, or **pipeline** layer is where App teams would use op's pipeline's to run jobs. Ideally this is automated or at most a single input. While running jobs can be simple, writing them takes in a good deal of complexity.
  - For investigating Deployer I worked with the API team. They have amazing examples of [pipelines](https://github.cms.gov/CMS-WDS/marketplace-api/tree/master/ops/jobs/deploy) which perfectly illustrate good abstraction. You can see these jobs only take the input of a `version` identifier. For example the current prod deploy is of version `r253`. So if I were to deploy to production I would run the `deploy-to-prod` job in Jenkins. For the version input I would provide `r254` and run the job (the API team does require a checkbox to acknowledge prod deploys). That's it! This will do all the work of deploying resources. The key to understand here is that deploys are dead simple.
- The **Config** layer, mostly composed of a rarely updated (few times a year) file which houses configuration data which will vary between teams. 
  - For Deployer this is something called a universe file stored in S3. An example of this can be seen in [app3](https://github.cms.gov/CMS-WDS/application/blob/master/ops/terraform/environments/env-shared/files/universe.json). Most of the file contains networking, security or log identifiers. These identifiers are important configuration which cannot be baked into the source code but also are not changed enough to be something defined at the app layer.
- The **Source** layer, the underlying script code. This does all the heavy lifting of deploying resources in the background
  - This should be built in a way which is as dynamic as possible. Meaning that anything which could change should be built to be able to be changed. This allows every team to be able to use the same underlying infrastructure and less duplication of code. This entails complexity but provides great benefits.


# 🏗️ Deploy
At this time the there is no app layer for our new deployer.

That is something which is our job to build for app teams.

For now the source layer is found in [deploy.py](https://github.cms.gov/OC-Foundational/ocf-shared/blob/main/deploy/deploy.py) and the config layer will be a toml file under [/applications/SOME_APP/jobs/SOME_APP-ENV.toml](https://github.cms.gov/OC-Foundational/ocf-shared/blob/main/applications/flh/jobs/flh-dev.toml)

A full picture of what the config layer will contain is not fully known at this time. 

For now we will assume that a toml file will contain most configuration needed for each service.

Let's talk about using the deploy script.

Currently the deploy script takes two arguments. The path to a toml file and an Image URI (soon this can be a list of Image URIs).

Now that we have our service ready for tasks we can run the script.

1. Using your terminal change directory outside this repository and clone the repository where deployer is located into a folder called "v4" with `git clone https://github.cms.gov/OC-Foundational/ocf-shared.git v4`
2. change directory into deployer with `cd v4/deploy`
3. We will be running Python outside of Docker so ensure you have the minimum required Python of 3.9+ with `python -V`. If not download the [latest python](https://www.python.org/downloads/) for your system.
4. install python packages with `pip install -r requirements.txt`
5. create a configuration toml file with the name `config.toml`
6. copy and paste the following into your toml file using the editor of your choice

> replace `NAME` with the same name you provided Terraform. For example if you provided Terraform `-var "name=Bob"` then change cluster and service to "Bob-test"
```toml
#config.toml
account = "879613780019"
region = "us-east-1"
cluster = "NAME-test"
service = "NAME-test"
port = 80
execution_role_arn = "arn:aws:iam::879613780019:role/delegatedadmin/developer/flh-dev-task-execution-role"
task_role_arn = "arn:aws:iam::879613780019:role/delegatedadmin/developer/flh-dev-task-role"
```

7. run deployer with `python deploy.py config.toml 879613780019.dkr.ecr.us-east-1.amazonaws.com/guide`

#### While that's running let's explain what's happening

- The Python deploy script is reading the toml file using the path and name of the toml file you provided. Another example may be something like this `python deploy.py ../../different-name.toml IMAGE-URI`
- The script's second argument is a Image URI. Currently due to _Docker authentication_ pulling images from Docker won't work, like `nginx`. However if you instead pull anywhere from ECR like with `python deploy.py ./my.toml public.ecr.aws/nginx/nginx` you will get a valid deploy of nginx to Fargate (however, without any configuration this will fail health checks to path `/_health` and continually redeploy). 
- Once the script has these arguments it parses the toml file and loads these values into variables
- It will attempt to load in any secrets which can be stored under Parameter Store using forward slash + service name: `"/" + YOUR_TOML_SERVICE_NAME`
- These secrets are not actually read at this time, but instead their ARN is stored in a list
- All this data is then passed to a `create_task_definition` function which will use it to, well create a task definition.
- Lastly a deploy is started using the Python AWS SDK of boto3. This exposes the [update_service](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ecs.html#ECS.Client.update_service) function which then passes the work to AWS's service scheduler. This tells AWS that you have a desired count of the latest task definition which you just added to.

> here is a basic example of a task definition. We see where most of the toml file lines are being used. [Full list of parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)
```py
{
  "name": service,
  "image": image_uri,
  "cpu": 256,
  "memory": 512,
  "portMappings": [
    { "containerPort": port }
  ],
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "/aws/ecs/fargate/" + service,
      "awslogs-region": region,
      "awslogs-stream-prefix": service,
    },
  },
  "secrets": secrets,
}
```
#### 🪄 ECS magic 
> the remaining work is all handled by ECS

If we had a previous task still running then it will be moved to the `ACTIVE` status at this time. However, our new task which will be started will have the `PRIMARY` status. Looking at the tasks section in ECS the task will have the `PROVISIONING` status. This is where the ENI mentioned in a previous lesson is created. After the task moves to the `PENDING` status. This is where the agent (who has the task execution role) will do things like pull the Docker image. Lastly the task is moved to the `RUNNING` status which means it has started the container.

<img src="https://raw.githubusercontent.com/oddballteam/ecs-guide/main/img/task.png" width=40%>

Assuming this isn't our first deploy we now have two tasks running, each running with their own task definition. The task will expose a private IP which will be targeted by the application load balancer target group. This will start with an `initial` status for the new target group. This will perform health checks (generally this means requests are sent to `HEALTH_PROTOCOL://TASK_PRIVATE_IP:HEALTH_PORT/_health`). If those health check fails AWS will assume it did something wrong and continually redeploy the same task. Assuming the app is responding to health checks with a code less than 400 it will mark it as `healthy`, the task has successfully been deployed and will receive the new traffic 👍

There is still an issue of the previous task running. If you have worked with load balancers you know they can drain traffic from a target. Traffic draining happens at this point and the old target will enter a `draining` state. This is a process to deregister it from a target group. At this time no new traffic will be directed to the previous task private IP. As long as in-flight requests don't go over the `deregistration delay` (default of 5 minutes) they will be completed. After this delay times out the old target will be removed from the target group completely (The load balancer will actually wait the full deregistration delay regardless of ongoing traffic, which can slow this process). 

This has just removed traffic, the task is still running. ECS will schedule for the deletion of the task. This essentially runs a `docker stop CONTAINER_ID` on the container. This also has a timeout setting where it will delete the task regardless of if Docker is able to stop the container. 

8. after a successful deploy, listen for logs in your terminal with (replacing `NAME` with your name) `aws logs tail /aws/ecs/fargate/NAME-test --follow` you should see a `Listening on 0.0.0.0:80` log indicating that the task was successful.

9. in your browser go to [load balancers](https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers:) and click on your load balancer. Find the `DNS name` and paste its value into a new tab as a URL.

10. 🥂 verify that you see a running web application 


# 🗺️ Explore 
That is all the content I have prepared for this guide at this time.

I would recommend exploring Fargate at this time for yourself.

As part of the Terraform you ran you have created a repository for your own images.

#### 🏆Challenge
If you want to attempt a challenge you could try uploading an image to the ECR you made.

Then provide your image URI to deployer and see if you can create a stable deploy.

Three important pitfalls related to this is:

- the task will need to respond on the /_health path otherwise it will be considered unhealthy and continually redeploy
- at this time only images from ECR will work at this time (they can be from your own private ECR!)
- this challenge mainly **requires** an understanding of Docker. If you don't understand Docker I cannot recommend this challenge.

#### 📎Hint
If you would like a hint. I essentially did this challenge for you and provided you my URI as part of the deployer command you ran previously. 

You could look at how I did it in the app folder of this repository. 

I built it using a new JS framework called Svelte but any web app could be used.

However, if you know nothing about web apps there is likely a simpler solution you could create using just nginx. This could be done with 2 files a `Dockerfile` and a `nginx.conf`

> Here would be half of a nginx solution
```dockerfile
FROM nginx:stable-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

# 🧹 Cleanup 

1. change directory back to this file location
2. run `terraform destroy`
3. enter `yes` to destroy the resources
4. Manually delete ECR and S3 using the CLI

> Terraform cannot delete buckets that are not empty, use the CLI to empty and delete them. Copy the bucket name from the Terraform output `deleting S3 Bucket (BUCKET_NAME_WILL_BE_HERE): BucketNotEmpty` and enter it into this small script. The first s3api will require you to press `q` to quit out of the delete preview.
```sh
BUCKET=YOUR_BUCKET_NAME

aws s3api delete-objects --bucket $BUCKET \
  --delete "$(aws s3api list-object-versions \
  --bucket $BUCKET \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
  
aws s3api delete-bucket --bucket $BUCKET
```

5. Verify that everything has been cleaned up by running `terraform refresh` and a `terraform state list`. This should show an output similar to this:

> Since every line contains a `data` section these are not _real_ resources. You can read more about data sources from the [terraform docs](https://developer.hashicorp.com/terraform/language/data-sources)
```
data.aws_caller_identity.current
module.service.data.aws_elb_service_account.elb_account
module.service.data.aws_iam_policy_document.fargate
module.service.data.aws_subnets.private
module.service.data.aws_subnets.public
module.dns.module.vpc.data.aws_vpc.vpc
module.service.module.common_sgs.data.aws_security_group.cmscloud-security-tools
module.service.module.common_sgs.data.aws_security_group.cmscloud-shared-services
module.service.module.common_sgs.data.aws_security_group.cmscloud-vpn
module.service.module.vpc.data.aws_vpc.vpc
```

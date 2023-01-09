# 🏖️ Sandbox 

`aws logs tail /ecs/test --follow`


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



# 🗺️ Explore 
We now have a Fargate environment bootstrapped.

Currently no tasks are running since no task definitions have been written.

Writing tasks will be handled by a Python deploy script.


#### Deploy script history
Previously deploying resources was done using a custom Go script called [Deployer](https://github.com/CMSgov/deployer).

After personally doing an investigation on the tool I would consider it a massive success. 

> a pdf of my presentation on Deployer can be seen [here](https://jira.cms.gov/secure/attachment/1144434/Deployer.pdf)

<img src="https://user-images.githubusercontent.com/16319829/81180309-2b51f000-8fee-11ea-8a78-ddfe8c3412a7.png" width=50% height=50%>

App teams have all successfully been able to interface with it using ops pipelines. 

Part of the magic that makes deployer a great tool is that it *abstracts* away many of the complexities. 

I was surprised to find that the vast majority of app teams members have no understanding of how the tool works despite it being in use for the last 6 years.



# 🧹 Cleanup 

1. run `terraform destroy`
2. enter `yes` to destroy the resources
3. Manually delete ECR and S3 using the CLI

> Terraform cannot delete ECR if there is at least one image present, use the CLI instead
```sh
REPO=YOUR_REPO_NAME

aws ecr delete-repository --repository-name $REPO --force
```

> Terraform cannot delete buckets that are not empty, use the CLI to empty and delete them.
```sh
BUCKET=YOUR_BUCKET_NAME

aws s3api delete-objects --bucket $BUCKET \
  --delete "$(aws s3api list-object-versions \
  --bucket $BUCKET \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
  
aws s3api delete-bucket --bucket $BUCKET
```

4. Verify that everything has been cleaned up by running `terraform refresh` and a `terraform state list`. This should show an output similar to this:

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

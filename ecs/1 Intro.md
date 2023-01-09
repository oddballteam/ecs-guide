# 👋 Guide to ECS
This guide will help onboard any and all engineers to the ECS.

There are many differences and new things to learn here compared to traditional EC2.

As part of learning ECS you will build your own service and deploy it, to get a more hands on experience.

Please follow all the steps to make sure you do not miss out on any important details.


### Background
> what is ECS?

ECS stands for Elastic Container Service. 

This is Amazon's attempt to bring serverless options to the popularity of containers.

Containers are an important part of ECS, they are the base of what you will be deploying.

For this reason understanding Docker, how to build, run, and debug are also essential for ECS.

While writing containers may be a task left to application teams, you should still understand how they work.

### Fargate
Fargate is the chosen branch of ECS which engineers will become familiar with.

The alternative is an EC2 launch type. 

The benefit of Fargate over EC2 is it is serverless, meaning there will less infrastructure to manage.

Once a auto scaling policy has been put in place, AWS will handle capacity.

The service will be scaled up or down depending on load.

No EC2 instances will be generated as part of Fargate, only containers.


#### Up Next, Fargate
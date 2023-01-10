# Terms
> Let's get started with some important vocabulary

### Clusters
A cluster is a regional grouping of tasks or services. 
This will include one or more containers.
A cluster will always be in one of these possible states:
- ACTIVE: The cluster is ready to accept tasks and, if applicable, you can register container instances with the cluster.
- PROVISIONING: The cluster has capacity providers associated with it and the resources needed for the capacity provider are being created.
- DEPROVISIONING: The cluster has capacity providers associated with it and the resources needed for the capacity provider are being deleted.
- FAILED: The cluster has capacity providers associated with it and the resources needed for the capacity provider have failed to create.
- INACTIVE: The cluster has been deleted

### Task Definition
Task definitions are where most of a clusters configuration will occur.
They describe one or more containers, to a maximum of 10.

Task Definitions can be thought of as a blueprint for your application. 
A small list of example task definition parameters are:
- what Docker image(s) to use
- what environment variables to pass to the container
- which ports should be opened for your application
- how much CPU and memory should be allocated to each container
- Which data volumes should be used with the containers in the task
- The IAM role that your tasks use


An exhaustive list of all parameters can be found [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)


### Task
A task is the instantiation of a task definition within a cluster.

Tasks can be manually started but in our implementation, this will be handled through a service.

With the Fargate launch type each task has its own isolation boundary and does not share the underlying kernel, CPU, memory, or elastic network interface with another task.

### Service
A service runs and maintains your desired number of tasks simultaneously in an Amazon ECS cluster.

How it works is that, if any of your tasks fail or stop for any reason, the Amazon ECS service scheduler launches another instance based on your task definition.

It does this to replace it and thereby maintain your desired number of tasks in the service.

By default it will spread tasks across Availability Zones.

Many times replacing the task does not actually solve the issue meaning when something goes wrong with a Task it will often be stuck in a loop of constantly redeploying.

### ECR
ECR stands for Elastic Container Registry.

Docker Images can be stored here.

Currently we use Artifactory for storing and pulling Images.

The current modules written for Fargate do support creating a ECR repository with each service.

An important thing to know about ECR is that it uses temporary Authentication tokens.

Similar to the role assumption tokens generated using the AWS CLI with `awsume`.

You need to sign-in to the registry in order to interact with it.

Once done, you can pull or push images. 

Or create new image repositories.

#### Up next, [Details](https://github.com/oddballteam/ecs-guide/blob/main/ecs/3%20Details.md)
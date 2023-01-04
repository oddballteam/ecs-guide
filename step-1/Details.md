#### Networking
All tasks launched using Fargate run inside your defined VPC.

You can define the subnets and Security Groups in a task definition or at runtime.

Fargate enforces the configuration specified when your tasks are started

When using the network mode `awsvpc` like we will be in our implementation.

Tasks will be allocated their own elastic network interface (ENI) and a primary private IPv4 address. 

This gives the task the same networking properties as EC2 instances.

When using a public subnet, you can optionally assign a public IP address to the task's ENI.

The ENI is important to consider since it will be used in all of these areas:

- When retrieving Amazon ECR login credentials
- Pulling images
  - When using container images that are hosted in Amazon ECR, you can configure Amazon ECR to use an interface VPC endpoint and the image pull occurs over the task's private IPv4 address
- Sending logs through a log driver
- Retrieving secrets from Secrets Manager or Systems Manager
- Application traffic
- Amazon EFS file system traffic

Amazon ECS populates the hostname of the task with an Amazon provided DNS hostname when both the `enableDnsHostnames` and `enableDnsSupport` options are enabled on your VPC.

If these options aren't enabled, the DNS hostname of the task is set to a random hostname.

You can't manually detach or modify the ENIs that are created and attached by Fargate.

This is to prevent the accidental deletion of an ENI that's associated with a running task.

To release the ENIs for a task, stop the task.

#### SSH
An important note about SSH. 

Best practice for containers is to have them stateless.

Meaning once the application team has put their approval on an Image it should not need an accessible shell.

Environment variables should be the main way of altering container behavior at that point.

In other words the Image should be written in a way which SSH is unnecessary.

AWS by default denies SSH access to containers. 

This has been done this for security reasons.

While SSH can be a powerful tool using it within Fargate will require extra work on our part.

### Roles
There are two roles involved in a task definition.

There is the task execution role and the task role.

Here is their summary:

- Task Execution Role = A role assumed by the overhead task agent which manages tasks in the cluster. This will usually only involve logging and interacting with ECR.
- Task Role = A role assumed by the application inside a container. This could involve any number of services on AWS, like S3 or RDS.


### Load Balancers
Load Balancers make a comeback in Fargate.

We will be using application Load Balancers.
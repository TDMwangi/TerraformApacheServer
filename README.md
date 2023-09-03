# Terraform Apache Server

An EC2 instance with Apache installed deployed with Terraform.

## _Steps:_

1. Create a VPC.
   ![image info](./img/1.png)
2. Create an Internet Gateway.
   ![image info](./img/2.png)
3. Create a custome Route Table.
   ![image info](./img/3.png)
4. Create a Subnet.
   ![image info](./img/4.png)
5. Associate the Subnet with a Route Table.
6. Create a Security Group to allow port 22, 80 and 443.
   ![image info](./img/5.png)
7. Create a Network Interface with an IP in the Subnet that was created in step 4.
8. Assign an Elastic IP to the Network Interface that was created in step 7.
   ![image info](./img/6.png)
9. Create an Ubuntu server and install/enable apache2.

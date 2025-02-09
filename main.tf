

## Create VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr_vpc
  tags = {
    Name = "My VPC"
  }
}

##  Create public and private subnets
resource "aws_subnet" "pubsub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.cidr_pubsub1
  availability_zone       = var.az1
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet1"
  }
}

resource "aws_subnet" "pubsub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.cidr_pubsub2
  availability_zone       = var.az2
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet2"
  }
}

resource "aws_subnet" "prvsub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.cidr_prvsub1
  availability_zone       = var.az1
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet1"
  }
}

resource "aws_subnet" "prvsub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.cidr_prvsub2
  availability_zone       = var.az2
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet2"
  }
}

## Create Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "IGW"
  }
}

# Create public route table
resource "aws_route_table" "RTpub" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route"
  }
}


# Create Elastic IP and Nat gateways
resource "aws_eip" "nateip1" {
  domain = "vpc"
}

resource "aws_eip" "nateip2" {
  domain = "vpc"
}


resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nateip1.id
  subnet_id = aws_subnet.pubsub1.id
  tags = {
    Name = "Nat1 VPC"
  }
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nateip2.id
  subnet_id = aws_subnet.pubsub2.id
  tags = {
    Name = "Nat2 VPC"
  }
}

# Create Private route table and attach the NAt gateway route
resource "aws_route_table" "RTprv1" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }
  tags = {
    Name = "Private Route1"
  }
}

resource "aws_route_table" "RTprv2" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat2.id
  }
  tags = {
    Name = "Private Route2"
  }
}

## Attach the subnets to the route tables
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.RTpub.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.RTpub.id
}

resource "aws_route_table_association" "rta3" {
  subnet_id      = aws_subnet.prvsub1.id
  route_table_id = aws_route_table.RTprv1.id
}

resource "aws_route_table_association" "rta4" {
  subnet_id      = aws_subnet.prvsub2.id
  route_table_id = aws_route_table.RTprv2.id
}

## CReate security groups
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}


## Create Key pair for instances
resource "aws_key_pair" "kp" {
  key_name = "key1"
  public_key = file("C:/Users/Vijesh/.ssh/id_rsa.pub")
}

## Create a bastion instance to login to the private instances
resource "aws_instance" "instance2vpc01" {
  ami = var.ami
  instance_type = var.type
  subnet_id = aws_subnet.pubsub1.id
  key_name = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  tags = {
    Name = "Bastion Server"
  }
  provisioner "file" {
    source      = "C:/Users/Vijesh/.ssh/id_rsa"
    destination = "/home/ubuntu/key.pem"

    connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("C:/Users/Vijesh/.ssh/id_rsa")
    host = self.public_ip
  }
  }
}

## Create a launch template to be used in the auoscaling group
resource "aws_launch_template" "launchtemp" {
  name = "lt1"
  instance_type = var.type
  key_name = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  image_id = var.ami
  user_data = base64encode(file("userdata.sh"))

}

## Create target groups for load balancer
resource "aws_lb_target_group" "tg" {
  name = "TG1"
  protocol = "HTTP"
  port = 80
  vpc_id = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}

## Create autoscaling group and attach the target group
resource "aws_autoscaling_group" "asg" {
  name = "ASG"
  #vpc_zone_identifier =aws_lb.lb.subnets
  vpc_zone_identifier = [aws_subnet.prvsub1.id,aws_subnet.prvsub2.id] 
  min_size = 2
  max_size = 4
  desired_capacity = 2
  #health_check_type = "ELB"
  health_check_grace_period = 500
  launch_template {
    id = aws_launch_template.launchtemp.id
    version = "$Default"
  }
  depends_on = [ aws_lb.lb ]
  target_group_arns = [aws_lb_target_group.tg.arn]

}

## Create load balancer
resource "aws_lb" "lb" {
  name = "Load-balancer1"
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = "application"
  security_groups = [aws_security_group.webSg.id]
  subnets = [aws_subnet.pubsub1.id,aws_subnet.pubsub2.id]  
}


## Create a listener to route the traffic to the target groups
resource "aws_lb_listener" "listen" {
  load_balancer_arn = aws_lb.lb.arn
  protocol = "HTTP"
  port = 80

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Defining cloudwatch alarm for high CPU
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name = "CPU_HIGH_ALERT"
  metric_name = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold = 50
  namespace = "AWS/EC2"
  statistic = "Average"
  evaluation_periods = 2      # contiuously 2 times if CPU greater than for 3 mins  
  period = 120            # average of cpu for 3 min
  alarm_description = "Scaling up as CPU high than 40%"
  #alarm_actions = [aws_autoscaling_policy.scale_up.arn,aws_sns_topic.sns1.arn]
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  actions_enabled = "true"

}

## Autoscaling policy for high CPU
resource "aws_autoscaling_policy" "scale_up" {
  name = "Scale-up"
  scaling_adjustment = 1
  autoscaling_group_name = aws_autoscaling_group.asg.name
  cooldown = 300
  adjustment_type = "ChangeInCapacity"
  policy_type = "SimpleScaling"
}

# Defining cloudwatch alarm for low CPU
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name = "CPU_LOW_ALERT"
  metric_name = "CPUUtilization"
  comparison_operator = "LessThanThreshold"
  threshold = 30
  namespace = "AWS/EC2"
  statistic = "Average"
  evaluation_periods = "2"
  period = 120
  alarm_description = "Scaling down as CPU less than 40%"
  
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  actions_enabled = "true"

}

## Autoscaling policy for low CPU
resource "aws_autoscaling_policy" "scale_down" {
  name = "Scale-down"
  scaling_adjustment = -1
  autoscaling_group_name = aws_autoscaling_group.asg.name
  cooldown = 300
  adjustment_type = "ChangeInCapacity"
  policy_type = "SimpleScaling"
}



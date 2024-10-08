resource "docker_image" "centos" {
  name = var.image_name
  keep_locally = false
}

resource "aws_ecs_cluster" "cluster" {
  name = "first-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

module "ecs-fargate" {
  source = "umotif-public/ecs-fargate/aws"
  version = "~> 6.1.0"

  name_prefix        = "ecs-fargate-centos"
  vpc_id             = aws_vpc.main-vpc.id
  private_subnet_ids = [aws_subnet.Private-Subnet-1.id,aws_subnet.Private-Subnet-2.id]

  cluster_id         = aws_ecs_cluster.cluster.id

  task_container_image   = var.image_name
  task_definition_cpu    = 256
  task_definition_memory = 512

  task_container_port             = 80
  task_container_assign_public_ip = true

  load_balanced = false

  target_groups = [
    {
      target_group_name = "tg-fargate-example"
      container_port    = 80
    }
  ]

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  tags = {
    Environment = "test"
    Project = "Terraform_1"
  }
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}
provider "aws" {
    region = "us-west-2"
    profile = "sre-challenge"
}

terraform {
  backend "s3" {
    bucket = "eea-sre-challenge"
    key    = "terraform_state"
    region = "us-west-2"
    encrypt = true
    profile = "sre-challenge"
    sts_region = "eu-west-1"
  }
}

module "payments_workers" {
    source     = "./workers"
    name       = "payments_workers"
    min_size   = 2
    desired_capacity = 2
    max_size   = 2
    instance_type = "t3.nano"
    cpuscale = 60.0
}

module "background_workers" {
    source     = "./workers"
    name       = "background_workers"
    min_size   = 2
    desired_capacity = 2
    max_size   = 2
    cpuscale = 60.0
}

module "messaging_background_workers" {
    source     = "./workers"
    name       = "messaging_background_workers"
    min_size   = 1
    max_size   = 4
}

resource "aws_autoscaling_schedule" "daily_messaging_scale_out" {
    scheduled_action_name  = "evening_payments_scale_out"
    min_size               = 1
    max_size               = 4
    desired_capacity       = -1
    recurrence             = "0 5 * * *"
    autoscaling_group_name = "${module.messaging_background_workers.scaling_group_id}"
}

resource "aws_autoscaling_schedule" "daily_messaging_scale_in" {
    scheduled_action_name  = "daily_messaging_scale_in"
    min_size               = 0
    max_size               = 4
    desired_capacity       = -1
    recurrence             = "0 22 * * *"
    autoscaling_group_name = "${module.messaging_background_workers.scaling_group_id}"
}

resource "aws_autoscaling_schedule" "evening_payments_scale_out" {
    scheduled_action_name  = "evening_payments_scale_out"
    min_size               = 4
    max_size               = 8
    desired_capacity       = -1
    recurrence             = "0 15 * * *"
    autoscaling_group_name = "${module.payments_workers.scaling_group_id}"
}

resource "aws_autoscaling_schedule" "evening_payments_scale_in" {
    scheduled_action_name  = "evening_payments_scale_in"
    min_size               = 2
    max_size               = 8
    desired_capacity       = -1
    recurrence             = "0 18 * * *"
    autoscaling_group_name = "${module.payments_workers.scaling_group_id}"
}

resource "aws_codedeploy_app" "sre-terraform-app" {
    name                  = "sre-terraform-app"
}

resource "aws_codedeploy_deployment_group" "workers-deployment_grp" {
    app_name              = "sre-terraform-app"
    deployment_group_name = "workers"
    service_role_arn      = "arn:aws:iam::639035123345:role/CodeDeploy-EC2-Role"
    deployment_config_name= "CodeDeployDefault.AllAtOnce"

    autoscaling_groups    = ["${module.background_workers.scaling_group_id}",
                             "${module.messaging_background_workers.scaling_group_id}",
                             "${module.payments_workers.scaling_group_id}"
                             ]
}

## Application servers

variable "elb_name" {
    type    = string
    default = "application-lb"
}


variable "sns_topic" {
    type    = string
    default = "arn:aws:sns:us-west-2:639035123345:Admins"
}

module "application" {
    source     = "./application"

    min_size   = 2
    max_size   = 4
}

resource "aws_codedeploy_deployment_group" "application-deployment-grp" {
    app_name              = "sre-terraform-app"
    deployment_group_name = "application"
    service_role_arn      = "arn:aws:iam::639035123345:role/CodeDeploy-EC2-Role"

    deployment_style {
        deployment_option = "WITH_TRAFFIC_CONTROL"
        deployment_type = "IN_PLACE"
    }

    load_balancer_info {
        elb_info {
            name = "${var.elb_name}"
        }
    }

    trigger_configuration {
        trigger_events    = ["DeploymentFailure"]
        trigger_name      = "On Failed Deployment"
        trigger_target_arn= "${var.sns_topic}"
    }

    auto_rollback_configuration {
        enabled = true
        events = ["DEPLOYMENT_FAILURE"]
    }

    autoscaling_groups    = ["${module.application.scaling_group_id}",
                            ]
}

terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 5.0"
		}
	}
	required_version = ">= 1.2.0"
}

provider "aws" {
	region = "us-east-1"
}

resource "aws_dynamodb_table" "games" {
  name           = "games"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "gameId"

  attribute {
    name = "gameId"
    type = "S"
  }

  tags = {
    Environment = "production"
    Name        = "GamesTable"
  }
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "DynamoDBTablePolicy"
  description = "Policy to secure DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::339713161833:role/LabRole" # Zastąp swoim ID konta AWS
          ]
        }
        Action   = "dynamodb:*"
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.games.name}"
      }
    ]
  })
}



resource "aws_cognito_user_pool" "main" {
  name                     = "example-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  #   mfa_configuration   = "OPTIONAL"

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your verification code is {####}."
    email_subject        = "Verify your email address"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    name                     = "email"
    required                 = true
    mutable                  = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name = "example-user-pool-client"

  user_pool_id           = aws_cognito_user_pool.main.id
  generate_secret        = false
  refresh_token_validity = 90
  explicit_auth_flows    = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]

  prevent_user_existence_errors = "ENABLED"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create subnet
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create route table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create security group
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow SSH, HTTP, and custom TicTacToe ports"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "lab_role_profile" {
  name = "LabRoleProfile"
  role = "LabRole"
}

resource "aws_instance" "my_instance" {
	ami = "ami-080e1f13689e07408"
	instance_type = "t2.small"
  iam_instance_profile  = aws_iam_instance_profile.lab_role_profile.name
	key_name = "vockey"
	subnet_id     = aws_subnet.my_subnet.id
	vpc_security_group_ids = [aws_security_group.my_security_group.id]
	associate_public_ip_address = "true"
	user_data = <<-EOF
		#!/bin/bash
		
		cd home/ubuntu
		sudo apt-get update -y
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo snap install docker
        
		sudo mkdir -p /usr/local/lib/docker/cli-plugins
		sudo curl -sL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose

		sudo chown root:root /usr/local/lib/docker/cli-plugins/docker-compose
		sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

		sudo apt-get install -y default-jdk

		sudo apt-get update -y
		sudo apt-get install -y maven
    sudo snap install jq

		git clone -b main https://github.com/pwr-cloudprogramming/a12-wiktor0072.git

		cd a12-wiktor0072/backend
		mvn package
		cd ../..

		# Retrieve IP address using metadata script
		API_URL="http://169.254.169.254/latest/api"
		TOKEN=$(curl -X PUT "$API_URL/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 600")
		TOKEN_HEADER="X-aws-ec2-metadata-token: $TOKEN"
		METADATA_URL="http://169.254.169.254/latest/meta-data"
		IP_V4=$(curl -H "$TOKEN_HEADER" -s $METADATA_URL/public-ipv4)

		# Replace IP address and URL in JavaScript file
		JS_FILE="a12-wiktor0072/frontend/src/play.js"  # Update with the path to your JavaScript file

		# Replace all occurrences of "localhost" with the IP address
		sed -i "s@localhost@$IP_V4@g" "$JS_FILE"

    JS_FILE="a12-wiktor0072/frontend/src/UploadPage.tsx"
    sed -i "s@localhost@$IP_V4@g" "$JS_FILE"

    JS_FILE="a12-wiktor0072/frontend/src/ResultPage.tsx"
    sed -i "s@localhost@$IP_V4@g" "$JS_FILE"
		

		
		#Replace in config.js
		
		REGION="${data.aws_region.current.name}"
    USERPOOLID="${aws_cognito_user_pool.main.id}"
    CLIENTID="${aws_cognito_user_pool_client.main.id}"

	  	# Ścieżka do pliku config.json
		CONFIG_FILE="a12-wiktor0072/frontend/src/config.json"


	  	# Użyj jq do aktualizacji wartości w pliku config.json
		sed -i "s@\"region\": \"[^\"]*\"@\"region\": \"$REGION\"@g" "$CONFIG_FILE"
		sed -i "s@\"userPoolId\": \"[^\"]*\"@\"userPoolId\": \"$USERPOOLID\"@g" "$CONFIG_FILE"
		sed -i "s@\"clientId\": \"[^\"]*\"@\"clientId\": \"$CLIENTID\"@g" "$CONFIG_FILE"

		cd a12-wiktor0072/frontend

		sudo docker build -t frontend:v1 -t frontend:latest .

		cd ../backend/src/main/resources

    credentials=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/LabRole)
    access_key=$(echo $credentials | jq -r '.AccessKeyId')
    secret_key=$(echo $credentials | jq -r '.SecretAccessKey')
    session_token=$(echo $credentials | jq -r '.Token')
    region="us-east-1" 

    output_file="application.properties"

    sed -i "s|amazon.aws.region=REGION|amazon.aws.region=us-east-1|g" $output_file
    
    cd ../../..

		sudo docker build -t backend:v1 -t backend:latest .
		cd ..
		sudo docker compose up -d


		EOF
	

	user_data_replace_on_change = true
	tags = {
		Name = "Tic-tac-toe-Webserver3"
	}
}

output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.main.id
}

data "aws_region" "current" {
}

data "aws_caller_identity" "current" {}

variable "region" {
  default = "us-west-1"
}
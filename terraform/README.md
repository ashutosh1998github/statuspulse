# Terraform Infrastructure

## Prerequisites
- Terraform installed
- AWS CLI configured with credentials

## Install Terraform
Download from: https://developer.hashicorp.com/terraform/downloads

## Usage

### 1. Initialize
```bash
terraform init
```

### 2. Preview changes
```bash
terraform plan
```

### 3. Apply
```bash
terraform apply
```

### 4. Get outputs
```bash
terraform output
```

### 5. Destroy (cleanup)
```bash
terraform destroy
```

## Variables
| Variable | Description | Default |
|---|---|---|
| aws_region | AWS region | ap-south-1 |
| instance_type | EC2 type | t2.micro |
| key_name | SSH key pair | statuspulse-key |
| app_name | App name | statuspulse |
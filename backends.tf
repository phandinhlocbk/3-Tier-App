# terraform {
#   backend "s3" {
#     bucket = "mybucket"
#     key    = "path/to/my/key"
#     region = "us-east-1"

#     # For State Locking
#     dynamodb_table = "dev-project1-vpc"  
#   }
# }
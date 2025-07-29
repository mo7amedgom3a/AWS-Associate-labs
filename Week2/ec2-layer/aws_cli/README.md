#!/bin/bash

# Set permissions for scripts
chmod +x setup.sh
chmod +x cleanup.sh
chmod +x test.sh

echo "AWS CLI scripts are now executable."
echo ""
echo "Available commands:"
echo "  ./setup.sh    - Create the EC2 instance and ECR repository"
echo "  ./test.sh     - Test the connectivity to created resources"
echo "  ./cleanup.sh  - Delete all created resources"

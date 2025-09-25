# Database Population Scripts

These scripts populate the DynamoDB and RDS MySQL databases with mock data for the serverless e-commerce application.

## Prerequisites

- Node.js installed
- AWS CLI configured with appropriate credentials
- Access to the DynamoDB table and RDS instance

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Configure environment variables for the RDS connection:
   ```
   export DB_HOST=your-rds-endpoint.us-east-1.rds.amazonaws.com
   export DB_PORT=3306
   export DB_USER=admin
   export DB_PASSWORD=your-password
   export DB_NAME=products
   ```

## Usage

### Populate DynamoDB Orders Table

```
npm run populate-dynamodb
```

This will create 20 mock orders with random customer IDs, items, and statuses.

### Populate RDS MySQL Products Table

```
npm run populate-rds
```

This will create 30 mock products with random categories, prices, and stock levels.

### Populate Both Databases

```
npm run populate-all
```

## Customization

You can modify the number of mock records by changing the parameters in the respective script files:

- `populate_dynamodb.js`: Change `generateOrders(20)` to your desired number
- `populate_rds.js`: Change `generateProducts(30)` to your desired number

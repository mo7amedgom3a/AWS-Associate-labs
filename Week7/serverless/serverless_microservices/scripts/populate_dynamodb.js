// Script to populate DynamoDB with mock order data
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

// Configure AWS SDK
AWS.config.update({
  region: 'us-east-1' // Replace with your region if different
});

// Create DynamoDB document client
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Table name - make sure this matches your actual table name
const tableName = 'serverless-ecommerce-dev-orders';

// Generate mock order data
const generateOrders = (count) => {
  const orders = [];
  const customers = ['cust-001', 'cust-002', 'cust-003', 'cust-004', 'cust-005'];
  const statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  
  for (let i = 0; i < count; i++) {
    const customer_id = customers[Math.floor(Math.random() * customers.length)];
    const order_id = `order-${uuidv4().substring(0, 8)}`;
    const items = [];
    
    // Generate 1-5 items per order
    const itemCount = Math.floor(Math.random() * 5) + 1;
    for (let j = 0; j < itemCount; j++) {
      items.push({
        product_id: `prod-${Math.floor(Math.random() * 20) + 1}`,
        quantity: Math.floor(Math.random() * 5) + 1,
        price: parseFloat((Math.random() * 100 + 5).toFixed(2))
      });
    }
    
    // Calculate total
    const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0).toFixed(2);
    
    orders.push({
      order_id,
      customer_id,
      status: statuses[Math.floor(Math.random() * statuses.length)],
      items,
      total: parseFloat(total),
      shipping_address: {
        street: `${Math.floor(Math.random() * 9999) + 1} Main St`,
        city: 'Example City',
        state: 'EX',
        zipcode: `${Math.floor(Math.random() * 90000) + 10000}`
      },
      order_date: new Date().toISOString()
    });
  }
  
  return orders;
};

// Insert orders into DynamoDB
const populateOrders = async (orders) => {
  console.log(`Inserting ${orders.length} orders into DynamoDB...`);
  
  for (const order of orders) {
    const params = {
      TableName: tableName,
      Item: order
    };
    
    try {
      await dynamodb.put(params).promise();
      console.log(`Successfully inserted order: ${order.order_id}`);
    } catch (error) {
      console.error(`Failed to insert order ${order.order_id}:`, error);
    }
  }
  
  console.log('Finished populating orders table.');
};

// Main function
const main = async () => {
  try {
    const orders = generateOrders(20); // Generate 20 mock orders
    await populateOrders(orders);
  } catch (error) {
    console.error('Error in main function:', error);
  }
};

// Run the script
main();

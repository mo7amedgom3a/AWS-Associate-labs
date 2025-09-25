// Script to populate RDS MySQL with mock product data
const mysql = require('mysql2/promise');
const { v4: uuidv4 } = require('uuid');

// Database configuration - replace with your actual RDS endpoint and credentials
const dbConfig = {
  host: process.env.DB_HOST || 'serverless-ecommerce-dev-products.ce9u8gyqms1d.us-east-1.rds.amazonaws.com',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'admin',
  timeout: 30000,
  password: process.env.DB_PASSWORD || 'MySecurePassword123!',
  database: process.env.DB_NAME || 'products'
};

// Generate mock product data
const generateProducts = (count) => {
  const products = [];
  const categories = ['Electronics', 'Clothing', 'Books', 'Home', 'Sports', 'Toys'];
  
  for (let i = 1; i <= count; i++) {
    const category = categories[Math.floor(Math.random() * categories.length)];
    const price = parseFloat((Math.random() * 500 + 10).toFixed(2));
    const stock = Math.floor(Math.random() * 100) + 1;
    
    products.push({
      product_id: uuidv4(),
      sku: `SKU-${category.substring(0, 3).toUpperCase()}-${i.toString().padStart(4, '0')}`,
      name: `${category} Item ${i}`,
      description: `This is a high-quality ${category.toLowerCase()} product, perfect for all your needs.`,
      price,
      stock_quantity: stock,
      is_active: Math.random() > 0.1 // 90% of products are active
    });
  }
  
  return products;
};

// Insert products into MySQL
const populateProducts = async (products) => {
  console.log('Connecting to MySQL database...');
  let connection;
  
  try {
    connection = await mysql.createConnection(dbConfig);
    console.log('Connected to MySQL database successfully.');
    
    console.log(`Inserting ${products.length} products into database...`);
    
    for (const product of products) {
      const query = `
        INSERT INTO products 
        (product_id, sku, name, description, price, stock_quantity, is_active) 
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `;
      
      const values = [
        product.product_id,
        product.sku,
        product.name,
        product.description,
        product.price,
        product.stock_quantity,
        product.is_active
      ];
      
      await connection.execute(query, values);
      console.log(`Inserted product: ${product.name}`);
    }
    
    console.log('Finished populating products table.');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (connection) {
      await connection.end();
      console.log('Database connection closed.');
    }
  }
};

// Main function
const main = async () => {
  try {
    const products = generateProducts(30); // Generate 30 mock products
    await populateProducts(products);
  } catch (error) {
    console.error('Error in main function:', error);
  }
};

// Run the script
main();

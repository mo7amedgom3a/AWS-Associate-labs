// API configuration
const config = {
    // This will be replaced with the actual API Gateway URL after deployment
    apiBaseUrl: 'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/dev',
    
    // API endpoints
    endpoints: {
        products: '/products',
        orders: '/orders',
        customerOrders: '/customers/{customerId}/orders'
    }
};

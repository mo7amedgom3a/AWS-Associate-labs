// API service for interacting with the backend
const api = {
    // Products API
    async getProducts() {
        try {
            const response = await fetch(`${config.apiBaseUrl}${config.endpoints.products}`);
            if (!response.ok) {
                throw new Error(`Failed to fetch products: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error('Error fetching products:', error);
            throw error;
        }
    },
    
    async getProduct(productId) {
        try {
            const response = await fetch(`${config.apiBaseUrl}${config.endpoints.products}/${productId}`);
            if (!response.ok) {
                throw new Error(`Failed to fetch product: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error(`Error fetching product ${productId}:`, error);
            throw error;
        }
    },
    
    // Orders API
    async createOrder(orderData) {
        try {
            const response = await fetch(`${config.apiBaseUrl}${config.endpoints.orders}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(orderData)
            });
            
            if (!response.ok) {
                throw new Error(`Failed to create order: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error('Error creating order:', error);
            throw error;
        }
    },
    
    async getOrder(orderId, customerId) {
        try {
            const response = await fetch(`${config.apiBaseUrl}${config.endpoints.orders}/${orderId}?customer_id=${customerId}`);
            if (!response.ok) {
                throw new Error(`Failed to fetch order: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error(`Error fetching order ${orderId}:`, error);
            throw error;
        }
    },
    
    async getCustomerOrders(customerId) {
        try {
            const endpoint = config.endpoints.customerOrders.replace('{customerId}', customerId);
            const response = await fetch(`${config.apiBaseUrl}${endpoint}`);
            if (!response.ok) {
                throw new Error(`Failed to fetch customer orders: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error(`Error fetching orders for customer ${customerId}:`, error);
            throw error;
        }
    },
    
    async updateOrderStatus(orderId, customerId, status) {
        try {
            const response = await fetch(`${config.apiBaseUrl}${config.endpoints.orders}/${orderId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    customer_id: customerId,
                    order_status: status
                })
            });
            
            if (!response.ok) {
                throw new Error(`Failed to update order status: ${response.status}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error(`Error updating order ${orderId} status:`, error);
            throw error;
        }
    }
};

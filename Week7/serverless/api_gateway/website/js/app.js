// Main application logic
document.addEventListener('DOMContentLoaded', () => {
    // App state
    const state = {
        products: [],
        cart: [],
        currentSection: 'products',
        customer: {
            id: ''
        }
    };

    // DOM elements
    const elements = {
        productsContainer: document.getElementById('products-container'),
        cartItems: document.getElementById('cart-items'),
        cartCount: document.getElementById('cart-count'),
        cartTotal: document.getElementById('cart-total'),
        checkoutTotal: document.getElementById('checkout-total'),
        checkoutBtn: document.getElementById('checkout-btn'),
        ordersContainer: document.getElementById('orders-container'),
        loadOrdersBtn: document.getElementById('load-orders-btn'),
        customerIdInput: document.getElementById('customer-id'),
        checkoutForm: document.getElementById('checkout-form'),
        checkoutCustomerId: document.getElementById('checkout-customer-id'),
        sections: {
            products: document.getElementById('products'),
            cart: document.getElementById('cart-section'),
            orders: document.getElementById('orders-section'),
            checkout: document.getElementById('checkout-section')
        },
        navLinks: document.querySelectorAll('nav a')
    };

    // Templates
    const templates = {
        product: document.getElementById('product-template'),
        cartItem: document.getElementById('cart-item-template'),
        order: document.getElementById('order-template')
    };

    // Initialize the application
    init();

    // Function to initialize the application
    function init() {
        // Load products
        loadProducts();
        
        // Set up event listeners
        setupEventListeners();
        
        // Initialize cart from localStorage if available
        initCart();
    }

    // Function to load products from the API
    async function loadProducts() {
        try {
            // For development, use mock data if API is not available
            try {
                state.products = await api.getProducts();
            } catch (error) {
                console.warn('Using mock product data due to API error:', error);
                // Mock products for development
                state.products = [
                    {
                        product_id: 'prod_1a2b3c4d',
                        sku: 'HEADPHONES-001',
                        name: 'Wireless Headphones',
                        description: 'High-quality wireless headphones with noise cancellation',
                        price: 99.99,
                        stock_quantity: 50,
                        is_active: true
                    },
                    {
                        product_id: 'prod_5e6f7g8h',
                        sku: 'SPEAKER-001',
                        name: 'Bluetooth Speaker',
                        description: 'Portable Bluetooth speaker with 20 hours of battery life',
                        price: 79.99,
                        stock_quantity: 30,
                        is_active: true
                    },
                    {
                        product_id: 'prod_9i8j7k6l',
                        sku: 'SMARTWATCH-001',
                        name: 'Smart Watch',
                        description: 'Fitness tracker and smartwatch with heart rate monitor',
                        price: 149.99,
                        stock_quantity: 20,
                        is_active: true
                    }
                ];
            }
            
            renderProducts();
        } catch (error) {
            console.error('Failed to load products:', error);
            elements.productsContainer.innerHTML = '<div class="error">Failed to load products. Please try again later.</div>';
        }
    }

    // Function to render products
    function renderProducts() {
        // Clear loading message
        elements.productsContainer.innerHTML = '';
        
        // Render each product
        state.products.forEach(product => {
            const productElement = templates.product.content.cloneNode(true);
            
            // Set product details
            productElement.querySelector('.product-name').textContent = product.name;
            productElement.querySelector('.product-description').textContent = product.description;
            productElement.querySelector('.product-price').textContent = `$${product.price.toFixed(2)}`;
            
            // Set product image (placeholder for now)
            const img = productElement.querySelector('.product-image img');
            img.src = `https://via.placeholder.com/300x200?text=${encodeURIComponent(product.name)}`;
            img.alt = product.name;
            
            // Add to cart button
            const addToCartBtn = productElement.querySelector('.add-to-cart-btn');
            addToCartBtn.dataset.productId = product.product_id;
            
            // Disable button if out of stock
            if (product.stock_quantity <= 0) {
                addToCartBtn.disabled = true;
                addToCartBtn.textContent = 'Out of Stock';
            }
            
            // Append to container
            elements.productsContainer.appendChild(productElement);
        });
    }

    // Function to set up event listeners
    function setupEventListeners() {
        // Navigation
        elements.navLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                
                // Get the section ID from the href
                const sectionId = link.getAttribute('href').substring(1);
                
                // Show the corresponding section
                showSection(sectionId);
                
                // Update active link
                elements.navLinks.forEach(l => l.classList.remove('active'));
                link.classList.add('active');
            });
        });
        
        // Add to cart buttons (delegated)
        elements.productsContainer.addEventListener('click', (e) => {
            if (e.target.classList.contains('add-to-cart-btn')) {
                const productId = e.target.dataset.productId;
                addToCart(productId);
            }
        });
        
        // Cart item quantity and remove buttons (delegated)
        elements.cartItems.addEventListener('click', (e) => {
            const cartItem = e.target.closest('.cart-item');
            if (!cartItem) return;
            
            const productId = cartItem.dataset.productId;
            
            if (e.target.classList.contains('increase')) {
                updateCartItemQuantity(productId, 1);
            } else if (e.target.classList.contains('decrease')) {
                updateCartItemQuantity(productId, -1);
            } else if (e.target.classList.contains('remove-btn')) {
                removeFromCart(productId);
            }
        });
        
        // Checkout button
        elements.checkoutBtn.addEventListener('click', () => {
            if (state.cart.length > 0) {
                showSection('checkout');
                updateCheckoutSummary();
            }
        });
        
        // Load orders button
        elements.loadOrdersBtn.addEventListener('click', () => {
            const customerId = elements.customerIdInput.value.trim();
            if (customerId) {
                state.customer.id = customerId;
                loadCustomerOrders(customerId);
            } else {
                alert('Please enter a customer ID');
            }
        });
        
        // Checkout form submission
        elements.checkoutForm.addEventListener('submit', (e) => {
            e.preventDefault();
            placeOrder();
        });
    }

    // Function to initialize cart from localStorage
    function initCart() {
        const savedCart = localStorage.getItem('cart');
        if (savedCart) {
            try {
                state.cart = JSON.parse(savedCart);
                updateCartUI();
            } catch (error) {
                console.error('Failed to load cart from localStorage:', error);
                state.cart = [];
            }
        }
    }

    // Function to save cart to localStorage
    function saveCart() {
        localStorage.setItem('cart', JSON.stringify(state.cart));
    }

    // Function to add a product to the cart
    function addToCart(productId) {
        // Find the product
        const product = state.products.find(p => p.product_id === productId);
        if (!product) return;
        
        // Check if the product is already in the cart
        const existingItem = state.cart.find(item => item.product_id === productId);
        
        if (existingItem) {
            // Increment quantity if already in cart
            existingItem.quantity++;
        } else {
            // Add new item to cart
            state.cart.push({
                product_id: product.product_id,
                name: product.name,
                price: product.price,
                quantity: 1
            });
        }
        
        // Update UI and save cart
        updateCartUI();
        saveCart();
    }

    // Function to update cart item quantity
    function updateCartItemQuantity(productId, change) {
        const item = state.cart.find(item => item.product_id === productId);
        if (!item) return;
        
        item.quantity += change;
        
        // Remove item if quantity is 0 or less
        if (item.quantity <= 0) {
            removeFromCart(productId);
            return;
        }
        
        // Update UI and save cart
        updateCartUI();
        saveCart();
    }

    // Function to remove an item from the cart
    function removeFromCart(productId) {
        state.cart = state.cart.filter(item => item.product_id !== productId);
        
        // Update UI and save cart
        updateCartUI();
        saveCart();
    }

    // Function to update the cart UI
    function updateCartUI() {
        // Update cart count
        const totalItems = state.cart.reduce((total, item) => total + item.quantity, 0);
        elements.cartCount.textContent = totalItems;
        
        // Enable/disable checkout button
        elements.checkoutBtn.disabled = totalItems === 0;
        
        // Update cart items
        elements.cartItems.innerHTML = '';
        
        if (state.cart.length === 0) {
            elements.cartItems.innerHTML = '<p class="empty-cart">Your cart is empty</p>';
        } else {
            state.cart.forEach(item => {
                const cartItemElement = templates.cartItem.content.cloneNode(true);
                
                // Set item details
                cartItemElement.querySelector('.cart-item').dataset.productId = item.product_id;
                cartItemElement.querySelector('.cart-item-name').textContent = item.name;
                cartItemElement.querySelector('.cart-item-price').textContent = `$${item.price.toFixed(2)}`;
                cartItemElement.querySelector('.quantity').textContent = item.quantity;
                
                // Append to container
                elements.cartItems.appendChild(cartItemElement);
            });
        }
        
        // Update cart total
        const totalPrice = state.cart.reduce((total, item) => total + (item.price * item.quantity), 0);
        elements.cartTotal.textContent = `$${totalPrice.toFixed(2)}`;
    }

    // Function to update checkout summary
    function updateCheckoutSummary() {
        const totalPrice = state.cart.reduce((total, item) => total + (item.price * item.quantity), 0);
        elements.checkoutTotal.textContent = `$${totalPrice.toFixed(2)}`;
        
        // Pre-fill customer ID if available
        if (state.customer.id) {
            elements.checkoutCustomerId.value = state.customer.id;
        }
    }

    // Function to place an order
    async function placeOrder() {
        try {
            // Get form data
            const customerId = elements.checkoutCustomerId.value.trim();
            const street = document.getElementById('checkout-street').value.trim();
            const city = document.getElementById('checkout-city').value.trim();
            const zipCode = document.getElementById('checkout-zip').value.trim();
            const country = document.getElementById('checkout-country').value.trim();
            
            // Create order data
            const orderData = {
                customer_id: customerId,
                shipping_address: {
                    street,
                    city,
                    zip_code: zipCode,
                    country
                },
                items: state.cart.map(item => ({
                    product_id: item.product_id,
                    quantity: item.quantity,
                    price_per_unit: item.price
                }))
            };
            
            // Save customer ID
            state.customer.id = customerId;
            
            // Call API to create order
            try {
                const order = await api.createOrder(orderData);
                
                // Clear cart
                state.cart = [];
                updateCartUI();
                saveCart();
                
                // Show success message
                alert(`Order placed successfully! Order ID: ${order.order_id}`);
                
                // Redirect to orders page
                showSection('orders');
                loadCustomerOrders(customerId);
            } catch (error) {
                console.error('Error placing order:', error);
                alert('Failed to place order. Please try again later.');
            }
        } catch (error) {
            console.error('Error processing order:', error);
            alert('An error occurred while processing your order.');
        }
    }

    // Function to load customer orders
    async function loadCustomerOrders(customerId) {
        try {
            elements.ordersContainer.innerHTML = '<div class="loading">Loading orders...</div>';
            
            try {
                const orders = await api.getCustomerOrders(customerId);
                renderOrders(orders);
            } catch (error) {
                console.warn('Using mock order data due to API error:', error);
                // Mock orders for development
                const mockOrders = [
                    {
                        order_id: 'a1b2c3d4-e5f6-7890-1234-567890abcdef',
                        customer_id: customerId,
                        order_date: '2025-09-21T10:30:00Z',
                        order_status: 'PENDING',
                        total_amount: 149.98,
                        shipping_address: {
                            street: '123 Serverless Way',
                            city: 'Cloud City',
                            zip_code: '12345',
                            country: 'AWS'
                        },
                        items: [
                            {
                                product_id: 'prod_1a2b3c4d',
                                quantity: 1,
                                price_per_unit: 99.99
                            },
                            {
                                product_id: 'prod_5e6f7g8h',
                                quantity: 2,
                                price_per_unit: 24.99
                            }
                        ]
                    }
                ];
                renderOrders(mockOrders);
            }
        } catch (error) {
            console.error('Failed to load orders:', error);
            elements.ordersContainer.innerHTML = '<div class="error">Failed to load orders. Please try again later.</div>';
        }
    }

    // Function to render orders
    function renderOrders(orders) {
        elements.ordersContainer.innerHTML = '';
        
        if (orders.length === 0) {
            elements.ordersContainer.innerHTML = '<div class="empty-orders">No orders found for this customer.</div>';
            return;
        }
        
        orders.forEach(order => {
            const orderElement = templates.order.content.cloneNode(true);
            
            // Set order details
            orderElement.querySelector('.order-id').textContent = order.order_id;
            orderElement.querySelector('.order-date').textContent = formatDate(order.order_date);
            
            // Set order status with appropriate class
            const statusElement = orderElement.querySelector('.order-status');
            statusElement.textContent = order.order_status;
            statusElement.classList.add(`status-${order.order_status.toLowerCase()}`);
            
            // Set order items
            const orderItemsContainer = orderElement.querySelector('.order-items');
            order.items.forEach(item => {
                const orderItem = document.createElement('div');
                orderItem.className = 'order-item';
                orderItem.innerHTML = `
                    <div class="order-item-name">${getProductName(item.product_id)} (x${item.quantity})</div>
                    <div class="order-item-price">$${(item.price_per_unit * item.quantity).toFixed(2)}</div>
                `;
                orderItemsContainer.appendChild(orderItem);
            });
            
            // Set total amount
            orderElement.querySelector('.total-amount').textContent = `$${order.total_amount.toFixed(2)}`;
            
            // Set shipping address
            orderElement.querySelector('.address-street').textContent = order.shipping_address.street;
            orderElement.querySelector('.address-city-zip').textContent = `${order.shipping_address.city}, ${order.shipping_address.zip_code}`;
            orderElement.querySelector('.address-country').textContent = order.shipping_address.country;
            
            // Append to container
            elements.ordersContainer.appendChild(orderElement);
        });
    }

    // Function to get product name from product ID
    function getProductName(productId) {
        const product = state.products.find(p => p.product_id === productId);
        return product ? product.name : 'Unknown Product';
    }

    // Function to format date
    function formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleString();
    }

    // Function to show a specific section
    function showSection(sectionId) {
        // Hide all sections
        Object.values(elements.sections).forEach(section => {
            section.classList.add('hidden');
        });
        
        // Show the selected section
        if (elements.sections[sectionId]) {
            elements.sections[sectionId].classList.remove('hidden');
            state.currentSection = sectionId;
        } else if (sectionId === 'cart') {
            elements.sections.cart.classList.remove('hidden');
            state.currentSection = 'cart';
        }
    }
});

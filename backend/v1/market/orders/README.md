# Orders Management API Documentation

## Overview
The Orders Management API provides a secure and organized way to manage marketplace orders with proper role-based access control. The API is organized into separate endpoints for customers, sellers, and administrators.

## 📁 API Structure

```
/api/v2/market/orders/
├── customers/           # Customer-specific endpoints
│   ├── my-orders.php           # List customer's own orders
│   ├── my-order-details.php    # Get customer's order details
│   ├── place-order.php         # Create new order
│   └── cancel-order.php        # Cancel customer's order
├── sellers/            # Seller-specific endpoints
│   ├── seller-orders.php       # List seller's orders to fulfill
│   ├── seller-order-details.php # Get seller's order details
│   └── update-status.php       # Update order status
├── admin/              # Admin endpoints
│   ├── admin-list.php          # List all orders (admin access)
│   └── admin-details.php       # Get any order details (admin access)
├── shared/             # Shared utilities
│   └── order-utils.php         # Common functions
└── README.md           # This documentation
```

## 🔐 Security & Access Control

### Customer APIs
- **Access**: Only customers can access their own orders
- **Required**: `customer_id` parameter for authentication
- **Scope**: Limited to orders where `customer_id` matches

### Seller APIs
- **Access**: Only sellers can access orders they need to fulfill
- **Required**: `seller_id` parameter for authentication
- **Scope**: Limited to orders where `seller_id` matches

### Admin APIs
- **Access**: Full access to all orders
- **Required**: No specific authentication (assumes admin role)
- **Scope**: Complete access to all order data

## 📋 API Endpoints

### Customer Endpoints

#### 1. List Customer Orders
```
GET /customers/my-orders.php
```

**Parameters:**
- `customer_id` (required): Customer ID for authentication
- `status` (optional): Filter by order status
- `limit` (optional): Number of orders per page (default: 10)
- `page` (optional): Page number (default: 1)

**Response:**
```json
{
  "success": true,
  "data": {
    "orders": [...],
    "pagination": {
      "current_page": 1,
      "total_pages": 1,
      "total_orders": "2",
      "limit": 10,
      "has_next": false,
      "has_prev": false
    }
  }
}
```

#### 2. Get Customer Order Details
```
GET /customers/my-order-details.php
```

**Parameters:**
- `id` (required): Order ID
- `customer_id` (required): Customer ID for authentication

**Response:** Complete order details including items, payment, and status history

#### 3. Place New Order
```
POST /customers/place-order.php
```

**Request Body:**
```json
{
  "customer_id": 1,
  "seller_id": 2,
  "total_amount": 5000,
  "currency": "RWF",
  "shipping_address": "Kigali, Rwanda",
  "shipping_notes": "Please deliver during business hours",
  "items": [
    {
      "product_id": 1,
      "quantity": 2,
      "unit_price": 2500
    }
  ]
}
```

#### 4. Cancel Order
```
PUT /customers/cancel-order.php
```

**Request Body:**
```json
{
  "order_id": 3,
  "customer_id": 1,
  "cancellation_reason": "Changed my mind"
}
```

### Seller Endpoints

#### 1. List Seller Orders
```
GET /sellers/seller-orders.php
```

**Parameters:**
- `seller_id` (required): Seller ID for authentication
- `status` (optional): Filter by order status
- `limit` (optional): Number of orders per page (default: 10)
- `page` (optional): Page number (default: 1)

#### 2. Get Seller Order Details
```
GET /sellers/seller-order-details.php
```

**Parameters:**
- `id` (required): Order ID
- `seller_id` (required): Seller ID for authentication

#### 3. Update Order Status
```
PUT /sellers/update-status.php
```

**Request Body:**
```json
{
  "order_id": 3,
  "seller_id": 2,
  "status": "confirmed",
  "changed_by": "seller_2",
  "notes": "Order confirmed and processing"
}
```

### Admin Endpoints

#### 1. List All Orders
```
GET /admin/admin-list.php
```

**Parameters:**
- `customer_id` (optional): Filter by customer
- `seller_id` (optional): Filter by seller
- `status` (optional): Filter by status
- `limit` (optional): Number of orders per page (default: 20)
- `page` (optional): Page number (default: 1)

#### 2. Get Any Order Details
```
GET /admin/admin-details.php
```

**Parameters:**
- `id` (required): Order ID

## 🗄️ Database Schema

### Orders Table
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_no VARCHAR(50) UNIQUE NOT NULL,
    customer_id INT NOT NULL,
    seller_id INT NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RWF',
    status VARCHAR(50) DEFAULT 'pending',
    shipping_address TEXT NOT NULL,
    shipping_notes TEXT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    cancellation_reason TEXT,
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (seller_id) REFERENCES users(id)
);
```

### Order Items Table
```sql
CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(15,2) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RWF',
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id),
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id)
);
```

## 🔄 Order Status Flow

1. **pending** → Initial order status
2. **confirmed** → Seller confirms order
3. **processing** → Seller starts processing
4. **shipped** → Order shipped
5. **delivered** → Order delivered
6. **cancelled** → Order cancelled (by customer or seller)
7. **refunded** → Order refunded

## 📊 Response Format

All APIs return consistent JSON responses:

**Success Response:**
```json
{
  "success": true,
  "data": {...}
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message"
}
```

## 🚀 Usage Examples

### Customer placing an order:
```bash
curl -X POST "http://localhost/gemura2/api/v2/market/orders/customers/place-order.php" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 1,
    "seller_id": 2,
    "total_amount": 5000,
    "currency": "RWF",
    "shipping_address": "Kigali, Rwanda",
    "items": [{"product_id": 1, "quantity": 2, "unit_price": 2500}]
  }'
```

### Seller updating order status:
```bash
curl -X PUT "http://localhost/gemura2/api/v2/market/orders/sellers/update-status.php" \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": 3,
    "seller_id": 2,
    "status": "confirmed"
  }'
```

### Admin viewing all orders:
```bash
curl -X GET "http://localhost/gemura2/api/v2/market/orders/admin/admin-list.php?limit=10&page=1"
```

## 🔧 Shared Utilities

The `shared/order-utils.php` file contains common functions:
- `getOrderItems()` - Retrieve order items with product details
- `getOrderPayment()` - Get payment information
- `getOrderStatusHistory()` - Get status change history
- `generateOrderNumber()` - Generate unique order numbers
- `isValidOrderStatus()` - Validate order status
- `canAccessOrder()` - Check user access permissions

## 🛡️ Security Features

1. **Role-based Access Control**: Different endpoints for different user types
2. **Data Isolation**: Users can only access their own data
3. **Input Validation**: All inputs are validated and sanitized
4. **Transaction Safety**: Database operations use transactions
5. **Error Handling**: Graceful error handling without exposing sensitive information

## 📝 Notes

- All APIs use the `$connection` variable for database access
- Missing tables (order_status_history, payments) are handled gracefully
- APIs are designed to work with or without the history tables
- All monetary values are returned as floats for precision
- Dates are returned in MySQL timestamp format

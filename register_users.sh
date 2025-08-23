#!/bin/bash

# Gemura v2 API User Registration Script
# This script registers multiple users with different roles

BASE_URL="https://api.gemura.rw/v2"

# Function to register a user
register_user() {
    local name="$1"
    local email="$2"
    local phone="$3"
    local nid="$4"
    local role="$5"
    local account_name="$6"
    
    echo "Registering user: $name ($email)"
    
    response=$(curl -s -X POST "$BASE_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"$name\",
            \"email\": \"$email\",
            \"phone\": \"$phone\",
            \"password\": \"password123\",
            \"nid\": \"$nid\",
            \"role\": \"$role\",
            \"account_name\": \"$account_name\",
            \"permissions\": {
                \"can_collect\": true,
                \"can_add_supplier\": true,
                \"can_view_reports\": true
            }
        }")
    
    echo "Response: $response"
    echo "----------------------------------------"
    
    # Extract token for supplier creation
    token=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ ! -z "$token" ]; then
        echo "Token extracted: ${token:0:20}..."
        echo "$name|$email|$token" >> registered_users.txt
    fi
}

# Clear previous results
> registered_users.txt

echo "Starting user registration..."
echo "================================"

# Register Admin Users (1 admin)
register_user "Admin User" "admin@gemura.rw" "+250788000001" "1199999999999991" "owner" "Gemura Admin Farm"

# Register Customer Users (4 customers)
register_user "Customer One" "customer1@gemura.rw" "+250788000002" "1199999999999992" "owner" "Customer One Farm"
register_user "Customer Two" "customer2@gemura.rw" "+250788000003" "1199999999999993" "owner" "Customer Two Farm"
register_user "Customer Three" "customer3@gemura.rw" "+250788000004" "1199999999999994" "owner" "Customer Three Farm"
register_user "Customer Four" "customer4@gemura.rw" "+250788000005" "1199999999999995" "owner" "Customer Four Farm"

# Register Supplier Users (34 suppliers)
for i in {1..34}; do
    name="Supplier $i"
    email="supplier$i@gemura.rw"
    phone=$(printf "+250788%06d" $((100000 + i)))
    nid=$(printf "119988%012d" $((100000000000 + i)))
    account_name="Supplier $i Farm"
    
    register_user "$name" "$email" "$phone" "$nid" "owner" "$account_name"
done

echo "Registration completed!"
echo "Check registered_users.txt for user details and tokens"

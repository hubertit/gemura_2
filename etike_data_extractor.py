#!/usr/bin/env python3
"""
Etike API Data Extractor
Fetches order data from https://api.etike.rw/orders/all_orders.php
and saves it to an Excel file on the desktop.
"""

import requests
import pandas as pd
import json
from datetime import datetime
import os

def fetch_etike_data():
    """Fetch data from Etike API"""
    url = "https://api.etike.rw/orders/all_orders.php"
    
    try:
        print("Fetching data from Etike API...")
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        print(f"✅ Successfully fetched data. Status: {data.get('status')}")
        return data
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error fetching data: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        return None

def process_orders_data(api_data):
    """Process orders data into a flat structure for Excel"""
    if not api_data or api_data.get('status') != 'success':
        print("❌ Invalid API response")
        return None
    
    orders = api_data.get('data', {}).get('orders', [])
    processed_orders = []
    
    for order in orders:
        # Extract order-level data
        order_base = {
            'Order ID': order.get('order_id'),
            'Order Code': order.get('order_code'),
            'Customer ID': order.get('customer_id'),
            'Order Date': order.get('order_date'),
            'Currency': order.get('currency'),
            'Total Amount': float(order.get('total_amount', 0)),
            'VAT Amount': float(order.get('vat_amount', 0)),
            'VAT Rate': float(order.get('vat_rate', 0)),
            'Payment Method': order.get('payment_method'),
            'Order Status': order.get('order_status'),
            'Payment Status': order.get('payment_status'),
            'Created At': order.get('created_at'),
            'Updated At': order.get('updated_at')
        }
        
        # Process each item in the order
        items = order.get('items', [])
        if items:
            for item in items:
                order_item = order_base.copy()
                order_item.update({
                    'Item ID': item.get('item_id'),
                    'Package ID': item.get('package_id'),
                    'Package Title': item.get('package_title'),
                    'Event Date': item.get('event_date'),
                    'Item Price': float(item.get('price', 0)),
                    'Quantity': int(item.get('quantity', 0)),
                    'Subtotal': float(item.get('subtotal', 0)),
                    'Ticket Status': item.get('ticket_status'),
                    'Scan Status': item.get('scan_status')
                })
                processed_orders.append(order_item)
        else:
            # If no items, just add the order data
            processed_orders.append(order_base)
    
    return processed_orders

def process_summary_data(api_data):
    """Process summary data for Excel"""
    if not api_data or api_data.get('status') != 'success':
        return None
    
    summary = api_data.get('data', {}).get('summary', [])
    processed_summary = []
    
    for item in summary:
        processed_summary.append({
            'Package Title': item.get('package_title'),
            'Event Date': item.get('event_date'),
            'Total Tickets': int(item.get('total_tickets', 0)),
            'Total Revenue': float(item.get('total_revenue', 0))
        })
    
    return processed_summary

def save_to_excel(orders_data, summary_data, filename):
    """Save data to Excel file with multiple sheets"""
    try:
        # Get desktop path
        desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
        file_path = os.path.join(desktop_path, filename)
        
        with pd.ExcelWriter(file_path, engine='openpyxl') as writer:
            # Orders sheet
            if orders_data:
                orders_df = pd.DataFrame(orders_data)
                orders_df.to_excel(writer, sheet_name='Orders', index=False)
                print(f"✅ Orders data: {len(orders_data)} records")
            
            # Summary sheet
            if summary_data:
                summary_df = pd.DataFrame(summary_data)
                summary_df.to_excel(writer, sheet_name='Summary', index=False)
                print(f"✅ Summary data: {len(summary_data)} records")
        
        print(f"📊 Excel file saved successfully: {file_path}")
        return file_path
        
    except Exception as e:
        print(f"❌ Error saving Excel file: {e}")
        return None

def main():
    """Main function"""
    print("🚀 Etike API Data Extractor")
    print("=" * 50)
    
    # Fetch data from API
    api_data = fetch_etike_data()
    if not api_data:
        return
    
    # Process data
    print("\n📋 Processing data...")
    orders_data = process_orders_data(api_data)
    summary_data = process_summary_data(api_data)
    
    if not orders_data and not summary_data:
        print("❌ No data to process")
        return
    
    # Generate filename with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"etike_orders_{timestamp}.xlsx"
    
    # Save to Excel
    print(f"\n💾 Saving to Excel file: {filename}")
    file_path = save_to_excel(orders_data, summary_data, filename)
    
    if file_path:
        print(f"\n🎉 Success! Data extracted and saved to:")
        print(f"📁 {file_path}")
        
        # Print summary statistics
        if orders_data:
            total_orders = len(set(order['Order ID'] for order in orders_data))
            total_revenue = sum(order['Total Amount'] for order in orders_data)
            print(f"\n📈 Summary Statistics:")
            print(f"   • Total Orders: {total_orders}")
            print(f"   • Total Order Items: {len(orders_data)}")
            print(f"   • Total Revenue: ${total_revenue:,.2f} USD")
        
        if summary_data:
            total_tickets = sum(item['Total Tickets'] for item in summary_data)
            total_summary_revenue = sum(item['Total Revenue'] for item in summary_data)
            print(f"   • Total Tickets Sold: {total_tickets}")
            print(f"   • Total Summary Revenue: ${total_summary_revenue:,.2f} USD")
    else:
        print("❌ Failed to save Excel file")

if __name__ == "__main__":
    main()

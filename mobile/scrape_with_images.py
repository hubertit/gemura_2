#!/usr/bin/env python3
"""
Script to scrape posts from Kigali Today with images and post them to Gemura feed
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import re
from urllib.parse import urljoin, urlparse
import hashlib

# Configuration
BASE_URL = "https://www.kigalitoday.com/ubuhinzi/ubworozi/"
API_BASE_URL = "https://api.gemura.rw/v2"
PHONE = "250788000000"
PASSWORD = "Pass123"
MAX_POSTS = 20

def login_and_get_token():
    """Login to get authentication token"""
    login_url = f"{API_BASE_URL}/auth/login.php"
    login_data = {
        "identifier": PHONE,
        "password": PASSWORD
    }
    
    try:
        response = requests.post(login_url, json=login_data)
        if response.status_code == 200:
            data = response.json()
            if data.get('code') == 200:
                return data['data']['user']['token']
        print(f"Login failed: {response.text}")
        return None
    except Exception as e:
        print(f"Login error: {e}")
        return None

def scrape_posts_with_images():
    """Scrape posts from Kigali Today with images"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(BASE_URL, headers=headers)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        posts = []
        
        # Find all images on the page that might be article images
        images = soup.find_all('img')
        
        for img in images:
            src = img.get('src')
            if not src:
                continue
                
            # Make sure it's a full URL
            if src.startswith('/'):
                src = urljoin(BASE_URL, src)
            elif not src.startswith('http'):
                continue
                
            # Skip external images
            if 'kigalitoday.com' not in src:
                continue
                
            # Skip small images (likely icons, buttons, etc.)
            if any(skip in src.lower() for skip in ['icon', 'logo', 'button', 'social', 'facebook', 'twitter']):
                continue
                
            # Look for article title near this image
            title = None
            
            # Check parent elements for text content
            parent = img.parent
            while parent and not title:
                # Look for headings or strong text
                heading = parent.find(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'strong', 'b'])
                if heading:
                    title = heading.get_text(strip=True)
                    break
                
                # Look for links with substantial text
                link = parent.find('a')
                if link:
                    link_text = link.get_text(strip=True)
                    if len(link_text) > 20:
                        title = link_text
                        break
                
                parent = parent.parent
            
            # If no title found, create a generic one
            if not title:
                title = f"Agriculture News - {len(posts) + 1}"
            
            # Skip if title is too short or generic
            if len(title) < 10:
                continue
                
            posts.append({
                'url': BASE_URL,  # Use base URL since we don't have specific article URLs
                'title': title,
                'content': title,
                'image_url': src
            })
            
            if len(posts) >= MAX_POSTS:
                break
        
        print(f"Found {len(posts)} posts with images")
        for i, post in enumerate(posts, 1):
            print(f"{i}. {post['title'][:60]}...")
            print(f"   Image: {post['image_url']}")
        
        return posts[:MAX_POSTS]
        
    except Exception as e:
        print(f"Scraping error: {e}")
        return []

def get_article_content(url):
    """Get full article content and image"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract main content
        content_selectors = [
            'div.article-content',
            'div.content',
            'div.post-content',
            'article',
            'div.entry-content'
        ]
        
        content = ""
        for selector in content_selectors:
            content_elem = soup.select_one(selector)
            if content_elem:
                content = content_elem.get_text(strip=True)
                break
        
        # If no specific content found, get all text
        if not content:
            content = soup.get_text(strip=True)
        
        # Extract image
        image_url = None
        img_selectors = [
            'img.article-image',
            'img.featured-image',
            'img.post-image',
            'img'
        ]
        
        for selector in img_selectors:
            img_elem = soup.select_one(selector)
            if img_elem and img_elem.get('src'):
                src = img_elem.get('src')
                if src.startswith('/'):
                    src = urljoin(url, src)
                elif not src.startswith('http'):
                    continue
                image_url = src
                break
        
        return content, image_url
        
    except Exception as e:
        print(f"Error getting article content from {url}: {e}")
        return None, None

def summarize_content(content, max_length=200):
    """Summarize content to avoid overloading"""
    if len(content) <= max_length:
        return content
    
    # Try to find a good breaking point
    sentences = content.split('. ')
    summary = ""
    
    for sentence in sentences:
        if len(summary + sentence) <= max_length:
            summary += sentence + ". "
        else:
            break
    
    if not summary:
        summary = content[:max_length] + "..."
    
    return summary.strip()

def create_post_data(post, token):
    """Create post data for API"""
    # Use the scraped image URL directly
    image_url = post.get('image_url')
    
    # Create hashtags based on content
    hashtags = ["#ubworozi", "#ubuhinzi", "#amakuru", "#rwanda"]
    
    # Add location
    location = "Rwanda"
    
    post_data = {
        "token": token,
        "content": f"{post['title']}\n\n{post['content']}",
        "hashtags": hashtags,
        "location": location
    }
    
    if image_url:
        post_data["media_url"] = image_url
        print(f"   📸 Using image: {image_url}")
    
    return post_data

def post_to_feed(post_data):
    """Post to Gemura feed API"""
    try:
        url = f"{API_BASE_URL}/feed/create.php"
        response = requests.post(url, json=post_data)
        
        if response.status_code == 200:
            data = response.json()
            if data.get('code') == 201:
                return True, "Success"
            else:
                return False, data.get('message', 'Unknown error')
        else:
            return False, f"HTTP {response.status_code}: {response.text}"
            
    except Exception as e:
        return False, str(e)

def main():
    print("🚀 Starting Kigali Today scraping with images...")
    
    # Login and get token
    print("🔐 Logging in...")
    token = login_and_get_token()
    if not token:
        print("❌ Failed to get authentication token")
        return
    
    print("✅ Login successful")
    
    # Scrape posts with images
    print(f"📰 Scraping posts with images from {BASE_URL}...")
    posts = scrape_posts_with_images()
    
    if not posts:
        print("❌ No posts found")
        return
    
    print(f"✅ Found {len(posts)} posts with images")
    
    # Process and post each article
    successful_posts = 0
    
    for i, post in enumerate(posts, 1):
        print(f"\n📝 Processing post {i}/{len(posts)}: {post['title'][:50]}...")
        
        try:
            # Create post data
            post_data = create_post_data(post, token)
            
            # Post to feed
            success, message = post_to_feed(post_data)
            
            if success:
                print(f"✅ Posted successfully with image")
                successful_posts += 1
            else:
                print(f"❌ Failed to post: {message}")
            
            # Add delay to avoid rate limiting
            time.sleep(3)
            
        except Exception as e:
            print(f"❌ Error processing post: {e}")
            continue
    
    print(f"\n🎉 Completed! Successfully posted {successful_posts}/{len(posts)} posts with images")

if __name__ == "__main__":
    main()

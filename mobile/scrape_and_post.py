#!/usr/bin/env python3
"""
Script to scrape posts from Kigali Today and post them to Gemura feed
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

def scrape_posts():
    """Scrape posts from Kigali Today"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        response = requests.get(BASE_URL, headers=headers)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        posts = []
        
        # Look for article titles and links in the content
        # Based on the website structure, look for headings and links
        
        # Find all headings that might be article titles
        headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
        
        for heading in headings:
            # Get the text content
            title_text = heading.get_text(strip=True)
            
            # Skip if no title or too short
            if not title_text or len(title_text) < 20:
                continue
                
            # Skip navigation items
            if any(skip in title_text.lower() for skip in ['navigation', 'menu', 'search', 'login']):
                continue
            
            # Look for a link within or near this heading
            link = heading.find('a', href=True)
            if not link:
                # Look for links in parent or sibling elements
                parent = heading.parent
                if parent:
                    link = parent.find('a', href=True)
            
            if link:
                href = link.get('href')
                
                # Make sure it's a full URL
                if href.startswith('/'):
                    href = urljoin(BASE_URL, href)
                elif not href.startswith('http'):
                    continue
                    
                # Skip external links
                if 'kigalitoday.com' not in href:
                    continue
                    
                posts.append({
                    'url': href,
                    'title': title_text,
                    'content': title_text
                })
                
                if len(posts) >= MAX_POSTS:
                    break
        
        # If we didn't find enough posts, look for any links with substantial text
        if len(posts) < MAX_POSTS:
            all_links = soup.find_all('a', href=True)
            
            for link in all_links:
                href = link.get('href')
                title_text = link.get_text(strip=True)
                
                # Skip if no title or too short
                if not title_text or len(title_text) < 20:
                    continue
                    
                # Skip navigation and non-article links
                if any(skip in href.lower() for skip in ['spip.php', 'mailto:', 'javascript:', '#']):
                    continue
                    
                # Make sure it's a full URL
                if href.startswith('/'):
                    href = urljoin(BASE_URL, href)
                elif not href.startswith('http'):
                    continue
                    
                # Skip external links
                if 'kigalitoday.com' not in href:
                    continue
                    
                # Check if we already have this post
                if not any(p['url'] == href for p in posts):
                    posts.append({
                        'url': href,
                        'title': title_text,
                        'content': title_text
                    })
                    
                    if len(posts) >= MAX_POSTS:
                        break
        
        print(f"Found {len(posts)} posts")
        for i, post in enumerate(posts, 1):
            print(f"{i}. {post['title'][:60]}...")
        
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
    content, image_url = get_article_content(post['url'])
    
    if not content:
        content = post['title']
    
    # Summarize content
    summary = summarize_content(content)
    
    # Create hashtags based on content
    hashtags = ["#ubworozi", "#ubuhinzi", "#amakuru", "#rwanda"]
    
    # Add location
    location = "Rwanda"
    
    post_data = {
        "token": token,
        "content": f"{post['title']}\n\n{summary}",
        "hashtags": hashtags,
        "location": location
    }
    
    if image_url:
        post_data["media_url"] = image_url
    
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
    print("🚀 Starting Kigali Today scraping and posting...")
    
    # Login and get token
    print("🔐 Logging in...")
    token = login_and_get_token()
    if not token:
        print("❌ Failed to get authentication token")
        return
    
    print("✅ Login successful")
    
    # Scrape posts
    print(f"📰 Scraping posts from {BASE_URL}...")
    posts = scrape_posts()
    
    if not posts:
        print("❌ No posts found")
        return
    
    print(f"✅ Found {len(posts)} posts")
    
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
                print(f"✅ Posted successfully")
                successful_posts += 1
            else:
                print(f"❌ Failed to post: {message}")
            
            # Add delay to avoid rate limiting
            time.sleep(2)
            
        except Exception as e:
            print(f"❌ Error processing post: {e}")
            continue
    
    print(f"\n🎉 Completed! Successfully posted {successful_posts}/{len(posts)} posts")

if __name__ == "__main__":
    main()

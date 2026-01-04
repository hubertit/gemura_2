#!/usr/bin/env python3
"""
Script to post agriculture content with real Kigali Today images
"""

import requests
import json
import time

# Configuration
API_BASE_URL = "https://api.gemura.rw/v2"
PHONE = "250788000000"
PASSWORD = "Pass123"

# Real agriculture posts with actual Kigali Today style images
REAL_AGRICULTURE_POSTS = [
    {
        "title": "Abahinzi n'aborozi bashinganishije ibyabo bamaze gushumbushwa asaga Miliyari 7Frw",
        "content": "Minisitiri w'Intebe, Dr Nsengiyumva Justin, yatangaje ko Abahinzi n'aborozi bashinganishije ibyabo bashumbushijwe asaga Miliyari 7Frw kuva gahunda yo kwishingira ibihingwa n'amatumgo yatangira mu 2019. Icyo gikaba cyarakumiriye igihombo bahuraga na cyo mbere.",
        "hashtags": ["#ubuhinzi", "#ubworozi", "#rwanda", "#amakuru"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton12345-abc123.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "U Rwanda rugiye kongera umukamo rufatiye urugero kuri Brazil",
        "content": "Minisitiri w'Ubuhinzi n'Ubworozi, Dr Mark Cyubahiro Bagabe, avuga ko u Rwanda rugiye kuvugurura icyororo cy'inka zitanga umukamo, rushingiye ku buryo bukoreshwa muri Brazil. Icyo kizajya rukube gatatu ingano y'amata aboneka ku munsi, kugeza ubu angana na litiro Miliyoni eshatu.",
        "hashtags": ["#ubworozi", "#amata", "#rwanda", "#iterambere"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton67890-def456.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Abakurikirana iby'ubworozi bakomeje gushaka uko umusaruro w'amata wakwiyongera muri Afurika",
        "content": "Abarenga 500 baturutse ku migabane itandukanye, bateraniye mu Rwanda guhera ku wa Kane tariki 29 Gicurasi 2025, bashakira hamwe ibisubizo by'uko umusaruro w'amata wakwiyongera muri Afurika.",
        "hashtags": ["#ubworozi", "#amata", "#afurika", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton11111-ghi789.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Nyagatare: Aborozi barifuza kwemererwa kwitumiriza intanga",
        "content": "Bamwe mu borozi mu Karere ka Nyagatare bavuga ko bifuza koroherezwa kwitumiriza hanze intanga z'amatumgo, kuko kenshi hari igihe bibagora kuzibona bitewe n'uko zitumizwa na RAB gusa, bigatuma rimwe na rimwe batazibonera igihe bazishakiye.",
        "hashtags": ["#ubworozi", "#nyagatare", "#intanga", "#rwanda"],
        "location": "Nyagatare, Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton22222-jkl012.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Abaganga b'amatumgo barasabwa kurushaho kwegera aborozi",
        "content": "Abaganga b'amatumgo barasabwa kurushaho kwegera aborozi kugira ngo babafashe mu kurwanya indwara z'amatumgo no kuzongera umusaruro wabo.",
        "hashtags": ["#ubworozi", "#amatungo", "#ubuvuzi", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton33333-mno345.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Bahamya ko bikuye mu bukene babikesha amatumgo magufi",
        "content": "Hari abaturage bo mu turere 15 tw'Intara y'Amajyepfo, Amajyaruguru n'Iburengerazuba bavuga ko barwanyije imirire mibi ndetse n'imibereho muri rusange irahinduka byihuse, babikesheje umushinga wiswe PRISM wa Minisiteri y'Ubuhinzi n'Ubworozi(MINAGRI).",
        "hashtags": ["#ubworozi", "#amatungo", "#prism", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton44444-pqr678.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "U Rwanda rwahagurukiye kuzamura umusaruro w'amafi",
        "content": "Muri Kamena 2024, u Rwanda rwari rugeze ku musaruro w'amafi wa toni 48,133 ku rwego rw'Igihugu, aho toni 9,000 muri zo arizo ziva mu bworozi bwayo andi akava mu burobyi busanzwe, gusa uwo musaruro ngo uracyari hasi, intego ikaba ari ukuwuzamura.",
        "hashtags": ["#ubworozi", "#amafi", "#rwanda", "#iterambere"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton55555-stu901.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Ibibwana by'ingurube bigiye kujya bihabwa amata y'ifu",
        "content": "Aborozi b'ingurube mu Rwanda batangaje ko mu gihe cy'amezi arindwi, bazaba batangije gahunda yo guha ibibwana by'ingurube amata yo kunywa byakorewe, kugira ngo za nyina zororoke vuba.",
        "hashtags": ["#ubworozi", "#ingurube", "#amata", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton66666-vwx234.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Gakenke: Barishimira ikoranabuhanga risigaye rikoreshwa mu kubegereza intanga z'ingurube",
        "content": "Aborozi b'ingurube bo mu Karere ka Gakenke, basanga uburyo bwo kubegereza intanga z'ingurube hakoreshejwe ikoranabuhanga ry'utudege duto tutagira Abapilote 'Drone', hari urwego rufatika bimaze kubagezaho.",
        "hashtags": ["#ubworozi", "#ingurube", "#ikoranabuhanga", "#gakenke"],
        "location": "Gakenke, Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton77777-yza567.jpg"  # Placeholder for real Kigali Today image
    },
    {
        "title": "Musanze: Batashye uruganda ruzaca akajagari mu gutunganya inyama z'ingurube",
        "content": "Mu Karere ka Musanze huzuye uruganda ruzajya rutunganya inyama z'ingurube hagamijwe kurushaho kuzongerera agaciro mu buryo bwubahirije ubuziranenge.",
        "hashtags": ["#ubworozi", "#ingurube", "#musanze", "#rwanda"],
        "location": "Musanze, Rwanda",
        "image_url": "https://www.kigalitoday.com/local/cache-vignettes/L200xH150/arton88888-bcd890.jpg"  # Placeholder for real Kigali Today image
    }
]

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
    print("🚀 Starting agriculture content posting with Kigali Today style images...")
    print("⚠️  Note: Using placeholder image URLs - these would be replaced with actual Kigali Today images")
    
    # Login and get token
    print("🔐 Logging in...")
    token = login_and_get_token()
    if not token:
        print("❌ Failed to get authentication token")
        return
    
    print("✅ Login successful")
    
    # Post each sample article with Kigali Today style images
    successful_posts = 0
    
    for i, post in enumerate(REAL_AGRICULTURE_POSTS, 1):
        print(f"\n📝 Processing post {i}/{len(REAL_AGRICULTURE_POSTS)}: {post['title'][:50]}...")
        print(f"   📸 Kigali Today style image: {post['image_url']}")
        
        try:
            # Create post data
            post_data = {
                "token": token,
                "content": f"{post['title']}\n\n{post['content']}",
                "hashtags": post['hashtags'],
                "location": post['location'],
                "media_url": post['image_url']
            }
            
            # Post to feed
            success, message = post_to_feed(post_data)
            
            if success:
                print(f"✅ Posted successfully with Kigali Today style image")
                successful_posts += 1
            else:
                print(f"❌ Failed to post: {message}")
            
            # Add delay to avoid rate limiting
            time.sleep(3)
            
        except Exception as e:
            print(f"❌ Error processing post: {e}")
            continue
    
    print(f"\n🎉 Completed! Successfully posted {successful_posts}/{len(REAL_AGRICULTURE_POSTS)} posts with Kigali Today style images")
    print("💡 To get real images, we would need to:")
    print("   1. Manually visit the Kigali Today website")
    print("   2. Right-click on article images and copy image URLs")
    print("   3. Replace the placeholder URLs with real ones")

if __name__ == "__main__":
    main()

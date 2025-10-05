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

# Real agriculture posts with actual Kigali Today images
REAL_KIGALI_TODAY_POSTS = [
    {
        "title": "Abahinzi n'aborozi bashinganishije ibyabo bamaze gushumbushwa asaga Miliyari 7Frw",
        "content": "Minisitiri w'Intebe, Dr Nsengiyumva Justin, yatangaje ko Abahinzi n'aborozi bashinganishije ibyabo bashumbushijwe asaga Miliyari 7Frw kuva gahunda yo kwishingira ibihingwa n'amatumgo yatangira mu 2019. Icyo gikaba cyarakumiriye igihombo bahuraga na cyo mbere.",
        "hashtags": ["#ubuhinzi", "#ubworozi", "#rwanda", "#amakuru"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/444-12.jpg"
    },
    {
        "title": "U Rwanda rugiye kongera umukamo rufatiye urugero kuri Brazil",
        "content": "Minisitiri w'Ubuhinzi n'Ubworozi, Dr Mark Cyubahiro Bagabe, avuga ko u Rwanda rugiye kuvugurura icyororo cy'inka zitanga umukamo, rushingiye ku buryo bukoreshwa muri Brazil. Icyo kizajya rukube gatatu ingano y'amata aboneka ku munsi, kugeza ubu angana na litiro Miliyoni eshatu.",
        "hashtags": ["#ubworozi", "#amata", "#rwanda", "#iterambere"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/agri-2.jpg"
    },
    {
        "title": "Abakurikirana iby'ubworozi bakomeje gushaka uko umusaruro w'amata wakwiyongera muri Afurika",
        "content": "Abarenga 500 baturutse ku migabane itandukanye, bateraniye mu Rwanda guhera ku wa Kane tariki 29 Gicurasi 2025, bashakira hamwe ibisubizo by'uko umusaruro w'amata wakwiyongera muri Afurika.",
        "hashtags": ["#ubworozi", "#amata", "#afurika", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/ok-107.jpg"
    },
    {
        "title": "Nyagatare: Aborozi barifuza kwemererwa kwitumiriza intanga",
        "content": "Bamwe mu borozi mu Karere ka Nyagatare bavuga ko bifuza koroherezwa kwitumiriza hanze intanga z'amatumgo, kuko kenshi hari igihe bibagora kuzibona bitewe n'uko zitumizwa na RAB gusa, bigatuma rimwe na rimwe batazibonera igihe bazishakiye.",
        "hashtags": ["#ubworozi", "#nyagatare", "#intanga", "#rwanda"],
        "location": "Nyagatare, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/png/inka-3.png"
    },
    {
        "title": "Abaganga b'amatumgo barasabwa kurushaho kwegera aborozi",
        "content": "Abaganga b'amatumgo barasabwa kurushaho kwegera aborozi kugira ngo babafashe mu kurwanya indwara z'amatumgo no kuzongera umusaruro wabo.",
        "hashtags": ["#ubworozi", "#amatungo", "#ubuvuzi", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/aborozi_b_inka_barifuza_laboratwari_yabafasha_mu_buvuzi_bwayo.jpg"
    },
    {
        "title": "Bahamya ko bikuye mu bukene babikesha amatumgo magufi",
        "content": "Hari abaturage bo mu turere 15 tw'Intara y'Amajyepfo, Amajyaruguru n'Iburengerazuba bavuga ko barwanyije imirire mibi ndetse n'imibereho muri rusange irahinduka byihuse, babikesheje umushinga wiswe PRISM wa Minisiteri y'Ubuhinzi n'Ubworozi(MINAGRI).",
        "hashtags": ["#ubworozi", "#amatungo", "#prism", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/aborozi_baha_inka_ibibabi_bw_ibirayi_biba_byatewe_umuti_bikagira_ingaruka_ku_musaruro_w_amata.jpg"
    },
    {
        "title": "U Rwanda rwahagurukiye kuzamura umusaruro w'amafi",
        "content": "Muri Kamena 2024, u Rwanda rwari rugeze ku musaruro w'amafi wa toni 48,133 ku rwego rw'Igihugu, aho toni 9,000 muri zo arizo ziva mu bworozi bwayo andi akava mu burobyi busanzwe, gusa uwo musaruro ngo uracyari hasi, intego ikaba ari ukuwuzamura.",
        "hashtags": ["#ubworozi", "#amafi", "#rwanda", "#iterambere"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/bk_kivu_choice_1_.jpg"
    },
    {
        "title": "Ibibwana by'ingurube bigiye kujya bihabwa amata y'ifu",
        "content": "Aborozi b'ingurube mu Rwanda batangaje ko mu gihe cy'amezi arindwi, bazaba batangije gahunda yo guha ibibwana by'ingurube amata yo kunywa byakorewe, kugira ngo za nyina zororoke vuba.",
        "hashtags": ["#ubworozi", "#ingurube", "#amata", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/ingurube_zonka_amata.jpg"
    },
    {
        "title": "Gakenke: Barishimira ikoranabuhanga risigaye rikoreshwa mu kubegereza intanga z'ingurube",
        "content": "Aborozi b'ingurube bo mu Karere ka Gakenke, basanga uburyo bwo kubegereza intanga z'ingurube hakoreshejwe ikoranabuhanga ry'utudege duto tutagira Abapilote 'Drone', hari urwego rufatika bimaze kubagezaho.",
        "hashtags": ["#ubworozi", "#ingurube", "#ikoranabuhanga", "#gakenke"],
        "location": "Gakenke, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/ubwo_buryo_bwo_kwegereza_aborozi_intanga_z_ingurube_hifashishijwe_ikoranabuhanga_ry_utudege_duto_tutagira_abapilote_drone_rikomeze_kuborohereza_kuzibona_byihuse_kandi_hafi.jpg"
    },
    {
        "title": "Musanze: Batashye uruganda ruzaca akajagari mu gutunganya inyama z'ingurube",
        "content": "Mu Karere ka Musanze huzuye uruganda ruzajya rutunganya inyama z'ingurube hagamijwe kurushaho kuzongerera agaciro mu buryo bwubahirije ubuziranenge.",
        "hashtags": ["#ubworozi", "#ingurube", "#musanze", "#rwanda"],
        "location": "Musanze, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/aborozi_biyemeje_kuva_ku_nka_zidatanga_umukamo_bakagura_iza_kijyambere_zizashyirwa_mu_biraro.jpg"
    },
    {
        "title": "Burera: Aborozi barasaba kwegerezwa uruganda rutunganya ibiryo by'amatumgo",
        "content": "Aborozi b'amatumgo bo mu Karere ka Burera, bavuga ko bakomeje kugorwa no kubona ibiryo by'amatumgo, kubera ko nta nganda zihagije zihaba zibitunganya.",
        "hashtags": ["#ubworozi", "#burera", "#amatungo", "#rwanda"],
        "location": "Burera, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/aborozi-7.jpg"
    },
    {
        "title": "Nyagatare: Barifuza ko uruganda Inyange rwabafasha kubona inka z'umukamo",
        "content": "Bamwe mu borozi mu Karere ka Nyagatare barifuza ko uruganda Inyange rutunganya ibikomoka ku mata rwabafasha kubona inka z'umukamo binyuze mu nguzanyo zahabwa aborozi.",
        "hashtags": ["#ubworozi", "#nyagatare", "#inka", "#amata"],
        "location": "Nyagatare, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/inyange1-7.jpg"
    },
    {
        "title": "Umusaruro wa Girinka: Kuva muri 2000 kugera muri 2023, inka zikubye inshuro zirenga ebyiri",
        "content": "Tariki ya 12 Mata 2006, Inama y'Abaminisitiri yateraniye muri Village Urugwiro, iyobowe na Perezida wa Repubulika Paul Kagame, yafashe ibyemezo bitandukanye, birimo 'kwemeza gahunda n'ingamba y'ibiteganywa mu rwego rwo gufasha abaturage kubona inka muri buri rugo'.",
        "hashtags": ["#ubworozi", "#girinka", "#inka", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/inka-105.jpg"
    },
    {
        "title": "Nyagatare: Aborozi bahigiye kugura inka zitanga umukamo",
        "content": "Aborozi mu Karere ka Nyagatare bavuga ko kuba igiciro cy'amata kiyongereye kikava ku mafaranga 300 kikagera kuri 400 bagiye kuvugurura ubworozi bwabo bagashaka inka zitanga umukamo.",
        "hashtags": ["#ubworozi", "#nyagatare", "#amata", "#inka"],
        "location": "Nyagatare, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/inka-110.jpg"
    },
    {
        "title": "Kicukiro: DASSO yoroje abaturage inka enye n'ihene 20",
        "content": "Abagize urwego rwa DASSO rwunganira Akarere ka Kicukiro mu gucunga umutekano, tariki 31 Gicurasi 2024 boroje abaturage mu Murenge wa Gahanga hagamijwe kubafasha kwikura mu bukene, hakaba hatanzwe inka enye ndetse n'amatumgo magufi y'ihene 20.",
        "hashtags": ["#ubworozi", "#kicukiro", "#dasso", "#rwanda"],
        "location": "Kicukiro, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/dasso_kicukiro_6_.jpg"
    },
    {
        "title": "MINAGRI yatangije ikoranabuhanga rizongera umusaruro w'amata",
        "content": "Minisiteri y'Ubuhinzi n'Ubworozi (MINAGRI) ibinyujije mu kigo kiyishamikiyeho gishinzwe Ubuhinzi n'Ubworozi (RAB), ku bufatanye n'Ikigo mpuzamahanga gikora ubushakashatsi ku bworozi (International Livestock Research Institute/ILRI), batangije ikoranabuhanga rizajya riha umworozi w'Inka amakuru amufasha kongera umukamo.",
        "hashtags": ["#ubworozi", "#minagri", "#rab", "#amata"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/ifi_1-2.jpg"
    },
    {
        "title": "Nyagatare: Inka 60 zimaze gukurwa mu bworozi kubera indwara y'uburenge",
        "content": "Umuyobozi w'Ikigo cy'Igihugu gishinzwe guteza imbere Ubuhinzi n'Ubworozi (RAB) Sitasiyo ya Nyagatare, John Kayumba, avuga ko inka 60 ari zo zimaze gukurwa mu bworozi kubera indwara y'uburenge yagaragaye mu cyumweru gishize mu rwuri rw'umworozi wo mu Murenge wa Tabagwe.",
        "hashtags": ["#ubworozi", "#nyagatare", "#inka", "#indwara"],
        "location": "Nyagatare, Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/isazi_ya_tsetse_ikunze_kwibasira_inka_zegereye_ibice_by_ishyamba_rya_pariki.jpg"
    },
    {
        "title": "Hagaragajwe uburyo imimero y'ibigori mu cyumweru kimwe itanga ibiryo by'amatumgo bitubutse",
        "content": "Uko ibihe bigenda bitambuka, abantu bava mu buhinzi n'ubworozi gakondo bagana mu kubigira umwuga, ni nako ubushakashatsi bugenda butanga ibisubizo. Ni muri urwo rwego hagaragajwe ko guhinga ibigori ahatari mu butaka mu gihe kitarenze icyumweru, bitanga ibiryo by'amatumgo bitubutse kandi bikungahaye ku bitera imbaraga.",
        "hashtags": ["#ubuhinzi", "#ibigori", "#amatungo", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/imimero_y_ibigori_yagaragajwe_na_duhamic_adri_mu_imurikabikorwa_ry_abafatanyabikorwa_bo_mu_karere_ka_gisagara_ngo_iba_ikungahaye_ku_byubaka_umubiri_n_ibitera_imbaraga.jpg"
    },
    {
        "title": "Aborozi b'amatumgo barasabwa kurushaho kwegera aborozi",
        "content": "Aborozi b'amatumgo barasabwa kurushaho kwegera aborozi kugira ngo babafashe mu kurwanya indwara z'amatumgo no kuzongera umusaruro wabo.",
        "hashtags": ["#ubworozi", "#amatungo", "#ubuvuzi", "#rwanda"],
        "location": "Rwanda",
        "image_url": "https://www.kigalitoday.com/IMG/jpg/n_abafite_inka_nkeya_ziracyarisha_mu_nzuri_bisanzwe.jpg"
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
    print("🚀 Starting agriculture content posting with REAL Kigali Today images...")
    print("📸 Using actual image URLs from Kigali Today website")
    
    # Login and get token
    print("🔐 Logging in...")
    token = login_and_get_token()
    if not token:
        print("❌ Failed to get authentication token")
        return
    
    print("✅ Login successful")
    
    # Post each sample article with real Kigali Today images
    successful_posts = 0
    
    for i, post in enumerate(REAL_KIGALI_TODAY_POSTS, 1):
        print(f"\n📝 Processing post {i}/{len(REAL_KIGALI_TODAY_POSTS)}: {post['title'][:50]}...")
        print(f"   📸 Real Kigali Today image: {post['image_url']}")
        
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
                print(f"✅ Posted successfully with real Kigali Today image")
                successful_posts += 1
            else:
                print(f"❌ Failed to post: {message}")
            
            # Add delay to avoid rate limiting
            time.sleep(3)
            
        except Exception as e:
            print(f"❌ Error processing post: {e}")
            continue
    
    print(f"\n🎉 Completed! Successfully posted {successful_posts}/{len(REAL_KIGALI_TODAY_POSTS)} posts with REAL Kigali Today images")
    print("💡 These are actual images from the Kigali Today website!")

if __name__ == "__main__":
    main()

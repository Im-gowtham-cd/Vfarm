import requests

API_KEY = "579b464db66ec23bdd0000014e235d4a0ccf4794761e05a8f7119343"
API_URL = "https://api.data.gov.in/resource/f9efb7cc-d1b7-4adb-90f5-291e2d7ffbe3"

def get_price_range(commodity_name):
    params = {
        "api-key": API_KEY,
        "format": "json",
        "limit": 1000,  
        "filters[commodity]": commodity_name.title()
    }

    try:
        response = requests.get(API_URL, params=params)
        if response.status_code == 200:
            data = response.json()
            records = data.get("records", [])
            prices = [int(r['modal_price']) for r in records if r.get('modal_price') and r['modal_price'].isdigit()]
            
            if prices:
                print(f"\n{commodity_name.title()} Price Range (Modal Price):")
                print(f" Min Price: ₹{min(prices)}")
                print(f" Max Price: ₹{max(prices)}")
                print(f" Avg Price: ₹{sum(prices)//len(prices)}")
                print(f" Total Records Used: {len(prices)}")
            else:
                print(" No valid price records found for this commodity.")
        else:
            print("API Error:", response.status_code, response.text)
    except Exception as e:
        print(" Exception occurred:", str(e))


commodity = input("Enter commodity name (e.g., Tomato, Onion, Banana): ")
get_price_range(commodity)

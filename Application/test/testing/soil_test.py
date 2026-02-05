import requests

url = "https://api.isric.org/soilgrids/v2.0/properties/query"

params = {
    "lon": 78.6569,
    "lat": 11.1271,
    "property": ["phh2o", "clay", "soc"],
    "depth": ["0-5cm"],
    "value": ["mean"]
}

headers = {
    "Accept": "application/json"
}

try:
    response = requests.get(url, params=params, headers=headers, timeout=10)
    if response.status_code == 200:
        data = response.json()
        print("✅ Success - Soil data retrieved:\n")
        print(data)
    else:
        print(f"❌ Failed with status code: {response.status_code}")
        print(response.text)
except requests.exceptions.RequestException as e:
    print("⚠ Error:", e)

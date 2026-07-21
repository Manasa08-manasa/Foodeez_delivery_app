import json, urllib.request
url = 'https://int.foodeez.in/restaurant/api/v1/auth/partner/send-otp'
data = json.dumps({'email': 'test@example.com'}).encode()
req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json', 'Accept': 'application/json'}, method='POST')
try:
    with urllib.request.urlopen(req, timeout=20) as r:
        print('STATUS', r.status)
        print(r.read().decode())
except Exception as e:
    print(type(e).__name__, e)

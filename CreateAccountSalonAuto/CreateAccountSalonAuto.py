import requests
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

user_name = 'admin@kiotviet.com'
password = '123'
cpanelSalonDev = 'https://cpanel-salon-dev.booking.citigo.net/login?redirect=%2f#f=Unauthorized'
cpanelSalonStag = 'https://cpanel-salon-stag.booking.citigo.net/login?redirect=%2f#f=Unauthorized'

#<input data-val="true" data-val-required="Nhập tên đăng nhập!" id="UserName" name="UserName" tabindex="1" type="text" value="">
#<input data-val="true" data-val-required="Nhập mật khẩu!" id="Password" name="Password" tabindex="2" type="password" value="">
#<input tabindex="4" name="quan-ly" type="submit" value="Đăng nhập" class="">

# get cookie by key 'ss-tok'


def get_login_token(url, username, password):
    driver = webdriver.Chrome()
    try:
        driver.get(url)
        
        username_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "UserName"))
        )
        username_input.send_keys(username)
        
        password_input = driver.find_element(By.ID, "Password")
        password_input.send_keys(password)
        
        login_button = driver.find_element(By.NAME, "quan-ly")
        login_button.click()
        
        time.sleep(2)
        
        ss_tok = driver.get_cookie('ss-tok')
        if ss_tok:
            # Save token to json file
            with open('cookie.json', 'w') as f:
                json.dump({'ss-tok': ss_tok['value']}, f, indent=4)
            return ss_tok['value']
            
    finally:
        driver.quit()

def create_retailer(base_name, token, env="dev"):
    # Define the URL based on environment
    if env == "dev":
        url = "https://cpanel-salon-dev.booking.citigo.net/api/retailers"
    else:
        url = "https://cpanel-salon-stag.booking.citigo.net/api/retailers"

    headers = {
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'en-US,en;q=0.9,vi;q=0.8',
        'content-type': 'application/json;charset=UTF-8',
        'origin': 'https://cpanel-salon-dev.booking.citigo.net',
        'referer': 'https://cpanel-salon-dev.booking.citigo.net/',
        'Cookie': f'ss-tok={token}; ss-opt=temp; ss-pid=cQCvXw3AP3JdBnfG6I1l'
    }

    data = {
        "Retailer": {
            "AppBrandingId": "1",
            "MaximumBranchs": 2,
            "CountryId": 1,
            "CompanyName": base_name,
            "CompanyAddress": base_name,
            "LocationName": "Hà Nội - Quận Bắc Từ Liêm",
            "temploc": "Hà Nội - Quận Bắc Từ Liêm",
            "WardName": "Phường Cổ Nhuế 1",
            "tempw": "Phường Cổ Nhuế 1",
            "Code": base_name,
            "Phone": "0981436091",
            "Website": base_name,
            "ContractType": 3,
            "TimeSheetBlockUnit": 100,
            "MaximumRooms": -1,
            "MaximumProducts": 2,
            "MaximumFanpages": 2,
            "LimitKiotMailInMonth": 2,
            "MaximumSaleChannels": 2,
            "IndustryId": 16,
            "ContractDate": "2025-06-03T17:00:00.000Z",
            "ExpiryDate": "2025-06-13T17:00:00.000Z",
            "IsUsingNewFnb": True,
            "MakeSampleData": True
        },
        "User": {
            "UserName": base_name,
            "PlainPassword": "123",
            "GivenName": base_name
        },
        "Branch": {
            "Name": base_name
        }
    }

    response = requests.post(url, headers=headers, json=data)
    return response

def main():
    # Environment selection
    env = input("Select environment (dev/stag) [default=dev]: ").lower() or "dev"
    
    # Login URL based on environment
    login_url = cpanelSalonDev if env == "dev" else cpanelSalonStag
    
    # Step 1: Get token
    token = get_login_token(login_url, user_name, password)
    if not token:
        print("Failed to get token")
        return

    # Starting number for sth
    current_num = 35  # Starting from sth35
    
    while True:
        base_name = f"sth{current_num}"
        print(f"\nCreating retailer: {base_name}")
        
        response = create_retailer(base_name, token, env)
        
        # Save response to file
        with open(f'response_{base_name}.json', 'w') as f:
            json.dump(response.json() if response.text else {"status_code": response.status_code}, f, indent=4)
        
        print(f"Status Code: {response.status_code}")
        if response.text:
            print(f"Response: {response.text[:200]}...")  # Print first 200 chars of response
        
        # Ask if user wants to continue
        if input("\nContinue to next number? (y/n): ").lower() != 'y':
            break
            
        current_num += 1

if __name__ == "__main__":
    main()
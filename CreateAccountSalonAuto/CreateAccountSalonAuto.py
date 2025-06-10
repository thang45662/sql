from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import json

user_name = 'admin@kiotviet.com'
password = '123'
cpanelSalonDev = 'https://cpanel-salon-dev.booking.citigo.net/login?redirect=%2f#f=Unauthorized'
cpanelSalonStag = 'https://cpanel-salon-stag.booking.citigo.net/login?redirect=%2f#f=Unauthorized'

#<input data-val="true" data-val-required="Nhập tên đăng nhập!" id="UserName" name="UserName" tabindex="1" type="text" value="">
#<input data-val="true" data-val-required="Nhập mật khẩu!" id="Password" name="Password" tabindex="2" type="password" value="">
#<input tabindex="4" name="quan-ly" type="submit" value="Đăng nhập" class="">

# get cookie by key 'ss-tok'


def login_chrome(url, username, password):
    # Create Chrome driver
    driver = webdriver.Chrome()

    try:
        # Navigate to the login page
        driver.get(url)

        # Wait for username field and enter username
        username_input = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "UserName"))
        )
        username_input.send_keys(username)

        # Find password field and enter password
        password_input = driver.find_element(By.ID, "Password")
        password_input.send_keys(password)

        # Find and click login button
        login_button = driver.find_element(By.NAME, "quan-ly")
        login_button.click()

        # Wait a bit for the login to complete
        time.sleep(2)

        # Get cookie and save to JSON file
        ss_tok = driver.get_cookie('ss-tok')
        if ss_tok:
            cookie_data = {
                'ss-tok': ss_tok['value']
            }
            with open('cookie.json', 'w') as f:
                json.dump(cookie_data, f, indent=4)
            print("Cookie saved to cookie.json")
        else:
            print("Cookie ss-tok not found")

        # Keep the browser window open
        input("Press Enter to close the browser...")

    finally:
        driver.quit()


# Use for dev environment
login_chrome(cpanelSalonDev, user_name, password)
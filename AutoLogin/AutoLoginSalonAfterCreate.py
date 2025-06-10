from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import json


def auto_login():
    try:
        # Đọc config để lấy số hiện tại
        with open('D:/codeAuto/CodeAuto/CreateAccountSalonAuto/retailer_config.json', 'r') as file:
            config = json.load(file)
            current_number = str(int(config.get("start_number", "46")) - 1)  # Lấy số 46 trừ đi 1

        # Thiết lập cho Coc Coc
        options = webdriver.ChromeOptions()
        options.add_argument('--start-maximized')
        options.binary_location = r"C:\Users\thang.th4\AppData\Local\CocCoc\Browser\Application\browser.exe"

        # Khởi tạo driver
        driver = webdriver.Chrome(options=options)

        # Thiết lập thông tin login
        retailer_name = f"sth{current_number}"  # sth là prefix mặc định
        username = retailer_name
        password = "123"

        # URL cho môi trường dev
        login_url = f"https://salon-dev.booking.citigo.net/login?redirect=%2f{retailer_name}%2f#f=Unauthorized"

        print(f"Starting login process for account: {retailer_name}")
        print(f"URL: {login_url}")

        # Mở trang login
        driver.get(login_url)

        # Đợi và điền form
        wait = WebDriverWait(driver, 20)
        time.sleep(2)

        print("Filling login form...")

        # Điền form bằng JavaScript
        js_fill = f"""
            document.getElementById('Retailer').value = '{retailer_name}';
            document.getElementById('UserName').value = '{username}';
            document.getElementById('Password').value = '{password}';
        """
        driver.execute_script(js_fill)

        time.sleep(1)

        # Click nút login
        print("Clicking login button...")
        driver.execute_script("document.querySelector('input[name=\"quan-ly\"]').click();")

        print("Login completed")

        # Đợi một thời gian để xem kết quả
        time.sleep(10)

        return True

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        if driver:
            driver.save_screenshot("login_error.png")
        return False

    finally:
        if 'driver' in locals():
            driver.quit()


if __name__ == "__main__":
    import os

    success = auto_login()
    if success:
        print("Login process completed successfully")
    else:
        print("Login process failed")
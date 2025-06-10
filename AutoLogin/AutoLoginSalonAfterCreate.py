from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import json

def auto_login():
    try:
        # Đọc config
        with open('D:/codeAuto/CodeAuto/CreateAccountSalonAuto/retailer_config.json', 'r') as file:
            config = json.load(file)
            current_number = str(int(config.get("start_number", "46")) - 1)

        # Thiết lập cho Coc Coc với chế độ ẩn danh
        options = webdriver.ChromeOptions()
        options.add_argument('--start-maximized')
        options.add_argument('--incognito')  # Thêm chế độ ẩn danh
        options.binary_location = r"C:\Users\thang.th4\AppData\Local\CocCoc\Browser\Application\browser.exe"
        
        # Khởi tạo driver
        driver = webdriver.Chrome(options=options)
        
        # Thiết lập thông tin login
        retailer_name = f"sth{current_number}"
        username = retailer_name
        password = "123"
        
        login_url = f"https://salon-dev.booking.citigo.net/login?redirect=%2f{retailer_name}%2f#f=Unauthorized"
        
        print(f"Starting login process for account: {retailer_name}")
        print(f"URL: {login_url}")
        
        driver.get(login_url)
        time.sleep(2)
        
        print("Filling login form...")
        js_fill = f"""
            document.getElementById('Retailer').value = '{retailer_name}';
            document.getElementById('UserName').value = '{username}';
            document.getElementById('Password').value = '{password}';
        """
        driver.execute_script(js_fill)
        
        time.sleep(1)
        
        print("Clicking login button...")
        driver.execute_script("document.querySelector('input[name=\"quan-ly\"]').click();")
        
        print("Login completed - Browser window will remain open")
        
        # KHÔNG đóng driver ở đây để giữ cửa sổ trình duyệt mở
        return True
        
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        if 'driver' in locals():
            driver.save_screenshot("login_error.png")
        return False

if __name__ == "__main__":
    success = auto_login()
    if success:
        print("Login process completed successfully")
        # Giữ script chạy để trình duyệt không bị đóng
        input("Press Enter to exit...")
    else:
        print("Login process failed")
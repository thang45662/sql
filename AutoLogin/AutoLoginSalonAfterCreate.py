from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import tkinter as tk
from tkinter import simpledialog, ttk
import threading
import time
import json

class LoginDialog:
    def __init__(self):
        self.root = tk.Tk()
        self.root.withdraw()  # Ẩn cửa sổ Tk chính
        self.custom_account = None
        self.response = None
        self.environment = "dev"  # Default environment
        
    def show_dialog(self):
        # Tạo cửa sổ dialog mới
        dialog = tk.Toplevel(self.root)
        dialog.title("Login Options")
        dialog.geometry("300x200")  # Increased height for environment selector
        
        # Đặt cửa sổ ở giữa màn hình
        dialog.update_idletasks()
        width = dialog.winfo_width()
        height = dialog.winfo_height()
        x = (dialog.winfo_screenwidth() // 2) - (width // 2)
        y = (dialog.winfo_screenheight() // 2) - (height // 2)
        dialog.geometry(f'+{x}+{y}')

        # Environment selection
        env_frame = tk.Frame(dialog)
        env_frame.pack(pady=5)
        
        env_label = tk.Label(env_frame, text="Environment:")
        env_label.pack(side=tk.LEFT, padx=5)
        
        self.env_var = tk.StringVar(value="dev")
        env_combo = ttk.Combobox(env_frame, textvariable=self.env_var, values=["local", "dev"], state="readonly", width=10)
        env_combo.pack(side=tk.LEFT)

        label = tk.Label(dialog, text="Bạn có muốn nhập account khác không?")
        label.pack(pady=10)

        time_label = tk.Label(dialog, text="5")
        time_label.pack()

        def count_down(remaining):
            if remaining > 0 and not self.response:
                time_label.config(text=str(remaining))
                dialog.after(1000, count_down, remaining - 1)
            elif not self.response:
                self.response = "no"
                dialog.destroy()

        def yes_clicked():
            self.response = "yes"
            self.environment = self.env_var.get()
            dialog.destroy()

        def no_clicked():
            self.response = "no"
            self.environment = self.env_var.get()
            dialog.destroy()

        yes_button = tk.Button(dialog, text="Có", command=yes_clicked)
        yes_button.pack(side=tk.LEFT, expand=True, padx=20)

        no_button = tk.Button(dialog, text="Không", command=no_clicked)
        no_button.pack(side=tk.RIGHT, expand=True, padx=20)

        # Start countdown using after()
        count_down(5)
        
        dialog.wait_window()
        
        if self.response == "yes":
            self.custom_account = simpledialog.askstring("Input", "Nhập tên account:")
            
        return self.custom_account, self.environment

# ... (Previous LoginDialog class remains the same) ...

def handle_security_warning(driver, wait):
    try:
        # Wait for the security warning button
        proceed_button = wait.until(EC.presence_of_element_located(
            (By.ID, "proceed-button")
        ))
        print("Found security warning 'Proceed' button")
        proceed_button.click()
        print("Clicked 'Proceed' button")
        time.sleep(2)  # Wait for navigation after clicking
        return True
    except TimeoutException:
        print("No security warning found - continuing with login")
        return False
    except Exception as e:
        print(f"Error handling security warning: {str(e)}")
        return False

def perform_login(driver, retailer_name, username, password, environment):
    wait = WebDriverWait(driver, 10)
    
    try:
        print("Starting login sequence...")
        
        if environment == "local":
            # Handle security warning first
            if handle_security_warning(driver, wait):
                print("Security warning handled, proceeding with login")
            
            try:
                print("Attempting local environment login sequence...")
                
                # Wait for and fill username field
                username_input = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='text']")))
                username_input.clear()
                username_input.send_keys(username)
                print("Username filled")
                
                # Fill password field
                password_input = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "input[type='password']")))
                password_input.clear()
                password_input.send_keys(password)
                print("Password filled")
                
                # Click login button
                login_button = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[type='submit']")))
                login_button.click()
                print("Login button clicked")
                
            except Exception as e:
                print(f"Local login sequence failed: {str(e)}")
                raise e
                
        else:
            try:
                # Dev environment login sequence
                print("Attempting dev environment login sequence...")
                
                js_fill = f"""
                    document.getElementById('Retailer').value = '{retailer_name}';
                    document.getElementById('UserName').value = '{username}';
                    document.getElementById('Password').value = '{password}';
                """
                driver.execute_script(js_fill)
                time.sleep(1)
                
                driver.execute_script("document.querySelector('input[name=\"quan-ly\"]').click();")
                print("Dev login sequence completed")
                
            except Exception as e:
                print(f"Dev login sequence failed: {str(e)}")
                raise e

    except Exception as e:
        print(f"Login error: {str(e)}")
        driver.save_screenshot(f"login_error_{environment}.png")
        raise e

def auto_login():
    try:
        dialog = LoginDialog()
        custom_account, environment = dialog.show_dialog()
        
        print(f"Selected environment: {environment}")  # Debug log
        
        options = webdriver.ChromeOptions()
        options.add_argument('--start-maximized')
        options.add_argument('--incognito')
        options.add_argument('--ignore-certificate-errors')
        options.add_argument('--ignore-ssl-errors')
        if environment == "local":
            options.add_argument('--allow-insecure-localhost')
            options.add_argument('--disable-web-security')
        
        options.binary_location = r"C:\Users\thang.th4\AppData\Local\CocCoc\Browser\Application\browser.exe"
        
        driver = webdriver.Chrome(options=options)
        wait = WebDriverWait(driver, 10)
        
        if custom_account:
            retailer_name = custom_account
            username = custom_account
            print(f"Using custom account: {custom_account}")
        else:
            with open('D:/codeAuto/CodeAuto/CreateAccountSalonAuto/retailer_config.json', 'r') as file:
                config = json.load(file)
                current_number = str(int(config.get("start_number", "46")) - 1)
            retailer_name = f"sth{current_number}"
            username = retailer_name
            print(f"Using default account: {retailer_name}")
            
        password = "123"
        
        # Set up URLs based on environment
        if environment == "local":
            login_url = "http://booking.localhost.com:86/login"  # Removed #/ from URL
        else:
            login_url = f"https://salon-dev.booking.citigo.net/login?redirect=%2f{retailer_name}%2f#f=Unauthorized"
        
        print(f"Environment: {environment}")
        print(f"Login URL: {login_url}")
        
        # Navigate to the login page
        driver.get(login_url)
        time.sleep(2)  # Wait for initial page load
        
        # Print current URL for debugging
        print(f"Current URL after navigation: {driver.current_url}")
        
        # Handle security warning if it appears (for local environment)
        if environment == "local":
            print("Checking for security warning...")
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    # Try to find and click the proceed button
                    proceed_button = wait.until(EC.element_to_be_clickable(
                        (By.CSS_SELECTOR, "#proceed-button, button.secondary-button.small-link")
                    ))
                    proceed_button.click()
                    print("Clicked proceed button successfully")
                    time.sleep(2)  # Wait for navigation
                    break
                except TimeoutException:
                    if attempt == max_retries - 1:
                        print("No security warning found after retries - continuing")
                    else:
                        print(f"Attempt {attempt + 1} failed, retrying...")
                        time.sleep(1)
        
        # Print page source for debugging
        print("Current page source:")
        print(driver.page_source[:500])
        
        perform_login(driver, retailer_name, username, password, environment)
        
        print("Login completed - Browser window will remain open")
        
        while True:
            time.sleep(1)
            
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        if 'driver' in locals():
            driver.save_screenshot("login_error.png")
            print("\nPage source at time of error:")
            print(driver.page_source[:500])
            # Print current URL when error occurs
            print(f"URL at time of error: {driver.current_url}")
        return False

if __name__ == "__main__":
    auto_login()
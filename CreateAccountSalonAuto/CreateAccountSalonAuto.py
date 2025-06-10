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
import requests
from tkinter import messagebox
from datetime import datetime, timedelta
import os  # Import the os module

from AutoLogin.AutoLoginSalonAfterCreate import LoginDialog


# ... (Previous LoginDialog class remains the same) ...

def perform_login(driver, retailer_name, username, password, environment):
    wait = WebDriverWait(driver, 10)
    
    def safe_find_and_fill(selector_strategies, value, error_msg):
        for by, selector in selector_strategies:
            try:
                element = wait.until(EC.presence_of_element_located((by, selector)))
                element.clear()
                element.send_keys(value)
                return True
            except (TimeoutException, NoSuchElementException):
                continue
        print(f"Failed to find element: {error_msg}")
        return False

    try:
        # Define multiple selector strategies for each field
        retailer_selectors = [
            (By.ID, "Retailer"),
            (By.NAME, "Retailer"),
            (By.CSS_SELECTOR, "input[placeholder*='retailer']"),
            (By.CSS_SELECTOR, "input[placeholder*='Retailer']")
        ]
        
        username_selectors = [
            (By.ID, "UserName"),
            (By.NAME, "UserName"),
            (By.CSS_SELECTOR, "input[placeholder*='username']"),
            (By.CSS_SELECTOR, "input[placeholder*='Username']")
        ]
        
        password_selectors = [
            (By.ID, "Password"),
            (By.NAME, "Password"),
            (By.CSS_SELECTOR, "input[type='password']")
        ]
        
        login_button_selectors = [
            (By.NAME, "quan-ly"),
            (By.CSS_SELECTOR, "input[name='quan-ly']"),
            (By.CSS_SELECTOR, "button[type='submit']"),
            (By.CSS_SELECTOR, ".login-button"),
            (By.XPATH, "//button[contains(text(), 'Login')]"),
            (By.XPATH, "//input[@value='Login']")
        ]

        # Try to find and fill each field
        if not safe_find_and_fill(retailer_selectors, retailer_name, "Retailer field"):
            # If we can't find elements, try waiting a bit and refreshing
            time.sleep(2)
            driver.refresh()
            time.sleep(2)
            if not safe_find_and_fill(retailer_selectors, retailer_name, "Retailer field after refresh"):
                raise Exception("Could not find retailer input field")

        if not safe_find_and_fill(username_selectors, username, "Username field"):
            raise Exception("Could not find username input field")

        if not safe_find_and_fill(password_selectors, password, "Password field"):
            raise Exception("Could not find password input field")

        # Try to find and click the login button
        for by, selector in login_button_selectors:
            try:
                button = wait.until(EC.element_to_be_clickable((by, selector)))
                button.click()
                print("Successfully clicked login button")
                return
            except (TimeoutException, NoSuchElementException):
                continue

        # If we get here, we couldn't find the login button
        raise Exception("Could not find login button")

    except Exception as e:
        print(f"Login error: {str(e)}")
        raise e

def auto_login():
    try:
        dialog = LoginDialog()
        custom_account, environment = dialog.show_dialog()
        
        options = webdriver.ChromeOptions()
        options.add_argument('--start-maximized')
        options.add_argument('--incognito')
        options.add_argument('--ignore-certificate-errors')
        options.add_argument('--ignore-ssl-errors')
        # Add these options to help with local development
        if environment == "local":
            options.add_argument('--allow-insecure-localhost')
            options.add_argument('--disable-web-security')
            options.add_argument('--reduce-security-for-testing')
        
        options.binary_location = r"C:\Users\thang.th4\AppData\Local\CocCoc\Browser\Application\browser.exe"
        
        driver = webdriver.Chrome(options=options)
        
        if custom_account:
            retailer_name = custom_account
            username = custom_account
        else:
            with open('D:/codeAuto/CodeAuto/CreateAccountSalonAuto/retailer_config.json', 'r') as file:
                config = json.load(file)
                current_number = str(int(config.get("start_number", "46")) - 1)
            retailer_name = f"sth{current_number}"
            username = retailer_name
            
        password = "123"
        
        if environment == "local":
            base_url = "http://booking.localhost.com:86"
            login_url = f"{base_url}/login"  # Simplified URL for local
        else:
            base_url = "https://salon-dev.booking.citigo.net"
            login_url = f"{base_url}/login?redirect=%2f{retailer_name}%2f#f=Unauthorized"
        
        print(f"Starting login process for account: {retailer_name} on {environment} environment")
        print(f"Using URL: {login_url}")
        
        driver.get(login_url)
        
        # Add a wait for page load
        wait = WebDriverWait(driver, 10)
        try:
            # Wait for any of the possible login form elements to be present
            wait.until(lambda d: any([
                len(d.find_elements(By.ID, "Retailer")) > 0,
                len(d.find_elements(By.NAME, "Retailer")) > 0,
                len(d.find_elements(By.CSS_SELECTOR, "input[type='text']")) > 0
            ]))
        except TimeoutException:
            print("Warning: Page load wait timeout - attempting login anyway")
        
        perform_login(driver, retailer_name, username, password, environment)
        
        print("Login completed - Browser window will remain open")
        
        while True:
            time.sleep(1)
            
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        if 'driver' in locals():
            driver.save_screenshot("login_error.png")
        return False

class RetailerCreator:
    def __init__(self, root):
        self.root = root
        self.root.title("Salon Retailer Creator")
        
        # Configure main window
        self.root.geometry("1000x800")
        self.root.resizable(True, True)
        
        # Variables
        self.env_var = tk.StringVar(value="dev")
        self.start_number_var = tk.StringVar(value="35")
        self.username_var = tk.StringVar(value="admin@kiotviet.com")
        self.password_var = tk.StringVar(value="123")
        self.dev_url_var = tk.StringVar(value="https://cpanel-salon-dev.booking.citigo.net")
        self.stag_url_var = tk.StringVar(value="https://cpanel-salon-stag.booking.citigo.net")
        
        self.create_widgets()
        self.load_config()

    def create_widgets(self):
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Environment Selection
        env_frame = ttk.LabelFrame(main_frame, text="Environment Selection", padding="10")
        env_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        ttk.Radiobutton(env_frame, text="Development", variable=self.env_var, 
                       value="dev").grid(row=0, column=0, padx=20)
        ttk.Radiobutton(env_frame, text="Staging", variable=self.env_var, 
                       value="stag").grid(row=0, column=1, padx=20)
        
        # Configuration Frame
        config_frame = ttk.LabelFrame(main_frame, text="Configuration", padding="10")
        config_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        # Start Number
        ttk.Label(config_frame, text="Start Number:").grid(row=0, column=0, sticky=tk.W, pady=5)
        ttk.Entry(config_frame, textvariable=self.start_number_var, width=10).grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # Username
        ttk.Label(config_frame, text="Username:").grid(row=1, column=0, sticky=tk.W, pady=5)
        ttk.Entry(config_frame, textvariable=self.username_var, width=40).grid(row=1, column=1, sticky=tk.W, pady=5)
        
        # Password
        ttk.Label(config_frame, text="Password:").grid(row=2, column=0, sticky=tk.W, pady=5)
        ttk.Entry(config_frame, textvariable=self.password_var, show="*", width=40).grid(row=2, column=1, sticky=tk.W, pady=5)
        
        # URL Configuration Frame
        url_frame = ttk.LabelFrame(main_frame, text="URL Configuration", padding="10")
        url_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        # Dev URL
        ttk.Label(url_frame, text="Dev URL:").grid(row=0, column=0, sticky=tk.W, pady=5)
        ttk.Entry(url_frame, textvariable=self.dev_url_var, width=60).grid(row=0, column=1, sticky=tk.W, pady=5)
        
        # Staging URL
        ttk.Label(url_frame, text="Staging URL:").grid(row=1, column=0, sticky=tk.W, pady=5)
        ttk.Entry(url_frame, textvariable=self.stag_url_var, width=60).grid(row=1, column=1, sticky=tk.W, pady=5)
        
        # Log Display
        log_frame = ttk.LabelFrame(main_frame, text="Creation Log", padding="10")
        log_frame.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=20, width=100)
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=5, column=0, columnspan=2, pady=10)
        
        ttk.Button(button_frame, text="Create Retailer", 
                  command=self.create_retailer).grid(row=0, column=0, padx=5)
        ttk.Button(button_frame, text="Save Config", 
                  command=self.save_config).grid(row=0, column=1, padx=5)
        ttk.Button(button_frame, text="Clear Log", 
                  command=self.clear_log).grid(row=0, column=2, padx=5)
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(4, weight=1)

    def log(self, message):
        """Add message to log with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
        self.root.update()

    def get_token(self):
        """Get authentication token"""
        base_url = self.get_base_url()
        login_url = f"{base_url}/login"
        
        try:
            session = requests.Session()
            
            # Login data
            login_data = {
                "UserName": self.username_var.get(),
                "Password": self.password_var.get(),
                "RememberMe": "true"
            }
            
            # Perform login
            response = session.post(login_url, data=login_data)
            
            if response.status_code == 200:
                ss_tok = session.cookies.get('ss-tok')
                if ss_tok:
                    return ss_tok
                else:
                    raise Exception("No token found in response")
            else:
                raise Exception(f"Login failed with status code: {response.status_code}")
            
        except Exception as e:
            self.log(f"Error getting token: {str(e)}")
            raise

    def get_saved_token(self):
        """Get token from saved tokens file"""
        try:
            with open('tokens.json', 'r') as f:
                tokens = json.load(f)
                current_env = self.env_var.get()
                if current_env in tokens:
                    return tokens[current_env]
        except FileNotFoundError:
            self.log("No saved tokens found")
        except Exception as e:
            self.log(f"Error loading token: {str(e)}")
        return None

    def save_token(self, token):
        """Save token to file"""
        try:
            tokens = {}
            try:
                with open('tokens.json', 'r') as f:
                    tokens = json.load(f)
            except FileNotFoundError:
                pass
            
            tokens[self.env_var.get()] = token
            
            with open('tokens.json', 'w') as f:
                json.dump(tokens, f, indent=4)
            self.log("Token saved successfully")
        except Exception as e:
            self.log(f"Error saving token: {str(e)}")

    def save_config(self):
        """Save configuration to file"""
        current_number = self.start_number_var.get()
        config = {
            'environment': self.env_var.get(),
            'start_number': current_number,
            'username': self.username_var.get(),
            'password': self.password_var.get(),
            'last_number': current_number,
            'dev_url': self.dev_url_var.get(),
            'stag_url': self.stag_url_var.get()
        }
        
        try:
            with open('retailer_config.json', 'w') as f:
                json.dump(config, f, indent=4)
            self.log(f"Configuration saved successfully. Last number: {current_number}")
        except Exception as e:
            self.log(f"Error saving configuration: {str(e)}")
            messagebox.showerror("Error", str(e))

    def load_config(self):
        """Load configuration from file"""
        try:
            if not os.path.exists('retailer_config.json'):
                # Create initial config file if not exists
                initial_config = {
                    'environment': 'dev',
                    'start_number': '35',
                    'username': 'admin@kiotviet.com',
                    'password': '123',
                    'last_number': '35',
                    'dev_url': 'https://cpanel-salon-dev.booking.citigo.net',
                    'stag_url': 'https://cpanel-salon-stag.booking.citigo.net'
                }
                with open('retailer_config.json', 'w') as f:
                    json.dump(initial_config, f, indent=4)
        
            with open('retailer_config.json', 'r') as f:
                config = json.load(f)
                self.env_var.set(config.get('environment', 'dev'))
                last_number = config.get('last_number', '35')
                self.start_number_var.set(last_number)
                self.username_var.set(config.get('username', 'admin@kiotviet.com'))
                self.password_var.set(config.get('password', '123'))
                self.dev_url_var.set(config.get('dev_url', 'https://cpanel-salon-dev.booking.citigo.net'))
                self.stag_url_var.set(config.get('stag_url', 'https://cpanel-salon-stag.booking.citigo.net'))
                self.log(f"Configuration loaded successfully. Current number: {last_number}")
        except Exception as e:
            self.log(f"Error loading configuration: {str(e)}")
            messagebox.showerror("Error", str(e))

    def get_base_url(self):
        """Get current base URL based on environment"""
        return self.dev_url_var.get() if self.env_var.get() == "dev" else self.stag_url_var.get()

    def create_retailer(self):
        """Create new retailer"""
        try:
            base_url = self.get_base_url()
            api_url = f"{base_url}/api/retailers"
            
            # Get saved token first
            token = self.get_saved_token()
            if token:
                self.log("Using saved token...")
            else:
                self.log("No saved token, getting new token...")
                token = self.get_token()
                if token:
                    self.save_token(token)
            
            # Get current number
            current_num = int(self.start_number_var.get())
            base_name = f"sth{current_num}"
            
            # Prepare dates
            contract_date = datetime.now()
            expiry_date = contract_date + timedelta(days=10)
            
            # Prepare headers
            headers = {
                'accept': 'application/json, text/plain, */*',
                'accept-language': 'en-US,en;q=0.9,vi;q=0.8',
                'content-type': 'application/json;charset=UTF-8',
                'origin': base_url,
                'referer': f'{base_url}/',
                'Cookie': f'ss-tok={token}; ss-opt=temp; ss-pid=cQCvXw3AP3JdBnfG6I1l'
            }
            
            # Prepare payload
            payload = {
                "Retailer": {
                    "AppBrandingId": "1",
                    "MaximumBranchs": 200,
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
                    "ContractType": 88,
                    "TimeSheetBlockUnit": 100,
                    "MaximumRooms": 200,
                    "MaximumProducts": 200,
                    "MaximumFanpages": 200,
                    "LimitKiotMailInMonth": 200,
                    "MaximumSaleChannels": 200,
                    "IndustryId": 16,
                    "ContractDate": contract_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "ExpiryDate": expiry_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
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
            
            # Make API call
            self.log(f"Creating retailer {base_name}...")
            response = requests.post(api_url, headers=headers, json=payload)
            
            # Parse response
            response_data = response.json()
            
            # Handle 401 error
            if response.status_code == 401:
                self.log("Token expired, getting new token...")
                messagebox.showerror("Token Expired", "Token has expired. Please provide new token in tokens.json file")
                return
            
            # Check for error response
            if 'ResponseStatus' in response_data and response_data['ResponseStatus'].get('ErrorCode'):
                error_msg = response_data['ResponseStatus'].get('Message', 'Unknown error')
                self.log(f"Error: {error_msg}")
            
                if "đã tồn tại" in error_msg:
                    # Tự động tăng số và thử lại
                    current_num += 1
                    self.start_number_var.set(str(current_num))
                    self.save_config()
                    messagebox.showinfo("Retailer exists", 
                                      f"Retailer {base_name} already exists.\nAutomatically trying next number: {current_num}")
                    # Gọi đệ quy để thử với số mới
                    self.create_retailer()
                    return
                else:
                    messagebox.showerror("Error", error_msg)
                    return
            
            if response.status_code == 200:
                success_msg = f"Retailer {base_name} created successfully!"
                self.log(success_msg)
                # Increment number for next creation
                self.start_number_var.set(str(current_num + 1))
                self.save_config()
                messagebox.showinfo("Success", success_msg)
            else:
                error_msg = f"Error creating retailer: Status {response.status_code}\nResponse: {response.text}"
                self.log(error_msg)
                messagebox.showerror("Error", error_msg)
            
        except Exception as e:
            error_msg = f"Error: {str(e)}"
            self.log(error_msg)
            messagebox.showerror("Error", error_msg)

    def clear_log(self):
        """Clear the log text area"""
        self.log_text.delete(1.0, tk.END)

def main():
    root = tk.Tk()
    app = RetailerCreator(root)
    root.mainloop()

if __name__ == "__main__":
    main()
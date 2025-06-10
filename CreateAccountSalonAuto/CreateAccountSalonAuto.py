import tkinter as tk
from tkinter import ttk, scrolledtext
import json
import requests
from tkinter import messagebox
from datetime import datetime, timedelta

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
        
        # URLs
        self.DEV_URL = 'https://cpanel-salon-dev.booking.citigo.net'
        self.STAG_URL = 'https://cpanel-salon-stag.booking.citigo.net'
        
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
        
        # Log Display
        log_frame = ttk.LabelFrame(main_frame, text="Creation Log", padding="10")
        log_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=20, width=100)
        self.log_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=3, column=0, columnspan=2, pady=10)
        
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
        main_frame.rowconfigure(2, weight=1)

    def log(self, message):
        """Add message to log with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.log_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.log_text.see(tk.END)
        self.root.update()

    def get_token(self):
        """Get authentication token"""
        base_url = self.DEV_URL if self.env_var.get() == "dev" else self.STAG_URL
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

    def create_retailer(self):
        """Create new retailer"""
        try:
            # Get token first
            self.log("Getting authentication token...")
            token = self.get_token()
            self.log("Token obtained successfully")
            
            # Prepare API call
            base_url = self.DEV_URL if self.env_var.get() == "dev" else self.STAG_URL
            api_url = f"{base_url}/api/retailers"
            
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
            
            if response.status_code == 200:
                self.log(f"Retailer {base_name} created successfully!")
                # Increment number for next creation
                self.start_number_var.set(str(current_num + 1))
                self.save_config()
            else:
                self.log(f"Error creating retailer: Status {response.status_code}")
                self.log(f"Response: {response.text}")
                
        except Exception as e:
            self.log(f"Error: {str(e)}")
            messagebox.showerror("Error", str(e))

    def clear_log(self):
        """Clear the log text area"""
        self.log_text.delete(1.0, tk.END)

    def save_config(self):
        """Save configuration to file"""
        config = {
            'environment': self.env_var.get(),
            'start_number': self.start_number_var.get(),
            'username': self.username_var.get(),
            'password': self.password_var.get()
        }
        
        try:
            with open('retailer_config.json', 'w') as f:
                json.dump(config, f, indent=4)
            self.log("Configuration saved successfully")
        except Exception as e:
            self.log(f"Error saving configuration: {str(e)}")
            messagebox.showerror("Error", str(e))

    def load_config(self):
        """Load configuration from file"""
        try:
            with open('retailer_config.json', 'r') as f:
                config = json.load(f)
                self.env_var.set(config.get('environment', 'dev'))
                self.start_number_var.set(config.get('start_number', '35'))
                self.username_var.set(config.get('username', 'admin@kiotviet.com'))
                self.password_var.set(config.get('password', '123'))
                self.log("Configuration loaded successfully")
        except FileNotFoundError:
            self.log("No saved configuration found, using defaults")
        except Exception as e:
            self.log(f"Error loading configuration: {str(e)}")
            messagebox.showerror("Error", str(e))

def main():
    root = tk.Tk()
    app = RetailerCreator(root)
    root.mainloop()

if __name__ == "__main__":
    main()
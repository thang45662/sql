from selenium import webdriver
import tkinter as tk
from tkinter import simpledialog
import threading
import time
import json

class LoginDialog:
    def __init__(self):
        self.root = tk.Tk()
        self.root.withdraw()  # Ẩn cửa sổ Tk chính
        self.custom_account = None
        self.response = None
        
    def show_dialog(self):
        # Tạo cửa sổ dialog mới
        dialog = tk.Toplevel(self.root)
        dialog.title("Login Options")
        dialog.geometry("300x150")
        
        # Đặt cửa sổ ở giữa màn hình
        dialog.update_idletasks()
        width = dialog.winfo_width()
        height = dialog.winfo_height()
        x = (dialog.winfo_screenwidth() // 2) - (width // 2)
        y = (dialog.winfo_screenheight() // 2) - (height // 2)
        dialog.geometry(f'+{x}+{y}')

        label = tk.Label(dialog, text="Bạn có muốn nhập account khác không?")
        label.pack(pady=10)

        time_label = tk.Label(dialog, text="5")
        time_label.pack()

        def count_down():
            countdown = 5
            while countdown > 0 and not self.response:
                time_label.config(text=str(countdown))
                time.sleep(1)
                countdown -= 1
            if not self.response:
                self.response = "no"
                dialog.destroy()

        def yes_clicked():
            self.response = "yes"
            dialog.destroy()

        def no_clicked():
            self.response = "no"
            dialog.destroy()

        yes_button = tk.Button(dialog, text="Có", command=yes_clicked)
        yes_button.pack(side=tk.LEFT, expand=True, padx=20)

        no_button = tk.Button(dialog, text="Không", command=no_clicked)
        no_button.pack(side=tk.RIGHT, expand=True, padx=20)

        # Bắt đầu đếm ngược trong thread riêng
        threading.Thread(target=count_down, daemon=True).start()
        
        dialog.wait_window()
        
        if self.response == "yes":
            self.custom_account = simpledialog.askstring("Input", "Nhập tên account:")
            
        return self.custom_account

def auto_login():
    try:
        # Hiển thị dialog và chờ lựa chọn
        dialog = LoginDialog()
        custom_account = dialog.show_dialog()
        
        # Thiết lập cho Coc Coc với chế độ ẩn danh
        options = webdriver.ChromeOptions()
        options.add_argument('--start-maximized')
        options.add_argument('--incognito')
        options.binary_location = r"C:\Users\thang.th4\AppData\Local\CocCoc\Browser\Application\browser.exe"
        
        driver = webdriver.Chrome(options=options)
        
        if custom_account:
            # Sử dụng account tùy chỉnh
            retailer_name = custom_account
            username = custom_account
        else:
            # Sử dụng account từ config
            with open('D:/codeAuto/CodeAuto/CreateAccountSalonAuto/retailer_config.json', 'r') as file:
                config = json.load(file)
                current_number = str(int(config.get("start_number", "46")) - 1)
            retailer_name = f"sth{current_number}"
            username = retailer_name
            
        password = "123"
        login_url = f"https://salon-dev.booking.citigo.net/login?redirect=%2f{retailer_name}%2f#f=Unauthorized"
        
        print(f"Starting login process for account: {retailer_name}")
        driver.get(login_url)
        time.sleep(2)
        
        js_fill = f"""
            document.getElementById('Retailer').value = '{retailer_name}';
            document.getElementById('UserName').value = '{username}';
            document.getElementById('Password').value = '{password}';
        """
        driver.execute_script(js_fill)
        time.sleep(1)
        
        driver.execute_script("document.querySelector('input[name=\"quan-ly\"]').click();")
        
        print("Login completed - Browser window will remain open")
        
        while True:
            time.sleep(1)
            
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        if 'driver' in locals():
            driver.save_screenshot("login_error.png")
        return False

if __name__ == "__main__":
    auto_login()
import tkinter as tk
from tkinter import ttk
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time


class TokenManager:
    def __init__(self, root):
        self.root = root
        self.root.title("Token Manager")

        # Configure main window
        self.root.geometry("600x400")
        self.root.resizable(True, True)

        # Variables
        self.env_var = tk.StringVar(value="dev")
        self.token_var = tk.StringVar(value="")
        self.status_var = tk.StringVar(value="Ready")

        # Constants
        self.DEV_URL = 'https://cpanel-salon-dev.booking.citigo.net/login?redirect=%2f#f=Unauthorized'
        self.STAG_URL = 'https://cpanel-salon-stag.booking.citigo.net/login?redirect=%2f#f=Unauthorized'
        self.USERNAME = 'admin@kiotviet.com'
        self.PASSWORD = '123'

        self.create_widgets()
        self.load_saved_tokens()

    def create_widgets(self):
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Environment Selection
        env_frame = ttk.LabelFrame(main_frame, text="Environment Selection", padding="5")
        env_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)

        ttk.Radiobutton(env_frame, text="Development", variable=self.env_var,
                        value="dev", command=self.on_env_change).grid(row=0, column=0, padx=20)
        ttk.Radiobutton(env_frame, text="Staging", variable=self.env_var,
                        value="stag", command=self.on_env_change).grid(row=0, column=1, padx=20)

        # Token Display
        token_frame = ttk.LabelFrame(main_frame, text="Token Information", padding="5")
        token_frame.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)

        # Token text area with scrollbar
        self.token_text = tk.Text(token_frame, height=5, width=50, wrap=tk.WORD)
        self.token_text.grid(row=0, column=0, sticky=(tk.W, tk.E))

        scrollbar = ttk.Scrollbar(token_frame, orient=tk.VERTICAL, command=self.token_text.yview)
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        self.token_text.configure(yscrollcommand=scrollbar.set)

        # Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=2, column=0, columnspan=2, pady=10)

        ttk.Button(button_frame, text="Get New Token",
                   command=self.get_new_token).grid(row=0, column=0, padx=5)
        ttk.Button(button_frame, text="Copy Token",
                   command=self.copy_token).grid(row=0, column=1, padx=5)
        ttk.Button(button_frame, text="Save Token",
                   command=self.save_tokens).grid(row=0, column=2, padx=5)

        # Status bar
        status_bar = ttk.Label(main_frame, textvariable=self.status_var)
        status_bar.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E))

        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)

    def on_env_change(self):
        """Handle environment change"""
        self.load_saved_tokens()

    def get_new_token(self):
        """Get new token from server"""
        self.status_var.set("Getting new token...")
        self.root.update()

        url = self.DEV_URL if self.env_var.get() == "dev" else self.STAG_URL

        try:
            driver = webdriver.Chrome()
            driver.get(url)

            # Wait for username field and login
            username_input = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, "UserName"))
            )
            username_input.send_keys(self.USERNAME)

            password_input = driver.find_element(By.ID, "Password")
            password_input.send_keys(self.PASSWORD)

            login_button = driver.find_element(By.NAME, "quan-ly")
            login_button.click()

            time.sleep(2)

            # Get token
            ss_tok = driver.get_cookie('ss-tok')
            if ss_tok:
                self.token_text.delete(1.0, tk.END)
                self.token_text.insert(tk.END, ss_tok['value'])
                self.save_tokens()
                self.status_var.set("Token retrieved successfully!")
            else:
                self.status_var.set("Failed to get token!")

        except Exception as e:
            self.status_var.set(f"Error: {str(e)}")
        finally:
            driver.quit()

    def copy_token(self):
        """Copy token to clipboard"""
        token = self.token_text.get(1.0, tk.END).strip()
        if token:
            self.root.clipboard_clear()
            self.root.clipboard_append(token)
            self.status_var.set("Token copied to clipboard!")
        else:
            self.status_var.set("No token to copy!")

    def save_tokens(self):
        """Save tokens to file"""
        try:
            tokens = {}
            try:
                with open('tokens.json', 'r') as f:
                    tokens = json.load(f)
            except FileNotFoundError:
                pass

            # Update token for current environment
            tokens[self.env_var.get()] = self.token_text.get(1.0, tk.END).strip()

            with open('tokens.json', 'w') as f:
                json.dump(tokens, f, indent=4)

            self.status_var.set("Tokens saved successfully!")
        except Exception as e:
            self.status_var.set(f"Error saving tokens: {str(e)}")

    def load_saved_tokens(self):
        """Load saved tokens from file"""
        try:
            with open('tokens.json', 'r') as f:
                tokens = json.load(f)
                current_env = self.env_var.get()
                if current_env in tokens:
                    self.token_text.delete(1.0, tk.END)
                    self.token_text.insert(tk.END, tokens[current_env])
                    self.status_var.set(f"Loaded saved token for {current_env}")
                else:
                    self.token_text.delete(1.0, tk.END)
                    self.status_var.set(f"No saved token for {current_env}")
        except FileNotFoundError:
            self.status_var.set("No saved tokens found")
        except Exception as e:
            self.status_var.set(f"Error loading tokens: {str(e)}")


def main():
    root = tk.Tk()
    app = TokenManager(root)
    root.mainloop()


if __name__ == "__main__":
    main()
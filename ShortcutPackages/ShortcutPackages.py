import os
import winshell
from win32com.client import Dispatch

exe_path = r"D:\codeAuto\CodeAuto\CreateAccountSalonAuto\dist\CreateAccountSalonAuto.exe"
shortcut_path = os.path.join(winshell.desktop(), "CreateAccountSalonAuto.lnk")

shell = Dispatch('WScript.Shell')
shortcut = shell.CreateShortCut(shortcut_path)
shortcut.Targetpath = exe_path
shortcut.WorkingDirectory = os.path.dirname(exe_path)
shortcut.IconLocation = exe_path
shortcut.save()

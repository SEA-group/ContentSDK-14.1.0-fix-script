# ContentSDK 14.1.0 update tool

![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/SEA-group/ContentSDK-14.1.0-fix-script?include_prereleases)
![GitHub last commit](https://img.shields.io/github/last-commit/SEA-group/ContentSDK-14.1.0-fix-script)
![GitHub issues](https://img.shields.io/github/issues-raw/SEA-group/ContentSDK-14.1.0-fix-script)
![GitHub downloads](https://img.shields.io/github/downloads/SEA-group/ContentSDK-14.1.0-fix-script/total)

A batch fix tool for PnF-typed skin mods in patch 14.1.0.
Originally coded in Matlab, translated to Python by DeepSeek followed by human debug.
Special thanks to Aslain and the test team of SEA Group for their active contribution.

It is currently suggested to use the Python version instead of the original Matlab version.

## A priori
* The old mods had no evident bug and worked in 14.0.0.
* The old mods have no unnecessary .model files, expecially backups.
* You have a safe backup of your old mods in a repository that can't be affected by this script.
* You have Python 3 installed and runtime environment configured on your computer.

## How to use
1. Put `SEA_xml_rectifier.py` in the repository of your old mods, say `[Repo_Mods]`.
2. Download the [latest Content SDK](https://github.com/wgmods/ModSDK/tags).
3. Create a folder `ModsSDK/` in `[Repo_Mods]` (by default), put all related ship SDK inside; or you can create a `ModsSDK/` elsewhere, and assigne the path in the python code line 13.
4. Run `SEA_xml_rectifier.py`, let the script process your mods.
5. Test the processed mods in game.
6. In file explorer, search for all folders `lods/`、all files `*.visualbak` and `*.modelbak`, delete them.

If you have absolute confidence in this script, you can toggle the parameter *keep_legacy_files* in line 9 to *False* prior to step 4, it will delete obsolete files so that you don't need to proceed to step 6 manually.

## Warning
If *keep_legacy_files* is set to *False*, **make sure that you're running the code in the repository where you put `SEA_xml_rectifier.py`, i.e. `[Repo_Mods]`.** Double click on `SEA_xml_rectifier.py` in file explorer is a safe move.

A bad example is to run `C:\Users\user_name> & C:/Users/user_name/AppData/Local/Programs/Python/Python3/python.exe D:/Documents/ModFix/SEA_xml_rectifier.py` in command line, this happens to PowerShell and some IDE when using %userprofile% as default path. In this case, the cleanup function looks for files to delete in `C:\Users\user_name` instead of `[Repo_Mods]`, and can remove irrelevant files.
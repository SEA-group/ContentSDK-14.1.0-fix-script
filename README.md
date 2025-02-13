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
* The old mods had no evident bug and worked in 14.0.0;
* The old mods have no unnecessary .model files, expecially backups;
* You have a safe backup of your old mods in a repository that can't be affected by this script.
* You have Python 3 installed and runtime environment configured on your computer.

## How to use
1. Put `SEA_xml_rectifier.py` in the repository of your old mods, say `[Repo_Mods]`;
2. Download the [latest Content SDK](https://github.com/wgmods/ModSDK/tags);
3. Create a folder `ModsSDK/` in `[Repo_Mods]`, put all related ship SDK inside;
4. Run `SEA_xml_rectifier.py`, let the script process your mods;
5. Test the processed mods in game;
6. In file explorer, search for all folders `lods/`、all files `*.visualbak` and `*.modelbak`, delete them.

If you have absolute confidence in this script, you can toggle the parameter *keep_legacy_files* in line 7 to *False* prior to step 4, it will delete obsolete files so that you don't need to proceed to step 6 manually.
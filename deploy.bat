@echo off
echo Copying files...
xcopy "..\BetterBags_ItemRack" "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns" /exclude:exclude.txt /y
echo Deployed
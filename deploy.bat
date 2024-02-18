@echo off
echo Copying files...
xcopy "." "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\BetterBags_ItemRack" /exclude:exclude.txt /y /i
echo Deployed
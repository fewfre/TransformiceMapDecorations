## V1.4 - 9 April 2023
- Porting over TFM dressroom code changes from last few years
- Added support for app to be openable in launcher
- Decoration categories now supported
- [Misc] (6 Jul 24) Converted changelog into markdown


## V1.3 - 9 June 2018
- Code cleanup / validation for "strict" compilation
- Small changes to code strucutre (including old file removal)
- Re-added infobar download button (for consitent name/scale for wiki)


## V1.2 - 16 December 2017
- Increased color swatches to 10 so there are enough for all items.
- Item resource swfs now loaded based on config.json
- Renamed "Costumes" to "GameAssets" and changed it from a singleton to a static class.


## V1.1 - 6 September 2017
- Adding various languages
- Moved over TFM Dressroom rework:
	- V1.5
		- Added app info on bottom left
			- Moved github button from Toolbox
			- Now display app's version (using a new "version" i18n string)
			- Now display translator's name (if app not using "en" and not blank) (using a new "translated_by" i18n string)
		- Bug: ConstantsApp.VERSION is now stored as a string.
		- Download button on Toolbox is now bigger (to show importance)
		- ShopInfoBar buttons tweaked
			- Refresh button is now smaller and to the right of download button
			- Added a "lock" button to prevent randomizing a specific category (inspired by micetigri Nekodancer generator)
			- If a button doesn't exist, there is no longer a blank space on the right.
			- Download button is now smaller (so as to not be bigger than main download button).
		- AssetManager now stores the loaded ApplicationDomains instead of the returned content as a movieclip
		- AssetManager now loads data into currentDomain if "useCurrentDomain" is used for that swf
		- Moved UI assets into a separate swf
		- Fewf class now keeps track of Stage, and has a MovieClip called "dispatcher" for global events.
		- I18n & TextBase updated to allow for changing language during runtime.
		- You can now change language during run-time
	- V1.6
		- Color finder feature added for items.
		- [bug] If you selected an item + colored it, selected something else, and then selected it again, the infobar image showed the default image.
		- [bug] Downloading a colored image (vs whole mouse) didn't save it colored.
	- V1.7
		- Imgur upload option added.
		- Resources are no longer cached.

## V1.0 - 4 July 2017
- Initial (rough) Commit - fully functional

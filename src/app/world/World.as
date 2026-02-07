package app.world
{
	import app.ui.*;
	import app.ui.common.*;
	import app.ui.panes.*;
	import app.ui.panes.colorpicker.*;
	import app.ui.screens.*;
	import app.ui.buttons.*;
	import app.data.*;
	import app.world.data.*;
	import app.world.elements.*;
	
	import com.adobe.images.*;
	import com.piterwilson.utils.*;
	import com.fewfre.utils.AssetManager;
	import com.fewfre.display.*;
	import com.fewfre.events.FewfEvent;
	import com.fewfre.utils.*;
	import ext.ParentApp;

	import flash.display.*;
	import flash.events.*
	import flash.external.ExternalInterface;
	import flash.display.MovieClip;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	import flash.net.URLVariables;
	
	public class World extends Sprite
	{
		// Storage
		internal var character		: CustomItem;
		internal var _paneManager	: PaneManager;

		internal var shopTabs		: ShopTabList;
		internal var _toolbox		: Toolbox;
		// internal var linkTray		: LinkTray;
		internal var _langScreen	: LangScreen;
		private var _aboutScreen    : AboutScreen;

		internal var currentlyColoringType:CategoryType=null;
		
		// Constants
		public static const COLOR_PANE_ID = "colorPane";
		public static const COLOR_FINDER_PANE_ID = "colorFinderPane";
		public static const TAB_OTHER:String = "other";
		
		// Constructor
		public function World(pStage:Stage) {
			super();
			_buildWorld(pStage);
			pStage.addEventListener(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
			pStage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDownListener);
		}
		
		private function _buildWorld(pStage:Stage) {
			GameAssets.init();

			/****************************
			* Create CustomItem
			*****************************/
			var parms:URLVariables = null;
			try {
				var urlPath:String = ExternalInterface.call("eval", "window.location.href");
				if(urlPath && urlPath.indexOf("?") > 0) {
					urlPath = urlPath.substr(urlPath.indexOf("?") + 1, urlPath.length);
					parms = new URLVariables();
					parms.decode(urlPath);
				}
			} catch (error:Error) { };

			this.character = addChild(new CustomItem({ x:190, y:325,
				item: GameAssets.getItemDataListByType(CategoryType.ALL[0])[0],
				params:parms
			})) as CustomItem;

			/****************************
			* Setup UI
			*****************************/
			var tShop:RoundedRectangle = new RoundedRectangle({ x:450, y:10, width:ConstantsApp.SHOP_WIDTH, height:ConstantsApp.SHOP_HEIGHT })
				.appendTo(this).drawAsTray();
			_paneManager = tShop.addChild(new PaneManager()) as PaneManager;
			
			var tabs:Vector.<Object> = new <Object>[];
			for each(var tType:CategoryType in CategoryType.ALL) {
				tabs.push({ text:tType.toString(), event:tType.toString() });
			}
			
			this.shopTabs = new ShopTabList(70, ConstantsApp.SHOP_HEIGHT, tabs).setXY(375, 10).appendTo(this);
			this.shopTabs.addEventListener(ShopTabList.TAB_CLICKED, _onTabClicked);

			// Toolbox
			_toolbox = addChild(new Toolbox({
				x:188, y:28, character:character,
				onSave:_onSaveClicked, onAnimate:_onPlayerAnimationToggle, /*onRandomize:_onRandomizeDesignClicked,*/
				onScale:_onScaleSliderChange // onShare:_onShareButtonClicked, 
			})) as Toolbox;
			
			/////////////////////////////
			// Bottom Left Area
			/////////////////////////////
			var tLangButton:SpriteButton = LangScreen.createLangButton({ width:30, height:25, origin:0.5 })
				.move(22, pStage.stageHeight-17).appendTo(this)
				.onButtonClick(_onLangButtonClicked) as SpriteButton;
			
			// About Screen Button
			var aboutButton:GameButton = new GameButton({ width:25, height:25, origin:0.5 }).move(tLangButton.x+(tLangButton.Width/2)+2+(25/2), ConstantsApp.APP_HEIGHT - 17).appendTo(this)
				.onButtonClick(_onAboutButtonClicked) as GameButton;
			new TextBase({ size:22, color:0xFFFFFF, bold:true, origin:0.5 }).move(0, -1).appendTo(aboutButton).setUntranslatedText("?");
			
			if(!!(ParentApp.reopenSelectionLauncher())) {
				new ScaleButton({ obj:new $BackArrow(), obj_scale:0.5 }).appendTo(this)
					.move(22, ConstantsApp.APP_HEIGHT-17-28)
					.onButtonClick(function():void{ ParentApp.reopenSelectionLauncher()(); });
			}
			
			/****************************
			* Screens
			*****************************/
			// linkTray = new LinkTray({ x:pStage.stageWidth * 0.5, y:pStage.stageHeight * 0.5 });
			// linkTray.addEventListener(LinkTray.CLOSE, _onShareTrayClosed);
			
			_langScreen = new LangScreen({  });
			_langScreen.addEventListener(LangScreen.CLOSE, _onLangScreenClosed);
			
			_aboutScreen = new AboutScreen();
			_aboutScreen.addEventListener(Event.CLOSE, _onAboutScreenClosed);
			
			/****************************
			* Create tabs and panes
			*****************************/
			var tPane = null;
			
			tPane = _paneManager.addPane(COLOR_PANE_ID, new ColorPickerTabPane({}));
			tPane.addEventListener(ColorPickerTabPane.EVENT_COLOR_PICKED, _onColorPickChanged);
			tPane.addEventListener(ColorPickerTabPane.EVENT_DEFAULT_CLICKED, _onDefaultsButtonClicked);
			tPane.addEventListener(ColorPickerTabPane.EVENT_EXIT, _onColorPickerBackClicked);
			
			tPane = _paneManager.addPane(COLOR_FINDER_PANE_ID, new ColorFinderPane({ }));
			tPane.addEventListener(ColorFinderPane.EVENT_EXIT, _onColorFinderBackClicked);

			// Create the panes
			for each(var tType:CategoryType in CategoryType.ALL) {
				tPane = _paneManager.addPane(tType.toString(), _setupPane(tType));
			}
			
			// Select First Pane
			shopTabs.tabs[0].toggleOn();
			_paneManager.getPane(CategoryType.ALL[0].toString()).buttons[0].toggleOn();
			
			tPane = null;
		}

		private function _setupPane(pType:CategoryType) : TabPane {
			var tPane:TabPane = new TabPane();
			tPane.addInfoBar( new ShopInfoBar({ showEyeDropButton:true, showGridManagementButtons:true }) );
			_setupPaneButtons(pType, tPane, GameAssets.getItemDataListByType(pType));
			tPane.infoBar.colorWheel.addEventListener(ButtonBase.CLICK, function(){ _colorButtonClicked(pType); });
			tPane.infoBar.removeItemOverlay.addEventListener(MouseEvent.CLICK, function(){ _removeItem(pType); });
			// Grid Management Events
			tPane.infoBar.randomizeButton.addEventListener(ButtonBase.CLICK, function(){ _randomItemOfType(pType); });
			tPane.infoBar.reverseButton.addEventListener(ButtonBase.CLICK, function(){ tPane.grid.reverse(); });
			tPane.infoBar.rightItemButton.addEventListener(ButtonBase.CLICK, function(){ _traversePaneButtonGrid(tPane, true); });
			tPane.infoBar.leftItemButton.addEventListener(ButtonBase.CLICK, function(){ _traversePaneButtonGrid(tPane, false); });
			// Misc
			if(tPane.infoBar.eyeDropButton) {
				tPane.infoBar.eyeDropButton.addEventListener(ButtonBase.CLICK, function(){ _eyeDropButtonClicked(pType); });
			}
			return tPane;
		}

		private function _setupPaneButtons(pType:CategoryType, pPane:TabPane, pItemArray:Vector.<ItemData>) : void {
			var buttonPerRow = 5;
			var scale = 1;
			// if(pType == CategoryType.Various) {
			// 		buttonPerRow = 4;
			// 		scale = 1;
			// }

			var grid:Grid = pPane.grid;
			if(!grid) { grid = pPane.addGrid( new Grid(385, buttonPerRow) ).setXY(15, 5); }
			grid.reset();

			var shopItem : MovieClip;
			var shopItemButton : PushButton;
			var i = -1;
			while (i < pItemArray.length-1) { i++;
				shopItem = GameAssets.getItemImage(pItemArray[i]);
				shopItem.scaleX = shopItem.scaleY = scale;

				shopItemButton = new PushButton({ width:grid.cellSize, height:grid.cellSize, obj:shopItem, id:i, data:{ type:pType, id:i } });
				grid.add(shopItemButton);
				pPane.buttons.push(shopItemButton);
				shopItemButton.addEventListener(PushButton.STATE_CHANGED_AFTER, _onItemToggled);
			}
			pPane.UpdatePane();
		}

		private function _onMouseWheel(pEvent:MouseEvent) : void {
			if(this.mouseX < this.shopTabs.x) {
				_toolbox.scaleSlider.updateViaMouseWheelDelta(pEvent.delta);
				character.scale = _toolbox.scaleSlider.value;
			}
		}

		private function _onKeyDownListener(e:KeyboardEvent) : void {
			if (e.keyCode == Keyboard.RIGHT){
				_traversePaneButtonGrid(_paneManager.getOpenPane(), true);
			}
			else if (e.keyCode == Keyboard.LEFT) {
				_traversePaneButtonGrid(_paneManager.getOpenPane(), false);
			}
			else if (e.keyCode == Keyboard.UP){
				_traversePaneButtonGridVertically(_paneManager.getOpenPane(), true);
			}
			else if (e.keyCode == Keyboard.DOWN) {
				_traversePaneButtonGridVertically(_paneManager.getOpenPane(), false);
			}
		}
		
		private function _traversePaneButtonGrid(pane:TabPane, pRight:Boolean):void {
			if(pane && pane.grid && pane.buttons && pane.buttons.length > 0 && pane.buttons[0] is PushButton) {
				var buttons:Array = pane.buttons;
				var activeButtonIndex:int = _findIndexActivePushButton(buttons);
				if(activeButtonIndex == -1) { activeButtonIndex = pane.grid.reversed ? buttons.length-1 : 0; }
				
				var dir:int = (pRight ? 1 : -1) * (pane.grid.reversed ? -1 : 1),
					length:uint = buttons.length;
					
				var newI:int = activeButtonIndex+dir;
				// mod it so it wraps - `length` added before mod to allow a `-1` dir to properly wrap
				newI = (length + newI) % length;
				
				var btn:PushButton = buttons[newI];
				btn.toggleOn();
				pane.scrollItemIntoView(btn);
			}
		}
		
		private function _traversePaneButtonGridVertically(pane:TabPane, pUp:Boolean):void {
			if(pane && pane.grid && pane.buttons && pane.buttons.length > 0 && pane.buttons[0] is PushButton) {
				var buttons:Array = pane.buttons, grid:Grid = pane.grid;
				
				var activeButtonIndex:int = _findIndexActivePushButton(buttons);
				if(activeButtonIndex == -1) { activeButtonIndex = grid.reversed ? buttons.length-1 : 0; }
				var dir:int = (pUp ? -1 : 1) * (grid.reversed ? -1 : 1),
					length:uint = buttons.length;
				
				var rowI:Number = Math.floor(activeButtonIndex / grid.columns);
				rowI = (rowI + dir); // increment row in direction
				rowI = (grid.rows + rowI) % grid.rows; // wrap it in both directions
				var colI = activeButtonIndex % grid.columns;
				
				// we want to stay in the same column, and just move up/down a row
				// var newRowI:Number = (grid.rows + rowI) % grid.rows;
				var newI:int = rowI*grid.columns + colI;
				
				// since row is modded, it can only ever be out of bounds at the end - this happens if the last
				// row doesn't have enough items to fill all columns, and active column is in one of them.
				if(newI >= length) {
					// we solve it by going an extra step in our current direction, mod it again so it can wrap if needed,
					// and then we recalculate the button i
					rowI += dir;
					rowI = (grid.rows + rowI) % grid.rows; // wrap it again
					newI = rowI*grid.columns + colI;
				}
				
				var btn:PushButton = buttons[newI];
				btn.toggleOn();
				pane.scrollItemIntoView(btn);
			}
		}
		
		// Find the pressed button
		private function _findIndexActivePushButton(pButtons:Array):int {
			for(var i:int = 0; i < pButtons.length; i++){
				if((pButtons[i] as PushButton).pushed){
					return i;
				}
			}
			return -1;
		}

		private function _onScaleSliderChange(pEvent:Event):void {
			character.scale = _toolbox.scaleSlider.value;
		}

		private function _onPlayerAnimationToggle(pEvent:Event):void {
			character.nextFrameChildren();
			// character.animatePose = !character.animatePose;
			// if(character.animatePose) {
			// 	character.outfit.play();
			// } else {
			// 	character.outfit.stop();
			// }
			// _toolbox.toggleAnimateButtonAsset(character.animatePose);
		}
		
	//#region Saving
		private function _getHardcodedSaveScale() : Number {
			var hardcodedSaveScale:Object = Fewf.sharedObject.getData(ConstantsApp.SHARED_OBJECT_KEY_HARDCODED_SAVE_SCALE);
			return hardcodedSaveScale ? hardcodedSaveScale as Number : 0;
		}

		private function _onSaveClicked(pEvent:Event) : void {
			_saveAsPNG(this.character, "decoration", this.character.scaleX);
		}
		
		private function _saveAsPNG(pObj:DisplayObject, pName:String, pScale:Number) : void {
			pScale = _getHardcodedSaveScale() || pScale;
			var hardcodedCanvasSaveSize:Object = Fewf.sharedObject.getData(ConstantsApp.SHARED_OBJECT_KEY_HARDCODED_CANVAS_SAVE_SIZE);
			if(!hardcodedCanvasSaveSize) {
				FewfDisplayUtils.saveAsPNG(pObj, pName, pScale);
			} else {
				FewfDisplayUtils.saveAsPNGWithFixedCanvasSize(pObj, pName, hardcodedCanvasSaveSize as Number, pScale, 0, 0);
			}
		}
	//#endregion Saving

		private function _onItemToggled(pEvent:FewfEvent) : void {
			var tType:CategoryType = pEvent.data.type;
			var tItemArray:Vector.<ItemData> = GameAssets.getItemDataListByType(tType);
			var tInfoBar:ShopInfoBar = getInfoBarByType(tType);

			// De-select all buttons that aren't the clicked one.
			var tButtons:Array = getButtonArrayByType(tType);
			for(var i:int = 0; i < tButtons.length; i++) {
				if(tButtons[i].data.id != pEvent.data.id) {
					if (tButtons[i].pushed)  { tButtons[i].toggleOff(); }
				}
			}
			
			// Select buttons on other tabs
			var tButtons2:Array = null;
			for(var j:int = 0; j < CategoryType.ALL.length; j++) {
				if(CategoryType.ALL[j] == tType) { continue; }
				tButtons2 = getButtonArrayByType(CategoryType.ALL[j]);
				for(var i:int = 0; i < tButtons2.length; i++) {
					if (tButtons2[i].pushed)  { tButtons2[i].toggleOff(); }
				}
				getTabByType(CategoryType.ALL[j]).infoBar.removeInfo();
			}
			tButtons2 = null;

			var tButton:PushButton = tButtons[pEvent.data.id];
			var tData:ItemData;
			// If clicked button is toggled on, equip it. Otherwise remove it.
			if(tButton.pushed) {
				tData = tItemArray[pEvent.data.id];
				setCurItemID(tType, tButton.id);
				this.character.setItemData(tData);

				tInfoBar.addInfo( tData, GameAssets.getColoredItemImage(tData) );
				tInfoBar.showColorWheel(GameAssets.getNumOfCustomColors(tButton.Image as MovieClip) > 0);
			} else {
				_removeItem(tType);
			}
		}

		private function toggleItemSelectionOneOff(pType:CategoryType, pButton:PushButton, pItemData:ItemData) : void {
			if (pButton.pushed) {
				this.character.setItemData( pItemData );
			} else {
				this.character.removeItem(pType);
			}
		}

		private function _removeItem(pType:CategoryType) : void {
			var tTabPane = getTabByType(pType);
			if(tTabPane.infoBar.hasData == false) { return; }

			// If item has a default value, toggle it on. otherwise remove item.
			/*if(pType == ITEM.SKIN || pType == ITEM.POSE) {*/
				var tDefaultIndex = 0;//(pType == ITEM.POSE ? GameAssets.defaultPoseIndex : GameAssets.defaultSkinIndex);
				tTabPane.buttons[tDefaultIndex].toggleOn();
			/*} else {
				this.character.removeItem(pType);
				tTabPane.infoBar.removeInfo();
				tTabPane.buttons[ tTabPane.selectedButtonIndex ].toggleOff();
			}*/
		}
		
		private function _onTabClicked(pEvent:FewfEvent) : void {
			_paneManager.openPane(pEvent.data.toString());
		}

		// private function _onRandomizeDesignClicked(pEvent:Event) : void {
		// 	for(var i:int = 0; i < ITEM.LAYERING.length; i++) {
		// 		_randomItemOfType(ITEM.LAYERING[i]);
		// 	}
		// 	_randomItemOfType(ITEM.POSE);
		// }

		private function _randomItemOfType(pType:CategoryType) : void {
			/*if(getInfoBarByType(pType).isRefreshLocked) { return; }*/
			var tButtons = getButtonArrayByType(pType);
			var tLength = tButtons.length;
			tButtons[ Math.floor(Math.random() * tLength) ].toggleOn();
		}

		// private function _onShareButtonClicked(pEvent:Event) : void {
		// 	var tURL = "";
		// 	try {
		// 		tURL = ExternalInterface.call("eval", "window.location.origin+window.location.pathname");
		// 		tURL += "?"+this.character.getParams();
		// 	} catch (error:Error) {
		// 		tURL = "<error creating link>";
		// 	};

		// 	linkTray.open(tURL);
		// 	addChild(linkTray);
		// }

		// private function _onShareTrayClosed(pEvent:Event) : void {
		// 	removeChild(linkTray);
		// }

		private function _onLangButtonClicked(pEvent:Event) : void {
			_langScreen.open();
			addChild(_langScreen);
		}

		private function _onLangScreenClosed(pEvent:Event) : void {
			removeChild(_langScreen);
		}

		private function _onAboutButtonClicked(e:Event) : void {
			_aboutScreen.open();
			addChild(_aboutScreen);
		}

		private function _onAboutScreenClosed(e:Event) : void {
			removeChild(_aboutScreen);
		}

		//{REGION Get TabPane data
			private function getTabByType(pType:CategoryType) : TabPane {
				return _paneManager.getPane(pType.toString());
			}

			private function getInfoBarByType(pType:CategoryType) : ShopInfoBar {
				return getTabByType(pType).infoBar;
			}

			private function getButtonArrayByType(pType:CategoryType) : Array {
				return getTabByType(pType).buttons;
			}

			private function getCurItemID(pType:CategoryType) : int {
				return getTabByType(pType).selectedButtonIndex;
			}

			private function setCurItemID(pType:CategoryType, pID:int) : void {
				getTabByType(pType).selectedButtonIndex = pID;
			}
		//}END Get TabPane data

		//{REGION Color Tab
			private function _onColorPickChanged(pEvent:FewfEvent):void {
				var color:uint = uint(pEvent.data.color);
				var pane = _paneManager.getPane(COLOR_PANE_ID) as ColorPickerTabPane;
				if(pEvent.data.randomizedAll) {
					this.character.getItemData(this.currentlyColoringType).colors = pane.getAllColors();
				} else {
					this.character.getItemData(this.currentlyColoringType).colors[pane.selectedSwatch] = color;
				}
				_refreshSelectedItemColor();
			}

			private function _onDefaultsButtonClicked(pEvent:Event) : void
			{
				this.character.getItemData(this.currentlyColoringType).setColorsToDefault();
				_refreshSelectedItemColor();
				(_paneManager.getPane(COLOR_PANE_ID) as ColorPickerTabPane).setupSwatches( this.character.getColors(this.currentlyColoringType) );
			}
			
			private function _refreshSelectedItemColor() : void {
				character.updateItem();
				
				var tItemData = this.character.getItemData(this.currentlyColoringType);
				var tItem:MovieClip = GameAssets.getColoredItemImage(tItemData);
				GameAssets.copyColor(tItem, getButtonArrayByType(this.currentlyColoringType)[ getCurItemID(this.currentlyColoringType) ].Image );
				GameAssets.copyColor(tItem, getInfoBarByType( this.currentlyColoringType ).Image );
				GameAssets.copyColor(tItem, _paneManager.getPane(COLOR_PANE_ID).infoBar.Image);
				/*var tMC:MovieClip = this.character.getItemFromIndex(this.currentlyColoringType);
				if (tMC != null)
				{
					GameAssets.colorDefault(tMC);
					GameAssets.copyColor( tMC, getButtonArrayByType(this.currentlyColoringType)[ getCurItemID(this.currentlyColoringType) ].Image );
					GameAssets.copyColor(tMC, getInfoBarByType(this.currentlyColoringType).Image);
					GameAssets.copyColor(tMC, _paneManager.getPane(COLOR_PANE_ID).infoBar.Image);
					
				}*/
			}

			private function _colorButtonClicked(pType:CategoryType) : void {
				if(this.character.getItemData(this.currentlyColoringType) == null) { return; }

				var tData:ItemData = getInfoBarByType(pType).data;
				_paneManager.getPane(COLOR_PANE_ID).infoBar.addInfo( tData, GameAssets.getItemImage(tData) );
				this.currentlyColoringType = pType;
				(_paneManager.getPane(COLOR_PANE_ID) as ColorPickerTabPane).setupSwatches( this.character.getColors(this.currentlyColoringType) );
				_paneManager.openPane(COLOR_PANE_ID);
			}

			private function _onColorPickerBackClicked(pEvent:Event):void {
				_paneManager.openPane(_paneManager.getPane(COLOR_PANE_ID).infoBar.data.type.toString());
			}

			private function _eyeDropButtonClicked(pType:CategoryType) : void {
				if(this.character.getItemData(pType) == null) { return; }

				var tData:ItemData = getInfoBarByType(pType).data;
				var tItem:MovieClip = GameAssets.getColoredItemImage(tData);
				var tItem2:MovieClip = GameAssets.getColoredItemImage(tData);
				_paneManager.getPane(COLOR_FINDER_PANE_ID).infoBar.addInfo( tData, tItem );
				this.currentlyColoringType = pType;
				(_paneManager.getPane(COLOR_FINDER_PANE_ID) as ColorFinderPane).setItem(tItem2);
				_paneManager.openPane(COLOR_FINDER_PANE_ID);
			}

			private function _onColorFinderBackClicked(pEvent:Event):void {
				_paneManager.openPane(_paneManager.getPane(COLOR_FINDER_PANE_ID).infoBar.data.type.toString());
			}
		//}END Color Tab
	}
}

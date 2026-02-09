package app.world
{
	import app.data.*;
	import app.ui.*;
	import app.ui.buttons.*;
	import app.ui.common.*;
	import app.ui.panes.*;
	import app.ui.panes.colorpicker.*;
	import app.ui.panes.infobar.GridManagementWidget;
	import app.ui.panes.infobar.Infobar;
	import app.ui.screens.*;
	import app.world.data.*;
	import app.world.elements.*;

	import com.fewfre.display.*;
	import com.fewfre.events.FewfEvent;
	import com.fewfre.utils.*;

	import ext.ParentApp;

	import flash.display.*;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	import app.ui.panes.base.SidePane;
	import app.ui.panes.base.ButtonGridSidePane;
	import app.world.events.ItemDataEvent;
	
	public class World extends Sprite
	{
		// Storage
		private var _character         : CustomItem;
		private var _panes             : PaneManager_World;

		private var _shopTabs          : ShopTabList;
		private var _toolbox           : Toolbox;
		
		// internal var linkTray		: LinkTray;
		internal var _langScreen	: LangScreen;
		private var _aboutScreen    : AboutScreen;

		internal var currentlyColoringType:CategoryType=null;
		
		// Constructor
		public function World(pStage:Stage) {
			super();
			_buildWorld(pStage);
			pStage.addEventListener(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
			pStage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDownListener);
		}
		
		private function _buildWorld(pStage:Stage) {
			GameAssets.init();

			/////////////////////////////
			// Create CustomItem
			/////////////////////////////
			var paramsString:String = null;
			if(!Fewf.isExternallyLoaded) {
				try {
					var urlPath:String = ExternalInterface.call("eval", "window.location.href");
					if(urlPath && urlPath.indexOf("?") > 0) {
						urlPath = urlPath.substr(urlPath.indexOf("?") + 1, urlPath.length);
					}
					paramsString = urlPath;
				} catch (error:Error) { };
			}

			_character = new CustomItem(GameAssets.getItemDataListByType(CategoryType.ALL[0])[0], paramsString)
				.move(190, 325).setDragBounds(0+4, 73+4, 375-4-4, ConstantsApp.APP_HEIGHT-(73+4)-4).appendTo(this);

			/////////////////////////////
			// Setup UI
			/////////////////////////////
			_shopTabs = new ShopTabList(70, ConstantsApp.SHOP_HEIGHT).move(375, 10).appendTo(this).on(ShopTabList.TAB_CLICKED, _onTabClicked);
			for each(var tType:CategoryType in CategoryType.ALL) {
				_shopTabs.addTab(tType.toString(), tType.toString());
			}
			
			var tShop:RoundRectangle = new RoundRectangle(ConstantsApp.SHOP_WIDTH, ConstantsApp.SHOP_HEIGHT).move(450, 10)
				.appendTo(this).drawAsTray();
			_panes = new PaneManager_World().appendTo(tShop.root) as PaneManager_World;

			/////////////////////////////
			// Top Area
			/////////////////////////////
			_toolbox = new Toolbox(_character).move(188, 28).appendTo(this)
				.on(Toolbox.SAVE_CLICKED, _onSaveClicked)
				.on(Toolbox.CLIPBOARD_CLICKED, _onClipboardButtonClicked)
				
				.on(Toolbox.SCALE_SLIDER_CHANGE, _onScaleSliderChange)
				.on(Toolbox.DEFAULT_SCALE_CLICKED, _onScaleSliderDefaultClicked)
				
				.on(Toolbox.RANDOM_CLICKED, _onRandomizeDesignClicked);
			
			/////////////////////////////
			// Bottom Left Area
			/////////////////////////////
			var tLangButton:GameButton = LangScreen.createLangButton(30, 25).move(22, ConstantsApp.APP_HEIGHT-17).appendTo(this)
				.onButtonClick(_onLangButtonClicked) as GameButton;
			
			// About Screen Button
			var aboutButton:GameButton = new GameButton(25).setOrigin(0.5).move(tLangButton.x+(tLangButton.Width/2)+2+(25/2), ConstantsApp.APP_HEIGHT - 17).appendTo(this)
				.onButtonClick(_onAboutButtonClicked) as GameButton;
			new TextBase("?", { size:22, color:0xFFFFFF, bold:true, origin:0.5 }).move(0, -1).appendTo(aboutButton);
			
			if(!!(ParentApp.reopenSelectionLauncher())) {
				new ScaleButton(new $BackArrow(), 0.5).appendTo(this)
					.move(22, ConstantsApp.APP_HEIGHT-17-28)
					.onButtonClick(function():void{ ParentApp.reopenSelectionLauncher()(); });
			}
			
			/////////////////////////////
			// Screens
			/////////////////////////////
			// _shareScreen = new ShareScreen().on(Event.CLOSE, _onShareScreenClosed);
			_langScreen = new LangScreen().on(Event.CLOSE, _onLangScreenClosed);
			_aboutScreen = new AboutScreen().on(Event.CLOSE, _onAboutScreenClosed);
			
			/////////////////////////////
			// Create item panes
			/////////////////////////////
			for each(var tType:CategoryType in CategoryType.ALL) {
				_panes.addPane(PaneManager_World.categoryTypeToId(tType), _setupPane(tType));
			}
			
			/////////////////////////////
			// Static Panes
			/////////////////////////////
			// Color Picker Pane
			_panes.addPane(PaneManager_World.COLOR_PANE, new ColorPickerTabPane())
				.on(ColorPickerTabPane.EVENT_COLOR_PICKED, _onColorPickChanged)
				// .on(ColorPickerTabPane.EVENT_PREVIEW_COLOR, _onColorPickHoverPreview)
				.on(Event.CLOSE, _onColorPickerBackClicked)
				.on(ColorPickerTabPane.EVENT_ITEM_ICON_CLICKED, function(e){
					_onColorPickerBackClicked(e);
					_removeItem(_panes.colorPickerPane.infobar.itemData.type);
				});
			
			// Color Finder Pane
			_panes.addPane(PaneManager_World.COLOR_FINDER_PANE, new ColorFinderPane())
				.on(Event.CLOSE, _onColorFinderBackClicked)
				.on(ColorFinderPane.EVENT_ITEM_ICON_CLICKED, function(e){
					_onColorFinderBackClicked(e);
					_removeItem(_panes.colorFinderPane.infobar.itemData.type);
				});
			
			// Select First Pane
			_shopTabs.toggleOnFirstTab();
			_panes.getShopPane(CategoryType.ALL[0]).buttons[0].toggleOn();
		}

		private function _setupPane(pType:CategoryType) : ShopCategoryPane {
			var tPane:ShopCategoryPane = new ShopCategoryPane(pType);
			tPane.on(ShopCategoryPane.ITEM_SELECTED, _onItemSelected);
			tPane.on(ShopCategoryPane.ITEM_REMOVED, _onItemRemoved);
			tPane.infobar.on(Infobar.COLOR_WHEEL_CLICKED, function(){ _colorButtonClicked(pType); });
			tPane.infobar.on(Infobar.ITEM_PREVIEW_CLICKED, function(){ _removeItem(pType); });
			tPane.infobar.on(Infobar.EYE_DROPPER_CLICKED, function(){ _eyeDropButtonClicked(pType); });
			tPane.infobar.on(GridManagementWidget.RANDOMIZE_CLICKED, function(){ _randomItemOfType(pType); });
			// tPane.infobar.on(GridManagementWidget.RANDOMIZE_LOCK_CLICKED, function(e:FewfEvent){
			// 	_character.setItemTypeLock(pType, e.data.locked);
			// 	_updateTabListLockByItemType(pType);
			// });
			return tPane;
		}
		private function getShopPane(pType:CategoryType) : ShopCategoryPane { return _panes.getShopPane(pType); }
		
		private function _updateTabListItemIndicator() {
			for each(var tType:CategoryType in CategoryType.ALL) {
				var tItemData:ItemData = _character.getItemData(tType);
				var tHasIndicator:Boolean = !!tItemData && tItemData.type === tType;//!!tItemData && !tItemData.matches(GameAssets.defaultSkin) && !tItemData.matches(GameAssets.defaultPose);
				if(_shopTabs.getTabButton(PaneManager_World.categoryTypeToId(tType))) _shopTabs.getTabButton(PaneManager_World.categoryTypeToId(tType)).setItemIndicator(tHasIndicator);
			}
		}

		private function _onMouseWheel(pEvent:MouseEvent) : void {
			if(this.mouseX < this._shopTabs.x) {
				_toolbox.scaleSlider.updateViaMouseWheelDelta(pEvent.delta);
				_character.scale = _toolbox.scaleSlider.value;
				_character.clampCoordsToDragBounds();
			}
		}

		private function _onKeyDownListener(e:KeyboardEvent) : void {
			if (e.keyCode == Keyboard.RIGHT || e.keyCode == Keyboard.LEFT || e.keyCode == Keyboard.UP || e.keyCode == Keyboard.DOWN){
				var pane:SidePane = _panes.getOpenPane();
				if(pane && pane is ButtonGridSidePane) {
					(pane as ButtonGridSidePane).handleKeyboardDirectionalInput(e.keyCode);
				}
				else if(pane && pane is ColorPickerTabPane) {
					if (e.keyCode == Keyboard.UP || e.keyCode == Keyboard.DOWN) {
						(pane as ColorPickerTabPane).nextSwatch(e.keyCode == Keyboard.DOWN);
					}
				}
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

		private function _onScaleSliderChange(e:Event):void {
			_character.scale = _toolbox.scaleSlider.value;
			_character.clampCoordsToDragBounds();
		}

		private function _onScaleSliderDefaultClicked(e:Event):void {
			_character.scale = _toolbox.scaleSlider.value = ConstantsApp.DEFAULT_CHARACTER_SCALE;
			_character.clampCoordsToDragBounds();
		}

		private function _onPlayerAnimationToggle(pEvent:Event):void {
			_character.nextFrameChildren();
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
			_saveAsPNG(_character.outfit, "decoration", _character.scale);
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

		private function _onClipboardButtonClicked(e:Event) : void {
			try {
				// if(ConstantsApp.ANIMATION_DOWNLOAD_ENABLED && isCharacterAnimating()) {
				// 	FewfDisplayUtils.copyToClipboardAnimatedGif(new Pose().applyOutfitData(character.outfitData).poseMC, 1, function(){
				// 		_toolbox.updateClipboardButton(false, false);
				// 	})
				// } else {
					FewfDisplayUtils.copyToClipboard(_character.outfit, _getHardcodedSaveScale() || _character.outfit.scaleX);
					_toolbox.updateClipboardButton(false, true);
				// }
			} catch(e) {
				_toolbox.updateClipboardButton(false, false);
			}
			setTimeout(function(){ _toolbox.updateClipboardButton(true); }, 750);
		}
	//#endregion Saving

	//#region Item Change Logic
		private function _deselectAllButtonsExceptForType(pType:CategoryType) : void {
			var tButtons:Vector.<PushButton> = null;
			for(var j:int = 0; j < CategoryType.ALL.length; j++) {
				if(CategoryType.ALL[j] == pType) { continue; }
				tButtons = getShopPane(CategoryType.ALL[j]).buttons;
				for(var i:int = 0; i < tButtons.length; i++) {
					if (tButtons[i].pushed)  { tButtons[i].toggleOff(); }
				}
				getShopPane(CategoryType.ALL[j]).infobar.removeInfo();
			}
			tButtons = null;
		}
	
		private function _onItemSelected(e:ItemDataEvent) : void {
			var tItemData:ItemData = e.itemData;
			
			// Deselect buttons on other tabs - unlike other apps selecting an item on any pane should deselect all others
			_deselectAllButtonsExceptForType(tItemData.type)

			var tPane:ShopCategoryPane = getShopPane(tItemData.type);
			tPane.updateInfobarWithItemData(tItemData);
			_character.setItemData(tItemData);
			_updateTabListItemIndicator();
		}
		private function _onItemRemoved(e:ItemDataEvent) : void {
			var tItemData:ItemData = e.itemData;
			_removeItem(tItemData.type);
			_updateTabListItemIndicator();
		}

		private function _removeItem(pType:CategoryType) : void {
			var tPane:ShopCategoryPane = getShopPane(pType);
			if(!tPane || tPane.infobar.hasData == false) { return; }

			// If item has a default value, toggle it on. otherwise remove item.
			/*if(pType == ITEM.SKIN || pType == ITEM.POSE) {*/
				var tDefaultIndex = 0;//(pType == ITEM.POSE ? GameAssets.defaultPoseIndex : GameAssets.defaultSkinIndex);
				tPane.buttons[tDefaultIndex].toggleOn();
			/*} else {
				var tOldData:ItemData = _character.getItemData(pType);
				_character.removeItem(pType);
				tPane.infobar.removeInfo();
				if(tOldData) tPane.setToggleStateGridButtonWithData(tOldData, false);
			}*/
			_updateTabListItemIndicator();
		}
		
		private function _onTabClicked(pEvent:FewfEvent) : void {
			_panes.openPane(pEvent.data.toString());
		}

		private function _onRandomizeDesignClicked(pEvent:Event) : void {
			var tType:CategoryType = CategoryType.ALL[ Math.floor(Math.random() * CategoryType.ALL.length) ];
			_randomItemOfType(tType);
			_deselectAllButtonsExceptForType(tType);
		}

		private function _randomItemOfType(pType:CategoryType) : void {
			var pane:ShopCategoryPane = getShopPane(pType);
			if(!pane.buttons.length) { return; }
			pane.chooseRandomItem();
		}
	//#endregion Item Change Logic
		
	//#region Screen Logic
		private function _onLangButtonClicked(e:Event) : void { _langScreen.appendTo(this).open(); }
		private function _onLangScreenClosed(e:Event) : void { _langScreen.removeSelf(); }

		private function _onAboutButtonClicked(e:Event) : void { _aboutScreen.appendTo(this).open(); }
		private function _onAboutScreenClosed(e:Event) : void { _aboutScreen.removeSelf(); }
	//#endregion Screen Logic

	//#region Color Tab
		private function _onColorPickChanged(pEvent:FewfEvent):void {
			var color:uint = uint(pEvent.data.color);
			var pane = _panes.colorPickerPane;
			if(pEvent.data.randomizedAll) {
				_character.getItemData(this.currentlyColoringType).colors = pane.getAllColors();
			} else {
				_character.getItemData(this.currentlyColoringType).colors[pane.selectedSwatch] = color;
			}
			_refreshSelectedItemColor(this.currentlyColoringType);
		}
		
		private function _refreshSelectedItemColor(pType:CategoryType) : void {
			_character.updateItem();
			
			var tPane:ShopCategoryPane = getShopPane(pType);
			var tItemData = _character.getItemData(pType);
			if(!tItemData) { return; }
			
			_refreshButtonCustomizationForItemData(tItemData);
			tPane.infobar.refreshItemImageUsingCurrentItemData();
			_panes.colorPickerPane.infobar.refreshItemImageUsingCurrentItemData();
		}
		
		private function _refreshButtonCustomizationForItemData(pItemData:ItemData) : void {
			if(!pItemData) { return; }
			var tPane:ShopCategoryPane = getShopPane(pItemData.type);
			if(!tPane) { return; }
			tPane.refreshButtonImage(pItemData);
		}

		private function _colorButtonClicked(pType:CategoryType) : void {
			if(_character.getItemData(this.currentlyColoringType) == null) { return; }

			var tData:ItemData = getShopPane(pType).infobar.itemData;
			_panes.colorPickerPane.infobar.addInfo( tData, GameAssets.getItemImage(tData) );
			this.currentlyColoringType = pType;
			_panes.colorPickerPane.init( tData.uniqId(), tData.colors, tData.defaultColors );
			_panes.openPane(PaneManager_World.COLOR_PANE);
		}

		private function _onColorPickerBackClicked(pEvent:Event):void {
			_panes.openShopPane(_panes.colorPickerPane.infobar.itemData.type);
		}

		private function _eyeDropButtonClicked(pType:CategoryType) : void {
			if(_character.getItemData(pType) == null) { return; }

			var tData:ItemData = getShopPane(pType).infobar.itemData;
			var tItem:MovieClip = GameAssets.getColoredItemImage(tData);
			var tItem2:MovieClip = GameAssets.getColoredItemImage(tData);
			_panes.colorFinderPane.infobar.addInfo( tData, tItem );
			this.currentlyColoringType = pType;
			_panes.colorFinderPane.setItem(tItem2);
			_panes.openPane(PaneManager_World.COLOR_FINDER_PANE);
		}

		private function _onColorFinderBackClicked(pEvent:Event):void {
			_panes.openShopPane(_panes.colorFinderPane.infobar.itemData.type);
		}
	//#endregion Color Tab
	}
}

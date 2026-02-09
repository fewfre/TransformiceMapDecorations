package app.ui.panes
{	
	import app.data.CategoryType;
	import app.data.GameAssets;
	import app.ui.buttons.PushButton;
	import app.ui.panes.base.ButtonGridSidePane;
	import app.ui.panes.infobar.Infobar;
	import app.world.data.ItemData;
	import app.world.events.ItemDataEvent;

	import com.fewfre.events.FewfEvent;
	import com.fewfre.utils.FewfUtils;

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;

	public class ShopCategoryPane extends ButtonGridSidePane
	{
		private var _type: CategoryType;
		private var _itemDataVector: Vector.<ItemData>;
		private var _defaultItemData: ItemData;
		
		public function get type():CategoryType { return _type; }
		public function get defaultItemData():ItemData { return _defaultItemData; }
		public function get isItemTypeLocked():Boolean { return _infobar.isRefreshLocked; }
		
		public static const ITEM_SELECTED : String = 'ITEM_SELECTED'; // ItemDataEvent
		public static const ITEM_REMOVED : String = 'ITEM_REMOVED'; // ItemDataEvent
		
		// Constructor
		public function ShopCategoryPane(pType:CategoryType) {
			this._type = pType;
			var buttonPerRow:int = 5;
			super(buttonPerRow);
			
			this.addInfobar( new Infobar({ showEyeDropper:true, showDownload:true, gridManagement:{ hideRandomizeLock:true } }) );
			_setupGrid(GameAssets.getItemDataListByType(_type));
		}
		
		/****************************
		* Public
		*****************************/
		public override function open() : void {
			super.open();
		}
		
		public function setToggleStateGridButtonWithData(pData:ItemData, pOn:Boolean, pScrollIntoView:Boolean=false, pFireEvent:Boolean=true) : PushButton {
			var cell:DisplayObject = _getCellWithItemData(pData);
			if(cell) {
				var btn:PushButton = _findPushButtonInCell(cell);
				btn.toggle(pOn, pFireEvent);
				try {
					if(pOn && pScrollIntoView) scrollItemIntoView(cell);
				} catch(e){}
				return btn;
			}
			return null;
		}
		
		public function toggleGridButtonWithData(pData:ItemData, pScrollIntoView:Boolean=false) : PushButton {
			return setToggleStateGridButtonWithData(pData, true, pScrollIntoView)
		}
		
		// public function updateAllButtonsToItemData(pData:ItemData, pScrollIntoView:Boolean=false) : void {
		// 	if(!pData) _untoggleAllCells();
		// 	setToggleStateGridButtonWithData(pData, true, pScrollIntoView, false);
		// }
		
		public function scrollItemDataIntoView(itemData:ItemData) : void {
			if(flagOpen) scrollItemIntoView(_getCellWithItemData(itemData));
		}
		
		public function chooseRandomItem() : void {
			var tLength = grid.cells.length;
			var cell:DisplayObject = grid.cells[ Math.floor(Math.random() * tLength) ];
			var btn:PushButton = _findPushButtonInCell(cell);
			btn.toggleOn();
			if(_flagOpen) scrollItemIntoView(cell);
		}
		
		public function filterItemIds(pIds:Vector.<String>) : void {
			var list:Vector.<ItemData> = GameAssets.getItemDataListByType(_type);
			if(pIds) { list = list.filter(function(data:ItemData, i, a){ return pIds.indexOf(data.id) >= 0 }) }
			_setupGrid(list);
		}
		
		// Update image when colors have been changed
		public function refreshButtonImage(pItemData:ItemData) : void {
			if(!pItemData || !pItemData.isCustomizable) { return; }
			
			var btn:PushButton = _getButtonWithItemData(pItemData);
			if(!btn) return;
			btn.setImage(GameAssets.getColoredItemImage(pItemData));
		}
		
		public function updateInfobarWithItemData(itemData:ItemData, filterEnabled:Boolean=false) : void {
			if(!itemData) {
				this.infobar.removeInfo();
				return;
			}
			
			var showColorWheel : Boolean = itemData.isCustomizable;
			this.infobar.addInfo( itemData, GameAssets.getColoredItemImage(itemData) );
			this.infobar.showColorWheel(showColorWheel);
		}
		
		/****************************
		* Private
		*****************************/
		protected function _getCellWithItemData(itemData:ItemData) : DisplayObject {
			return !itemData ? null : FewfUtils.vectorFind(grid.cells, function(c:DisplayObject){ return itemData.matches(_findPushButtonInCell(c).data.itemData) });
		}
		
		protected function _getButtonWithItemData(itemData:ItemData) : PushButton {
			return _findPushButtonInCell(_getCellWithItemData(itemData));
		}
		
		private function _setupGrid(pItemList:Vector.<ItemData>) : void {
			_itemDataVector = pItemList;

			resetGrid();

			for(var i:int = 0; i < pItemList.length; i++) {
				_addButton(pItemList[i], 1, i);
			}
			
			refreshScrollbox();
		}
		
		private function _addButton(itemData:ItemData, pScale:Number, i:int) : void {
			var shopItem : MovieClip = GameAssets.getColoredItemImage(itemData);
			shopItem.scaleX = shopItem.scaleY = pScale;
			var cell:Sprite = new Sprite();

			var shopItemButton:PushButton = new PushButton(grid.cellSize).setImage(shopItem).setData({ type:_type, itemID:itemData.id, itemData:itemData }).appendTo(cell) as PushButton;
			
			// Finally add to grid (do it at end so auto event handlers can be hooked up properly)
			addToGrid(cell);
		}
		
		/****************************
		* Events
		*****************************/
		protected override function _onCellPushButtonToggled(e:FewfEvent) : void {
			super._onCellPushButtonToggled(e);
			_dispatchItemDataEvent(e.data.itemData, (e.currentTarget as PushButton).pushed);
		}
		
		private function _dispatchItemDataEvent(itemData:ItemData, selected:Boolean=true) : void {
			dispatchEvent(new ItemDataEvent(selected ? ITEM_SELECTED : ITEM_REMOVED, itemData));
		}
	}
}

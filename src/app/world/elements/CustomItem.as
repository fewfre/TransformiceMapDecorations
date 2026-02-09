package app.world.elements
{

	import app.data.*;
	import app.world.data.ItemData;
	import com.fewfre.utils.Fewf;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.*;

	public class CustomItem
	{
		// Storage
		private var _root       : Sprite;
		private var _itemData   : ItemData;
		private var _outfit     : MovieClip;
		
		private var _dragging   : Boolean = false;
		private var _dragBounds : Rectangle;

		// Properties
		public function get root() : Sprite { return _root; }
		public function get outfit() : MovieClip { return _outfit; }
		public function get scale() : Number { return _outfit.scaleX; }
		public function set scale(pVal:Number) : void { _outfit.scaleX = _outfit.scaleY = pVal; }

		// Constructor
		public function CustomItem(pItemData:ItemData, paramsString:String=null) {
			_root = new Sprite();
			_itemData = pItemData;
			
			/*if(paramsString) _parseParams(paramsString);*/

			updateItem();
			
			// Make interactable
			_initDragging();
		}
		public function move(pX:Number, pY:Number) : CustomItem { _root.x = pX; _root.y = pY; return this; }
		public function appendTo(pParent:Sprite): CustomItem { pParent.addChild(_root); return this; }
		public function on(type:String, listener:Function, useCapture:Boolean = false): CustomItem { _root.addEventListener(type, listener, useCapture); return this; }
		public function off(type:String, listener:Function, useCapture:Boolean = false): CustomItem { _root.removeEventListener(type, listener, useCapture); return this; }

		public function updateItem() {
			var tScale = ConstantsApp.DEFAULT_CHARACTER_SCALE;
			if(_outfit != null) { tScale = _outfit.scaleX; _root.removeChild(_outfit); }
			_outfit = _root.addChild(new (_itemData.itemClass)()) as MovieClip;
			_outfit.scaleX = _outfit.scaleY = tScale;
			
			/*var tChild:DisplayObject = null;
			for(var i:int = 0; i < outfit.numChildren; i++) {
				tChild = outfit.getChildAt(i);
				if(_itemData.colors != null) {
					GameAssets.colorItemUsingColorList(outfit, _itemData.colors);
				}
				else { GameAssets.colorDefault(tChild); }
			}
			tChild = null;*/
			
			if(_itemData.colors != null) {
				GameAssets.colorItemUsingColorList(_outfit, _itemData.colors);
			}
			else { GameAssets.colorDefault(_outfit); }
			
			stopChildren();
			
			// if(animatePose) outfit.play(); else outfit.stopAtLastFrame();
		}

		private function _parseParams(pParams:String) : void {
			/*trace(pParams.toString());

			_setParamToType(pParams, ITEM.SKIN, "s", false);*/
		}
		private function _setParamToType(pParams:String, pType:String, pParam:String, pAllowNull:Boolean=true) {
			/*var tData:ItemData = null;
			if(pParams[pParam] != null) {
				if(pParams[pParam] == '') {
					tData = null;
				} else {
					tData = GameAssets.getItemFromTypeID(pType, pParams[pParam]);
				}
			}
			_itemDataMap[pType] = pAllowNull ? tData : ( tData == null ? _itemDataMap[pType] : tData );*/
		}

		public function getParams() : String {
			/*var tParms = new URLVariables();

			var tData:ItemData;
			tParms.s = (tData = getItemData(ITEM.SKIN)) ? tData.id : '';

			return tParms;*/
			return null;
		}
		
		public function stopChildren() : void {
			applyToAllChildren(function(pChild){
				pChild.stop();
			});
		}
		
		public function nextFrameChildren() : void {
			applyToAllChildren(function(pChild){
				pChild.nextFrame();
			});
		}
		
		public function goToFrameChildren(pFrame:int) : void {
			applyToAllChildren(function(pChild){
				pChild.gotoAndStop(pFrame);
			});
		}
		
		public function applyToAllChildren(pCallback:Function) : void {
			var tChild:MovieClip = null;
			for(var i:int = _outfit.numChildren-1; i >= 0; i--) {
				tChild = _outfit.getChildAt(i) as MovieClip;
				if(tChild) pCallback(tChild);
			}
		}

		/////////////////////////////
		// Dragging
		/////////////////////////////
		private function _initDragging() : void {
			_root.buttonMode = true;
			_root.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) {
				_dragging = true;
				var bounds:Rectangle = _dragBounds.clone();
				bounds.x -= e.localX * _root.scaleX;
				bounds.y -= e.localY * _root.scaleY;
				_root.startDrag(false, bounds);
			});
			Fewf.stage.addEventListener(MouseEvent.MOUSE_UP, function () { if(_dragging) { _dragging = false; _root.stopDrag(); } });
		}
		public function setDragBounds(pX:Number, pY:Number, pWidth:Number, pHeight:Number): CustomItem {
			_dragBounds = new Rectangle(pX, pY, pWidth, pHeight); return this;
		}
		public function clampCoordsToDragBounds() : void {
			_root.x = Math.max(_dragBounds.x, Math.min(_dragBounds.right, _root.x));
			_root.y = Math.max(_dragBounds.y, Math.min(_dragBounds.bottom, _root.y));
		}

		/////////////////////////////
		// Update Data
		/////////////////////////////
		public function getItemData(pType:CategoryType) : ItemData {
			return _itemData;
		}

		public function setItemData(pItem:ItemData) : void {
			_itemData = pItem;
			updateItem();
		}

		public function removeItem(pType:CategoryType) : void {
			_itemData = null;
			updateItem();
		}
	}
}

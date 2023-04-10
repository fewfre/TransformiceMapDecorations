package app.data
{
	import com.adobe.images.*;
	import com.fewfre.utils.*;
	import com.piterwilson.utils.ColorMathUtil;
	import app.data.*;
	import app.world.data.*;
	import app.world.elements.*;
	import flash.display.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.utils.Dictionary;

	public class GameAssets
	{
		private static const _MAX_COSTUMES_TO_CHECK_TO:Number = 10240; // all are numbered in a row, so fine to have this large
		
		public static var all_decorations: Vector.<ItemData>;
		public static var decorationDataMap: Dictionary;
		
		private static var decIDtoCategoryTypeMap: Dictionary;

		public static function init() : void {
			_setupIdToCatMap();
			
			all_decorations = new Vector.<ItemData>();
			decorationDataMap = new Dictionary();
			for each(var tType:CategoryType in CategoryType.ALL) {
				decorationDataMap[tType] = new Vector.<ItemData>();
			}
			_setupDecorationLists();
		}

		// pData = { base:String, type:String, after:String, pad:int }
		private static function _setupDecorationLists() {
			var tClass:Class, tData:ItemData, type:CategoryType;
			var breakCount = 0; // quit early if enough nulls in a row
			for(var i = 0; i <= _MAX_COSTUMES_TO_CHECK_TO; i++) {
				tClass = Fewf.assets.getLoadedClass( "$P_"+i );
				if(tClass != null) {
					breakCount = 0;
					
					type = getCategoryTypeFromDecId(i);
					tData = new ItemData(type, i, { itemClass:tClass });
					all_decorations.push(tData);
					decorationDataMap[type].push(tData);
				} else {
					breakCount++;
					if(breakCount > 5) {
						break;
					}
				}
			}
		}

		public static function zeroPad(number:int, width:int):String {
			var ret:String = ""+number;
			while( ret.length < width )
				ret="0" + ret;
			return ret;
		}

		private static function _setupIdToCatMap():void {
			decIDtoCategoryTypeMap = new Dictionary();
			// Taken from game code
            _catmap_loopBetweenAndSet(0,13,CategoryType.Transformice);
            _catmap_loopBetweenAndSet(14,34,CategoryType.House);
            _catmap_loopBetweenAndSet(35,49,CategoryType.Autumn);
            _catmap_loopBetweenAndSet(50,64,CategoryType.Winter);
            _catmap_loopBetweenAndSet(65,77,CategoryType.Valentines);
            _catmap_loopBetweenAndSet(78,88,CategoryType.Sea);
            _catmap_loopBetweenAndSet(91,118,CategoryType.Autumn);
            _catmap_loopBetweenAndSet(119,132,CategoryType.House);
            _catmap_loopBetweenAndSet(133,137,CategoryType.Autumn);
            _catmap_loopBetweenAndSet(138,147,CategoryType.Winter);
            _catmap_loopBetweenAndSet(154,157,CategoryType.Transformice);
            _catmap_loopBetweenAndSet(158,179,CategoryType.Autumn);
            _catmap_loopBetweenAndSet(197,210,CategoryType.Winter);
            _catmap_loopBetweenAndSet(239,256,CategoryType.Transformice);
            _catmap_loopBetweenAndSet(257,264,CategoryType.Winter);
            _catmap_loopBetweenAndSet(265,271,CategoryType.Spring);
            _catmap_manualSet(CategoryType.Transformice,148,149,181,183,186,193,195,211,267,268,269,272,273,274,275);
            _catmap_manualSet(CategoryType.House,185,189,190);
            _catmap_manualSet(CategoryType.Winter,182,184,186,191,192,194,196,212);
            _catmap_manualSet(CategoryType.Spring,219,220,221,222,227,228,229,230,231);
            _catmap_manualSet(CategoryType.Valentines,217,218,223,224,225,226,282);
		}
      
      private static function getCategoryTypeFromDecId(param1:int) : CategoryType {
		return !!decIDtoCategoryTypeMap[param1] ? decIDtoCategoryTypeMap[param1] : CategoryType.Various;
      }
      
      private static function _catmap_loopBetweenAndSet(start:int, length:int, value:CategoryType) : void {
		for(var i:int = start; i <= length; i++){ decIDtoCategoryTypeMap[i] = value; }
      }
      
      private static function _catmap_manualSet(value:CategoryType, ... rest) : void {
		for(var i:int = 0; i < rest.length; i++){
            decIDtoCategoryTypeMap[rest[i]] = value;
		}
      }
		
		/****************************
		* Access Data
		*****************************/
		public static function getItemDataListByType(pType:CategoryType) : Vector.<ItemData> {
			if(decorationDataMap[pType]) { return decorationDataMap[pType]; }
			trace("[GameAssets](getItemDataListByType) Unknown type: "+pType);
			return null;
		}

		public static function getItemFromTypeID(pType:CategoryType, pID:String) : ItemData {
			return FewfUtils.getFromVectorWithKeyVal(getItemDataListByType(pType), "id", pID);
		}

		/****************************
		* Color - GET
		*****************************/
		public static function findDefaultColors(pMC:MovieClip) : Vector.<uint> {
			return Vector.<uint>( _findDefaultColorsRecursive(pMC, []) );
		}
		private static function _findDefaultColorsRecursive(pMC:MovieClip, pList:Array) : Array {
			if (!pMC) { return pList; }

			var child:DisplayObject=null, name:String=null, colorI:int = 0;
			var i:*=0;
			while (i < pMC.numChildren)
			{
				child = pMC.getChildAt(i);
				name = child.name;
				
				if(name) {
					if (name.indexOf("Couleur") == 0 && name.length > 7) {
						// hardcoded fix for tfm eye:31, which has a color of: Couleur_08C7474 (0 and _ are swapped)
						if(name.charAt(7) == '_') {
							colorI = int(name.charAt(8));
							pList[colorI] = int("0x" + name.substr(name.indexOf("_") + 2, 6));
						} else {
							colorI = int(name.charAt(7));
							pList[colorI] = int("0x" + name.substr(name.indexOf("_") + 1, 6));
						}
					}
					else if(name.indexOf("slot_") == 0) {
						_findDefaultColorsRecursive(child as MovieClip, pList);
					}
					i++;
				}
			}
			return pList;
		}
		
		
		public static function getColors(pMC:MovieClip) : Array {
			var tChild:*=null;
			var tTransform:*=null;
			var tArray:Array=new Array();

			var i:int=0;
			while (i < pMC.numChildren) {
				tChild = pMC.getChildAt(i);
				if (tChild.name.indexOf("Couleur") == 0 && tChild.name.length > 7) {
					tTransform = tChild.transform.colorTransform;
					tArray[tChild.name.charAt(7)] = ColorMathUtil.RGBToHex(tTransform.redMultiplier * 128, tTransform.greenMultiplier * 128, tTransform.blueMultiplier * 128);
				}
				i++;
			}
			return tArray;
		}

		public static function getNumOfCustomColors(pMC:MovieClip) : int {
			// Use recursive one since the array it returns is a bit more safe for this than the vector
			return _findDefaultColorsRecursive(pMC, []).length;
		}

		/****************************
		* Color - APPLY
		*****************************/
		public static function copyColor(copyFromMC:MovieClip, copyToMC:MovieClip) : MovieClip {
			if (copyFromMC == null || copyToMC == null) { return null; }
			var tChild1:*=null;
			var tChild2:*=null;
			var i:int = 0;
			while (i < copyFromMC.numChildren) {
				tChild1 = copyFromMC.getChildAt(i);
				tChild2 = copyToMC.getChildAt(i);
				if (tChild1.name.indexOf("Couleur") == 0 && tChild1.name.length > 7) {
					tChild2.transform.colorTransform = tChild1.transform.colorTransform;
				}
				i++;
			}
			return copyToMC;
		}
		
		// pColor is an int hex value. ex: 0x000000
		public static function applyColorToObject(pItem:DisplayObject, pColor:int) : void {
			if(pColor < 0) { return; }
			var tR:*=pColor >> 16 & 255;
			var tG:*=pColor >> 8 & 255;
			var tB:*=pColor & 255;
			pItem.transform.colorTransform = new flash.geom.ColorTransform(tR / 128, tG / 128, tB / 128);
		}

		public static function colorItemUsingColorList(pSprite:Sprite, pColors:Vector.<uint>) : DisplayObject {
			if (pSprite == null) { return null; }

			var tChild: DisplayObject, name:String;
			var i:int=0;
			while (i < pSprite.numChildren) {
				tChild = pSprite.getChildAt(i); name = tChild.name;
				
				if (name.indexOf("Couleur") == 0 && name.length > 7) {
					var colorI:int = int(name.charAt(7));
					// fallback encase colorI is outside of the list
					var color:uint = colorI < pColors.length ? pColors[colorI] : int("0x" + name.split("_")[1]);
					applyColorToObject(tChild, color);
				}
				i++;
			}
			return pSprite;
		}

		public static function colorDefault(pMC:MovieClip) : MovieClip {
			var colors:Vector.<uint> = findDefaultColors(pMC);
			colorItemUsingColorList(pMC, colors);
			return pMC;
		}

		/****************************
		* Asset Creation
		*****************************/
		public static function getItemImage(pData:ItemData) : MovieClip {
			var tItem:MovieClip = new pData.itemClass();
			colorDefault(tItem);
			return tItem;
		}
		
		public static function getColoredItemImage(pData:ItemData) : MovieClip {
			return colorItemUsingColorList(getItemImage(pData), pData.colors) as MovieClip;
		}
		
		/****************************
		* Misc
		*****************************/
		public static function createHorizontalRule(pX:Number, pY:Number, pWidth:Number) : Sprite {
			var tLine:Sprite = new Sprite(); tLine.x = pX; tLine.y = pY;
			
			tLine.graphics.lineStyle(1, 0x11181c, 1, true);
			tLine.graphics.moveTo(0, 0);
			tLine.graphics.lineTo(pWidth, 0);
			
			tLine.graphics.lineStyle(1, 0x608599, 1, true);
			tLine.graphics.moveTo(0, 1);
			tLine.graphics.lineTo(pWidth, 1);
			
			return tLine;
		}
	}
}

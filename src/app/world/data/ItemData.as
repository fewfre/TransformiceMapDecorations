package app.world.data
{
	import app.data.*;
	import flash.display.*;
	import flash.geom.*;

	public class ItemData
	{
		public var type			: CategoryType;
		public var id			: String;
		public var itemClass	: Class;
		public var classMap		: Object;

		public var defaultColors: Array;
		public var colors		: Array;

		// pData = { itemClass:Class, ?classMap:Object<Class> }
		public function ItemData(pType:CategoryType, pId:String, pData:Object) {
			super();
			type = pType;
			id = pId;
			itemClass = pData.itemClass;
			classMap = pData.classMap;
			_initDefaultColors();
		}
		protected function _initDefaultColors() : void {
			defaultColors = GameAssets.getColors(GameAssets.colorDefault(new itemClass()));
			setColorsToDefault();
		}
		public function setColorsToDefault() : void {
			colors = defaultColors.concat();
		}

		public function getPart(pID:String, pOptions:Object=null) : Class {
			return !classMap ? null : (classMap[pID] ? classMap[pID] : null);
		}
	}
}

package app.ui.panes
{
	import app.data.CategoryType;
	import app.ui.panes.*;
	import app.ui.panes.base.*;
	import app.ui.panes.colorpicker.ColorPickerTabPane;

	public class PaneManager_World extends PaneManager
	{
		// Pane IDs
		public static const COLOR_PANE:String = "colorPane";
		public static const COLOR_FINDER_PANE:String = "colorFinderPane";
		
		// Constructor
		public function PaneManager_World() {
			super();
		}
		
		// ShopCategoryPane methods
		public function openShopPane(pType:CategoryType) : ShopCategoryPane { return openPane(categoryTypeToId(pType)) as ShopCategoryPane; }
		public function getShopPane(pType:CategoryType) : ShopCategoryPane { return getPane(categoryTypeToId(pType)) as ShopCategoryPane; }
		
		// Shortcuts to get panes with correct typing
		public function get colorPickerPane() : ColorPickerTabPane { return getPane(COLOR_PANE) as ColorPickerTabPane; }
		public function get colorFinderPane() : ColorFinderPane { return getPane(COLOR_FINDER_PANE) as ColorFinderPane; }
		
		/////////////////////////////
		// Static
		/////////////////////////////
		public static function categoryTypeToId(pType:CategoryType) : String { return pType.toString(); }
	}
}

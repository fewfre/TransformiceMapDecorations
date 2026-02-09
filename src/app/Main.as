package app
{
	import app.ui.screens.LoaderDisplay;
	import app.world.World;
	import com.fewfre.utils.*;
	import flash.display.*;
	import flash.events.*;
	import app.data.ConstantsApp;

	[SWF(backgroundColor="0x6A7495" , width="900" , height="425")]
	public class Main extends MovieClip
	{
		// Storage
		private var _loaderDisplay : LoaderDisplay;
		private var _world         : World;
		private var _config        : Object;
		private var _systemDetectedDefaultLang : String;
		
		// Constructor
		public function Main() {
			super();
			
			if (stage) {
				this._start();
			} else {
				addEventListener(Event.ADDED_TO_STAGE, this._start);
			}
		}
		
		private function _start(...args:*) {
			Fewf.init(stage, this.loaderInfo.parameters.swfUrlBase, 'fewfre-transformice-map-decorations');

			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = 16;

			BrowserMouseWheelPrevention.init(stage);

			_loaderDisplay = new LoaderDisplay(ConstantsApp.CENTER_X, ConstantsApp.CENTER_Y).appendTo(this);
			
			_startPreload();
		}
		
		private function _startPreload() : void {
			_load([
				Fewf.swfUrlBase+"resources/config.json",
			], String( new Date().getTime() ), _onPreloadComplete);
		}
		
		private function _onPreloadComplete() : void {
			_config = Fewf.config;
			_systemDetectedDefaultLang = Fewf.i18n.getSystemDetectedDefaultLangCodeOrFallback();
			
			if(Fewf.config.upload2imgur_url) Fewf.config.upload2imgur_url.replace("https://", Fewf.networkProtocol+"://");
			
			_startInitialLoad();
		}
		
		private function _startInitialLoad() : void {
			var tLangCodes : Array = [ Fewf.i18n.getConfigDefaultLangCode() ];
			if(tLangCodes.indexOf(_systemDetectedDefaultLang) == -1) tLangCodes.push(_systemDetectedDefaultLang);
			Fewf.i18n.loadLanguagesIfNeededAndUseLastLang(tLangCodes, _onInitialLoadComplete);
		}
		
		private function _onInitialLoadComplete() : void {
			_startLoad();
		}
		
		// Start main load
		private function _startLoad() : void {
			var tPacks = [
				[Fewf.swfUrlBase+"resources/interface.swf", { useCurrentDomain:true }],
				Fewf.swfUrlBase+"resources/flags.swf"
			];
			
			var tPack = _config.packs.items;
			for(var i:int = 0; i < tPack.length; i++) { tPacks.push(Fewf.swfUrlBase+"resources/"+tPack[i]); }
			
			_load(tPacks, Fewf.config.cachebreaker, _onLoadComplete);
		}
		
		private function _onLoadComplete() : void {
			_loaderDisplay.removeSelf().destroy();
			_loaderDisplay = null;
			
			_world = addChild(new World(stage)) as World;
		}
		
		/***************************
		* Helper Methods
		****************************/
		private function _load(pPacks:Array, pCacheBreaker:String, pCallback:Function) : void {
			Fewf.assets.load(pPacks, pCacheBreaker);
			var tFunc = function(event:Event){
				Fewf.assets.removeEventListener(AssetManager.LOADING_FINISHED, tFunc);
				pCallback();
				tFunc = null; pCallback = null;
			};
			Fewf.assets.addEventListener(AssetManager.LOADING_FINISHED, tFunc);
		}
	}
}

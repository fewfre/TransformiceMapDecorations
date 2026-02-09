package app.ui
{
	import app.data.ConstantsApp;
	import app.ui.buttons.GameButton;
	import app.ui.common.FancySlider;
	import app.ui.common.FrameBase;
	import app.world.elements.CustomItem;
	import com.adobe.images.PNGEncoder;
	import com.fewfre.display.RoundRectangle;
	import com.fewfre.loaders.SimpleUrlLoader;
	import com.fewfre.utils.Fewf;
	import com.fewfre.utils.FewfDisplayUtils;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	public class Toolbox extends Sprite
	{
		// Constants
		public static const SAVE_CLICKED          = "save_clicked";
		public static const CLIPBOARD_CLICKED     = "clipboard_clicked";
		
		public static const SCALE_SLIDER_CHANGE   = "scale_slider_change";
		public static const DEFAULT_SCALE_CLICKED = "default_scale_clicked";
		
		public static const RANDOM_CLICKED        = "random_clicked";
		
		// Storage
		private var _character		: CustomItem;
		
		// private var _animateButton      : PushButton;
		private var _clipboardButton    : GameButton;
		private var _imgurButton        : GameButton;
		
		private var _scaleSlider        : FancySlider;
		private var _defaultScaleButton : GameButton;
		
		// Properties
		public function get scaleSlider() : FancySlider { return _scaleSlider; }
		
		// Constructor
		public function Toolbox(pCharacter:CustomItem) {
			_character = pCharacter;
			var bg:RoundRectangle = new RoundRectangle(365, 35).toOrigin(0.5).drawAsTray().appendTo(this);
			
			/********************
			* Download Button
			*********************/
			var tDownloadTray:FrameBase = new FrameBase(66, 66).move(-bg.width*0.5 + 33, 9).appendTo(this);
			/*_downloadTray.drawSimpleGradient(ConstantsApp.COLOR_TRAY_GRADIENT, 15, ConstantsApp.COLOR_TRAY_B_1, ConstantsApp.COLOR_TRAY_B_2, ConstantsApp.COLOR_TRAY_B_3);*/
			
			// Download Button
			new GameButton(46).setImage(new $LargeDownload()).setOrigin(0.5)
				.onButtonClick(dispatchEventHandler(SAVE_CLICKED))
				.appendTo(tDownloadTray.root);
			
			/********************
			* Toolbar Buttons
			*********************/
			var tTray:Sprite = bg.addChild(new Sprite()) as Sprite;
			var tTrayWidth = bg.width - tDownloadTray.width;
			tTray.x = -(bg.width*0.5) + (tTrayWidth*0.5) + (bg.width - tTrayWidth);
			
			var tButtonSize = 28, tButtonSizeSpace=5, tButtonXInc=tButtonSize+tButtonSizeSpace;
			var xx = 0, yy = 0, tButtonsOnLeft = 0, tButtonOnRight = 0;
			
			// ### Left Side Buttons ###
			xx = -tTrayWidth*0.5 + tButtonSize*0.5 + tButtonSizeSpace;
			
			if(!!_getImgurUploadUrl()) {
				_imgurButton = new GameButton(tButtonSize).setImage(new $ImgurIcon(), 0.45).setOrigin(0.5).appendTo(tTray)
					.move(xx+tButtonXInc*tButtonsOnLeft, yy)
					.onButtonClick(_onImgurButtonClicked) as GameButton;
				tButtonsOnLeft++;
			}
			
			// if(Fewf.isAirRuntime) {
				_clipboardButton = new GameButton(tButtonSize).setImage(new $CopyIcon(), 0.415).setOrigin(0.5).appendTo(tTray)
					.move(xx+tButtonXInc*tButtonsOnLeft, yy)
					.onButtonClick(dispatchEventHandler(CLIPBOARD_CLICKED)) as GameButton;
				tButtonsOnLeft++;
			// }
			
			// ### Right Side Buttons ###
			xx = tTrayWidth*0.5-(tButtonSize*0.5 + tButtonSizeSpace);

			// Dice icon based on https://www.iconexperience.com/i_collection/icons/?icon=dice
			new GameButton(tButtonSize).setImage(new $Dice()).setOrigin(0.5).appendTo(tTray)
				.move(xx-tButtonXInc*tButtonOnRight, yy)
				.onButtonClick(dispatchEventHandler(RANDOM_CLICKED));
			tButtonOnRight++;
			
			/********************
			* Scale slider
			*********************/
			var tTotalButtons = tButtonsOnLeft+tButtonOnRight;
			var tSliderWidth = tTrayWidth - tButtonXInc*(tTotalButtons) - 20;
			xx = -tSliderWidth*0.5+(tButtonXInc*((tButtonsOnLeft-tButtonOnRight)*0.5))-1;
			_scaleSlider = new FancySlider(tSliderWidth).move(xx, yy)
				.setSliderParams(1, 8, ConstantsApp.DEFAULT_CHARACTER_SCALE)
				.appendTo(tTray)
				.on(FancySlider.CHANGE, dispatchEventHandler(SCALE_SLIDER_CHANGE));
			
			(_defaultScaleButton = new GameButton(100, 14)).setText('btn_color_defaults').setOrigin(0.5).move(xx+tSliderWidth/2, yy-16.5).appendTo(tTray).setAlpha(0)
				.onButtonClick(dispatchEventHandler(DEFAULT_SCALE_CLICKED));
				
			scaleSlider.on(MouseEvent.MOUSE_OVER, function():void{ _defaultScaleButton.alpha = 0.8; });
			_defaultScaleButton.on(MouseEvent.MOUSE_OVER, function():void{ _defaultScaleButton.alpha = 0.8; });
			scaleSlider.on(MouseEvent.MOUSE_OUT, function():void{ _defaultScaleButton.alpha = 0; });
			_defaultScaleButton.on(MouseEvent.MOUSE_OUT, function():void{ _defaultScaleButton.alpha = 0; });
		}
		public function move(pX:Number, pY:Number) : Toolbox { x = pX; y = pY; return this; }
		public function appendTo(pParent:Sprite): Toolbox { pParent.addChild(this); return this; }
		public function on(type:String, listener:Function): Toolbox { this.addEventListener(type, listener); return this; }
		public function off(type:String, listener:Function): Toolbox { this.removeEventListener(type, listener); return this; }
		
		///////////////////////
		// Public
		///////////////////////
		
		// public function toggleAnimateButtonAsset(pOn:Boolean) : void {
		// 	_animateButton.ChangeImage(pOn ? new $PauseButton() : new $PlayButton());
		// }
		
		public function updateClipboardButton(normal:Boolean, elseYes:Boolean=true) : void {
			if(!_clipboardButton) return;
			if(normal) _clipboardButton.setImage(new $CopyIcon(), 0.415);
			else _clipboardButton.setImage(elseYes ? new $Yes() : new $No(), 0.63);
		}
		
		///////////////////////
		// Imgur
		///////////////////////
		private function _getImgurUploadUrl() : String { return Fewf.config.upload2imgur_url; }
		
		private function _onImgurButtonClicked(e:Event) : void {
			_imgurButton.disable();
			_uploadToImgur(_character.root, function(pResp, err:String=null):void{
				_imgurButton.enable();
			});
		}
		
		private function _uploadToImgur(img:Sprite, pCallback:Function) : void {
			var tPNG:ByteArray = PNGEncoder.encode(FewfDisplayUtils.displayObjectToBitmapData(img, img.scaleX));
			new SimpleUrlLoader(_getImgurUploadUrl()).setToPost().addFormDataHeader()
				.addData("base64", FewfDisplayUtils.encodeByteArrayAsString(tPNG))
				.onComplete(function(resp){ pCallback(resp); })
				.onError(function(err:Error){ pCallback(null, "["+err.name+":"+err.errorID+"] "+err.message); })
				.load();
		}
		
		///////////////////////
		// Private
		///////////////////////
		private function dispatchEventHandler(pEventName:String) : Function {
			return function(e):void{ dispatchEvent(new Event(pEventName)); };
		}
	}
}

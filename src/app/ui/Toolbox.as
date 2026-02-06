package app.ui
{
	import com.fewfre.display.ButtonBase;
	import com.fewfre.utils.Fewf;
	import app.data.*;
	import app.ui.*;
	import app.ui.buttons.*;
	import app.ui.common.*;
	import flash.display.*;
	import flash.net.*;
	import app.world.elements.CustomItem;
	import com.fewfre.utils.FewfDisplayUtils;
	import flash.utils.setTimeout;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import com.adobe.images.PNGEncoder;
	import com.fewfre.loaders.SimpleUrlLoader;
	
	public class Toolbox extends MovieClip
	{
		// Storage
		private var _downloadTray	: FrameBase;
		private var _bg				: RoundedRectangle;
		private var _character		: CustomItem;
		
		public var scaleSlider		: FancySlider;
		public var animateButton	: SpriteButton;
		public var imgurButton		: SpriteButton;
		
		// Constructor
		// pData = { x:Number, y:Number, character:Character, onSave:Function, onAnimate:Function, onRandomize:Function, onShare:Function, onScale:Function }
		public function Toolbox(pData:Object) {
			_character = pData.character;
			this.x = pData.x;
			this.y = pData.y;
			
			var btn:ButtonBase;
			
			_bg = addChild(new RoundedRectangle({ width:365, height:35, origin:0.5 })) as RoundedRectangle;
			_bg.drawSimpleGradient(ConstantsApp.COLOR_TRAY_GRADIENT, 15, ConstantsApp.COLOR_TRAY_B_1, ConstantsApp.COLOR_TRAY_B_2, ConstantsApp.COLOR_TRAY_B_3);
			
			/********************
			* Download Button
			*********************/
			_downloadTray = addChild(new FrameBase({ x:-_bg.Width*0.5 + 33, y:9, width:66, height:66, origin:0.5 })) as FrameBase;
			/*_downloadTray.drawSimpleGradient(ConstantsApp.COLOR_TRAY_GRADIENT, 15, ConstantsApp.COLOR_TRAY_B_1, ConstantsApp.COLOR_TRAY_B_2, ConstantsApp.COLOR_TRAY_B_3);*/
			
			btn = _downloadTray.addChild(new SpriteButton({ width:46, height:46, obj:new $LargeDownload(), origin:0.5 })) as SpriteButton;
			btn.addEventListener(ButtonBase.CLICK, pData.onSave);
			
			/********************
			* Toolbar Buttons
			*********************/
			var tTray = _bg.addChild(new MovieClip());
			var tTrayWidth = _bg.Width - _downloadTray.Width;
			tTray.x = -(_bg.Width*0.5) + (tTrayWidth*0.5) + (_bg.Width - tTrayWidth);
			
			var tButtonSize = 28, tButtonSizeSpace=5, tButtonXInc=tButtonSize+tButtonSizeSpace;
			var tX = 0, tY = 0, tButtonsOnLeft = 0, tButtonOnRight = 0;
			
			// ### Left Side Buttons ###
			tX = -tTrayWidth*0.5 + tButtonSize*0.5 + tButtonSizeSpace;
			
			/*btn = tTray.addChild(new SpriteButton({ x:tX+tButtonXInc*tButtonsOnLeft, y:tY, width:tButtonSize, height:tButtonSize, obj_scale:0.45, obj:new $Link(), origin:0.5 }));
			btn.addEventListener(ButtonBase.CLICK, pData.onShare);
			tButtonsOnLeft++;*/
			
			if(!!_getImgurUploadUrl()) {
				btn = imgurButton = tTray.addChild(new SpriteButton({ x:tX+tButtonXInc*tButtonsOnLeft, y:tY, width:tButtonSize, height:tButtonSize, obj_scale:0.45, obj:new $ImgurIcon(), origin:0.5 })) as SpriteButton;
				btn.onButtonClick(_onImgurButtonClicked);
				tButtonsOnLeft++;
			}
			
			if(Fewf.isExternallyLoaded){
				btn = imgurButton = tTray.addChild(new SpriteButton({ x:tX+tButtonXInc*tButtonsOnLeft, y:tY, width:tButtonSize, height:tButtonSize, obj_scale:0.415, obj:new $CopyIcon(), origin:0.5 })) as SpriteButton;
				btn.addEventListener(ButtonBase.CLICK, function(e:*){
					try {
						FewfDisplayUtils.copyToClipboard(_character);
						imgurButton.ChangeImage(new $Yes());
					} catch(e) {
						imgurButton.ChangeImage(new $No());
					}
					setTimeout(function(){ imgurButton.ChangeImage(new $CopyIcon()); }, 750)
				});
				tButtonsOnLeft++;
			}
			
			// ### Right Side Buttons ###
			tX = tTrayWidth*0.5-(tButtonSize*0.5 + tButtonSizeSpace);

			/*btn = tTray.addChild(new SpriteButton({ x:tX-tButtonXInc*tButtonOnRight, y:tY, width:tButtonSize, height:tButtonSize, obj_scale:0.5, obj:new $Refresh(), origin:0.5 }));
			btn.addEventListener(ButtonBase.CLICK, pData.onRandomize);
			tButtonOnRight++;*/
			
			// animateButton = tTray.addChild(new SpriteButton({ x:tX-tButtonXInc*tButtonOnRight, y:tY, width:tButtonSize, height:tButtonSize, obj_scale:0.5, obj:new MovieClip(), origin:0.5 }));
			// animateButton.addEventListener(ButtonBase.CLICK, pData.onAnimate);
			// toggleAnimateButtonAsset(pData.character.animatePose);
			// tButtonOnRight++;
			
			/********************
			* Scale slider
			*********************/
			var tTotalButtons = tButtonsOnLeft+tButtonOnRight;
			var tSliderWidth = tTrayWidth - tButtonXInc*(tTotalButtons) - 20;
			tX = -tSliderWidth*0.5+(tButtonXInc*((tButtonsOnLeft-tButtonOnRight)*0.5))-1;
			scaleSlider = new FancySlider(tSliderWidth).setXY(tX, tY)
				.setSliderParams(1, 8, ConstantsApp.DEFAULT_CHARACTER_SCALE)
				.appendTo(tTray);
			scaleSlider.addEventListener(FancySlider.CHANGE, pData.onScale);
			
			pData = null;
		}
		
		public function toggleAnimateButtonAsset(pOn:Boolean) : void {
			animateButton.ChangeImage(pOn ? new $PauseButton() : new $PlayButton());
		}
		
		///////////////////////
		// Imgur
		///////////////////////
		private function _getImgurUploadUrl() : String { return Fewf.assets.getData("config").upload2imgur_url; }
		
		private function _onImgurButtonClicked(e:Event) : void {
			imgurButton.disable();
			_uploadToImgur(_character, function(pResp, err:String=null):void{
				imgurButton.enable();
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
	}
}

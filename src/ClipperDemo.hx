package;

import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.KeyboardEvent;
import flash.Lib;
import haxe.Timer;

import hxClipper.Clipper;


class ClipperDemo extends Sprite {

	public static function main(): Void {
		Lib.current.addChild(new ClipperDemo());
	}

	public function new() {
		super();
		
		// click/drag
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		
		// animate
		Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		// key presses
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
	}
	
    function onMouseUp( event: MouseEvent ): Void {
    }
    
    function onMouseDown( event: MouseEvent ): Void {
    }
    
    function onEnterFrame( event: Event ): Void {
    }
	
	function onKeyDown(event:KeyboardEvent):Void {
		if (event.keyCode == 27) {  // ESC
			quit();
		}
	}
	
	function quit() {
		#if flash
			flash.system.System.exit(1);
		#elseif sys
			Sys.exit(1);
		#end
	}
}
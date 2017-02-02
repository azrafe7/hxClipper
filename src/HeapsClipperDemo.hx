package;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.Lib;
import haxe.ds.ArraySort;
import hxd.clipper.Clipper;


class HeapsClipperDemo extends Sprite {

	public static function main(): Void {
		Lib.current.addChild(new HeapsClipperDemo());
	}

	private function init(?e) 
	{
		//testCustom();
	}

	public function new() {
		super();
		
		TestsHeaps.run();
		
		// click/drag
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		
		// animate
		Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		// key presses
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		#if iphone
		Lib.current.stage.addEventListener(Event.RESIZE, init);
		#else
		addEventListener(Event.ADDED_TO_STAGE, init);
		#end
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
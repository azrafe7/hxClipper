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

	private function init(?e) 
	{
		var subjectPolygon: Array<IntPoint> = [new IntPoint(0, 0), new IntPoint(200, 0), new IntPoint(100, 200)];
		var clipPolygon: Array<IntPoint> = [new IntPoint(0, 100), new IntPoint(200, 100), new IntPoint(300, 200)];
		var clipper = new Clipper();
		var resultPolygons: Array<Array<IntPoint>> = [];
		clipper.AddPath(subjectPolygon, PolyType.ptSubject, true);
		clipper.AddPath(clipPolygon, PolyType.ptClip, true);
		clipper.Execute(ClipType.ctIntersection, resultPolygons);
		
		trace(resultPolygons);
		
		graphics.lineStyle(2, 0xFF0000, 1.0);
		drawPolygon(subjectPolygon);
		
		graphics.lineStyle(2, 0x0000FF, 1.0);
		drawPolygon(clipPolygon);
		
		graphics.lineStyle(3, 0x00FF00, 1.0);
		graphics.beginFill(0xFF0000, 0.5);
		for( polygon in resultPolygons )
			drawPolygon(polygon);
		graphics.endFill();
	}
	
	public function drawPolygon( polygon: Array<IntPoint> )
	{
		var n: Int = polygon.length;
		if ( n < 3 ) return;
		var p: IntPoint = polygon[0];
		graphics.moveTo(p.X, p.Y);
		for ( i in 1...(n+1) )
		{
			p = polygon[i % n];
			graphics.lineTo(p.X, p.Y);
		}
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
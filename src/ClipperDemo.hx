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

using hxClipper.Clipper.InternalTools;


class ClipperDemo extends Sprite {

	public static function main(): Void {
		Lib.current.addChild(new ClipperDemo());
	}

	private function init(?e) 
	{
		//testJoins4();
		testJoins5();
	}
	
	
	function testJoins4():Void {
		var pft = PFT_EVEN_ODD;    
		var ints:Array<CInt> = [
			1172, 318, 337, 1066, 154, 639, 479, 448, 1197, 545, 1041, 773, 30, 888,
			444, 308, 1051, 552, 1109, 102, 658, 683, 394, 596, 972, 1145, 442, 179,
			470, 441, 227, 564, 1179, 1037, 213, 379, 1072, 872, 587, 171, 723, 329,
			272, 242, 952, 1121, 714, 1148, 91, 217, 735, 561, 903, 1009, 664, 1168,
			1160, 847, 9, 7, 619, 142, 1139, 1116, 1134, 369, 760, 647, 372, 134,
			1106, 183, 311, 103, 265, 185, 1062, 856, 453, 944, 44, 653, 766, 527,
			334, 965, 443, 971, 474, 36, 397, 1138, 901, 841, 775, 612, 222, 465,
			148, 955, 417, 540, 997, 472, 666, 802, 754, 32, 907, 638, 927, 42, 990,
			406, 99, 682, 17, 281, 106, 848];
			
		var subj = Tests.MakeDiamondPolygons(20, 600, 400);
		//trace(subj.length);
		for (i in 0...120) subj[ints[i]].clear();
		var c = new Clipper();
		//c.StrictlySimple = true;
		c.addPaths(subj, PT_SUBJECT, true);
		var solution = [];
		var res = c.executePaths(CT_UNION, solution, pft, pft);

		//trace(solution.length);
		
		graphics.clear();
		
		for (polygon in subj) {
			var col = 0xFF0000;// Std.int(Math.random() * 0xFFFFFF);
			graphics.lineStyle(1, col, 1.0);
			graphics.beginFill(col, 0.25);
			drawPolygon(polygon);
			graphics.endFill();
		}
		
		for (polygon in solution) {
			var col = Std.int(Math.random() * 0xFFFFFF);
			graphics.lineStyle(1, col, 1.0);
			graphics.beginFill(col, 0.25);
			drawPolygon(polygon);
			graphics.endFill();
		}
    }

	function testJoins5():Void {
		var pft = PFT_EVEN_ODD;    
		var ints:Array<CInt> = [
			553, 388, 574, 20, 191, 26, 461, 258, 509, 19, 466, 257, 90, 269, 373, 516,
			350, 333, 288, 141, 47, 217, 247, 519, 535, 336, 504, 497, 344, 341, 293,
			177, 558, 598, 399, 286, 482, 185, 266, 24, 27, 118, 338, 413, 514, 510,
			366, 46, 593, 465, 405, 32, 449, 6, 326, 59, 75, 173, 127, 130];
		var subj = Tests.MakeSquarePolygons(20, 600, 400);
		for (i in 0...60) subj.splice(ints[i], 1);
		var c = new Clipper();
		//c.StrictlySimple = true;
		c.addPaths(subj, PT_SUBJECT, true);
		var solution = [];
		var res = c.executePaths(CT_UNION, solution, pft, pft);
		//trace(solution.length);
		
		graphics.clear();
		
		for (polygon in subj) {
			var col = 0xFF0000;// Std.int(Math.random() * 0xFFFFFF);
			graphics.lineStyle(1, col, 1.0);
			graphics.beginFill(col, 0.25);
			drawPolygon(polygon);
			graphics.endFill();
		}
		
		for (polygon in solution) {
			var col = 0x00FF00;// Std.int(Math.random() * 0xFFFFFF);
			graphics.lineStyle(1, col, 1.0);
			graphics.beginFill(col, 0.25);
			drawPolygon(polygon);
			graphics.endFill();
		}
    }


	public function drawPolygon( polygon: Array<IntPoint> )
	{
		var n: Int = polygon.length;
		if ( n < 3 ) return;
		var p: IntPoint = polygon[0];
		graphics.moveTo(p.x, p.y);
		for ( i in 1...(n+1) )
		{
			p = polygon[i % n];
			graphics.lineTo(p.x, p.y);
		}
	}
	
	public function new() {
		super();
		
		Tests.run();
		
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
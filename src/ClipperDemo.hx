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
		var subjectPolygon: Array<IntPoint> = [new IntPoint(0, 0), new IntPoint(200, 0), new IntPoint(100, 200)];
		var clipPolygon: Array<IntPoint> = [new IntPoint(0, 100), new IntPoint(200, 100), new IntPoint(300, 200)];
		var clipper = new Clipper();
		var resultPolygons: Array<Array<IntPoint>> = [];
		clipper.AddPath(subjectPolygon, PolyType.ptSubject, true);
		clipper.AddPath(clipPolygon, PolyType.ptClip, true);
		
		clipper.Execute(ClipType.ctDifference, resultPolygons);
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
		
		testUnion2();
		//testJoins4();
	}
	
	function testUnion2():Void {
		var pft = pftEvenOdd;
		
		var ints:Array<Array<CInt>> = [[0, 10, 20, 10, 20, 20, 10, 2],
			[0, 10, 30, 10, 30, 20, 20, 2],
			[0, 10, 40, 10, 40, 20, 30, 2],
			[0, 10, 50, 10, 50, 20, 40, 2],
			[0, 10, 60, 10, 60, 20, 50, 2],
			[0, 20, 20, 20, 20, 30, 10, 3],
			[0, 20, 40, 20, 40, 30, 30, 3],
			[0, 30, 20, 30, 20, 40, 10, 4],
			[0, 30, 30, 30, 30, 40, 20, 4],
			[0, 30, 40, 30, 40, 40, 30, 4],
			[0, 30, 50, 30, 50, 40, 40, 4]];

		var subj:Paths = [];
		for (i in 0...11)
			subj.push(Tests.MakePolygonFromInts(ints[i], 12));
		var c = new Clipper();
		c.AddPaths(subj, ptSubject, true);

		var solution:Paths = [];
		var res = c.ExecutePaths(ctUnion, solution, pft, pft);
		res = res && (solution.length == 2);
		trace(solution.length);
		
		graphics.clear();
		
		graphics.lineStyle(1, 0xFF0000, 0.75);
		for (polygon in subj) {
			drawPolygon(polygon);
		}
		
		//graphics.lineStyle(1, 0x00FF00, 0.75);
		graphics.beginFill(0x00FF00, 0.5);
		for (polygon in solution)
			drawPolygon(polygon);
		graphics.endFill();
		
    } 
	
	function testJoins4():Void {
		var pft = pftEvenOdd;    
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
		for (i in 0...120) subj[ints[i]].clear();
		var c = new Clipper();
		c.AddPaths(subj, ptSubject, true);
		var solution = [];
		var res = c.ExecutePaths(ctUnion, solution, pft, pft);

		trace(solution.length);
		
		graphics.clear();
		
		graphics.lineStyle(1, 0xFF0000, 0.75);
		for (polygon in subj) {
			drawPolygon(polygon);
		}
		
		//graphics.lineStyle(1, 0x00FF00, 0.75);
		graphics.beginFill(0x00FF00, 0.5);
		for (polygon in solution)
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
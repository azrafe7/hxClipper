package;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.Lib;
import haxe.ds.ArraySort;
import hxClipper.Clipper;


using hxClipper.Clipper.InternalTools;


class ClipperDemo extends Sprite {

  public static function main(): Void {
    Lib.current.addChild(new ClipperDemo());
  }

  private function init(?e)
  {
    //testJoins4();
    //testJoins5();
    //testOrientation4();
    //testOrientation7();
    testCustom();

  }


  function testOrientation4():Void {
    var pft = PFT_NON_ZERO;

    var ints1:Array<CInt> = [40, 190, 400, 10, 510, 450,
      300, 50, 440, 230, 340, 290, 260, 510, 110, 50, 500, 90,
      450, 410, 550, 70, 70, 130, 410, 110, 130, 130, 470, 50,
      410, 10, 360, 50, 460, 90, 170, 270, 400, 210, 240, 370,
      50, 370, 350, 270, 530, 330, 170, 250, 440, 170, 40, 430,
      410, 90, 170, 510, 470, 130, 290, 390, 510, 410, 500, 230,
      490, 490, 430, 430, 10, 250, 240, 190, 80, 370, 60, 190,
      570, 490, 110, 270, 550, 290, 90, 10, 200, 10, 580, 450,
      500, 450, 370, 210, 10, 250, 60, 70, 220, 10, 530, 130, 190, 10,
      350, 170, 440, 330, 260, 50, 320, 10, 570, 10, 350, 170,
      130, 470, 350, 370, 40, 130, 540, 50, 10, 50, 320, 450, 270, 470,
      460, 10, 60, 110, 280, 170, 300, 410, 300, 370, 520, 170,
      460, 410, 180, 270, 270, 450, 50, 110, 490, 490, 10, 150,
      240, 490, 200, 190, 10, 10, 30, 370, 170, 410, 560, 290,
      140, 10, 350, 190, 290, 10, 460, 210, 70, 290, 300, 270,
      570, 450, 250, 330, 250, 290, 300, 410, 210, 330, 320, 390,
      160, 290, 70, 190, 40, 170, 490, 70, 70, 50];
    var ints2:Array<CInt> = [160, 510, 440, 90, 400, 510,
      220, 250, 480, 210, 80, 410, 530, 170, 10, 50, 220, 290,
      110, 490, 110, 10, 350, 130, 510, 330, 10, 410, 190, 30,
      90, 10, 380, 270, 50, 250, 510, 50, 580, 10, 50, 130, 540, 330,
      120, 250, 440, 250, 10, 430, 10, 410, 150, 190, 510, 490,
      400, 170, 200, 10, 170, 470, 300, 10, 130, 130, 190, 10,
      500, 350, 40, 10, 400, 230, 20, 370, 230, 510, 140, 10, 220, 490,
      90, 370, 490, 190, 520, 210, 180, 70, 440, 490, 510, 10,
      420, 210, 340, 410, 80, 10, 100, 190, 100, 250, 340, 390,
      360, 10, 170, 70, 300, 290, 110, 370, 160, 330, 210, 10,
      300, 10, 540, 410, 380, 490, 550, 290, 170, 450, 580, 390,
      360, 10, 450, 370, 520, 330, 100, 30, 160, 450, 160, 190,
      300, 90, 400, 270, 40, 170, 40, 90, 210, 330, 450, 50, 430, 370,
      290, 370, 150, 10, 340, 170, 10, 90, 180, 150, 530, 450,
      310, 490, 400, 450, 340, 10, 420, 210, 500, 70, 100, 10,
      400, 470, 40, 490, 550, 190, 30, 90, 100, 130, 70, 490, 20, 270,
      490, 410, 570, 370, 220, 90];

    var subj = new Paths();
    subj.clear();
    subj.push(Tests.MakePolygonFromInts(ints1));
    var clip = new Paths();
    clip.clear();
    //for (i in 0...ints2.length) if (i % 2 == 1) ints2[i] = 600-ints2[i];
    clip.push(Tests.MakePolygonFromInts(ints2));
    var c = new Clipper();
    c.addPaths(subj, PT_SUBJECT, true);
    c.addPaths(clip, PT_CLIP, true);

    var solution = new Paths();
    var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

    var cnt = 0;
    if (res) {
      for (i in 0...solution.length) {
        if (!Clipper.orientation(solution[i])) cnt++;
      }
    }


    graphics.clear();

    draw([]/*subj*/, clip, []/*solution*/);
    //draw([], [], solution);

    trace("TestOrientation4");
    for (poly in solution) {
      var str = "[";
      for (pt in poly) {
        str += pt.x + "," + pt.y + " ";
      }
      str += "]";
      trace(str);
    }

    //if (!res) throw "Error " + res;
    //if (2 != cnt) throw "Error length " + cnt;
    //assertTrue(res);
    //assertEquals(2, cnt);
    }

  function testCustom():Void {
    var pft = PFT_NON_ZERO;

    var ints1:Array<CInt> = [40, 190, 400, 10, 510, 450,
      300, 50, 440, 230, 340, 290];
    var ints2:Array<CInt> = [160, 510, 440, 90, 400, 510,
      220, 250, 480, 210, 80, 410];

    var subj = new Paths();
    subj.clear();
    subj.push(Tests.MakePolygonFromInts(ints1));
    var clip = new Paths();
    clip.clear();

    clip.push(Tests.MakePolygonFromInts(ints2));
    var c = new Clipper();
    c.addPaths(subj, PT_SUBJECT, true);
    c.addPaths(clip, PT_CLIP, true);

    var solution = new Paths();
    var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

    var cnt = 0;
    if (res) {
      for (i in 0...solution.length) {
        if (!Clipper.orientation(solution[i])) cnt++;
      }
    }


    graphics.clear();

    draw(subj, clip, []/*solution*/, flash.display.GraphicsPathWinding.NON_ZERO);
    draw([], [], solution, flash.display.GraphicsPathWinding.NON_ZERO, 500, 0);

    trace("TestCustom " + solution.length);
    for (poly in solution) {
      trace(dump(poly) + ",");
    }

    //if (!res) throw "Error " + res;
    //if (2 != cnt) throw "Error length " + cnt;
    //assertTrue(res);
    //assertEquals(2, cnt);
    }

    function dump(a:Path):String {
        var str = a.map(function(p) {
           return p.x + "," + p.y;
        }).join(", ");

        return "[" + str + "]";
    }

  function testOrientation7():Void {
    var pft = PFT_NON_ZERO;

    var ints1:Array<CInt> = [0, 0, 100, 0, 104, 116, 0, 118];
    var ints2:Array<CInt> = [111, 115, 200, 103, 200, 200, 105, 200];
    var ints3:Array<CInt> = [0, 103, 112, 111, 105, 200, 0, 200];
    var ints4:Array<CInt> = [116, 0, 200, 0, 200, 113, 101, 110];

    var subj = new Paths();
    subj.clear();
    subj.push(Tests.MakePolygonFromInts(ints1));
    subj.push(Tests.MakePolygonFromInts(ints2));
    var clip = new Paths();
    clip.clear();
    clip.push(Tests.MakePolygonFromInts(ints3));
    clip.push(Tests.MakePolygonFromInts(ints4));
    var c = new Clipper();
    c.addPaths(subj, PT_SUBJECT, true);
    c.addPaths(clip, PT_CLIP, true);
    var solution = new Paths();

    var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

    res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
    if (!res) throw "Error " + res;
    if (2 != solution.length) throw "Error length " + solution.length;
    //assertTrue(res);
    //assertEquals(2, solution.length);
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
    //c.strictlySimple = true;
    //c.reverseSolution = true;
    c.addPaths(subj, PT_SUBJECT, true);
    var solution = [];
    var res = c.executePaths(CT_UNION, solution, pft, pft);

    //trace(solution.length);

    draw(subj, [], solution);
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
    //c.strictlySimple = true;
    c.addPaths(subj, PT_SUBJECT, true);
    var solution = [];
    var res = c.executePaths(CT_UNION, solution, pft, pft);
    trace(solution.length);

    draw(subj, [], solution);
    }

  function draw(subject:Paths, clip:Paths, solution:Paths, winding:flash.display.GraphicsPathWinding = null, x:Float = 0., y:Float = 0.):Void {
    var alpha = .5;
    drawPaths(subject, x, y, 0xFF0000, alpha, winding);
    drawPaths(clip, x, y, 0x0000FF, alpha, winding);
    drawPaths(solution, x, y, 0x00FF00, alpha, winding);

    /*for (polygon in subject) {
      var col = 0xFF0000;// Std.int(Math.random() * 0xFFFFFF);
      drawPolygon(polygon, col, .25);
    }

    for (polygon in clip) {
      var col = 0x0000FF;// Std.int(Math.random() * 0xFFFFFF);
      drawPolygon(polygon, col, .25);
    }

    for (polygon in solution) {
      var col = 0x00FF00;// Std.int(Math.random() * 0xFFFFFF);
      drawPolygon(polygon, col, .25);
    }*/
  }

  public function sortByNonHolesFirst(poly, qoly):Int {
    var isPolyHole = !Clipper.orientation(poly);
    var isQolyHole = !Clipper.orientation(qoly);
    return isPolyHole ? 1 : isQolyHole ? -1 : 0;
  }

  public function drawPolygon(polygon:Array<IntPoint>, color:UInt, alpha:Float = 1)
  {
    var n:Int = polygon.length;
    if (n < 3) return;
    var p:IntPoint = polygon[0];

    var isHole = !Clipper.orientation(polygon);

    graphics.lineStyle(1, color, .9);

    if (isHole) graphics.beginFill(stage.color & 0xFFFFFF, 1);
    else graphics.beginFill(color, alpha);

    graphics.moveTo(p.x, p.y);
    for (i in 1...(n + 1))
    {
      p = polygon[i % n];
      graphics.lineTo(p.x, p.y);
    }

    graphics.endFill();
  }

  function drawPaths(paths:Array<Array<IntPoint>>, x:Float = 0., y:Float = 0., color:Int = 0xFFFFFF, alpha:Float = 1., winding:flash.display.GraphicsPathWinding = null, fill:Bool = true):Void
  {
    var g = graphics;
    g.lineStyle(null, color, alpha);

    if (paths.length <= 0) return;

    if (winding == null) flash.display.GraphicsPathWinding.EVEN_ODD;

    var data = new flash.Vector();
    var commands = new flash.Vector();

    for (path in paths) {
      var len = path.length;

      for (i in 0...len) {
        if (i == 0) commands.push(1); // moveTo
        else commands.push(2); // lineTo

        data.push(x + path[i].x);
        data.push(y + path[i].y);
      }
      // close
      if (fill) {
        commands.push(2);
        data.push(x + path[0].x);
        data.push(y + path[0].y);
      }
    }

    if (fill) g.beginFill(color, .25);
    g.drawPath(commands, data, winding);
    if (fill) g.endFill();
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
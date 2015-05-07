/*******************************************************************************
*                                                                              *
* Author    :  Angus Johnson                                                   *
* Version   :  0.9.1                                                           *
* Date      :  11 February 2014                                                *
* Website   :  http://www.angusj.com                                           *
* Copyright :  Angus Johnson 2010-2014                                         *
*                                                                              *
* License:                                                                     *
* Use, modification & distribution is subject to Boost Software License Ver 1. *
* http://www.boost.org/LICENSE_1_0.txt                                         *
*                                                                              *
*******************************************************************************/

// Porting from clippertest.cpp (Clipper 6.2.1 - sandbox folder)

// Remember to define USE_LINES (to enable open paths), 
// USE_INT64 has not been implemented (as Int128 is not currently supported in this hx ver).


package ;

import haxe.Log;
import haxe.Timer;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import hxClipper.Clipper;
import hxClipper.Clipper.CInt;
import hxClipper.Clipper.IntPoint;
import hxClipper.Clipper.Path;
import hxClipper.Clipper.Paths;
import hxClipper.Clipper.PolyFillType;
import hxClipper.Clipper.PolyTree;


using StringTools;
using hxClipper.Clipper.InternalTools;

/**
 * Test suite for TSTree.
 * 
 * Remember to define USE_LINES (to enable open paths), 
 * and USE_INT32 (as Int128 is not currently supported).
 * 
 * @author azrafe7
 */
class Tests extends TestCase
{
    var subj:Paths;
	var clip:Paths;
	var solution:Paths;
	
    var polytree:PolyTree;
    var pft:PolyFillType;

	public function new()
	{
		super();
		
		subj = new Paths();
		subj = new Paths();
		clip = new Paths();
		solution = new Paths();
		
		polytree = new PolyTree();
		pft = null;
    }
	
	
	static public function MakePolygonFromInts(ints:Array<CInt>, scale:Float = 1.0):Path {
		var i = 0;
		var p = new Path();
		while (i < ints.length) {
			p.push(new IntPoint(Std.int(ints[i].toFloat() * scale), Std.int(ints[i + 1].toFloat() * scale)));
			i += 2;
		}
		return p;
	}
	//---------------------------------------------------------------------------

	static public function MakeSquarePolygons(size:Int, totalWidth:Int, totalHeight:Int):Paths {
		var cols = Std.int(totalWidth / size);
		var rows = Std.int(totalHeight / size);
		var p = new Paths();
		for (i in 0...rows) {
			for (j in 0...cols) {
				var ints:Array<CInt> = [j * size, i * size, (j + 1) * size, i * size, 
										(j + 1) * size, (i + 1) * size, j * size, (i + 1) * size];
				p[j * rows + i] = MakePolygonFromInts(ints);
			}
		}
		return p;
	}
	//------------------------------------------------------------------------------

	static public function MakeDiamondPolygons(size:Int, totalWidth:Int, totalHeight:Int):Paths {
		var halfSize = Std.int(size / 2);
		size = halfSize * 2;
		var cols = Std.int(totalWidth / size);
		var rows = Std.int(totalHeight * 2 / size);
		var p = new Paths();
		var dx = 0;
		for (i in 0...rows) {
			if (dx == 0) dx = halfSize; 
			else dx = 0;
			
			for (j in 0...cols) {
				var ints:Array<CInt> = [dx + j * size,    			i * halfSize + halfSize,
										dx + j * size + halfSize,   i * halfSize,
										dx + (j+1) * size,          i * halfSize + halfSize,
										dx + j * size + halfSize,   i * halfSize + halfSize * 2];
				p[j * rows + i] = MakePolygonFromInts(ints);
			}
		}
		return p;
	}
	//------------------------------------------------------------------------------

	function testDifference1():Void 
	{
		pft = PolyFillType.PFT_EVEN_ODD;
		var ints1:Array<CInt> = [29, 342, 115, 68, 141, 86];
		var ints2:Array<CInt> = [128, 160, 99, 132, 97, 174];
		var ints3:Array<CInt> = [99, 212, 128, 160, 97, 174, 58, 160];
		var ints4:Array<CInt> = [97, 174, 99, 132, 60, 124, 58, 160];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(ClipType.CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[0]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
	}
	//------------------------------------------------------------------------------
	
    function testDifference2():Void
    {
		pft = PolyFillType.PFT_EVEN_ODD;

		var ints1:Array<CInt> = [-103, -219, -103, -136, -115, -136];
		var ints2:Array<CInt> = [-110, -174, -70, -174, -110, -155];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(ClipType.CT_DIFFERENCE, solution, pft, pft);
		
		assertTrue(res);
		assertEquals(1, solution.length);
    } 
	//------------------------------------------------------------------------------
	
	function testHorz1():Void {
		pft = PolyFillType.PFT_EVEN_ODD;

		var ints1:Array<CInt> = [380, 280, 450, 280, 130, 400, 490, 430, 320, 200, 450, 260];
		var ints2:Array<CInt> = [350, 240, 520, 470, 100, 300];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(ClipType.CT_INTERSECTION, solution, pft, pft);

		assertTrue(res);
		assertTrue(solution.length <= 2);
	}
	//------------------------------------------------------------------------------
	
    function testHorz2():Void
    {
		pft = PolyFillType.PFT_EVEN_ODD;

		var ints1:Array<CInt> = [120, 400, 350, 380, 340, 140];
		var ints2:Array<CInt> = [350, 370, 150, 370, 560, 20, 350, 390, 340, 150, 570, 230, 390, 40];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(ClipType.CT_INTERSECTION, solution, pft, pft);

		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//------------------------------------------------------------------------------

    function testHorz3():Void {
		pft = PolyFillType.PFT_EVEN_ODD;

		var ints1:Array<CInt> = [470, 190, 100, 520, 280, 270, 380, 270, 460, 170];
		var ints2:Array<CInt> = [170, 70, 500, 350, 110, 90];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(ClipType.CT_INTERSECTION, solution, pft, pft);

		assertTrue(res);
		assertEquals(1, solution.length);
    } 
	//------------------------------------------------------------------------------
	
    function testHorz4():Void {
		pft = PolyFillType.PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [904, 901, 1801, 901, 1801, 1801, 902, 1803];
		var ints2:Array<CInt> = [2, 1800, 902, 1800, 902, 2704, 4, 2701];
		var ints3:Array<CInt> = [902, 1802, 902, 2704, 1804, 2703, 1801, 1804];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		subj.push(MakePolygonFromInts(ints3));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		var res = c.executePaths(ClipType.CT_UNION, solution, pft, pft);

		res = res && Clipper.orientation(solution[0]) && !Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//------------------------------------------------------------------------------

	function testHorz5():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [93, 92, 183, 93, 184, 184, 94, 183];
		var ints2:Array<CInt> = [184, 1, 270, 2, 272, 91, 183, 94];
		var ints3:Array<CInt> = [92, 2, 91, 91, 184, 91, 184, 0];
		var ints4:Array<CInt> = [183, 93, 184, 184, 271, 182, 274, 94];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testHorz6():Void {
		pft = PFT_NON_ZERO;
	
		var ints1:Array<CInt> = [14, 15, 16, 12, 10, 12];
		var ints2:Array<CInt> = [15, 14, 11, 14, 13, 16, 17, 10, 10, 17, 18, 13];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);

		assertTrue(res);
		assertEquals(1, solution.length);
	}
	//---------------------------------------------------------------------------

	function testHorz7():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [11, 19, 19, 15, 15, 12, 13, 19, 15, 13, 10, 14, 13, 18, 16, 13];
		var ints2:Array<CInt> = [16, 10, 14, 17, 18, 10, 15, 18, 14, 14, 15, 14, 11, 16];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);

		assertTrue(res);
		assertEquals(2, solution.length);
	} 
	//---------------------------------------------------------------------------
	
	function testHorz8():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [12, 11, 15, 15, 18, 16, 16, 18, 15, 14, 14, 14, 19, 15];
		var ints2:Array<CInt> = [13, 12, 17, 17, 19, 15];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testHorz9():Void {
		pft = PFT_EVEN_ODD;

		var ints1:Array<CInt> = [380, 140, 430, 120, 180, 120, 430, 120, 190, 150];
		var ints2:Array<CInt> = [430, 130, 210, 70, 20, 260];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testHorz10():Void {
		pft = PFT_EVEN_ODD;

		var ints1:Array<CInt> = [40, 310, 410, 110, 460, 110, 260, 200];
		var ints2:Array<CInt> = [120, 260, 450, 220, 330, 220, 240, 220, 50, 380];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
	
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testOrientation1():Void {
		pft = PFT_EVEN_ODD;

		var ints1:Array<CInt> = [470, 130, 330, 10, 370, 10,
			290, 190, 290, 280, 190, 10, 70, 370, 10, 400, 310, 10, 490, 220,
			130, 10, 150, 400, 490, 150, 250, 60, 410, 320, 430, 410,
			470, 10, 10, 10, 250, 220, 10, 180, 250, 160, 490, 130, 190, 320,
			170, 240, 290, 280, 370, 240, 350, 90, 450, 190, 10, 370,
			110, 180, 290, 160, 190, 350, 490, 360, 190, 190, 370, 230,
			90, 220, 270, 10, 70, 190, 10, 270, 430, 100, 190, 140, 370, 80,
			10, 40, 250, 260, 430, 40, 130, 350, 190, 420, 10, 10, 130, 50,
			90, 400, 530, 50, 150, 90, 250, 150, 390, 310, 250, 180,
			310, 220, 350, 280, 30, 140, 430, 260, 130, 10, 430, 310,
			10, 60, 190, 60, 490, 320, 190, 360, 430, 130, 210, 220,
			270, 190, 10, 10, 510, 10, 150, 210, 90, 400, 110, 10, 130, 110,
			130, 80, 130, 30, 430, 190, 190, 380, 90, 300, 10, 340, 10, 70,
			250, 380, 310, 370, 370, 240, 190, 130, 490, 100, 470, 70,
			10, 420, 190, 20, 430, 290, 430, 10, 330, 70, 450, 140, 430, 40,
			150, 220, 170, 190, 10, 110, 470, 310, 510, 160, 10, 200];
		var ints2:Array<CInt> = [50, 420, 10, 180, 190, 160,
			50, 40, 490, 40, 450, 130, 450, 290, 290, 310, 430, 110,
			370, 250, 490, 220, 430, 230, 410, 220, 10, 200, 530, 130, 
			50, 350, 370, 290, 130, 130, 110, 390, 10, 350, 210, 340,
			370, 220, 530, 280, 370, 170, 190, 370, 330, 310, 510, 280, 
			90, 10, 50, 250, 170, 100, 110, 40, 310, 370, 430, 80, 390, 40, 
			250, 360, 350, 150, 130, 310, 10, 260, 390, 90, 370, 280,
			70, 100, 530, 190, 10, 250, 470, 340, 110, 180, 10, 10, 70, 380, 
			370, 60, 190, 290, 250, 70, 10, 150, 70, 120, 490, 340, 330, 40, 
			90, 10, 210, 40, 50, 10, 450, 370, 310, 390, 10, 10, 10, 270, 
			250, 180, 130, 120, 10, 150, 10, 220, 150, 280, 490, 10, 
			150, 370, 370, 220, 10, 310, 10, 330, 450, 150, 310, 80, 
			410, 40, 530, 290, 110, 240, 70, 140, 190, 410, 10, 250, 
			270, 230, 370, 380, 270, 280, 230, 220, 430, 110, 10, 290, 
			130, 250, 190, 40, 170, 320, 210, 220, 290, 40, 370, 380, 
			30, 380, 130, 50, 370, 340, 130, 190, 70, 250, 310, 270, 
			250, 290, 310, 280, 230, 150];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);

		if (res) {
			for (i in 0...solution.length) {
				if (!Clipper.orientation(solution[i])) {
					res = false;
					break;
				}
			}
		}
		
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testOrientation2():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [370, 150, 130, 400, 490, 290,
			490, 400, 170, 10, 130, 130, 270, 90, 430, 230, 310, 230,
			10, 80, 390, 110, 370, 20, 190, 210, 370, 410, 110, 100,
			410, 230, 370, 290, 350, 190, 350, 100, 230, 290];
		var ints2:Array<CInt> = [510, 400, 250, 100, 410, 410,
			170, 210, 390, 100, 10, 100, 10, 250, 10, 220, 130, 90, 410, 330,
			450, 160, 50, 180, 110, 100, 210, 320, 410, 220, 190, 30,
			370, 70, 270, 260, 450, 250, 90, 280];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);
		var cnt = 0;
		if (res) {
			for (i in 0...solution.length) {
				if (!Clipper.orientation(solution[i])) cnt++;
			}
		}
		assertTrue(res);
		assertEquals(4, cnt);
	} 
	//---------------------------------------------------------------------------

	function testOrientation3():Void {
		pft = PFT_EVEN_ODD;

		var ints1:Array<CInt> = [70, 290, 10, 410, 10, 220];
		var ints2:Array<CInt> = [430, 20, 10, 30, 10, 370, 250, 300,
			190, 10, 10, 370, 30, 220, 490, 100, 10, 370];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);

		if (res) {
			for (i in 0...solution.length) {
				if (!Clipper.orientation(solution[i])) {
					res = false;
					break;
				}
			}
		}
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testOrientation4():Void {
		pft = PFT_NON_ZERO;

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

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		var cnt = 0;
		if (res) {
			for (i in 0...solution.length) {
				if (!Clipper.orientation(solution[i])) cnt++;
			}
		}
		
		assertTrue(res);
		assertEquals(2, cnt);
    } 
	//---------------------------------------------------------------------------

	function testOrientation5():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [5237, 5237, 68632, 5164, 10315, 61247,
			10315, 20643, 16045, 29877, 24374, 11012, 10359, 19690, 10315, 20643,
			10315, 67660];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		
		var res = c.executePaths(CT_UNION, solution, pft, pft);

		res = res && !Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation6():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [0, 0, 100, 0, 101, 116, 0, 109];
		var ints2:Array<CInt> = [110, 112, 200, 106, 200, 200, 111, 200];
		var ints3:Array<CInt> = [0, 106, 101, 114, 107, 200, 0, 200];
		var ints4:Array<CInt> = [117, 0, 200, 0, 200, 110, 115, 102];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation7():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [0, 0, 100, 0, 104, 116, 0, 118];
		var ints2:Array<CInt> = [111, 115, 200, 103, 200, 200, 105, 200];
		var ints3:Array<CInt> = [0, 103, 112, 111, 105, 200, 0, 200];
		var ints4:Array<CInt> = [116, 0, 200, 0, 200, 113, 101, 110];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation8():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [0, 0, 112, 0, 111, 116, 0, 108];
		var ints2:Array<CInt> = [112, 114, 200, 108, 200, 200, 116, 200];
		var ints3:Array<CInt> = [0, 102, 118, 111, 117, 200, 0, 200];
		var ints4:Array<CInt> = [109, 0, 200, 0, 200, 117, 105, 110];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation9():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [0, 0, 114, 0, 113, 110, 0, 117];
		var ints2:Array<CInt> = [109, 114, 200, 106, 200, 200, 104, 200];
		var ints3:Array<CInt> = [0, 100, 118, 106, 103, 200, 0, 200];
		var ints4:Array<CInt> = [110, 0, 200, 0, 200, 116, 101, 105];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation10():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [0, 0, 102, 0, 103, 118, 0, 106];
		var ints2:Array<CInt> = [110, 115, 200, 108, 200, 200, 113, 200];
		var ints3:Array<CInt> = [0, 110, 103, 117, 109, 200, 0, 200];
		var ints4:Array<CInt> = [118, 0, 200, 0, 200, 108, 116, 101];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation11():Void {
		pft = PFT_NON_ZERO;

		var ints1:Array<CInt> = [0, 0, 100, 0, 107, 116, 0, 104];
		var ints2:Array<CInt> = [116, 100, 200, 115, 200, 200, 118, 200];
		var ints3:Array<CInt> = [0, 115, 107, 115, 115, 200, 0, 200];
		var ints4:Array<CInt> = [101, 0, 200, 0, 200, 100, 100, 100];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		
		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);

		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testOrientation12():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 119, 0, 113, 105, 0, 100];
		var ints2:Array<CInt> = [117, 103, 200, 105, 200, 200, 106, 200];
		var ints3:Array<CInt> = [0, 112, 116, 104, 108, 200, 0, 200];
		var ints4:Array<CInt> = [101, 0, 200, 0, 200, 117, 104, 112];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation13():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 119, 0, 109, 108, 0, 101];
		var ints2:Array<CInt> = [115, 100, 200, 103, 200, 200, 101, 200];
		var ints3:Array<CInt> = [0, 117, 110, 100, 103, 200, 0, 200];
		var ints4:Array<CInt> = [115, 0, 200, 0, 200, 109, 119, 102];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation14():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 102, 0, 119, 107, 0, 101];
		var ints2:Array<CInt> = [116, 110, 200, 114, 200, 200, 107, 200];
		var ints3:Array<CInt> = [0, 108, 117, 106, 111, 200, 0, 200];
		var ints4:Array<CInt> = [112, 0, 200, 0, 200, 117, 101, 112];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testOrientation15():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 106, 0, 107, 111, 0, 102];
		var ints2:Array<CInt> = [119, 116, 200, 118, 200, 200, 117, 200];
		var ints3:Array<CInt> = [0, 101, 107, 106, 111, 200, 0, 200];
		var ints4:Array<CInt> = [113, 0, 200, 0, 200, 114, 117, 117];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && Clipper.orientation(solution[1]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------
 
	function testSelfInt1():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 201, 0, 203, 217, 0, 207];
		var ints2:Array<CInt> = [204, 214, 400, 217, 400, 400, 205, 400];
		var ints3:Array<CInt> = [0, 211, 203, 214, 208, 400, 0, 400];
		var ints4:Array<CInt> = [207, 0, 400, 0, 400, 208, 218, 200];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && Clipper.orientation(solution[0]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testSelfInt2():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 200, 0, 219, 207, 0, 200];
		var ints2:Array<CInt> = [201, 207, 400, 200, 400, 400, 200, 400];
		var ints3:Array<CInt> = [0, 200, 214, 207, 200, 400, 0, 400];
		var ints4:Array<CInt> = [200, 0, 400, 0, 400, 200, 209, 215];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && (solution.length == 2) && Clipper.orientation(solution[0]) && Clipper.orientation(solution[1]);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testSelfInt3():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 201, 0, 207, 214, 0, 207];
		var ints2:Array<CInt> = [209, 211, 400, 206, 400, 400, 214, 400];
		var ints3:Array<CInt> = [0, 211, 207, 208, 213, 400, 0, 400];
		var ints4:Array<CInt> = [213, 0, 400, 0, 400, 210, 213, 200];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && (solution.length == 2) && Clipper.orientation(solution[0]) && Clipper.orientation(solution[1]);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testSelfInt4():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [0, 0, 214, 0, 209, 206, 0, 201];
		var ints2:Array<CInt> = [205, 208, 400, 207, 400, 400, 200, 400];
		var ints3:Array<CInt> = [201, 0, 400, 0, 400, 217, 205, 217];
		var ints4:Array<CInt> = [0, 205, 215, 206, 217, 400, 0, 400];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && Clipper.orientation(solution[0]) && Clipper.orientation(solution[1]);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testSelfInt5():Void {
		pft = PFT_EVEN_ODD;
		
		var ints1:Array<CInt> = [0, 0, 219, 0, 217, 217, 0, 200];
		var ints2:Array<CInt> = [214, 219, 400, 200, 400, 400, 219, 400];
		var ints3:Array<CInt> = [0, 207, 205, 211, 214, 400, 0, 400];
		var ints4:Array<CInt> = [202, 0, 400, 0, 400, 217, 205, 217];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		clip.clear();
		clip.push(MakePolygonFromInts(ints3));
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_DIFFERENCE, solution, pft, pft);
		
		res = res && (solution.length == 2) && Clipper.orientation(solution[0]) && Clipper.orientation(solution[1]);
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testSelfInt6():Void {
		pft = PFT_EVEN_ODD;
		
		var ints:Array<CInt> = [182, 179, 477, 123, 25, 55];
		var ints2:Array<CInt> = [477, 122, 485, 103, 122, 265, 55, 207];

		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_INTERSECTION, solution, pft, pft);
		
		res = res && (solution.length == 1) && Clipper.orientation(solution[0]);
		
		assertTrue(res);
    } 
	//---------------------------------------------------------------------------

	function testUnion1():Void {
		pft = PFT_NON_ZERO;
		
		var ints1:Array<CInt> = [1026, 1126, 1026, 235, 4505, 401,
			4522, 1145, 4503, 1162, 2280, 1129];
		var ints2:Array<CInt> = [4501, 1100, 4501, 866, 1146, 462,
			1071, 1067, 4469, 1000];
		var ints3:Array<CInt> = [4499, 1135, 3360, 1050, 3302, 1107];
		var ints4:Array<CInt> = [3360, 1050, 3291, 1118, 4512, 1136];

		subj.clear();
		subj.push(MakePolygonFromInts(ints1));
		subj.push(MakePolygonFromInts(ints2));
		subj.push(MakePolygonFromInts(ints3));
		clip.clear();
		clip.push(MakePolygonFromInts(ints4));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);

		var res = c.executePaths(CT_UNION, solution, pft, pft);
		res = res && (solution.length == 2) && Clipper.orientation(solution[0]) && !Clipper.orientation(solution[1]);
		
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testUnion2():Void {
		pft = PFT_EVEN_ODD;
		
		var ints:Array<Array<CInt>> = [[10, 10, 20, 10, 20, 20, 10, 20],
			[20, 10, 30, 10, 30, 20, 20, 20],
			[30, 10, 40, 10, 40, 20, 30, 20],
			[40, 10, 50, 10, 50, 20, 40, 20],
			[50, 10, 60, 10, 60, 20, 50, 20],
			[10, 20, 20, 20, 20, 30, 10, 30],
			[30, 20, 40, 20, 40, 30, 30, 30],
			[10, 30, 20, 30, 20, 40, 10, 40],
			[20, 30, 30, 30, 30, 40, 20, 40],
			[30, 30, 40, 30, 40, 40, 30, 40],
			[40, 30, 50, 30, 50, 40, 40, 40]];
		
		subj.clear();
		for (i in 0...11)
			subj.push(MakePolygonFromInts(ints[i]));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);

		var res = c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(2, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testUnion3():Void {
		pft = PFT_EVEN_ODD;     
		var ints:Array<Array<CInt>> = [[1,3, 2,4, 2,5], [1,3, 3,3, 2,4]];
		subj.clear();
		for (i in 0...2)
			subj.push(MakePolygonFromInts(ints[i]));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);

		var res = c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(1, solution.length);
    } 
	//---------------------------------------------------------------------------

	function testAddPath1():Void {
		
		var ints:Array<Array<CInt>> = [[480,20, 480,110, 320,30, 480,30, 250,250, 480,30]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath2():Void {
		
		var ints:Array<Array<CInt>> = [[60, 320, 390, 320, 100, 320,
			220, 120, 120, 10, 20, 380, 120, 20, 280, 20, 480, 20]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath3():Void {
		var ints:Array<Array<CInt>> = [[320, 70, 420, 370, 250, 170, 60, 290,
			10, 290, 210, 290, 400, 150, 410, 340]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath4():Void {
		
		var ints:Array<Array<CInt>> = [[300, 80, 280, 220,
			180, 220, 170, 220, 290, 220, 40, 180]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath5():Void {
		
		var ints:Array<Array<CInt>> = [[170, 340, 280, 230, 160, 50, 430, 370, 280, 230]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath6():Void {
		
		var ints:Array<Array<CInt>> = [[30, 380, 70, 160, 170, 220, 70, 160, 240, 160]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath7():Void {
		
		var ints:Array<Array<CInt>> = [[440, 300, 40, 40, 440, 300, 80, 360]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath8():Void {
		
		var ints:Array<Array<CInt>> = [[260, 10, 260, 240, 190, 100, 260, 10, 420, 120]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath9():Void {
		
		var ints:Array<Array<CInt>> = [[60, 240, 30, 10, 460, 170, 110, 280, 30, 10]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath10():Void {
		
		var ints:Array<Array<CInt>> = [[430, 270, 440, 260, 470, 30, 280, 30, 430, 270, 450, 40]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath11():Void {
		
		var ints:Array<Array<CInt>> = [[320, 10, 240, 300, 260, 140, 320, 10, 240, 300]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath12():Void {
		
		var ints:Array<Array<CInt>> = [[270, 340, 130, 50, 50, 350, 270, 340, 290, 40]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath13():Void {
		
		var ints:Array<Array<CInt>> = [[430, 330, 280, 10, 210, 280, 430, 330, 280, 10]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath14():Void {
		
		var ints:Array<Array<CInt>> = [[50, 30, 410, 330, 50, 30, 310, 50]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath15():Void {
		
		var ints:Array<Array<CInt>> = [[230, 50, 10, 50, 110, 50]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath16():Void {
		
		var ints:Array<Array<CInt>> = [[260, 320, 40, 130, 100, 30, 80, 360, 260, 320, 40, 50]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath17():Void {
		
		var ints:Array<Array<CInt>> = [[190, 170, 350, 290, 110, 290, 250, 290, 430, 90]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath18():Void {
		
		var ints:Array<Array<CInt>> = [[150, 330, 210, 70, 90, 70, 210, 70, 150, 330]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath19():Void {
		
		var ints:Array<Array<CInt>> = [[170, 290, 50, 290, 170, 290, 410, 310, 170, 290]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testAddPath20():Void {
		
		var ints:Array<Array<CInt>> = [[430, 10, 150, 110, 430, 10, 230, 50]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var c = new Clipper();
		var res = c.addPaths(subj, PT_SUBJECT, false);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testOpenPath1():Void {
		pft = PFT_EVEN_ODD;
		
		var ints:Array<Array<CInt>> = [[290, 370, 160, 150, 230, 150, 160, 150, 250, 280]];
		subj.clear();
		subj.push(MakePolygonFromInts(ints[0]));
		var ints2:Array<Array<CInt>> = [[150, 10, 160, 290, 200, 80, 50, 340]];
		clip.clear();
		clip.push(MakePolygonFromInts(ints2[0]));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, false);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePolyTree(CT_INTERSECTION, polytree, pft, pft);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testOpenPath2():Void {
		pft = PFT_EVEN_ODD;
		
		var ints:Array<CInt> = [50, 310, 210, 110, 260, 110, 170, 110, 350, 200];
		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		var ints2:Array<CInt> = [310, 30, 90, 90, 370, 130];
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, false);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePolyTree(CT_INTERSECTION, polytree, pft, pft);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testOpenPath3():Void {
		pft = PFT_EVEN_ODD;
		
		var ints:Array<CInt> = [40, 360,  260, 50,  180, 270,  180, 250,  410, 250,  140, 250,  350, 380];
		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		var ints2:Array<CInt> = [30, 110, 330, 90, 20, 370];
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, false);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePolyTree(CT_INTERSECTION, polytree, pft, pft);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testOpenPath4():Void {
		pft = PFT_EVEN_ODD;
		
		var ints:Array<CInt> = [10,50, 200,50];
		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		var ints2:Array<CInt> = [50,10, 150,10, 150,100, 50,100];
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, false);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePolyTree(CT_INTERSECTION, polytree, pft, pft) && (polytree.numChildren == 1);
		assertTrue(res);
    }
	//---------------------------------------------------------------------------

	function testSimplify1():Void {
		pft = PFT_EVEN_ODD;    
		var ints:Array<CInt> = [5048400, 1719180, 5050250, 1717630, 5049070,
			1717320, 5049150, 1717200, 5049350, 1717570];
		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		var c = new Clipper();
		c.strictlySimple = true; 
		c.addPaths(subj, PT_SUBJECT, true);
		var res = c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(2, solution.length);
    }
	//---------------------------------------------------------------------------

	function testSimplify2():Void {
		pft = PFT_NON_ZERO;    
		var ints:Array<CInt> = [220,720, 420,720, 420,520, 320,520, 320,480,
			480,480, 480,800, 180,800, 180,480, 320,480, 320,520, 220,520];
		var ints2:Array<CInt> = [440,520, 620,520, 620,420, 440,420];
		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		subj.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		var res =  c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(3, solution.length);
    }
	//---------------------------------------------------------------------------

	function testJoins1():Void {
		pft = PFT_EVEN_ODD;    
		var ints:Array<Array<CInt>> = [
			[0, 0, 0, 32, 32, 32, 32, 0],
			[32, 0, 32, 32, 64, 32, 64, 0],
			[64, 0, 64, 32, 96, 32, 96, 0],
			[96, 0, 96, 32, 128, 32, 128, 0],
			[0, 32, 0, 64, 32, 64, 32, 32],
			[64, 32, 64, 64, 96, 64, 96, 32],
			[0, 64, 0, 96, 32, 96, 32, 64],
			[32, 64, 32, 96, 64, 96, 64, 64]
		];
		
		subj.clear();
		for (i in 0...8)
			subj.push(MakePolygonFromInts(ints[i]));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		var res = c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(1, solution.length);
    }
	//---------------------------------------------------------------------------

	function testJoins2():Void {
		pft = PFT_NON_ZERO;    
		var ints:Array<Array<CInt>> = [
			[100, 100, 100, 91, 200, 91, 200, 100],
			[200, 91, 209, 91, 209, 250, 200, 250],
			[209, 250, 209, 259, 100, 259, 100, 250],
			[100, 250, 109, 250, 109, 300, 100, 300],
			[109, 300, 109, 309, 50, 309, 50, 300],
			[50, 309, 41, 309, 41, 250, 50, 250],
			[50, 250, 50, 259, 0, 259, 0, 250],
			[0, 259, -9, 259, -9, 100, 0, 100],
			[-9, 100, -9, 91, 50, 91, 50, 100],
			[50, 100, 41, 100, 41, 50, 50, 50],
			[41, 50, 41, 41, 100, 41, 100, 50],
			[100, 41, 109, 41, 109, 100, 100, 100]];
			
		subj.clear();
		for (i in 0...12)
			subj.push(MakePolygonFromInts(ints[i]));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		var res = c.executePaths(CT_UNION, solution, pft, pft)
				  && (Clipper.orientation(solution[0]) != Clipper.orientation(solution[1]));
		assertTrue(res);
		assertEquals(2, solution.length);
    }
	//---------------------------------------------------------------------------

	function testJoins3():Void {
		pft = PFT_NON_ZERO;    
		var ints:Array<CInt> = [220,720,  420,720,  420,520,  320,520,  320,480,  
			480,480,  480,800, 180,800,  180,480,  320,480,  320,520,  220,520];
		subj.clear();
		subj.push(MakePolygonFromInts(ints));
		var ints2:Array<CInt> = [440,520,  620,520,  620,420,  440,420];
		clip.clear();
		clip.push(MakePolygonFromInts(ints2));
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		c.addPaths(clip, PT_CLIP, true);
		var res = c.executePaths(CT_UNION, solution, pft, pft)
				  && (Clipper.orientation(solution[0]) != Clipper.orientation(solution[1]));
		assertTrue(res);
		assertEquals(2, solution.length);
    }
	//---------------------------------------------------------------------------

	function testJoins4():Void {
		pft = PFT_EVEN_ODD;    
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
			
		subj = MakeDiamondPolygons(20, 600, 400);
		for (i in 0...120) subj[Std.int(ints[i].toFloat())].clear();
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		var res = c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(69, solution.length);
    }
	//---------------------------------------------------------------------------

	function testJoins5():Void {
		pft = PFT_EVEN_ODD;    
		var ints:Array<CInt> = [
			553, 388, 574, 20, 191, 26, 461, 258, 509, 19, 466, 257, 90, 269, 373, 516,
			350, 333, 288, 141, 47, 217, 247, 519, 535, 336, 504, 497, 344, 341, 293,
			177, 558, 598, 399, 286, 482, 185, 266, 24, 27, 118, 338, 413, 514, 510,
			366, 46, 593, 465, 405, 32, 449, 6, 326, 59, 75, 173, 127, 130];
		subj = MakeSquarePolygons(20, 600, 400);
		for (i in 0...60) subj[Std.int(ints[i].toFloat())].clear();
		var c = new Clipper();
		c.addPaths(subj, PT_SUBJECT, true);
		var res = c.executePaths(CT_UNION, solution, pft, pft);
		assertTrue(res);
		assertEquals(37, solution.length);
    }
	//---------------------------------------------------------------------------

	function testOffsetPoly1():Void {
		var scale = 10.0;
		var ints2:Array<CInt> = [348,257, 364,148, 362,148, 326,241, 295,219, 258,88, 440,129, 370,196, 372,275];
		subj.clear();
		subj.push(MakePolygonFromInts(ints2, scale));
		var co = new ClipperOffset();
		co.addPaths(subj, JT_ROUND, ET_CLOSED_POLYGON);
		solution.clear();
		co.executePaths(solution, -7.0 * scale);
		assertEquals(2, solution.length);
    }
	//---------------------------------------------------------------------------
	
	
	static public function run():Void 
	{
		var runner = new CustomTestRunner();
		runner.add(new Tests());
		var startTime = Timer.stamp();
		var success = runner.run();
		trace("Tests executed in " + (Timer.stamp() - startTime) + "s");
	}
}


private class CustomTestRunner extends TestRunner {
	
#if flash
	var stringBuffer:StringBuf;
	
	override public function run():Bool 
	{
		var oldPrint = TestRunner.print;
		stringBuffer = new StringBuf();
		
		TestRunner.print = function (v:Dynamic):Void {
			stringBuffer.add(Std.string(v));
		};
		
		var result = super.run();
		flash.Lib.trace(stringBuffer.toString());
		TestRunner.print = oldPrint;
		
		return result;
	}
#end
}
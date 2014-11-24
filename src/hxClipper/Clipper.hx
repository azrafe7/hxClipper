/*******************************************************************************
*                                                                              *
* Author    :  Angus Johnson                                                   *
* Version   :  6.2.2                                                           *
* Date      :  14 November 2014                                                *
* Website   :  http://www.angusj.com                                           *
* Copyright :  Angus Johnson 2010-2014                                         *
*                                                                              *
* License:                                                                     *
* Use, modification & distribution is subject to Boost Software License Ver 1. *
* http://www.boost.org/LICENSE_1_0.txt                                         *
*                                                                              *
* Attributions:                                                                *
* The code in this library is an extension of Bala Vatti's clipping algorithm: *
* "A generic solution to polygon clipping"                                     *
* Communications of the ACM, Vol 35, Issue 7 (July 1992) pp 56-63.             *
* http://portal.acm.org/citation.cfm?id=129906                                 *
*                                                                              *
* Computer graphics and geometric modeling: implementation and algorithms      *
* By Max K. Agoston                                                            *
* Springer; 1 edition (January 4, 2005)                                        *
* http://books.google.com/books?q=vatti+clipping+agoston                       *
*                                                                              *
* See also:                                                                    *
* "Polygon Offsetting by Computing Winding Numbers"                            *
* Paper no. DETC2005-85513 pp. 565-575                                         *
* ASME 2005 International Design Engineering Technical Conferences             *
* and Computers and Information in Engineering Conference (IDETC/CIE2005)      *
* September 24-28, 2005 , Long Beach, California, USA                          *
* http://www.me.berkeley.edu/~mcmains/pubs/DAC05OffsetPolygon.pdf              *
*                                                                              *
*******************************************************************************/

/*******************************************************************************
*                                                                              *
* This is a translation of the Delphi Clipper library and the naming style     *
* used has retained a Delphi flavour.                                          *
*                                                                              *
*******************************************************************************/


/*
 * CS -> HX notes:
 * 		move some statics from ClipperBase to Clipper
 * 		find a way to fix Int128 and Slopes...
 * 		fix multi declarations
 * 		fix internal
 * 		check capacity
 * 		check switches/break
 * 		check occurrences of IntPoint.equals()
 * 		fix struct vs class issues (structs are: DoublePoint, Int128, IntPoint, IntRect)
 * 			replaced structs assignments with clone() or copyFrom()
 * 
 */

package hxClipper;

import haxe.ds.ArraySort;
import haxe.Int32;
import haxe.Int64;
import hxClipper.Clipper.ClipperBase;
import hxClipper.Clipper.DoublePoint;
import hxClipper.Clipper.Int128;
import hxClipper.Clipper.IntPoint;

using haxe.Int64;
using hxClipper.Clipper.Int128;
using hxClipper.Clipper.InternalTools;

//use_int32: When enabled 32bit ints are used instead of 64bit ints. This
//improve performance but coordinate values are limited to the range +/- 46340
//#define use_int32

//use_xyz: adds a Z member to IntPoint. Adds a minor cost to performance.
//#define use_xyz

//use_lines: Enables open path clipping. Adds a very minor cost to performance.
//#define use_lines



//using System.Text;          //for Int128.AsString() & StringBuilder
//using System.IO;            //debugging with streamReader & StreamWriter
//using System.Windows.Forms; //debugging to clipboard


#if use_int32
typedef CInt = Int;
#else
typedef CInt = Int64;
#end

typedef Path = Array<IntPoint>;
typedef Paths = Array<Array<IntPoint>>;

class DoublePoint 
{
	public var X:Float;
	public var Y:Float;

	public function new(x:Float = 0, y:Float = 0) {
		this.X = x;
		this.Y = y;
	}
	
	public function clone() {
		return new DoublePoint(this.X, this.Y);
	}
	
	static public function fromDoublePoint(dp:DoublePoint) {
		return dp.clone();
	}
	
	static public function fromIntPoint(ip:IntPoint) {
		return new DoublePoint(ip.X, ip.Y);
	}
	
	public function toString():String {
		return '(x:$X, y:$Y)';
	}
}


//------------------------------------------------------------------------------
// PolyTree & PolyNode classes
//------------------------------------------------------------------------------

class PolyTree extends PolyNode 
{
	/*internal*/ public var m_AllPolys:Array<PolyNode> = new Array<PolyNode>();

	//The GC probably handles this cleanup more efficiently ...
	//~PolyTree(){Clear();}

	public function Clear():Void {
		for (i in 0...m_AllPolys.length) {
			m_AllPolys[i] = null;
		}
		m_AllPolys.clear();
		m_Childs.clear();
	}

	public function GetFirst():PolyNode {
		if (m_Childs.length > 0) return m_Childs[0];
		else return null;
	}

	public var Total(get, never):Int;
	function get_Total():Int {
		var result = m_AllPolys.length;
		//with negative offsets, ignore the hidden outer polygon ...
		if (result > 0 && m_Childs[0] != m_AllPolys[0]) result--;
		return result;
	}

}

class PolyNode 
{
	/*internal*/ public var m_Parent:PolyNode;
	/*internal*/ public var m_polygon:Path = new Path();
	/*internal*/ public var m_Index:Int;
	/*internal*/ public var m_jointype:JoinType;
	/*internal*/ public var m_endtype:EndType;
	/*internal*/ public var m_Childs:Array<PolyNode> = new Array<PolyNode>();

	function IsHoleNode():Bool {
		var result = true;
		var node:PolyNode = m_Parent;
		while (node != null) {
			result = !result;
			node = node.m_Parent;
		}
		return result;
	}

	public var ChildCount(get, never):Int;
	function get_ChildCount():Int {
		return m_Childs.length;
	}

	public var Contour(get, never):Path;
	function get_Contour():Path {
		return m_polygon;
	}

	/*internal*/ public function AddChild(Child:PolyNode):Void {
		var cnt = m_Childs.length;
		m_Childs.push(Child);
		Child.m_Parent = this;
		Child.m_Index = cnt;
	}

	public function GetNext():PolyNode {
		if (m_Childs.length > 0) return m_Childs[0];
		else return GetNextSiblingUp();
	}

	/*internal*/ public function GetNextSiblingUp():PolyNode {
		if (m_Parent == null) return null;
		else if (m_Index == m_Parent.m_Childs.length - 1) return m_Parent.GetNextSiblingUp();
		else return m_Parent.m_Childs[m_Index + 1];
	}

	public var Childs(get, never):Array<PolyNode>;
	function get_Childs():Array<PolyNode> {
		return m_Childs;
	}

	public var Parent(get, null):PolyNode;
	public function get_Parent():PolyNode {
		return m_Parent;
	}

	public var IsHole(get, never):Bool;
	function get_IsHole():Bool {
		return IsHoleNode();
	}

	/*TODO: check why of this property*/
	public var IsOpen(default, default):Bool;
}


//------------------------------------------------------------------------------
// Int128 struct (enables safe math on signed 64bit integers)
// eg Int128 val1((Int64)9223372036854775807); //ie 2^63 -1
//    Int128 val2((Int64)9223372036854775807);
//    Int128 val3 = val1 * val2;
//    val3.ToString => "85070591730234615847396907784232501249" (8.5e+37)
//------------------------------------------------------------------------------

/*internal*/ class Int128 {
	var hi:Int64;
	var lo:Int64;	// this will make use of unsigned versions of ops

	static var zero64:Int64 = Int64.make(0, 0);
	static var one64:Int64 = Int64.make(0, 1);
	static inline var shift64:Float = 18446744073709551616.0; //2^64

	public function new(hi:Int64, lo:Int64) {
		this.lo = lo;
		this.hi = hi;
	}

	public function IsNeg():Bool {
		return hi.compare(zero64) < 0;
	}

	static public function compare(a:Int128, b:Int128):Int {
		if (a.hi != b.hi) return a.hi.compare(b.hi);
		else return a.lo.ucompare(b.lo);
	}
	
	static public function add(lhs:Int128, rhs:Int128):Int128 {
		lhs.hi = lhs.hi.add(rhs.hi);
		lhs.lo = lhs.lo.add(rhs.lo);
		if (lhs.lo.ucompare(rhs.lo) < 0) lhs.hi.add(one64);
		return lhs;
	}

	static public function sub(lhs:Int128, rhs:Int128):Int128 {
		return lhs.add(rhs.neg());
	}

	static public function neg(val:Int128):Int128 {
		if (val.lo.ucompare(zero64) == 0) return new Int128(val.hi.neg(), Int64.ofInt(0));
		else return new Int128(val.hi.neg(), val.lo.neg().add(one64));
	}

	public function toFloat():Float {
		var res:Float = 0;
		if (hi.compare(zero64) < 0) {
			if (lo.compare(zero64) == 0) res = Std.parseFloat(hi.toStr()) * shift64;
			else res = -(lo.neg().toInt() + Std.parseFloat(hi.neg().toStr()) * shift64);
		} else res = (lo.toInt() + Std.parseFloat(hi.toStr()) * shift64);
		return res;
	}

	//nb: Constructing two new Int128 objects every time we want to multiply longs  
	//is slow. So, although calling the Int128Mul method doesn't look as clean, the 
	//code runs significantly faster than if we'd used the * operator.

	static public function mul(lhs:Int64, rhs:Int64):Int128 {
		var negate = (lhs.isNeg()) != (rhs.isNeg());
		if (lhs.isNeg()) lhs = lhs.neg();
		if (rhs.isNeg()) rhs = rhs.neg();
		var int1Hi:Int64 = lhs.ushr(32);
		var int1Lo:Int64 = lhs.and(Int64.ofInt(0xFFFFFFFF));
		var int2Hi:Int64 = rhs.ushr(32);
		var int2Lo:Int64 = rhs.and(Int64.ofInt(0xFFFFFFFF));

		//nb: see comments in clipper.pas
		var a:Int64 = Int64.mul(int1Hi, int2Hi);
		var b:Int64 = Int64.mul(int1Lo, int2Lo);
		var c:Int64 = Int64.mul(int1Hi, int2Lo).add(Int64.mul(int1Lo, int2Hi));

		var hi:Int64 = (a.add(c.ushr(32)));
		var lo:Int64 = c.shl(32).add(b);

		if (lo.ucompare(b) < 0) hi = hi.add(one64);
		var result:Int128 = new Int128(hi, lo);
		if (negate) result = result.neg();
		return result;
	}

}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

class IntPoint 
{
	public var X:CInt;
	public var Y:CInt;
#if use_xyz 
	public var Z:CInt;

	public function new(x:CInt = 0, y:CInt = 0, z:CInt = 0) {
		this.X = x;
		this.Y = y;
		this.Z = z;
	}

	public function clone() {
		return new IntPoint(this.X, this.Y, this.Z);
	}
	
	public function copyFrom(ip:IntPoint):Void {
		this.X = ip.X;
		this.Y = ip.Y;
		this.Z = ip.Z;
	}
	
	public function toString():String {
		return '(x:$X, y:$Y, z:$Z)';
	}
	
	// TODO: casts?
	static public function fromFloats(x:Float, y:Float, z:Float = 0) {
		return new IntPoint(Std.int(x), Std.int(y), Std.int(z));
	}

	static public function fromDoublePoint(dp:DoublePoint) {
		return fromFloats(dp.X, dp.Y, 0);
	}

	static public function fromIntPoint(pt:IntPoint) {
		return pt.clone();
	}
#else 
	public function new(x:CInt = 0, y:CInt = 0) {
		this.X = x;
		this.Y = y;
	}

	public function clone() {
		return new IntPoint(this.X, this.Y);
	}
	
	public function toString():String {
		return '(x:$X, y:$Y)';
	}
	
	public function copyFrom(ip:IntPoint):Void {
		this.X = ip.X;
		this.Y = ip.Y;
	}
	
	static public function fromFloats(x:Float, y:Float) {
		return new IntPoint(Std.int(x), Std.int(y));
	}

	static public function fromDoublePoint(dp:DoublePoint) {
		return fromFloats(dp.X, dp.Y);
	}

	static public function fromIntPoint(pt:IntPoint) {
		return pt.clone();
	}
#end

	public function equals(ip:IntPoint):Bool {
		return this.X == ip.X && this.Y == ip.Y;
	}
	
	/* TODO: removed IntPoint ops
	public static bool operator == (IntPoint a, IntPoint b) {
		return a.X == b.X && a.Y == b.Y;
	}

	public static bool operator != (IntPoint a, IntPoint b) {
		return a.X != b.X || a.Y != b.Y;
	}

	public override bool Equals(object obj) {
		if (obj == null) return false;
		if (obj is IntPoint) {
			IntPoint a = (IntPoint) obj;
			return (X == a.X) && (Y == a.Y);
		} else return false;
	}

	public override int GetHashCode() {
		//simply prevents a compiler warning
		return base.GetHashCode();
	}*/

} // end struct IntPoint

class IntRect 
{
	public var left:CInt;
	public var top:CInt;
	public var right:CInt;
	public var bottom:CInt;

	public function new(l:CInt, t:CInt, r:CInt, b:CInt) {
		this.left = l;
		this.top = t;
		this.right = r;
		this.bottom = b;
	}
	
	public function clone(ir:IntRect):IntRect {
		return new IntRect(left, top, right, bottom);
	}
}

enum ClipType {
	ctIntersection; ctUnion; ctDifference; ctXor;
}

enum PolyType {
	ptSubject; ptClip;
}

//By far the most widely used winding rules for polygon filling are
//EvenOdd & NonZero (GDI, GDI+, XLib, OpenGL, Cairo, AGG, Quartz, SVG, Gr32)
//Others rules include Positive, Negative and ABS_GTR_EQ_TWO (only in OpenGL)
//see http://glprogramming.com/red/chapter11.html
enum PolyFillType {
	pftEvenOdd; pftNonZero; pftPositive; pftNegative;
}

enum JoinType {
	jtSquare; jtRound; jtMiter;
}
enum EndType {
	etClosedPolygon; etClosedLine; etOpenButt; etOpenSquare; etOpenRound;
}

/*internal*/ enum EdgeSide {
	esLeft; esRight;
}
/*internal*/ enum Direction {
	dRightToLeft; dLeftToRight;
}

/*internal*/ enum NodeType {
	ntAny; ntOpen; ntClosed;
}

/*internal*/ class TEdge 
{
	/*internal*/ public var Bot:IntPoint = new IntPoint();
	/*internal*/ public var Curr:IntPoint = new IntPoint();
	/*internal*/ public var Top:IntPoint = new IntPoint();
	/*internal*/ public var Delta:IntPoint = new IntPoint();
	/*internal*/ public var Dx:Float;
	/*internal*/ public var PolyTyp:PolyType;
	/*internal*/ public var Side:EdgeSide;
	/*internal*/ public var WindDelta:Int; //1 or -1 depending on winding direction
	/*internal*/ public var WindCnt:Int;
	/*internal*/ public var WindCnt2:Int; //winding count of the opposite polytype
	/*internal*/ public var OutIdx:Int;
	/*internal*/ public var Next:TEdge;
	/*internal*/ public var Prev:TEdge;
	/*internal*/ public var NextInLML:TEdge;
	/*internal*/ public var NextInAEL:TEdge;
	/*internal*/ public var PrevInAEL:TEdge;
	/*internal*/ public var NextInSEL:TEdge;
	/*internal*/ public var PrevInSEL:TEdge;
	
	/*internal*/ public function new() { }
	
	public function toString():String {
		return 'TE(curr:${Curr.toString()}, bot:${Bot.toString()}, top:${Top.toString()}, dx:$Dx)';
	}
}

class IntersectNode 
{
	/*internal*/ public var Edge1:TEdge;
	/*internal*/ public var Edge2:TEdge;
	/*internal*/ public var Pt:IntPoint = new IntPoint();
	
	/*internal*/ public function new() { }
}

/* TODO: fix the comparer (look into ListSort, or change List with Array
class MyIntersectNodeSort: IComparer < IntersectNode > {
	public int Compare(IntersectNode node1, IntersectNode node2) {
		cInt i = node2.Pt.Y - node1.Pt.Y;
		if (i > 0) return 1;
		else if (i < 0) return -1;
		else return 0;
	}
}*/

/*internal*/ class LocalMinima 
{
	/*internal*/ public var Y:CInt;
	/*internal*/ public var LeftBound:TEdge;
	/*internal*/ public var RightBound:TEdge;
	/*internal*/ public var Next:LocalMinima;
	
	/*internal*/ public function new() { }
}

/*internal*/ class Scanbeam 
{
	/*internal*/ public var Y:CInt;
	/*internal*/ public var Next:Scanbeam;
	
	/*internal*/ public function new() { }
}

/*internal*/ class OutRec 
{
	/*internal*/ public var Idx:Int;
	/*internal*/ public var IsHole:Bool;
	/*internal*/ public var IsOpen:Bool;
	/*internal*/ public var FirstLeft:OutRec; //see comments in clipper.pas
	/*internal*/ public var Pts:OutPt;
	/*internal*/ public var BottomPt:OutPt;
	/*internal*/ public var polyNode:PolyNode; //TODO: check name here
	
	/*internal*/ public function new() { }
}

/*internal*/ class OutPt 
{
	/*internal*/ public var Idx:Int;
	/*internal*/ public var Pt:IntPoint = new IntPoint();
	/*internal*/ public var Next:OutPt;
	/*internal*/ public var Prev:OutPt;
	
	/*internal*/ public function new() { }
}

/*internal*/ class Join 
{
	/*internal*/ public var OutPt1:OutPt;
	/*internal*/ public var OutPt2:OutPt;
	/*internal*/ public var OffPt:IntPoint = new IntPoint();
	
	/*internal*/ public function new() { }
}

class ClipperBase 
{
	// TODO: refactor to uppercase
	inline static public var horizontal:Float = -3.4E+38;
	inline static public var Skip:Int = -2;
	inline static public var Unassigned:Int = -1;
	inline static public var tolerance:Float = 1.0E-20;
	
	// TODO: camelcase
	/*internal*/ public static function near_zero(val:Float):Bool {
		return (val > -tolerance) && (val < tolerance);
	}

#if use_int32 
	inline static public var loRange:CInt = 0x7FFF;
	inline static public var hiRange:CInt = 0x7FFF;
#else 
	inline static public var loRange:CInt = 0x3FFFFFFF;
	inline static public var hiRange:CInt = 0x3FFFFFFFFFFFFFFFL;
#end

	/*internal*/ public var m_MinimaList:LocalMinima;
	/*internal*/ public var m_CurrentLM:LocalMinima;
	/*internal*/ public var m_edges:Array<Array<TEdge>> = new Array<Array<TEdge>>();
	/*internal*/ public var m_UseFullRange:Bool;
	/*internal*/ public var m_HasOpenPaths:Bool;

	//------------------------------------------------------------------------------

	//TODO: check this prop
	public var PreserveCollinear(default, default):Bool;
	//------------------------------------------------------------------------------

	/*TODO: check swap
	public function Swap(ref cInt val1, ref cInt val2):Void {
		cInt tmp = val1;
		val1 = val2;
		val2 = tmp;
	}*/
	//------------------------------------------------------------------------------

	/*internal*/ static public function IsHorizontal(e:TEdge):Bool {
		return e.Delta.Y == 0;
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function PointIsVertex(pt:IntPoint, pp:OutPt):Bool {
		var pp2:OutPt = pp;
		do {
			if (pp2.Pt.equals(pt)) return true;
			pp2 = pp2.Next;
		}
		while (pp2 != pp);
		return false;
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function PointOnLineSegment(pt:IntPoint, linePt1:IntPoint, linePt2:IntPoint, UseFullRange:Bool):Bool {
	#if !use_int32
		if (UseFullRange) return ((pt.X == linePt1.X) && (pt.Y == linePt1.Y)) || ((pt.X == linePt2.X) && (pt.Y == linePt2.Y)) 
								 || (((pt.X > linePt1.X) == (pt.X < linePt2.X)) && ((pt.Y > linePt1.Y) == (pt.Y < linePt2.Y)) 
								 && ((Int128.Int128Mul((pt.X - linePt1.X), (linePt2.Y - linePt1.Y)) == Int128.Int128Mul((linePt2.X - linePt1.X), (pt.Y - linePt1.Y)))));
		else 
	#else
		return ((pt.X == linePt1.X) && (pt.Y == linePt1.Y)) || ((pt.X == linePt2.X) && (pt.Y == linePt2.Y)) 
			   || (((pt.X > linePt1.X) == (pt.X < linePt2.X)) && ((pt.Y > linePt1.Y) == (pt.Y < linePt2.Y)) 
			   && ((pt.X - linePt1.X) * (linePt2.Y - linePt1.Y) == (linePt2.X - linePt1.X) * (pt.Y - linePt1.Y)));
	#end
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function PointOnPolygon(pt:IntPoint, pp:OutPt, UseFullRange:Bool):Bool {
		var pp2:OutPt = pp;
		while (true) {
			if (PointOnLineSegment(pt, pp2.Pt, pp2.Next.Pt, UseFullRange)) return true;
			pp2 = pp2.Next;
			if (pp2 == pp) break;
		}
		return false;
	}
	//------------------------------------------------------------------------------

	/* TODO: fix these Int128*/
	/*internal*/ static public function SlopesEqual(e1:TEdge, e2:TEdge, UseFullRange:Bool):Bool {
	#if !use_int32	
		if (UseFullRange) return Int128.mul(e1.Delta.Y, e2.Delta.X) == Int128.mul(e1.Delta.X, e2.Delta.Y);
		else
	#else 
		return /*(cInt)*/(e1.Delta.Y) * (e2.Delta.X) == /*(cInt)*/(e1.Delta.X) * (e2.Delta.Y);
	#end
	}
	//------------------------------------------------------------------------------

	/*protected*/ static function SlopesEqual3(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint, UseFullRange:Bool):Bool {
	#if !use_int32	
		if (UseFullRange) return Int128.Int128Mul(pt1.Y - pt2.Y, pt2.X - pt3.X) == Int128.Int128Mul(pt1.X - pt2.X, pt2.Y - pt3.Y);
		else 
	#else
		return /*(cInt)*/(pt1.Y - pt2.Y) * (pt2.X - pt3.X) - /*(cInt)*/(pt1.X - pt2.X) * (pt2.Y - pt3.Y) == 0;
	#end
	}
	//------------------------------------------------------------------------------

	/*protected*/ static function SlopesEqual4(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint, pt4:IntPoint, UseFullRange:Bool):Bool {
	#if !use_int32	
		if (UseFullRange) return Int128.Int128Mul(pt1.Y - pt2.Y, pt3.X - pt4.X) == Int128.Int128Mul(pt1.X - pt2.X, pt3.Y - pt4.Y);
		else 
	#else
		return /*(cInt)*/(pt1.Y - pt2.Y) * (pt3.X - pt4.X) - /*(cInt)*/(pt1.X - pt2.X) * (pt3.Y - pt4.Y) == 0;
	#end
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function new() //constructor (nb: no external instantiation)
	{
		m_MinimaList = null;
		m_CurrentLM = null;
		m_UseFullRange = false;
		m_HasOpenPaths = false;
	}
	//------------------------------------------------------------------------------

	public function Clear():Void {
		DisposeLocalMinimaList();
		for (i in 0...m_edges.length) {
			for (j in 0...m_edges[i].length) {
				m_edges[i][j] = null;
			}
			m_edges[i].clear();
		}
		m_edges.clear();
		m_UseFullRange = false;
		m_HasOpenPaths = false;
	}
	//------------------------------------------------------------------------------

	function DisposeLocalMinimaList():Void {
		while (m_MinimaList != null) {
			var tmpLm:LocalMinima = m_MinimaList.Next;
			m_MinimaList = null;
			m_MinimaList = tmpLm;
		}
		m_CurrentLM = null;
	}
	//------------------------------------------------------------------------------

	// TODO: check ref
	function RangeTest(Pt:IntPoint, /*ref*/ useFullRange:Bool):Void {
		if (useFullRange) {
			if (Pt.X > hiRange || Pt.Y > hiRange || -Pt.X > hiRange || -Pt.Y > hiRange) 
				throw new ClipperException("Coordinate outside allowed range");
		} else if (Pt.X > loRange || Pt.Y > loRange || -Pt.X > loRange || -Pt.Y > loRange) {
			useFullRange = true;
			RangeTest(Pt, /*ref*/ useFullRange);
		}
	}
	//------------------------------------------------------------------------------

	function InitEdge(e:TEdge, eNext:TEdge, ePrev:TEdge, pt:IntPoint):Void {
		e.Next = eNext;
		e.Prev = ePrev;
		e.Curr.copyFrom(pt);
		e.OutIdx = Unassigned;
	}
	//------------------------------------------------------------------------------

	function InitEdge2(e:TEdge, polyType:PolyType):Void {
		if (e.Curr.Y >= e.Next.Curr.Y) {
			e.Bot.copyFrom(e.Curr);
			e.Top.copyFrom(e.Next.Curr);
		} else {
			e.Top.copyFrom(e.Curr);
			e.Bot.copyFrom(e.Next.Curr);
		}
		SetDx(e);
		e.PolyTyp = polyType;
	}
	//------------------------------------------------------------------------------

	function FindNextLocMin(E:TEdge):TEdge {
		var E2:TEdge;
		while (true) {
			while (!E.Bot.equals(E.Prev.Bot) || E.Curr.equals(E.Top)) E = E.Next;
			if (E.Dx != horizontal && E.Prev.Dx != horizontal) break;
			while (E.Prev.Dx == horizontal) E = E.Prev;
			E2 = E;
			while (E.Dx == horizontal) E = E.Next;
			if (E.Top.Y == E.Prev.Bot.Y) continue; //ie just an intermediate horz.
			if (E2.Prev.Bot.X < E.Bot.X) E = E2;
			break;
		}
		return E;
	}
	//------------------------------------------------------------------------------

	function ProcessBound(E:TEdge, LeftBoundIsForward:Bool):TEdge {
		var EStart:TEdge, Result = E;
		var Horz:TEdge;

		if (Result.OutIdx == Skip) {
			//check if there are edges beyond the skip edge in the bound and if so
			//create another LocMin and calling ProcessBound once more ...
			E = Result;
			if (LeftBoundIsForward) {
				while (E.Top.Y == E.Next.Bot.Y) E = E.Next;
				while (E != Result && E.Dx == horizontal) E = E.Prev;
			} else {
				while (E.Top.Y == E.Prev.Bot.Y) E = E.Prev;
				while (E != Result && E.Dx == horizontal) E = E.Next;
			}
			if (E == Result) {
				if (LeftBoundIsForward) Result = E.Next;
				else Result = E.Prev;
			} else {
				//there are more edges in the bound beyond result starting with E
				if (LeftBoundIsForward) E = Result.Next;
				else E = Result.Prev;
				var locMin = new LocalMinima();
				locMin.Next = null;
				locMin.Y = E.Bot.Y;
				locMin.LeftBound = null;
				locMin.RightBound = E;
				E.WindDelta = 0;
				Result = ProcessBound(E, LeftBoundIsForward);
				InsertLocalMinima(locMin);
			}
			return Result;
		}

		if (E.Dx == horizontal) {
			//We need to be careful with open paths because this may not be a
			//true local minima (ie E may be following a skip edge).
			//Also, consecutive horz. edges may start heading left before going right.
			if (LeftBoundIsForward) EStart = E.Prev;
			else EStart = E.Next;
			if (EStart.OutIdx != Skip) {
				if (EStart.Dx == horizontal) //ie an adjoining horizontal skip edge
				{
					if (EStart.Bot.X != E.Bot.X && EStart.Top.X != E.Bot.X) ReverseHorizontal(E);
				} else if (EStart.Bot.X != E.Bot.X) ReverseHorizontal(E);
			}
		}

		EStart = E;
		if (LeftBoundIsForward) {
			while (Result.Top.Y == Result.Next.Bot.Y && Result.Next.OutIdx != Skip)
			Result = Result.Next;
			if (Result.Dx == horizontal && Result.Next.OutIdx != Skip) {
				//nb: at the top of a bound, horizontals are added to the bound
				//only when the preceding edge attaches to the horizontal's left vertex
				//unless a Skip edge is encountered when that becomes the top divide
				Horz = Result;
				while (Horz.Prev.Dx == horizontal) Horz = Horz.Prev;
				if (Horz.Prev.Top.X == Result.Next.Top.X) {
					if (!LeftBoundIsForward) Result = Horz.Prev;
				} else if (Horz.Prev.Top.X > Result.Next.Top.X) Result = Horz.Prev;
			}
			while (E != Result) {
				E.NextInLML = E.Next;
				if (E.Dx == horizontal && E != EStart && E.Bot.X != E.Prev.Top.X) ReverseHorizontal(E);
				E = E.Next;
			}
			if (E.Dx == horizontal && E != EStart && E.Bot.X != E.Prev.Top.X) ReverseHorizontal(E);
			Result = Result.Next; //move to the edge just beyond current bound
		} else {
			while (Result.Top.Y == Result.Prev.Bot.Y && Result.Prev.OutIdx != Skip)
			Result = Result.Prev;
			if (Result.Dx == horizontal && Result.Prev.OutIdx != Skip) {
				Horz = Result;
				while (Horz.Next.Dx == horizontal) Horz = Horz.Next;
				if (Horz.Next.Top.X == Result.Prev.Top.X) {
					if (!LeftBoundIsForward) Result = Horz.Next;
				} else if (Horz.Next.Top.X > Result.Prev.Top.X) Result = Horz.Next;
			}

			while (E != Result) {
				E.NextInLML = E.Prev;
				if (E.Dx == horizontal && E != EStart && E.Bot.X != E.Next.Top.X) ReverseHorizontal(E);
				E = E.Prev;
			}
			if (E.Dx == horizontal && E != EStart && E.Bot.X != E.Next.Top.X) ReverseHorizontal(E);
			Result = Result.Prev; //move to the edge just beyond current bound
		}
		return Result;
	}
	//------------------------------------------------------------------------------


	public function AddPath(pg:Path, polyType:PolyType, Closed:Bool):Bool {
	#if use_lines
		if (!Closed && polyType == PolyType.ptClip) throw new ClipperException("AddPath: Open paths must be subject.");
	#else 
		if (!Closed) throw new ClipperException("AddPath: Open paths have been disabled.");
	#end
		//TODO: why the cast
		var highI = /*(int)*/ pg.length - 1;
		if (Closed) while (highI > 0 && (pg[highI].equals(pg[0]))) --highI;
		while (highI > 0 && (pg[highI].equals(pg[highI - 1]))) --highI;
		if ((Closed && highI < 2) || (!Closed && highI < 1)) return false;

		//create a new edge array ...
		var edges = new Array<TEdge>(/*TODO:highI + 1*/);
		for (i in 0...highI + 1) edges.push(new TEdge());

		var IsFlat = true;

		//1. Basic (first) edge initialization ...
		edges[1].Curr.copyFrom(pg[1]);
		// TODO: check refs
		RangeTest(pg[0], /*ref*/ m_UseFullRange);
		RangeTest(pg[highI], /*ref*/ m_UseFullRange);
		InitEdge(edges[0], edges[1], edges[highI], pg[0]);
		InitEdge(edges[highI], edges[0], edges[highI - 1], pg[highI]);
		// TODO: check loop
		var i = highI - 1;
		while (i >= 1) {
			RangeTest(pg[i], /*ref*/ m_UseFullRange);
			InitEdge(edges[i], edges[i + 1], edges[i - 1], pg[i]);
			--i;
		}
		var eStart:TEdge = edges[0];

		//2. Remove duplicate vertices, and (when closed) collinear edges ...
		var E:TEdge = eStart, eLoopStop:TEdge = eStart;
		while (true) {
			//nb: allows matching start and end points when not Closed ...
			if (E.Curr.equals(E.Next.Curr) && (Closed || E.Next != eStart)) {
				if (E == E.Next) break;
				if (E == eStart) eStart = E.Next;
				E = RemoveEdge(E);
				eLoopStop = E;
				continue;
			}
			if (E.Prev == E.Next) break; //only two vertices
			else if (Closed && ClipperBase.SlopesEqual3(E.Prev.Curr, E.Curr, E.Next.Curr, m_UseFullRange) 
					 && (!PreserveCollinear || !Pt2IsBetweenPt1AndPt3(E.Prev.Curr, E.Curr, E.Next.Curr))) 
			{
				//Collinear edges are allowed for open paths but in closed paths
				//the default is to merge adjacent collinear edges into a single edge.
				//However, if the PreserveCollinear property is enabled, only overlapping
				//collinear edges (ie spikes) will be removed from closed paths.
				if (E == eStart) eStart = E.Next;
				E = RemoveEdge(E);
				E = E.Prev;
				eLoopStop = E;
				continue;
			}
			E = E.Next;
			if ((E == eLoopStop) || (!Closed && E.Next == eStart)) break;
		}

		if ((!Closed && (E == E.Next)) || (Closed && (E.Prev == E.Next))) return false;

		if (!Closed) {
			m_HasOpenPaths = true;
			eStart.Prev.OutIdx = Skip;
		}

		//3. Do second stage of edge initialization ...
		E = eStart;
		do {
			InitEdge2(E, polyType);
			E = E.Next;
			if (IsFlat && E.Curr.Y != eStart.Curr.Y) IsFlat = false;
		} while (E != eStart);

		//4. Finally, add edge bounds to LocalMinima list ...

		//Totally flat paths must be handled differently when adding them
		//to LocalMinima list to avoid endless loops etc ...
		if (IsFlat) {
			if (Closed) return false;
			E.Prev.OutIdx = Skip;
			var locMin = new LocalMinima();
			locMin.Next = null;
			locMin.Y = E.Bot.Y;
			locMin.LeftBound = null;
			locMin.RightBound = E;
			locMin.RightBound.Side = EdgeSide.esRight;
			locMin.RightBound.WindDelta = 0;
			while (true) {
				if (E.Bot.X != E.Prev.Top.X) ReverseHorizontal(E);
				if (E.Next.OutIdx == Skip) break;
				E.NextInLML = E.Next;
				E = E.Next;
			}
			InsertLocalMinima(locMin);
			m_edges.push(edges);
			return true;
		}

		m_edges.push(edges);
		var leftBoundIsForward:Bool;
		var EMin:TEdge = null;

		//workaround to avoid an endless loop in the while loop below when
		//open paths have matching start and end points ...
		if (E.Prev.Bot.equals(E.Prev.Top)) E = E.Next;

		while (true) {
			E = FindNextLocMin(E);
			if (E == EMin) break;
			else if (EMin == null) EMin = E;

			//E and E.Prev now share a local minima (left aligned if horizontal).
			//Compare their slopes to find which starts which bound ...
			var locMin = new LocalMinima();
			locMin.Next = null;
			locMin.Y = E.Bot.Y;
			if (E.Dx < E.Prev.Dx) {
				locMin.LeftBound = E.Prev;
				locMin.RightBound = E;
				leftBoundIsForward = false; //Q.nextInLML = Q.prev
			} else {
				locMin.LeftBound = E;
				locMin.RightBound = E.Prev;
				leftBoundIsForward = true; //Q.nextInLML = Q.next
			}
			locMin.LeftBound.Side = EdgeSide.esLeft;
			locMin.RightBound.Side = EdgeSide.esRight;

			if (!Closed) locMin.LeftBound.WindDelta = 0;
			else if (locMin.LeftBound.Next == locMin.RightBound) locMin.LeftBound.WindDelta = -1;
			else locMin.LeftBound.WindDelta = 1;
			locMin.RightBound.WindDelta = -locMin.LeftBound.WindDelta;

			E = ProcessBound(locMin.LeftBound, leftBoundIsForward);
			if (E.OutIdx == Skip) E = ProcessBound(E, leftBoundIsForward);

			var E2:TEdge = ProcessBound(locMin.RightBound, !leftBoundIsForward);
			if (E2.OutIdx == Skip) E2 = ProcessBound(E2, !leftBoundIsForward);

			if (locMin.LeftBound.OutIdx == Skip) locMin.LeftBound = null;
			else if (locMin.RightBound.OutIdx == Skip) locMin.RightBound = null;
			InsertLocalMinima(locMin);
			if (!leftBoundIsForward) E = E2;
		}
		return true;

	}
	//------------------------------------------------------------------------------

	public function AddPaths(ppg:Paths, polyType:PolyType, closed:Bool):Bool {
		var result = false;
		for (i in 0...ppg.length) {
			if (AddPath(ppg[i], polyType, closed)) result = true;
		}
		return result;
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function Pt2IsBetweenPt1AndPt3(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint):Bool {
		if ((pt1.equals(pt3)) || (pt1.equals(pt2)) || (pt3.equals(pt2))) return false;
		else if (pt1.X != pt3.X) return (pt2.X > pt1.X) == (pt2.X < pt3.X);
		else return (pt2.Y > pt1.Y) == (pt2.Y < pt3.Y);
	}
	//------------------------------------------------------------------------------

	function RemoveEdge(e:TEdge):TEdge {
		//removes e from double_linked_list (but without removing from memory)
		e.Prev.Next = e.Next;
		e.Next.Prev = e.Prev;
		var result = e.Next;
		e.Prev = null; //flag as removed (see ClipperBase.Clear)
		return result;
	}
	//------------------------------------------------------------------------------

	function SetDx(e:TEdge):Void {
		e.Delta.X = (e.Top.X - e.Bot.X);
		e.Delta.Y = (e.Top.Y - e.Bot.Y);
		if (e.Delta.Y == 0) e.Dx = horizontal;
		else {	// TODO: check cast to float
			var deltaX:Float = e.Delta.X;
			e.Dx = deltaX / (e.Delta.Y);
		}
	}
	//---------------------------------------------------------------------------

	function InsertLocalMinima(newLm:LocalMinima):Void {
		if (m_MinimaList == null) {
			m_MinimaList = newLm;
		} else if (newLm.Y >= m_MinimaList.Y) {
			newLm.Next = m_MinimaList;
			m_MinimaList = newLm;
		} else {
			var tmpLm:LocalMinima = m_MinimaList;
			// TODO: check this loop
			while (tmpLm.Next != null && (newLm.Y < tmpLm.Next.Y)) {
				tmpLm = tmpLm.Next;
			}
			newLm.Next = tmpLm.Next;
			tmpLm.Next = newLm;
		}
	}
	//------------------------------------------------------------------------------

	function PopLocalMinima():Void {
		if (m_CurrentLM == null) return;
		m_CurrentLM = m_CurrentLM.Next;
	}
	//------------------------------------------------------------------------------

	// TODO: check refs
	function ReverseHorizontal(e:TEdge):Void {
		//swap horizontal edges' top and bottom x's so they follow the natural
		//progression of the bounds - ie so their xbots will align with the
		//adjoining lower edge. [Helpful in the ProcessHorizontal() method.]
		var tmp = e.Top.X;
		e.Top.X = e.Bot.X;
		e.Bot.X = tmp;
	#if use_xyz 
		var tmp = e.Top.Z;
		e.Top.Z = e.Bot.Z;
		e.Bot.Z = tmp;
	#end
	}
	//------------------------------------------------------------------------------

	function Reset():Void {
		m_CurrentLM = m_MinimaList;
		if (m_CurrentLM == null) return; //ie nothing to process

		//reset all edges ...
		var lm:LocalMinima = m_MinimaList;
		while (lm != null) {
			var e:TEdge = lm.LeftBound;
			if (e != null) {
				e.Curr.copyFrom(e.Bot);
				e.Side = EdgeSide.esLeft;
				e.OutIdx = Unassigned;
			}
			e = lm.RightBound;
			if (e != null) {
				e.Curr.copyFrom(e.Bot);
				e.Side = EdgeSide.esRight;
				e.OutIdx = Unassigned;
			}
			lm = lm.Next;
		}
	}
	//------------------------------------------------------------------------------

	static public function GetBounds(paths:Paths):IntRect {
		var i:Int = 0, cnt:Int = paths.length;
		while (i < cnt && paths[i].length == 0) i++;
		if (i == cnt) return new IntRect(0, 0, 0, 0);
		var result = new IntRect(0, 0, 0, 0);
		result.left = paths[i][0].X;
		result.right = result.left;
		result.top = paths[i][0].Y;
		result.bottom = result.top;
		// TODO: check nested loops
		while (i < cnt) {
			for (j in 0...paths[i].length) {
				if (paths[i][j].X < result.left) result.left = paths[i][j].X;
				else if (paths[i][j].X > result.right) result.right = paths[i][j].X;
				if (paths[i][j].Y < result.top) result.top = paths[i][j].Y;
				else if (paths[i][j].Y > result.bottom) result.bottom = paths[i][j].Y;
			}
			i++;
		}
		return result;
	}

} //end ClipperBase

typedef IntersectNodeComparer = IntersectNode->IntersectNode->Int;

class Clipper extends ClipperBase 
{
	//InitOptions that can be passed to the constructor ...
	//TODO: check constants and constructor behaviour (maybe turn into enum)
	inline static public var ioReverseSolution:Int = 1;
	inline static public var ioStrictlySimple:Int = 2;
	inline static public var ioPreserveCollinear:Int = 4;

	var m_PolyOuts:Array<OutRec>;
	var m_ClipType:ClipType;
	var m_Scanbeam:Scanbeam;
	var m_ActiveEdges:TEdge;
	var m_SortedEdges:TEdge;
	var m_IntersectList:Array<IntersectNode>;
	var m_IntersectNodeComparer:IntersectNodeComparer;
	var m_ExecuteLocked:Bool;
	var m_ClipFillType:PolyFillType;
	var m_SubjFillType:PolyFillType;
	var m_Joins:Array<Join>;
	var m_GhostJoins:Array<Join>;
	var m_UsingPolyTree:Bool;
#if use_xyz 
	// TODO: ref here
	public delegate void ZFillCallback(bot1:IntPoint, top1:IntPoint, bot2:IntPoint, top2:IntPoint, /*ref*/ pt:IntPoint);
	public ZFillCallback ZFillFunction {
		get;
		set;
	}
#end
	// TODO: check constructor (:base()/super())
	public function new(InitOptions:Int = 0) { //constructor
		super();
		m_Scanbeam = null;
		m_ActiveEdges = null;
		m_SortedEdges = null;
		m_IntersectList = new Array<IntersectNode>();
		m_IntersectNodeComparer = compare;
		m_ExecuteLocked = false;
		m_UsingPolyTree = false;
		m_PolyOuts = new Array<OutRec>();
		m_Joins = new Array<Join>();
		m_GhostJoins = new Array<Join>();
		ReverseSolution = (ioReverseSolution & InitOptions) != 0;
		StrictlySimple = (ioStrictlySimple & InitOptions) != 0;
		PreserveCollinear = (ioPreserveCollinear & InitOptions) != 0;
	#if use_xyz 
		ZFillFunction = null;
	#end
	}
	//------------------------------------------------------------------------------

	static function compare(node1:IntersectNode, node2:IntersectNode):Int {
		var i:CInt = node2.Pt.Y - node1.Pt.Y;
		if (i > 0) return 1;
		else if (i < 0) return -1;
		else return 0;
	}
	
	function DisposeScanbeamList():Void {
		while (m_Scanbeam != null) {
			var sb2:Scanbeam = m_Scanbeam.Next;
			m_Scanbeam = null;
			m_Scanbeam = sb2;
		}
	}
	//------------------------------------------------------------------------------

	override function Reset():Void {
		super.Reset();
		m_Scanbeam = null;
		m_ActiveEdges = null;
		m_SortedEdges = null;
		var lm:LocalMinima = m_MinimaList;
		while (lm != null) {
			InsertScanbeam(lm.Y);
			lm = lm.Next;
		}
	}
	//------------------------------------------------------------------------------

	// TODO: check this prop
	public var ReverseSolution(default, default):Bool;
	//------------------------------------------------------------------------------

	public var StrictlySimple(default, default):Bool;
	//------------------------------------------------------------------------------

	function InsertScanbeam(Y:CInt):Void {
		if (m_Scanbeam == null) {
			m_Scanbeam = new Scanbeam();
			m_Scanbeam.Next = null;
			m_Scanbeam.Y = Y;
		} else if (Y > m_Scanbeam.Y) {
			var newSb = new Scanbeam();
			newSb.Y = Y;
			newSb.Next = m_Scanbeam;
			m_Scanbeam = newSb;
		} else {
			var sb2 = m_Scanbeam;
			while (sb2.Next != null && (Y <= sb2.Next.Y)) sb2 = sb2.Next;
			if (Y == sb2.Y) return; //ie ignores duplicates
			var newSb = new Scanbeam();
			newSb.Y = Y;
			newSb.Next = sb2.Next;
			sb2.Next = newSb;
		}
	}
	//------------------------------------------------------------------------------

	public function ExecutePaths(clipType:ClipType, solution:Paths, subjFillType:PolyFillType, clipFillType:PolyFillType):Bool {
		if (m_ExecuteLocked) return false;
		if (m_HasOpenPaths) throw new ClipperException("Error: PolyTree struct is needed for open path clipping.");

		m_ExecuteLocked = true;
		solution.clear();
		m_SubjFillType = subjFillType;
		m_ClipFillType = clipFillType;
		m_ClipType = clipType;
		m_UsingPolyTree = false;
		var succeeded:Bool = false;
		// TODO: finally?
		try {
			succeeded = ExecuteInternal();
			//build the return polygons ...
			if (succeeded) BuildResult(solution);
		} /*finally {
			DisposeAllPolyPts();
			m_ExecuteLocked = false;
		}*/
		DisposeAllPolyPts();
		m_ExecuteLocked = false;
		m_Joins.clear();
		m_GhostJoins.clear();
		return succeeded;
	}
	//------------------------------------------------------------------------------

	public function ExecutePolyTree(clipType:ClipType, polytree:PolyTree, subjFillType:PolyFillType, clipFillType:PolyFillType):Bool {
		if (m_ExecuteLocked) return false;
		m_ExecuteLocked = true;
		m_SubjFillType = subjFillType;
		m_ClipFillType = clipFillType;
		m_ClipType = clipType;
		m_UsingPolyTree = true;
		var succeeded:Bool = false;
		// TODO: finally?
		try {
			succeeded = ExecuteInternal();
			//build the return polygons ...
			if (succeeded) BuildResult2(polytree);
		} /*finally {
			DisposeAllPolyPts();
			m_ExecuteLocked = false;
		}*/
		DisposeAllPolyPts();
		m_ExecuteLocked = false;
		m_Joins.clear();
		m_GhostJoins.clear();
		return succeeded;
	}
	//------------------------------------------------------------------------------

	public function Execute(clipType:ClipType, solution:Dynamic):Bool {
		if (Std.is(solution, Paths)) {
			return ExecutePaths(clipType, solution, PolyFillType.pftEvenOdd, PolyFillType.pftEvenOdd);
		} else if (Std.is(solution, PolyTree)) {
			return ExecutePolyTree(clipType, solution, PolyFillType.pftEvenOdd, PolyFillType.pftEvenOdd);
		} else {
			throw new ClipperException("`solution` must be either a Paths or a PolyTree");
		}
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function FixHoleLinkage(outRec:OutRec):Void {
		//skip if an outermost polygon or
		//already already points to the correct FirstLeft ...
		if (outRec.FirstLeft == null || (outRec.IsHole != outRec.FirstLeft.IsHole && outRec.FirstLeft.Pts != null)) return;

		var orfl:OutRec = outRec.FirstLeft;
		// TODO: check while
		while (orfl != null && ((orfl.IsHole == outRec.IsHole) || orfl.Pts == null)) {
			orfl = orfl.FirstLeft;
		}
		outRec.FirstLeft = orfl;
	}
	//------------------------------------------------------------------------------

	function ExecuteInternal():Bool {
		try {
			Reset();
			if (m_CurrentLM == null) return false;

			var botY:CInt = PopScanbeam();
			do {
				InsertLocalMinimaIntoAEL(botY);
				m_GhostJoins.clear();
				ProcessHorizontals(false);
				if (m_Scanbeam == null) break;
				var topY:CInt = PopScanbeam();
				if (!ProcessIntersections(topY)) return false;
				ProcessEdgesAtTopOfScanbeam(topY);
				botY = topY;
			} while (m_Scanbeam != null || m_CurrentLM != null);

			//fix orientations ...
			for (i in 0...m_PolyOuts.length) {
				var outRec:OutRec = m_PolyOuts[i];
				if (outRec.Pts == null || outRec.IsOpen) continue;
				if ((outRec.IsHole.xor(ReverseSolution)) == (AreaOfOutRec(outRec) > 0)) ReversePolyPtLinks(outRec.Pts);
			}

			JoinCommonEdges();

			for (i in 0...m_PolyOuts.length) {
				var outRec:OutRec = m_PolyOuts[i];
				if (outRec.Pts != null && !outRec.IsOpen) FixupOutPolygon(outRec);
			}

			if (StrictlySimple) DoSimplePolygons();
			return true;
		}
		//catch { return false; }
		// TODO: finally? moved into caller
		/*finally {
			m_Joins.clear();
			m_GhostJoins.clear();
		}*/
	}
	//------------------------------------------------------------------------------

	function PopScanbeam():CInt {
		var Y:CInt = m_Scanbeam.Y;
		m_Scanbeam = m_Scanbeam.Next;
		return Y;
	}
	//------------------------------------------------------------------------------

	function DisposeAllPolyPts():Void {
		for (i in 0...m_PolyOuts.length) DisposeOutRec(i);
		m_PolyOuts.clear();
	}
	//------------------------------------------------------------------------------

	function DisposeOutRec(index:Int):Void {
		var outRec:OutRec = m_PolyOuts[index];
		outRec.Pts = null;
		outRec = null;
		m_PolyOuts[index] = null;
	}
	//------------------------------------------------------------------------------

	function AddJoin(Op1:OutPt, Op2:OutPt, OffPt:IntPoint):Void {
		var j = new Join();
		j.OutPt1 = Op1;
		j.OutPt2 = Op2;
		j.OffPt.copyFrom(OffPt);
		m_Joins.push(j);
	}
	//------------------------------------------------------------------------------

	function AddGhostJoin(Op:OutPt, OffPt:IntPoint):Void {
		var j = new Join();
		j.OutPt1 = Op;
		j.OffPt.copyFrom(OffPt);
		m_GhostJoins.push(j);
	}
	//------------------------------------------------------------------------------

#if use_xyz 
	// TODO: ref?
	/*internal*/ public function SetZ(/*ref*/ pt:IntPoint, e1:TEdge, e2:TEdge):Void {
		if (pt.Z != 0 || ZFillFunction == null) return;
		else if (pt.equals(e1.Bot)) pt.Z = e1.Bot.Z;
		else if (pt.equals(e1.Top)) pt.Z = e1.Top.Z;
		else if (pt.equals(e2.Bot)) pt.Z = e2.Bot.Z;
		else if (pt.equals(e2.Top)) pt.Z = e2.Top.Z;
		else ZFillFunction(e1.Bot, e1.Top, e2.Bot, e2.Top, ref pt);
	}
	//------------------------------------------------------------------------------
#end

	function InsertLocalMinimaIntoAEL(botY:CInt):Void {
		while (m_CurrentLM != null && (m_CurrentLM.Y == botY)) {
			var lb:TEdge = m_CurrentLM.LeftBound;
			var rb:TEdge = m_CurrentLM.RightBound;
			PopLocalMinima();

			var Op1:OutPt = null;
			if (lb == null) {
				InsertEdgeIntoAEL(rb, null);
				SetWindingCount(rb);
				if (IsContributing(rb)) 
					Op1 = AddOutPt(rb, rb.Bot);
			} else if (rb == null) {
				InsertEdgeIntoAEL(lb, null);
				SetWindingCount(lb);
				if (IsContributing(lb)) 
					Op1 = AddOutPt(lb, lb.Bot);
				InsertScanbeam(lb.Top.Y);
			} else {
				InsertEdgeIntoAEL(lb, null);
				InsertEdgeIntoAEL(rb, lb);
				SetWindingCount(lb);
				rb.WindCnt = lb.WindCnt;
				rb.WindCnt2 = lb.WindCnt2;
				if (IsContributing(lb)) 
					Op1 = AddLocalMinPoly(lb, rb, lb.Bot);
				InsertScanbeam(lb.Top.Y);
			}

			if (rb != null) {
				if (ClipperBase.IsHorizontal(rb)) AddEdgeToSEL(rb);
				else InsertScanbeam(rb.Top.Y);
			}

			if (lb == null || rb == null) continue;

			//if output polygons share an Edge with a horizontal rb, they'll need joining later ...
			if (Op1 != null && ClipperBase.IsHorizontal(rb) && m_GhostJoins.length > 0 && rb.WindDelta != 0) {
				for (i in 0...m_GhostJoins.length) {
					//if the horizontal Rb and a 'ghost' horizontal overlap, then convert
					//the 'ghost' join to a real join ready for later ...
					var j:Join = m_GhostJoins[i];
					if (HorzSegmentsOverlap(j.OutPt1.Pt.X, j.OffPt.X, rb.Bot.X, rb.Top.X)) AddJoin(j.OutPt1, Op1, j.OffPt);
				}
			}

			if (lb.OutIdx >= 0 && lb.PrevInAEL != null && lb.PrevInAEL.Curr.X == lb.Bot.X && lb.PrevInAEL.OutIdx >= 0 
				&& ClipperBase.SlopesEqual(lb.PrevInAEL, lb, m_UseFullRange) && lb.WindDelta != 0 && lb.PrevInAEL.WindDelta != 0) 
			{
				var Op2:OutPt = AddOutPt(lb.PrevInAEL, lb.Bot);
				AddJoin(Op1, Op2, lb.Top);
			}

			if (lb.NextInAEL != rb) {

				if (rb.OutIdx >= 0 && rb.PrevInAEL.OutIdx >= 0 && ClipperBase.SlopesEqual(rb.PrevInAEL, rb, m_UseFullRange) 
					&& rb.WindDelta != 0 && rb.PrevInAEL.WindDelta != 0) 
				{
					var Op2:OutPt = AddOutPt(rb.PrevInAEL, rb.Bot);
					AddJoin(Op1, Op2, rb.Top);
				}

				var e:TEdge = lb.NextInAEL;
				if (e != null) while (e != rb) {
					//nb: For calculating winding counts etc, IntersectEdges() assumes
					//that param1 will be to the right of param2 ABOVE the intersection ...
					IntersectEdges(rb, e, lb.Curr); //order important here
					e = e.NextInAEL;
				}
			}
		}
	}
	//------------------------------------------------------------------------------

	function InsertEdgeIntoAEL(edge:TEdge, startEdge:TEdge):Void {
		if (m_ActiveEdges == null) {
			edge.PrevInAEL = null;
			edge.NextInAEL = null;
			m_ActiveEdges = edge;
		} else if (startEdge == null && E2InsertsBeforeE1(m_ActiveEdges, edge)) {
			edge.PrevInAEL = null;
			edge.NextInAEL = m_ActiveEdges;
			m_ActiveEdges.PrevInAEL = edge;
			m_ActiveEdges = edge;
		} else {
			if (startEdge == null) startEdge = m_ActiveEdges;
			while (startEdge.NextInAEL != null && !E2InsertsBeforeE1(startEdge.NextInAEL, edge)) {
				startEdge = startEdge.NextInAEL;
			}
			edge.NextInAEL = startEdge.NextInAEL;
			if (startEdge.NextInAEL != null) startEdge.NextInAEL.PrevInAEL = edge;
			edge.PrevInAEL = startEdge;
			startEdge.NextInAEL = edge;
		}
	}
	//----------------------------------------------------------------------

	function E2InsertsBeforeE1(e1:TEdge, e2:TEdge):Bool {
		if (e2.Curr.X == e1.Curr.X) {
			if (e2.Top.Y > e1.Top.Y) return e2.Top.X < TopX(e1, e2.Top.Y);
			else return e1.Top.X > TopX(e2, e1.Top.Y);
		} else return e2.Curr.X < e1.Curr.X;
	}
	//------------------------------------------------------------------------------

	function IsEvenOddFillType(edge:TEdge):Bool {
		if (edge.PolyTyp == PolyType.ptSubject) return m_SubjFillType == PolyFillType.pftEvenOdd;
		else return m_ClipFillType == PolyFillType.pftEvenOdd;
	}
	//------------------------------------------------------------------------------

	function IsEvenOddAltFillType(edge:TEdge):Bool {
		if (edge.PolyTyp == PolyType.ptSubject) return m_ClipFillType == PolyFillType.pftEvenOdd;
		else return m_SubjFillType == PolyFillType.pftEvenOdd;
	}
	//------------------------------------------------------------------------------

	function IsContributing(edge:TEdge):Bool {
		var pft:PolyFillType, pft2:PolyFillType;
		if (edge.PolyTyp == PolyType.ptSubject) {
			pft = m_SubjFillType;
			pft2 = m_ClipFillType;
		} else {
			pft = m_ClipFillType;
			pft2 = m_SubjFillType;
		}

		switch (pft) {
			case PolyFillType.pftEvenOdd:
				//return false if a subj line has been flagged as inside a subj polygon
				if (edge.WindDelta == 0 && edge.WindCnt != 1) return false;
			case PolyFillType.pftNonZero:
				if (Math.abs(edge.WindCnt) != 1) return false;
			case PolyFillType.pftPositive:
				if (edge.WindCnt != 1) return false;
			default:
				//PolyFillType.pftNegative
				if (edge.WindCnt != -1) return false;
		}

		switch (m_ClipType) {
			case ClipType.ctIntersection:
				switch (pft2) {
					case PolyFillType.pftEvenOdd, PolyFillType.pftNonZero:
						return (edge.WindCnt2 != 0);
					case PolyFillType.pftPositive:
						return (edge.WindCnt2 > 0);
					default:
						return (edge.WindCnt2 < 0);
				}
			case ClipType.ctUnion:
				switch (pft2) {
					case PolyFillType.pftEvenOdd, PolyFillType.pftNonZero:
						return (edge.WindCnt2 == 0);
					case PolyFillType.pftPositive:
						return (edge.WindCnt2 <= 0);
					default:
						return (edge.WindCnt2 >= 0);
				}
			case ClipType.ctDifference:
				if (edge.PolyTyp == PolyType.ptSubject) switch (pft2) {
					case PolyFillType.pftEvenOdd, PolyFillType.pftNonZero:
						return (edge.WindCnt2 == 0);
					case PolyFillType.pftPositive:
						return (edge.WindCnt2 <= 0);
					default:
						return (edge.WindCnt2 >= 0);
				} else switch (pft2) {
					case PolyFillType.pftEvenOdd, PolyFillType.pftNonZero:
						return (edge.WindCnt2 != 0);
					case PolyFillType.pftPositive:
						return (edge.WindCnt2 > 0);
					default:
						return (edge.WindCnt2 < 0);
				}
			case ClipType.ctXor:
				if (edge.WindDelta == 0) //XOr always contributing unless open
					switch (pft2) {
						case PolyFillType.pftEvenOdd, PolyFillType.pftNonZero:
							return (edge.WindCnt2 == 0);
						case PolyFillType.pftPositive:
							return (edge.WindCnt2 <= 0);
						default:
							return (edge.WindCnt2 >= 0);
				} else return true;
		}
		return true;
	}
	//------------------------------------------------------------------------------

	function SetWindingCount(edge:TEdge):Void {
		var e:TEdge = edge.PrevInAEL;
		//find the edge of the same polytype that immediately preceeds 'edge' in AEL
		while (e != null && ((e.PolyTyp != edge.PolyTyp) || (e.WindDelta == 0))) e = e.PrevInAEL;
		if (e == null) {
			edge.WindCnt = (edge.WindDelta == 0 ? 1 : edge.WindDelta);
			edge.WindCnt2 = 0;
			e = m_ActiveEdges; //ie get ready to calc WindCnt2
		} else if (edge.WindDelta == 0 && m_ClipType != ClipType.ctUnion) {
			edge.WindCnt = 1;
			edge.WindCnt2 = e.WindCnt2;
			e = e.NextInAEL; //ie get ready to calc WindCnt2
		} else if (IsEvenOddFillType(edge)) {
			//EvenOdd filling ...
			if (edge.WindDelta == 0) {
				//are we inside a subj polygon ...
				var Inside = true;
				var e2:TEdge = e.PrevInAEL;
				while (e2 != null) {
					if (e2.PolyTyp == e.PolyTyp && e2.WindDelta != 0) Inside = !Inside;
					e2 = e2.PrevInAEL;
				}
				edge.WindCnt = (Inside ? 0 : 1);
			} else {
				edge.WindCnt = edge.WindDelta;
			}
			edge.WindCnt2 = e.WindCnt2;
			e = e.NextInAEL; //ie get ready to calc WindCnt2
		} else {
			//nonZero, Positive or Negative filling ...
			if (e.WindCnt * e.WindDelta < 0) {
				//prev edge is 'decreasing' WindCount (WC) toward zero
				//so we're outside the previous polygon ...
				if (Math.abs(e.WindCnt) > 1) {
					//outside prev poly but still inside another.
					//when reversing direction of prev poly use the same WC 
					if (e.WindDelta * edge.WindDelta < 0) edge.WindCnt = e.WindCnt;
					//otherwise continue to 'decrease' WC ...
					else edge.WindCnt = e.WindCnt + edge.WindDelta;
				} else
				//now outside all polys of same polytype so set own WC ...
				edge.WindCnt = (edge.WindDelta == 0 ? 1 : edge.WindDelta);
			} else {
				//prev edge is 'increasing' WindCount (WC) away from zero
				//so we're inside the previous polygon ...
				if (edge.WindDelta == 0) edge.WindCnt = (e.WindCnt < 0 ? e.WindCnt - 1 : e.WindCnt + 1);
				//if wind direction is reversing prev then use same WC
				else if (e.WindDelta * edge.WindDelta < 0) edge.WindCnt = e.WindCnt;
				//otherwise add to WC ...
				else edge.WindCnt = e.WindCnt + edge.WindDelta;
			}
			edge.WindCnt2 = e.WindCnt2;
			e = e.NextInAEL; //ie get ready to calc WindCnt2
		}

		//update WindCnt2 ...
		if (IsEvenOddAltFillType(edge)) {
			//EvenOdd filling ...
			while (e != edge) {
				if (e.WindDelta != 0) edge.WindCnt2 = (edge.WindCnt2 == 0 ? 1 : 0);
				e = e.NextInAEL;
			}
		} else {
			//nonZero, Positive or Negative filling ...
			while (e != edge) {
				edge.WindCnt2 += e.WindDelta;
				e = e.NextInAEL;
			}
		}
	}
	//------------------------------------------------------------------------------

	function AddEdgeToSEL(edge:TEdge):Void {
		//SEL pointers in PEdge are reused to build a list of horizontal edges.
		//However, we don't need to worry about order with horizontal edge processing.
		if (m_SortedEdges == null) {
			m_SortedEdges = edge;
			edge.PrevInSEL = null;
			edge.NextInSEL = null;
		} else {
			edge.NextInSEL = m_SortedEdges;
			edge.PrevInSEL = null;
			m_SortedEdges.PrevInSEL = edge;
			m_SortedEdges = edge;
		}
	}
	//------------------------------------------------------------------------------

	function CopyAELToSEL():Void {
		var e:TEdge = m_ActiveEdges;
		m_SortedEdges = e;
		while (e != null) {
			e.PrevInSEL = e.PrevInAEL;
			e.NextInSEL = e.NextInAEL;
			e = e.NextInAEL;
		}
	}
	//------------------------------------------------------------------------------

	function SwapPositionsInAEL(edge1:TEdge, edge2:TEdge):Void {
		//check that one or other edge hasn't already been removed from AEL ...
		if (edge1.NextInAEL == edge1.PrevInAEL || edge2.NextInAEL == edge2.PrevInAEL) return;

		if (edge1.NextInAEL == edge2) {
			var next:TEdge = edge2.NextInAEL;
			if (next != null) next.PrevInAEL = edge1;
			var prev:TEdge = edge1.PrevInAEL;
			if (prev != null) prev.NextInAEL = edge2;
			edge2.PrevInAEL = prev;
			edge2.NextInAEL = edge1;
			edge1.PrevInAEL = edge2;
			edge1.NextInAEL = next;
		} else if (edge2.NextInAEL == edge1) {
			var next:TEdge = edge1.NextInAEL;
			if (next != null) next.PrevInAEL = edge2;
			var prev:TEdge = edge2.PrevInAEL;
			if (prev != null) prev.NextInAEL = edge1;
			edge1.PrevInAEL = prev;
			edge1.NextInAEL = edge2;
			edge2.PrevInAEL = edge1;
			edge2.NextInAEL = next;
		} else {
			var next:TEdge = edge1.NextInAEL;
			var prev:TEdge = edge1.PrevInAEL;
			edge1.NextInAEL = edge2.NextInAEL;
			if (edge1.NextInAEL != null) edge1.NextInAEL.PrevInAEL = edge1;
			edge1.PrevInAEL = edge2.PrevInAEL;
			if (edge1.PrevInAEL != null) edge1.PrevInAEL.NextInAEL = edge1;
			edge2.NextInAEL = next;
			if (edge2.NextInAEL != null) edge2.NextInAEL.PrevInAEL = edge2;
			edge2.PrevInAEL = prev;
			if (edge2.PrevInAEL != null) edge2.PrevInAEL.NextInAEL = edge2;
		}

		if (edge1.PrevInAEL == null) m_ActiveEdges = edge1;
		else if (edge2.PrevInAEL == null) m_ActiveEdges = edge2;
	}
	//------------------------------------------------------------------------------

	function SwapPositionsInSEL(edge1:TEdge, edge2:TEdge):Void {
		if (edge1.NextInSEL == null && edge1.PrevInSEL == null) return;
		if (edge2.NextInSEL == null && edge2.PrevInSEL == null) return;

		if (edge1.NextInSEL == edge2) {
			var next:TEdge = edge2.NextInSEL;
			if (next != null) next.PrevInSEL = edge1;
			var prev:TEdge = edge1.PrevInSEL;
			if (prev != null) prev.NextInSEL = edge2;
			edge2.PrevInSEL = prev;
			edge2.NextInSEL = edge1;
			edge1.PrevInSEL = edge2;
			edge1.NextInSEL = next;
		} else if (edge2.NextInSEL == edge1) {
			var next:TEdge = edge1.NextInSEL;
			if (next != null) next.PrevInSEL = edge2;
			var prev:TEdge = edge2.PrevInSEL;
			if (prev != null) prev.NextInSEL = edge1;
			edge1.PrevInSEL = prev;
			edge1.NextInSEL = edge2;
			edge2.PrevInSEL = edge1;
			edge2.NextInSEL = next;
		} else {
			var next:TEdge = edge1.NextInSEL;
			var prev:TEdge = edge1.PrevInSEL;
			edge1.NextInSEL = edge2.NextInSEL;
			if (edge1.NextInSEL != null) edge1.NextInSEL.PrevInSEL = edge1;
			edge1.PrevInSEL = edge2.PrevInSEL;
			if (edge1.PrevInSEL != null) edge1.PrevInSEL.NextInSEL = edge1;
			edge2.NextInSEL = next;
			if (edge2.NextInSEL != null) edge2.NextInSEL.PrevInSEL = edge2;
			edge2.PrevInSEL = prev;
			if (edge2.PrevInSEL != null) edge2.PrevInSEL.NextInSEL = edge2;
		}

		if (edge1.PrevInSEL == null) m_SortedEdges = edge1;
		else if (edge2.PrevInSEL == null) m_SortedEdges = edge2;
	}
	//------------------------------------------------------------------------------


	function AddLocalMaxPoly(e1:TEdge, e2:TEdge, pt:IntPoint):Void {
		AddOutPt(e1, pt);
		if (e2.WindDelta == 0) AddOutPt(e2, pt);
		if (e1.OutIdx == e2.OutIdx) {
			e1.OutIdx = ClipperBase.Unassigned;
			e2.OutIdx = ClipperBase.Unassigned;
		} else if (e1.OutIdx < e2.OutIdx) AppendPolygon(e1, e2);
		else AppendPolygon(e2, e1);
	}
	//------------------------------------------------------------------------------

	function AddLocalMinPoly(e1:TEdge, e2:TEdge, pt:IntPoint):OutPt {
		var result:OutPt;
		var e:TEdge, prevE:TEdge;
		if (ClipperBase.IsHorizontal(e2) || (e1.Dx > e2.Dx)) {
			result = AddOutPt(e1, pt);
			e2.OutIdx = e1.OutIdx;
			e1.Side = EdgeSide.esLeft;
			e2.Side = EdgeSide.esRight;
			e = e1;
			if (e.PrevInAEL == e2) prevE = e2.PrevInAEL;
			else prevE = e.PrevInAEL;
		} else {
			result = AddOutPt(e2, pt);
			e1.OutIdx = e2.OutIdx;
			e1.Side = EdgeSide.esRight;
			e2.Side = EdgeSide.esLeft;
			e = e2;
			if (e.PrevInAEL == e1) prevE = e1.PrevInAEL;
			else prevE = e.PrevInAEL;
		}

		if (prevE != null && prevE.OutIdx >= 0 && (TopX(prevE, pt.Y) == TopX(e, pt.Y)) 
			&& ClipperBase.SlopesEqual(e, prevE, m_UseFullRange) && (e.WindDelta != 0) && (prevE.WindDelta != 0)) 
		{
			var outPt:OutPt = AddOutPt(prevE, pt);
			AddJoin(result, outPt, e.Top);
		}
		return result;
	}
	//------------------------------------------------------------------------------

	function CreateOutRec():OutRec {
		var result = new OutRec();
		result.Idx = ClipperBase.Unassigned;
		result.IsHole = false;
		result.IsOpen = false;
		result.FirstLeft = null;
		result.Pts = null;
		result.BottomPt = null;
		result.polyNode = null;
		m_PolyOuts.push(result);
		result.Idx = m_PolyOuts.length - 1;
		return result;
	}
	//------------------------------------------------------------------------------

	function AddOutPt(e:TEdge, pt:IntPoint):OutPt {
		var ToFront = (e.Side == EdgeSide.esLeft);
		if (e.OutIdx < 0) {
			var outRec:OutRec = CreateOutRec();
			outRec.IsOpen = (e.WindDelta == 0);
			var newOp = new OutPt();
			outRec.Pts = newOp;
			newOp.Idx = outRec.Idx;
			newOp.Pt.copyFrom(pt);
			newOp.Next = newOp;
			newOp.Prev = newOp;
			if (!outRec.IsOpen) SetHoleState(e, outRec);
			e.OutIdx = outRec.Idx; //nb: do this after SetZ !
			return newOp;
		} else {
			var outRec:OutRec = m_PolyOuts[e.OutIdx];
			//OutRec.Pts is the 'Left-most' point & OutRec.Pts.Prev is the 'Right-most'
			var op:OutPt = outRec.Pts;
			if (ToFront && pt.equals(op.Pt)) return op;
			else if (!ToFront && pt.equals(op.Prev.Pt)) return op.Prev;

			var newOp = new OutPt();
			newOp.Idx = outRec.Idx;
			newOp.Pt.copyFrom(pt);
			newOp.Next = op;
			newOp.Prev = op.Prev;
			newOp.Prev.Next = newOp;
			op.Prev = newOp;
			if (ToFront) outRec.Pts = newOp;
			return newOp;
		}
	}
	//------------------------------------------------------------------------------

	//TODO: ref?
	/*internal*/ function SwapPoints(/*ref*/ pt1:IntPoint, /*ref*/ pt2:IntPoint):Void {
		var tmp = pt1.clone();
		pt1.copyFrom(pt2);
		pt2.copyFrom(tmp);
	}
	//------------------------------------------------------------------------------

	// TODO: ref/swap
	function HorzSegmentsOverlap(seg1a:CInt, seg1b:CInt, seg2a:CInt, seg2b:CInt):Bool {
		if (seg1a > seg1b) {
			var tmp:CInt = seg1a;
			seg1a = seg1b;
			seg1b = tmp;
		}
		if (seg2a > seg2b) {
			var tmp:CInt = seg2a;
			seg2a = seg2b;
			seg2b = tmp;
		}
		return (seg1a < seg2b) && (seg2a < seg1b);
	}
	//------------------------------------------------------------------------------

	function SetHoleState(e:TEdge, outRec:OutRec):Void {
		var isHole = false;
		var e2:TEdge = e.PrevInAEL;
		while (e2 != null) {
			if (e2.OutIdx >= 0 && e2.WindDelta != 0) {
				isHole = !isHole;
				if (outRec.FirstLeft == null) outRec.FirstLeft = m_PolyOuts[e2.OutIdx];
			}
			e2 = e2.PrevInAEL;
		}
		if (isHole) outRec.IsHole = true;
	}
	//------------------------------------------------------------------------------

	function GetDx(pt1:IntPoint, pt2:IntPoint):Float {
		if (pt1.Y == pt2.Y) return ClipperBase.horizontal;
		else {
			var dx:Float = (pt2.X - pt1.X);
			var dy:Float = (pt2.Y - pt1.Y);
			return dy / dy;
		}
	}
	//---------------------------------------------------------------------------

	function FirstIsBottomPt(btmPt1:OutPt, btmPt2:OutPt):Bool {
		var p:OutPt = btmPt1.Prev;
		while ((p.Pt.equals(btmPt1.Pt)) && (p != btmPt1)) p = p.Prev;
		var dx1p:Float = Math.abs(GetDx(btmPt1.Pt, p.Pt));
		p = btmPt1.Next;
		while ((p.Pt.equals(btmPt1.Pt)) && (p != btmPt1)) p = p.Next;
		var dx1n:Float = Math.abs(GetDx(btmPt1.Pt, p.Pt));

		p = btmPt2.Prev;
		while ((p.Pt.equals(btmPt2.Pt)) && (p != btmPt2)) p = p.Prev;
		var dx2p:Float = Math.abs(GetDx(btmPt2.Pt, p.Pt));
		p = btmPt2.Next;
		while ((p.Pt.equals(btmPt2.Pt)) && (p != btmPt2)) p = p.Next;
		var dx2n:Float = Math.abs(GetDx(btmPt2.Pt, p.Pt));
		return (dx1p >= dx2p && dx1p >= dx2n) || (dx1n >= dx2p && dx1n >= dx2n);
	}
	//------------------------------------------------------------------------------

	function GetBottomPt(pp:OutPt):OutPt {
		var dups:OutPt = null;
		var p:OutPt = pp.Next;
		while (p != pp) {
			if (p.Pt.Y > pp.Pt.Y) {
				pp = p;
				dups = null;
			} else if (p.Pt.Y == pp.Pt.Y && p.Pt.X <= pp.Pt.X) {
				if (p.Pt.X < pp.Pt.X) {
					dups = null;
					pp = p;
				} else {
					if (p.Next != pp && p.Prev != pp) dups = p;
				}
			}
			p = p.Next;
		}
		if (dups != null) {
			//there appears to be at least 2 vertices at bottomPt so ...
			while (dups != p) {
				if (!FirstIsBottomPt(p, dups)) pp = dups;
				dups = dups.Next;
				while (!dups.Pt.equals(pp.Pt)) dups = dups.Next;
			}
		}
		return pp;
	}
	//------------------------------------------------------------------------------

	function GetLowermostRec(outRec1:OutRec, outRec2:OutRec):OutRec {
		//work out which polygon fragment has the correct hole state ...
		if (outRec1.BottomPt == null) outRec1.BottomPt = GetBottomPt(outRec1.Pts);
		if (outRec2.BottomPt == null) outRec2.BottomPt = GetBottomPt(outRec2.Pts);
		var bPt1:OutPt = outRec1.BottomPt;
		var bPt2:OutPt = outRec2.BottomPt;
		if (bPt1.Pt.Y > bPt2.Pt.Y) return outRec1;
		else if (bPt1.Pt.Y < bPt2.Pt.Y) return outRec2;
		else if (bPt1.Pt.X < bPt2.Pt.X) return outRec1;
		else if (bPt1.Pt.X > bPt2.Pt.X) return outRec2;
		else if (bPt1.Next == bPt1) return outRec2;
		else if (bPt2.Next == bPt2) return outRec1;
		else if (FirstIsBottomPt(bPt1, bPt2)) return outRec1;
		else return outRec2;
	}
	//------------------------------------------------------------------------------

	function Param1RightOfParam2(outRec1:OutRec, outRec2:OutRec):Bool {
		do {
			outRec1 = outRec1.FirstLeft;
			if (outRec1 == outRec2) return true;
		} while (outRec1 != null);
		return false;
	}
	//------------------------------------------------------------------------------

	function GetOutRec(idx:Int):OutRec {
		var outrec:OutRec = m_PolyOuts[idx];
		while (outrec != m_PolyOuts[outrec.Idx])
		outrec = m_PolyOuts[outrec.Idx];
		return outrec;
	}
	//------------------------------------------------------------------------------

	function AppendPolygon(e1:TEdge, e2:TEdge):Void {
		//get the start and ends of both output polygons ...
		var outRec1:OutRec = m_PolyOuts[e1.OutIdx];
		var outRec2:OutRec = m_PolyOuts[e2.OutIdx];

		var holeStateRec:OutRec;
		if (Param1RightOfParam2(outRec1, outRec2)) holeStateRec = outRec2;
		else if (Param1RightOfParam2(outRec2, outRec1)) holeStateRec = outRec1;
		else holeStateRec = GetLowermostRec(outRec1, outRec2);

		var p1_lft:OutPt = outRec1.Pts;
		var p1_rt:OutPt = p1_lft.Prev;
		var p2_lft:OutPt = outRec2.Pts;
		var p2_rt:OutPt = p2_lft.Prev;

		var side:EdgeSide;
		//join e2 poly onto e1 poly and delete pointers to e2 ...
		if (e1.Side == EdgeSide.esLeft) {
			if (e2.Side == EdgeSide.esLeft) {
				//z y x a b c
				ReversePolyPtLinks(p2_lft);
				p2_lft.Next = p1_lft;
				p1_lft.Prev = p2_lft;
				p1_rt.Next = p2_rt;
				p2_rt.Prev = p1_rt;
				outRec1.Pts = p2_rt;
			} else {
				//x y z a b c
				p2_rt.Next = p1_lft;
				p1_lft.Prev = p2_rt;
				p2_lft.Prev = p1_rt;
				p1_rt.Next = p2_lft;
				outRec1.Pts = p2_lft;
			}
			side = EdgeSide.esLeft;
		} else {
			if (e2.Side == EdgeSide.esRight) {
				//a b c z y x
				ReversePolyPtLinks(p2_lft);
				p1_rt.Next = p2_rt;
				p2_rt.Prev = p1_rt;
				p2_lft.Next = p1_lft;
				p1_lft.Prev = p2_lft;
			} else {
				//a b c x y z
				p1_rt.Next = p2_lft;
				p2_lft.Prev = p1_rt;
				p1_lft.Prev = p2_rt;
				p2_rt.Next = p1_lft;
			}
			side = EdgeSide.esRight;
		}

		outRec1.BottomPt = null;
		if (holeStateRec == outRec2) {
			if (outRec2.FirstLeft != outRec1) outRec1.FirstLeft = outRec2.FirstLeft;
			outRec1.IsHole = outRec2.IsHole;
		}
		outRec2.Pts = null;
		outRec2.BottomPt = null;

		outRec2.FirstLeft = outRec1;

		var OKIdx:Int = e1.OutIdx;
		var ObsoleteIdx:Int = e2.OutIdx;

		e1.OutIdx = ClipperBase.Unassigned; //nb: safe because we only get here via AddLocalMaxPoly
		e2.OutIdx = ClipperBase.Unassigned;

		var e:TEdge = m_ActiveEdges;
		while (e != null) {
			if (e.OutIdx == ObsoleteIdx) {
				e.OutIdx = OKIdx;
				e.Side = side;
				break;
			}
			e = e.NextInAEL;
		}
		outRec2.Idx = outRec1.Idx;
	}
	//------------------------------------------------------------------------------

	function ReversePolyPtLinks(pp:OutPt):Void {
		if (pp == null) return;
		var pp1:OutPt;
		var pp2:OutPt;
		pp1 = pp;
		do {
			pp2 = pp1.Next;
			pp1.Next = pp1.Prev;
			pp1.Prev = pp2;
			pp1 = pp2;
		} while (pp1 != pp);
	}
	//------------------------------------------------------------------------------

	static function SwapSides(edge1:TEdge, edge2:TEdge):Void {
		var side:EdgeSide = edge1.Side;
		edge1.Side = edge2.Side;
		edge2.Side = side;
	}
	//------------------------------------------------------------------------------

	static function SwapPolyIndexes(edge1:TEdge, edge2:TEdge):Void {
		var outIdx:Int = edge1.OutIdx;
		edge1.OutIdx = edge2.OutIdx;
		edge2.OutIdx = outIdx;
	}
	//------------------------------------------------------------------------------

	function IntersectEdges(e1:TEdge, e2:TEdge, pt:IntPoint):Void {
		//e1 will be to the left of e2 BELOW the intersection. Therefore e1 is before
		//e2 in AEL except when e1 is being inserted at the intersection point ...

		var e1Contributing = (e1.OutIdx >= 0);
		var e2Contributing = (e2.OutIdx >= 0);

		// TODO: ref
	#if use_xyz 
		SetZ(/*ref*/ pt, e1, e2);
	#end

	#if use_lines
		//if either edge is on an OPEN path ...
		if (e1.WindDelta == 0 || e2.WindDelta == 0) {
			//ignore subject-subject open path intersections UNLESS they
			//are both open paths, AND they are both 'contributing maximas' ...
			if (e1.WindDelta == 0 && e2.WindDelta == 0) return;
			//if intersecting a subj line with a subj poly ...
			else if (e1.PolyTyp == e2.PolyTyp && e1.WindDelta != e2.WindDelta && m_ClipType == ClipType.ctUnion) {
				if (e1.WindDelta == 0) {
					if (e2Contributing) {
						AddOutPt(e1, pt);
						if (e1Contributing) e1.OutIdx = Unassigned;
					}
				} else {
					if (e1Contributing) {
						AddOutPt(e2, pt);
						if (e2Contributing) e2.OutIdx = Unassigned;
					}
				}
			} else if (e1.PolyTyp != e2.PolyTyp) {
				if ((e1.WindDelta == 0) && Math.Abs(e2.WindCnt) == 1 && (m_ClipType != ClipType.ctUnion || e2.WindCnt2 == 0)) {
					AddOutPt(e1, pt);
					if (e1Contributing) e1.OutIdx = Unassigned;
				} else if ((e2.WindDelta == 0) && (Math.Abs(e1.WindCnt) == 1) && (m_ClipType != ClipType.ctUnion || e1.WindCnt2 == 0)) {
					AddOutPt(e2, pt);
					if (e2Contributing) e2.OutIdx = Unassigned;
				}
			}
			return;
		}
	#end

		//update winding counts...
		//assumes that e1 will be to the Right of e2 ABOVE the intersection
		if (e1.PolyTyp == e2.PolyTyp) {
			if (IsEvenOddFillType(e1)) {
				var oldE1WindCnt:Int = e1.WindCnt;
				e1.WindCnt = e2.WindCnt;
				e2.WindCnt = oldE1WindCnt;
			} else {
				if (e1.WindCnt + e2.WindDelta == 0) e1.WindCnt = -e1.WindCnt;
				else e1.WindCnt += e2.WindDelta;
				if (e2.WindCnt - e1.WindDelta == 0) e2.WindCnt = -e2.WindCnt;
				else e2.WindCnt -= e1.WindDelta;
			}
		} else {
			if (!IsEvenOddFillType(e2)) e1.WindCnt2 += e2.WindDelta;
			else e1.WindCnt2 = (e1.WindCnt2 == 0) ? 1 : 0;
			if (!IsEvenOddFillType(e1)) e2.WindCnt2 -= e1.WindDelta;
			else e2.WindCnt2 = (e2.WindCnt2 == 0) ? 1 : 0;
		}

		var e1FillType, e2FillType, e1FillType2, e2FillType2;
		if (e1.PolyTyp == PolyType.ptSubject) {
			e1FillType = m_SubjFillType;
			e1FillType2 = m_ClipFillType;
		} else {
			e1FillType = m_ClipFillType;
			e1FillType2 = m_SubjFillType;
		}
		if (e2.PolyTyp == PolyType.ptSubject) {
			e2FillType = m_SubjFillType;
			e2FillType2 = m_ClipFillType;
		} else {
			e2FillType = m_ClipFillType;
			e2FillType2 = m_SubjFillType;
		}

		var e1Wc:Int, e2Wc:Int;
		switch (e1FillType) {
			case PolyFillType.pftPositive:
				e1Wc = e1.WindCnt;
			case PolyFillType.pftNegative:
				e1Wc = -e1.WindCnt;
			default:
				e1Wc = Std.int(Math.abs(e1.WindCnt));
		}
		switch (e2FillType) {
			case PolyFillType.pftPositive:
				e2Wc = e2.WindCnt;
			case PolyFillType.pftNegative:
				e2Wc = -e2.WindCnt;
			default:
				e2Wc = Std.int(Math.abs(e2.WindCnt));
		}

		if (e1Contributing && e2Contributing) {
			if ((e1Wc != 0 && e1Wc != 1) || (e2Wc != 0 && e2Wc != 1) || (e1.PolyTyp != e2.PolyTyp && m_ClipType != ClipType.ctXor)) {
				AddLocalMaxPoly(e1, e2, pt);
			} else {
				AddOutPt(e1, pt);
				AddOutPt(e2, pt);
				SwapSides(e1, e2);
				SwapPolyIndexes(e1, e2);
			}
		} else if (e1Contributing) {
			if (e2Wc == 0 || e2Wc == 1) {
				AddOutPt(e1, pt);
				SwapSides(e1, e2);
				SwapPolyIndexes(e1, e2);
			}

		} else if (e2Contributing) {
			if (e1Wc == 0 || e1Wc == 1) {
				AddOutPt(e2, pt);
				SwapSides(e1, e2);
				SwapPolyIndexes(e1, e2);
			}
		} else if ((e1Wc == 0 || e1Wc == 1) && (e2Wc == 0 || e2Wc == 1)) {
			//neither edge is currently contributing ...
			// TODO: check double def of these ints, and Math.abs cast
			var e1Wc2:CInt, e2Wc2:CInt;
			switch (e1FillType2) {
				case PolyFillType.pftPositive:
					e1Wc2 = e1.WindCnt2;
				case PolyFillType.pftNegative:
					e1Wc2 = -e1.WindCnt2;
				default:
					e1Wc2 = Std.int(Math.abs(e1.WindCnt2));
			}
			switch (e2FillType2) {
				case PolyFillType.pftPositive:
					e2Wc2 = e2.WindCnt2;
				case PolyFillType.pftNegative:
					e2Wc2 = -e2.WindCnt2;
				default:
					e2Wc2 = Std.int(Math.abs(e2.WindCnt2));
			}

			if (e1.PolyTyp != e2.PolyTyp) {
				AddLocalMinPoly(e1, e2, pt);
			} else if (e1Wc == 1 && e2Wc == 1) switch (m_ClipType) {
				case ClipType.ctIntersection:
					if (e1Wc2 > 0 && e2Wc2 > 0) AddLocalMinPoly(e1, e2, pt);
				case ClipType.ctUnion:
					if (e1Wc2 <= 0 && e2Wc2 <= 0) AddLocalMinPoly(e1, e2, pt);
				case ClipType.ctDifference:
					if (((e1.PolyTyp == PolyType.ptClip) && (e1Wc2 > 0) && (e2Wc2 > 0)) 
						|| ((e1.PolyTyp == PolyType.ptSubject) && (e1Wc2 <= 0) && (e2Wc2 <= 0))) 
					{
						AddLocalMinPoly(e1, e2, pt);
					}
				case ClipType.ctXor:
					AddLocalMinPoly(e1, e2, pt);
			} else SwapSides(e1, e2);
		}
	}
	//------------------------------------------------------------------------------

	function DeleteFromAEL(e:TEdge):Void {
		var AelPrev:TEdge = e.PrevInAEL;
		var AelNext:TEdge = e.NextInAEL;
		if (AelPrev == null && AelNext == null && (e != m_ActiveEdges)) return; //already deleted
		if (AelPrev != null) AelPrev.NextInAEL = AelNext;
		else m_ActiveEdges = AelNext;
		if (AelNext != null) AelNext.PrevInAEL = AelPrev;
		e.NextInAEL = null;
		e.PrevInAEL = null;
	}
	//------------------------------------------------------------------------------

	function DeleteFromSEL(e:TEdge):Void {
		var SelPrev:TEdge = e.PrevInSEL;
		var SelNext:TEdge = e.NextInSEL;
		if (SelPrev == null && SelNext == null && (e != m_SortedEdges)) return; //already deleted
		if (SelPrev != null) SelPrev.NextInSEL = SelNext;
		else m_SortedEdges = SelNext;
		if (SelNext != null) SelNext.PrevInSEL = SelPrev;
		e.NextInSEL = null;
		e.PrevInSEL = null;
	}
	//------------------------------------------------------------------------------

	// TODO: ref (updated to return the modified edge)
	function UpdateEdgeIntoAEL(/*ref*/ e:TEdge):TEdge {
		if (e.NextInLML == null) throw new ClipperException("UpdateEdgeIntoAEL: invalid call");
		var AelPrev:TEdge = e.PrevInAEL;
		var AelNext:TEdge = e.NextInAEL;
		e.NextInLML.OutIdx = e.OutIdx;
		if (AelPrev != null) AelPrev.NextInAEL = e.NextInLML;
		else m_ActiveEdges = e.NextInLML;
		if (AelNext != null) AelNext.PrevInAEL = e.NextInLML;
		e.NextInLML.Side = e.Side;
		e.NextInLML.WindDelta = e.WindDelta;
		e.NextInLML.WindCnt = e.WindCnt;
		e.NextInLML.WindCnt2 = e.WindCnt2;
		e = e.NextInLML;
		e.Curr.copyFrom(e.Bot);
		e.PrevInAEL = AelPrev;
		e.NextInAEL = AelNext;
		if (!ClipperBase.IsHorizontal(e)) InsertScanbeam(e.Top.Y);
		return e;
	}
	//------------------------------------------------------------------------------

	function ProcessHorizontals(isTopOfScanbeam:Bool):Void {
		var horzEdge:TEdge = m_SortedEdges;
		while (horzEdge != null) {
			DeleteFromSEL(horzEdge);
			ProcessHorizontal(horzEdge, isTopOfScanbeam);
			horzEdge = m_SortedEdges;
		}
	}
	//------------------------------------------------------------------------------

	// TODO: check out
	function GetHorzDirection(HorzEdge:TEdge, outParams:{/*out*/ Dir:Direction, /*out*/ Left:CInt, /*out*/Right:CInt}):Void {
		if (HorzEdge.Bot.X < HorzEdge.Top.X) {
			outParams.Left = HorzEdge.Bot.X;
			outParams.Right = HorzEdge.Top.X;
			outParams.Dir = Direction.dLeftToRight;
		} else {
			outParams.Left = HorzEdge.Top.X;
			outParams.Right = HorzEdge.Bot.X;
			outParams.Dir = Direction.dRightToLeft;
		}
	}
	//------------------------------------------------------------------------

	function ProcessHorizontal(horzEdge:TEdge, isTopOfScanbeam:Bool):Void {
		var dir:Direction = null;
		var horzLeft:CInt = 0, horzRight:CInt = 0;

		// TODO: out
		var outParams = {/*out*/ Dir:dir, /*out*/ Left:horzLeft, /*out*/ Right:horzRight};
		GetHorzDirection(horzEdge, outParams);
		dir = outParams.Dir;
		horzLeft = outParams.Left;
		horzRight = outParams.Right;

		var eLastHorz:TEdge = horzEdge, eMaxPair:TEdge = null;
		while (eLastHorz.NextInLML != null && ClipperBase.IsHorizontal(eLastHorz.NextInLML)) eLastHorz = eLastHorz.NextInLML;
		if (eLastHorz.NextInLML == null) eMaxPair = GetMaximaPair(eLastHorz);

		while (true) {
			var IsLastHorz = (horzEdge == eLastHorz);
			var e:TEdge = GetNextInAEL(horzEdge, dir);
			while (e != null) {
				//Break if we've got to the end of an intermediate horizontal edge ...
				//nb: Smaller Dx's are to the right of larger Dx's ABOVE the horizontal.
				if (e.Curr.X == horzEdge.Top.X && horzEdge.NextInLML != null && e.Dx < horzEdge.NextInLML.Dx) break;

				var eNext:TEdge = GetNextInAEL(e, dir); //saves eNext for later

				if ((dir == Direction.dLeftToRight && e.Curr.X <= horzRight) || (dir == Direction.dRightToLeft && e.Curr.X >= horzLeft)) {
					//so far we're still in range of the horizontal Edge  but make sure
					//we're at the last of consec. horizontals when matching with eMaxPair
					if (e == eMaxPair && IsLastHorz) {
						if (horzEdge.OutIdx >= 0) {
							var op1:OutPt = AddOutPt(horzEdge, horzEdge.Top);
							var eNextHorz:TEdge = m_SortedEdges;
							while (eNextHorz != null) {
								if (eNextHorz.OutIdx >= 0 && HorzSegmentsOverlap(horzEdge.Bot.X,
								horzEdge.Top.X, eNextHorz.Bot.X, eNextHorz.Top.X)) {
									var op2:OutPt = AddOutPt(eNextHorz, eNextHorz.Bot);
									AddJoin(op2, op1, eNextHorz.Top);
								}
								eNextHorz = eNextHorz.NextInSEL;
							}
							AddGhostJoin(op1, horzEdge.Bot);
							AddLocalMaxPoly(horzEdge, eMaxPair, horzEdge.Top);
						}
						DeleteFromAEL(horzEdge);
						DeleteFromAEL(eMaxPair);
						return;
					} else if (dir == Direction.dLeftToRight) {
						var Pt = new IntPoint(e.Curr.X, horzEdge.Curr.Y);
						IntersectEdges(horzEdge, e, Pt);
					} else {
						var Pt = new IntPoint(e.Curr.X, horzEdge.Curr.Y);
						IntersectEdges(e, horzEdge, Pt);
					}
					SwapPositionsInAEL(horzEdge, e);
				} else if ((dir == Direction.dLeftToRight && e.Curr.X >= horzRight) 
						   || (dir == Direction.dRightToLeft && e.Curr.X <= horzLeft)) 
				{
					break;
				}
				e = eNext;
			} //end while

			if (horzEdge.NextInLML != null && ClipperBase.IsHorizontal(horzEdge.NextInLML)) {
				// TODO: ref
				horzEdge = UpdateEdgeIntoAEL(/*ref*/ horzEdge);
				if (horzEdge.OutIdx >= 0) AddOutPt(horzEdge, horzEdge.Bot);
				// TODO: out
				GetHorzDirection(horzEdge, outParams);
				dir = outParams.Dir;
				horzLeft = outParams.Left;
				horzRight = outParams.Right;
			} else break;
		} //end for (;;)

		if (horzEdge.NextInLML != null) {
			if (horzEdge.OutIdx >= 0) {
				var op1:OutPt = AddOutPt(horzEdge, horzEdge.Top);
				if (isTopOfScanbeam) AddGhostJoin(op1, horzEdge.Bot);

				// TODO: ref
				horzEdge = UpdateEdgeIntoAEL(/*ref*/ horzEdge);
				if (horzEdge.WindDelta == 0) return;
				//nb: HorzEdge is no longer horizontal here
				var ePrev:TEdge = horzEdge.PrevInAEL;
				var eNext:TEdge = horzEdge.NextInAEL;
				if (ePrev != null && ePrev.Curr.X == horzEdge.Bot.X && ePrev.Curr.Y == horzEdge.Bot.Y && ePrev.WindDelta != 0 
					&& (ePrev.OutIdx >= 0 && ePrev.Curr.Y > ePrev.Top.Y && ClipperBase.SlopesEqual(horzEdge, ePrev, m_UseFullRange))) 
				{
					var op2:OutPt = AddOutPt(ePrev, horzEdge.Bot);
					AddJoin(op1, op2, horzEdge.Top);
				} else if (eNext != null && eNext.Curr.X == horzEdge.Bot.X && eNext.Curr.Y == horzEdge.Bot.Y && eNext.WindDelta != 0 
						   && eNext.OutIdx >= 0 && eNext.Curr.Y > eNext.Top.Y && ClipperBase.SlopesEqual(horzEdge, eNext, m_UseFullRange)) 
				{
					var op2:OutPt = AddOutPt(eNext, horzEdge.Bot);
					AddJoin(op1, op2, horzEdge.Top);
				}
				// TODO: ref
			} else horzEdge = UpdateEdgeIntoAEL(/*ref*/ horzEdge);
		} else {
			if (horzEdge.OutIdx >= 0) AddOutPt(horzEdge, horzEdge.Top);
			DeleteFromAEL(horzEdge);
		}
	}
	//------------------------------------------------------------------------------

	function GetNextInAEL(e:TEdge, direction:Direction):TEdge {
		return direction == Direction.dLeftToRight ? e.NextInAEL : e.PrevInAEL;
	}
	//------------------------------------------------------------------------------

	function IsMinima(e:TEdge):Bool {
		return e != null && (e.Prev.NextInLML != e) && (e.Next.NextInLML != e);
	}
	//------------------------------------------------------------------------------

	function IsMaxima(e:TEdge, Y:Float):Bool {
		return (e != null && e.Top.Y == Y && e.NextInLML == null);
	}
	//------------------------------------------------------------------------------

	function IsIntermediate(e:TEdge, Y:Float):Bool {
		return (e.Top.Y == Y && e.NextInLML != null);
	}
	//------------------------------------------------------------------------------

	function GetMaximaPair(e:TEdge):TEdge {
		var result:TEdge = null;
		if ((e.Next.Top.equals(e.Top)) && e.Next.NextInLML == null) result = e.Next;
		else if ((e.Prev.Top.equals(e.Top)) && e.Prev.NextInLML == null) result = e.Prev;
		if (result != null && (result.OutIdx == ClipperBase.Skip || (result.NextInAEL == result.PrevInAEL 
			&& !ClipperBase.IsHorizontal(result)))) 
		{
			return null;
		}
		return result;
	}
	//------------------------------------------------------------------------------

	function ProcessIntersections(topY:CInt):Bool {
		if (m_ActiveEdges == null) return true;
		try {
			BuildIntersectList(topY);
			if (m_IntersectList.length == 0) return true;
			if (m_IntersectList.length == 1 || FixupIntersectionOrder()) ProcessIntersectList();
			else return false;
		} catch (e:Dynamic) {
			m_SortedEdges = null;
			m_IntersectList.clear();
			throw new ClipperException("ProcessIntersections error");
		}
		m_SortedEdges = null;
		return true;
	}
	//------------------------------------------------------------------------------

	function BuildIntersectList(topY:CInt):Void {
		if (m_ActiveEdges == null) return;

		//prepare for sorting ...
		var e:TEdge = m_ActiveEdges;
		m_SortedEdges = e;
		while (e != null) {
			e.PrevInSEL = e.PrevInAEL;
			e.NextInSEL = e.NextInAEL;
			e.Curr.X = TopX(e, topY);
			e = e.NextInAEL;
		}

		//bubblesort ...
		var isModified = true;
		while (isModified && m_SortedEdges != null) {
			isModified = false;
			e = m_SortedEdges;
			while (e.NextInSEL != null) {
				var eNext:TEdge = e.NextInSEL;
				var pt:IntPoint = new IntPoint();
				if (e.Curr.X > eNext.Curr.X) {
					// TODO: out
					IntersectPoint(e, eNext, /*out*/ pt);
					var newNode = new IntersectNode();
					newNode.Edge1 = e;
					newNode.Edge2 = eNext;
					newNode.Pt.copyFrom(pt);
					m_IntersectList.push(newNode);

					SwapPositionsInSEL(e, eNext);
					isModified = true;
				} else e = eNext;
			}
			if (e.PrevInSEL != null) e.PrevInSEL.NextInSEL = null;
			else break;
		}
		m_SortedEdges = null;
	}
	//------------------------------------------------------------------------------

	function EdgesAdjacent(inode:IntersectNode):Bool {
		return (inode.Edge1.NextInSEL == inode.Edge2) || (inode.Edge1.PrevInSEL == inode.Edge2);
	}
	//------------------------------------------------------------------------------

	static function IntersectNodeSort(node1:IntersectNode, node2:IntersectNode):Int {
		//the following typecast is safe because the differences in Pt.Y will
		//be limited to the height of the scanbeam.
		// TODO: check cast
		return Std.int(node2.Pt.Y - node1.Pt.Y);
	}
	//------------------------------------------------------------------------------

	function FixupIntersectionOrder():Bool {
		//pre-condition: intersections are sorted bottom-most first.
		//Now it's crucial that intersections are made only between adjacent edges,
		//so to ensure this the order of intersections may need adjusting ...
		ArraySort.sort(m_IntersectList, m_IntersectNodeComparer);

		CopyAELToSEL();
		var cnt:Int = m_IntersectList.length;
		for (i in 0...cnt) {
			if (!EdgesAdjacent(m_IntersectList[i])) {
				var j = i + 1;
				while (j < cnt && !EdgesAdjacent(m_IntersectList[j])) j++;
				if (j == cnt) return false;

				var tmp:IntersectNode = m_IntersectList[i];
				m_IntersectList[i] = m_IntersectList[j];
				m_IntersectList[j] = tmp;

			}
			SwapPositionsInSEL(m_IntersectList[i].Edge1, m_IntersectList[i].Edge2);
		}
		return true;
	}
	//------------------------------------------------------------------------------

	function ProcessIntersectList():Void {
		for (i in 0...m_IntersectList.length) {
			var iNode:IntersectNode = m_IntersectList[i]; {
				IntersectEdges(iNode.Edge1, iNode.Edge2, iNode.Pt);
				SwapPositionsInAEL(iNode.Edge1, iNode.Edge2);
			}
		}
		m_IntersectList.clear();
	}
	//------------------------------------------------------------------------------

	/*internal*/ static public function Round(value:Float):CInt {
		// TODO: check how to cast
		return value < 0 ? /*(cInt)*/Std.int(value - 0.5) : /*(cInt)*/Std.int(value + 0.5);
	}
	//------------------------------------------------------------------------------

	static function TopX(edge:TEdge, currentY:CInt):CInt {
		if (currentY == edge.Top.Y) return edge.Top.X;
		return edge.Bot.X + Round(edge.Dx * (currentY - edge.Bot.Y));
	}
	//------------------------------------------------------------------------------

	// TODO: check out
	function IntersectPoint(edge1:TEdge, edge2:TEdge, /*out*/ ip:IntPoint):Void {
		// TODO: check this ip and the out ip
		//ip = new IntPoint();
		var b1:Float, b2:Float;
		//nb: with very large coordinate values, it's possible for SlopesEqual() to 
		//return false but for the edge.Dx value be equal due to double precision rounding.
		if (edge1.Dx == edge2.Dx) {
			ip.Y = edge1.Curr.Y;
			ip.X = TopX(edge1, ip.Y);
			return;
		}

		if (edge1.Delta.X == 0) {
			ip.X = edge1.Bot.X;
			if (ClipperBase.IsHorizontal(edge2)) {
				ip.Y = edge2.Bot.Y;
			} else {
				b2 = edge2.Bot.Y - (edge2.Bot.X / edge2.Dx);
				ip.Y = Round(ip.X / edge2.Dx + b2);
			}
		} else if (edge2.Delta.X == 0) {
			ip.X = edge2.Bot.X;
			if (ClipperBase.IsHorizontal(edge1)) {
				ip.Y = edge1.Bot.Y;
			} else {
				b1 = edge1.Bot.Y - (edge1.Bot.X / edge1.Dx);
				ip.Y = Round(ip.X / edge1.Dx + b1);
			}
		} else {
			b1 = edge1.Bot.X - edge1.Bot.Y * edge1.Dx;
			b2 = edge2.Bot.X - edge2.Bot.Y * edge2.Dx;
			var q:Float = (b2 - b1) / (edge1.Dx - edge2.Dx);
			ip.Y = Round(q);
			if (Math.abs(edge1.Dx) < Math.abs(edge2.Dx)) ip.X = Round(edge1.Dx * q + b1);
			else ip.X = Round(edge2.Dx * q + b2);
		}

		if (ip.Y < edge1.Top.Y || ip.Y < edge2.Top.Y) {
			if (edge1.Top.Y > edge2.Top.Y) ip.Y = edge1.Top.Y;
			else ip.Y = edge2.Top.Y;
			if (Math.abs(edge1.Dx) < Math.abs(edge2.Dx)) ip.X = TopX(edge1, ip.Y);
			else ip.X = TopX(edge2, ip.Y);
		}
		//finally, don't allow 'ip' to be BELOW curr.Y (ie bottom of scanbeam) ...
		if (ip.Y > edge1.Curr.Y) {
			ip.Y = edge1.Curr.Y;
			//better to use the more vertical edge to derive X ...
			if (Math.abs(edge1.Dx) > Math.abs(edge2.Dx)) ip.X = TopX(edge2, ip.Y);
			else ip.X = TopX(edge1, ip.Y);
		}
	}
	//------------------------------------------------------------------------------

	function ProcessEdgesAtTopOfScanbeam(topY:CInt):Void {
		var e:TEdge = m_ActiveEdges;
		while (e != null) {
			//1. process maxima, treating them as if they're 'bent' horizontal edges,
			//   but exclude maxima with horizontal edges. nb: e can't be a horizontal.
			var IsMaximaEdge:Bool = IsMaxima(e, topY);

			if (IsMaximaEdge) {
				var eMaxPair:TEdge = GetMaximaPair(e);
				IsMaximaEdge = (eMaxPair == null || !ClipperBase.IsHorizontal(eMaxPair));
			}

			if (IsMaximaEdge) {
				var ePrev:TEdge = e.PrevInAEL;
				DoMaxima(e);
				if (ePrev == null) e = m_ActiveEdges;
				else e = ePrev.NextInAEL;
			} else {
				//2. promote horizontal edges, otherwise update Curr.X and Curr.Y ...
				if (IsIntermediate(e, topY) && ClipperBase.IsHorizontal(e.NextInLML)) {
					// TODO: ref
					e = UpdateEdgeIntoAEL(/*ref*/ e);
					if (e.OutIdx >= 0) AddOutPt(e, e.Bot);
					AddEdgeToSEL(e);
				} else {
					e.Curr.X = TopX(e, topY);
					e.Curr.Y = topY;
				}

				if (StrictlySimple) {
					var ePrev:TEdge = e.PrevInAEL;
					if ((e.OutIdx >= 0) && (e.WindDelta != 0) && ePrev != null && (ePrev.OutIdx >= 0) 
						&& (ePrev.Curr.X == e.Curr.X) && (ePrev.WindDelta != 0)) 
					{
						// TODO: I foresee a compiler error here
						var ip = e.Curr.clone();
					#if use_xyz 
						SetZ(ref ip, ePrev, e);
					#end 
						var op:OutPt = AddOutPt(ePrev, ip);
						var op2:OutPt = AddOutPt(e, ip);
						AddJoin(op, op2, ip); //StrictlySimple (type-3) join
					}
				}

				e = e.NextInAEL;
			}
		}

		//3. Process horizontals at the Top of the scanbeam ...
		ProcessHorizontals(true);

		//4. Promote intermediate vertices ...
		e = m_ActiveEdges;
		while (e != null) {
			if (IsIntermediate(e, topY)) {
				var op:OutPt = null;
				if (e.OutIdx >= 0) op = AddOutPt(e, e.Top);
				// TODO: ref
				e = UpdateEdgeIntoAEL(/*ref*/ e);

				//if output polygons share an edge, they'll need joining later ...
				var ePrev:TEdge = e.PrevInAEL;
				var eNext:TEdge = e.NextInAEL;
				if (ePrev != null && ePrev.Curr.X == e.Bot.X && ePrev.Curr.Y == e.Bot.Y && op != null && ePrev.OutIdx >= 0 
					&& ePrev.Curr.Y > ePrev.Top.Y && ClipperBase.SlopesEqual(e, ePrev, m_UseFullRange) && (e.WindDelta != 0) && (ePrev.WindDelta != 0)) 
				{
					var op2:OutPt = AddOutPt(ePrev, e.Bot);
					AddJoin(op, op2, e.Top);
				} else if (eNext != null && eNext.Curr.X == e.Bot.X && eNext.Curr.Y == e.Bot.Y && op != null && eNext.OutIdx >= 0 
						   && eNext.Curr.Y > eNext.Top.Y && ClipperBase.SlopesEqual(e, eNext, m_UseFullRange) && (e.WindDelta != 0) && (eNext.WindDelta != 0)) 
				{
					var op2:OutPt = AddOutPt(eNext, e.Bot);
					AddJoin(op, op2, e.Top);
				}
			}
			e = e.NextInAEL;
		}
	}
	//------------------------------------------------------------------------------

	function DoMaxima(e:TEdge):Void {
		var eMaxPair:TEdge = GetMaximaPair(e);
		if (eMaxPair == null) {
			if (e.OutIdx >= 0) AddOutPt(e, e.Top);
			DeleteFromAEL(e);
			return;
		}

		var eNext:TEdge = e.NextInAEL;
		while (eNext != null && eNext != eMaxPair) {
			IntersectEdges(e, eNext, e.Top);
			SwapPositionsInAEL(e, eNext);
			eNext = e.NextInAEL;
		}

		if (e.OutIdx == ClipperBase.Unassigned && eMaxPair.OutIdx == ClipperBase.Unassigned) {
			DeleteFromAEL(e);
			DeleteFromAEL(eMaxPair);
		} else if (e.OutIdx >= 0 && eMaxPair.OutIdx >= 0) {
			if (e.OutIdx >= 0) AddLocalMaxPoly(e, eMaxPair, e.Top);
			DeleteFromAEL(e);
			DeleteFromAEL(eMaxPair);
		}
	#if use_lines
		else if (e.WindDelta == 0) {
			if (e.OutIdx >= 0) {
				AddOutPt(e, e.Top);
				e.OutIdx = Unassigned;
			}
			DeleteFromAEL(e);

			if (eMaxPair.OutIdx >= 0) {
				AddOutPt(eMaxPair, e.Top);
				eMaxPair.OutIdx = Unassigned;
			}
			DeleteFromAEL(eMaxPair);
		}
	#end
		else throw new ClipperException("DoMaxima error");
	}
	//------------------------------------------------------------------------------

	static public function ReversePaths(polys:Paths):Void {
		for (poly in polys) {
			poly.reverse();
		}
	}
	//------------------------------------------------------------------------------

	static public function Orientation(poly:Path):Bool {
		return Area(poly) >= 0;
	}
	//------------------------------------------------------------------------------

	function PointCount(pts:OutPt):Int {
		if (pts == null) return 0;
		var result:Int = 0;
		var p:OutPt = pts;
		do {
			result++;
			p = p.Next;
		}
		while (p != pts);
		return result;
	}
	//------------------------------------------------------------------------------

	function BuildResult(polyg:Paths):Void {
		polyg.clear();
		//TODO:polyg.Capacity = m_PolyOuts.length;
		for (i in 0...m_PolyOuts.length) {
			var outRec:OutRec = m_PolyOuts[i];
			if (outRec.Pts == null) continue;
			var p:OutPt = outRec.Pts.Prev;
			var cnt:Int = PointCount(p);
			if (cnt < 2) continue;
			var pg = new Path(/*TODO:cnt*/);
			for (j in 0...cnt) {
				pg.push(p.Pt);
				p = p.Prev;
			}
			polyg.push(pg);
		}
	}
	//------------------------------------------------------------------------------

	function BuildResult2(polytree:PolyTree):Void {
		polytree.Clear();

		//add each output polygon/contour to polytree ...
		//TODO:polytree.m_AllPolys.Capacity = m_PolyOuts.length;
		for (i in 0...m_PolyOuts.length) {
			var outRec:OutRec = m_PolyOuts[i];
			var cnt:Int = PointCount(outRec.Pts);
			if ((outRec.IsOpen && cnt < 2) || (!outRec.IsOpen && cnt < 3)) continue;
			FixHoleLinkage(outRec);
			var pn = new PolyNode();
			polytree.m_AllPolys.push(pn);
			outRec.polyNode = pn;
			//TODO:pn.m_polygon.Capacity = cnt;
			var op:OutPt = outRec.Pts.Prev;
			for (j in 0...cnt) {
				pn.m_polygon.push(op.Pt);
				op = op.Prev;
			}
		}

		//fixup PolyNode links etc ...
		//TODO:polytree.m_Childs.Capacity = m_PolyOuts.length;
		for (i in 0...m_PolyOuts.length) {
			var outRec:OutRec = m_PolyOuts[i];
			if (outRec.polyNode == null) continue;
			else if (outRec.IsOpen) {
				outRec.polyNode.IsOpen = true;
				polytree.AddChild(outRec.polyNode);
			} else if (outRec.FirstLeft != null && outRec.FirstLeft.polyNode != null) outRec.FirstLeft.polyNode.AddChild(outRec.polyNode);
			else polytree.AddChild(outRec.polyNode);
		}
	}
	//------------------------------------------------------------------------------

	function FixupOutPolygon(outRec:OutRec):Void {
		//FixupOutPolygon() - removes duplicate points and simplifies consecutive
		//parallel edges by removing the middle vertex.
		var lastOK:OutPt = null;
		outRec.BottomPt = null;
		var pp:OutPt = outRec.Pts;
		while (true) {
			if (pp.Prev == pp || pp.Prev == pp.Next) {
				outRec.Pts = null;
				return;
			}
			//test for duplicate points and collinear edges ...
			if ((pp.Pt.equals(pp.Next.Pt)) || (pp.Pt.equals(pp.Prev.Pt)) || (ClipperBase.SlopesEqual3(pp.Prev.Pt, pp.Pt, pp.Next.Pt, m_UseFullRange) 
				&& (!PreserveCollinear || !Pt2IsBetweenPt1AndPt3(pp.Prev.Pt, pp.Pt, pp.Next.Pt)))) 
			{
				lastOK = null;
				pp.Prev.Next = pp.Next;
				pp.Next.Prev = pp.Prev;
				pp = pp.Prev;
			} else if (pp == lastOK) break;
			else {
				if (lastOK == null) lastOK = pp;
				pp = pp.Next;
			}
		}
		outRec.Pts = pp;
	}
	//------------------------------------------------------------------------------

	function DupOutPt(outPt:OutPt, InsertAfter:Bool):OutPt {
		var result = new OutPt();
		result.Pt.copyFrom(outPt.Pt);
		result.Idx = outPt.Idx;
		if (InsertAfter) {
			result.Next = outPt.Next;
			result.Prev = outPt;
			outPt.Next.Prev = result;
			outPt.Next = result;
		} else {
			result.Prev = outPt.Prev;
			result.Next = outPt;
			outPt.Prev.Next = result;
			outPt.Prev = result;
		}
		return result;
	}
	//------------------------------------------------------------------------------

	// TODO: out
	function GetOverlap(a1:CInt, a2:CInt, b1:CInt, b2:CInt, outParams:{/*out*/ Left:CInt, /*out*/ Right:CInt}):Bool {
		if (a1 < a2) {
			// TODO: check casts to CInt
			if (b1 < b2) {
				outParams.Left = Std.int(Math.max(a1, b1));
				outParams.Right = Std.int(Math.min(a2, b2));
			} else {
				outParams.Left = Std.int(Math.max(a1, b2));
				outParams.Right = Std.int(Math.min(a2, b1));
			}
		} else {
			if (b1 < b2) {
				outParams.Left = Std.int(Math.max(a2, b1));
				outParams.Right = Std.int(Math.min(a1, b2));
			} else {
				outParams.Left = Std.int(Math.max(a2, b2));
				outParams.Right = Std.int(Math.min(a1, b1));
			}
		}
		return outParams.Left < outParams.Right;
	}
	//------------------------------------------------------------------------------

	function JoinHorz(op1:OutPt, op1b:OutPt, op2:OutPt, op2b:OutPt,	Pt:IntPoint, DiscardLeft:Bool):Bool {
		var Dir1:Direction = (op1.Pt.X > op1b.Pt.X ? Direction.dRightToLeft : Direction.dLeftToRight);
		var Dir2:Direction = (op2.Pt.X > op2b.Pt.X ? Direction.dRightToLeft : Direction.dLeftToRight);
		if (Dir1 == Dir2) return false;

		//When DiscardLeft, we want Op1b to be on the Left of Op1, otherwise we
		//want Op1b to be on the Right. (And likewise with Op2 and Op2b.)
		//So, to facilitate this while inserting Op1b and Op2b ...
		//when DiscardLeft, make sure we're AT or RIGHT of Pt before adding Op1b,
		//otherwise make sure we're AT or LEFT of Pt. (Likewise with Op2b.)
		if (Dir1 == Direction.dLeftToRight) {
			while (op1.Next.Pt.X <= Pt.X && op1.Next.Pt.X >= op1.Pt.X && op1.Next.Pt.Y == Pt.Y)
			op1 = op1.Next;
			if (DiscardLeft && (op1.Pt.X != Pt.X)) op1 = op1.Next;
			op1b = DupOutPt(op1, !DiscardLeft);
			if (!op1b.Pt.equals(Pt)) {
				op1 = op1b;
				op1.Pt.copyFrom(Pt);
				op1b = DupOutPt(op1, !DiscardLeft);
			}
		} else {
			while (op1.Next.Pt.X >= Pt.X && op1.Next.Pt.X <= op1.Pt.X && op1.Next.Pt.Y == Pt.Y)
			op1 = op1.Next;
			if (!DiscardLeft && (op1.Pt.X != Pt.X)) op1 = op1.Next;
			op1b = DupOutPt(op1, DiscardLeft);
			if (!op1b.Pt.equals(Pt)) {
				op1 = op1b;
				op1.Pt.copyFrom(Pt);
				op1b = DupOutPt(op1, DiscardLeft);
			}
		}

		if (Dir2 == Direction.dLeftToRight) {
			while (op2.Next.Pt.X <= Pt.X && op2.Next.Pt.X >= op2.Pt.X && op2.Next.Pt.Y == Pt.Y)
			op2 = op2.Next;
			if (DiscardLeft && (op2.Pt.X != Pt.X)) op2 = op2.Next;
			op2b = DupOutPt(op2, !DiscardLeft);
			if (!op2b.Pt.equals(Pt)) {
				op2 = op2b;
				op2.Pt.copyFrom(Pt);
				op2b = DupOutPt(op2, !DiscardLeft);
			}
		} else {
			while (op2.Next.Pt.X >= Pt.X && op2.Next.Pt.X <= op2.Pt.X && op2.Next.Pt.Y == Pt.Y)
			op2 = op2.Next;
			if (!DiscardLeft && (op2.Pt.X != Pt.X)) op2 = op2.Next;
			op2b = DupOutPt(op2, DiscardLeft);
			if (!op2b.Pt.equals(Pt)) {
				op2 = op2b;
				op2.Pt.copyFrom(Pt);
				op2b = DupOutPt(op2, DiscardLeft);
			}
		}

		if ((Dir1 == Direction.dLeftToRight) == DiscardLeft) {
			op1.Prev = op2;
			op2.Next = op1;
			op1b.Next = op2b;
			op2b.Prev = op1b;
		} else {
			op1.Next = op2;
			op2.Prev = op1;
			op1b.Prev = op2b;
			op2b.Next = op1b;
		}
		return true;
	}
	//------------------------------------------------------------------------------

	function JoinPoints(j:Join, outRec1:OutRec, outRec2:OutRec):Bool {
		var op1:OutPt = j.OutPt1, op1b;
		var op2:OutPt = j.OutPt2, op2b;

		//There are 3 kinds of joins for output polygons ...
		//1. Horizontal joins where Join.OutPt1 & Join.OutPt2 are a vertices anywhere
		//along (horizontal) collinear edges (& Join.OffPt is on the same horizontal).
		//2. Non-horizontal joins where Join.OutPt1 & Join.OutPt2 are at the same
		//location at the Bottom of the overlapping segment (& Join.OffPt is above).
		//3. StrictlySimple joins where edges touch but are not collinear and where
		//Join.OutPt1, Join.OutPt2 & Join.OffPt all share the same point.
		var isHorizontal:Bool = (j.OutPt1.Pt.Y == j.OffPt.Y);

		if (isHorizontal && (j.OffPt.equals(j.OutPt1.Pt)) && (j.OffPt.equals(j.OutPt2.Pt))) {
			//Strictly Simple join ...
			if (outRec1 != outRec2) return false;
			op1b = j.OutPt1.Next;
			// TODO: check whiles
			while (op1b != op1 && (op1b.Pt.equals(j.OffPt))) {
				op1b = op1b.Next;
			}
			var reverse1:Bool = (op1b.Pt.Y > j.OffPt.Y);
			op2b = j.OutPt2.Next;
			while (op2b != op2 && (op2b.Pt.equals(j.OffPt))) {
				op2b = op2b.Next;
			}
			var reverse2:Bool = (op2b.Pt.Y > j.OffPt.Y);
			if (reverse1 == reverse2) return false;
			if (reverse1) {
				op1b = DupOutPt(op1, false);
				op2b = DupOutPt(op2, true);
				op1.Prev = op2;
				op2.Next = op1;
				op1b.Next = op2b;
				op2b.Prev = op1b;
				j.OutPt1 = op1;
				j.OutPt2 = op1b;
				return true;
			} else {
				op1b = DupOutPt(op1, true);
				op2b = DupOutPt(op2, false);
				op1.Next = op2;
				op2.Prev = op1;
				op1b.Prev = op2b;
				op2b.Next = op1b;
				j.OutPt1 = op1;
				j.OutPt2 = op1b;
				return true;
			}
		} else if (isHorizontal) {
			//treat horizontal joins differently to non-horizontal joins since with
			//them we're not yet sure where the overlapping is. OutPt1.Pt & OutPt2.Pt
			//may be anywhere along the horizontal edge.
			op1b = op1;
			while (op1.Prev.Pt.Y == op1.Pt.Y && op1.Prev != op1b && op1.Prev != op2) op1 = op1.Prev;
			while (op1b.Next.Pt.Y == op1b.Pt.Y && op1b.Next != op1 && op1b.Next != op2) op1b = op1b.Next;
			if (op1b.Next == op1 || op1b.Next == op2) return false; //a flat 'polygon'

			op2b = op2;
			while (op2.Prev.Pt.Y == op2.Pt.Y && op2.Prev != op2b && op2.Prev != op1b) op2 = op2.Prev;
			while (op2b.Next.Pt.Y == op2b.Pt.Y && op2b.Next != op2 && op2b.Next != op1) op2b = op2b.Next;
			if (op2b.Next == op2 || op2b.Next == op1) return false; //a flat 'polygon'

			var Left:CInt = 0, Right:CInt = 0;
			//Op1 -. Op1b & Op2 -. Op2b are the extremites of the horizontal edges
			// TODO: out
			var outParams = { Left:Left, Right:Right };
			if (!GetOverlap(op1.Pt.X, op1b.Pt.X, op2.Pt.X, op2b.Pt.X, outParams)) return false;
			Left = outParams.Left;
			Right = outParams.Right;

			//DiscardLeftSide: when overlapping edges are joined, a spike will created
			//which needs to be cleaned up. However, we don't want Op1 or Op2 caught up
			//on the discard Side as either may still be needed for other joins ...
			var Pt:IntPoint = new IntPoint();
			var DiscardLeftSide:Bool;
			if (op1.Pt.X >= Left && op1.Pt.X <= Right) {
				Pt.copyFrom(op1.Pt);
				DiscardLeftSide = (op1.Pt.X > op1b.Pt.X);
			} else if (op2.Pt.X >= Left && op2.Pt.X <= Right) {
				Pt.copyFrom(op2.Pt);
				DiscardLeftSide = (op2.Pt.X > op2b.Pt.X);
			} else if (op1b.Pt.X >= Left && op1b.Pt.X <= Right) {
				Pt.copyFrom(op1b.Pt);
				DiscardLeftSide = op1b.Pt.X > op1.Pt.X;
			} else {
				Pt.copyFrom(op2b.Pt);
				DiscardLeftSide = (op2b.Pt.X > op2.Pt.X);
			}
			j.OutPt1 = op1;
			j.OutPt2 = op2;
			return JoinHorz(op1, op1b, op2, op2b, Pt, DiscardLeftSide);
		} else {
			//nb: For non-horizontal joins ...
			//    1. Jr.OutPt1.Pt.Y == Jr.OutPt2.Pt.Y
			//    2. Jr.OutPt1.Pt > Jr.OffPt.Y

			//make sure the polygons are correctly oriented ...
			op1b = op1.Next;
			while ((op1b.Pt.equals(op1.Pt)) && (op1b != op1)) op1b = op1b.Next;
			var Reverse1:Bool = ((op1b.Pt.Y > op1.Pt.Y) || !ClipperBase.SlopesEqual3(op1.Pt, op1b.Pt, j.OffPt, m_UseFullRange));
			if (Reverse1) {
				op1b = op1.Prev;
				while ((op1b.Pt.equals(op1.Pt)) && (op1b != op1)) op1b = op1b.Prev;
				if ((op1b.Pt.Y > op1.Pt.Y) || !ClipperBase.SlopesEqual3(op1.Pt, op1b.Pt, j.OffPt, m_UseFullRange)) return false;
			}
			op2b = op2.Next;
			while ((op2b.Pt.equals(op2.Pt)) && (op2b != op2)) op2b = op2b.Next;
			var Reverse2:Bool = ((op2b.Pt.Y > op2.Pt.Y) || !ClipperBase.SlopesEqual3(op2.Pt, op2b.Pt, j.OffPt, m_UseFullRange));
			if (Reverse2) {
				op2b = op2.Prev;
				while ((op2b.Pt.equals(op2.Pt)) && (op2b != op2)) op2b = op2b.Prev;
				if ((op2b.Pt.Y > op2.Pt.Y) || !ClipperBase.SlopesEqual3(op2.Pt, op2b.Pt, j.OffPt, m_UseFullRange)) return false;
			}

			if ((op1b == op1) || (op2b == op2) || (op1b == op2b) || ((outRec1 == outRec2) && (Reverse1 == Reverse2))) return false;

			if (Reverse1) {
				op1b = DupOutPt(op1, false);
				op2b = DupOutPt(op2, true);
				op1.Prev = op2;
				op2.Next = op1;
				op1b.Next = op2b;
				op2b.Prev = op1b;
				j.OutPt1 = op1;
				j.OutPt2 = op1b;
				return true;
			} else {
				op1b = DupOutPt(op1, true);
				op2b = DupOutPt(op2, false);
				op1.Next = op2;
				op2.Prev = op1;
				op1b.Prev = op2b;
				op2b.Next = op1b;
				j.OutPt1 = op1;
				j.OutPt2 = op1b;
				return true;
			}
		}
	}
	//----------------------------------------------------------------------

	static public function PointInPolygon(pt:IntPoint, path:Path):Int {
		//returns 0 if false, +1 if true, -1 if pt ON polygon boundary
		//See "The Point in Polygon Problem for Arbitrary Polygons" by Hormann & Agathos
		//http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.88.5498&rep=rep1&type=pdf
		var result:Int = 0, cnt:Int = path.length;
		if (cnt < 3) return 0;
		var ip:IntPoint = path[0].clone();
		// TODO: check loop and casts
		var ipNext:IntPoint = new IntPoint();
		for (i in 1...cnt + 1) {
			ipNext.copyFrom((i == cnt ? path[0] : path[i]));
			if (ipNext.Y == pt.Y) {
				if ((ipNext.X == pt.X) || (ip.Y == pt.Y && ((ipNext.X > pt.X) == (ip.X < pt.X)))) return -1;
			}
			if ((ip.Y < pt.Y) != (ipNext.Y < pt.Y)) {
				if (ip.X >= pt.X) {
					if (ipNext.X > pt.X) result = 1 - result;
					else {
						var dx:Float = /*(double)*/(ip.X - pt.X);
						var dy:Float = /*(double)*/(ip.Y - pt.Y);
						var d:Float =  dx * (ipNext.Y - pt.Y) - (ipNext.X - pt.X) * dy;
						if (d == 0) return -1;
						else if ((d > 0) == (ipNext.Y > ip.Y)) result = 1 - result;
					}
				} else {
					if (ipNext.X > pt.X) {
						var dx:Float = /*(double)*/(ip.X - pt.X);
						var dy:Float = /*(double)*/(ip.Y - pt.Y);
						var d:Float =  dx * (ipNext.Y - pt.Y) - (ipNext.X - pt.X) * dy;
						if (d == 0) return -1;
						else if ((d > 0) == (ipNext.Y > ip.Y)) result = 1 - result;
					}
				}
			}
			ip.copyFrom(ipNext);
		}
		return result;
	}
	//------------------------------------------------------------------------------

	static function PointInOutPt(pt:IntPoint, op:OutPt):Int {
		//returns 0 if false, +1 if true, -1 if pt ON polygon boundary
		//See "The Point in Polygon Problem for Arbitrary Polygons" by Hormann & Agathos
		//http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.88.5498&rep=rep1&type=pdf
		var result:Int = 0;
		var startOp:OutPt = op;
		var ptx:CInt = pt.X, pty:CInt = pt.Y;
		var poly0x:CInt = op.Pt.X, poly0y:CInt = op.Pt.Y;
		do {
			op = op.Next;
			var poly1x:CInt = op.Pt.X, poly1y:CInt = op.Pt.Y;

			if (poly1y == pty) {
				if ((poly1x == ptx) || (poly0y == pty && ((poly1x > ptx) == (poly0x < ptx)))) return -1;
			}
			if ((poly0y < pty) != (poly1y < pty)) {
				if (poly0x >= ptx) {
					if (poly1x > ptx) result = 1 - result;
					else {
						// TODO: casts here too
						var dx:Float = /*(double)*/(poly0x - ptx);
						var dy:Float = /*(double)*/(poly0y - pty);
						var d:Float = dx * (poly1y - pty) - (poly1x - ptx) * dy;
						if (d == 0) return -1;
						if ((d > 0) == (poly1y > poly0y)) result = 1 - result;
					}
				} else {
					if (poly1x > ptx) {
						var dx:Float = /*(double)*/(poly0x - ptx);
						var dy:Float = /*(double)*/(poly0y - pty);
						var d:Float = dx * (poly1y - pty) - (poly1x - ptx) * dy;
						if (d == 0) return -1;
						if ((d > 0) == (poly1y > poly0y)) result = 1 - result;
					}
				}
			}
			poly0x = poly1x;
			poly0y = poly1y;
		} while (startOp != op);
		return result;
	}
	//------------------------------------------------------------------------------

	static function Poly2ContainsPoly1(outPt1:OutPt, outPt2:OutPt):Bool {
		var op:OutPt = outPt1;
		do {
			//nb: PointInPolygon returns 0 if false, +1 if true, -1 if pt on polygon
			// TODO: rename two versions of PointInPolygon
			var res:Int = PointInOutPt(op.Pt, outPt2);
			if (res >= 0) return res > 0;
			op = op.Next;
		} while (op != outPt1);
		return true;
	}
	//----------------------------------------------------------------------

	function FixupFirstLefts1(OldOutRec:OutRec, NewOutRec:OutRec):Void {
		for (i in 0...m_PolyOuts.length) {
			var outRec:OutRec = m_PolyOuts[i];
			if (outRec.Pts == null || outRec.FirstLeft == null) continue;
			var firstLeft:OutRec = ParseFirstLeft(outRec.FirstLeft);
			if (firstLeft == OldOutRec) {
				if (Poly2ContainsPoly1(outRec.Pts, NewOutRec.Pts)) outRec.FirstLeft = NewOutRec;
			}
		}
	}
	//----------------------------------------------------------------------

	function FixupFirstLefts2(OldOutRec:OutRec, NewOutRec:OutRec):Void {
		for (outRec in m_PolyOuts)
			if (outRec.FirstLeft == OldOutRec) outRec.FirstLeft = NewOutRec;
	}
	//----------------------------------------------------------------------

	static function ParseFirstLeft(FirstLeft:OutRec):OutRec {
		while (FirstLeft != null && FirstLeft.Pts == null) FirstLeft = FirstLeft.FirstLeft;
		return FirstLeft;
	}
	//------------------------------------------------------------------------------

	function JoinCommonEdges():Void {
		for (i in 0...m_Joins.length) {
			var join:Join = m_Joins[i];

			var outRec1:OutRec = GetOutRec(join.OutPt1.Idx);
			var outRec2:OutRec = GetOutRec(join.OutPt2.Idx);

			if (outRec1.Pts == null || outRec2.Pts == null) continue;

			//get the polygon fragment with the correct hole state (FirstLeft)
			//before calling JoinPoints() ...
			var holeStateRec:OutRec;
			if (outRec1 == outRec2) holeStateRec = outRec1;
			else if (Param1RightOfParam2(outRec1, outRec2)) holeStateRec = outRec2;
			else if (Param1RightOfParam2(outRec2, outRec1)) holeStateRec = outRec1;
			else holeStateRec = GetLowermostRec(outRec1, outRec2);

			if (!JoinPoints(join, outRec1, outRec2)) continue;

			if (outRec1 == outRec2) {
				//instead of joining two polygons, we've just created a new one by
				//splitting one polygon into two.
				outRec1.Pts = join.OutPt1;
				outRec1.BottomPt = null;
				outRec2 = CreateOutRec();
				outRec2.Pts = join.OutPt2;

				//update all OutRec2.Pts Idx's ...
				UpdateOutPtIdxs(outRec2);

				//We now need to check every OutRec.FirstLeft pointer. If it points
				//to OutRec1 it may need to point to OutRec2 instead ...
				if (m_UsingPolyTree) for (j in 0...m_PolyOuts.length - 1) {
					var oRec:OutRec = m_PolyOuts[j];
					if (oRec.Pts == null || ParseFirstLeft(oRec.FirstLeft) != outRec1 || oRec.IsHole == outRec1.IsHole) continue;
					if (Poly2ContainsPoly1(oRec.Pts, join.OutPt2)) oRec.FirstLeft = outRec2;
				}

				if (Poly2ContainsPoly1(outRec2.Pts, outRec1.Pts)) {
					//outRec2 is contained by outRec1 ...
					outRec2.IsHole = !outRec1.IsHole;
					outRec2.FirstLeft = outRec1;

					//fixup FirstLeft pointers that may need reassigning to OutRec1
					if (m_UsingPolyTree) FixupFirstLefts2(outRec2, outRec1);

					if ((outRec2.IsHole.xor(ReverseSolution)) == (AreaOfOutRec(outRec2) > 0)) ReversePolyPtLinks(outRec2.Pts);

				} else if (Poly2ContainsPoly1(outRec1.Pts, outRec2.Pts)) {
					//outRec1 is contained by outRec2 ...
					outRec2.IsHole = outRec1.IsHole;
					outRec1.IsHole = !outRec2.IsHole;
					outRec2.FirstLeft = outRec1.FirstLeft;
					outRec1.FirstLeft = outRec2;

					//fixup FirstLeft pointers that may need reassigning to OutRec1
					if (m_UsingPolyTree) FixupFirstLefts2(outRec1, outRec2);

					if ((outRec1.IsHole.xor(ReverseSolution)) == (AreaOfOutRec(outRec1) > 0)) ReversePolyPtLinks(outRec1.Pts);
				} else {
					//the 2 polygons are completely separate ...
					outRec2.IsHole = outRec1.IsHole;
					outRec2.FirstLeft = outRec1.FirstLeft;

					//fixup FirstLeft pointers that may need reassigning to OutRec2
					if (m_UsingPolyTree) FixupFirstLefts1(outRec1, outRec2);
				}

			} else {
				//joined 2 polygons together ...

				outRec2.Pts = null;
				outRec2.BottomPt = null;
				outRec2.Idx = outRec1.Idx;

				outRec1.IsHole = holeStateRec.IsHole;
				if (holeStateRec == outRec2) outRec1.FirstLeft = outRec2.FirstLeft;
				outRec2.FirstLeft = outRec1;

				//fixup FirstLeft pointers that may need reassigning to OutRec1
				if (m_UsingPolyTree) FixupFirstLefts2(outRec2, outRec1);
			}
		}
	}
	//------------------------------------------------------------------------------

	function UpdateOutPtIdxs(outrec:OutRec):Void {
		var op:OutPt = outrec.Pts;
		do {
			op.Idx = outrec.Idx;
			op = op.Prev;
		}
		while (op != outrec.Pts);
	}
	//------------------------------------------------------------------------------

	function DoSimplePolygons():Void {
		var i:Int = 0;
		while (i < m_PolyOuts.length) {
			var outrec:OutRec = m_PolyOuts[i++];
			var op:OutPt = outrec.Pts;
			if (op == null || outrec.IsOpen) continue;
			do //for each Pt in Polygon until duplicate found do ...
			{
				var op2:OutPt = op.Next;
				while (op2 != outrec.Pts) {
					if ((op.Pt.equals(op2.Pt)) && op2.Next != op && op2.Prev != op) {
						//split the polygon into two ...
						var op3:OutPt = op.Prev;
						var op4:OutPt = op2.Prev;
						op.Prev = op4;
						op4.Next = op;
						op2.Prev = op3;
						op3.Next = op2;

						outrec.Pts = op;
						var outrec2:OutRec = CreateOutRec();
						outrec2.Pts = op2;
						UpdateOutPtIdxs(outrec2);
						if (Poly2ContainsPoly1(outrec2.Pts, outrec.Pts)) {
							//OutRec2 is contained by OutRec1 ...
							outrec2.IsHole = !outrec.IsHole;
							outrec2.FirstLeft = outrec;
							if (m_UsingPolyTree) FixupFirstLefts2(outrec2, outrec);
						} else if (Poly2ContainsPoly1(outrec.Pts, outrec2.Pts)) {
							//OutRec1 is contained by OutRec2 ...
							outrec2.IsHole = outrec.IsHole;
							outrec.IsHole = !outrec2.IsHole;
							outrec2.FirstLeft = outrec.FirstLeft;
							outrec.FirstLeft = outrec2;
							if (m_UsingPolyTree) FixupFirstLefts2(outrec, outrec2);
						} else {
							//the 2 polygons are separate ...
							outrec2.IsHole = outrec.IsHole;
							outrec2.FirstLeft = outrec.FirstLeft;
							if (m_UsingPolyTree) FixupFirstLefts1(outrec, outrec2);
						}
						op2 = op; //ie get ready for the next iteration
					}
					op2 = op2.Next;
				}
				op = op.Next;
			}
			while (op != outrec.Pts);
		}
	}
	//------------------------------------------------------------------------------

	static public function Area(poly:Path):Float {
		// TODO: unneeded cast, right?
		var cnt:Int = /*(int)*/ poly.length;
		if (cnt < 3) return 0;
		var a:Float = 0;
		// TODO: check loop and casts, but should be fine
		var j:Int = cnt - 1;
		for (i in 0...cnt) {
			var dx:Float = /*(double)*/ poly[j].X + poly[i].X;
			var dy:Float = /*(double)*/ poly[j].Y - poly[i].Y;
			a += dx * dy;
			j = i;
		}
		return -a * 0.5;
	}
	//------------------------------------------------------------------------------

	function AreaOfOutRec(outRec:OutRec):Float {
		var op:OutPt = outRec.Pts;
		if (op == null) return 0;
		var a:Float = 0;
		do {
			// TODO: casts
			var dx:Float = /*(double)*/(op.Prev.Pt.X + op.Pt.X);
			var dy:Float = /*(double)*/(op.Prev.Pt.Y - op.Pt.Y);
			a += dx * dy;
			op = op.Next;
		} while (op != outRec.Pts);
		return a * 0.5;
	}

	//------------------------------------------------------------------------------
	// SimplifyPolygon functions ...
	// Convert self-intersecting polygons into simple polygons
	//------------------------------------------------------------------------------

	static public function SimplifyPolygon(poly:Path, fillType:PolyFillType = null):Paths {
		if (fillType == null) fillType = PolyFillType.pftEvenOdd;
		var result = new Paths();
		var c = new Clipper();
		c.StrictlySimple = true;
		c.AddPath(poly, PolyType.ptSubject, true);
		c.ExecutePaths(ClipType.ctUnion, result, fillType, fillType);
		return result;
	}
	//------------------------------------------------------------------------------

	static public function SimplifyPolygons(polys:Paths, fillType:PolyFillType = null):Paths {
		if (fillType == null) fillType = PolyFillType.pftEvenOdd;
		var result = new Paths();
		var c = new Clipper();
		c.StrictlySimple = true;
		c.AddPaths(polys, PolyType.ptSubject, true);
		c.ExecutePaths(ClipType.ctUnion, result, fillType, fillType);
		return result;
	}
	//------------------------------------------------------------------------------

	static function DistanceSqrd(pt1:IntPoint, pt2:IntPoint):Float {
		// TODO: casts
		var dx:Float = (/*(double)*/ pt1.X - pt2.X);
		var dy:Float = (/*(double)*/ pt1.Y - pt2.Y);
		return (dx * dx + dy * dy);
	}
	//------------------------------------------------------------------------------

	static function DistanceFromLineSqrd(pt:IntPoint, ln1:IntPoint, ln2:IntPoint):Float {
		//The equation of a line in general form (Ax + By + C = 0)
		//given 2 points (x¹,y¹) & (x²,y²) is ...
		//(y¹ - y²)x + (x² - x¹)y + (y² - y¹)x¹ - (x² - x¹)y¹ = 0
		//A = (y¹ - y²); B = (x² - x¹); C = (y² - y¹)x¹ - (x² - x¹)y¹
		//perpendicular distance of point (x³,y³) = (Ax³ + By³ + C)/Sqrt(A² + B²)
		//see http://en.wikipedia.org/wiki/Perpendicular_distance
		var A:Float = ln1.Y - ln2.Y;
		var B:Float = ln2.X - ln1.X;
		var C:Float = A * ln1.X + B * ln1.Y;
		C = A * pt.X + B * pt.Y - C;
		return (C * C) / (A * A + B * B);
	}
	//---------------------------------------------------------------------------

	static function SlopesNearCollinear(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint, distSqrd:Float):Bool {
		//this function is more accurate when the point that's GEOMETRICALLY 
		//between the other 2 points is the one that's tested for distance.  
		//nb: with 'spikes', either pt1 or pt3 is geometrically between the other pts                    
		if (Math.abs(pt1.X - pt2.X) > Math.abs(pt1.Y - pt2.Y)) {
			if ((pt1.X > pt2.X) == (pt1.X < pt3.X)) return DistanceFromLineSqrd(pt1, pt2, pt3) < distSqrd;
			else if ((pt2.X > pt1.X) == (pt2.X < pt3.X)) return DistanceFromLineSqrd(pt2, pt1, pt3) < distSqrd;
			else return DistanceFromLineSqrd(pt3, pt1, pt2) < distSqrd;
		} else {
			if ((pt1.Y > pt2.Y) == (pt1.Y < pt3.Y)) return DistanceFromLineSqrd(pt1, pt2, pt3) < distSqrd;
			else if ((pt2.Y > pt1.Y) == (pt2.Y < pt3.Y)) return DistanceFromLineSqrd(pt2, pt1, pt3) < distSqrd;
			else return DistanceFromLineSqrd(pt3, pt1, pt2) < distSqrd;
		}
	}
	//------------------------------------------------------------------------------

	static function PointsAreClose(pt1:IntPoint, pt2:IntPoint, distSqrd:Float):Bool {
		// TODO: casts
		var dx:Float = /*(double)*/ pt1.X - pt2.X;
		var dy:Float = /*(double)*/ pt1.Y - pt2.Y;
		return ((dx * dx) + (dy * dy) <= distSqrd);
	}
	//------------------------------------------------------------------------------

	static function ExcludeOp(op:OutPt):OutPt {
		var result:OutPt = op.Prev;
		result.Next = op.Next;
		op.Next.Prev = result;
		result.Idx = 0;
		return result;
	}
	//------------------------------------------------------------------------------

	static function CleanPolygon(path:Path, distance:Float = 1.415):Path {
		//distance = proximity in units/pixels below which vertices will be stripped. 
		//Default ~= sqrt(2) so when adjacent vertices or semi-adjacent vertices have 
		//both x & y coords within 1 unit, then the second vertex will be stripped.

		var cnt:Int = path.length;

		if (cnt == 0) return new Path();

		// TODO: check this vec
		var outPts = [for (i in 0...cnt) new OutPt()];

		for (i in 0...cnt) {
			outPts[i].Pt.copyFrom(path[i]);
			outPts[i].Next = outPts[(i + 1) % cnt];
			outPts[i].Next.Prev = outPts[i];
			outPts[i].Idx = 0;
		}

		var distSqrd:Float = distance * distance;
		var op:OutPt = outPts[0];
		while (op.Idx == 0 && op.Next != op.Prev) {
			if (PointsAreClose(op.Pt, op.Prev.Pt, distSqrd)) {
				op = ExcludeOp(op);
				cnt--;
			} else if (PointsAreClose(op.Prev.Pt, op.Next.Pt, distSqrd)) {
				ExcludeOp(op.Next);
				op = ExcludeOp(op);
				cnt -= 2;
			} else if (SlopesNearCollinear(op.Prev.Pt, op.Pt, op.Next.Pt, distSqrd)) {
				op = ExcludeOp(op);
				cnt--;
			} else {
				op.Idx = 1;
				op = op.Next;
			}
		}

		if (cnt < 3) cnt = 0;
		var result = new Path(/*TODO:cnt*/);
		for (i in 0...cnt) {
			result.push(op.Pt);
			op = op.Next;
		}
		outPts = null;
		return result;
	}
	//------------------------------------------------------------------------------

	static public function CleanPolygons(polys:Paths, distance:Float = 1.415):Paths {
		var result = new Paths(/*TODO:polys.length*/);
		for (i in 0...polys.length)
			result.push(CleanPolygon(polys[i], distance));
		return result;
	}
	//------------------------------------------------------------------------------

	/*internal*/ static public function Minkowski(pattern:Path, path:Path, IsSum:Bool, IsClosed:Bool):Paths {
		var delta:Int = (IsClosed ? 1 : 0);
		var polyCnt:Int = pattern.length;
		var pathCnt:Int = path.length;
		var result = new Paths(/*TODO:pathCnt*/);
		if (IsSum) for (i in 0...pathCnt) {
			var p = new Path(/*TODO:polyCnt*/);
			for (ip in pattern)
				p.push(new IntPoint(path[i].X + ip.X, path[i].Y + ip.Y));
			result.push(p);
		} else for (i in 0...pathCnt) {
			var p = new Path(/*TODO:polyCnt*/);
			for (ip in pattern)
				p.push(new IntPoint(path[i].X - ip.X, path[i].Y - ip.Y));
			result.push(p);
		}

		var quads:Paths = new Paths(/*TODO:(pathCnt + delta) * (polyCnt + 1)*/);
		for (i in 0...pathCnt - 1 + delta) {
			for (j in 0...polyCnt) {
				var quad = new Path(/*TODO:4*/);
				quad.push(result[i % pathCnt][j % polyCnt]);
				quad.push(result[(i + 1) % pathCnt][j % polyCnt]);
				quad.push(result[(i + 1) % pathCnt][(j + 1) % polyCnt]);
				quad.push(result[i % pathCnt][(j + 1) % polyCnt]);
				if (!Orientation(quad)) quad.reverse();
				quads.push(quad);
			}
		}
		return quads;
	}
	//------------------------------------------------------------------------------

	static public function MinkowskiSum(pattern:Path, path:Path, pathIsClosed:Bool):Paths {
		var paths:Paths = Minkowski(pattern, path, true, pathIsClosed);
		var c = new Clipper();
		c.AddPaths(paths, PolyType.ptSubject, true);
		c.ExecutePaths(ClipType.ctUnion, paths, PolyFillType.pftNonZero, PolyFillType.pftNonZero);
		return paths;
	}
	//------------------------------------------------------------------------------

	static function TranslatePath(path:Path, delta:IntPoint):Path {
		var outPath = new Path(/*TODO:path.length*/);
		for (i in 0...path.length)
			outPath.push(new IntPoint(path[i].X + delta.X, path[i].Y + delta.Y));
		return outPath;
	}
	//------------------------------------------------------------------------------

	static public function MinkowskiSumPaths(pattern:Path, paths:Paths, pathIsClosed:Bool):Paths {
		var solution = new Paths();
		var c = new Clipper();
		for (i in 0...paths.length) {
			var tmp:Paths = Minkowski(pattern, paths[i], true, pathIsClosed);
			c.AddPaths(tmp, PolyType.ptSubject, true);
			if (pathIsClosed) {
				var path:Path = TranslatePath(paths[i], pattern[0]);
				c.AddPath(path, PolyType.ptClip, true);
			}
		}
		c.ExecutePaths(ClipType.ctUnion, solution, PolyFillType.pftNonZero, PolyFillType.pftNonZero);
		return solution;
	}
	//------------------------------------------------------------------------------

	static public function MinkowskiDiff(poly1:Path, poly2:Path):Paths {
		var paths:Paths = Minkowski(poly1, poly2, false, true);
		var c = new Clipper();
		c.AddPaths(paths, PolyType.ptSubject, true);
		c.ExecutePaths(ClipType.ctUnion, paths, PolyFillType.pftNonZero, PolyFillType.pftNonZero);
		return paths;
	}
	//------------------------------------------------------------------------------

	static public function PolyTreeToPaths(polytree:PolyTree):Paths {

		var result = new Paths();
		//TODO:result.Capacity = polytree.Total;
		AddPolyNodeToPaths(polytree, NodeType.ntAny, result);
		return result;
	}
	//------------------------------------------------------------------------------

	/*internal*/ static public function AddPolyNodeToPaths(polynode:PolyNode, nt:NodeType, paths:Paths):Void {
		var match = true;
		switch (nt) {
			case NodeType.ntOpen:
				return;
			case NodeType.ntClosed:
				match = !polynode.IsOpen;
			default:
		}

		if (polynode.m_polygon.length > 0 && match) paths.push(polynode.m_polygon);
		for (pn in polynode.Childs)
			AddPolyNodeToPaths(pn, nt, paths);
	}
	//------------------------------------------------------------------------------

	static public function OpenPathsFromPolyTree(polytree:PolyTree):Paths {
		var result = new Paths();
		//TODO:result.Capacity = polytree.ChildCount;
		for (i in 0...polytree.ChildCount)
			if (polytree.Childs[i].IsOpen) result.push(polytree.Childs[i].m_polygon);
		return result;
	}
	//------------------------------------------------------------------------------

	static public function ClosedPathsFromPolyTree(polytree:PolyTree):Paths {
		var result = new Paths();
		//TODO:result.Capacity = polytree.Total;
		AddPolyNodeToPaths(polytree, NodeType.ntClosed, result);
		return result;
	}
	//------------------------------------------------------------------------------

} //end Clipper

class ClipperOffset 
{
	var m_destPolys:Paths;
	var m_srcPoly:Path;
	var m_destPoly:Path;
	var m_normals:Array<DoublePoint> = new Array<DoublePoint>();
	var m_delta:Float;
	var m_sinA:Float;
	var m_sin:Float;
	var m_cos:Float;
	var m_miterLim:Float;
	var m_StepsPerRad:Float;

	var m_lowest:IntPoint;
	var m_polyNodes:PolyNode = new PolyNode();

	// TODO: prop?
	public var ArcTolerance(default, default):Float;

	// TODO: prop?
	public var MiterLimit(default, default):Float;

	// TODO: uppercase (ISSUES: multi var (comma separated) on same line, inline var without type, Bool xor missing)
	inline static var two_pi:Float = 6.283185307179586476925286766559; // TODO: Math.PI * 2;
	inline static var def_arc_tolerance:Float = 0.25;

	public function new(miterLimit:Float = 2.0, arcTolerance:Float = def_arc_tolerance) {
		MiterLimit = miterLimit;
		ArcTolerance = arcTolerance;
		m_lowest.X = -1;
	}
	//------------------------------------------------------------------------------

	public function Clear():Void {
		m_polyNodes.Childs.clear();
		m_lowest.X = -1;
	}
	//------------------------------------------------------------------------------

	/*internal*/ static public function Round(value:Float):CInt {
		// TODO: check how to cast (this is already defined in Clipper)
		//return value < 0 ? /*(cInt)*/Std.int(value - 0.5) : /*(cInt)*/Std.int(value + 0.5);
		return Clipper.Round(value);
	}
	//------------------------------------------------------------------------------

	public function AddPath(path:Path, joinType:JoinType, endType:EndType):Void {
		var highI:Int = path.length - 1;
		if (highI < 0) return;
		var newNode = new PolyNode();
		newNode.m_jointype = joinType;
		newNode.m_endtype = endType;

		//strip duplicate points from path and also get index to the lowest point ...
		if (endType == EndType.etClosedLine || endType == EndType.etClosedPolygon) {
			while (highI > 0 && path[0].equals(path[highI])) highI--;
		}
		//TODO:newNode.m_polygon.Capacity = highI + 1;
		newNode.m_polygon.push(path[0]);
		var j:Int = 0, k:Int = 0;
		// TODO: check loop
		for (i in 1...highI + 1) {
			if (!newNode.m_polygon[j].equals(path[i])) {
				j++;
				newNode.m_polygon.push(path[i]);
				if (path[i].Y > newNode.m_polygon[k].Y
					|| (path[i].Y == newNode.m_polygon[k].Y && path[i].X < newNode.m_polygon[k].X)) 
				{
					k = j;
				}
			}
		}
		if (endType == EndType.etClosedPolygon && j < 2) return;

		m_polyNodes.AddChild(newNode);

		//if this path's lowest pt is lower than all the others then update m_lowest
		if (endType != EndType.etClosedPolygon) return;
		if (m_lowest.X < 0) m_lowest = new IntPoint(m_polyNodes.ChildCount - 1, k);
		else {
			// TODO: casts
			var ip:IntPoint = m_polyNodes.Childs[Std.int(m_lowest.X)].m_polygon[Std.int(m_lowest.Y)].clone();
			if (newNode.m_polygon[k].Y > ip.Y || (newNode.m_polygon[k].Y == ip.Y && newNode.m_polygon[k].X < ip.X)) {
				m_lowest = new IntPoint(m_polyNodes.ChildCount - 1, k);
			}
		}
	}
	//------------------------------------------------------------------------------

	public function AddPaths(paths:Paths, joinType:JoinType, endType:EndType):Void {
		for (p in paths)
			AddPath(p, joinType, endType);
	}
	//------------------------------------------------------------------------------

	function FixOrientations():Void {
		//fixup orientations of all closed paths if the orientation of the
		//closed path with the lowermost vertex is wrong ...
		// TODO: cast
		if (m_lowest.X >= 0 && !Clipper.Orientation(m_polyNodes.Childs[Std.int(m_lowest.X)].m_polygon)) {
			for (i in 0...m_polyNodes.ChildCount) {
				var node:PolyNode = m_polyNodes.Childs[i];
				if (node.m_endtype == EndType.etClosedPolygon || (node.m_endtype == EndType.etClosedLine 
					&& Clipper.Orientation(node.m_polygon))) 
				{
					node.m_polygon.reverse();
				}
			}
		} else {
			for (i in 0...m_polyNodes.ChildCount) {
				var node:PolyNode = m_polyNodes.Childs[i];
				if (node.m_endtype == EndType.etClosedLine && !Clipper.Orientation(node.m_polygon)) node.m_polygon.reverse();
			}
		}
	}
	//------------------------------------------------------------------------------

	/*internal*/ static public function GetUnitNormal(pt1:IntPoint, pt2:IntPoint):DoublePoint {
		var dx:Float = (pt2.X - pt1.X);
		var dy:Float = (pt2.Y - pt1.Y);
		if ((dx == 0) && (dy == 0)) return new DoublePoint();

		var f:Float = 1 * 1.0 / Math.sqrt(dx * dx + dy * dy);
		dx *= f;
		dy *= f;

		return new DoublePoint(dy, -dx);
	}
	//------------------------------------------------------------------------------

	function DoOffset(delta:Float):Void {
		m_destPolys = new Paths();
		m_delta = delta;

		//if Zero offset, just copy any CLOSED polygons to m_p and return ...
		if (ClipperBase.near_zero(delta)) {
			//TODO:m_destPolys.Capacity = m_polyNodes.ChildCount;
			for (i in 0...m_polyNodes.ChildCount) {
				var node:PolyNode = m_polyNodes.Childs[i];
				if (node.m_endtype == EndType.etClosedPolygon) m_destPolys.push(node.m_polygon);
			}
			return;
		}

		//see offset_triginometry3.svg in the documentation folder ...
		if (MiterLimit > 2) m_miterLim = 2 / (MiterLimit * MiterLimit);
		else m_miterLim = 0.5;

		var y:Float;
		if (ArcTolerance <= 0.0) y = def_arc_tolerance;
		else if (ArcTolerance > Math.abs(delta) * def_arc_tolerance) y = Math.abs(delta) * def_arc_tolerance;
		else y = ArcTolerance;
		//see offset_triginometry2.svg in the documentation folder ...
		var steps:Float = Math.PI / Math.acos(1 - y / Math.abs(delta));
		m_sin = Math.sin(two_pi / steps);
		m_cos = Math.cos(two_pi / steps);
		m_StepsPerRad = steps / two_pi;
		if (delta < 0.0) m_sin = -m_sin;

		// TODO: danger loops
		//TODO:m_destPolys.Capacity = m_polyNodes.ChildCount * 2;
		for (i in 0...m_polyNodes.ChildCount) {
			var node:PolyNode = m_polyNodes.Childs[i];
			m_srcPoly = node.m_polygon;

			var len:Int = m_srcPoly.length;

			if (len == 0 || (delta <= 0 && (len < 3 || node.m_endtype != EndType.etClosedPolygon))) continue;

			m_destPoly = new Path();

			if (len == 1) {
				if (node.m_jointype == JoinType.jtRound) {
					var X:Float = 1.0, Y:Float = 0.0;
					// TODO: check loop (int vs float)
					var j:Int = 1;
					while (j <= steps) {
						m_destPoly.push(new IntPoint(Round(m_srcPoly[0].X + X * delta), Round(m_srcPoly[0].Y + Y * delta)));
						var X2:Float = X;
						X = X * m_cos - m_sin * Y;
						Y = X2 * m_sin + Y * m_cos;
						j++;
					}
				} else {
					var X:Float = -1.0, Y:Float = -1.0;
					for (j in 0...4) {
						m_destPoly.push(new IntPoint(Round(m_srcPoly[0].X + X * delta), Round(m_srcPoly[0].Y + Y * delta)));
						if (X < 0) X = 1;
						else if (Y < 0) Y = 1;
						else X = -1;
					}
				}
				m_destPolys.push(m_destPoly);
				continue;
			}

			//build m_normals ...
			m_normals.clear();
			//TODO:m_normals.Capacity = len;
			for (j in 0...len - 1) {
				m_normals.push(GetUnitNormal(m_srcPoly[j], m_srcPoly[j + 1]));
			}
			if (node.m_endtype == EndType.etClosedLine || node.m_endtype == EndType.etClosedPolygon) {
				m_normals.push(GetUnitNormal(m_srcPoly[len - 1], m_srcPoly[0]));
			} else m_normals.push(m_normals[len - 2].clone());

			if (node.m_endtype == EndType.etClosedPolygon) {
				var k:Int = len - 1;
				for (j in 0...len) {
					// TODO: ref
					k = OffsetPoint(j, /*ref*/ k, node.m_jointype);
				}
				m_destPolys.push(m_destPoly);
			} else if (node.m_endtype == EndType.etClosedLine) {
				var k:Int = len - 1;
				for (j in 0...len) {
					// TODO: ref
					k = OffsetPoint(j, /*ref*/ k, node.m_jointype);
				}
				m_destPolys.push(m_destPoly);
				m_destPoly = new Path();
				//re-build m_normals ...
				var n:DoublePoint = m_normals[len - 1].clone();
				var nj:Int = len - 1;
				// TODO: check here
				while (nj > 0) {
					m_normals[nj] = new DoublePoint(-m_normals[nj - 1].X, -m_normals[nj - 1].Y);
					nj--;
				}
				m_normals[0] = new DoublePoint(-n.X, -n.Y);
				k = 0;
				// TODO: and here
				nj = len - 1;
				while (nj >= 0) {
					// TODO: ref
					k = OffsetPoint(nj, /*ref*/ k, node.m_jointype);
					nj--;
				}
				m_destPolys.push(m_destPoly);
			} else {
				var k:Int = 0;
				for (j in 1...len - 1) {
					// TODO: ref
					k = OffsetPoint(j, /*ref*/ k, node.m_jointype);
				}

				var pt1:IntPoint;
				if (node.m_endtype == EndType.etOpenButt) {
					// TODO: casts
					var j:Int = len - 1;
					pt1 = new IntPoint(/*(cInt)*/ Round(m_srcPoly[j].X + m_normals[j].X * delta), /*(cInt)*/ Round(m_srcPoly[j].Y + m_normals[j].Y * delta));
					m_destPoly.push(pt1);
					pt1 = new IntPoint(/*(cInt)*/ Round(m_srcPoly[j].X - m_normals[j].X * delta), /*(cInt)*/ Round(m_srcPoly[j].Y - m_normals[j].Y * delta));
					m_destPoly.push(pt1);
				} else {
					var j:Int = len - 1;
					k = len - 2;
					m_sinA = 0;
					m_normals[j] = new DoublePoint(-m_normals[j].X, -m_normals[j].Y);
					if (node.m_endtype == EndType.etOpenSquare) DoSquare(j, k);
					else DoRound(j, k);
				}

				//re-build m_normals ...
				// TODO: check whiles
				var nj:Int = len - 1;
				while (nj > 0) {
					m_normals[nj] = new DoublePoint(-m_normals[nj - 1].X, -m_normals[nj - 1].Y);
					nj--;
				}

				m_normals[0] = new DoublePoint(-m_normals[1].X, -m_normals[1].Y);

				k = len - 1;
				nj = k - 1;
				while (nj > 0) {
					// TODO: ref
					k = OffsetPoint(nj, /*ref*/ k, node.m_jointype);
					nj--;
				}

				if (node.m_endtype == EndType.etOpenButt) {
					// TODO: casts
					pt1 = new IntPoint(/*(cInt)*/ Round(m_srcPoly[0].X - m_normals[0].X * delta), /*(cInt)*/ Round(m_srcPoly[0].Y - m_normals[0].Y * delta));
					m_destPoly.push(pt1);
					pt1 = new IntPoint(/*(cInt)*/ Round(m_srcPoly[0].X + m_normals[0].X * delta), /*(cInt)*/ Round(m_srcPoly[0].Y + m_normals[0].Y * delta));
					m_destPoly.push(pt1);
				} else {
					k = 1;
					m_sinA = 0;
					if (node.m_endtype == EndType.etOpenSquare) DoSquare(0, 1);
					else DoRound(0, 1);
				}
				m_destPolys.push(m_destPoly);
			}
		}
	}
	//------------------------------------------------------------------------------

	// TODO: ref
	public function ExecutePathsWithDelta(/*ref*/ solution:Paths, delta:Float):Void {
		solution.clear();
		FixOrientations();
		DoOffset(delta);
		//now clean up 'corners' ...
		var clpr = new Clipper();
		clpr.AddPaths(m_destPolys, PolyType.ptSubject, true);
		if (delta > 0) {
			clpr.ExecutePaths(ClipType.ctUnion, solution,
			PolyFillType.pftPositive, PolyFillType.pftPositive);
		} else {
			var r:IntRect = ClipperBase.GetBounds(m_destPolys);
			var outer = new Path(/*TODO:4*/);

			outer.push(new IntPoint(r.left - 10, r.bottom + 10));
			outer.push(new IntPoint(r.right + 10, r.bottom + 10));
			outer.push(new IntPoint(r.right + 10, r.top - 10));
			outer.push(new IntPoint(r.left - 10, r.top - 10));

			clpr.AddPath(outer, PolyType.ptSubject, true);
			clpr.ReverseSolution = true;
			clpr.ExecutePaths(ClipType.ctUnion, solution, PolyFillType.pftNegative, PolyFillType.pftNegative);
			if (solution.length > 0) solution.shift(); //TODO: RemoveAt(0);
		}
	}
	//------------------------------------------------------------------------------

	// TODO: ref
	public function ExecutePolyTreeWithDelta(/*ref*/ solution:PolyTree, delta:Float):Void {
		solution.Clear();
		FixOrientations();
		DoOffset(delta);

		//now clean up 'corners' ...
		var clpr = new Clipper();
		clpr.AddPaths(m_destPolys, PolyType.ptSubject, true);
		if (delta > 0) {
			clpr.ExecutePolyTree(ClipType.ctUnion, solution, PolyFillType.pftPositive, PolyFillType.pftPositive);
		} else {
			var r:IntRect = ClipperBase.GetBounds(m_destPolys);
			var outer = new Path(/*TODO:4*/);

			outer.push(new IntPoint(r.left - 10, r.bottom + 10));
			outer.push(new IntPoint(r.right + 10, r.bottom + 10));
			outer.push(new IntPoint(r.right + 10, r.top - 10));
			outer.push(new IntPoint(r.left - 10, r.top - 10));

			clpr.AddPath(outer, PolyType.ptSubject, true);
			clpr.ReverseSolution = true;
			clpr.ExecutePolyTree(ClipType.ctUnion, solution, PolyFillType.pftNegative, PolyFillType.pftNegative);
			//remove the outer PolyNode rectangle ...
			if (solution.ChildCount == 1 && solution.Childs[0].ChildCount > 0) {
				var outerNode:PolyNode = solution.Childs[0];
				//TODO:solution.Childs.Capacity = outerNode.ChildCount;
				solution.Childs[0] = outerNode.Childs[0];
				solution.Childs[0].m_Parent = solution;
				for (i in 1...outerNode.ChildCount)
					solution.AddChild(outerNode.Childs[i]);
			} else solution.Clear();
		}
	}
	//------------------------------------------------------------------------------

	// TODO: ref (updated to return the modified k)
	function OffsetPoint(j:Int, /*ref*/ k:Int, jointype:JoinType):Int {
		//cross product ...
		m_sinA = (m_normals[k].X * m_normals[j].Y - m_normals[j].X * m_normals[k].Y);

		if (Math.abs(m_sinA * m_delta) < 1.0) {
			//dot product ...
			var cosA:Float = (m_normals[k].X * m_normals[j].X + m_normals[j].Y * m_normals[k].Y);
			if (cosA > 0) // angle ==> 0 degrees
			{
				m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + m_normals[k].X * m_delta), Round(m_srcPoly[j].Y + m_normals[k].Y * m_delta)));
				return k;
			}
			//else angle ==> 180 degrees   
		} else if (m_sinA > 1.0) m_sinA = 1.0;
		else if (m_sinA < -1.0) m_sinA = -1.0;

		if (m_sinA * m_delta < 0) {
			m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + m_normals[k].X * m_delta), Round(m_srcPoly[j].Y + m_normals[k].Y * m_delta)));
			m_destPoly.push(m_srcPoly[j]);
			m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + m_normals[j].X * m_delta), Round(m_srcPoly[j].Y + m_normals[j].Y * m_delta)));
		} else switch (jointype) {
			case JoinType.jtMiter:
				{
					var r:Float = 1 + (m_normals[j].X * m_normals[k].X + m_normals[j].Y * m_normals[k].Y);
					if (r >= m_miterLim) DoMiter(j, k, r);
					else DoSquare(j, k);
				}
			case JoinType.jtSquare:
				DoSquare(j, k);
			case JoinType.jtRound:
				DoRound(j, k);
		}
		k = j;
		return k;
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function DoSquare(j:Int, k:Int):Void {
		var dx:Float = Math.tan(Math.atan2(m_sinA, m_normals[k].X * m_normals[j].X + m_normals[k].Y * m_normals[j].Y) / 4);
		m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + m_delta * (m_normals[k].X - m_normals[k].Y * dx)), Round(m_srcPoly[j].Y + m_delta * (m_normals[k].Y + m_normals[k].X * dx))));
		m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + m_delta * (m_normals[j].X + m_normals[j].Y * dx)), Round(m_srcPoly[j].Y + m_delta * (m_normals[j].Y - m_normals[j].X * dx))));
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function DoMiter(j:Int, k:Int, r:Float):Void {
		var q:Float = m_delta / r;
		m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + (m_normals[k].X + m_normals[j].X) * q), Round(m_srcPoly[j].Y + (m_normals[k].Y + m_normals[j].Y) * q)));
	}
	//------------------------------------------------------------------------------

	/*internal*/ public function DoRound(j:Int, k:Int):Void {
		var a:Float = Math.atan2(m_sinA, m_normals[k].X * m_normals[j].X + m_normals[k].Y * m_normals[j].Y);
		// TODO: cast
		var steps:Int = Std.int(Math.max(Std.int(Round(m_StepsPerRad * Math.abs(a))), 1));

		var X:Float = m_normals[k].X, Y = m_normals[k].Y, X2;
		for (i in 0...steps) {
			m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + X * m_delta), Round(m_srcPoly[j].Y + Y * m_delta)));
			X2 = X;
			X = X * m_cos - m_sin * Y;
			Y = X2 * m_sin + Y * m_cos;
		}
		m_destPoly.push(new IntPoint(Round(m_srcPoly[j].X + m_normals[j].X * m_delta), Round(m_srcPoly[j].Y + m_normals[j].Y * m_delta)));
	}
	//------------------------------------------------------------------------------
}

class ClipperException
{
	var desc:String;
	
	public function new(description:String) {
		this.desc = description;
	}
	
	public function toString():String {
		return desc;
	}
}
//------------------------------------------------------------------------------

class InternalTools
{
	/** Empties an array of its contents. */
	static inline public function clear<T>(array:Array<T>)
	{
#if (cpp || php)
		array.splice(0, array.length);
#else
		untyped array.length = 0;
#end
	}
	
	static inline public function xor(a:Bool, b:Bool):Bool
	{
		return (a && !b) || (b && !a);
	}
	
	static inline public function traceEdges(edge:TEdge):Void {
		var e = edge;
		var max = 15;
		while (e != null && max > 0) {
			trace(e);
			e = e.Next;
			max--;
		}
	}
}
//------------------------------------------------------------------------------

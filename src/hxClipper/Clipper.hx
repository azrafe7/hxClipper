/*******************************************************************************
*                                                                              *
* Author    :  Angus Johnson                                                   *
* Version   :  6.4.2 (r512)                                                    *
* Date      :  27 February 2017                                                 *
* Website   :  http://www.angusj.com                                           *
* Copyright :  Angus Johnson 2010-2021                                         *
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

/** @see: http://sourceforge.net/projects/polyclipping/ */

/*
 * CS -> HX notes:
 *     [~] should be up to r512 (tests relative to sandbox from r479)
 *     [x] move some statics from ClipperBase to Clipper
 *     [ ] find a way to fix Int128 and Slopes...
 *     [x] fix multi declarations
 *     [x] fix internal
 *     [x] check capacity
 *     [x] check switches/break
 *     [x] check occurrences of IntPoint.equals()
 *     [~] fix struct vs class issues (structs are: DoublePoint, Int128, IntPoint, IntRect)
 *     [x] replace structs check for equality with .equals() instead of ==
 *     [x] replace structs assignments with clone() or copyFrom()
 *     [ ] EitherType for Paths and PolyTree in Execute() (instead of Dynamic and Std.is())?
 *     [x] adjust to haxe naming style conventions
 */

package hxClipper;

import haxe.ds.ArraySort;
import hxClipper.Clipper.ClipperBase;
import hxClipper.Clipper.DoublePoint;
import hxClipper.Clipper.IntPoint;

using hxClipper.Clipper.InternalTools;

//USE_INT64: When enabled 64bit ints are used instead of 32bit ints. This
//impacts performance but coordinate values are not limited to the range +/- 46340
//#define USE_INT64

//USE_XYZ: adds a Z member to IntPoint. Adds a minor cost to performance.
//#define USE_XYZ

//USE_LINES: Enables open path clipping. Adds a very minor cost to performance.
//#define USE_LINES


#if !USE_INT64
typedef CInt = Int;
#else
typedef CInt = Int64;
#end

typedef Path = Array<IntPoint>;
typedef Paths = Array<Array<IntPoint>>;

@:expose()
@:native("DoublePoint")
class DoublePoint
{
  public var x:Float;
  public var y:Float;

  public function new(x:Float = 0, y:Float = 0) {
    this.x = x;
    this.y = y;
  }

  #if (CLIPPER_INLINE) inline #end
  public function clone() {
    return new DoublePoint(this.x, this.y);
  }

  #if (CLIPPER_INLINE) inline #end
  static public function fromDoublePoint(dp:DoublePoint) {
    return dp.clone();
  }

  #if (CLIPPER_INLINE) inline #end
  static public function fromIntPoint(ip:IntPoint) {
    return new DoublePoint(ip.x, ip.y);
  }

  #if (python) @:native("__repr__") #end
  public function toString():String {
    return '(x:$x, y:$y)';
  }
}


//------------------------------------------------------------------------------
// PolyTree & PolyNode classes
//------------------------------------------------------------------------------

@:expose()
@:native("PolyTree")
@:allow(hxClipper.ClipperBase)
class PolyTree extends PolyNode
{
  /*internal*/ var mAllPolys:Array<PolyNode> = new Array<PolyNode>();

  //The GC probably handles this cleanup more efficiently ...
  //~PolyTree(){Clear();}

  public function new():Void { super(); }

  public function clear():Void {
    for (i in 0...mAllPolys.length) {
      mAllPolys[i] = null;
    }
    mAllPolys.clear();
    mChildren.clear();
  }

  #if (CLIPPER_INLINE) inline #end
  public function getFirst():PolyNode {
    if (mChildren.length > 0) return mChildren[0];
    else return null;
  }

  public var total(get, never):Int;
  #if (CLIPPER_INLINE) inline #end
  function get_total():Int {
    var result = mAllPolys.length;
    //with negative offsets, ignore the hidden outer polygon ...
    if (result > 0 && mChildren[0] != mAllPolys[0]) result--;
    return result;
  }

}

@:expose()
@:native("PolyNode")
@:allow(hxClipper.ClipperBase)
@:allow(hxClipper.ClipperOffset)
class PolyNode
{
  /*internal*/ var mParent:PolyNode;
  /*internal*/ var mPolygon:Path = new Path();
  /*internal*/ var mIndex:Int;
  /*internal*/ var mJoinType:JoinType;
  /*internal*/ var mEndtype:EndType;
  /*internal*/ var mChildren:Array<PolyNode> = new Array<PolyNode>();

  public function new() { }

  function isHoleNode():Bool {
    var result = true;
    var node:PolyNode = mParent;
    while (node != null) {
      result = !result;
      node = node.mParent;
    }
    return result;
  }

  public var numChildren(get, never):Int;
  #if (CLIPPER_INLINE) inline #end
  function get_numChildren():Int {
    return mChildren.length;
  }

  public var contour(get, never):Path;
  #if (CLIPPER_INLINE) inline #end
  function get_contour():Path {
    return mPolygon;
  }

  /*internal*/ function addChild(child:PolyNode):Void {
    var cnt = mChildren.length;
    mChildren.push(child);
    child.mParent = this;
    child.mIndex = cnt;
  }

  public function getNext():PolyNode {
    if (mChildren.length > 0) return mChildren[0];
    else return getNextSiblingUp();
  }

  /*internal*/ function getNextSiblingUp():PolyNode {
    if (mParent == null) return null;
    else if (mIndex == mParent.mChildren.length - 1) return mParent.getNextSiblingUp();
    else return mParent.mChildren[mIndex + 1];
  }

  public var children(get, never):Array<PolyNode>;
  #if (CLIPPER_INLINE) inline #end
  function get_children():Array<PolyNode> {
    return mChildren;
  }

  public var parent(get, null):PolyNode;
  #if (CLIPPER_INLINE) inline #end
  public function get_parent():PolyNode {
    return mParent;
  }

  public var isHole(get, never):Bool;
  #if (CLIPPER_INLINE) inline #end
  function get_isHole():Bool {
    return isHoleNode();
  }

  /*NOTE: check why of this property*/
  public var isOpen(default, default):Bool;
}


#if USE_INT64
//------------------------------------------------------------------------------
// Int128 struct (enables safe math on signed 64bit integers)
// eg Int128 val1((Int64)9223372036854775807); //ie 2^63 -1
//    Int128 val2((Int64)9223372036854775807);
//    Int128 val3 = val1 * val2;
//    val3.ToString => "85070591730234615847396907784232501249" (8.5e+37)
//------------------------------------------------------------------------------

/*internal*/ class Int128 {
  var hi:Int64;
  var lo:Int64;  // this will make use of unsigned versions of ops

  static var zero64:Int64 = Int64.make(0, 0);
  static var one64:Int64 = Int64.make(0, 1);
  static inline var shift64:Float = 18446744073709551616.0; //2^64

  public function new(hi:Int64, lo:Int64) {
    this.lo = lo;
    this.hi = hi;
  }

  public function isNeg():Bool {
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
#end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

@:expose()
@:native("IntPoint")
class IntPoint
{
  public var x:CInt;
  public var y:CInt;
#if USE_XYZ
  public var z:CInt;

  public function new(x:CInt = 0, y:CInt = 0, z:CInt = 0) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  #if (CLIPPER_INLINE) inline #end
  public function clone() {
    return new IntPoint(this.x, this.y, this.z);
  }

  #if (CLIPPER_INLINE) inline #end
  public function copyFrom(ip:IntPoint):Void {
    this.x = ip.x;
    this.y = ip.y;
    this.z = ip.z;
  }

  #if (python) @:native("__repr__") #end
  public function toString():String {
    return '(x:$x, y:$y, z:$z)';
  }

  // NOTE: casts?
  static public function fromFloats(x:Float, y:Float, z:Float = 0) {
    return new IntPoint(Std.int(x), Std.int(y), Std.int(z));
  }

  #if (CLIPPER_INLINE) inline #end
  static public function fromDoublePoint(dp:DoublePoint) {
    return fromFloats(dp.x, dp.y, 0);
  }

  #if (CLIPPER_INLINE) inline #end
  static public function fromIntPoint(pt:IntPoint) {
    return pt.clone();
  }
#else
  public function new(x:CInt = 0, y:CInt = 0) {
    this.x = x;
    this.y = y;
  }

  #if (CLIPPER_INLINE) inline #end
  public function clone() {
    return new IntPoint(this.x, this.y);
  }

  #if (python) @:native("__repr__") #end
  public function toString():String {
    return '(x:$x, y:$y)';
  }

  #if (CLIPPER_INLINE) inline #end
  public function copyFrom(ip:IntPoint):Void {
    this.x = ip.x;
    this.y = ip.y;
  }

  static public function fromFloats(x:Float, y:Float) {
    return new IntPoint(Std.int(x), Std.int(y));
  }

  #if (CLIPPER_INLINE) inline #end
  static public function fromDoublePoint(dp:DoublePoint) {
    return fromFloats(dp.x, dp.y);
  }

  #if (CLIPPER_INLINE) inline #end
  static public function fromIntPoint(pt:IntPoint) {
    return pt.clone();
  }
#end

  #if (CLIPPER_INLINE) inline #end
  public function equals(ip:IntPoint):Bool {
    return this.x == ip.x && this.y == ip.y;
  }

  /* NOTE: removed IntPoint ops
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

@:expose()
@:native("IntRect")
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

  #if (CLIPPER_INLINE) inline #end
  public function clone(ir:IntRect):IntRect {
    return new IntRect(left, top, right, bottom);
  }
}

@:expose()
@:native("ClipType")
enum ClipType {
  CT_INTERSECTION;
  CT_UNION;
  CT_DIFFERENCE;
  CT_XOR;
}

@:expose()
@:native("PolyType")
enum PolyType {
  PT_SUBJECT;
  PT_CLIP;
}

//By far the most widely used winding rules for polygon filling are
//EvenOdd & NonZero (GDI, GDI+, XLib, OpenGL, Cairo, AGG, Quartz, SVG, Gr32)
//Others rules include Positive, Negative and ABS_GTR_EQ_TWO (only in OpenGL)
//see http://glprogramming.com/red/chapter11.html
@:expose()
@:native("PolyFillType")
enum PolyFillType {
  PFT_EVEN_ODD;
  PFT_NON_ZERO;
  PFT_POSITIVE;
  PFT_NEGATIVE;
}

@:expose()
@:native("JoinType")
enum JoinType {
  JT_SQUARE;
  JT_ROUND;
  JT_MITER;
}

@:expose()
@:native("EndType")
enum EndType {
  ET_CLOSED_POLYGON;
  ET_CLOSED_LINE;
  ET_OPEN_BUTT;
  ET_OPEN_SQUARE;
  ET_OPEN_ROUND;
}

/*internal*/ private enum EdgeSide {
  ES_LEFT;
  ES_RIGHT;
}
/*internal*/ private enum Direction {
  D_RIGHT_TO_LEFT;
  D_LEFT_TO_RIGHT;
}

/*internal*/ private enum NodeType {
  NT_ANY;
  NT_OPEN;
  NT_CLOSED;
}

@:allow(hxClipper.ClipperBase)
/*internal*/ private class TEdge
{
  /*internal*/ var bot:IntPoint = new IntPoint();
  /*internal*/ var curr:IntPoint = new IntPoint(); //current (updated for every new scanbeam)
  /*internal*/ var top:IntPoint = new IntPoint();
  /*internal*/ var delta:IntPoint = new IntPoint();
  /*internal*/ var dx:Float;
  /*internal*/ var polyType:PolyType;
  /*internal*/ var side:EdgeSide; //side only refers to current side of solution poly
  /*internal*/ var windDelta:Int; //1 or -1 depending on winding direction
  /*internal*/ var windCnt:Int;
  /*internal*/ var windCnt2:Int; //winding count of the opposite polytype
  /*internal*/ var outIdx:Int;
  /*internal*/ var next:TEdge;
  /*internal*/ var prev:TEdge;
  /*internal*/ var nextInLML:TEdge;
  /*internal*/ var nextInAEL:TEdge;
  /*internal*/ var prevInAEL:TEdge;
  /*internal*/ var nextInSEL:TEdge;
  /*internal*/ var prevInSEL:TEdge;

  /*internal*/ function new() { }

  #if (python) @:native("__repr__") #end
  function toString():String {
    return 'TE(curr:${curr.toString()}, bot:${bot.toString()}, top:${top.toString()}, dx:$dx)';
  }
}

@:expose()
@:native("IntersectNode")
@:allow(hxClipper.ClipperBase)
class IntersectNode
{
  /*internal*/ var edge1:TEdge;
  /*internal*/ var edge2:TEdge;
  /*internal*/ var pt:IntPoint = new IntPoint();

  /*internal*/ function new() { }
}

/* NOTE: fix the comparer (look into ListSort, or change List with Array
class MyIntersectNodeSort: IComparer < IntersectNode > {
  public int Compare(IntersectNode node1, IntersectNode node2) {
    cInt i = node2.pt.Y - node1.pt.Y;
    if (i > 0) return 1;
    else if (i < 0) return -1;
    else return 0;
  }
}*/

@:allow(hxClipper.ClipperBase)
/*internal*/ private class LocalMinima
{
  /*internal*/ var y:CInt;
  /*internal*/ var leftBound:TEdge;
  /*internal*/ var rightBound:TEdge;
  /*internal*/ var next:LocalMinima;

  /*internal*/ function new() { }
}

@:allow(hxClipper.ClipperBase)
/*internal*/ private class Scanbeam
{
  /*internal*/ var y:CInt;
  /*internal*/ var next:Scanbeam;

  /*internal*/ function new() { }
}

@:allow(hxClipper.ClipperBase)
/*internal*/ private class Maxima
{
  /*internal*/ var x:CInt;
  /*internal*/ var next:Maxima;
  /*internal*/ var prev:Maxima;

  /*internal*/ function new() { }
}

//OutRec: contains a path in the clipping solution. Edges in the AEL will
//carry a pointer to an OutRec when they are part of the clipping solution.
@:allow(hxClipper.ClipperBase)
/*internal*/ private class OutRec
{
  /*internal*/ var idx:Int;
  /*internal*/ var isHole:Bool;
  /*internal*/ var isOpen:Bool;
  /*internal*/ var firstLeft:OutRec; //see comments in clipper.pas
  /*internal*/ var pts:OutPt;
  /*internal*/ var bottomPt:OutPt;
  /*internal*/ var polyNode:PolyNode; //NOTE: check name here

  /*internal*/ function new() { }
}

@:allow(hxClipper.ClipperBase)
/*internal*/ private class OutPt
{
  /*internal*/ var idx:Int;
  /*internal*/ var pt:IntPoint = new IntPoint();
  /*internal*/ var next:OutPt;
  /*internal*/ var prev:OutPt;

  /*internal*/ function new() { }
}

@:allow(hxClipper.ClipperBase)
/*internal*/ private class Join
{
  /*internal*/ var outPt1:OutPt;
  /*internal*/ var outPt2:OutPt;
  /*internal*/ var offPt:IntPoint = new IntPoint();

  /*internal*/ function new() { }
}

@:allow(hxClipper.Clipper)
@:allow(hxClipper.ClipperOffset)
class ClipperBase
{
  // NOTE: refactor to uppercase
  inline static var HORIZONTAL:Float = -3.4E+38;
  inline static var SKIP:Int = -2;
  inline static var UNASSIGNED:Int = -1;
  inline static var TOLERANCE:Float = 1.0E-20;

  // NOTE: camelcase
  /*internal*/ static function nearZero(val:Float):Bool {
    return (val > -TOLERANCE) && (val < TOLERANCE);
  }

#if !USE_INT64
  inline static var LO_RANGE:CInt = 0x7FFF;
  inline static var HI_RANGE:CInt = 0x7FFF;
#else
  inline static var LO_RANGE:CInt = 0x3FFFFFFF;
  inline static var HI_RANGE:CInt = 0x3FFFFFFFFFFFFFFFL;
#end

  /*internal*/ var mMinimaList:LocalMinima;
  /*internal*/ var mCurrentLM:LocalMinima;
  /*internal*/ var mEdges:Array<Array<TEdge>> = new Array<Array<TEdge>>();
  /*internal*/ var mScanbeam:Scanbeam;
  /*internal*/ var mPolyOuts:Array<OutRec>;
  /*internal*/ var mActiveEdges:TEdge;
  /*internal*/ var mUseFullRange:Bool;
  /*internal*/ var mHasOpenPaths:Bool;

  //------------------------------------------------------------------------------

  //NOTE: check this prop
  public var preserveCollinear(default, default):Bool;
  //------------------------------------------------------------------------------

  /*NOTE: check swap
  public function Swap(ref cInt val1, ref cInt val2):Void {
    cInt tmp = val1;
    val1 = val2;
    val2 = tmp;
  }*/
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ static function isHorizontal(e:TEdge):Bool {
    return e.delta.y == 0;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function pointIsVertex(pt:IntPoint, pp:OutPt):Bool {
    var pp2:OutPt = pp;
    do {
      if (pp2.pt.equals(pt)) return true;
      pp2 = pp2.next;
    } while (pp2 != pp);
    return false;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function pointOnLineSegment(pt:IntPoint, linePt1:IntPoint, linePt2:IntPoint, useFullRange:Bool):Bool {
  #if USE_INT64
    if (useFullRange) return ((pt.x == linePt1.x) && (pt.y == linePt1.y)) || ((pt.x == linePt2.x) && (pt.y == linePt2.y))
                 || (((pt.x > linePt1.x) == (pt.x < linePt2.x)) && ((pt.y > linePt1.y) == (pt.y < linePt2.y))
                 && ((Int128.Int128Mul((pt.x - linePt1.x), (linePt2.y - linePt1.y)) == Int128.Int128Mul((linePt2.x - linePt1.x), (pt.y - linePt1.y)))));
    else
  #else
    return ((pt.x == linePt1.x) && (pt.y == linePt1.y)) || ((pt.x == linePt2.x) && (pt.y == linePt2.y))
         || (((pt.x > linePt1.x) == (pt.x < linePt2.x)) && ((pt.y > linePt1.y) == (pt.y < linePt2.y))
         && ((pt.x - linePt1.x) * (linePt2.y - linePt1.y) == (linePt2.x - linePt1.x) * (pt.y - linePt1.y)));
  #end
  }
  //------------------------------------------------------------------------------

  /*internal*/ function pointOnPolygon(pt:IntPoint, pp:OutPt, useFullRange:Bool):Bool {
    var pp2:OutPt = pp;
    while (true) {
      if (pointOnLineSegment(pt, pp2.pt, pp2.next.pt, useFullRange)) return true;
      pp2 = pp2.next;
      if (pp2 == pp) break;
    }
    return false;
  }
  //------------------------------------------------------------------------------

  /* NOTE: fix these Int128*/
  #if (CLIPPER_INLINE) inline #end
  /*internal*/ static function slopesEqual(e1:TEdge, e2:TEdge, useFullRange:Bool):Bool {
  #if USE_INT64
    if (useFullRange) return Int128.mul(e1.delta.y, e2.delta.x) == Int128.mul(e1.delta.x, e2.delta.y);
    else
  #else
    return /*(cInt)*/(e1.delta.y) * (e2.delta.x) == /*(cInt)*/(e1.delta.x) * (e2.delta.y);
  #end
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ static function slopesEqual3(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint, useFullRange:Bool):Bool {
  #if USE_INT64
    if (useFullRange) return Int128.Int128Mul(pt1.y - pt2.y, pt2.x - pt3.x) == Int128.Int128Mul(pt1.x - pt2.x, pt2.y - pt3.y);
    else
  #else
    return /*(cInt)*/(pt1.y - pt2.y) * (pt2.x - pt3.x) - /*(cInt)*/(pt1.x - pt2.x) * (pt2.y - pt3.y) == 0;
  #end
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ static function slopesEqual4(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint, pt4:IntPoint, useFullRange:Bool):Bool {
  #if USE_INT64
    if (useFullRange) return Int128.Int128Mul(pt1.y - pt2.y, pt3.x - pt4.x) == Int128.Int128Mul(pt1.x - pt2.x, pt3.y - pt4.y);
    else
  #else
    return /*(cInt)*/(pt1.y - pt2.y) * (pt3.x - pt4.x) - /*(cInt)*/(pt1.x - pt2.x) * (pt3.y - pt4.y) == 0;
  #end
  }
  //------------------------------------------------------------------------------

  /*internal*/ function new() //constructor (nb: no external instantiation)
  {
    mMinimaList = null;
    mCurrentLM = null;
    mUseFullRange = false;
    mHasOpenPaths = false;
  }
  //------------------------------------------------------------------------------

  public function clear():Void {
    disposeLocalMinimaList();
    for (i in 0...mEdges.length) {
      for (j in 0...mEdges[i].length) {
        mEdges[i][j] = null;
      }
      mEdges[i].clear();
    }
    mEdges.clear();
    mUseFullRange = false;
    mHasOpenPaths = false;
  }
  //------------------------------------------------------------------------------

  function disposeLocalMinimaList():Void {
    while (mMinimaList != null) {
      var tmpLm:LocalMinima = mMinimaList.next;
      mMinimaList = null;
      mMinimaList = tmpLm;
    }
    mCurrentLM = null;
  }
  //------------------------------------------------------------------------------

  // NOTE: check ref - changed to return it
  function rangeTest(pt:IntPoint, /*ref*/ useFullRange:Bool):Bool {
    //return true;  // to skip the range test
    if (useFullRange) {
    #if (!CLIPPER_NO_EXCEPTIONS)
      if (pt.x > HI_RANGE || pt.y > HI_RANGE || -pt.x > HI_RANGE || -pt.y > HI_RANGE)
        throw new ClipperException("Coordinate outside allowed range");
    #end
    } else if (pt.x > LO_RANGE || pt.y > LO_RANGE || -pt.x > LO_RANGE || -pt.y > LO_RANGE) {
      useFullRange = true;
      rangeTest(pt, /*ref*/ useFullRange);
    }
    return useFullRange;
  }
  //------------------------------------------------------------------------------

  function initEdge(e:TEdge, eNext:TEdge, ePrev:TEdge, pt:IntPoint):Void {
    e.next = eNext;
    e.prev = ePrev;
    e.curr.copyFrom(pt);
    e.outIdx = UNASSIGNED;
  }
  //------------------------------------------------------------------------------

  function initEdge2(e:TEdge, polyType:PolyType):Void {
    if (e.curr.y >= e.next.curr.y) {
      e.bot.copyFrom(e.curr);
      e.top.copyFrom(e.next.curr);
    } else {
      e.top.copyFrom(e.curr);
      e.bot.copyFrom(e.next.curr);
    }
    setDx(e);
    e.polyType = polyType;
  }
  //------------------------------------------------------------------------------

  function findNextLocMin(e:TEdge):TEdge {
    var e2:TEdge;
    while (true) {
      while (!e.bot.equals(e.prev.bot) || e.curr.equals(e.top)) e = e.next;
      if (e.dx != HORIZONTAL && e.prev.dx != HORIZONTAL) break;
      while (e.prev.dx == HORIZONTAL) e = e.prev;
      e2 = e;
      while (e.dx == HORIZONTAL) e = e.next;
      if (e.top.y == e.prev.bot.y) continue; //ie just an intermediate horz.
      if (e2.prev.bot.x < e.bot.x) e = e2;
      break;
    }
    return e;
  }
  //------------------------------------------------------------------------------

  function processBound(e:TEdge, leftBoundIsForward:Bool):TEdge {
    var eStart:TEdge, result = e;
    var horz:TEdge;

    if (result.outIdx == SKIP) {
      //check if there are edges beyond the skip edge in the bound and if so
      //create another LocMin and calling ProcessBound once more ...
      e = result;
      if (leftBoundIsForward) {
        while (e.top.y == e.next.bot.y) e = e.next;
        while (e != result && e.dx == HORIZONTAL) e = e.prev;
      } else {
        while (e.top.y == e.prev.bot.y) e = e.prev;
        while (e != result && e.dx == HORIZONTAL) e = e.next;
      }
      if (e == result) {
        if (leftBoundIsForward) result = e.next;
        else result = e.prev;
      } else {
        //there are more edges in the bound beyond result starting with E
        if (leftBoundIsForward) e = result.next;
        else e = result.prev;
        var locMin = new LocalMinima();
        locMin.next = null;
        locMin.y = e.bot.y;
        locMin.leftBound = null;
        locMin.rightBound = e;
        e.windDelta = 0;
        result = processBound(e, leftBoundIsForward);
        insertLocalMinima(locMin);
      }
      return result;
    }

    if (e.dx == HORIZONTAL) {
      //We need to be careful with open paths because this may not be a
      //true local minima (ie E may be following a skip edge).
      //Also, consecutive horz. edges may start heading left before going right.
      if (leftBoundIsForward) eStart = e.prev;
      else eStart = e.next;

      if (eStart.dx == HORIZONTAL) //ie an adjoining horizontal skip edge
      {
        if (eStart.bot.x != e.bot.x && eStart.top.x != e.bot.x) reverseHorizontal(e);
      } else if (eStart.bot.x != e.bot.x) reverseHorizontal(e);
    }

    eStart = e;
    if (leftBoundIsForward) {
      while (result.top.y == result.next.bot.y && result.next.outIdx != SKIP) result = result.next;

      if (result.dx == HORIZONTAL && result.next.outIdx != SKIP) {
        //nb: at the top of a bound, horizontals are added to the bound
        //only when the preceding edge attaches to the horizontal's left vertex
        //unless a Skip edge is encountered when that becomes the top divide
        horz = result;
        while (horz.prev.dx == HORIZONTAL) horz = horz.prev;
        if (horz.prev.top.x > result.next.top.x) result = horz.prev;
      }
      while (e != result) {
        e.nextInLML = e.next;
        if (e.dx == HORIZONTAL && e != eStart && e.bot.x != e.prev.top.x) reverseHorizontal(e);
        e = e.next;
      }
      if (e.dx == HORIZONTAL && e != eStart && e.bot.x != e.prev.top.x) reverseHorizontal(e);
      result = result.next; //move to the edge just beyond current bound
    } else {
      while (result.top.y == result.prev.bot.y && result.prev.outIdx != SKIP) result = result.prev;

      if (result.dx == HORIZONTAL && result.prev.outIdx != SKIP) {
        horz = result;
        while (horz.next.dx == HORIZONTAL) horz = horz.next;
        if (horz.next.top.x == result.prev.top.x || horz.next.top.x > result.prev.top.x) result = horz.next;
      }

      while (e != result) {
        e.nextInLML = e.prev;
        if (e.dx == HORIZONTAL && e != eStart && e.bot.x != e.next.top.x) reverseHorizontal(e);
        e = e.prev;
      }
      if (e.dx == HORIZONTAL && e != eStart && e.bot.x != e.next.top.x) reverseHorizontal(e);
      result = result.prev; //move to the edge just beyond current bound
    }
    return result;
  }
  //------------------------------------------------------------------------------


  public function addPath(path:Path, polyType:PolyType, closed:Bool):Bool {
#if (!CLIPPER_NO_EXCEPTIONS)
  #if USE_LINES
    if (!closed && polyType == PolyType.PT_CLIP) throw new ClipperException("AddPath: Open paths must be subject.");
  #else
    if (!closed) throw new ClipperException("AddPath: Open paths have been disabled (define USE_LINES to enable them).");
  #end
#end
    //NOTE: why the cast
    var highI = /*(int)*/ path.length - 1;
    if (closed) while (highI > 0 && (path[highI].equals(path[0]))) --highI;
    while (highI > 0 && (path[highI].equals(path[highI - 1]))) --highI;
    if ((closed && highI < 2) || (!closed && highI < 1)) return false;

    //create a new edge array ...
    var edges = new Array<TEdge>(/*NOTE:highI + 1*/);
    for (i in 0...highI + 1) edges.push(new TEdge());

    var isFlat = true;

    //1. Basic (first) edge initialization ...
    edges[1].curr.copyFrom(path[1]);
    // NOTE: check refs
    mUseFullRange = rangeTest(path[0], /*ref*/ mUseFullRange);
    mUseFullRange = rangeTest(path[highI], /*ref*/ mUseFullRange);
    initEdge(edges[0], edges[1], edges[highI], path[0]);
    initEdge(edges[highI], edges[0], edges[highI - 1], path[highI]);
    // NOTE: check loop
    var i = highI - 1;
    while (i >= 1) {
      mUseFullRange = rangeTest(path[i], /*ref*/ mUseFullRange);
      initEdge(edges[i], edges[i + 1], edges[i - 1], path[i]);
      --i;
    }
    var eStart:TEdge = edges[0];

    //2. Remove duplicate vertices, and (when closed) collinear edges ...
    var e:TEdge = eStart, eLoopStop:TEdge = eStart;
    while (true) {
      //nb: allows matching start and end points when not Closed ...
      if (e.curr.equals(e.next.curr) && (closed || e.next != eStart)) {
        if (e == e.next) break;
        if (e == eStart) eStart = e.next;
        e = removeEdge(e);
        eLoopStop = e;
        continue;
      }
      if (e.prev == e.next) break; //only two vertices
      else if (closed && ClipperBase.slopesEqual3(e.prev.curr, e.curr, e.next.curr, mUseFullRange)
           && (!preserveCollinear || !pt2IsBetweenPt1AndPt3(e.prev.curr, e.curr, e.next.curr)))
      {
        //Collinear edges are allowed for open paths but in closed paths
        //the default is to merge adjacent collinear edges into a single edge.
        //However, if the PreserveCollinear property is enabled, only overlapping
        //collinear edges (ie spikes) will be removed from closed paths.
        if (e == eStart) eStart = e.next;
        e = removeEdge(e);
        e = e.prev;
        eLoopStop = e;
        continue;
      }
      e = e.next;
      if ((e == eLoopStop) || (!closed && e.next == eStart)) break;
    }

    if ((!closed && (e == e.next)) || (closed && (e.prev == e.next))) return false;

    if (!closed) {
      mHasOpenPaths = true;
      eStart.prev.outIdx = SKIP;
    }

    //3. Do second stage of edge initialization ...
    e = eStart;
    do {
      initEdge2(e, polyType);
      e = e.next;
      if (isFlat && e.curr.y != eStart.curr.y) isFlat = false;
    } while (e != eStart);

    //4. Finally, add edge bounds to LocalMinima list ...

    //Totally flat paths must be handled differently when adding them
    //to LocalMinima list to avoid endless loops etc ...
    if (isFlat) {
      if (closed) return false;
      e.prev.outIdx = SKIP;
      var locMin = new LocalMinima();
      locMin.next = null;
      locMin.y = e.bot.y;
      locMin.leftBound = null;
      locMin.rightBound = e;
      locMin.rightBound.side = EdgeSide.ES_RIGHT;
      locMin.rightBound.windDelta = 0;
      while (true) {
        if (e.bot.x != e.prev.top.x) reverseHorizontal(e);
        if (e.next.outIdx == SKIP) break;
        e.nextInLML = e.next;
        e = e.next;
      }
      insertLocalMinima(locMin);
      mEdges.push(edges);
      return true;
    }

    mEdges.push(edges);
    var leftBoundIsForward:Bool;
    var eMin:TEdge = null;

    //workaround to avoid an endless loop in the while loop below when
    //open paths have matching start and end points ...
    if (e.prev.bot.equals(e.prev.top)) e = e.next;

    while (true) {
      e = findNextLocMin(e);
      if (e == eMin) break;
      else if (eMin == null) eMin = e;

      //E and E.prev now share a local minima (left aligned if horizontal).
      //Compare their slopes to find which starts which bound ...
      var locMin = new LocalMinima();
      locMin.next = null;
      locMin.y = e.bot.y;
      if (e.dx < e.prev.dx) {
        locMin.leftBound = e.prev;
        locMin.rightBound = e;
        leftBoundIsForward = false; //Q.nextInLML = Q.prev
      } else {
        locMin.leftBound = e;
        locMin.rightBound = e.prev;
        leftBoundIsForward = true; //Q.nextInLML = Q.next
      }
      locMin.leftBound.side = EdgeSide.ES_LEFT;
      locMin.rightBound.side = EdgeSide.ES_RIGHT;

      if (!closed) locMin.leftBound.windDelta = 0;
      else if (locMin.leftBound.next == locMin.rightBound) locMin.leftBound.windDelta = -1;
      else locMin.leftBound.windDelta = 1;
      locMin.rightBound.windDelta = -locMin.leftBound.windDelta;

      e = processBound(locMin.leftBound, leftBoundIsForward);
      if (e.outIdx == SKIP) e = processBound(e, leftBoundIsForward);

      var E2:TEdge = processBound(locMin.rightBound, !leftBoundIsForward);
      if (E2.outIdx == SKIP) E2 = processBound(E2, !leftBoundIsForward);

      if (locMin.leftBound.outIdx == SKIP) locMin.leftBound = null;
      else if (locMin.rightBound.outIdx == SKIP) locMin.rightBound = null;
      insertLocalMinima(locMin);
      if (!leftBoundIsForward) e = E2;
    }
    return true;

  }
  //------------------------------------------------------------------------------

  public function addPaths(paths:Paths, polyType:PolyType, closed:Bool):Bool {
    var result = false;
    for (i in 0...paths.length) {
      if (addPath(paths[i], polyType, closed)) result = true;
    }
    return result;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function pt2IsBetweenPt1AndPt3(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint):Bool {
    if ((pt1.equals(pt3)) || (pt1.equals(pt2)) || (pt3.equals(pt2))) return false;
    else if (pt1.x != pt3.x) return (pt2.x > pt1.x) == (pt2.x < pt3.x);
    else return (pt2.y > pt1.y) == (pt2.y < pt3.y);
  }
  //------------------------------------------------------------------------------

  function removeEdge(e:TEdge):TEdge {
    //removes e from double_linked_list (but without removing from memory)
    e.prev.next = e.next;
    e.next.prev = e.prev;
    var result = e.next;
    e.prev = null; //flag as removed (see ClipperBase.Clear)
    return result;
  }
  //------------------------------------------------------------------------------

  function setDx(e:TEdge):Void {
    e.delta.x = (e.top.x - e.bot.x);
    e.delta.y = (e.top.y - e.bot.y);
    if (e.delta.y == 0) e.dx = HORIZONTAL;
    else {  // NOTE: check cast to float
      var deltaX:Float = e.delta.x;
      e.dx = deltaX / (e.delta.y);
    }
  }
  //---------------------------------------------------------------------------

  function insertLocalMinima(newLm:LocalMinima):Void {
    if (mMinimaList == null) {
      mMinimaList = newLm;
    } else if (newLm.y >= mMinimaList.y) {
      newLm.next = mMinimaList;
      mMinimaList = newLm;
    } else {
      var tmpLm:LocalMinima = mMinimaList;
      // NOTE: check this loop
      while (tmpLm.next != null && (newLm.y < tmpLm.next.y)) {
        tmpLm = tmpLm.next;
      }
      newLm.next = tmpLm.next;
      tmpLm.next = newLm;
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: out (r493 to r494)
  /*internal*/ function popLocalMinima(y:CInt, /*out*/ current:{lm:LocalMinima}):Bool {
    current.lm = mCurrentLM;

    if (mCurrentLM != null && mCurrentLM.y == y)
    {
      mCurrentLM = mCurrentLM.next;
      return true;
    }
    return false;
  }
  //------------------------------------------------------------------------------

  // NOTE: check refs
  function reverseHorizontal(e:TEdge):Void {
    //swap horizontal edges' top and bottom x's so they follow the natural
    //progression of the bounds - ie so their xbots will align with the
    //adjoining lower edge. [Helpful in the ProcessHorizontal() method.]
    var tmp = e.top.x;
    e.top.x = e.bot.x;
    e.bot.x = tmp;
  #if USE_XYZ
    var tmp = e.top.z;
    e.top.z = e.bot.z;
    e.bot.z = tmp;
  #end
  }
  //------------------------------------------------------------------------------

  /*internal*/ function reset():Void {
    mCurrentLM = mMinimaList;
    if (mCurrentLM == null) return; //ie nothing to process

    //reset all edges ...
    mScanbeam = null;
    var lm:LocalMinima = mMinimaList;
    while (lm != null) {
      insertScanbeam(lm.y);
      var e:TEdge = lm.leftBound;
      if (e != null) {
        e.curr.copyFrom(e.bot);
        e.outIdx = UNASSIGNED;
      }
      e = lm.rightBound;
      if (e != null) {
        e.curr.copyFrom(e.bot);
        e.outIdx = UNASSIGNED;
      }
      lm = lm.next;
    }
    mActiveEdges = null;
  }
  //------------------------------------------------------------------------------

  static public function getBounds(paths:Paths):IntRect {
    var i:Int = 0, cnt:Int = paths.length;
    while (i < cnt && paths[i].length == 0) i++;
    if (i == cnt) return new IntRect(0, 0, 0, 0);
    var result = new IntRect(0, 0, 0, 0);
    result.left = paths[i][0].x;
    result.right = result.left;
    result.top = paths[i][0].y;
    result.bottom = result.top;
    // NOTE: check nested loops
    while (i < cnt) {
      for (j in 0...paths[i].length) {
        if (paths[i][j].x < result.left) result.left = paths[i][j].x;
        else if (paths[i][j].x > result.right) result.right = paths[i][j].x;
        if (paths[i][j].y < result.top) result.top = paths[i][j].y;
        else if (paths[i][j].y > result.bottom) result.bottom = paths[i][j].y;
      }
      i++;
    }
    return result;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function insertScanbeam(y:CInt):Void {
    //single-linked list: sorted descending, ignoring dups.
    if (mScanbeam == null) {
      mScanbeam = new Scanbeam();
      mScanbeam.next = null;
      mScanbeam.y = y;
    } else if (y > mScanbeam.y) {
      var newSb = new Scanbeam();
      newSb.y = y;
      newSb.next = mScanbeam;
      mScanbeam = newSb;
    } else {
      var sb2 = mScanbeam;
      while (sb2.next != null && (y <= sb2.next.y)) sb2 = sb2.next;
      if (y == sb2.y) return; //ie ignores duplicates
      var newSb = new Scanbeam();
      newSb.y = y;
      newSb.next = sb2.next;
      sb2.next = newSb;
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: changed signature in r494 (from CInt->Void to Out<CInt>->Bool)
  /*internal*/ function popScanbeam(/*out y:CInt*/):{y:CInt, popped:Bool} {
    var res = { y:0, popped:false };
    if (mScanbeam == null)
    {
      return res;
    }
    res.y = mScanbeam.y;
    mScanbeam = mScanbeam.next;
    res.popped = true;
    return res;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ function localMinimaPending():Bool {
    return (mCurrentLM != null);
  }
  //------------------------------------------------------------------------------

  /*internal*/ function createOutRec():OutRec {
    var result = new OutRec();
    result.idx = ClipperBase.UNASSIGNED;
    result.isHole = false;
    result.isOpen = false;
    result.firstLeft = null;
    result.pts = null;
    result.bottomPt = null;
    result.polyNode = null;
    mPolyOuts.push(result);
    result.idx = mPolyOuts.length - 1;
    return result;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function disposeOutRec(index:Int):Void {
    var outRec:OutRec = mPolyOuts[index];
    outRec.pts = null;
    outRec = null;
    mPolyOuts[index] = null;
  }
  //------------------------------------------------------------------------------

  // NOTE: ref (updated to return the modified edge)
  /*internal*/ function updateEdgeIntoAEL(/*ref*/ e:TEdge):TEdge {
  #if (!CLIPPER_NO_EXCEPTIONS)
    if (e.nextInLML == null) throw new ClipperException("UpdateEdgeIntoAEL: invalid call");
  #end
    var aelPrev:TEdge = e.prevInAEL;
    var aelNext:TEdge = e.nextInAEL;
    e.nextInLML.outIdx = e.outIdx;
    if (aelPrev != null) aelPrev.nextInAEL = e.nextInLML;
    else mActiveEdges = e.nextInLML;
    if (aelNext != null) aelNext.prevInAEL = e.nextInLML;
    e.nextInLML.side = e.side;
    e.nextInLML.windDelta = e.windDelta;
    e.nextInLML.windCnt = e.windCnt;
    e.nextInLML.windCnt2 = e.windCnt2;
    e = e.nextInLML;
    e.curr.copyFrom(e.bot);
    e.prevInAEL = aelPrev;
    e.nextInAEL = aelNext;
    if (!ClipperBase.isHorizontal(e)) insertScanbeam(e.top.y);
    return e;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function swapPositionsInAEL(edge1:TEdge, edge2:TEdge):Void {
    //check that one or other edge hasn't already been removed from AEL ...
    if (edge1.nextInAEL == edge1.prevInAEL || edge2.nextInAEL == edge2.prevInAEL) return;

    if (edge1.nextInAEL == edge2) {
      var next:TEdge = edge2.nextInAEL;
      if (next != null) next.prevInAEL = edge1;
      var prev:TEdge = edge1.prevInAEL;
      if (prev != null) prev.nextInAEL = edge2;
      edge2.prevInAEL = prev;
      edge2.nextInAEL = edge1;
      edge1.prevInAEL = edge2;
      edge1.nextInAEL = next;
    } else if (edge2.nextInAEL == edge1) {
      var next:TEdge = edge1.nextInAEL;
      if (next != null) next.prevInAEL = edge2;
      var prev:TEdge = edge2.prevInAEL;
      if (prev != null) prev.nextInAEL = edge1;
      edge1.prevInAEL = prev;
      edge1.nextInAEL = edge2;
      edge2.prevInAEL = edge1;
      edge2.nextInAEL = next;
    } else {
      var next:TEdge = edge1.nextInAEL;
      var prev:TEdge = edge1.prevInAEL;
      edge1.nextInAEL = edge2.nextInAEL;
      if (edge1.nextInAEL != null) edge1.nextInAEL.prevInAEL = edge1;
      edge1.prevInAEL = edge2.prevInAEL;
      if (edge1.prevInAEL != null) edge1.prevInAEL.nextInAEL = edge1;
      edge2.nextInAEL = next;
      if (edge2.nextInAEL != null) edge2.nextInAEL.prevInAEL = edge2;
      edge2.prevInAEL = prev;
      if (edge2.prevInAEL != null) edge2.prevInAEL.nextInAEL = edge2;
    }

    if (edge1.prevInAEL == null) mActiveEdges = edge1;
    else if (edge2.prevInAEL == null) mActiveEdges = edge2;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function deleteFromAEL(e:TEdge):Void {
    var aelPrev:TEdge = e.prevInAEL;
    var aelNext:TEdge = e.nextInAEL;
    if (aelPrev == null && aelNext == null && (e != mActiveEdges)) return; //already deleted
    if (aelPrev != null) aelPrev.nextInAEL = aelNext;
    else mActiveEdges = aelNext;
    if (aelNext != null) aelNext.prevInAEL = aelPrev;
    e.nextInAEL = null;
    e.prevInAEL = null;
  }
  //------------------------------------------------------------------------------

} //end ClipperBase

typedef IntersectNodeComparer = IntersectNode->IntersectNode->Int;

@:expose()
@:native("ClipOptions")
@:enum
abstract ClipOptions(Int) from Int to Int
{
  var CO_REVERSE_SOLUTION = 1;
  var CO_STRICTLY_SIMPLE = 2;
  var CO_PRESERVE_COLLINEAR = 4;
}

typedef ZFillCallback = /*bot1:*/IntPoint->/*, top1:*/IntPoint->/*, bot2:*/IntPoint->/*, top2:*/IntPoint->/*, ref pt:*/IntPoint->Void/*)*/;

@:expose()
@:native("Clipper")
@:allow(hxClipper.ClipperOffset)
class Clipper extends ClipperBase
{
  //InitOptions that can be passed to the constructor ...
  //NOTE: check constants and constructor behaviour (maybe turn into enum) - done: see ClipOptions
  /*inline static public var ioReverseSolution:Int = 1;
  inline static public var ioStrictlySimple:Int = 2;
  inline static public var ioPreserveCollinear:Int = 4;*/

  var mClipType:ClipType;
  var mMaxima:Maxima;
  var mSortedEdges:TEdge;
  var mIntersectList:Array<IntersectNode>;
  var mIntersectNodeComparer:IntersectNodeComparer;
  var mExecuteLocked:Bool;
  var mClipFillType:PolyFillType;
  var mSubjFillType:PolyFillType;
  var mJoins:Array<Join>;
  var mGhostJoins:Array<Join>;
  var mUsingPolyTree:Bool;
#if USE_XYZ
  // NOTE: ref and delegate here
  //public delegate void ZFillCallback(bot1:IntPoint, top1:IntPoint, bot2:IntPoint, top2:IntPoint, /*ref*/ pt:IntPoint);
  public var zFillFunction:ZFillCallback = null;
#end
  // NOTE: check constructor (:base()/super())
  public function new(initOptions:ClipOptions = 0) { //constructor
    super();
    mScanbeam = null;
    mMaxima = null;
    mActiveEdges = null;
    mSortedEdges = null;
    mIntersectList = new Array<IntersectNode>();
    mIntersectNodeComparer = compare;
    mExecuteLocked = false;
    mUsingPolyTree = false;
    mPolyOuts = new Array<OutRec>();
    mJoins = new Array<Join>();
    mGhostJoins = new Array<Join>();
    reverseSolution = (ClipOptions.CO_REVERSE_SOLUTION & initOptions) != 0;
    strictlySimple = (ClipOptions.CO_STRICTLY_SIMPLE & initOptions) != 0;
    preserveCollinear = (ClipOptions.CO_PRESERVE_COLLINEAR & initOptions) != 0;
  #if USE_XYZ
    zFillFunction = null;
  #end
  }
  //------------------------------------------------------------------------------

  static function compare(node1:IntersectNode, node2:IntersectNode):Int {
    var i:CInt = node2.pt.y - node1.pt.y;
    if (i > 0) return 1;
    else if (i < 0) return -1;
    else return 0;
  }

  //------------------------------------------------------------------------------

  function insertMaxima(x:CInt):Void {
    //double-linked list: sorted ascending, ignoring dups.
    var newMax = new Maxima();
    newMax.x = x;
    if (mMaxima == null) {
      mMaxima = newMax;
      mMaxima.next = null;
      mMaxima.prev = null;
    } else if (x < mMaxima.x) {
      newMax.next = mMaxima;
      newMax.prev = null;
      mMaxima = newMax;
    } else {
      var m = mMaxima;
      while (m.next != null && (x >= m.next.x)) m = m.next;
      if (x == m.x) return; //ie ignores duplicates (& CG to clean up newMax)
      //insert newMax between m and m.Next ...
      newMax.next = m.next;
      newMax.prev = m;
      if (m.next != null) m.next.prev = newMax;
      m.next = newMax;
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: check this prop
  public var reverseSolution(default, default):Bool;
  //------------------------------------------------------------------------------

  public var strictlySimple(default, default):Bool;
  //------------------------------------------------------------------------------

  public function executePaths(clipType:ClipType, solution:Paths, subjFillType:PolyFillType, clipFillType:PolyFillType):Bool {
    if (mExecuteLocked) return false;
  #if (!CLIPPER_NO_EXCEPTIONS)
    if (mHasOpenPaths) throw new ClipperException("Error: PolyTree struct is needed for open path clipping.");
  #end

    mExecuteLocked = true;
    solution.clear();
    mSubjFillType = subjFillType;
    mClipFillType = clipFillType;
    mClipType = clipType;
    mUsingPolyTree = false;
    var succeeded:Bool = false;
    // NOTE: finally?
    try {
      succeeded = executeInternal();
      //build the return polygons ...
      if (succeeded) buildResult(solution);
    } /*finally {
      DisposeAllPolyPts();
      mExecuteLocked = false;
    }*/
    disposeAllPolyPts();
    mExecuteLocked = false;
    mJoins.clear();
    mGhostJoins.clear();
    return succeeded;
  }
  //------------------------------------------------------------------------------

  public function executePolyTree(clipType:ClipType, polytree:PolyTree, subjFillType:PolyFillType, clipFillType:PolyFillType):Bool {
    if (mExecuteLocked) return false;
    mExecuteLocked = true;
    mSubjFillType = subjFillType;
    mClipFillType = clipFillType;
    mClipType = clipType;
    mUsingPolyTree = true;
    var succeeded:Bool = false;
    // NOTE: finally?
    try {
      succeeded = executeInternal();
      //build the return polygons ...
      if (succeeded) buildResult2(polytree);
    } /*finally {
      DisposeAllPolyPts();
      mExecuteLocked = false;
    }*/
    disposeAllPolyPts();
    mExecuteLocked = false;
    mJoins.clear();
    mGhostJoins.clear();
    return succeeded;
  }
  //------------------------------------------------------------------------------

  public function execute(clipType:ClipType, solution:Dynamic):Bool {
    if (Std.is(solution, Paths)) {
      return executePaths(clipType, solution, PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_EVEN_ODD);
    } else if (Std.is(solution, PolyTree)) {
      return executePolyTree(clipType, solution, PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_EVEN_ODD);
    }
  #if (!CLIPPER_NO_EXCEPTIONS)
    else throw new ClipperException("`solution` must be either a Paths or a PolyTree");
  #else
    return false;
  #end
  }
  //------------------------------------------------------------------------------

  /*internal*/ function fixHoleLinkage(outRec:OutRec):Void {
    //skip if an outermost polygon or
    //already already points to the correct FirstLeft ...
    if (outRec.firstLeft == null || (outRec.isHole != outRec.firstLeft.isHole && outRec.firstLeft.pts != null)) return;

    var orfl:OutRec = outRec.firstLeft;
    // NOTE: check while
    while (orfl != null && ((orfl.isHole == outRec.isHole) || orfl.pts == null)) {
      orfl = orfl.firstLeft;
    }
    outRec.firstLeft = orfl;
  }
  //------------------------------------------------------------------------------

  //NOTE: double check logic of changes from r493 to r494
  function executeInternal():Bool {
    try {
      reset();
      mSortedEdges = null;
      mMaxima = null;

      var botY:CInt, topY:CInt;
      var popRes = popScanbeam();
      botY = popRes.y;
      if (!popRes.popped) return false;

      insertLocalMinimaIntoAEL(botY);
      while (true) {
        popRes = popScanbeam();
        topY = popRes.y;
        if (popRes.popped || localMinimaPending()) {
          processHorizontals();
          mGhostJoins.clear();

          if (!processIntersections(topY)) return false;
          processEdgesAtTopOfScanbeam(topY);
          botY = topY;
          insertLocalMinimaIntoAEL(botY);
        } else {
          break;
        }
      }

      //fix orientations ...
      for (i in 0...mPolyOuts.length) {
        var outRec:OutRec = mPolyOuts[i];
        if (outRec.pts == null || outRec.isOpen) continue;
        if ((outRec.isHole.xor(reverseSolution)) == (areaOfOutRec(outRec) > 0)) reversePolyPtLinks(outRec.pts);
      }

      joinCommonEdges();

      for (i in 0...mPolyOuts.length) {
        var outRec:OutRec = mPolyOuts[i];
        if (outRec.pts == null) {
          continue;
        } else if (outRec.isOpen) {
          fixupOutPolyLine(outRec);
        } else {
          fixupOutPolygon(outRec);
        }
      }

      if (strictlySimple) doSimplePolygons();
      return true;
    }
    //catch { return false; }
    // NOTE: finally? moved into callers
    /*finally {
      mJoins.clear();
      mGhostJoins.clear();
    }*/
  }
  //------------------------------------------------------------------------------

  function disposeAllPolyPts():Void {
    for (i in 0...mPolyOuts.length) disposeOutRec(i);
    mPolyOuts.clear();
  }
  //------------------------------------------------------------------------------

  function addJoin(op1:OutPt, op2:OutPt, offPt:IntPoint):Void {
    var j = new Join();
    j.outPt1 = op1;
    j.outPt2 = op2;
    j.offPt.copyFrom(offPt);
    mJoins.push(j);
  }
  //------------------------------------------------------------------------------

  function addGhostJoin(op:OutPt, offPt:IntPoint):Void {
    var j = new Join();
    j.outPt1 = op;
    j.offPt.copyFrom(offPt);
    mGhostJoins.push(j);
  }
  //------------------------------------------------------------------------------

#if USE_XYZ
  // NOTE: ref?
  /*internal*/ function setZ(/*ref*/ pt:IntPoint, e1:TEdge, e2:TEdge):Void {
    if (pt.z != 0 || zFillFunction == null) return;
    else if (pt.equals(e1.bot)) pt.z = e1.bot.z;
    else if (pt.equals(e1.top)) pt.z = e1.top.z;
    else if (pt.equals(e2.bot)) pt.z = e2.bot.z;
    else if (pt.equals(e2.top)) pt.z = e2.top.z;
    else zFillFunction(e1.bot, e1.top, e2.bot, e2.top, /*ref*/ pt);
  }
  //------------------------------------------------------------------------------
#end

  // NOTE: watch out changes from r493 to r494
  function insertLocalMinimaIntoAEL(botY:CInt):Void {
    var current = {lm:null};
    while (popLocalMinima(botY, /*out*/ current)) {
      var lm:LocalMinima = current.lm;
      var lb:TEdge = lm.leftBound;
      var rb:TEdge = lm.rightBound;

      var op1:OutPt = null;
      if (lb == null) {
        insertEdgeIntoAEL(rb, null);
        setWindingCount(rb);
        if (isContributing(rb))
          op1 = addOutPt(rb, rb.bot);
      } else if (rb == null) {
        insertEdgeIntoAEL(lb, null);
        setWindingCount(lb);
        if (isContributing(lb))
          op1 = addOutPt(lb, lb.bot);
        insertScanbeam(lb.top.y);
      } else {
        insertEdgeIntoAEL(lb, null);
        insertEdgeIntoAEL(rb, lb);
        setWindingCount(lb);
        rb.windCnt = lb.windCnt;
        rb.windCnt2 = lb.windCnt2;
        if (isContributing(lb))
          op1 = addLocalMinPoly(lb, rb, lb.bot);
        insertScanbeam(lb.top.y);
      }

      if (rb != null) {
        if (ClipperBase.isHorizontal(rb)) {
          if (rb.nextInLML != null) {
            insertScanbeam(rb.nextInLML.top.y);
          }
          addEdgeToSEL(rb);
        }
        else insertScanbeam(rb.top.y);
      }

      if (lb == null || rb == null) continue;

      //if output polygons share an Edge with a horizontal rb, they'll need joining later ...
      if (op1 != null && ClipperBase.isHorizontal(rb) && mGhostJoins.length > 0 && rb.windDelta != 0) {
        for (i in 0...mGhostJoins.length) {
          //if the horizontal Rb and a 'ghost' horizontal overlap, then convert
          //the 'ghost' join to a real join ready for later ...
          var j:Join = mGhostJoins[i];
          if (horzSegmentsOverlap(j.outPt1.pt.x, j.offPt.x, rb.bot.x, rb.top.x)) addJoin(j.outPt1, op1, j.offPt);
        }
      }

      if (lb.outIdx >= 0 && lb.prevInAEL != null && lb.prevInAEL.curr.x == lb.bot.x && lb.prevInAEL.outIdx >= 0
        && ClipperBase.slopesEqual4(lb.prevInAEL.curr, lb.prevInAEL.top, lb.curr, lb.top, mUseFullRange)
        && lb.windDelta != 0 && lb.prevInAEL.windDelta != 0)
      {
        var op2:OutPt = addOutPt(lb.prevInAEL, lb.bot);
        addJoin(op1, op2, lb.top);
      }

      if (lb.nextInAEL != rb) {

        if (rb.outIdx >= 0 && rb.prevInAEL.outIdx >= 0
          && ClipperBase.slopesEqual4(rb.prevInAEL.curr, rb.prevInAEL.top, rb.curr, rb.top, mUseFullRange)
          && rb.windDelta != 0 && rb.prevInAEL.windDelta != 0)
        {
          var op2:OutPt = addOutPt(rb.prevInAEL, rb.bot);
          addJoin(op1, op2, rb.top);
        }

        var e:TEdge = lb.nextInAEL;
        if (e != null) while (e != rb) {
          //nb: For calculating winding counts etc, IntersectEdges() assumes
          //that param1 will be to the right of param2 ABOVE the intersection ...
          intersectEdges(rb, e, lb.curr); //order important here
          e = e.nextInAEL;
        }
      }
    }
  }
  //------------------------------------------------------------------------------

  function insertEdgeIntoAEL(edge:TEdge, startEdge:TEdge):Void {
    if (mActiveEdges == null) {
      edge.prevInAEL = null;
      edge.nextInAEL = null;
      mActiveEdges = edge;
    } else if (startEdge == null && e2InsertsBeforeE1(mActiveEdges, edge)) {
      edge.prevInAEL = null;
      edge.nextInAEL = mActiveEdges;
      mActiveEdges.prevInAEL = edge;
      mActiveEdges = edge;
    } else {
      if (startEdge == null) startEdge = mActiveEdges;
      while (startEdge.nextInAEL != null && !e2InsertsBeforeE1(startEdge.nextInAEL, edge)) {
        startEdge = startEdge.nextInAEL;
      }
      edge.nextInAEL = startEdge.nextInAEL;
      if (startEdge.nextInAEL != null) startEdge.nextInAEL.prevInAEL = edge;
      edge.prevInAEL = startEdge;
      startEdge.nextInAEL = edge;
    }
  }
  //----------------------------------------------------------------------

  function e2InsertsBeforeE1(e1:TEdge, e2:TEdge):Bool {
    if (e2.curr.x == e1.curr.x) {
      if (e2.top.y > e1.top.y) return e2.top.x < topX(e1, e2.top.y);
      else return e1.top.x > topX(e2, e1.top.y);
    } else return e2.curr.x < e1.curr.x;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function isEvenOddFillType(edge:TEdge):Bool {
    if (edge.polyType == PolyType.PT_SUBJECT) return mSubjFillType == PolyFillType.PFT_EVEN_ODD;
    else return mClipFillType == PolyFillType.PFT_EVEN_ODD;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function isEvenOddAltFillType(edge:TEdge):Bool {
    if (edge.polyType == PolyType.PT_SUBJECT) return mClipFillType == PolyFillType.PFT_EVEN_ODD;
    else return mSubjFillType == PolyFillType.PFT_EVEN_ODD;
  }
  //------------------------------------------------------------------------------

  function isContributing(edge:TEdge):Bool {
    var pft:PolyFillType, pft2:PolyFillType;
    if (edge.polyType == PolyType.PT_SUBJECT) {
      pft = mSubjFillType;
      pft2 = mClipFillType;
    } else {
      pft = mClipFillType;
      pft2 = mSubjFillType;
    }

    switch (pft) {
      case PolyFillType.PFT_EVEN_ODD:
        //return false if a subj line has been flagged as inside a subj polygon
        if (edge.windDelta == 0 && edge.windCnt != 1) return false;
      case PolyFillType.PFT_NON_ZERO:
        if (Math.abs(edge.windCnt) != 1) return false;
      case PolyFillType.PFT_POSITIVE:
        if (edge.windCnt != 1) return false;
      default:
        //PolyFillType.pftNegative
        if (edge.windCnt != -1) return false;
    }

    switch (mClipType) {
      case ClipType.CT_INTERSECTION:
        switch (pft2) {
          case PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_NON_ZERO:
            return (edge.windCnt2 != 0);
          case PolyFillType.PFT_POSITIVE:
            return (edge.windCnt2 > 0);
          default:
            return (edge.windCnt2 < 0);
        }
      case ClipType.CT_UNION:
        switch (pft2) {
          case PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_NON_ZERO:
            return (edge.windCnt2 == 0);
          case PolyFillType.PFT_POSITIVE:
            return (edge.windCnt2 <= 0);
          default:
            return (edge.windCnt2 >= 0);
        }
      case ClipType.CT_DIFFERENCE:
        if (edge.polyType == PolyType.PT_SUBJECT) switch (pft2) {
          case PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_NON_ZERO:
            return (edge.windCnt2 == 0);
          case PolyFillType.PFT_POSITIVE:
            return (edge.windCnt2 <= 0);
          default:
            return (edge.windCnt2 >= 0);
        } else switch (pft2) {
          case PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_NON_ZERO:
            return (edge.windCnt2 != 0);
          case PolyFillType.PFT_POSITIVE:
            return (edge.windCnt2 > 0);
          default:
            return (edge.windCnt2 < 0);
        }
      case ClipType.CT_XOR:
        if (edge.windDelta == 0) //XOr always contributing unless open
          switch (pft2) {
            case PolyFillType.PFT_EVEN_ODD, PolyFillType.PFT_NON_ZERO:
              return (edge.windCnt2 == 0);
            case PolyFillType.PFT_POSITIVE:
              return (edge.windCnt2 <= 0);
            default:
              return (edge.windCnt2 >= 0);
        } else return true;
    }
    return true;
  }
  //------------------------------------------------------------------------------

  function setWindingCount(edge:TEdge):Void {
    var e:TEdge = edge.prevInAEL;
    //find the edge of the same polytype that immediately preceeds 'edge' in AEL
    while (e != null && ((e.polyType != edge.polyType) || (e.windDelta == 0))) e = e.prevInAEL;
    if (e == null) {
      var pft:PolyFillType = (edge.polyType == PolyType.PT_SUBJECT ? mSubjFillType : mClipFillType);
      if (edge.windDelta == 0) edge.windCnt = (pft == PolyFillType.PFT_NEGATIVE ? -1 : 1);
      else edge.windCnt = edge.windDelta;
      edge.windCnt2 = 0;
      e = mActiveEdges; //ie get ready to calc WindCnt2
    } else if (edge.windDelta == 0 && mClipType != ClipType.CT_UNION) {
      edge.windCnt = 1;
      edge.windCnt2 = e.windCnt2;
      e = e.nextInAEL; //ie get ready to calc WindCnt2
    } else if (isEvenOddFillType(edge)) {
      //EvenOdd filling ...
      if (edge.windDelta == 0) {
        //are we inside a subj polygon ...
        var inside = true;
        var e2:TEdge = e.prevInAEL;
        while (e2 != null) {
          if (e2.polyType == e.polyType && e2.windDelta != 0) inside = !inside;
          e2 = e2.prevInAEL;
        }
        edge.windCnt = (inside ? 0 : 1);
      } else {
        edge.windCnt = edge.windDelta;
      }
      edge.windCnt2 = e.windCnt2;
      e = e.nextInAEL; //ie get ready to calc WindCnt2
    } else {
      //nonZero, Positive or Negative filling ...
      if (e.windCnt * e.windDelta < 0) {
        //prev edge is 'decreasing' WindCount (WC) toward zero
        //so we're outside the previous polygon ...
        if (Math.abs(e.windCnt) > 1) {
          //outside prev poly but still inside another.
          //when reversing direction of prev poly use the same WC
          if (e.windDelta * edge.windDelta < 0) edge.windCnt = e.windCnt;
          //otherwise continue to 'decrease' WC ...
          else edge.windCnt = e.windCnt + edge.windDelta;
        } else
        //now outside all polys of same polytype so set own WC ...
        edge.windCnt = (edge.windDelta == 0 ? 1 : edge.windDelta);
      } else {
        //prev edge is 'increasing' WindCount (WC) away from zero
        //so we're inside the previous polygon ...
        if (edge.windDelta == 0) edge.windCnt = (e.windCnt < 0 ? e.windCnt - 1 : e.windCnt + 1);
        //if wind direction is reversing prev then use same WC
        else if (e.windDelta * edge.windDelta < 0) edge.windCnt = e.windCnt;
        //otherwise add to WC ...
        else edge.windCnt = e.windCnt + edge.windDelta;
      }
      edge.windCnt2 = e.windCnt2;
      e = e.nextInAEL; //ie get ready to calc WindCnt2
    }

    //update WindCnt2 ...
    if (isEvenOddAltFillType(edge)) {
      //EvenOdd filling ...
      while (e != edge) {
        if (e.windDelta != 0) edge.windCnt2 = (edge.windCnt2 == 0 ? 1 : 0);
        e = e.nextInAEL;
      }
    } else {
      //nonZero, Positive or Negative filling ...
      while (e != edge) {
        edge.windCnt2 += e.windDelta;
        e = e.nextInAEL;
      }
    }
  }
  //------------------------------------------------------------------------------

  function addEdgeToSEL(edge:TEdge):Void {
    //SEL pointers in PEdge are used to build transient lists of horizontal edges.
    //However, since we don't need to worry about processing order, all additions
    //are made to the front of the list ...
    if (mSortedEdges == null) {
      mSortedEdges = edge;
      edge.prevInSEL = null;
      edge.nextInSEL = null;
    } else {
      edge.nextInSEL = mSortedEdges;
      edge.prevInSEL = null;
      mSortedEdges.prevInSEL = edge;
      mSortedEdges = edge;
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: check `out` param refactor into multireturn (r493 to r494)
  /*internal*/ function popEdgeFromSEL(/*out*/ /*e:TEdge*/):{popped:Bool, edge:TEdge} {
    //Pop edge from front of SEL (ie SEL is a FILO list)
    var res = { popped:false, edge:null };
    res.edge = mSortedEdges;
    if (res.edge == null) return res;
    var oldE:TEdge = res.edge;
    mSortedEdges = res.edge.nextInSEL;
    if (mSortedEdges != null) mSortedEdges.prevInSEL = null;
    oldE.nextInSEL = null;
    oldE.prevInSEL = null;
    res.popped = true;
    return res;
  }
  //------------------------------------------------------------------------------

  function copyAELToSEL():Void {
    var e:TEdge = mActiveEdges;
    mSortedEdges = e;
    while (e != null) {
      e.prevInSEL = e.prevInAEL;
      e.nextInSEL = e.nextInAEL;
      e = e.nextInAEL;
    }
  }
  //------------------------------------------------------------------------------

  function swapPositionsInSEL(edge1:TEdge, edge2:TEdge):Void {
    if (edge1.nextInSEL == null && edge1.prevInSEL == null) return;
    if (edge2.nextInSEL == null && edge2.prevInSEL == null) return;

    if (edge1.nextInSEL == edge2) {
      var next:TEdge = edge2.nextInSEL;
      if (next != null) next.prevInSEL = edge1;
      var prev:TEdge = edge1.prevInSEL;
      if (prev != null) prev.nextInSEL = edge2;
      edge2.prevInSEL = prev;
      edge2.nextInSEL = edge1;
      edge1.prevInSEL = edge2;
      edge1.nextInSEL = next;
    } else if (edge2.nextInSEL == edge1) {
      var next:TEdge = edge1.nextInSEL;
      if (next != null) next.prevInSEL = edge2;
      var prev:TEdge = edge2.prevInSEL;
      if (prev != null) prev.nextInSEL = edge1;
      edge1.prevInSEL = prev;
      edge1.nextInSEL = edge2;
      edge2.prevInSEL = edge1;
      edge2.nextInSEL = next;
    } else {
      var next:TEdge = edge1.nextInSEL;
      var prev:TEdge = edge1.prevInSEL;
      edge1.nextInSEL = edge2.nextInSEL;
      if (edge1.nextInSEL != null) edge1.nextInSEL.prevInSEL = edge1;
      edge1.prevInSEL = edge2.prevInSEL;
      if (edge1.prevInSEL != null) edge1.prevInSEL.nextInSEL = edge1;
      edge2.nextInSEL = next;
      if (edge2.nextInSEL != null) edge2.nextInSEL.prevInSEL = edge2;
      edge2.prevInSEL = prev;
      if (edge2.prevInSEL != null) edge2.prevInSEL.nextInSEL = edge2;
    }

    if (edge1.prevInSEL == null) mSortedEdges = edge1;
    else if (edge2.prevInSEL == null) mSortedEdges = edge2;
  }
  //------------------------------------------------------------------------------


  function addLocalMaxPoly(e1:TEdge, e2:TEdge, pt:IntPoint):Void {
    addOutPt(e1, pt);
    if (e2.windDelta == 0) addOutPt(e2, pt);
    if (e1.outIdx == e2.outIdx) {
      e1.outIdx = ClipperBase.UNASSIGNED;
      e2.outIdx = ClipperBase.UNASSIGNED;
    } else if (e1.outIdx < e2.outIdx) appendPolygon(e1, e2);
    else appendPolygon(e2, e1);
  }
  //------------------------------------------------------------------------------

  // NOTE: check `result` (as Angus' code doesn't init it)
  function addLocalMinPoly(e1:TEdge, e2:TEdge, pt:IntPoint):OutPt {
    var result:OutPt = null;
    var e:TEdge, prevE:TEdge;
    if (ClipperBase.isHorizontal(e2) || (e1.dx > e2.dx)) {
      result = addOutPt(e1, pt);
      e2.outIdx = e1.outIdx;
      e1.side = EdgeSide.ES_LEFT;
      e2.side = EdgeSide.ES_RIGHT;
      e = e1;
      if (e.prevInAEL == e2) prevE = e2.prevInAEL;
      else prevE = e.prevInAEL;
    } else {
      result = addOutPt(e2, pt);
      e1.outIdx = e2.outIdx;
      e1.side = EdgeSide.ES_RIGHT;
      e2.side = EdgeSide.ES_LEFT;
      e = e2;
      if (e.prevInAEL == e1) prevE = e1.prevInAEL;
      else prevE = e.prevInAEL;
    }

    if (prevE != null && prevE.outIdx >= 0 && prevE.top.y < pt.y && e.top.y < pt.y) {
      var xPrev:CInt = topX(prevE, pt.y);
      var xE:CInt = topX(e, pt.y);
      if ((xPrev == xE) && (e.windDelta != 0) && (prevE.windDelta != 0)
        && ClipperBase.slopesEqual4(new IntPoint(xPrev, pt.y), prevE.top, new IntPoint(xE, pt.y), e.top, mUseFullRange))
      {
        var outPt:OutPt = addOutPt(prevE, pt);
        addJoin(result, outPt, e.top);
      }
    }
    return result;
  }
  //------------------------------------------------------------------------------

  function addOutPt(e:TEdge, pt:IntPoint):OutPt {
    if (e.outIdx < 0) {
      var outRec:OutRec = createOutRec();
      outRec.isOpen = (e.windDelta == 0);
      var newOp = new OutPt();
      outRec.pts = newOp;
      newOp.idx = outRec.idx;
      newOp.pt.copyFrom(pt);
      newOp.next = newOp;
      newOp.prev = newOp;
      if (!outRec.isOpen) setHoleState(e, outRec);
      e.outIdx = outRec.idx; //nb: do this after SetZ !
      return newOp;
    } else {
      var outRec:OutRec = mPolyOuts[e.outIdx];
      //OutRec.pts is the 'Left-most' point & OutRec.pts.prev is the 'Right-most'
      var op:OutPt = outRec.pts;
      var toFront = (e.side == EdgeSide.ES_LEFT);
      if (toFront && pt.equals(op.pt)) return op;
      else if (!toFront && pt.equals(op.prev.pt)) return op.prev;

      var newOp = new OutPt();
      newOp.idx = outRec.idx;
      newOp.pt.copyFrom(pt);
      newOp.next = op;
      newOp.prev = op.prev;
      newOp.prev.next = newOp;
      op.prev = newOp;
      if (toFront) outRec.pts = newOp;
      return newOp;
    }
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function getLastOutPt(e:TEdge):OutPt {
    var outRec = mPolyOuts[e.outIdx];
    if (e.side == EdgeSide.ES_LEFT)
      return outRec.pts;
    else
      return outRec.pts.prev;
  }
  //------------------------------------------------------------------------------

  //NOTE: ref?
  /*internal*/ function swapPoints(/*ref*/ pt1:IntPoint, /*ref*/ pt2:IntPoint):Void {
    var tmp = pt1.clone();
    pt1.copyFrom(pt2);
    pt2.copyFrom(tmp);
  }
  //------------------------------------------------------------------------------

  // NOTE: ref/swap
  function horzSegmentsOverlap(seg1a:CInt, seg1b:CInt, seg2a:CInt, seg2b:CInt):Bool {
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

  function setHoleState(e:TEdge, outRec:OutRec):Void {
    var e2:TEdge = e.prevInAEL;
    var eTmp:TEdge = null;
    while (e2 != null) {
      if (e2.outIdx >= 0 && e2.windDelta != 0) {
        if (eTmp == null) {
          eTmp = e2;
        } else if (eTmp.outIdx == e2.outIdx) {
          eTmp = null; // paired
        }
      }
      e2 = e2.prevInAEL;
    }

    if (eTmp == null) {
          outRec.firstLeft = null;
          outRec.isHole = false;
        } else {
          outRec.firstLeft = mPolyOuts[eTmp.outIdx];
          outRec.isHole = !outRec.firstLeft.isHole;
        }
  }
  //------------------------------------------------------------------------------

  function getDx(pt1:IntPoint, pt2:IntPoint):Float {
    if (pt1.y == pt2.y) return ClipperBase.HORIZONTAL;
    else {
      var dx:Float = (pt2.x - pt1.x);
      var dy:Float = (pt2.y - pt1.y);
      return dx / dy;
    }
  }
  //---------------------------------------------------------------------------

  function firstIsBottomPt(btmPt1:OutPt, btmPt2:OutPt):Bool {
    var p:OutPt = btmPt1.prev;
    while ((p.pt.equals(btmPt1.pt)) && (p != btmPt1)) p = p.prev;
    var dx1p:Float = Math.abs(getDx(btmPt1.pt, p.pt));
    p = btmPt1.next;
    while ((p.pt.equals(btmPt1.pt)) && (p != btmPt1)) p = p.next;
    var dx1n:Float = Math.abs(getDx(btmPt1.pt, p.pt));

    p = btmPt2.prev;
    while ((p.pt.equals(btmPt2.pt)) && (p != btmPt2)) p = p.prev;
    var dx2p:Float = Math.abs(getDx(btmPt2.pt, p.pt));
    p = btmPt2.next;
    while ((p.pt.equals(btmPt2.pt)) && (p != btmPt2)) p = p.next;
    var dx2n:Float = Math.abs(getDx(btmPt2.pt, p.pt));

    if (Math.max(dx1p, dx1n) == Math.max(dx2p, dx2n)
      && Math.min(dx1p, dx1n) == Math.min(dx2p, dx2n))
    {
      return areaOfOutPt(btmPt1) > 0; //if otherwise identical use orientation
    } else {
      return (dx1p >= dx2p && dx1p >= dx2n) || (dx1n >= dx2p && dx1n >= dx2n);
    }
  }
  //------------------------------------------------------------------------------

  function getBottomPt(pp:OutPt):OutPt {
    var dups:OutPt = null;
    var p:OutPt = pp.next;
    while (p != pp) {
      if (p.pt.y > pp.pt.y) {
        pp = p;
        dups = null;
      } else if (p.pt.y == pp.pt.y && p.pt.x <= pp.pt.x) {
        if (p.pt.x < pp.pt.x) {
          dups = null;
          pp = p;
        } else {
          if (p.next != pp && p.prev != pp) dups = p;
        }
      }
      p = p.next;
    }
    if (dups != null) {
      //there appears to be at least 2 vertices at bottomPt so ...
      while (dups != p) {
        if (!firstIsBottomPt(p, dups)) pp = dups;
        dups = dups.next;
        while (!dups.pt.equals(pp.pt)) dups = dups.next;
      }
    }
    return pp;
  }
  //------------------------------------------------------------------------------

  function getLowermostRec(outRec1:OutRec, outRec2:OutRec):OutRec {
    //work out which polygon fragment has the correct hole state ...
    if (outRec1.bottomPt == null) outRec1.bottomPt = getBottomPt(outRec1.pts);
    if (outRec2.bottomPt == null) outRec2.bottomPt = getBottomPt(outRec2.pts);
    var bPt1:OutPt = outRec1.bottomPt;
    var bPt2:OutPt = outRec2.bottomPt;
    if (bPt1.pt.y > bPt2.pt.y) return outRec1;
    else if (bPt1.pt.y < bPt2.pt.y) return outRec2;
    else if (bPt1.pt.x < bPt2.pt.x) return outRec1;
    else if (bPt1.pt.x > bPt2.pt.x) return outRec2;
    else if (bPt1.next == bPt1) return outRec2;
    else if (bPt2.next == bPt2) return outRec1;
    else if (firstIsBottomPt(bPt1, bPt2)) return outRec1;
    else return outRec2;
  }
  //------------------------------------------------------------------------------

  function outRec1RightOfOutRec2(outRec1:OutRec, outRec2:OutRec):Bool {
    do {
      outRec1 = outRec1.firstLeft;
      if (outRec1 == outRec2) return true;
    } while (outRec1 != null);
    return false;
  }
  //------------------------------------------------------------------------------

  function getOutRec(idx:Int):OutRec {
    var outrec:OutRec = mPolyOuts[idx];
    while (outrec != mPolyOuts[outrec.idx])
      outrec = mPolyOuts[outrec.idx];
    return outrec;
  }
  //------------------------------------------------------------------------------

  function appendPolygon(e1:TEdge, e2:TEdge):Void {
    var outRec1:OutRec = mPolyOuts[e1.outIdx];
    var outRec2:OutRec = mPolyOuts[e2.outIdx];

    var holeStateRec:OutRec;
    if (outRec1RightOfOutRec2(outRec1, outRec2)) holeStateRec = outRec2;
    else if (outRec1RightOfOutRec2(outRec2, outRec1)) holeStateRec = outRec1;
    else holeStateRec = getLowermostRec(outRec1, outRec2);

    //get the start and ends of both output polygons and
    //join E2 poly onto E1 poly and delete pointers to E2 ...
    var p1_lft:OutPt = outRec1.pts;
    var p1_rt:OutPt = p1_lft.prev;
    var p2_lft:OutPt = outRec2.pts;
    var p2_rt:OutPt = p2_lft.prev;

    //join e2 poly onto e1 poly and delete pointers to e2 ...
    if (e1.side == EdgeSide.ES_LEFT) {
      if (e2.side == EdgeSide.ES_LEFT) {
        //z y x a b c
        reversePolyPtLinks(p2_lft);
        p2_lft.next = p1_lft;
        p1_lft.prev = p2_lft;
        p1_rt.next = p2_rt;
        p2_rt.prev = p1_rt;
        outRec1.pts = p2_rt;
      } else {
        //x y z a b c
        p2_rt.next = p1_lft;
        p1_lft.prev = p2_rt;
        p2_lft.prev = p1_rt;
        p1_rt.next = p2_lft;
        outRec1.pts = p2_lft;
      }
    } else {
      if (e2.side == EdgeSide.ES_RIGHT) {
        //a b c z y x
        reversePolyPtLinks(p2_lft);
        p1_rt.next = p2_rt;
        p2_rt.prev = p1_rt;
        p2_lft.next = p1_lft;
        p1_lft.prev = p2_lft;
      } else {
        //a b c x y z
        p1_rt.next = p2_lft;
        p2_lft.prev = p1_rt;
        p1_lft.prev = p2_rt;
        p2_rt.next = p1_lft;
      }
    }

    outRec1.bottomPt = null;
    if (holeStateRec == outRec2) {
      if (outRec2.firstLeft != outRec1) outRec1.firstLeft = outRec2.firstLeft;
      outRec1.isHole = outRec2.isHole;
    }
    outRec2.pts = null;
    outRec2.bottomPt = null;

    outRec2.firstLeft = outRec1;

    var OKIdx:Int = e1.outIdx;
    var ObsoleteIdx:Int = e2.outIdx;

    e1.outIdx = ClipperBase.UNASSIGNED; //nb: safe because we only get here via AddLocalMaxPoly
    e2.outIdx = ClipperBase.UNASSIGNED;

    var e:TEdge = mActiveEdges;
    while (e != null) {
      if (e.outIdx == ObsoleteIdx) {
        e.outIdx = OKIdx;
        e.side = e1.side;
        break;
      }
      e = e.nextInAEL;
    }
    outRec2.idx = outRec1.idx;
  }
  //------------------------------------------------------------------------------

  function reversePolyPtLinks(pp:OutPt):Void {
    if (pp == null) return;
    var pp1:OutPt;
    var pp2:OutPt;
    pp1 = pp;
    do {
      pp2 = pp1.next;
      pp1.next = pp1.prev;
      pp1.prev = pp2;
      pp1 = pp2;
    } while (pp1 != pp);
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  static function swapSides(edge1:TEdge, edge2:TEdge):Void {
    var side:EdgeSide = edge1.side;
    edge1.side = edge2.side;
    edge2.side = side;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  static function swapPolyIndexes(edge1:TEdge, edge2:TEdge):Void {
    var outIdx:Int = edge1.outIdx;
    edge1.outIdx = edge2.outIdx;
    edge2.outIdx = outIdx;
  }
  //------------------------------------------------------------------------------

  function intersectEdges(e1:TEdge, e2:TEdge, pt:IntPoint):Void {
    //e1 will be to the left of e2 BELOW the intersection. Therefore e1 is before
    //e2 in AEL except when e1 is being inserted at the intersection point ...

    var e1Contributing = (e1.outIdx >= 0);
    var e2Contributing = (e2.outIdx >= 0);

    // NOTE: ref
  #if USE_XYZ
    setZ(/*ref*/ pt, e1, e2);
  #end

  #if USE_LINES
    //if either edge is on an OPEN path ...
    if (e1.windDelta == 0 || e2.windDelta == 0) {
      //ignore subject-subject open path intersections UNLESS they
      //are both open paths, AND they are both 'contributing maximas' ...
      if (e1.windDelta == 0 && e2.windDelta == 0) return;
      //if intersecting a subj line with a subj poly ...
      else if (e1.polyType == e2.polyType && e1.windDelta != e2.windDelta && mClipType == ClipType.CT_UNION) {
        if (e1.windDelta == 0) {
          if (e2Contributing) {
            addOutPt(e1, pt);
            if (e1Contributing) e1.outIdx = ClipperBase.UNASSIGNED;
          }
        } else {
          if (e1Contributing) {
            addOutPt(e2, pt);
            if (e2Contributing) e2.outIdx = ClipperBase.UNASSIGNED;
          }
        }
      } else if (e1.polyType != e2.polyType) {
        if ((e1.windDelta == 0) && Math.abs(e2.windCnt) == 1 && (mClipType != ClipType.CT_UNION || e2.windCnt2 == 0)) {
          addOutPt(e1, pt);
          if (e1Contributing) e1.outIdx = ClipperBase.UNASSIGNED;
        } else if ((e2.windDelta == 0) && (Math.abs(e1.windCnt) == 1) && (mClipType != ClipType.CT_UNION || e1.windCnt2 == 0)) {
          addOutPt(e2, pt);
          if (e2Contributing) e2.outIdx = ClipperBase.UNASSIGNED;
        }
      }
      return;
    }
  #end

    //update winding counts...
    //assumes that e1 will be to the Right of e2 ABOVE the intersection
    if (e1.polyType == e2.polyType) {
      if (isEvenOddFillType(e1)) {
        var oldE1WindCnt:Int = e1.windCnt;
        e1.windCnt = e2.windCnt;
        e2.windCnt = oldE1WindCnt;
      } else {
        if (e1.windCnt + e2.windDelta == 0) e1.windCnt = -e1.windCnt;
        else e1.windCnt += e2.windDelta;
        if (e2.windCnt - e1.windDelta == 0) e2.windCnt = -e2.windCnt;
        else e2.windCnt -= e1.windDelta;
      }
    } else {
      if (!isEvenOddFillType(e2)) e1.windCnt2 += e2.windDelta;
      else e1.windCnt2 = (e1.windCnt2 == 0) ? 1 : 0;
      if (!isEvenOddFillType(e1)) e2.windCnt2 -= e1.windDelta;
      else e2.windCnt2 = (e2.windCnt2 == 0) ? 1 : 0;
    }

    var e1FillType, e2FillType, e1FillType2, e2FillType2;
    if (e1.polyType == PolyType.PT_SUBJECT) {
      e1FillType = mSubjFillType;
      e1FillType2 = mClipFillType;
    } else {
      e1FillType = mClipFillType;
      e1FillType2 = mSubjFillType;
    }
    if (e2.polyType == PolyType.PT_SUBJECT) {
      e2FillType = mSubjFillType;
      e2FillType2 = mClipFillType;
    } else {
      e2FillType = mClipFillType;
      e2FillType2 = mSubjFillType;
    }

    var e1Wc:Int, e2Wc:Int;
    switch (e1FillType) {
      case PolyFillType.PFT_POSITIVE:
        e1Wc = e1.windCnt;
      case PolyFillType.PFT_NEGATIVE:
        e1Wc = -e1.windCnt;
      default:
        e1Wc = Std.int(Math.abs(e1.windCnt));
    }
    switch (e2FillType) {
      case PolyFillType.PFT_POSITIVE:
        e2Wc = e2.windCnt;
      case PolyFillType.PFT_NEGATIVE:
        e2Wc = -e2.windCnt;
      default:
        e2Wc = Std.int(Math.abs(e2.windCnt));
    }

    if (e1Contributing && e2Contributing) {
      if ((e1Wc != 0 && e1Wc != 1) || (e2Wc != 0 && e2Wc != 1) || (e1.polyType != e2.polyType && mClipType != ClipType.CT_XOR)) {
        addLocalMaxPoly(e1, e2, pt);
      } else {
        addOutPt(e1, pt);
        addOutPt(e2, pt);
        swapSides(e1, e2);
        swapPolyIndexes(e1, e2);
      }
    } else if (e1Contributing) {
      if (e2Wc == 0 || e2Wc == 1) {
        addOutPt(e1, pt);
        swapSides(e1, e2);
        swapPolyIndexes(e1, e2);
      }

    } else if (e2Contributing) {
      if (e1Wc == 0 || e1Wc == 1) {
        addOutPt(e2, pt);
        swapSides(e1, e2);
        swapPolyIndexes(e1, e2);
      }
    } else if ((e1Wc == 0 || e1Wc == 1) && (e2Wc == 0 || e2Wc == 1)) {
      //neither edge is currently contributing ...
      // NOTE: check double def of these ints, and Math.abs cast
      var e1Wc2:CInt, e2Wc2:CInt;
      switch (e1FillType2) {
        case PolyFillType.PFT_POSITIVE:
          e1Wc2 = e1.windCnt2;
        case PolyFillType.PFT_NEGATIVE:
          e1Wc2 = -e1.windCnt2;
        default:
          e1Wc2 = Std.int(Math.abs(e1.windCnt2));
      }
      switch (e2FillType2) {
        case PolyFillType.PFT_POSITIVE:
          e2Wc2 = e2.windCnt2;
        case PolyFillType.PFT_NEGATIVE:
          e2Wc2 = -e2.windCnt2;
        default:
          e2Wc2 = Std.int(Math.abs(e2.windCnt2));
      }

      if (e1.polyType != e2.polyType) {
        addLocalMinPoly(e1, e2, pt);
      } else if (e1Wc == 1 && e2Wc == 1) switch (mClipType) {
        case ClipType.CT_INTERSECTION:
          if (e1Wc2 > 0 && e2Wc2 > 0) addLocalMinPoly(e1, e2, pt);
        case ClipType.CT_UNION:
          if (e1Wc2 <= 0 && e2Wc2 <= 0) addLocalMinPoly(e1, e2, pt);
        case ClipType.CT_DIFFERENCE:
          if (((e1.polyType == PolyType.PT_CLIP) && (e1Wc2 > 0) && (e2Wc2 > 0))
            || ((e1.polyType == PolyType.PT_SUBJECT) && (e1Wc2 <= 0) && (e2Wc2 <= 0)))
          {
            addLocalMinPoly(e1, e2, pt);
          }
        case ClipType.CT_XOR:
          addLocalMinPoly(e1, e2, pt);
      } else swapSides(e1, e2);
    }
  }
  //------------------------------------------------------------------------------

  function deleteFromSEL(e:TEdge):Void {
    var selPrev:TEdge = e.prevInSEL;
    var selNext:TEdge = e.nextInSEL;
    if (selPrev == null && selNext == null && (e != mSortedEdges)) return; //already deleted
    if (selPrev != null) selPrev.nextInSEL = selNext;
    else mSortedEdges = selNext;
    if (selNext != null) selNext.prevInSEL = selPrev;
    e.nextInSEL = null;
    e.prevInSEL = null;
  }
  //------------------------------------------------------------------------------

  // NOTE: check r493 to 494 refactor
  function processHorizontals():Void {
    var horzEdge:TEdge = null; //mSortedEdges;
    while (true) {
      var popRes = popEdgeFromSEL(/*out horzEdge*/);
      horzEdge = popRes.edge;
      if (popRes.popped) {
        processHorizontal(horzEdge);
      } else {
        break;
      }
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: check out
  function getHorzDirection(horzEdge:TEdge, outParams:{/*out*/ dir:Direction, /*out*/ left:CInt, /*out*/right:CInt}):Void {
    if (horzEdge.bot.x < horzEdge.top.x) {
      outParams.left = horzEdge.bot.x;
      outParams.right = horzEdge.top.x;
      outParams.dir = Direction.D_LEFT_TO_RIGHT;
    } else {
      outParams.left = horzEdge.top.x;
      outParams.right = horzEdge.bot.x;
      outParams.dir = Direction.D_RIGHT_TO_LEFT;
    }
  }
  //------------------------------------------------------------------------

  function processHorizontal(horzEdge:TEdge):Void {
    var dir:Direction = null;
    var horzLeft:CInt = 0, horzRight:CInt = 0;
    var isOpen:Bool = horzEdge.windDelta == 0;

    // NOTE: out
    var outParams = {/*out*/ dir:dir, /*out*/ left:horzLeft, /*out*/ right:horzRight};
    getHorzDirection(horzEdge, outParams);
    dir = outParams.dir;
    horzLeft = outParams.left;
    horzRight = outParams.right;

    var eLastHorz:TEdge = horzEdge, eMaxPair:TEdge = null;
    while (eLastHorz.nextInLML != null && ClipperBase.isHorizontal(eLastHorz.nextInLML)) eLastHorz = eLastHorz.nextInLML;
    if (eLastHorz.nextInLML == null) eMaxPair = getMaximaPair(eLastHorz);

    var currMax = mMaxima;
    if (currMax != null) {
      //get the first maxima in range (X) ...
      if (dir == Direction.D_LEFT_TO_RIGHT) {
        while (currMax != null && currMax.x <= horzEdge.bot.x) currMax = currMax.next;
        if (currMax != null && currMax.x >= eLastHorz.top.x) currMax = null;
      } else {
        while (currMax.next != null && currMax.next.x < horzEdge.bot.x) currMax = currMax.next;
        if (currMax.x <= eLastHorz.top.x) currMax = null;
      }
    }

    var op1:OutPt = null;
    while (true) {  //loop through consec. horizontal edges
      var isLastHorz = (horzEdge == eLastHorz);
      var e:TEdge = getNextInAEL(horzEdge, dir);
      while (e != null) {
        //this code block inserts extra coords into horizontal edges (in output
        //polygons) wherever maxima touch these horizontal edges. This helps
        //'simplifying' polygons (ie if the Simplify property is set).
        if (currMax != null)
        {
          if (dir == Direction.D_LEFT_TO_RIGHT) {
            while (currMax != null && currMax.x < e.curr.x) {
              if (horzEdge.outIdx >= 0 && !isOpen) addOutPt(horzEdge, new IntPoint(currMax.x, horzEdge.bot.y));
              currMax = currMax.next;
            }
          } else {
            while (currMax != null && currMax.x > e.curr.x) {
              if (horzEdge.outIdx >= 0 && !isOpen) addOutPt(horzEdge, new IntPoint(currMax.x, horzEdge.bot.y));
              currMax = currMax.prev;
            }
          }
        }

        if ((dir == Direction.D_LEFT_TO_RIGHT && e.curr.x > horzRight) ||
          (dir == Direction.D_RIGHT_TO_LEFT && e.curr.x < horzLeft)) break;

        //Also break if we've got to the end of an intermediate horizontal edge ...
        //nb: Smaller Dx's are to the right of larger Dx's ABOVE the horizontal.
        if (e.curr.x == horzEdge.top.x && horzEdge.nextInLML != null && e.dx < horzEdge.nextInLML.dx) break;

        if (horzEdge.outIdx >= 0 && !isOpen) { //note: may be done multiple times
        #if USE_XYZ
          if (dir == Direction.D_LEFT_TO_RIGHT) setZ(/*ref*/ e.curr, horzEdge, e);
          else setZ(/*ref*/ e.curr, e, horzEdge);
        #end
          op1 = addOutPt(horzEdge, e.curr);
          var eNextHorz:TEdge = mSortedEdges;
          while (eNextHorz != null) {
            if (eNextHorz.outIdx >= 0 && horzSegmentsOverlap(horzEdge.bot.x, horzEdge.top.x, eNextHorz.bot.x, eNextHorz.top.x)) {
              var op2:OutPt = getLastOutPt(eNextHorz);
              addJoin(op2, op1, eNextHorz.top);
            }
            eNextHorz = eNextHorz.nextInSEL;
          }
          addGhostJoin(op1, horzEdge.bot);
        }

        //OK, so far we're still in range of the horizontal Edge  but make sure
        //we're at the last of consec. horizontals when matching with eMaxPair
        if (e == eMaxPair && isLastHorz)
        {
          if (horzEdge.outIdx >= 0) addLocalMaxPoly(horzEdge, eMaxPair, horzEdge.top);
          deleteFromAEL(horzEdge);
          deleteFromAEL(eMaxPair);
          return;
        }

        if (dir == Direction.D_LEFT_TO_RIGHT) {
          var pt = new IntPoint(e.curr.x, horzEdge.curr.y);
          intersectEdges(horzEdge, e, pt);
        } else {
          var pt = new IntPoint(e.curr.x, horzEdge.curr.y);
          intersectEdges(e, horzEdge, pt);
        }
        var eNext:TEdge = getNextInAEL(e, dir);
        swapPositionsInAEL(horzEdge, e);

        e = eNext;
      } //end while (e != null)

      //Break out of loop if HorzEdge.NextInLML is not also horizontal ...
      if (horzEdge.nextInLML == null || !ClipperBase.isHorizontal(horzEdge.nextInLML)) break;

      // NOTE: ref
      horzEdge = updateEdgeIntoAEL(/*ref*/ horzEdge);
      if (horzEdge.outIdx >= 0) addOutPt(horzEdge, horzEdge.bot);
      // NOTE: out
      getHorzDirection(horzEdge, outParams);
      dir = outParams.dir;
      horzLeft = outParams.left;
      horzRight = outParams.right;

    } //end for (;;)

    if (horzEdge.outIdx >= 0 && op1 == null) {
        op1 = getLastOutPt(horzEdge);
        var eNextHorz:TEdge = mSortedEdges;
        while (eNextHorz != null) {
            if (eNextHorz.outIdx >= 0 &&
      horzSegmentsOverlap(horzEdge.bot.x,
      horzEdge.top.x, eNextHorz.bot.x, eNextHorz.top.x))
            {
                var op2:OutPt = getLastOutPt(eNextHorz);
                addJoin(op2, op1, eNextHorz.top);
            }
            eNextHorz = eNextHorz.nextInSEL;
        }
        addGhostJoin(op1, horzEdge.top);
    }

    if (horzEdge.nextInLML != null) {
      if (horzEdge.outIdx >= 0) {
        var op1:OutPt = addOutPt(horzEdge, horzEdge.top);

        // NOTE: ref
        horzEdge = updateEdgeIntoAEL(/*ref*/ horzEdge);
        if (horzEdge.windDelta == 0) return;
        //nb: HorzEdge is no longer horizontal here
        var ePrev:TEdge = horzEdge.prevInAEL;
        var eNext:TEdge = horzEdge.nextInAEL;
        if (ePrev != null && ePrev.curr.x == horzEdge.bot.x && ePrev.curr.y == horzEdge.bot.y && ePrev.windDelta != 0
          && (ePrev.outIdx >= 0 && ePrev.curr.y > ePrev.top.y && ClipperBase.slopesEqual(horzEdge, ePrev, mUseFullRange)))
        {
          var op2:OutPt = addOutPt(ePrev, horzEdge.bot);
          addJoin(op1, op2, horzEdge.top);
        } else if (eNext != null && eNext.curr.x == horzEdge.bot.x && eNext.curr.y == horzEdge.bot.y && eNext.windDelta != 0
               && eNext.outIdx >= 0 && eNext.curr.y > eNext.top.y && ClipperBase.slopesEqual(horzEdge, eNext, mUseFullRange))
        {
          var op2:OutPt = addOutPt(eNext, horzEdge.bot);
          addJoin(op1, op2, horzEdge.top);
        }
        // NOTE: ref
      } else horzEdge = updateEdgeIntoAEL(/*ref*/ horzEdge);
    } else {
      if (horzEdge.outIdx >= 0) addOutPt(horzEdge, horzEdge.top);
      deleteFromAEL(horzEdge);
    }
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function getNextInAEL(e:TEdge, direction:Direction):TEdge {
    return direction == Direction.D_LEFT_TO_RIGHT ? e.nextInAEL : e.prevInAEL;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function isMinima(e:TEdge):Bool {
    return e != null && (e.prev.nextInLML != e) && (e.next.nextInLML != e);
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function isMaxima(e:TEdge, y:Float):Bool {
    return (e != null && e.top.y == y && e.nextInLML == null);
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function isIntermediate(e:TEdge, y:Float):Bool {
    return (e.top.y == y && e.nextInLML != null);
  }
  //------------------------------------------------------------------------------

  // NOTE: using equals() instead ot == to test equality. Check other places where this change is needed.
  /*internal*/ function getMaximaPair(e:TEdge):TEdge {
    if ((e.next.top.equals(e.top)) && e.next.nextInLML == null)
      return e.next;
    else if ((e.prev.top.equals(e.top)) && e.prev.nextInLML == null)
      return e.prev;
    else
      return null;
  }
  //------------------------------------------------------------------------------

  /*internal*/ function getMaximaPairEx(e:TEdge):TEdge {
    //as above but returns null if MaxPair isn't in AEL (unless it's horizontal)
    var result:TEdge = getMaximaPair(e);
    if (result == null || result.outIdx == ClipperBase.SKIP
      || ((result.nextInAEL == result.prevInAEL) && !ClipperBase.isHorizontal(result)))
    {
      return null;
    }
    return result;
  }
  //------------------------------------------------------------------------------

  function processIntersections(topY:CInt):Bool {
    if (mActiveEdges == null) return true;
    try {
      buildIntersectList(topY);
      if (mIntersectList.length == 0) return true;
      if (mIntersectList.length == 1 || fixupIntersectionOrder()) {
        processIntersectList();
      }
      else return false;
    }
  #if (!CLIPPER_NO_EXCEPTIONS)
    catch (e:Dynamic) {
      mSortedEdges = null;
      mIntersectList.clear();
      throw new ClipperException("ProcessIntersections error");
    }
  #end
    mSortedEdges = null;
    return true;
  }
  //------------------------------------------------------------------------------

  function buildIntersectList(topY:CInt):Void {
    if (mActiveEdges == null) return;

    //prepare for sorting ...
    var e:TEdge = mActiveEdges;
    mSortedEdges = e;
    while (e != null) {
      e.prevInSEL = e.prevInAEL;
      e.nextInSEL = e.nextInAEL;
      e.curr.x = topX(e, topY);
      e = e.nextInAEL;
    }

    //bubblesort ...
    var isModified = true;
    while (isModified && mSortedEdges != null) {
      isModified = false;
      e = mSortedEdges;
      while (e.nextInSEL != null) {
        var eNext:TEdge = e.nextInSEL;
        var pt:IntPoint = new IntPoint();
        if (e.curr.x > eNext.curr.x) {
          // NOTE: out
          intersectPoint(e, eNext, /*out*/ pt);
          if (pt.y < topY) {
            pt = new IntPoint(topX(e, topY), topY);
          }
          var newNode = new IntersectNode();
          newNode.edge1 = e;
          newNode.edge2 = eNext;
          newNode.pt.copyFrom(pt);
          mIntersectList.push(newNode);

          swapPositionsInSEL(e, eNext);
          isModified = true;
        } else e = eNext;
      }
      if (e.prevInSEL != null) e.prevInSEL.nextInSEL = null;
      else break;
    }
    mSortedEdges = null;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function edgesAdjacent(inode:IntersectNode):Bool {
    return (inode.edge1.nextInSEL == inode.edge2) || (inode.edge1.prevInSEL == inode.edge2);
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  static function intersectNodeSort(node1:IntersectNode, node2:IntersectNode):Int {
    //the following typecast is safe because the differences in Pt.Y will
    //be limited to the height of the scanbeam.
    // NOTE: check cast
    return Std.int(node2.pt.y - node1.pt.y);
  }
  //------------------------------------------------------------------------------

  function fixupIntersectionOrder():Bool {
    //pre-condition: intersections are sorted bottom-most first.
    //Now it's crucial that intersections are made only between adjacent edges,
    //so to ensure this the order of intersections may need adjusting ...
    ArraySort.sort(mIntersectList, mIntersectNodeComparer);

    copyAELToSEL();
    var cnt:Int = mIntersectList.length;
    for (i in 0...cnt) {
      if (!edgesAdjacent(mIntersectList[i])) {
        var j = i + 1;
        while (j < cnt && !edgesAdjacent(mIntersectList[j])) j++;
        if (j == cnt) return false;

        var tmp:IntersectNode = mIntersectList[i];
        mIntersectList[i] = mIntersectList[j];
        mIntersectList[j] = tmp;

      }
      swapPositionsInSEL(mIntersectList[i].edge1, mIntersectList[i].edge2);
    }
    return true;
  }
  //------------------------------------------------------------------------------

  function processIntersectList():Void {
    for (i in 0...mIntersectList.length) {
      var iNode:IntersectNode = mIntersectList[i];
      intersectEdges(iNode.edge1, iNode.edge2, iNode.pt);
      swapPositionsInAEL(iNode.edge1, iNode.edge2);

    }
    mIntersectList.clear();
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ static function round(value:Float):CInt {
    // NOTE: check how to cast
    return value < 0 ? /*(cInt)*/Std.int(value - 0.5) : /*(cInt)*/Std.int(value + 0.5);
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  static function topX(edge:TEdge, currentY:CInt):CInt {
    if (currentY == edge.top.y) return edge.top.x;
    return edge.bot.x + round(edge.dx * (currentY - edge.bot.y));
  }
  //------------------------------------------------------------------------------

  // NOTE: check out
  function intersectPoint(edge1:TEdge, edge2:TEdge, /*out*/ ip:IntPoint):Void {
    // NOTE: check this ip and the out ip
    //ip = new IntPoint();
    var b1:Float, b2:Float;
    //nb: with very large coordinate values, it's possible for SlopesEqual() to
    //return false but for the edge.Dx value be equal due to double precision rounding.
    if (edge1.dx == edge2.dx) {
      ip.y = edge1.curr.y;
      ip.x = topX(edge1, ip.y);
      return;
    }

    if (edge1.delta.x == 0) {
      ip.x = edge1.bot.x;
      if (ClipperBase.isHorizontal(edge2)) {
        ip.y = edge2.bot.y;
      } else {
        b2 = edge2.bot.y - (edge2.bot.x / edge2.dx);
        ip.y = round(ip.x / edge2.dx + b2);
      }
    } else if (edge2.delta.x == 0) {
      ip.x = edge2.bot.x;
      if (ClipperBase.isHorizontal(edge1)) {
        ip.y = edge1.bot.y;
      } else {
        b1 = edge1.bot.y - (edge1.bot.x / edge1.dx);
        ip.y = round(ip.x / edge1.dx + b1);
      }
    } else {
      b1 = edge1.bot.x - edge1.bot.y * edge1.dx;
      b2 = edge2.bot.x - edge2.bot.y * edge2.dx;
      var q:Float = (b2 - b1) / (edge1.dx - edge2.dx);
      ip.y = round(q);
      if (Math.abs(edge1.dx) < Math.abs(edge2.dx)) ip.x = round(edge1.dx * q + b1);
      else ip.x = round(edge2.dx * q + b2);
    }

    if (ip.y < edge1.top.y || ip.y < edge2.top.y) {
      if (edge1.top.y > edge2.top.y) ip.y = edge1.top.y;
      else ip.y = edge2.top.y;
      if (Math.abs(edge1.dx) < Math.abs(edge2.dx)) ip.x = topX(edge1, ip.y);
      else ip.x = topX(edge2, ip.y);
    }
    //finally, don't allow 'ip' to be BELOW curr.Y (ie bottom of scanbeam) ...
    if (ip.y > edge1.curr.y) {
      ip.y = edge1.curr.y;
      //better to use the more vertical edge to derive X ...
      if (Math.abs(edge1.dx) > Math.abs(edge2.dx)) ip.x = topX(edge2, ip.y);
      else ip.x = topX(edge1, ip.y);
    }
  }
  //------------------------------------------------------------------------------

  function processEdgesAtTopOfScanbeam(topY:CInt):Void {
    var e:TEdge = mActiveEdges;
    while (e != null) {
      //1. process maxima, treating them as if they're 'bent' horizontal edges,
      //   but exclude maxima with horizontal edges. nb: e can't be a horizontal.
      var isMaximaEdge:Bool = isMaxima(e, topY);

      if (isMaximaEdge) {
        var eMaxPair:TEdge = getMaximaPairEx(e);
        isMaximaEdge = (eMaxPair == null || !ClipperBase.isHorizontal(eMaxPair));
      }

      if (isMaximaEdge) {
        if (strictlySimple) insertMaxima(e.top.x);
        var ePrev:TEdge = e.prevInAEL;
        doMaxima(e);
        if (ePrev == null) e = mActiveEdges;
        else e = ePrev.nextInAEL;
      } else {
        //2. promote horizontal edges, otherwise update Curr.X and Curr.Y ...
        if (isIntermediate(e, topY) && ClipperBase.isHorizontal(e.nextInLML)) {
          // NOTE: ref
          e = updateEdgeIntoAEL(/*ref*/ e);
          if (e.outIdx >= 0) addOutPt(e, e.bot);
          addEdgeToSEL(e);
        } else {
          e.curr.x = topX(e, topY);
          e.curr.y = topY;
        #if USE_XYZ
          if (e.top.y == topY) e.curr.z = e.top.z;
          else if (e.bot.y == topY) e.curr.z = e.bot.z;
          else e.curr.z = 0;
        #end
        }

        //When StrictlySimple and 'e' is being touched by another edge, then
        //make sure both edges have a vertex here ...
        if (strictlySimple) {
          var ePrev:TEdge = e.prevInAEL;
          if ((e.outIdx >= 0) && (e.windDelta != 0) && ePrev != null && (ePrev.outIdx >= 0)
            && (ePrev.curr.x == e.curr.x) && (ePrev.windDelta != 0))
          {
            // NOTE: I foresee a compiler error here
            var ip = e.curr.clone();
          #if USE_XYZ
            setZ(/*ref*/ ip, ePrev, e);
          #end
            var op:OutPt = addOutPt(ePrev, ip);
            var op2:OutPt = addOutPt(e, ip);
            addJoin(op, op2, ip); //StrictlySimple (type-3) join
          }
        }

        e = e.nextInAEL;
      }
    }

    //3. Process horizontals at the Top of the scanbeam ...
    processHorizontals();
        mMaxima = null;

    //4. Promote intermediate vertices ...
    e = mActiveEdges;
    while (e != null) {
      if (isIntermediate(e, topY)) {
        var op:OutPt = null;
        if (e.outIdx >= 0) op = addOutPt(e, e.top);
        // NOTE: ref
        e = updateEdgeIntoAEL(/*ref*/ e);

        //if output polygons share an edge, they'll need joining later ...
        var ePrev:TEdge = e.prevInAEL;
        var eNext:TEdge = e.nextInAEL;
        if (ePrev != null && ePrev.curr.x == e.bot.x && ePrev.curr.y == e.bot.y && op != null && ePrev.outIdx >= 0
          && ePrev.curr.y > ePrev.top.y
          && ClipperBase.slopesEqual4(e.curr, e.top, ePrev.curr, ePrev.top, mUseFullRange)
          && (e.windDelta != 0) && (ePrev.windDelta != 0))
        {
          var op2:OutPt = addOutPt(ePrev, e.bot);
          addJoin(op, op2, e.top);
        } else if (eNext != null && eNext.curr.x == e.bot.x && eNext.curr.y == e.bot.y && op != null && eNext.outIdx >= 0
               && eNext.curr.y > eNext.top.y
               && ClipperBase.slopesEqual4(e.curr, e.top, eNext.curr, eNext.top, mUseFullRange)
               && (e.windDelta != 0) && (eNext.windDelta != 0))
        {
          var op2:OutPt = addOutPt(eNext, e.bot);
          addJoin(op, op2, e.top);
        }
      }
      e = e.nextInAEL;
    }
  }
  //------------------------------------------------------------------------------

  function doMaxima(e:TEdge):Void {
    var eMaxPair:TEdge = getMaximaPairEx(e);
    if (eMaxPair == null) {
      if (e.outIdx >= 0) addOutPt(e, e.top);
      deleteFromAEL(e);
      return;
    }

    var eNext:TEdge = e.nextInAEL;
    while (eNext != null && eNext != eMaxPair) {
      intersectEdges(e, eNext, e.top);
      swapPositionsInAEL(e, eNext);
      eNext = e.nextInAEL;
    }

    if (e.outIdx == ClipperBase.UNASSIGNED && eMaxPair.outIdx == ClipperBase.UNASSIGNED) {
      deleteFromAEL(e);
      deleteFromAEL(eMaxPair);
    } else if (e.outIdx >= 0 && eMaxPair.outIdx >= 0) {
      if (e.outIdx >= 0) addLocalMaxPoly(e, eMaxPair, e.top);
      deleteFromAEL(e);
      deleteFromAEL(eMaxPair);
    }
  #if USE_LINES
    else if (e.windDelta == 0) {
      if (e.outIdx >= 0) {
        addOutPt(e, e.top);
        e.outIdx = ClipperBase.UNASSIGNED;
      }
      deleteFromAEL(e);

      if (eMaxPair.outIdx >= 0) {
        addOutPt(eMaxPair, e.top);
        eMaxPair.outIdx = ClipperBase.UNASSIGNED;
      }
      deleteFromAEL(eMaxPair);
    }
  #end
  #if (!CLIPPER_NO_EXCEPTIONS)
    else throw new ClipperException("DoMaxima error");
  #end
  }
  //------------------------------------------------------------------------------

  static public function reversePaths(polys:Paths):Void {
    for (poly in polys) {
      poly.reverse();
    }
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  static public function orientation(poly:Path):Bool {
    return area(poly) >= 0;
  }
  //------------------------------------------------------------------------------

  function pointCount(pts:OutPt):Int {
    if (pts == null) return 0;
    var result:Int = 0;
    var p:OutPt = pts;
    do {
      result++;
      p = p.next;
    } while (p != pts);

    return result;
  }
  //------------------------------------------------------------------------------

  function buildResult(polyg:Paths):Void {
    polyg.clear();
    //NOTE:polyg.Capacity = mPolyOuts.length;
    for (i in 0...mPolyOuts.length) {
      var outRec:OutRec = mPolyOuts[i];
      if (outRec.pts == null) continue;
      var p:OutPt = outRec.pts.prev;
      var cnt:Int = pointCount(p);
      if (cnt < 2) continue;
      var pg = new Path(/*NOTE:cnt*/);
      for (j in 0...cnt) {
        pg.push(p.pt);
        p = p.prev;
      }
      polyg.push(pg);
    }
  }
  //------------------------------------------------------------------------------

  function buildResult2(polytree:PolyTree):Void {
    polytree.clear();

    //add each output polygon/contour to polytree ...
    //NOTE:polytree.mAllPolys.Capacity = mPolyOuts.length;
    for (i in 0...mPolyOuts.length) {
      var outRec:OutRec = mPolyOuts[i];
      var cnt:Int = pointCount(outRec.pts);
      if ((outRec.isOpen && cnt < 2) || (!outRec.isOpen && cnt < 3)) continue;
      fixHoleLinkage(outRec);
      var pn = new PolyNode();
      polytree.mAllPolys.push(pn);
      outRec.polyNode = pn;
      //NOTE:pn.mPolygon.Capacity = cnt;
      var op:OutPt = outRec.pts.prev;
      for (j in 0...cnt) {
        pn.mPolygon.push(op.pt);
        op = op.prev;
      }
    }

    //fixup PolyNode links etc ...
    //NOTE:polytree.mChilds.Capacity = mPolyOuts.length;
    for (i in 0...mPolyOuts.length) {
      var outRec:OutRec = mPolyOuts[i];
      if (outRec.polyNode == null) continue;
      else if (outRec.isOpen) {
        outRec.polyNode.isOpen = true;
        polytree.addChild(outRec.polyNode);
      } else if (outRec.firstLeft != null && outRec.firstLeft.polyNode != null) outRec.firstLeft.polyNode.addChild(outRec.polyNode);
      else polytree.addChild(outRec.polyNode);
    }
  }
  //------------------------------------------------------------------------------

  function fixupOutPolyLine(outrec:OutRec):Void {
    var pp:OutPt = outrec.pts;
    var lastPP:OutPt = pp.prev;
    while (pp != lastPP) {
      pp = pp.next;
      if (pp.pt == pp.prev.pt) {
        if (pp == lastPP) lastPP = pp.prev;
        var tmpPP:OutPt = pp.prev;
        tmpPP.next = pp.next;
        pp.next.prev = tmpPP;
        pp = tmpPP;
      }
    }
    if (pp == pp.prev) outrec.pts = null;
  }
  //------------------------------------------------------------------------------

  function fixupOutPolygon(outRec:OutRec):Void {
    //FixupOutPolygon() - removes duplicate points and simplifies consecutive
    //parallel edges by removing the middle vertex.
    var lastOK:OutPt = null;
    outRec.bottomPt = null;
    var pp:OutPt = outRec.pts;
    var preserveCol = preserveCollinear || strictlySimple;
    while (true) {
      if (pp.prev == pp || pp.prev == pp.next) {
        outRec.pts = null;
        return;
      }
      //test for duplicate points and collinear edges ...
      if ((pp.pt.equals(pp.next.pt)) || (pp.pt.equals(pp.prev.pt)) || (ClipperBase.slopesEqual3(pp.prev.pt, pp.pt, pp.next.pt, mUseFullRange)
        && (!preserveCol || !pt2IsBetweenPt1AndPt3(pp.prev.pt, pp.pt, pp.next.pt))))
      {
        lastOK = null;
        pp.prev.next = pp.next;
        pp.next.prev = pp.prev;
        pp = pp.prev;
      } else if (pp == lastOK) break;
      else {
        if (lastOK == null) lastOK = pp;
        pp = pp.next;
      }
    }
    outRec.pts = pp;
  }
  //------------------------------------------------------------------------------

  function dupOutPt(outPt:OutPt, insertAfter:Bool):OutPt {
    var result = new OutPt();
    result.pt.copyFrom(outPt.pt);
    result.idx = outPt.idx;
    if (insertAfter) {
      result.next = outPt.next;
      result.prev = outPt;
      outPt.next.prev = result;
      outPt.next = result;
    } else {
      result.prev = outPt.prev;
      result.next = outPt;
      outPt.prev.next = result;
      outPt.prev = result;
    }
    return result;
  }
  //------------------------------------------------------------------------------

  // NOTE: out
  function getOverlap(a1:CInt, a2:CInt, b1:CInt, b2:CInt, outParams:{/*out*/ left:CInt, /*out*/ right:CInt}):Bool {
    if (a1 < a2) {
      // NOTE: check casts to CInt
      if (b1 < b2) {
        outParams.left = Std.int(Math.max(a1, b1));
        outParams.right = Std.int(Math.min(a2, b2));
      } else {
        outParams.left = Std.int(Math.max(a1, b2));
        outParams.right = Std.int(Math.min(a2, b1));
      }
    } else {
      if (b1 < b2) {
        outParams.left = Std.int(Math.max(a2, b1));
        outParams.right = Std.int(Math.min(a1, b2));
      } else {
        outParams.left = Std.int(Math.max(a2, b2));
        outParams.right = Std.int(Math.min(a1, b1));
      }
    }
    return outParams.left < outParams.right;
  }
  //------------------------------------------------------------------------------

  function joinHorz(op1:OutPt, op1b:OutPt, op2:OutPt, op2b:OutPt,  pt:IntPoint, discardLeft:Bool):Bool {
    var dir1:Direction = (op1.pt.x > op1b.pt.x ? Direction.D_RIGHT_TO_LEFT : Direction.D_LEFT_TO_RIGHT);
    var dir2:Direction = (op2.pt.x > op2b.pt.x ? Direction.D_RIGHT_TO_LEFT : Direction.D_LEFT_TO_RIGHT);
    if (dir1 == dir2) return false;

    //When DiscardLeft, we want Op1b to be on the Left of Op1, otherwise we
    //want Op1b to be on the Right. (And likewise with Op2 and Op2b.)
    //So, to facilitate this while inserting Op1b and Op2b ...
    //when DiscardLeft, make sure we're AT or RIGHT of Pt before adding Op1b,
    //otherwise make sure we're AT or LEFT of Pt. (Likewise with Op2b.)
    if (dir1 == Direction.D_LEFT_TO_RIGHT) {
      while (op1.next.pt.x <= pt.x && op1.next.pt.x >= op1.pt.x && op1.next.pt.y == pt.y) op1 = op1.next;

      if (discardLeft && (op1.pt.x != pt.x)) op1 = op1.next;
      op1b = dupOutPt(op1, !discardLeft);
      if (!op1b.pt.equals(pt)) {
        op1 = op1b;
        op1.pt.copyFrom(pt);
        op1b = dupOutPt(op1, !discardLeft);
      }
    } else {
      while (op1.next.pt.x >= pt.x && op1.next.pt.x <= op1.pt.x && op1.next.pt.y == pt.y) op1 = op1.next;

      if (!discardLeft && (op1.pt.x != pt.x)) op1 = op1.next;
      op1b = dupOutPt(op1, discardLeft);
      if (!op1b.pt.equals(pt)) {
        op1 = op1b;
        op1.pt.copyFrom(pt);
        op1b = dupOutPt(op1, discardLeft);
      }
    }

    if (dir2 == Direction.D_LEFT_TO_RIGHT) {
      while (op2.next.pt.x <= pt.x && op2.next.pt.x >= op2.pt.x && op2.next.pt.y == pt.y) op2 = op2.next;

      if (discardLeft && (op2.pt.x != pt.x)) op2 = op2.next;
      op2b = dupOutPt(op2, !discardLeft);
      if (!op2b.pt.equals(pt)) {
        op2 = op2b;
        op2.pt.copyFrom(pt);
        op2b = dupOutPt(op2, !discardLeft);
      }
    } else {
      while (op2.next.pt.x >= pt.x && op2.next.pt.x <= op2.pt.x && op2.next.pt.y == pt.y) op2 = op2.next;

      if (!discardLeft && (op2.pt.x != pt.x)) op2 = op2.next;
      op2b = dupOutPt(op2, discardLeft);
      if (!op2b.pt.equals(pt)) {
        op2 = op2b;
        op2.pt.copyFrom(pt);
        op2b = dupOutPt(op2, discardLeft);
      }
    }

    if ((dir1 == Direction.D_LEFT_TO_RIGHT) == discardLeft) {
      op1.prev = op2;
      op2.next = op1;
      op1b.next = op2b;
      op2b.prev = op1b;
    } else {
      op1.next = op2;
      op2.prev = op1;
      op1b.prev = op2b;
      op2b.next = op1b;
    }
    return true;
  }
  //------------------------------------------------------------------------------

  function joinPoints(j:Join, outRec1:OutRec, outRec2:OutRec):Bool {
    var op1:OutPt = j.outPt1, op1b;
    var op2:OutPt = j.outPt2, op2b;

    //There are 3 kinds of joins for output polygons ...
    //1. Horizontal joins where Join.OutPt1 & Join.OutPt2 are vertices anywhere
    //along (horizontal) collinear edges (& Join.OffPt is on the same horizontal).
    //2. Non-horizontal joins where Join.OutPt1 & Join.OutPt2 are at the same
    //location at the Bottom of the overlapping segment (& Join.OffPt is above).
    //3. StrictlySimple joins where edges touch but are not collinear and where
    //Join.OutPt1, Join.OutPt2 & Join.OffPt all share the same point.
    var isHorizontal:Bool = (j.outPt1.pt.y == j.offPt.y);

    if (isHorizontal && (j.offPt.equals(j.outPt1.pt)) && (j.offPt.equals(j.outPt2.pt))) {
      //Strictly Simple join ...
      if (outRec1 != outRec2) return false;
      op1b = j.outPt1.next;
      // NOTE: check whiles
      while (op1b != op1 && (op1b.pt.equals(j.offPt))) {
        op1b = op1b.next;
      }
      var reverse1:Bool = (op1b.pt.y > j.offPt.y);
      op2b = j.outPt2.next;
      while (op2b != op2 && (op2b.pt.equals(j.offPt))) {
        op2b = op2b.next;
      }
      var reverse2:Bool = (op2b.pt.y > j.offPt.y);
      if (reverse1 == reverse2) return false;
      if (reverse1) {
        op1b = dupOutPt(op1, false);
        op2b = dupOutPt(op2, true);
        op1.prev = op2;
        op2.next = op1;
        op1b.next = op2b;
        op2b.prev = op1b;
        j.outPt1 = op1;
        j.outPt2 = op1b;
        return true;
      } else {
        op1b = dupOutPt(op1, true);
        op2b = dupOutPt(op2, false);
        op1.next = op2;
        op2.prev = op1;
        op1b.prev = op2b;
        op2b.next = op1b;
        j.outPt1 = op1;
        j.outPt2 = op1b;
        return true;
      }
    } else if (isHorizontal) {
      //treat horizontal joins differently to non-horizontal joins since with
      //them we're not yet sure where the overlapping is. OutPt1.pt & OutPt2.pt
      //may be anywhere along the horizontal edge.
      op1b = op1;
      while (op1.prev.pt.y == op1.pt.y && op1.prev != op1b && op1.prev != op2) op1 = op1.prev;
      while (op1b.next.pt.y == op1b.pt.y && op1b.next != op1 && op1b.next != op2) op1b = op1b.next;
      if (op1b.next == op1 || op1b.next == op2) return false; //a flat 'polygon'

      op2b = op2;
      while (op2.prev.pt.y == op2.pt.y && op2.prev != op2b && op2.prev != op1b) op2 = op2.prev;
      while (op2b.next.pt.y == op2b.pt.y && op2b.next != op2 && op2b.next != op1) op2b = op2b.next;
      if (op2b.next == op2 || op2b.next == op1) return false; //a flat 'polygon'

      var left:CInt = 0, right:CInt = 0;
      //Op1 -. Op1b & Op2 -. Op2b are the extremites of the horizontal edges
      // NOTE: out
      var outParams = { left:left, right:right };
      if (!getOverlap(op1.pt.x, op1b.pt.x, op2.pt.x, op2b.pt.x, outParams)) return false;
      left = outParams.left;
      right = outParams.right;

      //DiscardLeftSide: when overlapping edges are joined, a spike will created
      //which needs to be cleaned up. However, we don't want Op1 or Op2 caught up
      //on the discard Side as either may still be needed for other joins ...
      var pt:IntPoint = new IntPoint();
      var discardLeftSide:Bool;
      if (op1.pt.x >= left && op1.pt.x <= right) {
        pt.copyFrom(op1.pt);
        discardLeftSide = (op1.pt.x > op1b.pt.x);
      } else if (op2.pt.x >= left && op2.pt.x <= right) {
        pt.copyFrom(op2.pt);
        discardLeftSide = (op2.pt.x > op2b.pt.x);
      } else if (op1b.pt.x >= left && op1b.pt.x <= right) {
        pt.copyFrom(op1b.pt);
        discardLeftSide = op1b.pt.x > op1.pt.x;
      } else {
        pt.copyFrom(op2b.pt);
        discardLeftSide = (op2b.pt.x > op2.pt.x);
      }
      j.outPt1 = op1;
      j.outPt2 = op2;
      return joinHorz(op1, op1b, op2, op2b, pt, discardLeftSide);
    } else {
      //nb: For non-horizontal joins ...
      //    1. Jr.OutPt1.pt.Y == Jr.OutPt2.pt.Y
      //    2. Jr.OutPt1.pt > Jr.OffPt.Y

      //make sure the polygons are correctly oriented ...
      op1b = op1.next;
      while ((op1b.pt.equals(op1.pt)) && (op1b != op1)) op1b = op1b.next;
      var reverse1:Bool = ((op1b.pt.y > op1.pt.y) || !ClipperBase.slopesEqual3(op1.pt, op1b.pt, j.offPt, mUseFullRange));
      if (reverse1) {
        op1b = op1.prev;
        while ((op1b.pt.equals(op1.pt)) && (op1b != op1)) op1b = op1b.prev;
        if ((op1b.pt.y > op1.pt.y) || !ClipperBase.slopesEqual3(op1.pt, op1b.pt, j.offPt, mUseFullRange)) return false;
      }
      op2b = op2.next;
      while ((op2b.pt.equals(op2.pt)) && (op2b != op2)) op2b = op2b.next;
      var reverse2:Bool = ((op2b.pt.y > op2.pt.y) || !ClipperBase.slopesEqual3(op2.pt, op2b.pt, j.offPt, mUseFullRange));
      if (reverse2) {
        op2b = op2.prev;
        while ((op2b.pt.equals(op2.pt)) && (op2b != op2)) op2b = op2b.prev;
        if ((op2b.pt.y > op2.pt.y) || !ClipperBase.slopesEqual3(op2.pt, op2b.pt, j.offPt, mUseFullRange)) return false;
      }

      if ((op1b == op1) || (op2b == op2) || (op1b == op2b) || ((outRec1 == outRec2) && (reverse1 == reverse2))) return false;

      if (reverse1) {
        op1b = dupOutPt(op1, false);
        op2b = dupOutPt(op2, true);
        op1.prev = op2;
        op2.next = op1;
        op1b.next = op2b;
        op2b.prev = op1b;
        j.outPt1 = op1;
        j.outPt2 = op1b;
        return true;
      } else {
        op1b = dupOutPt(op1, true);
        op2b = dupOutPt(op2, false);
        op1.next = op2;
        op2.prev = op1;
        op1b.prev = op2b;
        op2b.next = op1b;
        j.outPt1 = op1;
        j.outPt2 = op1b;
        return true;
      }
    }
  }
  //----------------------------------------------------------------------

  //See "The Point in Polygon Problem for Arbitrary Polygons" by Hormann & Agathos
  //http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.88.5498&rep=rep1&type=pdf
  static public function pointInPolygon(pt:IntPoint, path:Path):Int {
    //returns 0 if false, +1 if true, -1 if pt ON polygon boundary

    var result:Int = 0, cnt:Int = path.length;
    if (cnt < 3) return 0;
    var ip:IntPoint = path[0].clone();
    // NOTE: check loop and casts
    var ipNext:IntPoint = new IntPoint();
    for (i in 1...cnt + 1) {
      ipNext.copyFrom((i == cnt ? path[0] : path[i]));
      if (ipNext.y == pt.y) {
        if ((ipNext.x == pt.x) || (ip.y == pt.y && ((ipNext.x > pt.x) == (ip.x < pt.x)))) return -1;
      }
      if ((ip.y < pt.y) != (ipNext.y < pt.y)) {
        if (ip.x >= pt.x) {
          if (ipNext.x > pt.x) result = 1 - result;
          else {
            var dx:Float = /*(double)*/(ip.x - pt.x);
            var dy:Float = /*(double)*/(ip.y - pt.y);
            var d:Float =  dx * (ipNext.y - pt.y) - (ipNext.x - pt.x) * dy;
            if (d == 0) return -1;
            else if ((d > 0) == (ipNext.y > ip.y)) result = 1 - result;
          }
        } else {
          if (ipNext.x > pt.x) {
            var dx:Float = /*(double)*/(ip.x - pt.x);
            var dy:Float = /*(double)*/(ip.y - pt.y);
            var d:Float =  dx * (ipNext.y - pt.y) - (ipNext.x - pt.x) * dy;
            if (d == 0) return -1;
            else if ((d > 0) == (ipNext.y > ip.y)) result = 1 - result;
          }
        }
      }
      ip.copyFrom(ipNext);
    }
    return result;
  }
  //------------------------------------------------------------------------------

  static function pointInOutPt(pt:IntPoint, op:OutPt):Int {
    //returns 0 if false, +1 if true, -1 if pt ON polygon boundary
    //See "The Point in Polygon Problem for Arbitrary Polygons" by Hormann & Agathos
    //http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.88.5498&rep=rep1&type=pdf
    var result:Int = 0;
    var startOp:OutPt = op;
    var ptx:CInt = pt.x, pty:CInt = pt.y;
    var poly0x:CInt = op.pt.x, poly0y:CInt = op.pt.y;
    do {
      op = op.next;
      var poly1x:CInt = op.pt.x, poly1y:CInt = op.pt.y;

      if (poly1y == pty) {
        if ((poly1x == ptx) || (poly0y == pty && ((poly1x > ptx) == (poly0x < ptx)))) return -1;
      }
      if ((poly0y < pty) != (poly1y < pty)) {
        if (poly0x >= ptx) {
          if (poly1x > ptx) result = 1 - result;
          else {
            // NOTE: casts here too
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

  static function poly2ContainsPoly1(outPt1:OutPt, outPt2:OutPt):Bool {
    var op:OutPt = outPt1;
    do {
      //nb: PointInPolygon returns 0 if false, +1 if true, -1 if pt on polygon
      // NOTE: rename two versions of PointInPolygon
      var res:Int = pointInOutPt(op.pt, outPt2);
      if (res >= 0) return res > 0;
      op = op.next;
    } while (op != outPt1);
    return true;
  }
  //----------------------------------------------------------------------

  function fixupFirstLefts1(oldOutRec:OutRec, newOutRec:OutRec):Void {
    for (i in 0...mPolyOuts.length) {
      var outRec:OutRec = mPolyOuts[i];
      var firstLeft:OutRec = parseFirstLeft(outRec.firstLeft);
      if (outRec.pts != null && firstLeft == oldOutRec) {
        if (poly2ContainsPoly1(outRec.pts, newOutRec.pts)) outRec.firstLeft = newOutRec;
      }
    }
  }
  //----------------------------------------------------------------------

  function fixupFirstLefts2(innerOutRec:OutRec, outerOutRec:OutRec):Void {
    //A polygon has split into two such that one is now the inner of the other.
    //It's possible that these polygons now wrap around other polygons, so check
    //every polygon that's also contained by OuterOutRec's FirstLeft container
    //(including nil) to see if they've become inner to the new inner polygon ...
    var orfl:OutRec = outerOutRec.firstLeft;
    for (outRec in mPolyOuts) {
      if (outRec.pts == null || outRec == outerOutRec || outRec == innerOutRec)
        continue;
      var firstLeft:OutRec = parseFirstLeft(outRec.firstLeft);
      if (firstLeft != orfl && firstLeft != innerOutRec && firstLeft != outerOutRec)
        continue;
      if (poly2ContainsPoly1(outRec.pts, innerOutRec.pts))
        outRec.firstLeft = innerOutRec;
      else if (poly2ContainsPoly1(outRec.pts, outerOutRec.pts))
        outRec.firstLeft = outerOutRec;
      else if (outRec.firstLeft == innerOutRec || outRec.firstLeft == outerOutRec)
        outRec.firstLeft = orfl;
    }
  }
  //----------------------------------------------------------------------

  function fixupFirstLefts3(oldOutRec:OutRec, newOutRec:OutRec):Void {
    //same as FixupFirstLefts1 but doesn't call Poly2ContainsPoly1()
    for (outRec in mPolyOuts) {
      var firstLeft:OutRec = parseFirstLeft(outRec.firstLeft);
      if (outRec.pts != null && firstLeft == oldOutRec)
        outRec.firstLeft = newOutRec;
    }
  }
  //----------------------------------------------------------------------

  static function parseFirstLeft(firstLeft:OutRec):OutRec {
    while (firstLeft != null && firstLeft.pts == null) firstLeft = firstLeft.firstLeft;
    return firstLeft;
  }
  //------------------------------------------------------------------------------

  function joinCommonEdges():Void {
    for (i in 0...mJoins.length) {
      var join:Join = mJoins[i];

      var outRec1:OutRec = getOutRec(join.outPt1.idx);
      var outRec2:OutRec = getOutRec(join.outPt2.idx);

      if (outRec1.pts == null || outRec2.pts == null) continue;
      if (outRec1.isOpen || outRec2.isOpen) continue;

      //get the polygon fragment with the correct hole state (FirstLeft)
      //before calling JoinPoints() ...
      var holeStateRec:OutRec;
      if (outRec1 == outRec2) holeStateRec = outRec1;
      else if (outRec1RightOfOutRec2(outRec1, outRec2)) holeStateRec = outRec2;
      else if (outRec1RightOfOutRec2(outRec2, outRec1)) holeStateRec = outRec1;
      else holeStateRec = getLowermostRec(outRec1, outRec2);

      if (!joinPoints(join, outRec1, outRec2)) continue;

      if (outRec1 == outRec2) {
        //instead of joining two polygons, we've just created a new one by
        //splitting one polygon into two.
        outRec1.pts = join.outPt1;
        outRec1.bottomPt = null;
        outRec2 = createOutRec();
        outRec2.pts = join.outPt2;

        //update all OutRec2.pts Idx's ...
        updateOutPtIdxs(outRec2);

        if (poly2ContainsPoly1(outRec2.pts, outRec1.pts)) {
          //outRec1 contains outRec2 ...
          outRec2.isHole = !outRec1.isHole;
          outRec2.firstLeft = outRec1;

          if (mUsingPolyTree) fixupFirstLefts2(outRec2, outRec1);

          if ((outRec2.isHole.xor(reverseSolution)) == (areaOfOutRec(outRec2) > 0)) reversePolyPtLinks(outRec2.pts);

        } else if (poly2ContainsPoly1(outRec1.pts, outRec2.pts)) {
          //outRec2 contains outRec1 ...
          outRec2.isHole = outRec1.isHole;
          outRec1.isHole = !outRec2.isHole;
          outRec2.firstLeft = outRec1.firstLeft;
          outRec1.firstLeft = outRec2;

          if (mUsingPolyTree) fixupFirstLefts2(outRec1, outRec2);

          if ((outRec1.isHole.xor(reverseSolution)) == (areaOfOutRec(outRec1) > 0)) reversePolyPtLinks(outRec1.pts);
        } else {
          //the 2 polygons are completely separate ...
          outRec2.isHole = outRec1.isHole;
          outRec2.firstLeft = outRec1.firstLeft;

          //fixup FirstLeft pointers that may need reassigning to OutRec2
          if (mUsingPolyTree) fixupFirstLefts1(outRec1, outRec2);
        }

      } else {
        //joined 2 polygons together ...

        outRec2.pts = null;
        outRec2.bottomPt = null;
        outRec2.idx = outRec1.idx;

        outRec1.isHole = holeStateRec.isHole;
        if (holeStateRec == outRec2) outRec1.firstLeft = outRec2.firstLeft;
        outRec2.firstLeft = outRec1;

        //fixup FirstLeft pointers that may need reassigning to OutRec1
        if (mUsingPolyTree) fixupFirstLefts3(outRec2, outRec1);
      }
    }
  }
  //------------------------------------------------------------------------------

  function updateOutPtIdxs(outrec:OutRec):Void {
    var op:OutPt = outrec.pts;
    do {
      op.idx = outrec.idx;
      op = op.prev;
    } while (op != outrec.pts);
  }
  //------------------------------------------------------------------------------

  function doSimplePolygons():Void {
    var i:Int = 0;
    while (i < mPolyOuts.length) {
      var outrec:OutRec = mPolyOuts[i++];
      var op:OutPt = outrec.pts;
      if (op == null || outrec.isOpen) continue;
      do //for each Pt in Polygon until duplicate found do ...
      {
        var op2:OutPt = op.next;
        while (op2 != outrec.pts) {
          if ((op.pt.equals(op2.pt)) && op2.next != op && op2.prev != op) {
            //split the polygon into two ...
            var op3:OutPt = op.prev;
            var op4:OutPt = op2.prev;
            op.prev = op4;
            op4.next = op;
            op2.prev = op3;
            op3.next = op2;

            outrec.pts = op;
            var outrec2:OutRec = createOutRec();
            outrec2.pts = op2;
            updateOutPtIdxs(outrec2);
            if (poly2ContainsPoly1(outrec2.pts, outrec.pts)) {
              //OutRec2 is contained by OutRec1 ...
              outrec2.isHole = !outrec.isHole;
              outrec2.firstLeft = outrec;
              if (mUsingPolyTree) fixupFirstLefts2(outrec2, outrec);
            } else if (poly2ContainsPoly1(outrec.pts, outrec2.pts)) {
              //OutRec1 is contained by OutRec2 ...
              outrec2.isHole = outrec.isHole;
              outrec.isHole = !outrec2.isHole;
              outrec2.firstLeft = outrec.firstLeft;
              outrec.firstLeft = outrec2;
              if (mUsingPolyTree) fixupFirstLefts2(outrec, outrec2);
            } else {
              //the 2 polygons are separate ...
              outrec2.isHole = outrec.isHole;
              outrec2.firstLeft = outrec.firstLeft;
              if (mUsingPolyTree) fixupFirstLefts1(outrec, outrec2);
            }
            op2 = op; //ie get ready for the next iteration
          }
          op2 = op2.next;
        }
        op = op.next;
      }
      while (op != outrec.pts);
    }
  }
  //------------------------------------------------------------------------------

  static public function area(poly:Path):Float {
    // NOTE: unneeded cast, right?
    if (poly == null || poly.length < 3) return 0;
    var cnt:Int = /*(int)*/ poly.length;
    var a:Float = 0;
    // NOTE: check loop and casts, but should be fine
    var j:Int = cnt - 1;
    for (i in 0...cnt) {
      var dx:Float = /*(double)*/ poly[j].x + poly[i].x;
      var dy:Float = /*(double)*/ poly[j].y - poly[i].y;
      a += dx * dy;
      j = i;
    }
    return -a * 0.5;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  function areaOfOutRec(outRec:OutRec):Float {
    return areaOfOutPt(outRec.pts);
  }
  //------------------------------------------------------------------------------

  function areaOfOutPt(op:OutPt):Float {
    var opFirst:OutPt = op;
    if (op == null) return 0;
    var a:Float = 0;
    do {
      // NOTE: casts
      var dx:Float = /*(double)*/(op.prev.pt.x + op.pt.x);
      var dy:Float = /*(double)*/(op.prev.pt.y - op.pt.y);
      a += dx * dy;
      op = op.next;
    } while (op != opFirst);
    return a * 0.5;
  }

  //------------------------------------------------------------------------------
  // SimplifyPolygon functions ...
  // Convert self-intersecting polygons into simple polygons
  //------------------------------------------------------------------------------

  static public function simplifyPolygon(poly:Path, fillType:PolyFillType = null):Paths {
    if (fillType == null) fillType = PolyFillType.PFT_EVEN_ODD;
    var result = new Paths();
    var c = new Clipper();
    c.strictlySimple = true;
    c.addPath(poly, PolyType.PT_SUBJECT, true);
    c.executePaths(ClipType.CT_UNION, result, fillType, fillType);
    return result;
  }
  //------------------------------------------------------------------------------

  static public function simplifyPolygons(polys:Paths, fillType:PolyFillType = null):Paths {
    if (fillType == null) fillType = PolyFillType.PFT_EVEN_ODD;
    var result = new Paths();
    var c = new Clipper();
    c.strictlySimple = true;
    c.addPaths(polys, PolyType.PT_SUBJECT, true);
    c.executePaths(ClipType.CT_UNION, result, fillType, fillType);
    return result;
  }
  //------------------------------------------------------------------------------

  static function distanceSqrd(pt1:IntPoint, pt2:IntPoint):Float {
    // NOTE: casts
    var dx:Float = (/*(double)*/ pt1.x - pt2.x);
    var dy:Float = (/*(double)*/ pt1.y - pt2.y);
    return (dx * dx + dy * dy);
  }
  //------------------------------------------------------------------------------

  static function distanceFromLineSqrd(pt:IntPoint, ln1:IntPoint, ln2:IntPoint):Float {
    //The equation of a line in general form (Ax + By + C = 0)
    //given 2 points (x¹,y¹) & (x²,y²) is ...
    //(y¹ - y²)x + (x² - x¹)y + (y² - y¹)x¹ - (x² - x¹)y¹ = 0
    //A = (y¹ - y²); B = (x² - x¹); C = (y² - y¹)x¹ - (x² - x¹)y¹
    //perpendicular distance of point (x³,y³) = (Ax³ + By³ + C)/Sqrt(A² + B²)
    //see http://en.wikipedia.org/wiki/Perpendicular_distance
    var A:Float = ln1.y - ln2.y;
    var B:Float = ln2.x - ln1.x;
    var C:Float = A * ln1.x + B * ln1.y;
    C = A * pt.x + B * pt.y - C;
    return (C * C) / (A * A + B * B);
  }
  //---------------------------------------------------------------------------

  static function slopesNearCollinear(pt1:IntPoint, pt2:IntPoint, pt3:IntPoint, distSqrd:Float):Bool {
    //this function is more accurate when the point that's GEOMETRICALLY
    //between the other 2 points is the one that's tested for distance.
    //nb: with 'spikes', either pt1 or pt3 is geometrically between the other pts
    if (Math.abs(pt1.x - pt2.x) > Math.abs(pt1.y - pt2.y)) {
      if ((pt1.x > pt2.x) == (pt1.x < pt3.x)) return distanceFromLineSqrd(pt1, pt2, pt3) < distSqrd;
      else if ((pt2.x > pt1.x) == (pt2.x < pt3.x)) return distanceFromLineSqrd(pt2, pt1, pt3) < distSqrd;
      else return distanceFromLineSqrd(pt3, pt1, pt2) < distSqrd;
    } else {
      if ((pt1.y > pt2.y) == (pt1.y < pt3.y)) return distanceFromLineSqrd(pt1, pt2, pt3) < distSqrd;
      else if ((pt2.y > pt1.y) == (pt2.y < pt3.y)) return distanceFromLineSqrd(pt2, pt1, pt3) < distSqrd;
      else return distanceFromLineSqrd(pt3, pt1, pt2) < distSqrd;
    }
  }
  //------------------------------------------------------------------------------

  static function pointsAreClose(pt1:IntPoint, pt2:IntPoint, distSqrd:Float):Bool {
    // NOTE: casts
    var dx:Float = /*(double)*/ pt1.x - pt2.x;
    var dy:Float = /*(double)*/ pt1.y - pt2.y;
    return ((dx * dx) + (dy * dy) <= distSqrd);
  }
  //------------------------------------------------------------------------------

  static function excludeOp(op:OutPt):OutPt {
    var result:OutPt = op.prev;
    result.next = op.next;
    op.next.prev = result;
    result.idx = 0;
    return result;
  }
  //------------------------------------------------------------------------------

  static function cleanPolygon(path:Path, distance:Float = 1.415):Path {
    //distance = proximity in units/pixels below which vertices will be stripped.
    //Default ~= sqrt(2) so when adjacent vertices or semi-adjacent vertices have
    //both x & y coords within 1 unit, then the second vertex will be stripped.

    var cnt:Int = path.length;

    if (cnt == 0) return new Path();

    // NOTE: check this vec
    var outPts:Array<OutPt> = [for (i in 0...cnt) new OutPt()];

    for (i in 0...cnt) {
      outPts[i].pt.copyFrom(path[i]);
      outPts[i].next = outPts[(i + 1) % cnt];
      outPts[i].next.prev = outPts[i];
      outPts[i].idx = 0;
    }

    var distSqrd:Float = distance * distance;
    var op:OutPt = outPts[0];
    while (op.idx == 0 && op.next != op.prev) {
      if (pointsAreClose(op.pt, op.prev.pt, distSqrd)) {
        op = excludeOp(op);
        cnt--;
      } else if (pointsAreClose(op.prev.pt, op.next.pt, distSqrd)) {
        excludeOp(op.next);
        op = excludeOp(op);
        cnt -= 2;
      } else if (slopesNearCollinear(op.prev.pt, op.pt, op.next.pt, distSqrd)) {
        op = excludeOp(op);
        cnt--;
      } else {
        op.idx = 1;
        op = op.next;
      }
    }

    if (cnt < 3) cnt = 0;
    var result = new Path(/*NOTE:cnt*/);
    for (i in 0...cnt) {
      result.push(op.pt);
      op = op.next;
    }
    outPts = null;
    return result;
  }
  //------------------------------------------------------------------------------

  static public function cleanPolygons(polys:Paths, distance:Float = 1.415):Paths {
    var result = new Paths(/*NOTE:polys.length*/);
    for (i in 0...polys.length)
      result.push(cleanPolygon(polys[i], distance));
    return result;
  }
  //------------------------------------------------------------------------------

  /*internal*/ static function minkowski(pattern:Path, path:Path, isSum:Bool, isClosed:Bool):Paths {
    var delta:Int = (isClosed ? 1 : 0);
    var polyCnt:Int = pattern.length;
    var pathCnt:Int = path.length;
    var result = new Paths(/*NOTE:pathCnt*/);
    if (isSum) for (i in 0...pathCnt) {
      var p = new Path(/*NOTE:polyCnt*/);
      for (ip in pattern)
        p.push(new IntPoint(path[i].x + ip.x, path[i].y + ip.y));
      result.push(p);
    } else for (i in 0...pathCnt) {
      var p = new Path(/*NOTE:polyCnt*/);
      for (ip in pattern)
        p.push(new IntPoint(path[i].x - ip.x, path[i].y - ip.y));
      result.push(p);
    }

    var quads:Paths = new Paths(/*NOTE:(pathCnt + delta) * (polyCnt + 1)*/);
    for (i in 0...pathCnt - 1 + delta) {
      for (j in 0...polyCnt) {
        var quad = new Path(/*NOTE:4*/);
        quad.push(result[i % pathCnt][j % polyCnt]);
        quad.push(result[(i + 1) % pathCnt][j % polyCnt]);
        quad.push(result[(i + 1) % pathCnt][(j + 1) % polyCnt]);
        quad.push(result[i % pathCnt][(j + 1) % polyCnt]);
        if (!orientation(quad)) quad.reverse();
        quads.push(quad);
      }
    }
    return quads;
  }
  //------------------------------------------------------------------------------

  static public function minkowskiSum(pattern:Path, path:Path, pathIsClosed:Bool):Paths {
    var paths:Paths = minkowski(pattern, path, true, pathIsClosed);
    var c = new Clipper();
    c.addPaths(paths, PolyType.PT_SUBJECT, true);
    c.executePaths(ClipType.CT_UNION, paths, PolyFillType.PFT_NON_ZERO, PolyFillType.PFT_NON_ZERO);
    return paths;
  }
  //------------------------------------------------------------------------------

  static function translatePath(path:Path, delta:IntPoint):Path {
    var outPath = new Path(/*NOTE:path.length*/);
    for (i in 0...path.length)
      outPath.push(new IntPoint(path[i].x + delta.x, path[i].y + delta.y));
    return outPath;
  }
  //------------------------------------------------------------------------------

  static public function minkowskiSumPaths(pattern:Path, paths:Paths, pathIsClosed:Bool):Paths {
    var solution = new Paths();
    var c = new Clipper();
    for (i in 0...paths.length) {
      var tmp:Paths = minkowski(pattern, paths[i], true, pathIsClosed);
      c.addPaths(tmp, PolyType.PT_SUBJECT, true);
      if (pathIsClosed) {
        var path:Path = translatePath(paths[i], pattern[0]);
        c.addPath(path, PolyType.PT_CLIP, true);
      }
    }
    c.executePaths(ClipType.CT_UNION, solution, PolyFillType.PFT_NON_ZERO, PolyFillType.PFT_NON_ZERO);
    return solution;
  }
  //------------------------------------------------------------------------------

  static public function minkowskiDiff(poly1:Path, poly2:Path):Paths {
    var paths:Paths = minkowski(poly1, poly2, false, true);
    var c = new Clipper();
    c.addPaths(paths, PolyType.PT_SUBJECT, true);
    c.executePaths(ClipType.CT_UNION, paths, PolyFillType.PFT_NON_ZERO, PolyFillType.PFT_NON_ZERO);
    return paths;
  }
  //------------------------------------------------------------------------------

  static public function polyTreeToPaths(polytree:PolyTree):Paths {

    var result = new Paths();
    //NOTE:result.Capacity = polytree.Total;
    addPolyNodeToPaths(polytree, NodeType.NT_ANY, result);
    return result;
  }
  //------------------------------------------------------------------------------

  /*internal*/ static function addPolyNodeToPaths(polynode:PolyNode, nt:NodeType, paths:Paths):Void {
    var match = true;
    switch (nt) {
      case NodeType.NT_OPEN:
        return;
      case NodeType.NT_CLOSED:
        match = !polynode.isOpen;
      default:
    }

    if (polynode.mPolygon.length > 0 && match) paths.push(polynode.mPolygon);
    for (pn in polynode.children)
      addPolyNodeToPaths(pn, nt, paths);
  }
  //------------------------------------------------------------------------------

  static public function openPathsFromPolyTree(polytree:PolyTree):Paths {
    var result = new Paths();
    //NOTE:result.Capacity = polytree.ChildCount;
    for (i in 0...polytree.numChildren)
      if (polytree.children[i].isOpen) result.push(polytree.children[i].mPolygon);
    return result;
  }
  //------------------------------------------------------------------------------

  static public function closedPathsFromPolyTree(polytree:PolyTree):Paths {
    var result = new Paths();
    //NOTE:result.Capacity = polytree.Total;
    addPolyNodeToPaths(polytree, NodeType.NT_CLOSED, result);
    return result;
  }
  //------------------------------------------------------------------------------

} //end Clipper

@:expose()
@:native("ClipperOffset")
class ClipperOffset
{
  var mDestPolys:Paths;
  var mSrcPoly:Path;
  var mDestPoly:Path;
  var mNormals:Array<DoublePoint> = new Array<DoublePoint>();
  var mDelta:Float;
  var mSinA:Float;
  var mSin:Float;
  var mCos:Float;
  var mMiterLim:Float;
  var mStepsPerRad:Float;

  var mLowest:IntPoint = new IntPoint();
  var mPolyNodes:PolyNode = new PolyNode();

  // NOTE: prop?
  public var arcTolerance(default, default):Float;

  // NOTE: prop?
  public var miterLimit(default, default):Float;

  // NOTE: uppercase (ISSUES: multi var (comma separated) on same line, inline var without type, Bool xor missing)
  inline static var TWO_PI:Float = 6.283185307179586476925286766559; // NOTE: Math.PI * 2;
  inline static var DEFAULT_ARC_TOLERANCE:Float = 0.25;

  public function new(miterLimit:Float = 2.0, arcTolerance:Float = DEFAULT_ARC_TOLERANCE) {
    this.miterLimit = miterLimit;
    this.arcTolerance = arcTolerance;
    mLowest.x = -1;
  }
  //------------------------------------------------------------------------------

  public function clear():Void {
    mPolyNodes.children.clear();
    mLowest.x = -1;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ static function round(value:Float):CInt {
    // NOTE: check how to cast (this is already defined in Clipper)
    //return value < 0 ? /*(cInt)*/Std.int(value - 0.5) : /*(cInt)*/Std.int(value + 0.5);
    return Clipper.round(value);
  }
  //------------------------------------------------------------------------------

  public function addPath(path:Path, joinType:JoinType, endType:EndType):Void {
    var highI:Int = path.length - 1;
    if (highI < 0) return;
    var newNode = new PolyNode();
    newNode.mJoinType = joinType;
    newNode.mEndtype = endType;

    //strip duplicate points from path and also get index to the lowest point ...
    if (endType == EndType.ET_CLOSED_LINE || endType == EndType.ET_CLOSED_POLYGON) {
      while (highI > 0 && path[0].equals(path[highI])) highI--;
    }
    //NOTE:newNode.mPolygon.Capacity = highI + 1;
    newNode.mPolygon.push(path[0]);
    var j:Int = 0, k:Int = 0;
    // NOTE: check loop
    for (i in 1...highI + 1) {
      if (!newNode.mPolygon[j].equals(path[i])) {
        j++;
        newNode.mPolygon.push(path[i]);
        if (path[i].y > newNode.mPolygon[k].y
          || (path[i].y == newNode.mPolygon[k].y && path[i].x < newNode.mPolygon[k].x))
        {
          k = j;
        }
      }
    }
    if (endType == EndType.ET_CLOSED_POLYGON && j < 2) return;

    mPolyNodes.addChild(newNode);

    //if this path's lowest pt is lower than all the others then update mLowest
    if (endType != EndType.ET_CLOSED_POLYGON) return;
    if (mLowest.x < 0) mLowest = new IntPoint(mPolyNodes.numChildren - 1, k);
    else {
      // NOTE: casts
      var ip:IntPoint = mPolyNodes.children[Std.int(mLowest.x)].mPolygon[Std.int(mLowest.y)].clone();
      if (newNode.mPolygon[k].y > ip.y || (newNode.mPolygon[k].y == ip.y && newNode.mPolygon[k].x < ip.x)) {
        mLowest = new IntPoint(mPolyNodes.numChildren - 1, k);
      }
    }
  }
  //------------------------------------------------------------------------------

  public function addPaths(paths:Paths, joinType:JoinType, endType:EndType):Void {
    for (p in paths)
      addPath(p, joinType, endType);
  }
  //------------------------------------------------------------------------------

  function fixOrientations():Void {
    //fixup orientations of all closed paths if the orientation of the
    //closed path with the lowermost vertex is wrong ...
    // NOTE: cast
    if (mLowest.x >= 0 && !Clipper.orientation(mPolyNodes.children[Std.int(mLowest.x)].mPolygon)) {
      for (i in 0...mPolyNodes.numChildren) {
        var node:PolyNode = mPolyNodes.children[i];
        if (node.mEndtype == EndType.ET_CLOSED_POLYGON || (node.mEndtype == EndType.ET_CLOSED_LINE
          && Clipper.orientation(node.mPolygon)))
        {
          node.mPolygon.reverse();
        }
      }
    } else {
      for (i in 0...mPolyNodes.numChildren) {
        var node:PolyNode = mPolyNodes.children[i];
        if (node.mEndtype == EndType.ET_CLOSED_LINE && !Clipper.orientation(node.mPolygon)) node.mPolygon.reverse();
      }
    }
  }
  //------------------------------------------------------------------------------

  /*internal*/ static function getUnitNormal(pt1:IntPoint, pt2:IntPoint):DoublePoint {
    var dx:Float = (pt2.x - pt1.x);
    var dy:Float = (pt2.y - pt1.y);
    if ((dx == 0) && (dy == 0)) return new DoublePoint();

    var f:Float = 1 * 1.0 / Math.sqrt(dx * dx + dy * dy);
    dx *= f;
    dy *= f;

    return new DoublePoint(dy, -dx);
  }
  //------------------------------------------------------------------------------

  function doOffset(delta:Float):Void {
    mDestPolys = new Paths();
    mDelta = delta;

    //if Zero offset, just copy any CLOSED polygons to mP and return ...
    if (ClipperBase.nearZero(delta)) {
      //NOTE:mDestPolys.Capacity = mPolyNodes.ChildCount;
      for (i in 0...mPolyNodes.numChildren) {
        var node:PolyNode = mPolyNodes.children[i];
        if (node.mEndtype == EndType.ET_CLOSED_POLYGON) mDestPolys.push(node.mPolygon);
      }
      return;
    }

    //see offset_triginometry3.svg in the documentation folder ...
    if (miterLimit > 2) mMiterLim = 2 / (miterLimit * miterLimit);
    else mMiterLim = 0.5;

    var y:Float;
    if (arcTolerance <= 0.0) y = DEFAULT_ARC_TOLERANCE;
    else if (arcTolerance > Math.abs(delta) * DEFAULT_ARC_TOLERANCE) y = Math.abs(delta) * DEFAULT_ARC_TOLERANCE;
    else y = arcTolerance;
    //see offset_triginometry2.svg in the documentation folder ...
    var steps:Float = Math.PI / Math.acos(1 - y / Math.abs(delta));
    mSin = Math.sin(TWO_PI / steps);
    mCos = Math.cos(TWO_PI / steps);
    mStepsPerRad = steps / TWO_PI;
    if (delta < 0.0) mSin = -mSin;

    // NOTE: danger loops
    //NOTE:mDestPolys.Capacity = mPolyNodes.ChildCount * 2;
    for (i in 0...mPolyNodes.numChildren) {
      var node:PolyNode = mPolyNodes.children[i];
      mSrcPoly = node.mPolygon;

      var len:Int = mSrcPoly.length;

      if (len == 0 || (delta <= 0 && (len < 3 || node.mEndtype != EndType.ET_CLOSED_POLYGON))) continue;

      mDestPoly = new Path();

      if (len == 1) {
        if (node.mJoinType == JoinType.JT_ROUND) {
          var x:Float = 1.0, y:Float = 0.0;
          // NOTE: check loop (int vs float)
          var j:Int = 1;
          while (j <= steps) {
            mDestPoly.push(new IntPoint(round(mSrcPoly[0].x + x * delta), round(mSrcPoly[0].y + y * delta)));
            var x2:Float = x;
            x = x * mCos - mSin * y;
            y = x2 * mSin + y * mCos;
            j++;
          }
        } else {
          var x:Float = -1.0, y:Float = -1.0;
          for (j in 0...4) {
            mDestPoly.push(new IntPoint(round(mSrcPoly[0].x + x * delta), round(mSrcPoly[0].y + y * delta)));
            if (x < 0) x = 1;
            else if (y < 0) y = 1;
            else x = -1;
          }
        }
        mDestPolys.push(mDestPoly);
        continue;
      }

      //build mNormals ...
      mNormals.clear();
      //NOTE:mNormals.Capacity = len;
      for (j in 0...len - 1) {
        mNormals.push(getUnitNormal(mSrcPoly[j], mSrcPoly[j + 1]));
      }
      if (node.mEndtype == EndType.ET_CLOSED_LINE || node.mEndtype == EndType.ET_CLOSED_POLYGON) {
        mNormals.push(getUnitNormal(mSrcPoly[len - 1], mSrcPoly[0]));
      } else mNormals.push(mNormals[len - 2].clone());

      if (node.mEndtype == EndType.ET_CLOSED_POLYGON) {
        var k:Int = len - 1;
        for (j in 0...len) {
          // NOTE: ref
          k = offsetPoint(j, /*ref*/ k, node.mJoinType);
        }
        mDestPolys.push(mDestPoly);
      } else if (node.mEndtype == EndType.ET_CLOSED_LINE) {
        var k:Int = len - 1;
        for (j in 0...len) {
          // NOTE: ref
          k = offsetPoint(j, /*ref*/ k, node.mJoinType);
        }
        mDestPolys.push(mDestPoly);
        mDestPoly = new Path();
        //re-build mNormals ...
        var n:DoublePoint = mNormals[len - 1].clone();
        var nj:Int = len - 1;
        // NOTE: check here
        while (nj > 0) {
          mNormals[nj] = new DoublePoint(-mNormals[nj - 1].x, -mNormals[nj - 1].y);
          nj--;
        }
        mNormals[0] = new DoublePoint(-n.x, -n.y);
        k = 0;
        // NOTE: and here
        nj = len - 1;
        while (nj >= 0) {
          // NOTE: ref
          k = offsetPoint(nj, /*ref*/ k, node.mJoinType);
          nj--;
        }
        mDestPolys.push(mDestPoly);
      } else {
        var k:Int = 0;
        for (j in 1...len - 1) {
          // NOTE: ref
          k = offsetPoint(j, /*ref*/ k, node.mJoinType);
        }

        var pt1:IntPoint;
        if (node.mEndtype == EndType.ET_OPEN_BUTT) {
          // NOTE: casts
          var j:Int = len - 1;
          pt1 = new IntPoint(/*(cInt)*/ round(mSrcPoly[j].x + mNormals[j].x * delta), /*(cInt)*/ round(mSrcPoly[j].y + mNormals[j].y * delta));
          mDestPoly.push(pt1);
          pt1 = new IntPoint(/*(cInt)*/ round(mSrcPoly[j].x - mNormals[j].x * delta), /*(cInt)*/ round(mSrcPoly[j].y - mNormals[j].y * delta));
          mDestPoly.push(pt1);
        } else {
          var j:Int = len - 1;
          k = len - 2;
          mSinA = 0;
          mNormals[j] = new DoublePoint(-mNormals[j].x, -mNormals[j].y);
          if (node.mEndtype == EndType.ET_OPEN_SQUARE) doSquare(j, k);
          else doRound(j, k);
        }

        //re-build mNormals ...
        // NOTE: check whiles
        var nj:Int = len - 1;
        while (nj > 0) {
          mNormals[nj] = new DoublePoint(-mNormals[nj - 1].x, -mNormals[nj - 1].y);
          nj--;
        }

        mNormals[0] = new DoublePoint(-mNormals[1].x, -mNormals[1].y);

        k = len - 1;
        nj = k - 1;
        while (nj > 0) {
          // NOTE: ref
          k = offsetPoint(nj, /*ref*/ k, node.mJoinType);
          nj--;
        }

        if (node.mEndtype == EndType.ET_OPEN_BUTT) {
          // NOTE: casts
          pt1 = new IntPoint(/*(cInt)*/ round(mSrcPoly[0].x - mNormals[0].x * delta), /*(cInt)*/ round(mSrcPoly[0].y - mNormals[0].y * delta));
          mDestPoly.push(pt1);
          pt1 = new IntPoint(/*(cInt)*/ round(mSrcPoly[0].x + mNormals[0].x * delta), /*(cInt)*/ round(mSrcPoly[0].y + mNormals[0].y * delta));
          mDestPoly.push(pt1);
        } else {
          k = 1;
          mSinA = 0;
          if (node.mEndtype == EndType.ET_OPEN_SQUARE) doSquare(0, 1);
          else doRound(0, 1);
        }
        mDestPolys.push(mDestPoly);
      }
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: added to call proper version of executePaths/PolyTree
  public function execute(/*ref*/ solution:Dynamic, delta:Float):Void {
    if (Std.is(solution, Paths)) {
      return executePaths(solution, delta);
    } else if (Std.is(solution, PolyTree)) {
      return executePolyTree(solution, delta);
    }
  #if (!CLIPPER_NO_EXCEPTIONS)
    else throw new ClipperException("`solution` must be either a Paths or a PolyTree");
  #end
  }
  //------------------------------------------------------------------------------

  // NOTE: ref
  public function executePaths(/*ref*/ solution:Paths, delta:Float):Void {
    solution.clear();
    fixOrientations();
    doOffset(delta);
    //now clean up 'corners' ...
    var clpr = new Clipper();
    clpr.addPaths(mDestPolys, PolyType.PT_SUBJECT, true);
    if (delta > 0) {
      clpr.executePaths(ClipType.CT_UNION, solution,
      PolyFillType.PFT_POSITIVE, PolyFillType.PFT_POSITIVE);
    } else {
      var r:IntRect = ClipperBase.getBounds(mDestPolys);
      var outer = new Path(/*NOTE:4*/);

      outer.push(new IntPoint(r.left - 10, r.bottom + 10));
      outer.push(new IntPoint(r.right + 10, r.bottom + 10));
      outer.push(new IntPoint(r.right + 10, r.top - 10));
      outer.push(new IntPoint(r.left - 10, r.top - 10));

      clpr.addPath(outer, PolyType.PT_SUBJECT, true);
      clpr.reverseSolution = true;
      clpr.executePaths(ClipType.CT_UNION, solution, PolyFillType.PFT_NEGATIVE, PolyFillType.PFT_NEGATIVE);
      if (solution.length > 0) solution.shift(); //NOTE: RemoveAt(0);
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: ref
  public function executePolyTree(/*ref*/ solution:PolyTree, delta:Float):Void {
    solution.clear();
    fixOrientations();
    doOffset(delta);

    //now clean up 'corners' ...
    var clpr = new Clipper();
    clpr.addPaths(mDestPolys, PolyType.PT_SUBJECT, true);
    if (delta > 0) {
      clpr.executePolyTree(ClipType.CT_UNION, solution, PolyFillType.PFT_POSITIVE, PolyFillType.PFT_POSITIVE);
    } else {
      var r:IntRect = ClipperBase.getBounds(mDestPolys);
      var outer = new Path(/*NOTE:4*/);

      outer.push(new IntPoint(r.left - 10, r.bottom + 10));
      outer.push(new IntPoint(r.right + 10, r.bottom + 10));
      outer.push(new IntPoint(r.right + 10, r.top - 10));
      outer.push(new IntPoint(r.left - 10, r.top - 10));

      clpr.addPath(outer, PolyType.PT_SUBJECT, true);
      clpr.reverseSolution = true;
      clpr.executePolyTree(ClipType.CT_UNION, solution, PolyFillType.PFT_NEGATIVE, PolyFillType.PFT_NEGATIVE);
      //remove the outer PolyNode rectangle ...
      if (solution.numChildren == 1 && solution.children[0].numChildren > 0) {
        var outerNode:PolyNode = solution.children[0];
        //NOTE:solution.Childs.Capacity = outerNode.ChildCount;
        solution.children[0] = outerNode.children[0];
        solution.children[0].mParent = solution;
        for (i in 1...outerNode.numChildren)
          solution.addChild(outerNode.children[i]);
      } else solution.clear();
    }
  }
  //------------------------------------------------------------------------------

  // NOTE: ref (updated to return the modified k)
  function offsetPoint(j:Int, /*ref*/ k:Int, joinType:JoinType):Int {
    //cross product ...
    mSinA = (mNormals[k].x * mNormals[j].y - mNormals[j].x * mNormals[k].y);

    if (Math.abs(mSinA * mDelta) < 1.0) {
      //dot product ...
      var cosA:Float = (mNormals[k].x * mNormals[j].x + mNormals[j].y * mNormals[k].y);
      if (cosA > 0) // angle ==> 0 degrees
      {
        mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + mNormals[k].x * mDelta), round(mSrcPoly[j].y + mNormals[k].y * mDelta)));
        return k;
      }
      //else angle ==> 180 degrees
    } else if (mSinA > 1.0) mSinA = 1.0;
    else if (mSinA < -1.0) mSinA = -1.0;

    if (mSinA * mDelta < 0) {
      mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + mNormals[k].x * mDelta), round(mSrcPoly[j].y + mNormals[k].y * mDelta)));
      mDestPoly.push(mSrcPoly[j]);
      mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + mNormals[j].x * mDelta), round(mSrcPoly[j].y + mNormals[j].y * mDelta)));
    } else switch (joinType) {
      case JoinType.JT_MITER:
        {
          var r:Float = 1 + (mNormals[j].x * mNormals[k].x + mNormals[j].y * mNormals[k].y);
          if (r >= mMiterLim) doMiter(j, k, r);
          else doSquare(j, k);
        }
      case JoinType.JT_SQUARE:
        doSquare(j, k);
      case JoinType.JT_ROUND:
        doRound(j, k);
    }
    k = j;
    return k;
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ function doSquare(j:Int, k:Int):Void {
    var dx:Float = Math.tan(Math.atan2(mSinA, mNormals[k].x * mNormals[j].x + mNormals[k].y * mNormals[j].y) / 4);
    mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + mDelta * (mNormals[k].x - mNormals[k].y * dx)), round(mSrcPoly[j].y + mDelta * (mNormals[k].y + mNormals[k].x * dx))));
    mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + mDelta * (mNormals[j].x + mNormals[j].y * dx)), round(mSrcPoly[j].y + mDelta * (mNormals[j].y - mNormals[j].x * dx))));
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ function doMiter(j:Int, k:Int, r:Float):Void {
    var q:Float = mDelta / r;
    mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + (mNormals[k].x + mNormals[j].x) * q), round(mSrcPoly[j].y + (mNormals[k].y + mNormals[j].y) * q)));
  }
  //------------------------------------------------------------------------------

  #if (CLIPPER_INLINE) inline #end
  /*internal*/ function doRound(j:Int, k:Int):Void {
    var a:Float = Math.atan2(mSinA, mNormals[k].x * mNormals[j].x + mNormals[k].y * mNormals[j].y);
    // NOTE: cast
    var steps:Int = Std.int(Math.max(Std.int(round(mStepsPerRad * Math.abs(a))), 1));

    var x:Float = mNormals[k].x, y = mNormals[k].y, x2;
    for (i in 0...steps) {
      mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + x * mDelta), round(mSrcPoly[j].y + y * mDelta)));
      x2 = x;
      x = x * mCos - mSin * y;
      y = x2 * mSin + y * mCos;
    }
    mDestPoly.push(new IntPoint(round(mSrcPoly[j].x + mNormals[j].x * mDelta), round(mSrcPoly[j].y + mNormals[j].y * mDelta)));
  }
  //------------------------------------------------------------------------------
}

@:expose()
@:native("ClipperException")
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

@:expose()
@:native("InternalTools")
class InternalTools
{
  /** Empties an array of its contents. */
  static inline public function clear<T>(array:Array<T>)
  {
#if (cs || cpp || php || python ||eval )
    array.splice(0, array.length);
#else
    untyped array.length = 0;
#end
  }

  static inline public function xor(a:Bool, b:Bool):Bool
  {
    return (a && !b) || (b && !a);
  }
}
//------------------------------------------------------------------------------

abstract Ref<T>(haxe.ds.Vector<T>) {
  public var value(get, set):T;

  inline function new() this = new haxe.ds.Vector(1);

  @:to inline function get_value():T return this[0];
  inline function set_value(param:T) return this[0] = param;

  #if (python) @:native("__repr__") #end
  public function toString():String return '@[' + Std.string(value)+']';

  @:noUsing @:from static inline public function to<A>(v:A):Ref<A> {
    var ret = new Ref();
    ret.value = v;
    return ret;
  }
}
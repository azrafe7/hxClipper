package;

import haxe.io.Bytes;
import haxe.Resource;
import hxClipper.Clipper;
import hxClipper.Clipper.ClipType;
import hxClipper.Clipper.IntPoint;
import js.Browser;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasWindingRule;
import sui.*;
import sui.controls.*;
import thx.Timer;

using hxClipper.Clipper.InternalTools;

#if USE_INT64
import com.fundoware.engine.bigint.FunMutableBigInt as BigInt;
using com.fundoware.engine.bigint.FunBigIntTools;
#end

typedef Polygon = Array<IntPoint>;

typedef Polygons = Array<Polygon>;


@:access(sui)
class SuiDemoJS {

	static var width:Int = 800;
	static var height:Int = 500;
	
	var australia:Polygons;
	
	var scale:Float = 1000;
	
	var clipType:ClipType;
	var fillType:PolyFillType;
	var joinType:JoinType;
	
	var countLabel:LabelControl;
	var nudCount:Int = 50;
	var offset:Float = 0;
	
	var subjects:Polygons = [];
	var clips:Polygons = [];
	var solution:Polygons = [];
	
	var showSubjects:Bool = true;
	var showClips:Bool = true;
	var showSolution:Bool = true;
	
	var generatingCircles:Bool = false;
	var randomPolys:Polygons = [];
	var randomCircles:Polygons = [];
	
	var subjAreaControl:FloatControl;
	var clipAreaControl:FloatControl;
	var intersectAreaControl:FloatControl;
	var sciAreaControl:FloatControl;
	var unionAreaControl:FloatControl;
	
	var ctx:CanvasRenderingContext2D;
	
	
	public static function main(): Void {
		new SuiDemoJS();
	}

	public function new()
	{
		Tests.run();
		
		australia = getPolysFromBytes(Resource.getBytes("australia"), scale);

		clipType = CT_INTERSECTION;
		fillType = PFT_NON_ZERO;
		joinType = JT_ROUND;
		
		var canvas = createCanvas(width, height, 10, 10);
		ctx = canvas.getContext2d();
		
		genRandomPolygons();
		createUI();
		
		update();
	}
	
	function createUI():Void
	{
		var debouncedUpdate:Void->Void;
		debouncedUpdate = Timer.debounce(update, 50);
		
		var sui = new Sui();
		var ui = sui.folder("hxClipper - SuiDemo");
		
		var uiFolder = ui.folder("Options");
		uiFolder.text("Bool Op", "CT_INTERSECTION", {
			list: [
				{ label: "intersect", value: "CT_INTERSECTION" },
				{ label: "union", value: "CT_UNION" },
				{ label: "difference", value: "CT_DIFFERENCE" },
				{ label: "xor", value: "CT_XOR" },
		], listonly: true }, function (v):Void {
			clipType = Type.createEnum(ClipType, v);
			update();
		});
		uiFolder.text("Fill Rule", "PFT_NON_ZERO", {
			list: [
				{ label: "evenodd", value: "PFT_EVEN_ODD" },
				{ label: "nonzero", value: "PFT_NON_ZERO" },
		], listonly: true}, function (v):Void {
			fillType = Type.createEnum(PolyFillType, v);
			update();
		});
		
		countLabel = new sui.controls.LabelControl("Vertex Count");
		var countControl = Sui.createInt(nudCount, {
			min: 3,
			max: 100
		});
		uiFolder.grid.add(HorizontalPair(countLabel, countControl));
		uiFolder.float("Offset", offset, {
			step: 1,
			min: -20,
			max: 20
		}, function (v):Void {
			offset = v;
			debouncedUpdate();
		});
		uiFolder.text("Join Type", "JT_ROUND", {
			list: [
				{ label: "miter", value: "JT_MITER" },
				{ label: "square", value: "JT_SQUARE" },
				{ label: "round", value: "JT_ROUND" },
		], listonly: true}, function (v):Void {
			joinType = Type.createEnum(JoinType, v);
			update();
		});
		
		uiFolder = ui.folder("Generate Samples");
		uiFolder.trigger("random polys", function ():Void {
			generatingCircles = false;
			countLabel.set("Vertex Count");
			genRandomPolygons();
			setRandomPolygons();
			update();
		});
		uiFolder.trigger("australia + circles", function ():Void {
			generatingCircles = true;
			countLabel.set("Circle Count");
			subjects.clear();
			subjects = australia.concat([]);
			genRandomCircles();
			setRandomCircles();
			update();
		});
		
		uiFolder = ui.folder("Visibility");
		uiFolder.bool("Show Subjects", showSubjects, function (v):Void {
			showSubjects = v;
			update();
		});
		uiFolder.bool("Show Clips", showClips, function (v):Void {
			showClips = v;
			update();
		});
		uiFolder.bool("Show Solution", showSolution, function (v):Void {
			showSolution = v;
			update();
		});

		uiFolder = ui.folder("Area Info");
		subjAreaControl = cast uiFolder.float("Subjects (s)", 0, { disabled: true }, function (v):Void {});
		clipAreaControl = cast uiFolder.float("Clips (c)", 0, { disabled: true }, function (v):Void {});
		intersectAreaControl = cast uiFolder.float("Intersection (i)", 0, { disabled: true }, function (v):Void {});
		sciAreaControl = cast uiFolder.float("(s) + (c) - (i)", 0, { disabled: true }, function (v):Void {});
		unionAreaControl = cast uiFolder.float("Union", 0, { disabled: true }, function (v):Void {});
		
		// moved here so it can access areaControls
		countControl.streams.value.subscribe(function (v):Void {
			nudCount = v;
			if (generatingCircles) setRandomCircles();
			else setRandomPolygons();
			debouncedUpdate();
		});
		
		sui.attach();
	}
	
	function update():Void
	{
		ctx.clearRect(0, 0, width, height);
		
		// draw subjects and clips
		var fillRule = (fillType == PFT_EVEN_ODD ? CanvasWindingRule.EVENODD : CanvasWindingRule.NONZERO);
		
		if (showSubjects) drawPolys(subjects, "#C3C9CF", "#DDDDF0", .75, .5, .6, fillRule);
		if (showClips) drawPolys(clips, "#F9BEA6", "#FFE0E0", .75, .5, .6, fillRule);
		
		// do the clipping ...
		if ((clips.length > 0 || subjects.length > 0))
		{
			var c = new Clipper();
			c.addPaths(subjects, PolyType.PT_SUBJECT, true);
			c.addPaths(clips, PolyType.PT_CLIP, true);
			solution.clear();
			var success = c.executePaths(clipType, solution, fillType, fillType);
			
			if (success) {
				
				var solution2:Polygons = new Polygons();
				
				if (offset != 0) {
					var co = new ClipperOffset();
					co.addPaths(solution, joinType, EndType.ET_CLOSED_POLYGON);
					co.executePaths(solution2, offset * scale);
				} else {
					solution2 = solution2.concat(solution);
				}
				
				// it really shouldn't matter what FillMode is used for solution
				// polygons because none of the solution polygons overlap. 
				// However, NONZERO will show any orientation errors where 
                // holes will be stroked (outlined) correctly but filled incorrectly  ...
				if (showSolution) drawPolys(solution2, "#003300", "#66EF7F", 1, .5, .75, CanvasWindingRule.NONZERO);
				
				calcAreas();
			}
		}
	}
	
	function calcAreas():Void
	{
		var subjArea:Float = 0;
		var clipArea:Float = 0;
		var intersectArea:Float = 0;
		var sciArea:Float = 0;
		var unionArea:Float = 0;
		
		var solution:Polygons = new Polygons();
		
		var c = new Clipper();
		c.addPaths(subjects, PT_SUBJECT, true);
		c.executePaths(CT_UNION, solution, fillType, fillType);
		for (poly in solution) {
			subjArea += Clipper.area(poly);
		}
		
		c.clear();
		c.addPaths(clips, PT_CLIP, true);
		c.executePaths(CT_UNION, solution, fillType, fillType);
		for (poly in solution) {
			clipArea += Clipper.area(poly);
		}
		
		c.addPaths(subjects, PT_SUBJECT, true);
		c.executePaths(CT_INTERSECTION, solution, fillType, fillType);
		for (poly in solution) {
			intersectArea += Clipper.area(poly);
		}
		
		c.executePaths(CT_UNION, solution, fillType, fillType);
		for (poly in solution) {
			unionArea += Clipper.area(poly);
		}

		sciArea = subjArea + clipArea - intersectArea;
		
		subjAreaControl.set(Math.round(subjArea / 100000));
		clipAreaControl.set(Math.round(clipArea / 100000));
		intersectAreaControl.set(Math.round(intersectArea / 100000));
		sciAreaControl.set(Math.round(sciArea / 100000));
		unionAreaControl.set(Math.round(unionArea / 100000));
	}
	
	function setRandomPolygons():Void
	{
		subjects.clear();
		subjects[0] = randomPolys[0].slice(0, nudCount);
		clips.clear();
		clips[0] = randomPolys[1].slice(0, nudCount);
	}
	
	function setRandomCircles():Void
	{
		clips.clear();
		clips = randomCircles.slice(0, nudCount);
	}
	
	function drawPoly(poly:Polygon):Void
	{
		var p0 = poly[0];
		ctx.moveTo((p0.x.toFloat() / scale), (p0.y.toFloat() / scale));
		for (i in 1...poly.length) {
			var p = poly[i];
			
			ctx.lineTo((p.x.toFloat() / scale), (p.y.toFloat() / scale));
		}
		ctx.lineTo((p0.x.toFloat() / scale), (p0.y.toFloat() / scale));	// close path
	}
	
	function drawPolys(polys:Polygons, strokeColor:String, fillColor:String, strokeAlpha:Float = 1, fillAlpha:Float = 1, lineWidth:Float = 1, fillRule:CanvasWindingRule = null):Void
	{
		if (fillRule == null) fillRule = CanvasWindingRule.NONZERO;
		ctx.save();
		ctx.globalAlpha = fillAlpha;
		ctx.fillStyle = fillColor;
		ctx.beginPath();
		for (poly in polys) {
			drawPoly(poly);
		}
		ctx.closePath();
		ctx.fill(fillRule);
		ctx.restore();
		ctx.globalAlpha = strokeAlpha;
		ctx.strokeStyle = strokeColor;
		ctx.lineWidth = lineWidth;
		ctx.stroke();
	}
	
	function createCanvas(w:Int, h:Int, offsetX:Int = 0, offsetY:Int = 0) 
	{
		var canvas = Browser.document.createCanvasElement();
		canvas.width = w;
		canvas.height = h;
		if (offsetX != 0 && offsetY != 0) {
			canvas.style.position = "relative";
			canvas.style.left = '${offsetX}px';
			canvas.style.top = '${offsetY}px';
		}
		Browser.document.body.appendChild(canvas);
		
		return canvas;
	}
	
	function genRandomPoint(l:Int, t:Int, r:Int, b:Int):IntPoint 
	{
	    var Q:Int = 10;
		return new IntPoint(
			Std.int((Math.random() * (r / Q) * Q + l + 10) * scale),
			Std.int((Math.random() * (b / Q) * Q + t + 10) * scale)
		);
	}
	
	function genRandomCircles():Void
	{
		var count = 100;
		randomCircles.clear();
		
		var max_radius = 50, margin = 10;
		
		for (i in 0...count)
		{
			var circle = [];
			
			var w = width - max_radius * 2 - margin * 2;
			var h = height - max_radius * 2 - margin * 2;

			var radius = Math.random() * (max_radius - margin) + margin;
			var x = Math.random() * w + radius + margin;
			var y = Math.random() * h + radius + margin;
			
			var steps = Std.int(radius * 2);
			var theta = 2 * Math.PI / steps;
			for (s in 0...steps) 
			{
				circle.push(new IntPoint(
					Std.int(scale * (x + radius * Math.cos(theta * s))),
					Std.int(scale * (y + radius * Math.sin(theta * s)))
				));
			}
			randomCircles.push(circle);
		}
	}
	
	function genRandomPolygons():Void
	{
		var count = 100;
		var Q:Int = 10;
		var l = 10;
		var t = 10;
		var r = Std.int((width - 20) / Q * Q);
		var b = Std.int((height - 20) / Q * Q);

		randomPolys = [[], []];
		for (i in 0...count) {
			randomPolys[0].push(genRandomPoint(l, t, r, b));
			randomPolys[1].push(genRandomPoint(l, t, r, b));
		}
	}

	function getPolysFromBytes(bytes:Bytes, scale:Float = 1):Polygons
	{
		var res = [];
		var pos = 0;
		var polyCnt = bytes.getInt32(pos);
		for (i in 0...polyCnt)
		{
			pos += 4;
			var vertCnt = bytes.getInt32(pos);
			var pg = [];
			for (j in 0...vertCnt)
			{
				pos += 4;
				var x = bytes.getFloat(pos) * scale;
				pos += 4;
				var y = bytes.getFloat(pos) * scale;
				pg.push(new IntPoint(Std.int(x), Std.int(y)));
			}
			res.push(pg);
		}
		return res;
	}
}
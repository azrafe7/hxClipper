(function (console) { "use strict";
var $estr = function() { return js_Boot.__string_rec(this,''); };
function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var EReg = function(r,opt) {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
};
EReg.__name__ = ["EReg"];
EReg.prototype = {
	r: null
	,match: function(s) {
		if(this.r.global) this.r.lastIndex = 0;
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
	,matched: function(n) {
		if(this.r.m != null && n >= 0 && n < this.r.m.length) return this.r.m[n]; else throw new js__$Boot_HaxeError("EReg::matched");
	}
	,matchedPos: function() {
		if(this.r.m == null) throw new js__$Boot_HaxeError("No string matched");
		return { pos : this.r.m.index, len : this.r.m[0].length};
	}
	,matchSub: function(s,pos,len) {
		if(len == null) len = -1;
		if(this.r.global) {
			this.r.lastIndex = pos;
			this.r.m = this.r.exec(len < 0?s:HxOverrides.substr(s,0,pos + len));
			var b = this.r.m != null;
			if(b) this.r.s = s;
			return b;
		} else {
			var b1 = this.match(len < 0?HxOverrides.substr(s,pos,null):HxOverrides.substr(s,pos,len));
			if(b1) {
				this.r.s = s;
				this.r.m.index += pos;
			}
			return b1;
		}
	}
	,split: function(s) {
		var d = "#__delim__#";
		return s.replace(this.r,d).split(d);
	}
	,replace: function(s,by) {
		return s.replace(this.r,by);
	}
	,map: function(s,f) {
		var offset = 0;
		var buf = new StringBuf();
		do {
			if(offset >= s.length) break; else if(!this.matchSub(s,offset)) {
				buf.add(HxOverrides.substr(s,offset,null));
				break;
			}
			var p = this.matchedPos();
			buf.add(HxOverrides.substr(s,offset,p.pos - offset));
			buf.add(f(this));
			if(p.len == 0) {
				buf.add(HxOverrides.substr(s,p.pos,1));
				offset = p.pos + 1;
			} else offset = p.pos + p.len;
		} while(this.r.global);
		if(!this.r.global && offset > 0 && offset < s.length) buf.add(HxOverrides.substr(s,offset,null));
		return buf.b;
	}
	,__class__: EReg
};
var HxOverrides = function() { };
HxOverrides.__name__ = ["HxOverrides"];
HxOverrides.dateStr = function(date) {
	var m = date.getMonth() + 1;
	var d = date.getDate();
	var h = date.getHours();
	var mi = date.getMinutes();
	var s = date.getSeconds();
	return date.getFullYear() + "-" + (m < 10?"0" + m:"" + m) + "-" + (d < 10?"0" + d:"" + d) + " " + (h < 10?"0" + h:"" + h) + ":" + (mi < 10?"0" + mi:"" + mi) + ":" + (s < 10?"0" + s:"" + s);
};
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
};
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
};
HxOverrides.indexOf = function(a,obj,i) {
	var len = a.length;
	if(i < 0) {
		i += len;
		if(i < 0) i = 0;
	}
	while(i < len) {
		if(a[i] === obj) return i;
		i++;
	}
	return -1;
};
HxOverrides.remove = function(a,obj) {
	var i = HxOverrides.indexOf(a,obj,0);
	if(i == -1) return false;
	a.splice(i,1);
	return true;
};
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
};
var Lambda = function() { };
Lambda.__name__ = ["Lambda"];
Lambda.has = function(it,elt) {
	var $it0 = $iterator(it)();
	while( $it0.hasNext() ) {
		var x = $it0.next();
		if(x == elt) return true;
	}
	return false;
};
Math.__name__ = ["Math"];
var Reflect = function() { };
Reflect.__name__ = ["Reflect"];
Reflect.hasField = function(o,field) {
	return Object.prototype.hasOwnProperty.call(o,field);
};
Reflect.field = function(o,field) {
	try {
		return o[field];
	} catch( e ) {
		haxe_CallStack.lastException = e;
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		return null;
	}
};
Reflect.callMethod = function(o,func,args) {
	return func.apply(o,args);
};
Reflect.fields = function(o) {
	var a = [];
	if(o != null) {
		var hasOwnProperty = Object.prototype.hasOwnProperty;
		for( var f in o ) {
		if(f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o,f)) a.push(f);
		}
	}
	return a;
};
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && !(f.__name__ || f.__ename__);
};
Reflect.isObject = function(v) {
	if(v == null) return false;
	var t = typeof(v);
	return t == "string" || t == "object" && v.__enum__ == null || t == "function" && (v.__name__ || v.__ename__) != null;
};
var Std = function() { };
Std.__name__ = ["Std"];
Std.string = function(s) {
	return js_Boot.__string_rec(s,"");
};
Std["int"] = function(x) {
	return x | 0;
};
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
};
Std.random = function(x) {
	if(x <= 0) return 0; else return Math.floor(Math.random() * x);
};
var StringBuf = function() {
	this.b = "";
};
StringBuf.__name__ = ["StringBuf"];
StringBuf.prototype = {
	b: null
	,add: function(x) {
		this.b += Std.string(x);
	}
	,__class__: StringBuf
};
var StringTools = function() { };
StringTools.__name__ = ["StringTools"];
StringTools.htmlEscape = function(s,quotes) {
	s = s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
	if(quotes) return s.split("\"").join("&quot;").split("'").join("&#039;"); else return s;
};
StringTools.startsWith = function(s,start) {
	return s.length >= start.length && HxOverrides.substr(s,0,start.length) == start;
};
StringTools.endsWith = function(s,end) {
	var elen = end.length;
	var slen = s.length;
	return slen >= elen && HxOverrides.substr(s,slen - elen,elen) == end;
};
StringTools.isSpace = function(s,pos) {
	var c = HxOverrides.cca(s,pos);
	return c > 8 && c < 14 || c == 32;
};
StringTools.ltrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,r)) r++;
	if(r > 0) return HxOverrides.substr(s,r,l - r); else return s;
};
StringTools.rtrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,l - r - 1)) r++;
	if(r > 0) return HxOverrides.substr(s,0,l - r); else return s;
};
StringTools.trim = function(s) {
	return StringTools.ltrim(StringTools.rtrim(s));
};
StringTools.lpad = function(s,c,l) {
	if(c.length <= 0) return s;
	while(s.length < l) s = c + s;
	return s;
};
StringTools.replace = function(s,sub,by) {
	return s.split(sub).join(by);
};
StringTools.fastCodeAt = function(s,index) {
	return s.charCodeAt(index);
};
var SuiDemoJS = function() {
	this.generatingCircles = false;
	this.showSolution = true;
	this.showClips = true;
	this.showSubjects = true;
	this.solution = [];
	this.clips = [];
	this.subjects = [];
	this.offset = 0;
	this.nudCount = 50;
	this.scale = 10;
	this.australia = this.getPolysFromBytes(haxe_Resource.getBytes("australia"),this.scale);
	this.clipType = hxClipper_ClipType.CT_INTERSECTION;
	this.fillType = hxClipper_PolyFillType.PFT_NON_ZERO;
	this.joinType = hxClipper_JoinType.JT_ROUND;
	var canvas = this.createCanvas(SuiDemoJS.width,SuiDemoJS.height,10,10);
	this.ctx = canvas.getContext("2d",null);
	this.createUI();
	this.subjects.length = 0;
	this.genRandomPolygons(this.nudCount);
	this.update();
};
SuiDemoJS.__name__ = ["SuiDemoJS"];
SuiDemoJS.main = function() {
	new SuiDemoJS();
};
SuiDemoJS.prototype = {
	australia: null
	,scale: null
	,clipType: null
	,fillType: null
	,joinType: null
	,countLabel: null
	,nudCount: null
	,offset: null
	,subjects: null
	,clips: null
	,solution: null
	,showSubjects: null
	,showClips: null
	,showSolution: null
	,generatingCircles: null
	,subjAreaControl: null
	,clipAreaControl: null
	,intersectAreaControl: null
	,sciAreaControl: null
	,unionAreaControl: null
	,ctx: null
	,createUI: function() {
		var _g = this;
		var sui1 = new sui_Sui();
		var ui = sui1.folder("hxClipper - SuiDemo");
		var uiFolder = ui.folder("Options");
		uiFolder.text("Bool Op","CT_INTERSECTION",{ list : [{ label : "intersect", value : "CT_INTERSECTION"},{ label : "union", value : "CT_UNION"},{ label : "difference", value : "CT_DIFFERENCE"},{ label : "xor", value : "CT_XOR"}], listonly : true},function(v) {
			_g.clipType = Type.createEnum(hxClipper_ClipType,v);
			_g.update();
		});
		uiFolder.text("Fill Rule","PFT_NON_ZERO",{ list : [{ label : "evenodd", value : "PFT_EVEN_ODD"},{ label : "nonzero", value : "PFT_NON_ZERO"}], listonly : true},function(v1) {
			_g.fillType = Type.createEnum(hxClipper_PolyFillType,v1);
			_g.update();
		});
		this.countLabel = new sui_controls_LabelControl("Vertex Count");
		var countControl = sui_Sui.createInt(this.nudCount,{ min : 3, max : 100});
		uiFolder.grid.add(sui_components_CellContent.HorizontalPair(this.countLabel,countControl));
		uiFolder["float"]("Offset",this.offset,{ step : 1, min : -20, max : 20},function(v2) {
			_g.offset = v2;
			_g.update();
		});
		uiFolder.text("Join Type","JT_ROUND",{ list : [{ label : "miter", value : "JT_MITER"},{ label : "square", value : "JT_SQUARE"},{ label : "round", value : "JT_ROUND"}], listonly : true},function(v3) {
			_g.joinType = Type.createEnum(hxClipper_JoinType,v3);
			_g.update();
		});
		uiFolder = ui.folder("Generate Samples");
		uiFolder.trigger("random polys",null,null,function() {
			_g.generatingCircles = false;
			_g.countLabel.set("Vertex Count");
			_g.genRandomPolygons(_g.nudCount);
			_g.update();
		});
		uiFolder.trigger("australia + circles",null,null,function() {
			_g.generatingCircles = true;
			_g.countLabel.set("Circle Count");
			_g.genRandomCircles(_g.nudCount);
			_g.subjects.length = 0;
			_g.subjects = _g.australia.concat([]);
			_g.update();
		});
		uiFolder = ui.folder("Visibility");
		uiFolder.bool("Show Subjects",this.showSubjects,null,function(v4) {
			_g.showSubjects = v4;
			_g.update();
		});
		uiFolder.bool("Show Clips",this.showClips,null,function(v5) {
			_g.showClips = v5;
			_g.update();
		});
		uiFolder.bool("Show Solution",this.showSolution,null,function(v6) {
			_g.showSolution = v6;
			_g.update();
		});
		uiFolder = ui.folder("Area Info");
		this.subjAreaControl = uiFolder["float"]("Subjects (s)",0,{ disabled : true},function(v7) {
		});
		this.clipAreaControl = uiFolder["float"]("Clips (c)",0,{ disabled : true},function(v8) {
		});
		this.intersectAreaControl = uiFolder["float"]("Intersection (i)",0,{ disabled : true},function(v9) {
		});
		this.sciAreaControl = uiFolder["float"]("(s) + (c) - (i)",0,{ disabled : true},function(v10) {
		});
		this.unionAreaControl = uiFolder["float"]("Union",0,{ disabled : true},function(v11) {
		});
		countControl.streams.value.subscribe(function(v12) {
			_g.nudCount = v12;
			if(_g.generatingCircles) _g.genRandomCircles(_g.nudCount); else _g.genRandomPolygons(_g.nudCount);
			_g.update();
		});
		sui1.attach();
	}
	,update: function() {
		this.ctx.clearRect(0,0,SuiDemoJS.width,SuiDemoJS.height);
		var fillRule;
		if(this.fillType == hxClipper_PolyFillType.PFT_EVEN_ODD) fillRule = "evenodd"; else fillRule = "nonzero";
		if(this.showSubjects) this.drawPolys(this.subjects,"#C3C9CF","#DDDDF0",.75,.5,.6,fillRule);
		if(this.showClips) this.drawPolys(this.clips,"#F9BEA6","#FFE0E0",.75,.5,.6,fillRule);
		if(this.clips.length > 0 || this.subjects.length > 0) {
			var c = new hxClipper_Clipper();
			c.addPaths(this.subjects,hxClipper_PolyType.PT_SUBJECT,true);
			c.addPaths(this.clips,hxClipper_PolyType.PT_CLIP,true);
			this.solution.length = 0;
			var success = c.executePaths(this.clipType,this.solution,this.fillType,this.fillType);
			if(success) {
				var solution2 = [];
				if(this.offset != 0) {
					var co = new hxClipper_ClipperOffset();
					co.addPaths(this.solution,this.joinType,hxClipper_EndType.ET_CLOSED_POLYGON);
					co.executePaths(solution2,this.offset * this.scale);
				} else solution2 = solution2.concat(this.solution);
				if(this.showSolution) this.drawPolys(solution2,"#003300","#66EF7F",1,.5,.75,"nonzero");
				this.calcAreas();
			}
		}
	}
	,calcAreas: function() {
		var subjArea = 0;
		var clipArea = 0;
		var intersectArea = 0;
		var sciArea = 0;
		var unionArea = 0;
		var solution = [];
		var c = new hxClipper_Clipper();
		c.addPaths(this.subjects,hxClipper_PolyType.PT_SUBJECT,true);
		c.executePaths(hxClipper_ClipType.CT_UNION,solution,this.fillType,this.fillType);
		var _g = 0;
		while(_g < solution.length) {
			var poly = solution[_g];
			++_g;
			subjArea += hxClipper_Clipper.area(poly);
		}
		c.clear();
		c.addPaths(this.clips,hxClipper_PolyType.PT_CLIP,true);
		c.executePaths(hxClipper_ClipType.CT_UNION,solution,this.fillType,this.fillType);
		var _g1 = 0;
		while(_g1 < solution.length) {
			var poly1 = solution[_g1];
			++_g1;
			clipArea += hxClipper_Clipper.area(poly1);
		}
		c.addPaths(this.subjects,hxClipper_PolyType.PT_SUBJECT,true);
		c.executePaths(hxClipper_ClipType.CT_INTERSECTION,solution,this.fillType,this.fillType);
		var _g2 = 0;
		while(_g2 < solution.length) {
			var poly2 = solution[_g2];
			++_g2;
			intersectArea += hxClipper_Clipper.area(poly2);
		}
		c.executePaths(hxClipper_ClipType.CT_UNION,solution,this.fillType,this.fillType);
		var _g3 = 0;
		while(_g3 < solution.length) {
			var poly3 = solution[_g3];
			++_g3;
			unionArea += hxClipper_Clipper.area(poly3);
		}
		sciArea = subjArea + clipArea - intersectArea;
		this.subjAreaControl.set(Math.round(subjArea / 100000));
		this.clipAreaControl.set(Math.round(clipArea / 100000));
		this.intersectAreaControl.set(Math.round(intersectArea / 100000));
		this.sciAreaControl.set(Math.round(sciArea / 100000));
		this.unionAreaControl.set(Math.round(unionArea / 100000));
	}
	,drawPoly: function(poly) {
		var p0 = poly[0];
		this.ctx.moveTo(p0.x / this.scale,p0.y / this.scale);
		var _g1 = 1;
		var _g = poly.length;
		while(_g1 < _g) {
			var i = _g1++;
			var p = poly[i];
			this.ctx.lineTo(p.x / this.scale,p.y / this.scale);
		}
		this.ctx.lineTo(p0.x / this.scale,p0.y / this.scale);
	}
	,drawPolys: function(polys,strokeColor,fillColor,strokeAlpha,fillAlpha,lineWidth,fillRule) {
		if(lineWidth == null) lineWidth = 1;
		if(fillAlpha == null) fillAlpha = 1;
		if(strokeAlpha == null) strokeAlpha = 1;
		if(fillRule == null) fillRule = "nonzero";
		this.ctx.save();
		this.ctx.globalAlpha = fillAlpha;
		this.ctx.fillStyle = fillColor;
		this.ctx.beginPath();
		var _g = 0;
		while(_g < polys.length) {
			var poly = polys[_g];
			++_g;
			this.drawPoly(poly);
		}
		this.ctx.closePath();
		this.ctx.fill(fillRule);
		this.ctx.restore();
		this.ctx.globalAlpha = strokeAlpha;
		this.ctx.strokeStyle = strokeColor;
		this.ctx.lineWidth = lineWidth;
		this.ctx.stroke();
	}
	,createCanvas: function(w,h,offsetX,offsetY) {
		if(offsetY == null) offsetY = 0;
		if(offsetX == null) offsetX = 0;
		var canvas;
		var _this = window.document;
		canvas = _this.createElement("canvas");
		canvas.width = w;
		canvas.height = h;
		if(offsetX != 0 && offsetY != 0) {
			canvas.style.position = "relative";
			canvas.style.left = "" + offsetX + "px";
			canvas.style.top = "" + offsetY + "px";
		}
		window.document.body.appendChild(canvas);
		return canvas;
	}
	,genRandomPoint: function(l,t,r,b) {
		var Q = 10;
		return new hxClipper_IntPoint(Std["int"]((Math.random() * (r / Q) * Q + l + 10) * this.scale),Std["int"]((Math.random() * (b / Q) * Q + t + 10) * this.scale));
	}
	,genRandomCircles: function(count) {
		this.clips.length = 0;
		var max_radius = 50;
		var margin = 10;
		var _g = 0;
		while(_g < count) {
			var i = _g++;
			var circle = [];
			var w = SuiDemoJS.width - max_radius * 2 - margin * 2;
			var h = SuiDemoJS.height - max_radius * 2 - margin * 2;
			var radius = Math.random() * (max_radius - margin) + margin;
			var x = Math.random() * w + radius + margin;
			var y = Math.random() * h + radius + margin;
			var steps = radius * 2 | 0;
			var theta = 2 * Math.PI / steps;
			var _g1 = 0;
			while(_g1 < steps) {
				var s = _g1++;
				circle.push(new hxClipper_IntPoint(Std["int"](this.scale * (x + radius * Math.cos(theta * s))),Std["int"](this.scale * (y + radius * Math.sin(theta * s)))));
			}
			this.clips.push(circle);
		}
	}
	,genRandomPolygons: function(count) {
		var Q = 10;
		var l = 10;
		var t = 10;
		var r = (SuiDemoJS.width - 20) / Q * Q | 0;
		var b = (SuiDemoJS.height - 20) / Q * Q | 0;
		this.subjects.length = 0;
		this.clips.length = 0;
		var subj = [];
		var _g = 0;
		while(_g < count) {
			var i = _g++;
			subj.push(this.genRandomPoint(l,t,r,b));
		}
		this.subjects.push(subj);
		var clip = [];
		var _g1 = 0;
		while(_g1 < count) {
			var i1 = _g1++;
			clip.push(this.genRandomPoint(l,t,r,b));
		}
		this.clips.push(clip);
	}
	,getPolysFromBytes: function(bytes,scale) {
		if(scale == null) scale = 1;
		var res = [];
		var pos = 0;
		var polyCnt = bytes.getInt32(pos);
		var _g = 0;
		while(_g < polyCnt) {
			var i = _g++;
			pos += 4;
			var vertCnt = bytes.getInt32(pos);
			var pg = [];
			var _g1 = 0;
			while(_g1 < vertCnt) {
				var j = _g1++;
				pos += 4;
				var x = bytes.getFloat(pos) * scale;
				pos += 4;
				var y = bytes.getFloat(pos) * scale;
				pg.push(new hxClipper_IntPoint(x | 0,y | 0));
			}
			res.push(pg);
		}
		return res;
	}
	,__class__: SuiDemoJS
};
var ValueType = { __ename__ : ["ValueType"], __constructs__ : ["TNull","TInt","TFloat","TBool","TObject","TFunction","TClass","TEnum","TUnknown"] };
ValueType.TNull = ["TNull",0];
ValueType.TNull.toString = $estr;
ValueType.TNull.__enum__ = ValueType;
ValueType.TInt = ["TInt",1];
ValueType.TInt.toString = $estr;
ValueType.TInt.__enum__ = ValueType;
ValueType.TFloat = ["TFloat",2];
ValueType.TFloat.toString = $estr;
ValueType.TFloat.__enum__ = ValueType;
ValueType.TBool = ["TBool",3];
ValueType.TBool.toString = $estr;
ValueType.TBool.__enum__ = ValueType;
ValueType.TObject = ["TObject",4];
ValueType.TObject.toString = $estr;
ValueType.TObject.__enum__ = ValueType;
ValueType.TFunction = ["TFunction",5];
ValueType.TFunction.toString = $estr;
ValueType.TFunction.__enum__ = ValueType;
ValueType.TClass = function(c) { var $x = ["TClass",6,c]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; };
ValueType.TEnum = function(e) { var $x = ["TEnum",7,e]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; };
ValueType.TUnknown = ["TUnknown",8];
ValueType.TUnknown.toString = $estr;
ValueType.TUnknown.__enum__ = ValueType;
var Type = function() { };
Type.__name__ = ["Type"];
Type.getClass = function(o) {
	if(o == null) return null; else return js_Boot.getClass(o);
};
Type.getSuperClass = function(c) {
	return c.__super__;
};
Type.getClassName = function(c) {
	var a = c.__name__;
	if(a == null) return null;
	return a.join(".");
};
Type.getEnumName = function(e) {
	var a = e.__ename__;
	return a.join(".");
};
Type.createEnum = function(e,constr,params) {
	var f = Reflect.field(e,constr);
	if(f == null) throw new js__$Boot_HaxeError("No such constructor " + constr);
	if(Reflect.isFunction(f)) {
		if(params == null) throw new js__$Boot_HaxeError("Constructor " + constr + " need parameters");
		return Reflect.callMethod(e,f,params);
	}
	if(params != null && params.length != 0) throw new js__$Boot_HaxeError("Constructor " + constr + " does not need parameters");
	return f;
};
Type.getInstanceFields = function(c) {
	var a = [];
	for(var i in c.prototype) a.push(i);
	HxOverrides.remove(a,"__class__");
	HxOverrides.remove(a,"__properties__");
	return a;
};
Type["typeof"] = function(v) {
	var _g = typeof(v);
	switch(_g) {
	case "boolean":
		return ValueType.TBool;
	case "string":
		return ValueType.TClass(String);
	case "number":
		if(Math.ceil(v) == v % 2147483648.0) return ValueType.TInt;
		return ValueType.TFloat;
	case "object":
		if(v == null) return ValueType.TNull;
		var e = v.__enum__;
		if(e != null) return ValueType.TEnum(e);
		var c = js_Boot.getClass(v);
		if(c != null) return ValueType.TClass(c);
		return ValueType.TObject;
	case "function":
		if(v.__name__ || v.__ename__) return ValueType.TObject;
		return ValueType.TFunction;
	case "undefined":
		return ValueType.TNull;
	default:
		return ValueType.TUnknown;
	}
};
var dots_Detect = function() { };
dots_Detect.__name__ = ["dots","Detect"];
dots_Detect.supportsInput = function(type) {
	var i;
	var _this = window.document;
	i = _this.createElement("input");
	i.setAttribute("type",type);
	return i.type == type;
};
dots_Detect.supportsInputPlaceholder = function() {
	var i;
	var _this = window.document;
	i = _this.createElement("input");
	return Object.prototype.hasOwnProperty.call(i,"placeholder");
};
dots_Detect.supportsInputAutofocus = function() {
	var i;
	var _this = window.document;
	i = _this.createElement("input");
	return Object.prototype.hasOwnProperty.call(i,"autofocus");
};
dots_Detect.supportsCanvas = function() {
	return null != ($_=((function($this) {
		var $r;
		var _this = window.document;
		$r = _this.createElement("canvas");
		return $r;
	}(this))),$bind($_,$_.getContext));
};
dots_Detect.supportsVideo = function() {
	return null != ($_=((function($this) {
		var $r;
		var _this = window.document;
		$r = _this.createElement("video");
		return $r;
	}(this))),$bind($_,$_.canPlayType));
};
dots_Detect.supportsLocalStorage = function() {
	try {
		return 'localStorage' in window && window['localStorage'] !== null;
	} catch( e ) {
		haxe_CallStack.lastException = e;
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		return false;
	}
};
dots_Detect.supportsWebWorkers = function() {
	return !(!window.Worker);
};
dots_Detect.supportsOffline = function() {
	return null != window.applicationCache;
};
dots_Detect.supportsGeolocation = function() {
	return Reflect.hasField(window.navigator,"geolocation");
};
dots_Detect.supportsMicrodata = function() {
	return Reflect.hasField(window.document,"getItems");
};
dots_Detect.supportsHistory = function() {
	return !!(window.history && history.pushState);
};
var dots_Dom = function() { };
dots_Dom.__name__ = ["dots","Dom"];
dots_Dom.addCss = function(css,container) {
	if(null == container) container = window.document.head;
	var style;
	var _this = window.document;
	style = _this.createElement("style");
	style.type = "text/css";
	style.appendChild(window.document.createTextNode(css));
	container.appendChild(style);
};
var dots_Html = function() { };
dots_Html.__name__ = ["dots","Html"];
dots_Html.parseNodes = function(html) {
	if(!dots_Html.pattern.match(html)) throw new js__$Boot_HaxeError("Invalid pattern \"" + html + "\"");
	var el;
	var _g = dots_Html.pattern.matched(1).toLowerCase();
	switch(_g) {
	case "tbody":case "thead":
		el = window.document.createElement("table");
		break;
	case "td":case "th":
		el = window.document.createElement("tr");
		break;
	case "tr":
		el = window.document.createElement("tbody");
		break;
	default:
		el = window.document.createElement("div");
	}
	el.innerHTML = html;
	return el.childNodes;
};
dots_Html.parseArray = function(html) {
	return dots_Html.nodeListToArray(dots_Html.parseNodes(html));
};
dots_Html.parse = function(html) {
	return dots_Html.parseNodes(html)[0];
};
dots_Html.nodeListToArray = function(list) {
	return Array.prototype.slice.call(list,0);
};
var dots_Query = function() { };
dots_Query.__name__ = ["dots","Query"];
dots_Query.first = function(selector,ctx) {
	return (ctx != null?ctx:dots_Query.doc).querySelector(selector);
};
dots_Query.list = function(selector,ctx) {
	return (ctx != null?ctx:dots_Query.doc).querySelectorAll(selector);
};
dots_Query.all = function(selector,ctx) {
	return dots_Html.nodeListToArray(dots_Query.list(selector,ctx));
};
dots_Query.getElementIndex = function(el) {
	var index = 0;
	while(null != (el = el.previousElementSibling)) index++;
	return index;
};
dots_Query.childrenOf = function(children,parent) {
	return children.filter(function(child) {
		return child.parentElement == parent;
	});
};
var haxe_StackItem = { __ename__ : ["haxe","StackItem"], __constructs__ : ["CFunction","Module","FilePos","Method","LocalFunction"] };
haxe_StackItem.CFunction = ["CFunction",0];
haxe_StackItem.CFunction.toString = $estr;
haxe_StackItem.CFunction.__enum__ = haxe_StackItem;
haxe_StackItem.Module = function(m) { var $x = ["Module",1,m]; $x.__enum__ = haxe_StackItem; $x.toString = $estr; return $x; };
haxe_StackItem.FilePos = function(s,file,line) { var $x = ["FilePos",2,s,file,line]; $x.__enum__ = haxe_StackItem; $x.toString = $estr; return $x; };
haxe_StackItem.Method = function(classname,method) { var $x = ["Method",3,classname,method]; $x.__enum__ = haxe_StackItem; $x.toString = $estr; return $x; };
haxe_StackItem.LocalFunction = function(v) { var $x = ["LocalFunction",4,v]; $x.__enum__ = haxe_StackItem; $x.toString = $estr; return $x; };
var haxe_CallStack = function() { };
haxe_CallStack.__name__ = ["haxe","CallStack"];
haxe_CallStack.getStack = function(e) {
	if(e == null) return [];
	var oldValue = Error.prepareStackTrace;
	Error.prepareStackTrace = function(error,callsites) {
		var stack = [];
		var _g = 0;
		while(_g < callsites.length) {
			var site = callsites[_g];
			++_g;
			if(haxe_CallStack.wrapCallSite != null) site = haxe_CallStack.wrapCallSite(site);
			var method = null;
			var fullName = site.getFunctionName();
			if(fullName != null) {
				var idx = fullName.lastIndexOf(".");
				if(idx >= 0) {
					var className = HxOverrides.substr(fullName,0,idx);
					var methodName = HxOverrides.substr(fullName,idx + 1,null);
					method = haxe_StackItem.Method(className,methodName);
				}
			}
			stack.push(haxe_StackItem.FilePos(method,site.getFileName(),site.getLineNumber()));
		}
		return stack;
	};
	var a = haxe_CallStack.makeStack(e.stack);
	Error.prepareStackTrace = oldValue;
	return a;
};
haxe_CallStack.callStack = function() {
	try {
		throw new Error();
	} catch( e ) {
		haxe_CallStack.lastException = e;
		if (e instanceof js__$Boot_HaxeError) e = e.val;
		var a = haxe_CallStack.getStack(e);
		a.shift();
		return a;
	}
};
haxe_CallStack.exceptionStack = function() {
	return haxe_CallStack.getStack(haxe_CallStack.lastException);
};
haxe_CallStack.toString = function(stack) {
	var b = new StringBuf();
	var _g = 0;
	while(_g < stack.length) {
		var s = stack[_g];
		++_g;
		b.b += "\nCalled from ";
		haxe_CallStack.itemToString(b,s);
	}
	return b.b;
};
haxe_CallStack.itemToString = function(b,s) {
	switch(s[1]) {
	case 0:
		b.b += "a C function";
		break;
	case 1:
		var m = s[2];
		b.b += "module ";
		if(m == null) b.b += "null"; else b.b += "" + m;
		break;
	case 2:
		var line = s[4];
		var file = s[3];
		var s1 = s[2];
		if(s1 != null) {
			haxe_CallStack.itemToString(b,s1);
			b.b += " (";
		}
		if(file == null) b.b += "null"; else b.b += "" + file;
		b.b += " line ";
		if(line == null) b.b += "null"; else b.b += "" + line;
		if(s1 != null) b.b += ")";
		break;
	case 3:
		var meth = s[3];
		var cname = s[2];
		if(cname == null) b.b += "null"; else b.b += "" + cname;
		b.b += ".";
		if(meth == null) b.b += "null"; else b.b += "" + meth;
		break;
	case 4:
		var n = s[2];
		b.b += "local function #";
		if(n == null) b.b += "null"; else b.b += "" + n;
		break;
	}
};
haxe_CallStack.makeStack = function(s) {
	if(s == null) return []; else if(typeof(s) == "string") {
		var stack = s.split("\n");
		if(stack[0] == "Error") stack.shift();
		var m = [];
		var rie10 = new EReg("^   at ([A-Za-z0-9_. ]+) \\(([^)]+):([0-9]+):([0-9]+)\\)$","");
		var _g = 0;
		while(_g < stack.length) {
			var line = stack[_g];
			++_g;
			if(rie10.match(line)) {
				var path = rie10.matched(1).split(".");
				var meth = path.pop();
				var file = rie10.matched(2);
				var line1 = Std.parseInt(rie10.matched(3));
				m.push(haxe_StackItem.FilePos(meth == "Anonymous function"?haxe_StackItem.LocalFunction():meth == "Global code"?null:haxe_StackItem.Method(path.join("."),meth),file,line1));
			} else m.push(haxe_StackItem.Module(StringTools.trim(line)));
		}
		return m;
	} else return s;
};
var haxe_IMap = function() { };
haxe_IMap.__name__ = ["haxe","IMap"];
haxe_IMap.prototype = {
	get: null
	,set: null
	,exists: null
	,keys: null
	,__class__: haxe_IMap
};
var haxe__$Int64__$_$_$Int64 = function(high,low) {
	this.high = high;
	this.low = low;
};
haxe__$Int64__$_$_$Int64.__name__ = ["haxe","_Int64","___Int64"];
haxe__$Int64__$_$_$Int64.prototype = {
	high: null
	,low: null
	,__class__: haxe__$Int64__$_$_$Int64
};
var haxe_Log = function() { };
haxe_Log.__name__ = ["haxe","Log"];
haxe_Log.trace = function(v,infos) {
	js_Boot.__trace(v,infos);
};
var haxe_Resource = function() { };
haxe_Resource.__name__ = ["haxe","Resource"];
haxe_Resource.getBytes = function(name) {
	var _g = 0;
	var _g1 = haxe_Resource.content;
	while(_g < _g1.length) {
		var x = _g1[_g];
		++_g;
		if(x.name == name) {
			if(x.str != null) return haxe_io_Bytes.ofString(x.str);
			return haxe_crypto_Base64.decode(x.data);
		}
	}
	return null;
};
var haxe_io_Bytes = function(data) {
	this.length = data.byteLength;
	this.b = new Uint8Array(data);
	this.b.bufferValue = data;
	data.hxBytes = this;
	data.bytes = this.b;
};
haxe_io_Bytes.__name__ = ["haxe","io","Bytes"];
haxe_io_Bytes.alloc = function(length) {
	return new haxe_io_Bytes(new ArrayBuffer(length));
};
haxe_io_Bytes.ofString = function(s) {
	var a = [];
	var i = 0;
	while(i < s.length) {
		var c = StringTools.fastCodeAt(s,i++);
		if(55296 <= c && c <= 56319) c = c - 55232 << 10 | StringTools.fastCodeAt(s,i++) & 1023;
		if(c <= 127) a.push(c); else if(c <= 2047) {
			a.push(192 | c >> 6);
			a.push(128 | c & 63);
		} else if(c <= 65535) {
			a.push(224 | c >> 12);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		} else {
			a.push(240 | c >> 18);
			a.push(128 | c >> 12 & 63);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		}
	}
	return new haxe_io_Bytes(new Uint8Array(a).buffer);
};
haxe_io_Bytes.prototype = {
	length: null
	,b: null
	,data: null
	,get: function(pos) {
		return this.b[pos];
	}
	,set: function(pos,v) {
		this.b[pos] = v & 255;
	}
	,getFloat: function(pos) {
		if(this.data == null) this.data = new DataView(this.b.buffer,this.b.byteOffset,this.b.byteLength);
		return this.data.getFloat32(pos,true);
	}
	,getInt32: function(pos) {
		if(this.data == null) this.data = new DataView(this.b.buffer,this.b.byteOffset,this.b.byteLength);
		return this.data.getInt32(pos,true);
	}
	,__class__: haxe_io_Bytes
};
var haxe_crypto_Base64 = function() { };
haxe_crypto_Base64.__name__ = ["haxe","crypto","Base64"];
haxe_crypto_Base64.decode = function(str,complement) {
	if(complement == null) complement = true;
	if(complement) while(HxOverrides.cca(str,str.length - 1) == 61) str = HxOverrides.substr(str,0,-1);
	return new haxe_crypto_BaseCode(haxe_crypto_Base64.BYTES).decodeBytes(haxe_io_Bytes.ofString(str));
};
var haxe_crypto_BaseCode = function(base) {
	var len = base.length;
	var nbits = 1;
	while(len > 1 << nbits) nbits++;
	if(nbits > 8 || len != 1 << nbits) throw new js__$Boot_HaxeError("BaseCode : base length must be a power of two.");
	this.base = base;
	this.nbits = nbits;
};
haxe_crypto_BaseCode.__name__ = ["haxe","crypto","BaseCode"];
haxe_crypto_BaseCode.prototype = {
	base: null
	,nbits: null
	,tbl: null
	,initTable: function() {
		var tbl = [];
		var _g = 0;
		while(_g < 256) {
			var i = _g++;
			tbl[i] = -1;
		}
		var _g1 = 0;
		var _g2 = this.base.length;
		while(_g1 < _g2) {
			var i1 = _g1++;
			tbl[this.base.b[i1]] = i1;
		}
		this.tbl = tbl;
	}
	,decodeBytes: function(b) {
		var nbits = this.nbits;
		var base = this.base;
		if(this.tbl == null) this.initTable();
		var tbl = this.tbl;
		var size = b.length * nbits >> 3;
		var out = haxe_io_Bytes.alloc(size);
		var buf = 0;
		var curbits = 0;
		var pin = 0;
		var pout = 0;
		while(pout < size) {
			while(curbits < 8) {
				curbits += nbits;
				buf <<= nbits;
				var i = tbl[b.get(pin++)];
				if(i == -1) throw new js__$Boot_HaxeError("BaseCode : invalid encoded char");
				buf |= i;
			}
			curbits -= 8;
			out.set(pout++,buf >> curbits & 255);
		}
		return out;
	}
	,__class__: haxe_crypto_BaseCode
};
var haxe_ds_ArraySort = function() { };
haxe_ds_ArraySort.__name__ = ["haxe","ds","ArraySort"];
haxe_ds_ArraySort.sort = function(a,cmp) {
	haxe_ds_ArraySort.rec(a,cmp,0,a.length);
};
haxe_ds_ArraySort.rec = function(a,cmp,from,to) {
	var middle = from + to >> 1;
	if(to - from < 12) {
		if(to <= from) return;
		var _g = from + 1;
		while(_g < to) {
			var i = _g++;
			var j = i;
			while(j > from) {
				if(cmp(a[j],a[j - 1]) < 0) haxe_ds_ArraySort.swap(a,j - 1,j); else break;
				j--;
			}
		}
		return;
	}
	haxe_ds_ArraySort.rec(a,cmp,from,middle);
	haxe_ds_ArraySort.rec(a,cmp,middle,to);
	haxe_ds_ArraySort.doMerge(a,cmp,from,middle,to,middle - from,to - middle);
};
haxe_ds_ArraySort.doMerge = function(a,cmp,from,pivot,to,len1,len2) {
	var first_cut;
	var second_cut;
	var len11;
	var len22;
	var new_mid;
	if(len1 == 0 || len2 == 0) return;
	if(len1 + len2 == 2) {
		if(cmp(a[pivot],a[from]) < 0) haxe_ds_ArraySort.swap(a,pivot,from);
		return;
	}
	if(len1 > len2) {
		len11 = len1 >> 1;
		first_cut = from + len11;
		second_cut = haxe_ds_ArraySort.lower(a,cmp,pivot,to,first_cut);
		len22 = second_cut - pivot;
	} else {
		len22 = len2 >> 1;
		second_cut = pivot + len22;
		first_cut = haxe_ds_ArraySort.upper(a,cmp,from,pivot,second_cut);
		len11 = first_cut - from;
	}
	haxe_ds_ArraySort.rotate(a,cmp,first_cut,pivot,second_cut);
	new_mid = first_cut + len22;
	haxe_ds_ArraySort.doMerge(a,cmp,from,first_cut,new_mid,len11,len22);
	haxe_ds_ArraySort.doMerge(a,cmp,new_mid,second_cut,to,len1 - len11,len2 - len22);
};
haxe_ds_ArraySort.rotate = function(a,cmp,from,mid,to) {
	var n;
	if(from == mid || mid == to) return;
	n = haxe_ds_ArraySort.gcd(to - from,mid - from);
	while(n-- != 0) {
		var val = a[from + n];
		var shift = mid - from;
		var p1 = from + n;
		var p2 = from + n + shift;
		while(p2 != from + n) {
			a[p1] = a[p2];
			p1 = p2;
			if(to - p2 > shift) p2 += shift; else p2 = from + (shift - (to - p2));
		}
		a[p1] = val;
	}
};
haxe_ds_ArraySort.gcd = function(m,n) {
	while(n != 0) {
		var t = m % n;
		m = n;
		n = t;
	}
	return m;
};
haxe_ds_ArraySort.upper = function(a,cmp,from,to,val) {
	var len = to - from;
	var half;
	var mid;
	while(len > 0) {
		half = len >> 1;
		mid = from + half;
		if(cmp(a[val],a[mid]) < 0) len = half; else {
			from = mid + 1;
			len = len - half - 1;
		}
	}
	return from;
};
haxe_ds_ArraySort.lower = function(a,cmp,from,to,val) {
	var len = to - from;
	var half;
	var mid;
	while(len > 0) {
		half = len >> 1;
		mid = from + half;
		if(cmp(a[mid],a[val]) < 0) {
			from = mid + 1;
			len = len - half - 1;
		} else len = half;
	}
	return from;
};
haxe_ds_ArraySort.swap = function(a,i,j) {
	var tmp = a[i];
	a[i] = a[j];
	a[j] = tmp;
};
var haxe_ds_IntMap = function() {
	this.h = { };
};
haxe_ds_IntMap.__name__ = ["haxe","ds","IntMap"];
haxe_ds_IntMap.__interfaces__ = [haxe_IMap];
haxe_ds_IntMap.prototype = {
	h: null
	,set: function(key,value) {
		this.h[key] = value;
	}
	,get: function(key) {
		return this.h[key];
	}
	,exists: function(key) {
		return this.h.hasOwnProperty(key);
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key | 0);
		}
		return HxOverrides.iter(a);
	}
	,__class__: haxe_ds_IntMap
};
var haxe_ds_ObjectMap = function() {
	this.h = { };
	this.h.__keys__ = { };
};
haxe_ds_ObjectMap.__name__ = ["haxe","ds","ObjectMap"];
haxe_ds_ObjectMap.__interfaces__ = [haxe_IMap];
haxe_ds_ObjectMap.prototype = {
	h: null
	,set: function(key,value) {
		var id = key.__id__ || (key.__id__ = ++haxe_ds_ObjectMap.count);
		this.h[id] = value;
		this.h.__keys__[id] = key;
	}
	,get: function(key) {
		return this.h[key.__id__];
	}
	,exists: function(key) {
		return this.h.__keys__[key.__id__] != null;
	}
	,keys: function() {
		var a = [];
		for( var key in this.h.__keys__ ) {
		if(this.h.hasOwnProperty(key)) a.push(this.h.__keys__[key]);
		}
		return HxOverrides.iter(a);
	}
	,__class__: haxe_ds_ObjectMap
};
var haxe_ds_Option = { __ename__ : ["haxe","ds","Option"], __constructs__ : ["Some","None"] };
haxe_ds_Option.Some = function(v) { var $x = ["Some",0,v]; $x.__enum__ = haxe_ds_Option; $x.toString = $estr; return $x; };
haxe_ds_Option.None = ["None",1];
haxe_ds_Option.None.toString = $estr;
haxe_ds_Option.None.__enum__ = haxe_ds_Option;
var haxe_ds_StringMap = function() {
	this.h = { };
};
haxe_ds_StringMap.__name__ = ["haxe","ds","StringMap"];
haxe_ds_StringMap.__interfaces__ = [haxe_IMap];
haxe_ds_StringMap.prototype = {
	h: null
	,rh: null
	,set: function(key,value) {
		if(__map_reserved[key] != null) this.setReserved(key,value); else this.h[key] = value;
	}
	,get: function(key) {
		if(__map_reserved[key] != null) return this.getReserved(key);
		return this.h[key];
	}
	,exists: function(key) {
		if(__map_reserved[key] != null) return this.existsReserved(key);
		return this.h.hasOwnProperty(key);
	}
	,setReserved: function(key,value) {
		if(this.rh == null) this.rh = { };
		this.rh["$" + key] = value;
	}
	,getReserved: function(key) {
		if(this.rh == null) return null; else return this.rh["$" + key];
	}
	,existsReserved: function(key) {
		if(this.rh == null) return false;
		return this.rh.hasOwnProperty("$" + key);
	}
	,keys: function() {
		var _this = this.arrayKeys();
		return HxOverrides.iter(_this);
	}
	,arrayKeys: function() {
		var out = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) out.push(key);
		}
		if(this.rh != null) {
			for( var key in this.rh ) {
			if(key.charCodeAt(0) == 36) out.push(key.substr(1));
			}
		}
		return out;
	}
	,__class__: haxe_ds_StringMap
};
var haxe_io_Error = { __ename__ : ["haxe","io","Error"], __constructs__ : ["Blocked","Overflow","OutsideBounds","Custom"] };
haxe_io_Error.Blocked = ["Blocked",0];
haxe_io_Error.Blocked.toString = $estr;
haxe_io_Error.Blocked.__enum__ = haxe_io_Error;
haxe_io_Error.Overflow = ["Overflow",1];
haxe_io_Error.Overflow.toString = $estr;
haxe_io_Error.Overflow.__enum__ = haxe_io_Error;
haxe_io_Error.OutsideBounds = ["OutsideBounds",2];
haxe_io_Error.OutsideBounds.toString = $estr;
haxe_io_Error.OutsideBounds.__enum__ = haxe_io_Error;
haxe_io_Error.Custom = function(e) { var $x = ["Custom",3,e]; $x.__enum__ = haxe_io_Error; $x.toString = $estr; return $x; };
var haxe_io_FPHelper = function() { };
haxe_io_FPHelper.__name__ = ["haxe","io","FPHelper"];
haxe_io_FPHelper.i32ToFloat = function(i) {
	var sign = 1 - (i >>> 31 << 1);
	var exp = i >>> 23 & 255;
	var sig = i & 8388607;
	if(sig == 0 && exp == 0) return 0.0;
	return sign * (1 + Math.pow(2,-23) * sig) * Math.pow(2,exp - 127);
};
haxe_io_FPHelper.floatToI32 = function(f) {
	if(f == 0) return 0;
	var af;
	if(f < 0) af = -f; else af = f;
	var exp = Math.floor(Math.log(af) / 0.6931471805599453);
	if(exp < -127) exp = -127; else if(exp > 128) exp = 128;
	var sig = Math.round((af / Math.pow(2,exp) - 1) * 8388608) & 8388607;
	return (f < 0?-2147483648:0) | exp + 127 << 23 | sig;
};
haxe_io_FPHelper.i64ToDouble = function(low,high) {
	var sign = 1 - (high >>> 31 << 1);
	var exp = (high >> 20 & 2047) - 1023;
	var sig = (high & 1048575) * 4294967296. + (low >>> 31) * 2147483648. + (low & 2147483647);
	if(sig == 0 && exp == -1023) return 0.0;
	return sign * (1.0 + Math.pow(2,-52) * sig) * Math.pow(2,exp);
};
haxe_io_FPHelper.doubleToI64 = function(v) {
	var i64 = haxe_io_FPHelper.i64tmp;
	if(v == 0) {
		i64.low = 0;
		i64.high = 0;
	} else {
		var av;
		if(v < 0) av = -v; else av = v;
		var exp = Math.floor(Math.log(av) / 0.6931471805599453);
		var sig;
		var v1 = (av / Math.pow(2,exp) - 1) * 4503599627370496.;
		sig = Math.round(v1);
		var sig_l = sig | 0;
		var sig_h = sig / 4294967296.0 | 0;
		i64.low = sig_l;
		i64.high = (v < 0?-2147483648:0) | exp + 1023 << 20 | sig_h;
	}
	return i64;
};
var hxClipper_DoublePoint = function(x,y) {
	if(y == null) y = 0;
	if(x == null) x = 0;
	this.x = x;
	this.y = y;
};
hxClipper_DoublePoint.__name__ = ["hxClipper","DoublePoint"];
hxClipper_DoublePoint.fromDoublePoint = function(dp) {
	return dp.clone();
};
hxClipper_DoublePoint.fromIntPoint = function(ip) {
	return new hxClipper_DoublePoint(ip.x,ip.y);
};
hxClipper_DoublePoint.prototype = {
	x: null
	,y: null
	,clone: function() {
		return new hxClipper_DoublePoint(this.x,this.y);
	}
	,toString: function() {
		return "(x:" + this.x + ", y:" + this.y + ")";
	}
	,__class__: hxClipper_DoublePoint
};
var hxClipper_PolyNode = function() {
	this.mChildren = [];
	this.mPolygon = [];
};
hxClipper_PolyNode.__name__ = ["hxClipper","PolyNode"];
hxClipper_PolyNode.prototype = {
	mParent: null
	,mPolygon: null
	,mIndex: null
	,mJoinType: null
	,mEndtype: null
	,mChildren: null
	,isHoleNode: function() {
		var result = true;
		var node = this.mParent;
		while(node != null) {
			result = !result;
			node = node.mParent;
		}
		return result;
	}
	,get_numChildren: function() {
		return this.mChildren.length;
	}
	,get_contour: function() {
		return this.mPolygon;
	}
	,addChild: function(child) {
		var cnt = this.mChildren.length;
		this.mChildren.push(child);
		child.mParent = this;
		child.mIndex = cnt;
	}
	,getNext: function() {
		if(this.mChildren.length > 0) return this.mChildren[0]; else return this.getNextSiblingUp();
	}
	,getNextSiblingUp: function() {
		if(this.mParent == null) return null; else if(this.mIndex == this.mParent.mChildren.length - 1) return this.mParent.getNextSiblingUp(); else return this.mParent.mChildren[this.mIndex + 1];
	}
	,get_children: function() {
		return this.mChildren;
	}
	,parent: null
	,get_parent: function() {
		return this.mParent;
	}
	,get_isHole: function() {
		return this.isHoleNode();
	}
	,isOpen: null
	,__class__: hxClipper_PolyNode
};
var hxClipper_PolyTree = function() {
	this.mAllPolys = [];
	hxClipper_PolyNode.call(this);
};
hxClipper_PolyTree.__name__ = ["hxClipper","PolyTree"];
hxClipper_PolyTree.__super__ = hxClipper_PolyNode;
hxClipper_PolyTree.prototype = $extend(hxClipper_PolyNode.prototype,{
	mAllPolys: null
	,clear: function() {
		var _g1 = 0;
		var _g = this.mAllPolys.length;
		while(_g1 < _g) {
			var i = _g1++;
			this.mAllPolys[i] = null;
		}
		this.mAllPolys.length = 0;
		this.mChildren.length = 0;
	}
	,getFirst: function() {
		if(this.mChildren.length > 0) return this.mChildren[0]; else return null;
	}
	,get_total: function() {
		var result = this.mAllPolys.length;
		if(result > 0 && this.mChildren[0] != this.mAllPolys[0]) result--;
		return result;
	}
	,__class__: hxClipper_PolyTree
});
var hxClipper_IntPoint = function(x,y) {
	if(y == null) y = 0;
	if(x == null) x = 0;
	this.x = x;
	this.y = y;
};
hxClipper_IntPoint.__name__ = ["hxClipper","IntPoint"];
hxClipper_IntPoint.fromFloats = function(x,y) {
	return new hxClipper_IntPoint(x | 0,y | 0);
};
hxClipper_IntPoint.fromDoublePoint = function(dp) {
	return hxClipper_IntPoint.fromFloats(dp.x,dp.y);
};
hxClipper_IntPoint.fromIntPoint = function(pt) {
	return pt.clone();
};
hxClipper_IntPoint.prototype = {
	x: null
	,y: null
	,clone: function() {
		return new hxClipper_IntPoint(this.x,this.y);
	}
	,toString: function() {
		return "(x:" + this.x + ", y:" + this.y + ")";
	}
	,copyFrom: function(ip) {
		this.x = ip.x;
		this.y = ip.y;
	}
	,equals: function(ip) {
		return this.x == ip.x && this.y == ip.y;
	}
	,__class__: hxClipper_IntPoint
};
var hxClipper_IntRect = function(l,t,r,b) {
	this.left = l;
	this.top = t;
	this.right = r;
	this.bottom = b;
};
hxClipper_IntRect.__name__ = ["hxClipper","IntRect"];
hxClipper_IntRect.prototype = {
	left: null
	,top: null
	,right: null
	,bottom: null
	,clone: function(ir) {
		return new hxClipper_IntRect(this.left,this.top,this.right,this.bottom);
	}
	,__class__: hxClipper_IntRect
};
var hxClipper_ClipType = { __ename__ : ["hxClipper","ClipType"], __constructs__ : ["CT_INTERSECTION","CT_UNION","CT_DIFFERENCE","CT_XOR"] };
hxClipper_ClipType.CT_INTERSECTION = ["CT_INTERSECTION",0];
hxClipper_ClipType.CT_INTERSECTION.toString = $estr;
hxClipper_ClipType.CT_INTERSECTION.__enum__ = hxClipper_ClipType;
hxClipper_ClipType.CT_UNION = ["CT_UNION",1];
hxClipper_ClipType.CT_UNION.toString = $estr;
hxClipper_ClipType.CT_UNION.__enum__ = hxClipper_ClipType;
hxClipper_ClipType.CT_DIFFERENCE = ["CT_DIFFERENCE",2];
hxClipper_ClipType.CT_DIFFERENCE.toString = $estr;
hxClipper_ClipType.CT_DIFFERENCE.__enum__ = hxClipper_ClipType;
hxClipper_ClipType.CT_XOR = ["CT_XOR",3];
hxClipper_ClipType.CT_XOR.toString = $estr;
hxClipper_ClipType.CT_XOR.__enum__ = hxClipper_ClipType;
var hxClipper_PolyType = { __ename__ : ["hxClipper","PolyType"], __constructs__ : ["PT_SUBJECT","PT_CLIP"] };
hxClipper_PolyType.PT_SUBJECT = ["PT_SUBJECT",0];
hxClipper_PolyType.PT_SUBJECT.toString = $estr;
hxClipper_PolyType.PT_SUBJECT.__enum__ = hxClipper_PolyType;
hxClipper_PolyType.PT_CLIP = ["PT_CLIP",1];
hxClipper_PolyType.PT_CLIP.toString = $estr;
hxClipper_PolyType.PT_CLIP.__enum__ = hxClipper_PolyType;
var hxClipper_PolyFillType = { __ename__ : ["hxClipper","PolyFillType"], __constructs__ : ["PFT_EVEN_ODD","PFT_NON_ZERO","PFT_POSITIVE","PFT_NEGATIVE"] };
hxClipper_PolyFillType.PFT_EVEN_ODD = ["PFT_EVEN_ODD",0];
hxClipper_PolyFillType.PFT_EVEN_ODD.toString = $estr;
hxClipper_PolyFillType.PFT_EVEN_ODD.__enum__ = hxClipper_PolyFillType;
hxClipper_PolyFillType.PFT_NON_ZERO = ["PFT_NON_ZERO",1];
hxClipper_PolyFillType.PFT_NON_ZERO.toString = $estr;
hxClipper_PolyFillType.PFT_NON_ZERO.__enum__ = hxClipper_PolyFillType;
hxClipper_PolyFillType.PFT_POSITIVE = ["PFT_POSITIVE",2];
hxClipper_PolyFillType.PFT_POSITIVE.toString = $estr;
hxClipper_PolyFillType.PFT_POSITIVE.__enum__ = hxClipper_PolyFillType;
hxClipper_PolyFillType.PFT_NEGATIVE = ["PFT_NEGATIVE",3];
hxClipper_PolyFillType.PFT_NEGATIVE.toString = $estr;
hxClipper_PolyFillType.PFT_NEGATIVE.__enum__ = hxClipper_PolyFillType;
var hxClipper_JoinType = { __ename__ : ["hxClipper","JoinType"], __constructs__ : ["JT_SQUARE","JT_ROUND","JT_MITER"] };
hxClipper_JoinType.JT_SQUARE = ["JT_SQUARE",0];
hxClipper_JoinType.JT_SQUARE.toString = $estr;
hxClipper_JoinType.JT_SQUARE.__enum__ = hxClipper_JoinType;
hxClipper_JoinType.JT_ROUND = ["JT_ROUND",1];
hxClipper_JoinType.JT_ROUND.toString = $estr;
hxClipper_JoinType.JT_ROUND.__enum__ = hxClipper_JoinType;
hxClipper_JoinType.JT_MITER = ["JT_MITER",2];
hxClipper_JoinType.JT_MITER.toString = $estr;
hxClipper_JoinType.JT_MITER.__enum__ = hxClipper_JoinType;
var hxClipper_EndType = { __ename__ : ["hxClipper","EndType"], __constructs__ : ["ET_CLOSED_POLYGON","ET_CLOSED_LINE","ET_OPEN_BUTT","ET_OPEN_SQUARE","ET_OPEN_ROUND"] };
hxClipper_EndType.ET_CLOSED_POLYGON = ["ET_CLOSED_POLYGON",0];
hxClipper_EndType.ET_CLOSED_POLYGON.toString = $estr;
hxClipper_EndType.ET_CLOSED_POLYGON.__enum__ = hxClipper_EndType;
hxClipper_EndType.ET_CLOSED_LINE = ["ET_CLOSED_LINE",1];
hxClipper_EndType.ET_CLOSED_LINE.toString = $estr;
hxClipper_EndType.ET_CLOSED_LINE.__enum__ = hxClipper_EndType;
hxClipper_EndType.ET_OPEN_BUTT = ["ET_OPEN_BUTT",2];
hxClipper_EndType.ET_OPEN_BUTT.toString = $estr;
hxClipper_EndType.ET_OPEN_BUTT.__enum__ = hxClipper_EndType;
hxClipper_EndType.ET_OPEN_SQUARE = ["ET_OPEN_SQUARE",3];
hxClipper_EndType.ET_OPEN_SQUARE.toString = $estr;
hxClipper_EndType.ET_OPEN_SQUARE.__enum__ = hxClipper_EndType;
hxClipper_EndType.ET_OPEN_ROUND = ["ET_OPEN_ROUND",4];
hxClipper_EndType.ET_OPEN_ROUND.toString = $estr;
hxClipper_EndType.ET_OPEN_ROUND.__enum__ = hxClipper_EndType;
var hxClipper__$Clipper_EdgeSide = { __ename__ : ["hxClipper","_Clipper","EdgeSide"], __constructs__ : ["ES_LEFT","ES_RIGHT"] };
hxClipper__$Clipper_EdgeSide.ES_LEFT = ["ES_LEFT",0];
hxClipper__$Clipper_EdgeSide.ES_LEFT.toString = $estr;
hxClipper__$Clipper_EdgeSide.ES_LEFT.__enum__ = hxClipper__$Clipper_EdgeSide;
hxClipper__$Clipper_EdgeSide.ES_RIGHT = ["ES_RIGHT",1];
hxClipper__$Clipper_EdgeSide.ES_RIGHT.toString = $estr;
hxClipper__$Clipper_EdgeSide.ES_RIGHT.__enum__ = hxClipper__$Clipper_EdgeSide;
var hxClipper__$Clipper_Direction = { __ename__ : ["hxClipper","_Clipper","Direction"], __constructs__ : ["D_RIGHT_TO_LEFT","D_LEFT_TO_RIGHT"] };
hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT = ["D_RIGHT_TO_LEFT",0];
hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT.toString = $estr;
hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT.__enum__ = hxClipper__$Clipper_Direction;
hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT = ["D_LEFT_TO_RIGHT",1];
hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT.toString = $estr;
hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT.__enum__ = hxClipper__$Clipper_Direction;
var hxClipper__$Clipper_NodeType = { __ename__ : ["hxClipper","_Clipper","NodeType"], __constructs__ : ["NT_ANY","NT_OPEN","NT_CLOSED"] };
hxClipper__$Clipper_NodeType.NT_ANY = ["NT_ANY",0];
hxClipper__$Clipper_NodeType.NT_ANY.toString = $estr;
hxClipper__$Clipper_NodeType.NT_ANY.__enum__ = hxClipper__$Clipper_NodeType;
hxClipper__$Clipper_NodeType.NT_OPEN = ["NT_OPEN",1];
hxClipper__$Clipper_NodeType.NT_OPEN.toString = $estr;
hxClipper__$Clipper_NodeType.NT_OPEN.__enum__ = hxClipper__$Clipper_NodeType;
hxClipper__$Clipper_NodeType.NT_CLOSED = ["NT_CLOSED",2];
hxClipper__$Clipper_NodeType.NT_CLOSED.toString = $estr;
hxClipper__$Clipper_NodeType.NT_CLOSED.__enum__ = hxClipper__$Clipper_NodeType;
var hxClipper__$Clipper_TEdge = function() {
	this.delta = new hxClipper_IntPoint();
	this.top = new hxClipper_IntPoint();
	this.curr = new hxClipper_IntPoint();
	this.bot = new hxClipper_IntPoint();
};
hxClipper__$Clipper_TEdge.__name__ = ["hxClipper","_Clipper","TEdge"];
hxClipper__$Clipper_TEdge.prototype = {
	bot: null
	,curr: null
	,top: null
	,delta: null
	,dx: null
	,polyType: null
	,side: null
	,windDelta: null
	,windCnt: null
	,windCnt2: null
	,outIdx: null
	,next: null
	,prev: null
	,nextInLML: null
	,nextInAEL: null
	,prevInAEL: null
	,nextInSEL: null
	,prevInSEL: null
	,toString: function() {
		return "TE(curr:" + this.curr.toString() + ", bot:" + this.bot.toString() + ", top:" + this.top.toString() + ", dx:" + this.dx + ")";
	}
	,__class__: hxClipper__$Clipper_TEdge
};
var hxClipper_IntersectNode = function() {
	this.pt = new hxClipper_IntPoint();
};
hxClipper_IntersectNode.__name__ = ["hxClipper","IntersectNode"];
hxClipper_IntersectNode.prototype = {
	edge1: null
	,edge2: null
	,pt: null
	,__class__: hxClipper_IntersectNode
};
var hxClipper__$Clipper_LocalMinima = function() {
};
hxClipper__$Clipper_LocalMinima.__name__ = ["hxClipper","_Clipper","LocalMinima"];
hxClipper__$Clipper_LocalMinima.prototype = {
	y: null
	,leftBound: null
	,rightBound: null
	,next: null
	,__class__: hxClipper__$Clipper_LocalMinima
};
var hxClipper__$Clipper_Scanbeam = function() {
};
hxClipper__$Clipper_Scanbeam.__name__ = ["hxClipper","_Clipper","Scanbeam"];
hxClipper__$Clipper_Scanbeam.prototype = {
	y: null
	,next: null
	,__class__: hxClipper__$Clipper_Scanbeam
};
var hxClipper__$Clipper_Maxima = function() {
};
hxClipper__$Clipper_Maxima.__name__ = ["hxClipper","_Clipper","Maxima"];
hxClipper__$Clipper_Maxima.prototype = {
	x: null
	,next: null
	,prev: null
	,__class__: hxClipper__$Clipper_Maxima
};
var hxClipper__$Clipper_OutRec = function() {
};
hxClipper__$Clipper_OutRec.__name__ = ["hxClipper","_Clipper","OutRec"];
hxClipper__$Clipper_OutRec.prototype = {
	idx: null
	,isHole: null
	,isOpen: null
	,firstLeft: null
	,pts: null
	,bottomPt: null
	,polyNode: null
	,__class__: hxClipper__$Clipper_OutRec
};
var hxClipper__$Clipper_OutPt = function() {
	this.pt = new hxClipper_IntPoint();
};
hxClipper__$Clipper_OutPt.__name__ = ["hxClipper","_Clipper","OutPt"];
hxClipper__$Clipper_OutPt.prototype = {
	idx: null
	,pt: null
	,next: null
	,prev: null
	,__class__: hxClipper__$Clipper_OutPt
};
var hxClipper__$Clipper_Join = function() {
	this.offPt = new hxClipper_IntPoint();
};
hxClipper__$Clipper_Join.__name__ = ["hxClipper","_Clipper","Join"];
hxClipper__$Clipper_Join.prototype = {
	outPt1: null
	,outPt2: null
	,offPt: null
	,__class__: hxClipper__$Clipper_Join
};
var hxClipper_ClipperBase = function() {
	this.mEdges = [];
	this.mMinimaList = null;
	this.mCurrentLM = null;
	this.mUseFullRange = false;
	this.mHasOpenPaths = false;
};
hxClipper_ClipperBase.__name__ = ["hxClipper","ClipperBase"];
hxClipper_ClipperBase.nearZero = function(val) {
	return val > -1e-020 && val < 1.0E-20;
};
hxClipper_ClipperBase.isHorizontal = function(e) {
	return e.delta.y == 0;
};
hxClipper_ClipperBase.slopesEqual = function(e1,e2,useFullRange) {
	return e1.delta.y * e2.delta.x == e1.delta.x * e2.delta.y;
};
hxClipper_ClipperBase.slopesEqual3 = function(pt1,pt2,pt3,useFullRange) {
	return (pt1.y - pt2.y) * (pt2.x - pt3.x) - (pt1.x - pt2.x) * (pt2.y - pt3.y) == 0;
};
hxClipper_ClipperBase.slopesEqual4 = function(pt1,pt2,pt3,pt4,useFullRange) {
	return (pt1.y - pt2.y) * (pt3.x - pt4.x) - (pt1.x - pt2.x) * (pt3.y - pt4.y) == 0;
};
hxClipper_ClipperBase.getBounds = function(paths) {
	var i = 0;
	var cnt = paths.length;
	while(i < cnt && paths[i].length == 0) i++;
	if(i == cnt) return new hxClipper_IntRect(0,0,0,0);
	var result = new hxClipper_IntRect(0,0,0,0);
	result.left = paths[i][0].x;
	result.right = result.left;
	result.top = paths[i][0].y;
	result.bottom = result.top;
	while(i < cnt) {
		var _g1 = 0;
		var _g = paths[i].length;
		while(_g1 < _g) {
			var j = _g1++;
			if(paths[i][j].x < result.left) result.left = paths[i][j].x; else if(paths[i][j].x > result.right) result.right = paths[i][j].x;
			if(paths[i][j].y < result.top) result.top = paths[i][j].y; else if(paths[i][j].y > result.bottom) result.bottom = paths[i][j].y;
		}
		i++;
	}
	return result;
};
hxClipper_ClipperBase.prototype = {
	mMinimaList: null
	,mCurrentLM: null
	,mEdges: null
	,mUseFullRange: null
	,mHasOpenPaths: null
	,preserveCollinear: null
	,pointIsVertex: function(pt,pp) {
		var pp2 = pp;
		do {
			if(pp2.pt.equals(pt)) return true;
			pp2 = pp2.next;
		} while(pp2 != pp);
		return false;
	}
	,pointOnLineSegment: function(pt,linePt1,linePt2,useFullRange) {
		return pt.x == linePt1.x && pt.y == linePt1.y || pt.x == linePt2.x && pt.y == linePt2.y || pt.x > linePt1.x == pt.x < linePt2.x && pt.y > linePt1.y == pt.y < linePt2.y && (pt.x - linePt1.x) * (linePt2.y - linePt1.y) == (linePt2.x - linePt1.x) * (pt.y - linePt1.y);
	}
	,pointOnPolygon: function(pt,pp,useFullRange) {
		var pp2 = pp;
		while(true) {
			if(this.pointOnLineSegment(pt,pp2.pt,pp2.next.pt,useFullRange)) return true;
			pp2 = pp2.next;
			if(pp2 == pp) break;
		}
		return false;
	}
	,clear: function() {
		this.disposeLocalMinimaList();
		var _g1 = 0;
		var _g = this.mEdges.length;
		while(_g1 < _g) {
			var i = _g1++;
			var _g3 = 0;
			var _g2 = this.mEdges[i].length;
			while(_g3 < _g2) {
				var j = _g3++;
				this.mEdges[i][j] = null;
			}
			this.mEdges[i].length = 0;
		}
		this.mEdges.length = 0;
		this.mUseFullRange = false;
		this.mHasOpenPaths = false;
	}
	,disposeLocalMinimaList: function() {
		while(this.mMinimaList != null) {
			var tmpLm = this.mMinimaList.next;
			this.mMinimaList = null;
			this.mMinimaList = tmpLm;
		}
		this.mCurrentLM = null;
	}
	,rangeTest: function(pt,useFullRange) {
		if(useFullRange) {
			if(pt.x > 32767 || pt.y > 32767 || -pt.x > 32767 || -pt.y > 32767) throw new js__$Boot_HaxeError(new hxClipper_ClipperException("Coordinate outside allowed range"));
		} else if(pt.x > 32767 || pt.y > 32767 || -pt.x > 32767 || -pt.y > 32767) {
			useFullRange = true;
			this.rangeTest(pt,useFullRange);
		}
		return useFullRange;
	}
	,initEdge: function(e,eNext,ePrev,pt) {
		e.next = eNext;
		e.prev = ePrev;
		e.curr.copyFrom(pt);
		e.outIdx = -1;
	}
	,initEdge2: function(e,polyType) {
		if(e.curr.y >= e.next.curr.y) {
			e.bot.copyFrom(e.curr);
			e.top.copyFrom(e.next.curr);
		} else {
			e.top.copyFrom(e.curr);
			e.bot.copyFrom(e.next.curr);
		}
		this.setDx(e);
		e.polyType = polyType;
	}
	,findNextLocMin: function(e) {
		var e2;
		while(true) {
			while(!e.bot.equals(e.prev.bot) || e.curr.equals(e.top)) e = e.next;
			if(e.dx != -3.4E+38 && e.prev.dx != -3.4E+38) break;
			while(e.prev.dx == -3.4E+38) e = e.prev;
			e2 = e;
			while(e.dx == -3.4E+38) e = e.next;
			if(e.top.y == e.prev.bot.y) continue;
			if(e2.prev.bot.x < e.bot.x) e = e2;
			break;
		}
		return e;
	}
	,processBound: function(e,leftBoundIsForward) {
		var eStart;
		var result = e;
		var horz;
		if(result.outIdx == -2) {
			e = result;
			if(leftBoundIsForward) {
				while(e.top.y == e.next.bot.y) e = e.next;
				while(e != result && e.dx == -3.4E+38) e = e.prev;
			} else {
				while(e.top.y == e.prev.bot.y) e = e.prev;
				while(e != result && e.dx == -3.4E+38) e = e.next;
			}
			if(e == result) {
				if(leftBoundIsForward) result = e.next; else result = e.prev;
			} else {
				if(leftBoundIsForward) e = result.next; else e = result.prev;
				var locMin = new hxClipper__$Clipper_LocalMinima();
				locMin.next = null;
				locMin.y = e.bot.y;
				locMin.leftBound = null;
				locMin.rightBound = e;
				e.windDelta = 0;
				result = this.processBound(e,leftBoundIsForward);
				this.insertLocalMinima(locMin);
			}
			return result;
		}
		if(e.dx == -3.4E+38) {
			if(leftBoundIsForward) eStart = e.prev; else eStart = e.next;
			if(eStart.dx == -3.4E+38) {
				if(eStart.bot.x != e.bot.x && eStart.top.x != e.bot.x) this.reverseHorizontal(e);
			} else if(eStart.bot.x != e.bot.x) this.reverseHorizontal(e);
		}
		eStart = e;
		if(leftBoundIsForward) {
			while(result.top.y == result.next.bot.y && result.next.outIdx != -2) result = result.next;
			if(result.dx == -3.4E+38 && result.next.outIdx != -2) {
				horz = result;
				while(horz.prev.dx == -3.4E+38) horz = horz.prev;
				if(horz.prev.top.x > result.next.top.x) result = horz.prev;
			}
			while(e != result) {
				e.nextInLML = e.next;
				if(e.dx == -3.4E+38 && e != eStart && e.bot.x != e.prev.top.x) this.reverseHorizontal(e);
				e = e.next;
			}
			if(e.dx == -3.4E+38 && e != eStart && e.bot.x != e.prev.top.x) this.reverseHorizontal(e);
			result = result.next;
		} else {
			while(result.top.y == result.prev.bot.y && result.prev.outIdx != -2) result = result.prev;
			if(result.dx == -3.4E+38 && result.prev.outIdx != -2) {
				horz = result;
				while(horz.next.dx == -3.4E+38) horz = horz.next;
				if(horz.next.top.x == result.prev.top.x || horz.next.top.x > result.prev.top.x) result = horz.next;
			}
			while(e != result) {
				e.nextInLML = e.prev;
				if(e.dx == -3.4E+38 && e != eStart && e.bot.x != e.next.top.x) this.reverseHorizontal(e);
				e = e.prev;
			}
			if(e.dx == -3.4E+38 && e != eStart && e.bot.x != e.next.top.x) this.reverseHorizontal(e);
			result = result.prev;
		}
		return result;
	}
	,addPath: function(path,polyType,closed) {
		if(!closed) throw new js__$Boot_HaxeError(new hxClipper_ClipperException("AddPath: Open paths have been disabled (define USE_LINES to enable them)."));
		var highI = path.length - 1;
		if(closed) while(highI > 0 && path[highI].equals(path[0])) --highI;
		while(highI > 0 && path[highI].equals(path[highI - 1])) --highI;
		if(closed && highI < 2 || !closed && highI < 1) return false;
		var edges = [];
		var _g1 = 0;
		var _g = highI + 1;
		while(_g1 < _g) {
			var i1 = _g1++;
			edges.push(new hxClipper__$Clipper_TEdge());
		}
		var isFlat = true;
		edges[1].curr.copyFrom(path[1]);
		this.mUseFullRange = this.rangeTest(path[0],this.mUseFullRange);
		this.mUseFullRange = this.rangeTest(path[highI],this.mUseFullRange);
		this.initEdge(edges[0],edges[1],edges[highI],path[0]);
		this.initEdge(edges[highI],edges[0],edges[highI - 1],path[highI]);
		var i = highI - 1;
		while(i >= 1) {
			this.mUseFullRange = this.rangeTest(path[i],this.mUseFullRange);
			this.initEdge(edges[i],edges[i + 1],edges[i - 1],path[i]);
			--i;
		}
		var eStart = edges[0];
		var e = eStart;
		var eLoopStop = eStart;
		while(true) {
			if(e.curr.equals(e.next.curr) && (closed || e.next != eStart)) {
				if(e == e.next) break;
				if(e == eStart) eStart = e.next;
				e = this.removeEdge(e);
				eLoopStop = e;
				continue;
			}
			if(e.prev == e.next) break; else if(closed && hxClipper_ClipperBase.slopesEqual3(e.prev.curr,e.curr,e.next.curr,this.mUseFullRange) && (!this.preserveCollinear || !this.pt2IsBetweenPt1AndPt3(e.prev.curr,e.curr,e.next.curr))) {
				if(e == eStart) eStart = e.next;
				e = this.removeEdge(e);
				e = e.prev;
				eLoopStop = e;
				continue;
			}
			e = e.next;
			if(e == eLoopStop || !closed && e.next == eStart) break;
		}
		if(!closed && e == e.next || closed && e.prev == e.next) return false;
		if(!closed) {
			this.mHasOpenPaths = true;
			eStart.prev.outIdx = -2;
		}
		e = eStart;
		do {
			this.initEdge2(e,polyType);
			e = e.next;
			if(isFlat && e.curr.y != eStart.curr.y) isFlat = false;
		} while(e != eStart);
		if(isFlat) {
			if(closed) return false;
			e.prev.outIdx = -2;
			var locMin = new hxClipper__$Clipper_LocalMinima();
			locMin.next = null;
			locMin.y = e.bot.y;
			locMin.leftBound = null;
			locMin.rightBound = e;
			locMin.rightBound.side = hxClipper__$Clipper_EdgeSide.ES_RIGHT;
			locMin.rightBound.windDelta = 0;
			while(true) {
				if(e.bot.x != e.prev.top.x) this.reverseHorizontal(e);
				if(e.next.outIdx == -2) break;
				e.nextInLML = e.next;
				e = e.next;
			}
			this.insertLocalMinima(locMin);
			this.mEdges.push(edges);
			return true;
		}
		this.mEdges.push(edges);
		var leftBoundIsForward;
		var eMin = null;
		if(e.prev.bot.equals(e.prev.top)) e = e.next;
		while(true) {
			e = this.findNextLocMin(e);
			if(e == eMin) break; else if(eMin == null) eMin = e;
			var locMin1 = new hxClipper__$Clipper_LocalMinima();
			locMin1.next = null;
			locMin1.y = e.bot.y;
			if(e.dx < e.prev.dx) {
				locMin1.leftBound = e.prev;
				locMin1.rightBound = e;
				leftBoundIsForward = false;
			} else {
				locMin1.leftBound = e;
				locMin1.rightBound = e.prev;
				leftBoundIsForward = true;
			}
			locMin1.leftBound.side = hxClipper__$Clipper_EdgeSide.ES_LEFT;
			locMin1.rightBound.side = hxClipper__$Clipper_EdgeSide.ES_RIGHT;
			if(!closed) locMin1.leftBound.windDelta = 0; else if(locMin1.leftBound.next == locMin1.rightBound) locMin1.leftBound.windDelta = -1; else locMin1.leftBound.windDelta = 1;
			locMin1.rightBound.windDelta = -locMin1.leftBound.windDelta;
			e = this.processBound(locMin1.leftBound,leftBoundIsForward);
			if(e.outIdx == -2) e = this.processBound(e,leftBoundIsForward);
			var E2 = this.processBound(locMin1.rightBound,!leftBoundIsForward);
			if(E2.outIdx == -2) E2 = this.processBound(E2,!leftBoundIsForward);
			if(locMin1.leftBound.outIdx == -2) locMin1.leftBound = null; else if(locMin1.rightBound.outIdx == -2) locMin1.rightBound = null;
			this.insertLocalMinima(locMin1);
			if(!leftBoundIsForward) e = E2;
		}
		return true;
	}
	,addPaths: function(paths,polyType,closed) {
		var result = false;
		var _g1 = 0;
		var _g = paths.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(this.addPath(paths[i],polyType,closed)) result = true;
		}
		return result;
	}
	,pt2IsBetweenPt1AndPt3: function(pt1,pt2,pt3) {
		if(pt1.equals(pt3) || pt1.equals(pt2) || pt3.equals(pt2)) return false; else if(pt1.x != pt3.x) return pt2.x > pt1.x == pt2.x < pt3.x; else return pt2.y > pt1.y == pt2.y < pt3.y;
	}
	,removeEdge: function(e) {
		e.prev.next = e.next;
		e.next.prev = e.prev;
		var result = e.next;
		e.prev = null;
		return result;
	}
	,setDx: function(e) {
		e.delta.x = e.top.x - e.bot.x;
		e.delta.y = e.top.y - e.bot.y;
		if(e.delta.y == 0) e.dx = -3.4E+38; else {
			var deltaX = e.delta.x;
			e.dx = deltaX / e.delta.y;
		}
	}
	,insertLocalMinima: function(newLm) {
		if(this.mMinimaList == null) this.mMinimaList = newLm; else if(newLm.y >= this.mMinimaList.y) {
			newLm.next = this.mMinimaList;
			this.mMinimaList = newLm;
		} else {
			var tmpLm = this.mMinimaList;
			while(tmpLm.next != null && newLm.y < tmpLm.next.y) tmpLm = tmpLm.next;
			newLm.next = tmpLm.next;
			tmpLm.next = newLm;
		}
	}
	,popLocalMinima: function() {
		if(this.mCurrentLM == null) return;
		this.mCurrentLM = this.mCurrentLM.next;
	}
	,reverseHorizontal: function(e) {
		var tmp = e.top.x;
		e.top.x = e.bot.x;
		e.bot.x = tmp;
	}
	,reset: function() {
		this.mCurrentLM = this.mMinimaList;
		if(this.mCurrentLM == null) return;
		var lm = this.mMinimaList;
		while(lm != null) {
			var e = lm.leftBound;
			if(e != null) {
				e.curr.copyFrom(e.bot);
				e.side = hxClipper__$Clipper_EdgeSide.ES_LEFT;
				e.outIdx = -1;
			}
			e = lm.rightBound;
			if(e != null) {
				e.curr.copyFrom(e.bot);
				e.side = hxClipper__$Clipper_EdgeSide.ES_RIGHT;
				e.outIdx = -1;
			}
			lm = lm.next;
		}
	}
	,__class__: hxClipper_ClipperBase
};
var hxClipper_Clipper = function(initOptions) {
	if(initOptions == null) initOptions = 0;
	hxClipper_ClipperBase.call(this);
	this.mScanbeam = null;
	this.mMaxima = null;
	this.mActiveEdges = null;
	this.mSortedEdges = null;
	this.mIntersectList = [];
	this.mIntersectNodeComparer = hxClipper_Clipper.compare;
	this.mExecuteLocked = false;
	this.mUsingPolyTree = false;
	this.mPolyOuts = [];
	this.mJoins = [];
	this.mGhostJoins = [];
	this.reverseSolution = (1 & initOptions) != 0;
	this.strictlySimple = (2 & initOptions) != 0;
	this.preserveCollinear = (4 & initOptions) != 0;
};
hxClipper_Clipper.__name__ = ["hxClipper","Clipper"];
hxClipper_Clipper.compare = function(node1,node2) {
	var i = node2.pt.y - node1.pt.y;
	if(i > 0) return 1; else if(i < 0) return -1; else return 0;
};
hxClipper_Clipper.swapSides = function(edge1,edge2) {
	var side = edge1.side;
	edge1.side = edge2.side;
	edge2.side = side;
};
hxClipper_Clipper.swapPolyIndexes = function(edge1,edge2) {
	var outIdx = edge1.outIdx;
	edge1.outIdx = edge2.outIdx;
	edge2.outIdx = outIdx;
};
hxClipper_Clipper.intersectNodeSort = function(node1,node2) {
	return node2.pt.y - node1.pt.y | 0;
};
hxClipper_Clipper.round = function(value) {
	if(value < 0) return value - 0.5 | 0; else return value + 0.5 | 0;
};
hxClipper_Clipper.topX = function(edge,currentY) {
	if(currentY == edge.top.y) return edge.top.x;
	return edge.bot.x + hxClipper_Clipper.round(edge.dx * (currentY - edge.bot.y));
};
hxClipper_Clipper.reversePaths = function(polys) {
	var _g = 0;
	while(_g < polys.length) {
		var poly = polys[_g];
		++_g;
		poly.reverse();
	}
};
hxClipper_Clipper.orientation = function(poly) {
	return hxClipper_Clipper.area(poly) >= 0;
};
hxClipper_Clipper.pointInPolygon = function(pt,path) {
	var result = 0;
	var cnt = path.length;
	if(cnt < 3) return 0;
	var ip = path[0].clone();
	var ipNext = new hxClipper_IntPoint();
	var _g1 = 1;
	var _g = cnt + 1;
	while(_g1 < _g) {
		var i = _g1++;
		ipNext.copyFrom(i == cnt?path[0]:path[i]);
		if(ipNext.y == pt.y) {
			if(ipNext.x == pt.x || ip.y == pt.y && ipNext.x > pt.x == ip.x < pt.x) return -1;
		}
		if(ip.y < pt.y != ipNext.y < pt.y) {
			if(ip.x >= pt.x) {
				if(ipNext.x > pt.x) result = 1 - result; else {
					var dx = ip.x - pt.x;
					var dy = ip.y - pt.y;
					var d = dx * (ipNext.y - pt.y) - (ipNext.x - pt.x) * dy;
					if(d == 0) return -1; else if(d > 0 == ipNext.y > ip.y) result = 1 - result;
				}
			} else if(ipNext.x > pt.x) {
				var dx1 = ip.x - pt.x;
				var dy1 = ip.y - pt.y;
				var d1 = dx1 * (ipNext.y - pt.y) - (ipNext.x - pt.x) * dy1;
				if(d1 == 0) return -1; else if(d1 > 0 == ipNext.y > ip.y) result = 1 - result;
			}
		}
		ip.copyFrom(ipNext);
	}
	return result;
};
hxClipper_Clipper.pointInOutPt = function(pt,op) {
	var result = 0;
	var startOp = op;
	var ptx = pt.x;
	var pty = pt.y;
	var poly0x = op.pt.x;
	var poly0y = op.pt.y;
	do {
		op = op.next;
		var poly1x = op.pt.x;
		var poly1y = op.pt.y;
		if(poly1y == pty) {
			if(poly1x == ptx || poly0y == pty && poly1x > ptx == poly0x < ptx) return -1;
		}
		if(poly0y < pty != poly1y < pty) {
			if(poly0x >= ptx) {
				if(poly1x > ptx) result = 1 - result; else {
					var dx = poly0x - ptx;
					var dy = poly0y - pty;
					var d = dx * (poly1y - pty) - (poly1x - ptx) * dy;
					if(d == 0) return -1;
					if(d > 0 == poly1y > poly0y) result = 1 - result;
				}
			} else if(poly1x > ptx) {
				var dx1 = poly0x - ptx;
				var dy1 = poly0y - pty;
				var d1 = dx1 * (poly1y - pty) - (poly1x - ptx) * dy1;
				if(d1 == 0) return -1;
				if(d1 > 0 == poly1y > poly0y) result = 1 - result;
			}
		}
		poly0x = poly1x;
		poly0y = poly1y;
	} while(startOp != op);
	return result;
};
hxClipper_Clipper.poly2ContainsPoly1 = function(outPt1,outPt2) {
	var op = outPt1;
	do {
		var res = hxClipper_Clipper.pointInOutPt(op.pt,outPt2);
		if(res >= 0) return res > 0;
		op = op.next;
	} while(op != outPt1);
	return true;
};
hxClipper_Clipper.parseFirstLeft = function(firstLeft) {
	while(firstLeft != null && firstLeft.pts == null) firstLeft = firstLeft.firstLeft;
	return firstLeft;
};
hxClipper_Clipper.area = function(poly) {
	if(poly == null || poly.length < 3) return 0;
	var cnt = poly.length;
	var a = 0;
	var j = cnt - 1;
	var _g = 0;
	while(_g < cnt) {
		var i = _g++;
		var dx = poly[j].x + poly[i].x;
		var dy = poly[j].y - poly[i].y;
		a += dx * dy;
		j = i;
	}
	return -a * 0.5;
};
hxClipper_Clipper.simplifyPolygon = function(poly,fillType) {
	if(fillType == null) fillType = hxClipper_PolyFillType.PFT_EVEN_ODD;
	var result = [];
	var c = new hxClipper_Clipper();
	c.strictlySimple = true;
	c.addPath(poly,hxClipper_PolyType.PT_SUBJECT,true);
	c.executePaths(hxClipper_ClipType.CT_UNION,result,fillType,fillType);
	return result;
};
hxClipper_Clipper.simplifyPolygons = function(polys,fillType) {
	if(fillType == null) fillType = hxClipper_PolyFillType.PFT_EVEN_ODD;
	var result = [];
	var c = new hxClipper_Clipper();
	c.strictlySimple = true;
	c.addPaths(polys,hxClipper_PolyType.PT_SUBJECT,true);
	c.executePaths(hxClipper_ClipType.CT_UNION,result,fillType,fillType);
	return result;
};
hxClipper_Clipper.distanceSqrd = function(pt1,pt2) {
	var dx = pt1.x - pt2.x;
	var dy = pt1.y - pt2.y;
	return dx * dx + dy * dy;
};
hxClipper_Clipper.distanceFromLineSqrd = function(pt,ln1,ln2) {
	var A = ln1.y - ln2.y;
	var B = ln2.x - ln1.x;
	var C = A * ln1.x + B * ln1.y;
	C = A * pt.x + B * pt.y - C;
	return C * C / (A * A + B * B);
};
hxClipper_Clipper.slopesNearCollinear = function(pt1,pt2,pt3,distSqrd) {
	if(Math.abs(pt1.x - pt2.x) > Math.abs(pt1.y - pt2.y)) {
		if(pt1.x > pt2.x == pt1.x < pt3.x) return hxClipper_Clipper.distanceFromLineSqrd(pt1,pt2,pt3) < distSqrd; else if(pt2.x > pt1.x == pt2.x < pt3.x) return hxClipper_Clipper.distanceFromLineSqrd(pt2,pt1,pt3) < distSqrd; else return hxClipper_Clipper.distanceFromLineSqrd(pt3,pt1,pt2) < distSqrd;
	} else if(pt1.y > pt2.y == pt1.y < pt3.y) return hxClipper_Clipper.distanceFromLineSqrd(pt1,pt2,pt3) < distSqrd; else if(pt2.y > pt1.y == pt2.y < pt3.y) return hxClipper_Clipper.distanceFromLineSqrd(pt2,pt1,pt3) < distSqrd; else return hxClipper_Clipper.distanceFromLineSqrd(pt3,pt1,pt2) < distSqrd;
};
hxClipper_Clipper.pointsAreClose = function(pt1,pt2,distSqrd) {
	var dx = pt1.x - pt2.x;
	var dy = pt1.y - pt2.y;
	return dx * dx + dy * dy <= distSqrd;
};
hxClipper_Clipper.excludeOp = function(op) {
	var result = op.prev;
	result.next = op.next;
	op.next.prev = result;
	result.idx = 0;
	return result;
};
hxClipper_Clipper.cleanPolygon = function(path,distance) {
	if(distance == null) distance = 1.415;
	var cnt = path.length;
	if(cnt == 0) return [];
	var outPts;
	var _g = [];
	var _g1 = 0;
	while(_g1 < cnt) {
		var i = _g1++;
		_g.push(new hxClipper__$Clipper_OutPt());
	}
	outPts = _g;
	var _g11 = 0;
	while(_g11 < cnt) {
		var i1 = _g11++;
		outPts[i1].pt.copyFrom(path[i1]);
		outPts[i1].next = outPts[(i1 + 1) % cnt];
		outPts[i1].next.prev = outPts[i1];
		outPts[i1].idx = 0;
	}
	var distSqrd = distance * distance;
	var op = outPts[0];
	while(op.idx == 0 && op.next != op.prev) if(hxClipper_Clipper.pointsAreClose(op.pt,op.prev.pt,distSqrd)) {
		op = hxClipper_Clipper.excludeOp(op);
		cnt--;
	} else if(hxClipper_Clipper.pointsAreClose(op.prev.pt,op.next.pt,distSqrd)) {
		hxClipper_Clipper.excludeOp(op.next);
		op = hxClipper_Clipper.excludeOp(op);
		cnt -= 2;
	} else if(hxClipper_Clipper.slopesNearCollinear(op.prev.pt,op.pt,op.next.pt,distSqrd)) {
		op = hxClipper_Clipper.excludeOp(op);
		cnt--;
	} else {
		op.idx = 1;
		op = op.next;
	}
	if(cnt < 3) cnt = 0;
	var result = [];
	var _g12 = 0;
	while(_g12 < cnt) {
		var i2 = _g12++;
		result.push(op.pt);
		op = op.next;
	}
	outPts = null;
	return result;
};
hxClipper_Clipper.cleanPolygons = function(polys,distance) {
	if(distance == null) distance = 1.415;
	var result = [];
	var _g1 = 0;
	var _g = polys.length;
	while(_g1 < _g) {
		var i = _g1++;
		result.push(hxClipper_Clipper.cleanPolygon(polys[i],distance));
	}
	return result;
};
hxClipper_Clipper.minkowski = function(pattern,path,isSum,isClosed) {
	var delta;
	if(isClosed) delta = 1; else delta = 0;
	var polyCnt = pattern.length;
	var pathCnt = path.length;
	var result = [];
	if(isSum) {
		var _g = 0;
		while(_g < pathCnt) {
			var i = _g++;
			var p = [];
			var _g1 = 0;
			while(_g1 < pattern.length) {
				var ip = pattern[_g1];
				++_g1;
				p.push(new hxClipper_IntPoint(path[i].x + ip.x,path[i].y + ip.y));
			}
			result.push(p);
		}
	} else {
		var _g2 = 0;
		while(_g2 < pathCnt) {
			var i1 = _g2++;
			var p1 = [];
			var _g11 = 0;
			while(_g11 < pattern.length) {
				var ip1 = pattern[_g11];
				++_g11;
				p1.push(new hxClipper_IntPoint(path[i1].x - ip1.x,path[i1].y - ip1.y));
			}
			result.push(p1);
		}
	}
	var quads = [];
	var _g12 = 0;
	var _g3 = pathCnt - 1 + delta;
	while(_g12 < _g3) {
		var i2 = _g12++;
		var _g21 = 0;
		while(_g21 < polyCnt) {
			var j = _g21++;
			var quad = [];
			quad.push(result[i2 % pathCnt][j % polyCnt]);
			quad.push(result[(i2 + 1) % pathCnt][j % polyCnt]);
			quad.push(result[(i2 + 1) % pathCnt][(j + 1) % polyCnt]);
			quad.push(result[i2 % pathCnt][(j + 1) % polyCnt]);
			if(!hxClipper_Clipper.orientation(quad)) quad.reverse();
			quads.push(quad);
		}
	}
	return quads;
};
hxClipper_Clipper.minkowskiSum = function(pattern,path,pathIsClosed) {
	var paths = hxClipper_Clipper.minkowski(pattern,path,true,pathIsClosed);
	var c = new hxClipper_Clipper();
	c.addPaths(paths,hxClipper_PolyType.PT_SUBJECT,true);
	c.executePaths(hxClipper_ClipType.CT_UNION,paths,hxClipper_PolyFillType.PFT_NON_ZERO,hxClipper_PolyFillType.PFT_NON_ZERO);
	return paths;
};
hxClipper_Clipper.translatePath = function(path,delta) {
	var outPath = [];
	var _g1 = 0;
	var _g = path.length;
	while(_g1 < _g) {
		var i = _g1++;
		outPath.push(new hxClipper_IntPoint(path[i].x + delta.x,path[i].y + delta.y));
	}
	return outPath;
};
hxClipper_Clipper.minkowskiSumPaths = function(pattern,paths,pathIsClosed) {
	var solution = [];
	var c = new hxClipper_Clipper();
	var _g1 = 0;
	var _g = paths.length;
	while(_g1 < _g) {
		var i = _g1++;
		var tmp = hxClipper_Clipper.minkowski(pattern,paths[i],true,pathIsClosed);
		c.addPaths(tmp,hxClipper_PolyType.PT_SUBJECT,true);
		if(pathIsClosed) {
			var path = hxClipper_Clipper.translatePath(paths[i],pattern[0]);
			c.addPath(path,hxClipper_PolyType.PT_CLIP,true);
		}
	}
	c.executePaths(hxClipper_ClipType.CT_UNION,solution,hxClipper_PolyFillType.PFT_NON_ZERO,hxClipper_PolyFillType.PFT_NON_ZERO);
	return solution;
};
hxClipper_Clipper.minkowskiDiff = function(poly1,poly2) {
	var paths = hxClipper_Clipper.minkowski(poly1,poly2,false,true);
	var c = new hxClipper_Clipper();
	c.addPaths(paths,hxClipper_PolyType.PT_SUBJECT,true);
	c.executePaths(hxClipper_ClipType.CT_UNION,paths,hxClipper_PolyFillType.PFT_NON_ZERO,hxClipper_PolyFillType.PFT_NON_ZERO);
	return paths;
};
hxClipper_Clipper.polyTreeToPaths = function(polytree) {
	var result = [];
	hxClipper_Clipper.addPolyNodeToPaths(polytree,hxClipper__$Clipper_NodeType.NT_ANY,result);
	return result;
};
hxClipper_Clipper.addPolyNodeToPaths = function(polynode,nt,paths) {
	var match = true;
	switch(nt[1]) {
	case 1:
		return;
	case 2:
		match = !polynode.isOpen;
		break;
	default:
	}
	if(polynode.mPolygon.length > 0 && match) paths.push(polynode.mPolygon);
	var _g = 0;
	var _g1 = polynode.get_children();
	while(_g < _g1.length) {
		var pn = _g1[_g];
		++_g;
		hxClipper_Clipper.addPolyNodeToPaths(pn,nt,paths);
	}
};
hxClipper_Clipper.openPathsFromPolyTree = function(polytree) {
	var result = [];
	var _g1 = 0;
	var _g = polytree.get_numChildren();
	while(_g1 < _g) {
		var i = _g1++;
		if(polytree.get_children()[i].isOpen) result.push(polytree.get_children()[i].mPolygon);
	}
	return result;
};
hxClipper_Clipper.closedPathsFromPolyTree = function(polytree) {
	var result = [];
	hxClipper_Clipper.addPolyNodeToPaths(polytree,hxClipper__$Clipper_NodeType.NT_CLOSED,result);
	return result;
};
hxClipper_Clipper.__super__ = hxClipper_ClipperBase;
hxClipper_Clipper.prototype = $extend(hxClipper_ClipperBase.prototype,{
	mPolyOuts: null
	,mClipType: null
	,mScanbeam: null
	,mMaxima: null
	,mActiveEdges: null
	,mSortedEdges: null
	,mIntersectList: null
	,mIntersectNodeComparer: null
	,mExecuteLocked: null
	,mClipFillType: null
	,mSubjFillType: null
	,mJoins: null
	,mGhostJoins: null
	,mUsingPolyTree: null
	,insertScanbeam: function(y) {
		if(this.mScanbeam == null) {
			this.mScanbeam = new hxClipper__$Clipper_Scanbeam();
			this.mScanbeam.next = null;
			this.mScanbeam.y = y;
		} else if(y > this.mScanbeam.y) {
			var newSb = new hxClipper__$Clipper_Scanbeam();
			newSb.y = y;
			newSb.next = this.mScanbeam;
			this.mScanbeam = newSb;
		} else {
			var sb2 = this.mScanbeam;
			while(sb2.next != null && y <= sb2.next.y) sb2 = sb2.next;
			if(y == sb2.y) return;
			var newSb1 = new hxClipper__$Clipper_Scanbeam();
			newSb1.y = y;
			newSb1.next = sb2.next;
			sb2.next = newSb1;
		}
	}
	,insertMaxima: function(x) {
		var newMax = new hxClipper__$Clipper_Maxima();
		newMax.x = x;
		if(this.mMaxima == null) {
			this.mMaxima = newMax;
			this.mMaxima.next = null;
			this.mMaxima.prev = null;
		} else if(x < this.mMaxima.x) {
			newMax.next = this.mMaxima;
			newMax.prev = null;
			this.mMaxima = newMax;
		} else {
			var m = this.mMaxima;
			while(m.next != null && x >= m.next.x) m = m.next;
			if(x == m.x) return;
			newMax.next = m.next;
			newMax.prev = m;
			if(m.next != null) m.next.prev = newMax;
			m.next = newMax;
		}
	}
	,reset: function() {
		hxClipper_ClipperBase.prototype.reset.call(this);
		this.mScanbeam = null;
		this.mActiveEdges = null;
		this.mSortedEdges = null;
		var lm = this.mMinimaList;
		while(lm != null) {
			this.insertScanbeam(lm.y);
			lm = lm.next;
		}
	}
	,reverseSolution: null
	,strictlySimple: null
	,executePaths: function(clipType,solution,subjFillType,clipFillType) {
		if(this.mExecuteLocked) return false;
		if(this.mHasOpenPaths) throw new js__$Boot_HaxeError(new hxClipper_ClipperException("Error: PolyTree struct is needed for open path clipping."));
		this.mExecuteLocked = true;
		solution.length = 0;
		this.mSubjFillType = subjFillType;
		this.mClipFillType = clipFillType;
		this.mClipType = clipType;
		this.mUsingPolyTree = false;
		var succeeded = false;
		succeeded = this.executeInternal();
		if(succeeded) this.buildResult(solution);
		this.disposeAllPolyPts();
		this.mExecuteLocked = false;
		this.mJoins.length = 0;
		this.mGhostJoins.length = 0;
		return succeeded;
	}
	,executePolyTree: function(clipType,polytree,subjFillType,clipFillType) {
		if(this.mExecuteLocked) return false;
		this.mExecuteLocked = true;
		this.mSubjFillType = subjFillType;
		this.mClipFillType = clipFillType;
		this.mClipType = clipType;
		this.mUsingPolyTree = true;
		var succeeded = false;
		succeeded = this.executeInternal();
		if(succeeded) this.buildResult2(polytree);
		this.disposeAllPolyPts();
		this.mExecuteLocked = false;
		this.mJoins.length = 0;
		this.mGhostJoins.length = 0;
		return succeeded;
	}
	,execute: function(clipType,solution) {
		if((solution instanceof Array) && solution.__enum__ == null) return this.executePaths(clipType,solution,hxClipper_PolyFillType.PFT_EVEN_ODD,hxClipper_PolyFillType.PFT_EVEN_ODD); else if(js_Boot.__instanceof(solution,hxClipper_PolyTree)) return this.executePolyTree(clipType,solution,hxClipper_PolyFillType.PFT_EVEN_ODD,hxClipper_PolyFillType.PFT_EVEN_ODD); else throw new js__$Boot_HaxeError(new hxClipper_ClipperException("`solution` must be either a Paths or a PolyTree"));
	}
	,fixHoleLinkage: function(outRec) {
		if(outRec.firstLeft == null || outRec.isHole != outRec.firstLeft.isHole && outRec.firstLeft.pts != null) return;
		var orfl = outRec.firstLeft;
		while(orfl != null && (orfl.isHole == outRec.isHole || orfl.pts == null)) orfl = orfl.firstLeft;
		outRec.firstLeft = orfl;
	}
	,executeInternal: function() {
		this.reset();
		if(this.mCurrentLM == null) return false;
		var botY = this.popScanbeam();
		do {
			this.insertLocalMinimaIntoAEL(botY);
			this.processHorizontals();
			this.mGhostJoins.length = 0;
			if(this.mScanbeam == null) break;
			var topY = this.popScanbeam();
			if(!this.processIntersections(topY)) return false;
			this.processEdgesAtTopOfScanbeam(topY);
			botY = topY;
		} while(this.mScanbeam != null || this.mCurrentLM != null);
		var _g1 = 0;
		var _g = this.mPolyOuts.length;
		while(_g1 < _g) {
			var i = _g1++;
			var outRec = this.mPolyOuts[i];
			if(outRec.pts == null || outRec.isOpen) continue;
			if(hxClipper_InternalTools.xor(outRec.isHole,this.reverseSolution) == this.areaOfOutRec(outRec) > 0) this.reversePolyPtLinks(outRec.pts);
		}
		this.joinCommonEdges();
		var _g11 = 0;
		var _g2 = this.mPolyOuts.length;
		while(_g11 < _g2) {
			var i1 = _g11++;
			var outRec1 = this.mPolyOuts[i1];
			if(outRec1.pts == null) continue; else if(outRec1.isOpen) this.fixupOutPolyLine(outRec1); else this.fixupOutPolygon(outRec1);
		}
		if(this.strictlySimple) this.doSimplePolygons();
		return true;
	}
	,popScanbeam: function() {
		var y = this.mScanbeam.y;
		this.mScanbeam = this.mScanbeam.next;
		return y;
	}
	,disposeAllPolyPts: function() {
		var _g1 = 0;
		var _g = this.mPolyOuts.length;
		while(_g1 < _g) {
			var i = _g1++;
			this.disposeOutRec(i);
		}
		this.mPolyOuts.length = 0;
	}
	,disposeOutRec: function(index) {
		var outRec = this.mPolyOuts[index];
		outRec.pts = null;
		outRec = null;
		this.mPolyOuts[index] = null;
	}
	,addJoin: function(op1,op2,offPt) {
		var j = new hxClipper__$Clipper_Join();
		j.outPt1 = op1;
		j.outPt2 = op2;
		j.offPt.copyFrom(offPt);
		this.mJoins.push(j);
	}
	,addGhostJoin: function(op,offPt) {
		var j = new hxClipper__$Clipper_Join();
		j.outPt1 = op;
		j.offPt.copyFrom(offPt);
		this.mGhostJoins.push(j);
	}
	,insertLocalMinimaIntoAEL: function(botY) {
		while(this.mCurrentLM != null && this.mCurrentLM.y == botY) {
			var lb = this.mCurrentLM.leftBound;
			var rb = this.mCurrentLM.rightBound;
			this.popLocalMinima();
			var op1 = null;
			if(lb == null) {
				this.insertEdgeIntoAEL(rb,null);
				this.setWindingCount(rb);
				if(this.isContributing(rb)) op1 = this.addOutPt(rb,rb.bot);
			} else if(rb == null) {
				this.insertEdgeIntoAEL(lb,null);
				this.setWindingCount(lb);
				if(this.isContributing(lb)) op1 = this.addOutPt(lb,lb.bot);
				this.insertScanbeam(lb.top.y);
			} else {
				this.insertEdgeIntoAEL(lb,null);
				this.insertEdgeIntoAEL(rb,lb);
				this.setWindingCount(lb);
				rb.windCnt = lb.windCnt;
				rb.windCnt2 = lb.windCnt2;
				if(this.isContributing(lb)) op1 = this.addLocalMinPoly(lb,rb,lb.bot);
				this.insertScanbeam(lb.top.y);
			}
			if(rb != null) {
				if(hxClipper_ClipperBase.isHorizontal(rb)) this.addEdgeToSEL(rb); else this.insertScanbeam(rb.top.y);
			}
			if(lb == null || rb == null) continue;
			if(op1 != null && hxClipper_ClipperBase.isHorizontal(rb) && this.mGhostJoins.length > 0 && rb.windDelta != 0) {
				var _g1 = 0;
				var _g = this.mGhostJoins.length;
				while(_g1 < _g) {
					var i = _g1++;
					var j = this.mGhostJoins[i];
					if(this.horzSegmentsOverlap(j.outPt1.pt.x,j.offPt.x,rb.bot.x,rb.top.x)) this.addJoin(j.outPt1,op1,j.offPt);
				}
			}
			if(lb.outIdx >= 0 && lb.prevInAEL != null && lb.prevInAEL.curr.x == lb.bot.x && lb.prevInAEL.outIdx >= 0 && hxClipper_ClipperBase.slopesEqual(lb.prevInAEL,lb,this.mUseFullRange) && lb.windDelta != 0 && lb.prevInAEL.windDelta != 0) {
				var op2 = this.addOutPt(lb.prevInAEL,lb.bot);
				this.addJoin(op1,op2,lb.top);
			}
			if(lb.nextInAEL != rb) {
				if(rb.outIdx >= 0 && rb.prevInAEL.outIdx >= 0 && hxClipper_ClipperBase.slopesEqual(rb.prevInAEL,rb,this.mUseFullRange) && rb.windDelta != 0 && rb.prevInAEL.windDelta != 0) {
					var op21 = this.addOutPt(rb.prevInAEL,rb.bot);
					this.addJoin(op1,op21,rb.top);
				}
				var e = lb.nextInAEL;
				if(e != null) while(e != rb) {
					this.intersectEdges(rb,e,lb.curr);
					e = e.nextInAEL;
				}
			}
		}
	}
	,insertEdgeIntoAEL: function(edge,startEdge) {
		if(this.mActiveEdges == null) {
			edge.prevInAEL = null;
			edge.nextInAEL = null;
			this.mActiveEdges = edge;
		} else if(startEdge == null && this.e2InsertsBeforeE1(this.mActiveEdges,edge)) {
			edge.prevInAEL = null;
			edge.nextInAEL = this.mActiveEdges;
			this.mActiveEdges.prevInAEL = edge;
			this.mActiveEdges = edge;
		} else {
			if(startEdge == null) startEdge = this.mActiveEdges;
			while(startEdge.nextInAEL != null && !this.e2InsertsBeforeE1(startEdge.nextInAEL,edge)) startEdge = startEdge.nextInAEL;
			edge.nextInAEL = startEdge.nextInAEL;
			if(startEdge.nextInAEL != null) startEdge.nextInAEL.prevInAEL = edge;
			edge.prevInAEL = startEdge;
			startEdge.nextInAEL = edge;
		}
	}
	,e2InsertsBeforeE1: function(e1,e2) {
		if(e2.curr.x == e1.curr.x) {
			if(e2.top.y > e1.top.y) return e2.top.x < hxClipper_Clipper.topX(e1,e2.top.y); else return e1.top.x > hxClipper_Clipper.topX(e2,e1.top.y);
		} else return e2.curr.x < e1.curr.x;
	}
	,isEvenOddFillType: function(edge) {
		if(edge.polyType == hxClipper_PolyType.PT_SUBJECT) return this.mSubjFillType == hxClipper_PolyFillType.PFT_EVEN_ODD; else return this.mClipFillType == hxClipper_PolyFillType.PFT_EVEN_ODD;
	}
	,isEvenOddAltFillType: function(edge) {
		if(edge.polyType == hxClipper_PolyType.PT_SUBJECT) return this.mClipFillType == hxClipper_PolyFillType.PFT_EVEN_ODD; else return this.mSubjFillType == hxClipper_PolyFillType.PFT_EVEN_ODD;
	}
	,isContributing: function(edge) {
		var pft;
		var pft2;
		if(edge.polyType == hxClipper_PolyType.PT_SUBJECT) {
			pft = this.mSubjFillType;
			pft2 = this.mClipFillType;
		} else {
			pft = this.mClipFillType;
			pft2 = this.mSubjFillType;
		}
		switch(pft[1]) {
		case 0:
			if(edge.windDelta == 0 && edge.windCnt != 1) return false;
			break;
		case 1:
			if(Math.abs(edge.windCnt) != 1) return false;
			break;
		case 2:
			if(edge.windCnt != 1) return false;
			break;
		default:
			if(edge.windCnt != -1) return false;
		}
		var _g = this.mClipType;
		switch(_g[1]) {
		case 0:
			switch(pft2[1]) {
			case 0:case 1:
				return edge.windCnt2 != 0;
			case 2:
				return edge.windCnt2 > 0;
			default:
				return edge.windCnt2 < 0;
			}
			break;
		case 1:
			switch(pft2[1]) {
			case 0:case 1:
				return edge.windCnt2 == 0;
			case 2:
				return edge.windCnt2 <= 0;
			default:
				return edge.windCnt2 >= 0;
			}
			break;
		case 2:
			if(edge.polyType == hxClipper_PolyType.PT_SUBJECT) switch(pft2[1]) {
			case 0:case 1:
				return edge.windCnt2 == 0;
			case 2:
				return edge.windCnt2 <= 0;
			default:
				return edge.windCnt2 >= 0;
			} else switch(pft2[1]) {
			case 0:case 1:
				return edge.windCnt2 != 0;
			case 2:
				return edge.windCnt2 > 0;
			default:
				return edge.windCnt2 < 0;
			}
			break;
		case 3:
			if(edge.windDelta == 0) switch(pft2[1]) {
			case 0:case 1:
				return edge.windCnt2 == 0;
			case 2:
				return edge.windCnt2 <= 0;
			default:
				return edge.windCnt2 >= 0;
			} else return true;
			break;
		}
		return true;
	}
	,setWindingCount: function(edge) {
		var e = edge.prevInAEL;
		while(e != null && (e.polyType != edge.polyType || e.windDelta == 0)) e = e.prevInAEL;
		if(e == null) {
			if(edge.windDelta == 0) edge.windCnt = 1; else edge.windCnt = edge.windDelta;
			edge.windCnt2 = 0;
			e = this.mActiveEdges;
		} else if(edge.windDelta == 0 && this.mClipType != hxClipper_ClipType.CT_UNION) {
			edge.windCnt = 1;
			edge.windCnt2 = e.windCnt2;
			e = e.nextInAEL;
		} else if(this.isEvenOddFillType(edge)) {
			if(edge.windDelta == 0) {
				var inside = true;
				var e2 = e.prevInAEL;
				while(e2 != null) {
					if(e2.polyType == e.polyType && e2.windDelta != 0) inside = !inside;
					e2 = e2.prevInAEL;
				}
				if(inside) edge.windCnt = 0; else edge.windCnt = 1;
			} else edge.windCnt = edge.windDelta;
			edge.windCnt2 = e.windCnt2;
			e = e.nextInAEL;
		} else {
			if(e.windCnt * e.windDelta < 0) {
				if(Math.abs(e.windCnt) > 1) {
					if(e.windDelta * edge.windDelta < 0) edge.windCnt = e.windCnt; else edge.windCnt = e.windCnt + edge.windDelta;
				} else if(edge.windDelta == 0) edge.windCnt = 1; else edge.windCnt = edge.windDelta;
			} else if(edge.windDelta == 0) if(e.windCnt < 0) edge.windCnt = e.windCnt - 1; else edge.windCnt = e.windCnt + 1; else if(e.windDelta * edge.windDelta < 0) edge.windCnt = e.windCnt; else edge.windCnt = e.windCnt + edge.windDelta;
			edge.windCnt2 = e.windCnt2;
			e = e.nextInAEL;
		}
		if(this.isEvenOddAltFillType(edge)) while(e != edge) {
			if(e.windDelta != 0) if(edge.windCnt2 == 0) edge.windCnt2 = 1; else edge.windCnt2 = 0;
			e = e.nextInAEL;
		} else while(e != edge) {
			edge.windCnt2 += e.windDelta;
			e = e.nextInAEL;
		}
	}
	,addEdgeToSEL: function(edge) {
		if(this.mSortedEdges == null) {
			this.mSortedEdges = edge;
			edge.prevInSEL = null;
			edge.nextInSEL = null;
		} else {
			edge.nextInSEL = this.mSortedEdges;
			edge.prevInSEL = null;
			this.mSortedEdges.prevInSEL = edge;
			this.mSortedEdges = edge;
		}
	}
	,copyAELToSEL: function() {
		var e = this.mActiveEdges;
		this.mSortedEdges = e;
		while(e != null) {
			e.prevInSEL = e.prevInAEL;
			e.nextInSEL = e.nextInAEL;
			e = e.nextInAEL;
		}
	}
	,swapPositionsInAEL: function(edge1,edge2) {
		if(edge1.nextInAEL == edge1.prevInAEL || edge2.nextInAEL == edge2.prevInAEL) return;
		if(edge1.nextInAEL == edge2) {
			var next = edge2.nextInAEL;
			if(next != null) next.prevInAEL = edge1;
			var prev = edge1.prevInAEL;
			if(prev != null) prev.nextInAEL = edge2;
			edge2.prevInAEL = prev;
			edge2.nextInAEL = edge1;
			edge1.prevInAEL = edge2;
			edge1.nextInAEL = next;
		} else if(edge2.nextInAEL == edge1) {
			var next1 = edge1.nextInAEL;
			if(next1 != null) next1.prevInAEL = edge2;
			var prev1 = edge2.prevInAEL;
			if(prev1 != null) prev1.nextInAEL = edge1;
			edge1.prevInAEL = prev1;
			edge1.nextInAEL = edge2;
			edge2.prevInAEL = edge1;
			edge2.nextInAEL = next1;
		} else {
			var next2 = edge1.nextInAEL;
			var prev2 = edge1.prevInAEL;
			edge1.nextInAEL = edge2.nextInAEL;
			if(edge1.nextInAEL != null) edge1.nextInAEL.prevInAEL = edge1;
			edge1.prevInAEL = edge2.prevInAEL;
			if(edge1.prevInAEL != null) edge1.prevInAEL.nextInAEL = edge1;
			edge2.nextInAEL = next2;
			if(edge2.nextInAEL != null) edge2.nextInAEL.prevInAEL = edge2;
			edge2.prevInAEL = prev2;
			if(edge2.prevInAEL != null) edge2.prevInAEL.nextInAEL = edge2;
		}
		if(edge1.prevInAEL == null) this.mActiveEdges = edge1; else if(edge2.prevInAEL == null) this.mActiveEdges = edge2;
	}
	,swapPositionsInSEL: function(edge1,edge2) {
		if(edge1.nextInSEL == null && edge1.prevInSEL == null) return;
		if(edge2.nextInSEL == null && edge2.prevInSEL == null) return;
		if(edge1.nextInSEL == edge2) {
			var next = edge2.nextInSEL;
			if(next != null) next.prevInSEL = edge1;
			var prev = edge1.prevInSEL;
			if(prev != null) prev.nextInSEL = edge2;
			edge2.prevInSEL = prev;
			edge2.nextInSEL = edge1;
			edge1.prevInSEL = edge2;
			edge1.nextInSEL = next;
		} else if(edge2.nextInSEL == edge1) {
			var next1 = edge1.nextInSEL;
			if(next1 != null) next1.prevInSEL = edge2;
			var prev1 = edge2.prevInSEL;
			if(prev1 != null) prev1.nextInSEL = edge1;
			edge1.prevInSEL = prev1;
			edge1.nextInSEL = edge2;
			edge2.prevInSEL = edge1;
			edge2.nextInSEL = next1;
		} else {
			var next2 = edge1.nextInSEL;
			var prev2 = edge1.prevInSEL;
			edge1.nextInSEL = edge2.nextInSEL;
			if(edge1.nextInSEL != null) edge1.nextInSEL.prevInSEL = edge1;
			edge1.prevInSEL = edge2.prevInSEL;
			if(edge1.prevInSEL != null) edge1.prevInSEL.nextInSEL = edge1;
			edge2.nextInSEL = next2;
			if(edge2.nextInSEL != null) edge2.nextInSEL.prevInSEL = edge2;
			edge2.prevInSEL = prev2;
			if(edge2.prevInSEL != null) edge2.prevInSEL.nextInSEL = edge2;
		}
		if(edge1.prevInSEL == null) this.mSortedEdges = edge1; else if(edge2.prevInSEL == null) this.mSortedEdges = edge2;
	}
	,addLocalMaxPoly: function(e1,e2,pt) {
		this.addOutPt(e1,pt);
		if(e2.windDelta == 0) this.addOutPt(e2,pt);
		if(e1.outIdx == e2.outIdx) {
			e1.outIdx = -1;
			e2.outIdx = -1;
		} else if(e1.outIdx < e2.outIdx) this.appendPolygon(e1,e2); else this.appendPolygon(e2,e1);
	}
	,addLocalMinPoly: function(e1,e2,pt) {
		var result;
		var e;
		var prevE;
		if(hxClipper_ClipperBase.isHorizontal(e2) || e1.dx > e2.dx) {
			result = this.addOutPt(e1,pt);
			e2.outIdx = e1.outIdx;
			e1.side = hxClipper__$Clipper_EdgeSide.ES_LEFT;
			e2.side = hxClipper__$Clipper_EdgeSide.ES_RIGHT;
			e = e1;
			if(e.prevInAEL == e2) prevE = e2.prevInAEL; else prevE = e.prevInAEL;
		} else {
			result = this.addOutPt(e2,pt);
			e1.outIdx = e2.outIdx;
			e1.side = hxClipper__$Clipper_EdgeSide.ES_RIGHT;
			e2.side = hxClipper__$Clipper_EdgeSide.ES_LEFT;
			e = e2;
			if(e.prevInAEL == e1) prevE = e1.prevInAEL; else prevE = e.prevInAEL;
		}
		if(prevE != null && prevE.outIdx >= 0 && hxClipper_Clipper.topX(prevE,pt.y) == hxClipper_Clipper.topX(e,pt.y) && hxClipper_ClipperBase.slopesEqual(e,prevE,this.mUseFullRange) && e.windDelta != 0 && prevE.windDelta != 0) {
			var outPt = this.addOutPt(prevE,pt);
			this.addJoin(result,outPt,e.top);
		}
		return result;
	}
	,createOutRec: function() {
		var result = new hxClipper__$Clipper_OutRec();
		result.idx = -1;
		result.isHole = false;
		result.isOpen = false;
		result.firstLeft = null;
		result.pts = null;
		result.bottomPt = null;
		result.polyNode = null;
		this.mPolyOuts.push(result);
		result.idx = this.mPolyOuts.length - 1;
		return result;
	}
	,addOutPt: function(e,pt) {
		if(e.outIdx < 0) {
			var outRec = this.createOutRec();
			outRec.isOpen = e.windDelta == 0;
			var newOp = new hxClipper__$Clipper_OutPt();
			outRec.pts = newOp;
			newOp.idx = outRec.idx;
			newOp.pt.copyFrom(pt);
			newOp.next = newOp;
			newOp.prev = newOp;
			if(!outRec.isOpen) this.setHoleState(e,outRec);
			e.outIdx = outRec.idx;
			return newOp;
		} else {
			var outRec1 = this.mPolyOuts[e.outIdx];
			var op = outRec1.pts;
			var toFront = e.side == hxClipper__$Clipper_EdgeSide.ES_LEFT;
			if(toFront && pt.equals(op.pt)) return op; else if(!toFront && pt.equals(op.prev.pt)) return op.prev;
			var newOp1 = new hxClipper__$Clipper_OutPt();
			newOp1.idx = outRec1.idx;
			newOp1.pt.copyFrom(pt);
			newOp1.next = op;
			newOp1.prev = op.prev;
			newOp1.prev.next = newOp1;
			op.prev = newOp1;
			if(toFront) outRec1.pts = newOp1;
			return newOp1;
		}
	}
	,getLastOutPt: function(e) {
		var outRec = this.mPolyOuts[e.outIdx];
		if(e.side == hxClipper__$Clipper_EdgeSide.ES_LEFT) return outRec.pts; else return outRec.pts.prev;
	}
	,swapPoints: function(pt1,pt2) {
		var tmp = pt1.clone();
		pt1.copyFrom(pt2);
		pt2.copyFrom(tmp);
	}
	,horzSegmentsOverlap: function(seg1a,seg1b,seg2a,seg2b) {
		if(seg1a > seg1b) {
			var tmp = seg1a;
			seg1a = seg1b;
			seg1b = tmp;
		}
		if(seg2a > seg2b) {
			var tmp1 = seg2a;
			seg2a = seg2b;
			seg2b = tmp1;
		}
		return seg1a < seg2b && seg2a < seg1b;
	}
	,setHoleState: function(e,outRec) {
		var isHole = false;
		var e2 = e.prevInAEL;
		while(e2 != null) {
			if(e2.outIdx >= 0 && e2.windDelta != 0) {
				isHole = !isHole;
				if(outRec.firstLeft == null) outRec.firstLeft = this.mPolyOuts[e2.outIdx];
			}
			e2 = e2.prevInAEL;
		}
		if(isHole) outRec.isHole = true;
	}
	,getDx: function(pt1,pt2) {
		if(pt1.y == pt2.y) return -3.4E+38; else {
			var dx = pt2.x - pt1.x;
			var dy = pt2.y - pt1.y;
			return dx / dy;
		}
	}
	,firstIsBottomPt: function(btmPt1,btmPt2) {
		var p = btmPt1.prev;
		while(p.pt.equals(btmPt1.pt) && p != btmPt1) p = p.prev;
		var dx1p = Math.abs(this.getDx(btmPt1.pt,p.pt));
		p = btmPt1.next;
		while(p.pt.equals(btmPt1.pt) && p != btmPt1) p = p.next;
		var dx1n = Math.abs(this.getDx(btmPt1.pt,p.pt));
		p = btmPt2.prev;
		while(p.pt.equals(btmPt2.pt) && p != btmPt2) p = p.prev;
		var dx2p = Math.abs(this.getDx(btmPt2.pt,p.pt));
		p = btmPt2.next;
		while(p.pt.equals(btmPt2.pt) && p != btmPt2) p = p.next;
		var dx2n = Math.abs(this.getDx(btmPt2.pt,p.pt));
		return dx1p >= dx2p && dx1p >= dx2n || dx1n >= dx2p && dx1n >= dx2n;
	}
	,getBottomPt: function(pp) {
		var dups = null;
		var p = pp.next;
		while(p != pp) {
			if(p.pt.y > pp.pt.y) {
				pp = p;
				dups = null;
			} else if(p.pt.y == pp.pt.y && p.pt.x <= pp.pt.x) {
				if(p.pt.x < pp.pt.x) {
					dups = null;
					pp = p;
				} else if(p.next != pp && p.prev != pp) dups = p;
			}
			p = p.next;
		}
		if(dups != null) while(dups != p) {
			if(!this.firstIsBottomPt(p,dups)) pp = dups;
			dups = dups.next;
			while(!dups.pt.equals(pp.pt)) dups = dups.next;
		}
		return pp;
	}
	,getLowermostRec: function(outRec1,outRec2) {
		if(outRec1.bottomPt == null) outRec1.bottomPt = this.getBottomPt(outRec1.pts);
		if(outRec2.bottomPt == null) outRec2.bottomPt = this.getBottomPt(outRec2.pts);
		var bPt1 = outRec1.bottomPt;
		var bPt2 = outRec2.bottomPt;
		if(bPt1.pt.y > bPt2.pt.y) return outRec1; else if(bPt1.pt.y < bPt2.pt.y) return outRec2; else if(bPt1.pt.x < bPt2.pt.x) return outRec1; else if(bPt1.pt.x > bPt2.pt.x) return outRec2; else if(bPt1.next == bPt1) return outRec2; else if(bPt2.next == bPt2) return outRec1; else if(this.firstIsBottomPt(bPt1,bPt2)) return outRec1; else return outRec2;
	}
	,param1RightOfParam2: function(outRec1,outRec2) {
		do {
			outRec1 = outRec1.firstLeft;
			if(outRec1 == outRec2) return true;
		} while(outRec1 != null);
		return false;
	}
	,getOutRec: function(idx) {
		var outrec = this.mPolyOuts[idx];
		while(outrec != this.mPolyOuts[outrec.idx]) outrec = this.mPolyOuts[outrec.idx];
		return outrec;
	}
	,appendPolygon: function(e1,e2) {
		var outRec1 = this.mPolyOuts[e1.outIdx];
		var outRec2 = this.mPolyOuts[e2.outIdx];
		var holeStateRec;
		if(this.param1RightOfParam2(outRec1,outRec2)) holeStateRec = outRec2; else if(this.param1RightOfParam2(outRec2,outRec1)) holeStateRec = outRec1; else holeStateRec = this.getLowermostRec(outRec1,outRec2);
		var p1_lft = outRec1.pts;
		var p1_rt = p1_lft.prev;
		var p2_lft = outRec2.pts;
		var p2_rt = p2_lft.prev;
		var side;
		if(e1.side == hxClipper__$Clipper_EdgeSide.ES_LEFT) {
			if(e2.side == hxClipper__$Clipper_EdgeSide.ES_LEFT) {
				this.reversePolyPtLinks(p2_lft);
				p2_lft.next = p1_lft;
				p1_lft.prev = p2_lft;
				p1_rt.next = p2_rt;
				p2_rt.prev = p1_rt;
				outRec1.pts = p2_rt;
			} else {
				p2_rt.next = p1_lft;
				p1_lft.prev = p2_rt;
				p2_lft.prev = p1_rt;
				p1_rt.next = p2_lft;
				outRec1.pts = p2_lft;
			}
			side = hxClipper__$Clipper_EdgeSide.ES_LEFT;
		} else {
			if(e2.side == hxClipper__$Clipper_EdgeSide.ES_RIGHT) {
				this.reversePolyPtLinks(p2_lft);
				p1_rt.next = p2_rt;
				p2_rt.prev = p1_rt;
				p2_lft.next = p1_lft;
				p1_lft.prev = p2_lft;
			} else {
				p1_rt.next = p2_lft;
				p2_lft.prev = p1_rt;
				p1_lft.prev = p2_rt;
				p2_rt.next = p1_lft;
			}
			side = hxClipper__$Clipper_EdgeSide.ES_RIGHT;
		}
		outRec1.bottomPt = null;
		if(holeStateRec == outRec2) {
			if(outRec2.firstLeft != outRec1) outRec1.firstLeft = outRec2.firstLeft;
			outRec1.isHole = outRec2.isHole;
		}
		outRec2.pts = null;
		outRec2.bottomPt = null;
		outRec2.firstLeft = outRec1;
		var OKIdx = e1.outIdx;
		var ObsoleteIdx = e2.outIdx;
		e1.outIdx = -1;
		e2.outIdx = -1;
		var e = this.mActiveEdges;
		while(e != null) {
			if(e.outIdx == ObsoleteIdx) {
				e.outIdx = OKIdx;
				e.side = side;
				break;
			}
			e = e.nextInAEL;
		}
		outRec2.idx = outRec1.idx;
	}
	,reversePolyPtLinks: function(pp) {
		if(pp == null) return;
		var pp1;
		var pp2;
		pp1 = pp;
		do {
			pp2 = pp1.next;
			pp1.next = pp1.prev;
			pp1.prev = pp2;
			pp1 = pp2;
		} while(pp1 != pp);
	}
	,intersectEdges: function(e1,e2,pt) {
		var e1Contributing = e1.outIdx >= 0;
		var e2Contributing = e2.outIdx >= 0;
		if(e1.polyType == e2.polyType) {
			if(this.isEvenOddFillType(e1)) {
				var oldE1WindCnt = e1.windCnt;
				e1.windCnt = e2.windCnt;
				e2.windCnt = oldE1WindCnt;
			} else {
				if(e1.windCnt + e2.windDelta == 0) e1.windCnt = -e1.windCnt; else e1.windCnt += e2.windDelta;
				if(e2.windCnt - e1.windDelta == 0) e2.windCnt = -e2.windCnt; else e2.windCnt -= e1.windDelta;
			}
		} else {
			if(!this.isEvenOddFillType(e2)) e1.windCnt2 += e2.windDelta; else if(e1.windCnt2 == 0) e1.windCnt2 = 1; else e1.windCnt2 = 0;
			if(!this.isEvenOddFillType(e1)) e2.windCnt2 -= e1.windDelta; else if(e2.windCnt2 == 0) e2.windCnt2 = 1; else e2.windCnt2 = 0;
		}
		var e1FillType;
		var e2FillType;
		var e1FillType2;
		var e2FillType2;
		if(e1.polyType == hxClipper_PolyType.PT_SUBJECT) {
			e1FillType = this.mSubjFillType;
			e1FillType2 = this.mClipFillType;
		} else {
			e1FillType = this.mClipFillType;
			e1FillType2 = this.mSubjFillType;
		}
		if(e2.polyType == hxClipper_PolyType.PT_SUBJECT) {
			e2FillType = this.mSubjFillType;
			e2FillType2 = this.mClipFillType;
		} else {
			e2FillType = this.mClipFillType;
			e2FillType2 = this.mSubjFillType;
		}
		var e1Wc;
		var e2Wc;
		switch(e1FillType[1]) {
		case 2:
			e1Wc = e1.windCnt;
			break;
		case 3:
			e1Wc = -e1.windCnt;
			break;
		default:
			e1Wc = Std["int"](Math.abs(e1.windCnt));
		}
		switch(e2FillType[1]) {
		case 2:
			e2Wc = e2.windCnt;
			break;
		case 3:
			e2Wc = -e2.windCnt;
			break;
		default:
			e2Wc = Std["int"](Math.abs(e2.windCnt));
		}
		if(e1Contributing && e2Contributing) {
			if(e1Wc != 0 && e1Wc != 1 || e2Wc != 0 && e2Wc != 1 || e1.polyType != e2.polyType && this.mClipType != hxClipper_ClipType.CT_XOR) this.addLocalMaxPoly(e1,e2,pt); else {
				this.addOutPt(e1,pt);
				this.addOutPt(e2,pt);
				hxClipper_Clipper.swapSides(e1,e2);
				hxClipper_Clipper.swapPolyIndexes(e1,e2);
			}
		} else if(e1Contributing) {
			if(e2Wc == 0 || e2Wc == 1) {
				this.addOutPt(e1,pt);
				hxClipper_Clipper.swapSides(e1,e2);
				hxClipper_Clipper.swapPolyIndexes(e1,e2);
			}
		} else if(e2Contributing) {
			if(e1Wc == 0 || e1Wc == 1) {
				this.addOutPt(e2,pt);
				hxClipper_Clipper.swapSides(e1,e2);
				hxClipper_Clipper.swapPolyIndexes(e1,e2);
			}
		} else if((e1Wc == 0 || e1Wc == 1) && (e2Wc == 0 || e2Wc == 1)) {
			var e1Wc2;
			var e2Wc2;
			switch(e1FillType2[1]) {
			case 2:
				e1Wc2 = e1.windCnt2;
				break;
			case 3:
				e1Wc2 = -e1.windCnt2;
				break;
			default:
				e1Wc2 = Std["int"](Math.abs(e1.windCnt2));
			}
			switch(e2FillType2[1]) {
			case 2:
				e2Wc2 = e2.windCnt2;
				break;
			case 3:
				e2Wc2 = -e2.windCnt2;
				break;
			default:
				e2Wc2 = Std["int"](Math.abs(e2.windCnt2));
			}
			if(e1.polyType != e2.polyType) this.addLocalMinPoly(e1,e2,pt); else if(e1Wc == 1 && e2Wc == 1) {
				var _g = this.mClipType;
				switch(_g[1]) {
				case 0:
					if(e1Wc2 > 0 && e2Wc2 > 0) this.addLocalMinPoly(e1,e2,pt);
					break;
				case 1:
					if(e1Wc2 <= 0 && e2Wc2 <= 0) this.addLocalMinPoly(e1,e2,pt);
					break;
				case 2:
					if(e1.polyType == hxClipper_PolyType.PT_CLIP && e1Wc2 > 0 && e2Wc2 > 0 || e1.polyType == hxClipper_PolyType.PT_SUBJECT && e1Wc2 <= 0 && e2Wc2 <= 0) this.addLocalMinPoly(e1,e2,pt);
					break;
				case 3:
					this.addLocalMinPoly(e1,e2,pt);
					break;
				}
			} else hxClipper_Clipper.swapSides(e1,e2);
		}
	}
	,deleteFromAEL: function(e) {
		var aelPrev = e.prevInAEL;
		var aelNext = e.nextInAEL;
		if(aelPrev == null && aelNext == null && e != this.mActiveEdges) return;
		if(aelPrev != null) aelPrev.nextInAEL = aelNext; else this.mActiveEdges = aelNext;
		if(aelNext != null) aelNext.prevInAEL = aelPrev;
		e.nextInAEL = null;
		e.prevInAEL = null;
	}
	,deleteFromSEL: function(e) {
		var selPrev = e.prevInSEL;
		var selNext = e.nextInSEL;
		if(selPrev == null && selNext == null && e != this.mSortedEdges) return;
		if(selPrev != null) selPrev.nextInSEL = selNext; else this.mSortedEdges = selNext;
		if(selNext != null) selNext.prevInSEL = selPrev;
		e.nextInSEL = null;
		e.prevInSEL = null;
	}
	,updateEdgeIntoAEL: function(e) {
		if(e.nextInLML == null) throw new js__$Boot_HaxeError(new hxClipper_ClipperException("UpdateEdgeIntoAEL: invalid call"));
		var aelPrev = e.prevInAEL;
		var aelNext = e.nextInAEL;
		e.nextInLML.outIdx = e.outIdx;
		if(aelPrev != null) aelPrev.nextInAEL = e.nextInLML; else this.mActiveEdges = e.nextInLML;
		if(aelNext != null) aelNext.prevInAEL = e.nextInLML;
		e.nextInLML.side = e.side;
		e.nextInLML.windDelta = e.windDelta;
		e.nextInLML.windCnt = e.windCnt;
		e.nextInLML.windCnt2 = e.windCnt2;
		e = e.nextInLML;
		e.curr.copyFrom(e.bot);
		e.prevInAEL = aelPrev;
		e.nextInAEL = aelNext;
		if(!hxClipper_ClipperBase.isHorizontal(e)) this.insertScanbeam(e.top.y);
		return e;
	}
	,processHorizontals: function() {
		var horzEdge = this.mSortedEdges;
		while(horzEdge != null) {
			this.deleteFromSEL(horzEdge);
			this.processHorizontal(horzEdge);
			horzEdge = this.mSortedEdges;
		}
	}
	,getHorzDirection: function(horzEdge,outParams) {
		if(horzEdge.bot.x < horzEdge.top.x) {
			outParams.left = horzEdge.bot.x;
			outParams.right = horzEdge.top.x;
			outParams.dir = hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT;
		} else {
			outParams.left = horzEdge.top.x;
			outParams.right = horzEdge.bot.x;
			outParams.dir = hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT;
		}
	}
	,processHorizontal: function(horzEdge) {
		var dir = null;
		var horzLeft = 0;
		var horzRight = 0;
		var isOpen = horzEdge.outIdx >= 0 && this.mPolyOuts[horzEdge.outIdx].isOpen;
		var outParams = { dir : dir, left : horzLeft, right : horzRight};
		this.getHorzDirection(horzEdge,outParams);
		dir = outParams.dir;
		horzLeft = outParams.left;
		horzRight = outParams.right;
		var eLastHorz = horzEdge;
		var eMaxPair = null;
		while(eLastHorz.nextInLML != null && hxClipper_ClipperBase.isHorizontal(eLastHorz.nextInLML)) eLastHorz = eLastHorz.nextInLML;
		if(eLastHorz.nextInLML == null) eMaxPair = this.getMaximaPair(eLastHorz);
		var currMax = this.mMaxima;
		if(currMax != null) {
			if(dir == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT) {
				while(currMax != null && currMax.x <= horzEdge.bot.x) currMax = currMax.next;
				if(currMax != null && currMax.x >= eLastHorz.top.x) currMax = null;
			} else {
				while(currMax.next != null && currMax.next.x < horzEdge.bot.x) currMax = currMax.next;
				if(currMax.x <= eLastHorz.top.x) currMax = null;
			}
		}
		var op1 = null;
		while(true) {
			var isLastHorz = horzEdge == eLastHorz;
			var e = this.getNextInAEL(horzEdge,dir);
			while(e != null) {
				if(currMax != null) {
					if(dir == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT) while(currMax != null && currMax.x < e.curr.x) {
						if(horzEdge.outIdx >= 0 && !isOpen) this.addOutPt(horzEdge,new hxClipper_IntPoint(currMax.x,horzEdge.bot.y));
						currMax = currMax.next;
					} else while(currMax != null && currMax.x > e.curr.x) {
						if(horzEdge.outIdx >= 0 && !isOpen) this.addOutPt(horzEdge,new hxClipper_IntPoint(currMax.x,horzEdge.bot.y));
						currMax = currMax.prev;
					}
				}
				if(dir == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT && e.curr.x > horzRight || dir == hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT && e.curr.x < horzLeft) break;
				if(e.curr.x == horzEdge.top.x && horzEdge.nextInLML != null && e.dx < horzEdge.nextInLML.dx) break;
				if(horzEdge.outIdx >= 0 && !isOpen) {
					op1 = this.addOutPt(horzEdge,e.curr);
					var eNextHorz = this.mSortedEdges;
					while(eNextHorz != null) {
						if(eNextHorz.outIdx >= 0 && this.horzSegmentsOverlap(horzEdge.bot.x,horzEdge.top.x,eNextHorz.bot.x,eNextHorz.top.x)) {
							var op2 = this.getLastOutPt(eNextHorz);
							this.addJoin(op2,op1,eNextHorz.top);
						}
						eNextHorz = eNextHorz.nextInSEL;
					}
					this.addGhostJoin(op1,horzEdge.bot);
				}
				if(e == eMaxPair && isLastHorz) {
					if(horzEdge.outIdx >= 0) this.addLocalMaxPoly(horzEdge,eMaxPair,horzEdge.top);
					this.deleteFromAEL(horzEdge);
					this.deleteFromAEL(eMaxPair);
					return;
				}
				if(dir == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT) {
					var pt = new hxClipper_IntPoint(e.curr.x,horzEdge.curr.y);
					this.intersectEdges(horzEdge,e,pt);
				} else {
					var pt1 = new hxClipper_IntPoint(e.curr.x,horzEdge.curr.y);
					this.intersectEdges(e,horzEdge,pt1);
				}
				var eNext = this.getNextInAEL(e,dir);
				this.swapPositionsInAEL(horzEdge,e);
				e = eNext;
			}
			if(horzEdge.nextInLML == null || !hxClipper_ClipperBase.isHorizontal(horzEdge.nextInLML)) break;
			horzEdge = this.updateEdgeIntoAEL(horzEdge);
			if(horzEdge.outIdx >= 0) this.addOutPt(horzEdge,horzEdge.bot);
			this.getHorzDirection(horzEdge,outParams);
			dir = outParams.dir;
			horzLeft = outParams.left;
			horzRight = outParams.right;
		}
		if(horzEdge.outIdx >= 0 && op1 == null) {
			op1 = this.getLastOutPt(horzEdge);
			var eNextHorz1 = this.mSortedEdges;
			while(eNextHorz1 != null) {
				if(eNextHorz1.outIdx >= 0 && this.horzSegmentsOverlap(horzEdge.bot.x,horzEdge.top.x,eNextHorz1.bot.x,eNextHorz1.top.x)) {
					var op21 = this.getLastOutPt(eNextHorz1);
					this.addJoin(op21,op1,eNextHorz1.top);
				}
				eNextHorz1 = eNextHorz1.nextInSEL;
			}
			this.addGhostJoin(op1,horzEdge.top);
		}
		if(horzEdge.nextInLML != null) {
			if(horzEdge.outIdx >= 0) {
				var op11 = this.addOutPt(horzEdge,horzEdge.top);
				horzEdge = this.updateEdgeIntoAEL(horzEdge);
				if(horzEdge.windDelta == 0) return;
				var ePrev = horzEdge.prevInAEL;
				var eNext1 = horzEdge.nextInAEL;
				if(ePrev != null && ePrev.curr.x == horzEdge.bot.x && ePrev.curr.y == horzEdge.bot.y && ePrev.windDelta != 0 && (ePrev.outIdx >= 0 && ePrev.curr.y > ePrev.top.y && hxClipper_ClipperBase.slopesEqual(horzEdge,ePrev,this.mUseFullRange))) {
					var op22 = this.addOutPt(ePrev,horzEdge.bot);
					this.addJoin(op11,op22,horzEdge.top);
				} else if(eNext1 != null && eNext1.curr.x == horzEdge.bot.x && eNext1.curr.y == horzEdge.bot.y && eNext1.windDelta != 0 && eNext1.outIdx >= 0 && eNext1.curr.y > eNext1.top.y && hxClipper_ClipperBase.slopesEqual(horzEdge,eNext1,this.mUseFullRange)) {
					var op23 = this.addOutPt(eNext1,horzEdge.bot);
					this.addJoin(op11,op23,horzEdge.top);
				}
			} else horzEdge = this.updateEdgeIntoAEL(horzEdge);
		} else {
			if(horzEdge.outIdx >= 0) this.addOutPt(horzEdge,horzEdge.top);
			this.deleteFromAEL(horzEdge);
		}
	}
	,getNextInAEL: function(e,direction) {
		if(direction == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT) return e.nextInAEL; else return e.prevInAEL;
	}
	,isMinima: function(e) {
		return e != null && e.prev.nextInLML != e && e.next.nextInLML != e;
	}
	,isMaxima: function(e,y) {
		return e != null && e.top.y == y && e.nextInLML == null;
	}
	,isIntermediate: function(e,y) {
		return e.top.y == y && e.nextInLML != null;
	}
	,getMaximaPair: function(e) {
		var result = null;
		if(e.next.top.equals(e.top) && e.next.nextInLML == null) result = e.next; else if(e.prev.top.equals(e.top) && e.prev.nextInLML == null) result = e.prev;
		if(result != null && (result.outIdx == -2 || result.nextInAEL == result.prevInAEL && !hxClipper_ClipperBase.isHorizontal(result))) return null;
		return result;
	}
	,processIntersections: function(topY) {
		if(this.mActiveEdges == null) return true;
		try {
			this.buildIntersectList(topY);
			if(this.mIntersectList.length == 0) return true;
			if(this.mIntersectList.length == 1 || this.fixupIntersectionOrder()) this.processIntersectList(); else return false;
		} catch( e ) {
			haxe_CallStack.lastException = e;
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			this.mSortedEdges = null;
			this.mIntersectList.length = 0;
			throw new js__$Boot_HaxeError(new hxClipper_ClipperException("ProcessIntersections error"));
		}
		this.mSortedEdges = null;
		return true;
	}
	,buildIntersectList: function(topY) {
		if(this.mActiveEdges == null) return;
		var e = this.mActiveEdges;
		this.mSortedEdges = e;
		while(e != null) {
			e.prevInSEL = e.prevInAEL;
			e.nextInSEL = e.nextInAEL;
			e.curr.x = hxClipper_Clipper.topX(e,topY);
			e = e.nextInAEL;
		}
		var isModified = true;
		while(isModified && this.mSortedEdges != null) {
			isModified = false;
			e = this.mSortedEdges;
			while(e.nextInSEL != null) {
				var eNext = e.nextInSEL;
				var pt = new hxClipper_IntPoint();
				if(e.curr.x > eNext.curr.x) {
					this.intersectPoint(e,eNext,pt);
					var newNode = new hxClipper_IntersectNode();
					newNode.edge1 = e;
					newNode.edge2 = eNext;
					newNode.pt.copyFrom(pt);
					this.mIntersectList.push(newNode);
					this.swapPositionsInSEL(e,eNext);
					isModified = true;
				} else e = eNext;
			}
			if(e.prevInSEL != null) e.prevInSEL.nextInSEL = null; else break;
		}
		this.mSortedEdges = null;
	}
	,edgesAdjacent: function(inode) {
		return inode.edge1.nextInSEL == inode.edge2 || inode.edge1.prevInSEL == inode.edge2;
	}
	,fixupIntersectionOrder: function() {
		haxe_ds_ArraySort.sort(this.mIntersectList,this.mIntersectNodeComparer);
		this.copyAELToSEL();
		var cnt = this.mIntersectList.length;
		var _g = 0;
		while(_g < cnt) {
			var i = _g++;
			if(!this.edgesAdjacent(this.mIntersectList[i])) {
				var j = i + 1;
				while(j < cnt && !this.edgesAdjacent(this.mIntersectList[j])) j++;
				if(j == cnt) return false;
				var tmp = this.mIntersectList[i];
				this.mIntersectList[i] = this.mIntersectList[j];
				this.mIntersectList[j] = tmp;
			}
			this.swapPositionsInSEL(this.mIntersectList[i].edge1,this.mIntersectList[i].edge2);
		}
		return true;
	}
	,processIntersectList: function() {
		var _g1 = 0;
		var _g = this.mIntersectList.length;
		while(_g1 < _g) {
			var i = _g1++;
			var iNode = this.mIntersectList[i];
			this.intersectEdges(iNode.edge1,iNode.edge2,iNode.pt);
			this.swapPositionsInAEL(iNode.edge1,iNode.edge2);
		}
		this.mIntersectList.length = 0;
	}
	,intersectPoint: function(edge1,edge2,ip) {
		var b1;
		var b2;
		if(edge1.dx == edge2.dx) {
			ip.y = edge1.curr.y;
			ip.x = hxClipper_Clipper.topX(edge1,ip.y);
			return;
		}
		if(edge1.delta.x == 0) {
			ip.x = edge1.bot.x;
			if(hxClipper_ClipperBase.isHorizontal(edge2)) ip.y = edge2.bot.y; else {
				b2 = edge2.bot.y - edge2.bot.x / edge2.dx;
				ip.y = hxClipper_Clipper.round(ip.x / edge2.dx + b2);
			}
		} else if(edge2.delta.x == 0) {
			ip.x = edge2.bot.x;
			if(hxClipper_ClipperBase.isHorizontal(edge1)) ip.y = edge1.bot.y; else {
				b1 = edge1.bot.y - edge1.bot.x / edge1.dx;
				ip.y = hxClipper_Clipper.round(ip.x / edge1.dx + b1);
			}
		} else {
			b1 = edge1.bot.x - edge1.bot.y * edge1.dx;
			b2 = edge2.bot.x - edge2.bot.y * edge2.dx;
			var q = (b2 - b1) / (edge1.dx - edge2.dx);
			ip.y = hxClipper_Clipper.round(q);
			if(Math.abs(edge1.dx) < Math.abs(edge2.dx)) ip.x = hxClipper_Clipper.round(edge1.dx * q + b1); else ip.x = hxClipper_Clipper.round(edge2.dx * q + b2);
		}
		if(ip.y < edge1.top.y || ip.y < edge2.top.y) {
			if(edge1.top.y > edge2.top.y) ip.y = edge1.top.y; else ip.y = edge2.top.y;
			if(Math.abs(edge1.dx) < Math.abs(edge2.dx)) ip.x = hxClipper_Clipper.topX(edge1,ip.y); else ip.x = hxClipper_Clipper.topX(edge2,ip.y);
		}
		if(ip.y > edge1.curr.y) {
			ip.y = edge1.curr.y;
			if(Math.abs(edge1.dx) > Math.abs(edge2.dx)) ip.x = hxClipper_Clipper.topX(edge2,ip.y); else ip.x = hxClipper_Clipper.topX(edge1,ip.y);
		}
	}
	,processEdgesAtTopOfScanbeam: function(topY) {
		var e = this.mActiveEdges;
		while(e != null) {
			var isMaximaEdge = this.isMaxima(e,topY);
			if(isMaximaEdge) {
				var eMaxPair = this.getMaximaPair(e);
				isMaximaEdge = eMaxPair == null || !hxClipper_ClipperBase.isHorizontal(eMaxPair);
			}
			if(isMaximaEdge) {
				if(this.strictlySimple) this.insertMaxima(e.top.x);
				var ePrev = e.prevInAEL;
				this.doMaxima(e);
				if(ePrev == null) e = this.mActiveEdges; else e = ePrev.nextInAEL;
			} else {
				if(this.isIntermediate(e,topY) && hxClipper_ClipperBase.isHorizontal(e.nextInLML)) {
					e = this.updateEdgeIntoAEL(e);
					if(e.outIdx >= 0) this.addOutPt(e,e.bot);
					this.addEdgeToSEL(e);
				} else {
					e.curr.x = hxClipper_Clipper.topX(e,topY);
					e.curr.y = topY;
				}
				if(this.strictlySimple) {
					var ePrev1 = e.prevInAEL;
					if(e.outIdx >= 0 && e.windDelta != 0 && ePrev1 != null && ePrev1.outIdx >= 0 && ePrev1.curr.x == e.curr.x && ePrev1.windDelta != 0) {
						var ip = e.curr.clone();
						var op = this.addOutPt(ePrev1,ip);
						var op2 = this.addOutPt(e,ip);
						this.addJoin(op,op2,ip);
					}
				}
				e = e.nextInAEL;
			}
		}
		this.processHorizontals();
		this.mMaxima = null;
		e = this.mActiveEdges;
		while(e != null) {
			if(this.isIntermediate(e,topY)) {
				var op1 = null;
				if(e.outIdx >= 0) op1 = this.addOutPt(e,e.top);
				e = this.updateEdgeIntoAEL(e);
				var ePrev2 = e.prevInAEL;
				var eNext = e.nextInAEL;
				if(ePrev2 != null && ePrev2.curr.x == e.bot.x && ePrev2.curr.y == e.bot.y && op1 != null && ePrev2.outIdx >= 0 && ePrev2.curr.y > ePrev2.top.y && hxClipper_ClipperBase.slopesEqual(e,ePrev2,this.mUseFullRange) && e.windDelta != 0 && ePrev2.windDelta != 0) {
					var op21 = this.addOutPt(ePrev2,e.bot);
					this.addJoin(op1,op21,e.top);
				} else if(eNext != null && eNext.curr.x == e.bot.x && eNext.curr.y == e.bot.y && op1 != null && eNext.outIdx >= 0 && eNext.curr.y > eNext.top.y && hxClipper_ClipperBase.slopesEqual(e,eNext,this.mUseFullRange) && e.windDelta != 0 && eNext.windDelta != 0) {
					var op22 = this.addOutPt(eNext,e.bot);
					this.addJoin(op1,op22,e.top);
				}
			}
			e = e.nextInAEL;
		}
	}
	,doMaxima: function(e) {
		var eMaxPair = this.getMaximaPair(e);
		if(eMaxPair == null) {
			if(e.outIdx >= 0) this.addOutPt(e,e.top);
			this.deleteFromAEL(e);
			return;
		}
		var eNext = e.nextInAEL;
		while(eNext != null && eNext != eMaxPair) {
			this.intersectEdges(e,eNext,e.top);
			this.swapPositionsInAEL(e,eNext);
			eNext = e.nextInAEL;
		}
		if(e.outIdx == -1 && eMaxPair.outIdx == -1) {
			this.deleteFromAEL(e);
			this.deleteFromAEL(eMaxPair);
		} else if(e.outIdx >= 0 && eMaxPair.outIdx >= 0) {
			if(e.outIdx >= 0) this.addLocalMaxPoly(e,eMaxPair,e.top);
			this.deleteFromAEL(e);
			this.deleteFromAEL(eMaxPair);
		} else throw new js__$Boot_HaxeError(new hxClipper_ClipperException("DoMaxima error"));
	}
	,pointCount: function(pts) {
		if(pts == null) return 0;
		var result = 0;
		var p = pts;
		do {
			result++;
			p = p.next;
		} while(p != pts);
		return result;
	}
	,buildResult: function(polyg) {
		polyg.length = 0;
		var _g1 = 0;
		var _g = this.mPolyOuts.length;
		while(_g1 < _g) {
			var i = _g1++;
			var outRec = this.mPolyOuts[i];
			if(outRec.pts == null) continue;
			var p = outRec.pts.prev;
			var cnt = this.pointCount(p);
			if(cnt < 2) continue;
			var pg = [];
			var _g2 = 0;
			while(_g2 < cnt) {
				var j = _g2++;
				pg.push(p.pt);
				p = p.prev;
			}
			polyg.push(pg);
		}
	}
	,buildResult2: function(polytree) {
		polytree.clear();
		var _g1 = 0;
		var _g = this.mPolyOuts.length;
		while(_g1 < _g) {
			var i = _g1++;
			var outRec = this.mPolyOuts[i];
			var cnt = this.pointCount(outRec.pts);
			if(outRec.isOpen && cnt < 2 || !outRec.isOpen && cnt < 3) continue;
			this.fixHoleLinkage(outRec);
			var pn = new hxClipper_PolyNode();
			polytree.mAllPolys.push(pn);
			outRec.polyNode = pn;
			var op = outRec.pts.prev;
			var _g2 = 0;
			while(_g2 < cnt) {
				var j = _g2++;
				pn.mPolygon.push(op.pt);
				op = op.prev;
			}
		}
		var _g11 = 0;
		var _g3 = this.mPolyOuts.length;
		while(_g11 < _g3) {
			var i1 = _g11++;
			var outRec1 = this.mPolyOuts[i1];
			if(outRec1.polyNode == null) continue; else if(outRec1.isOpen) {
				outRec1.polyNode.isOpen = true;
				polytree.addChild(outRec1.polyNode);
			} else if(outRec1.firstLeft != null && outRec1.firstLeft.polyNode != null) outRec1.firstLeft.polyNode.addChild(outRec1.polyNode); else polytree.addChild(outRec1.polyNode);
		}
	}
	,fixupOutPolyLine: function(outrec) {
		var pp = outrec.pts;
		var lastPP = pp.prev;
		while(pp != lastPP) {
			pp = pp.next;
			if(pp.pt == pp.prev.pt) {
				if(pp == lastPP) lastPP = pp.prev;
				var tmpPP = pp.prev;
				tmpPP.next = pp.next;
				pp.next.prev = tmpPP;
				pp = tmpPP;
			}
		}
		if(pp == pp.prev) outrec.pts = null;
	}
	,fixupOutPolygon: function(outRec) {
		var lastOK = null;
		outRec.bottomPt = null;
		var pp = outRec.pts;
		var preserveCol = this.preserveCollinear || this.strictlySimple;
		while(true) {
			if(pp.prev == pp || pp.prev == pp.next) {
				outRec.pts = null;
				return;
			}
			if(pp.pt.equals(pp.next.pt) || pp.pt.equals(pp.prev.pt) || hxClipper_ClipperBase.slopesEqual3(pp.prev.pt,pp.pt,pp.next.pt,this.mUseFullRange) && (!preserveCol || !this.pt2IsBetweenPt1AndPt3(pp.prev.pt,pp.pt,pp.next.pt))) {
				lastOK = null;
				pp.prev.next = pp.next;
				pp.next.prev = pp.prev;
				pp = pp.prev;
			} else if(pp == lastOK) break; else {
				if(lastOK == null) lastOK = pp;
				pp = pp.next;
			}
		}
		outRec.pts = pp;
	}
	,dupOutPt: function(outPt,insertAfter) {
		var result = new hxClipper__$Clipper_OutPt();
		result.pt.copyFrom(outPt.pt);
		result.idx = outPt.idx;
		if(insertAfter) {
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
	,getOverlap: function(a1,a2,b1,b2,outParams) {
		if(a1 < a2) {
			if(b1 < b2) {
				outParams.left = Std["int"](Math.max(a1,b1));
				outParams.right = Std["int"](Math.min(a2,b2));
			} else {
				outParams.left = Std["int"](Math.max(a1,b2));
				outParams.right = Std["int"](Math.min(a2,b1));
			}
		} else if(b1 < b2) {
			outParams.left = Std["int"](Math.max(a2,b1));
			outParams.right = Std["int"](Math.min(a1,b2));
		} else {
			outParams.left = Std["int"](Math.max(a2,b2));
			outParams.right = Std["int"](Math.min(a1,b1));
		}
		return outParams.left < outParams.right;
	}
	,joinHorz: function(op1,op1b,op2,op2b,pt,discardLeft) {
		var dir1;
		if(op1.pt.x > op1b.pt.x) dir1 = hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT; else dir1 = hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT;
		var dir2;
		if(op2.pt.x > op2b.pt.x) dir2 = hxClipper__$Clipper_Direction.D_RIGHT_TO_LEFT; else dir2 = hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT;
		if(dir1 == dir2) return false;
		if(dir1 == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT) {
			while(op1.next.pt.x <= pt.x && op1.next.pt.x >= op1.pt.x && op1.next.pt.y == pt.y) op1 = op1.next;
			if(discardLeft && op1.pt.x != pt.x) op1 = op1.next;
			op1b = this.dupOutPt(op1,!discardLeft);
			if(!op1b.pt.equals(pt)) {
				op1 = op1b;
				op1.pt.copyFrom(pt);
				op1b = this.dupOutPt(op1,!discardLeft);
			}
		} else {
			while(op1.next.pt.x >= pt.x && op1.next.pt.x <= op1.pt.x && op1.next.pt.y == pt.y) op1 = op1.next;
			if(!discardLeft && op1.pt.x != pt.x) op1 = op1.next;
			op1b = this.dupOutPt(op1,discardLeft);
			if(!op1b.pt.equals(pt)) {
				op1 = op1b;
				op1.pt.copyFrom(pt);
				op1b = this.dupOutPt(op1,discardLeft);
			}
		}
		if(dir2 == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT) {
			while(op2.next.pt.x <= pt.x && op2.next.pt.x >= op2.pt.x && op2.next.pt.y == pt.y) op2 = op2.next;
			if(discardLeft && op2.pt.x != pt.x) op2 = op2.next;
			op2b = this.dupOutPt(op2,!discardLeft);
			if(!op2b.pt.equals(pt)) {
				op2 = op2b;
				op2.pt.copyFrom(pt);
				op2b = this.dupOutPt(op2,!discardLeft);
			}
		} else {
			while(op2.next.pt.x >= pt.x && op2.next.pt.x <= op2.pt.x && op2.next.pt.y == pt.y) op2 = op2.next;
			if(!discardLeft && op2.pt.x != pt.x) op2 = op2.next;
			op2b = this.dupOutPt(op2,discardLeft);
			if(!op2b.pt.equals(pt)) {
				op2 = op2b;
				op2.pt.copyFrom(pt);
				op2b = this.dupOutPt(op2,discardLeft);
			}
		}
		if(dir1 == hxClipper__$Clipper_Direction.D_LEFT_TO_RIGHT == discardLeft) {
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
	,joinPoints: function(j,outRec1,outRec2) {
		var op1 = j.outPt1;
		var op1b;
		var op2 = j.outPt2;
		var op2b;
		var isHorizontal = j.outPt1.pt.y == j.offPt.y;
		if(isHorizontal && j.offPt.equals(j.outPt1.pt) && j.offPt.equals(j.outPt2.pt)) {
			if(outRec1 != outRec2) return false;
			op1b = j.outPt1.next;
			while(op1b != op1 && op1b.pt.equals(j.offPt)) op1b = op1b.next;
			var reverse1 = op1b.pt.y > j.offPt.y;
			op2b = j.outPt2.next;
			while(op2b != op2 && op2b.pt.equals(j.offPt)) op2b = op2b.next;
			var reverse2 = op2b.pt.y > j.offPt.y;
			if(reverse1 == reverse2) return false;
			if(reverse1) {
				op1b = this.dupOutPt(op1,false);
				op2b = this.dupOutPt(op2,true);
				op1.prev = op2;
				op2.next = op1;
				op1b.next = op2b;
				op2b.prev = op1b;
				j.outPt1 = op1;
				j.outPt2 = op1b;
				return true;
			} else {
				op1b = this.dupOutPt(op1,true);
				op2b = this.dupOutPt(op2,false);
				op1.next = op2;
				op2.prev = op1;
				op1b.prev = op2b;
				op2b.next = op1b;
				j.outPt1 = op1;
				j.outPt2 = op1b;
				return true;
			}
		} else if(isHorizontal) {
			op1b = op1;
			while(op1.prev.pt.y == op1.pt.y && op1.prev != op1b && op1.prev != op2) op1 = op1.prev;
			while(op1b.next.pt.y == op1b.pt.y && op1b.next != op1 && op1b.next != op2) op1b = op1b.next;
			if(op1b.next == op1 || op1b.next == op2) return false;
			op2b = op2;
			while(op2.prev.pt.y == op2.pt.y && op2.prev != op2b && op2.prev != op1b) op2 = op2.prev;
			while(op2b.next.pt.y == op2b.pt.y && op2b.next != op2 && op2b.next != op1) op2b = op2b.next;
			if(op2b.next == op2 || op2b.next == op1) return false;
			var left = 0;
			var right = 0;
			var outParams = { left : left, right : right};
			if(!this.getOverlap(op1.pt.x,op1b.pt.x,op2.pt.x,op2b.pt.x,outParams)) return false;
			left = outParams.left;
			right = outParams.right;
			var pt = new hxClipper_IntPoint();
			var discardLeftSide;
			if(op1.pt.x >= left && op1.pt.x <= right) {
				pt.copyFrom(op1.pt);
				discardLeftSide = op1.pt.x > op1b.pt.x;
			} else if(op2.pt.x >= left && op2.pt.x <= right) {
				pt.copyFrom(op2.pt);
				discardLeftSide = op2.pt.x > op2b.pt.x;
			} else if(op1b.pt.x >= left && op1b.pt.x <= right) {
				pt.copyFrom(op1b.pt);
				discardLeftSide = op1b.pt.x > op1.pt.x;
			} else {
				pt.copyFrom(op2b.pt);
				discardLeftSide = op2b.pt.x > op2.pt.x;
			}
			j.outPt1 = op1;
			j.outPt2 = op2;
			return this.joinHorz(op1,op1b,op2,op2b,pt,discardLeftSide);
		} else {
			op1b = op1.next;
			while(op1b.pt.equals(op1.pt) && op1b != op1) op1b = op1b.next;
			var reverse11 = op1b.pt.y > op1.pt.y || !hxClipper_ClipperBase.slopesEqual3(op1.pt,op1b.pt,j.offPt,this.mUseFullRange);
			if(reverse11) {
				op1b = op1.prev;
				while(op1b.pt.equals(op1.pt) && op1b != op1) op1b = op1b.prev;
				if(op1b.pt.y > op1.pt.y || !hxClipper_ClipperBase.slopesEqual3(op1.pt,op1b.pt,j.offPt,this.mUseFullRange)) return false;
			}
			op2b = op2.next;
			while(op2b.pt.equals(op2.pt) && op2b != op2) op2b = op2b.next;
			var reverse21 = op2b.pt.y > op2.pt.y || !hxClipper_ClipperBase.slopesEqual3(op2.pt,op2b.pt,j.offPt,this.mUseFullRange);
			if(reverse21) {
				op2b = op2.prev;
				while(op2b.pt.equals(op2.pt) && op2b != op2) op2b = op2b.prev;
				if(op2b.pt.y > op2.pt.y || !hxClipper_ClipperBase.slopesEqual3(op2.pt,op2b.pt,j.offPt,this.mUseFullRange)) return false;
			}
			if(op1b == op1 || op2b == op2 || op1b == op2b || outRec1 == outRec2 && reverse11 == reverse21) return false;
			if(reverse11) {
				op1b = this.dupOutPt(op1,false);
				op2b = this.dupOutPt(op2,true);
				op1.prev = op2;
				op2.next = op1;
				op1b.next = op2b;
				op2b.prev = op1b;
				j.outPt1 = op1;
				j.outPt2 = op1b;
				return true;
			} else {
				op1b = this.dupOutPt(op1,true);
				op2b = this.dupOutPt(op2,false);
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
	,fixupFirstLefts1: function(oldOutRec,newOutRec) {
		var _g1 = 0;
		var _g = this.mPolyOuts.length;
		while(_g1 < _g) {
			var i = _g1++;
			var outRec = this.mPolyOuts[i];
			if(outRec.pts == null || outRec.firstLeft == null) continue;
			var firstLeft = hxClipper_Clipper.parseFirstLeft(outRec.firstLeft);
			if(firstLeft == oldOutRec) {
				if(hxClipper_Clipper.poly2ContainsPoly1(outRec.pts,newOutRec.pts)) outRec.firstLeft = newOutRec;
			}
		}
	}
	,fixupFirstLefts2: function(oldOutRec,newOutRec) {
		var _g = 0;
		var _g1 = this.mPolyOuts;
		while(_g < _g1.length) {
			var outRec = _g1[_g];
			++_g;
			if(outRec.firstLeft == oldOutRec) outRec.firstLeft = newOutRec;
		}
	}
	,joinCommonEdges: function() {
		var _g1 = 0;
		var _g = this.mJoins.length;
		while(_g1 < _g) {
			var i = _g1++;
			var join = this.mJoins[i];
			var outRec1 = this.getOutRec(join.outPt1.idx);
			var outRec2 = this.getOutRec(join.outPt2.idx);
			if(outRec1.pts == null || outRec2.pts == null) continue;
			if(outRec1.isOpen || outRec2.isOpen) continue;
			var holeStateRec;
			if(outRec1 == outRec2) holeStateRec = outRec1; else if(this.param1RightOfParam2(outRec1,outRec2)) holeStateRec = outRec2; else if(this.param1RightOfParam2(outRec2,outRec1)) holeStateRec = outRec1; else holeStateRec = this.getLowermostRec(outRec1,outRec2);
			if(!this.joinPoints(join,outRec1,outRec2)) continue;
			if(outRec1 == outRec2) {
				outRec1.pts = join.outPt1;
				outRec1.bottomPt = null;
				outRec2 = this.createOutRec();
				outRec2.pts = join.outPt2;
				this.updateOutPtIdxs(outRec2);
				if(this.mUsingPolyTree) {
					var _g3 = 0;
					var _g2 = this.mPolyOuts.length - 1;
					while(_g3 < _g2) {
						var j = _g3++;
						var oRec = this.mPolyOuts[j];
						if(oRec.pts == null || hxClipper_Clipper.parseFirstLeft(oRec.firstLeft) != outRec1 || oRec.isHole == outRec1.isHole) continue;
						if(hxClipper_Clipper.poly2ContainsPoly1(oRec.pts,join.outPt2)) oRec.firstLeft = outRec2;
					}
				}
				if(hxClipper_Clipper.poly2ContainsPoly1(outRec2.pts,outRec1.pts)) {
					outRec2.isHole = !outRec1.isHole;
					outRec2.firstLeft = outRec1;
					if(this.mUsingPolyTree) this.fixupFirstLefts2(outRec2,outRec1);
					if(hxClipper_InternalTools.xor(outRec2.isHole,this.reverseSolution) == this.areaOfOutRec(outRec2) > 0) this.reversePolyPtLinks(outRec2.pts);
				} else if(hxClipper_Clipper.poly2ContainsPoly1(outRec1.pts,outRec2.pts)) {
					outRec2.isHole = outRec1.isHole;
					outRec1.isHole = !outRec2.isHole;
					outRec2.firstLeft = outRec1.firstLeft;
					outRec1.firstLeft = outRec2;
					if(this.mUsingPolyTree) this.fixupFirstLefts2(outRec1,outRec2);
					if(hxClipper_InternalTools.xor(outRec1.isHole,this.reverseSolution) == this.areaOfOutRec(outRec1) > 0) this.reversePolyPtLinks(outRec1.pts);
				} else {
					outRec2.isHole = outRec1.isHole;
					outRec2.firstLeft = outRec1.firstLeft;
					if(this.mUsingPolyTree) this.fixupFirstLefts1(outRec1,outRec2);
				}
			} else {
				outRec2.pts = null;
				outRec2.bottomPt = null;
				outRec2.idx = outRec1.idx;
				outRec1.isHole = holeStateRec.isHole;
				if(holeStateRec == outRec2) outRec1.firstLeft = outRec2.firstLeft;
				outRec2.firstLeft = outRec1;
				if(this.mUsingPolyTree) this.fixupFirstLefts2(outRec2,outRec1);
			}
		}
	}
	,updateOutPtIdxs: function(outrec) {
		var op = outrec.pts;
		do {
			op.idx = outrec.idx;
			op = op.prev;
		} while(op != outrec.pts);
	}
	,doSimplePolygons: function() {
		var i = 0;
		while(i < this.mPolyOuts.length) {
			var outrec = this.mPolyOuts[i++];
			var op = outrec.pts;
			if(op == null || outrec.isOpen) continue;
			do {
				var op2 = op.next;
				while(op2 != outrec.pts) {
					if(op.pt.equals(op2.pt) && op2.next != op && op2.prev != op) {
						var op3 = op.prev;
						var op4 = op2.prev;
						op.prev = op4;
						op4.next = op;
						op2.prev = op3;
						op3.next = op2;
						outrec.pts = op;
						var outrec2 = this.createOutRec();
						outrec2.pts = op2;
						this.updateOutPtIdxs(outrec2);
						if(hxClipper_Clipper.poly2ContainsPoly1(outrec2.pts,outrec.pts)) {
							outrec2.isHole = !outrec.isHole;
							outrec2.firstLeft = outrec;
							if(this.mUsingPolyTree) this.fixupFirstLefts2(outrec2,outrec);
						} else if(hxClipper_Clipper.poly2ContainsPoly1(outrec.pts,outrec2.pts)) {
							outrec2.isHole = outrec.isHole;
							outrec.isHole = !outrec2.isHole;
							outrec2.firstLeft = outrec.firstLeft;
							outrec.firstLeft = outrec2;
							if(this.mUsingPolyTree) this.fixupFirstLefts2(outrec,outrec2);
						} else {
							outrec2.isHole = outrec.isHole;
							outrec2.firstLeft = outrec.firstLeft;
							if(this.mUsingPolyTree) this.fixupFirstLefts1(outrec,outrec2);
						}
						op2 = op;
					}
					op2 = op2.next;
				}
				op = op.next;
			} while(op != outrec.pts);
		}
	}
	,areaOfOutRec: function(outRec) {
		var op = outRec.pts;
		if(op == null) return 0;
		var a = 0;
		do {
			var dx = op.prev.pt.x + op.pt.x;
			var dy = op.prev.pt.y - op.pt.y;
			a += dx * dy;
			op = op.next;
		} while(op != outRec.pts);
		return a * 0.5;
	}
	,__class__: hxClipper_Clipper
});
var hxClipper_ClipperOffset = function(miterLimit,arcTolerance) {
	if(arcTolerance == null) arcTolerance = 0.25;
	if(miterLimit == null) miterLimit = 2.0;
	this.mPolyNodes = new hxClipper_PolyNode();
	this.mLowest = new hxClipper_IntPoint();
	this.mNormals = [];
	this.miterLimit = miterLimit;
	this.arcTolerance = arcTolerance;
	this.mLowest.x = -1;
};
hxClipper_ClipperOffset.__name__ = ["hxClipper","ClipperOffset"];
hxClipper_ClipperOffset.round = function(value) {
	return hxClipper_Clipper.round(value);
};
hxClipper_ClipperOffset.getUnitNormal = function(pt1,pt2) {
	var dx = pt2.x - pt1.x;
	var dy = pt2.y - pt1.y;
	if(dx == 0 && dy == 0) return new hxClipper_DoublePoint();
	var f = 1.0 / Math.sqrt(dx * dx + dy * dy);
	dx *= f;
	dy *= f;
	return new hxClipper_DoublePoint(dy,-dx);
};
hxClipper_ClipperOffset.prototype = {
	mDestPolys: null
	,mSrcPoly: null
	,mDestPoly: null
	,mNormals: null
	,mDelta: null
	,mSinA: null
	,mSin: null
	,mCos: null
	,mMiterLim: null
	,mStepsPerRad: null
	,mLowest: null
	,mPolyNodes: null
	,arcTolerance: null
	,miterLimit: null
	,clear: function() {
		hxClipper_InternalTools.clear(this.mPolyNodes.get_children());
		this.mLowest.x = -1;
	}
	,addPath: function(path,joinType,endType) {
		var highI = path.length - 1;
		if(highI < 0) return;
		var newNode = new hxClipper_PolyNode();
		newNode.mJoinType = joinType;
		newNode.mEndtype = endType;
		if(endType == hxClipper_EndType.ET_CLOSED_LINE || endType == hxClipper_EndType.ET_CLOSED_POLYGON) while(highI > 0 && path[0].equals(path[highI])) highI--;
		newNode.mPolygon.push(path[0]);
		var j = 0;
		var k = 0;
		var _g1 = 1;
		var _g = highI + 1;
		while(_g1 < _g) {
			var i = _g1++;
			if(!newNode.mPolygon[j].equals(path[i])) {
				j++;
				newNode.mPolygon.push(path[i]);
				if(path[i].y > newNode.mPolygon[k].y || path[i].y == newNode.mPolygon[k].y && path[i].x < newNode.mPolygon[k].x) k = j;
			}
		}
		if(endType == hxClipper_EndType.ET_CLOSED_POLYGON && j < 2) return;
		this.mPolyNodes.addChild(newNode);
		if(endType != hxClipper_EndType.ET_CLOSED_POLYGON) return;
		if(this.mLowest.x < 0) this.mLowest = new hxClipper_IntPoint(this.mPolyNodes.get_numChildren() - 1,k); else {
			var ip = this.mPolyNodes.get_children()[this.mLowest.x | 0].mPolygon[this.mLowest.y | 0].clone();
			if(newNode.mPolygon[k].y > ip.y || newNode.mPolygon[k].y == ip.y && newNode.mPolygon[k].x < ip.x) this.mLowest = new hxClipper_IntPoint(this.mPolyNodes.get_numChildren() - 1,k);
		}
	}
	,addPaths: function(paths,joinType,endType) {
		var _g = 0;
		while(_g < paths.length) {
			var p = paths[_g];
			++_g;
			this.addPath(p,joinType,endType);
		}
	}
	,fixOrientations: function() {
		if(this.mLowest.x >= 0 && !hxClipper_Clipper.orientation(this.mPolyNodes.get_children()[this.mLowest.x | 0].mPolygon)) {
			var _g1 = 0;
			var _g = this.mPolyNodes.get_numChildren();
			while(_g1 < _g) {
				var i = _g1++;
				var node = this.mPolyNodes.get_children()[i];
				if(node.mEndtype == hxClipper_EndType.ET_CLOSED_POLYGON || node.mEndtype == hxClipper_EndType.ET_CLOSED_LINE && hxClipper_Clipper.orientation(node.mPolygon)) node.mPolygon.reverse();
			}
		} else {
			var _g11 = 0;
			var _g2 = this.mPolyNodes.get_numChildren();
			while(_g11 < _g2) {
				var i1 = _g11++;
				var node1 = this.mPolyNodes.get_children()[i1];
				if(node1.mEndtype == hxClipper_EndType.ET_CLOSED_LINE && !hxClipper_Clipper.orientation(node1.mPolygon)) node1.mPolygon.reverse();
			}
		}
	}
	,doOffset: function(delta) {
		this.mDestPolys = [];
		this.mDelta = delta;
		if(hxClipper_ClipperBase.nearZero(delta)) {
			var _g1 = 0;
			var _g = this.mPolyNodes.get_numChildren();
			while(_g1 < _g) {
				var i = _g1++;
				var node = this.mPolyNodes.get_children()[i];
				if(node.mEndtype == hxClipper_EndType.ET_CLOSED_POLYGON) this.mDestPolys.push(node.mPolygon);
			}
			return;
		}
		if(this.miterLimit > 2) this.mMiterLim = 2 / (this.miterLimit * this.miterLimit); else this.mMiterLim = 0.5;
		var y;
		if(this.arcTolerance <= 0.0) y = 0.25; else if(this.arcTolerance > Math.abs(delta) * 0.25) y = Math.abs(delta) * 0.25; else y = this.arcTolerance;
		var steps = Math.PI / Math.acos(1 - y / Math.abs(delta));
		this.mSin = Math.sin(6.283185307179586476925286766559 / steps);
		this.mCos = Math.cos(6.283185307179586476925286766559 / steps);
		this.mStepsPerRad = steps / 6.283185307179586476925286766559;
		if(delta < 0.0) this.mSin = -this.mSin;
		var _g11 = 0;
		var _g2 = this.mPolyNodes.get_numChildren();
		while(_g11 < _g2) {
			var i1 = _g11++;
			var node1 = this.mPolyNodes.get_children()[i1];
			this.mSrcPoly = node1.mPolygon;
			var len = this.mSrcPoly.length;
			if(len == 0 || delta <= 0 && (len < 3 || node1.mEndtype != hxClipper_EndType.ET_CLOSED_POLYGON)) continue;
			this.mDestPoly = [];
			if(len == 1) {
				if(node1.mJoinType == hxClipper_JoinType.JT_ROUND) {
					var x = 1.0;
					var y1 = 0.0;
					var j = 1;
					while(j <= steps) {
						this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[0].x + x * delta),hxClipper_ClipperOffset.round(this.mSrcPoly[0].y + y1 * delta)));
						var x2 = x;
						x = x * this.mCos - this.mSin * y1;
						y1 = x2 * this.mSin + y1 * this.mCos;
						j++;
					}
				} else {
					var x1 = -1.0;
					var y2 = -1.0;
					var _g21 = 0;
					while(_g21 < 4) {
						var j1 = _g21++;
						this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[0].x + x1 * delta),hxClipper_ClipperOffset.round(this.mSrcPoly[0].y + y2 * delta)));
						if(x1 < 0) x1 = 1; else if(y2 < 0) y2 = 1; else x1 = -1;
					}
				}
				this.mDestPolys.push(this.mDestPoly);
				continue;
			}
			this.mNormals.length = 0;
			var _g3 = 0;
			var _g22 = len - 1;
			while(_g3 < _g22) {
				var j2 = _g3++;
				this.mNormals.push(hxClipper_ClipperOffset.getUnitNormal(this.mSrcPoly[j2],this.mSrcPoly[j2 + 1]));
			}
			if(node1.mEndtype == hxClipper_EndType.ET_CLOSED_LINE || node1.mEndtype == hxClipper_EndType.ET_CLOSED_POLYGON) this.mNormals.push(hxClipper_ClipperOffset.getUnitNormal(this.mSrcPoly[len - 1],this.mSrcPoly[0])); else this.mNormals.push(this.mNormals[len - 2].clone());
			if(node1.mEndtype == hxClipper_EndType.ET_CLOSED_POLYGON) {
				var k = len - 1;
				var _g23 = 0;
				while(_g23 < len) {
					var j3 = _g23++;
					k = this.offsetPoint(j3,k,node1.mJoinType);
				}
				this.mDestPolys.push(this.mDestPoly);
			} else if(node1.mEndtype == hxClipper_EndType.ET_CLOSED_LINE) {
				var k1 = len - 1;
				var _g24 = 0;
				while(_g24 < len) {
					var j4 = _g24++;
					k1 = this.offsetPoint(j4,k1,node1.mJoinType);
				}
				this.mDestPolys.push(this.mDestPoly);
				this.mDestPoly = [];
				var n = this.mNormals[len - 1].clone();
				var nj = len - 1;
				while(nj > 0) {
					this.mNormals[nj] = new hxClipper_DoublePoint(-this.mNormals[nj - 1].x,-this.mNormals[nj - 1].y);
					nj--;
				}
				this.mNormals[0] = new hxClipper_DoublePoint(-n.x,-n.y);
				k1 = 0;
				nj = len - 1;
				while(nj >= 0) {
					k1 = this.offsetPoint(nj,k1,node1.mJoinType);
					nj--;
				}
				this.mDestPolys.push(this.mDestPoly);
			} else {
				var k2 = 0;
				var _g31 = 1;
				var _g25 = len - 1;
				while(_g31 < _g25) {
					var j5 = _g31++;
					k2 = this.offsetPoint(j5,k2,node1.mJoinType);
				}
				var pt1;
				if(node1.mEndtype == hxClipper_EndType.ET_OPEN_BUTT) {
					var j6 = len - 1;
					pt1 = new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j6].x + this.mNormals[j6].x * delta),hxClipper_ClipperOffset.round(this.mSrcPoly[j6].y + this.mNormals[j6].y * delta));
					this.mDestPoly.push(pt1);
					pt1 = new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j6].x - this.mNormals[j6].x * delta),hxClipper_ClipperOffset.round(this.mSrcPoly[j6].y - this.mNormals[j6].y * delta));
					this.mDestPoly.push(pt1);
				} else {
					var j7 = len - 1;
					k2 = len - 2;
					this.mSinA = 0;
					this.mNormals[j7] = new hxClipper_DoublePoint(-this.mNormals[j7].x,-this.mNormals[j7].y);
					if(node1.mEndtype == hxClipper_EndType.ET_OPEN_SQUARE) this.doSquare(j7,k2); else this.doRound(j7,k2);
				}
				var nj1 = len - 1;
				while(nj1 > 0) {
					this.mNormals[nj1] = new hxClipper_DoublePoint(-this.mNormals[nj1 - 1].x,-this.mNormals[nj1 - 1].y);
					nj1--;
				}
				this.mNormals[0] = new hxClipper_DoublePoint(-this.mNormals[1].x,-this.mNormals[1].y);
				k2 = len - 1;
				nj1 = k2 - 1;
				while(nj1 > 0) {
					k2 = this.offsetPoint(nj1,k2,node1.mJoinType);
					nj1--;
				}
				if(node1.mEndtype == hxClipper_EndType.ET_OPEN_BUTT) {
					pt1 = new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[0].x - this.mNormals[0].x * delta),hxClipper_ClipperOffset.round(this.mSrcPoly[0].y - this.mNormals[0].y * delta));
					this.mDestPoly.push(pt1);
					pt1 = new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[0].x + this.mNormals[0].x * delta),hxClipper_ClipperOffset.round(this.mSrcPoly[0].y + this.mNormals[0].y * delta));
					this.mDestPoly.push(pt1);
				} else {
					k2 = 1;
					this.mSinA = 0;
					if(node1.mEndtype == hxClipper_EndType.ET_OPEN_SQUARE) this.doSquare(0,1); else this.doRound(0,1);
				}
				this.mDestPolys.push(this.mDestPoly);
			}
		}
	}
	,execute: function(solution,delta) {
		if((solution instanceof Array) && solution.__enum__ == null) return this.executePaths(solution,delta); else if(js_Boot.__instanceof(solution,hxClipper_PolyTree)) return this.executePolyTree(solution,delta); else throw new js__$Boot_HaxeError(new hxClipper_ClipperException("`solution` must be either a Paths or a PolyTree"));
	}
	,executePaths: function(solution,delta) {
		solution.length = 0;
		this.fixOrientations();
		this.doOffset(delta);
		var clpr = new hxClipper_Clipper();
		clpr.addPaths(this.mDestPolys,hxClipper_PolyType.PT_SUBJECT,true);
		if(delta > 0) clpr.executePaths(hxClipper_ClipType.CT_UNION,solution,hxClipper_PolyFillType.PFT_POSITIVE,hxClipper_PolyFillType.PFT_POSITIVE); else {
			var r = hxClipper_ClipperBase.getBounds(this.mDestPolys);
			var outer = [];
			outer.push(new hxClipper_IntPoint(r.left - 10,r.bottom + 10));
			outer.push(new hxClipper_IntPoint(r.right + 10,r.bottom + 10));
			outer.push(new hxClipper_IntPoint(r.right + 10,r.top - 10));
			outer.push(new hxClipper_IntPoint(r.left - 10,r.top - 10));
			clpr.addPath(outer,hxClipper_PolyType.PT_SUBJECT,true);
			clpr.reverseSolution = true;
			clpr.executePaths(hxClipper_ClipType.CT_UNION,solution,hxClipper_PolyFillType.PFT_NEGATIVE,hxClipper_PolyFillType.PFT_NEGATIVE);
			if(solution.length > 0) solution.shift();
		}
	}
	,executePolyTree: function(solution,delta) {
		solution.clear();
		this.fixOrientations();
		this.doOffset(delta);
		var clpr = new hxClipper_Clipper();
		clpr.addPaths(this.mDestPolys,hxClipper_PolyType.PT_SUBJECT,true);
		if(delta > 0) clpr.executePolyTree(hxClipper_ClipType.CT_UNION,solution,hxClipper_PolyFillType.PFT_POSITIVE,hxClipper_PolyFillType.PFT_POSITIVE); else {
			var r = hxClipper_ClipperBase.getBounds(this.mDestPolys);
			var outer = [];
			outer.push(new hxClipper_IntPoint(r.left - 10,r.bottom + 10));
			outer.push(new hxClipper_IntPoint(r.right + 10,r.bottom + 10));
			outer.push(new hxClipper_IntPoint(r.right + 10,r.top - 10));
			outer.push(new hxClipper_IntPoint(r.left - 10,r.top - 10));
			clpr.addPath(outer,hxClipper_PolyType.PT_SUBJECT,true);
			clpr.reverseSolution = true;
			clpr.executePolyTree(hxClipper_ClipType.CT_UNION,solution,hxClipper_PolyFillType.PFT_NEGATIVE,hxClipper_PolyFillType.PFT_NEGATIVE);
			if(solution.get_numChildren() == 1 && solution.get_children()[0].get_numChildren() > 0) {
				var outerNode = solution.get_children()[0];
				solution.get_children()[0] = outerNode.get_children()[0];
				solution.get_children()[0].mParent = solution;
				var _g1 = 1;
				var _g = outerNode.get_numChildren();
				while(_g1 < _g) {
					var i = _g1++;
					solution.addChild(outerNode.get_children()[i]);
				}
			} else solution.clear();
		}
	}
	,offsetPoint: function(j,k,joinType) {
		this.mSinA = this.mNormals[k].x * this.mNormals[j].y - this.mNormals[j].x * this.mNormals[k].y;
		if(Math.abs(this.mSinA * this.mDelta) < 1.0) {
			var cosA = this.mNormals[k].x * this.mNormals[j].x + this.mNormals[j].y * this.mNormals[k].y;
			if(cosA > 0) {
				this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + this.mNormals[k].x * this.mDelta),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + this.mNormals[k].y * this.mDelta)));
				return k;
			}
		} else if(this.mSinA > 1.0) this.mSinA = 1.0; else if(this.mSinA < -1.0) this.mSinA = -1.0;
		if(this.mSinA * this.mDelta < 0) {
			this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + this.mNormals[k].x * this.mDelta),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + this.mNormals[k].y * this.mDelta)));
			this.mDestPoly.push(this.mSrcPoly[j]);
			this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + this.mNormals[j].x * this.mDelta),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + this.mNormals[j].y * this.mDelta)));
		} else switch(joinType[1]) {
		case 2:
			var r = 1 + (this.mNormals[j].x * this.mNormals[k].x + this.mNormals[j].y * this.mNormals[k].y);
			if(r >= this.mMiterLim) this.doMiter(j,k,r); else this.doSquare(j,k);
			break;
		case 0:
			this.doSquare(j,k);
			break;
		case 1:
			this.doRound(j,k);
			break;
		}
		k = j;
		return k;
	}
	,doSquare: function(j,k) {
		var dx = Math.tan(Math.atan2(this.mSinA,this.mNormals[k].x * this.mNormals[j].x + this.mNormals[k].y * this.mNormals[j].y) / 4);
		this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + this.mDelta * (this.mNormals[k].x - this.mNormals[k].y * dx)),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + this.mDelta * (this.mNormals[k].y + this.mNormals[k].x * dx))));
		this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + this.mDelta * (this.mNormals[j].x + this.mNormals[j].y * dx)),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + this.mDelta * (this.mNormals[j].y - this.mNormals[j].x * dx))));
	}
	,doMiter: function(j,k,r) {
		var q = this.mDelta / r;
		this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + (this.mNormals[k].x + this.mNormals[j].x) * q),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + (this.mNormals[k].y + this.mNormals[j].y) * q)));
	}
	,doRound: function(j,k) {
		var a = Math.atan2(this.mSinA,this.mNormals[k].x * this.mNormals[j].x + this.mNormals[k].y * this.mNormals[j].y);
		var steps = Std["int"](Math.max(Std["int"](hxClipper_ClipperOffset.round(this.mStepsPerRad * Math.abs(a))),1));
		var x = this.mNormals[k].x;
		var y = this.mNormals[k].y;
		var x2;
		var _g = 0;
		while(_g < steps) {
			var i = _g++;
			this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + x * this.mDelta),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + y * this.mDelta)));
			x2 = x;
			x = x * this.mCos - this.mSin * y;
			y = x2 * this.mSin + y * this.mCos;
		}
		this.mDestPoly.push(new hxClipper_IntPoint(hxClipper_ClipperOffset.round(this.mSrcPoly[j].x + this.mNormals[j].x * this.mDelta),hxClipper_ClipperOffset.round(this.mSrcPoly[j].y + this.mNormals[j].y * this.mDelta)));
	}
	,__class__: hxClipper_ClipperOffset
};
var hxClipper_ClipperException = function(description) {
	this.desc = description;
};
hxClipper_ClipperException.__name__ = ["hxClipper","ClipperException"];
hxClipper_ClipperException.prototype = {
	desc: null
	,toString: function() {
		return this.desc;
	}
	,__class__: hxClipper_ClipperException
};
var hxClipper_InternalTools = function() { };
hxClipper_InternalTools.__name__ = ["hxClipper","InternalTools"];
hxClipper_InternalTools.clear = function(array) {
	array.length = 0;
};
hxClipper_InternalTools.xor = function(a,b) {
	return a && !b || b && !a;
};
var js__$Boot_HaxeError = function(val) {
	Error.call(this);
	this.val = val;
	this.message = String(val);
	if(Error.captureStackTrace) Error.captureStackTrace(this,js__$Boot_HaxeError);
};
js__$Boot_HaxeError.__name__ = ["js","_Boot","HaxeError"];
js__$Boot_HaxeError.__super__ = Error;
js__$Boot_HaxeError.prototype = $extend(Error.prototype,{
	val: null
	,__class__: js__$Boot_HaxeError
});
var js_Boot = function() { };
js_Boot.__name__ = ["js","Boot"];
js_Boot.__unhtml = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
};
js_Boot.__trace = function(v,i) {
	var msg;
	if(i != null) msg = i.fileName + ":" + i.lineNumber + ": "; else msg = "";
	msg += js_Boot.__string_rec(v,"");
	if(i != null && i.customParams != null) {
		var _g = 0;
		var _g1 = i.customParams;
		while(_g < _g1.length) {
			var v1 = _g1[_g];
			++_g;
			msg += "," + js_Boot.__string_rec(v1,"");
		}
	}
	var d;
	if(typeof(document) != "undefined" && (d = document.getElementById("haxe:trace")) != null) d.innerHTML += js_Boot.__unhtml(msg) + "<br/>"; else if(typeof console != "undefined" && console.log != null) console.log(msg);
};
js_Boot.getClass = function(o) {
	if((o instanceof Array) && o.__enum__ == null) return Array; else {
		var cl = o.__class__;
		if(cl != null) return cl;
		var name = js_Boot.__nativeClassName(o);
		if(name != null) return js_Boot.__resolveNativeClass(name);
		return null;
	}
};
js_Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str2 = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i1 = _g1++;
					if(i1 != 2) str2 += "," + js_Boot.__string_rec(o[i1],s); else str2 += js_Boot.__string_rec(o[i1],s);
				}
				return str2 + ")";
			}
			var l = o.length;
			var i;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js_Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			haxe_CallStack.lastException = e;
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
js_Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0;
		var _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js_Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js_Boot.__interfLoop(cc.__super__,cl);
};
js_Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Array:
		return (o instanceof Array) && o.__enum__ == null;
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) return true;
				if(js_Boot.__interfLoop(js_Boot.getClass(o),cl)) return true;
			} else if(typeof(cl) == "object" && js_Boot.__isNativeObj(cl)) {
				if(o instanceof cl) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
};
js_Boot.__nativeClassName = function(o) {
	var name = js_Boot.__toStr.call(o).slice(8,-1);
	if(name == "Object" || name == "Function" || name == "Math" || name == "JSON") return null;
	return name;
};
js_Boot.__isNativeObj = function(o) {
	return js_Boot.__nativeClassName(o) != null;
};
js_Boot.__resolveNativeClass = function(name) {
	if(typeof window != "undefined") return window[name]; else return global[name];
};
var js_html_compat_ArrayBuffer = function(a) {
	if((a instanceof Array) && a.__enum__ == null) {
		this.a = a;
		this.byteLength = a.length;
	} else {
		var len = a;
		this.a = [];
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			this.a[i] = 0;
		}
		this.byteLength = len;
	}
};
js_html_compat_ArrayBuffer.__name__ = ["js","html","compat","ArrayBuffer"];
js_html_compat_ArrayBuffer.sliceImpl = function(begin,end) {
	var u = new Uint8Array(this,begin,end == null?null:end - begin);
	var result = new ArrayBuffer(u.byteLength);
	var resultArray = new Uint8Array(result);
	resultArray.set(u);
	return result;
};
js_html_compat_ArrayBuffer.prototype = {
	byteLength: null
	,a: null
	,slice: function(begin,end) {
		return new js_html_compat_ArrayBuffer(this.a.slice(begin,end));
	}
	,__class__: js_html_compat_ArrayBuffer
};
var js_html_compat_DataView = function(buffer,byteOffset,byteLength) {
	this.buf = buffer;
	if(byteOffset == null) this.offset = 0; else this.offset = byteOffset;
	if(byteLength == null) this.length = buffer.byteLength - this.offset; else this.length = byteLength;
	if(this.offset < 0 || this.length < 0 || this.offset + this.length > buffer.byteLength) throw new js__$Boot_HaxeError(haxe_io_Error.OutsideBounds);
};
js_html_compat_DataView.__name__ = ["js","html","compat","DataView"];
js_html_compat_DataView.prototype = {
	buf: null
	,offset: null
	,length: null
	,getInt8: function(byteOffset) {
		var v = this.buf.a[this.offset + byteOffset];
		if(v >= 128) return v - 256; else return v;
	}
	,getUint8: function(byteOffset) {
		return this.buf.a[this.offset + byteOffset];
	}
	,getInt16: function(byteOffset,littleEndian) {
		var v = this.getUint16(byteOffset,littleEndian);
		if(v >= 32768) return v - 65536; else return v;
	}
	,getUint16: function(byteOffset,littleEndian) {
		if(littleEndian) return this.buf.a[this.offset + byteOffset] | this.buf.a[this.offset + byteOffset + 1] << 8; else return this.buf.a[this.offset + byteOffset] << 8 | this.buf.a[this.offset + byteOffset + 1];
	}
	,getInt32: function(byteOffset,littleEndian) {
		var p = this.offset + byteOffset;
		var a = this.buf.a[p++];
		var b = this.buf.a[p++];
		var c = this.buf.a[p++];
		var d = this.buf.a[p++];
		if(littleEndian) return a | b << 8 | c << 16 | d << 24; else return d | c << 8 | b << 16 | a << 24;
	}
	,getUint32: function(byteOffset,littleEndian) {
		var v = this.getInt32(byteOffset,littleEndian);
		if(v < 0) return v + 4294967296.; else return v;
	}
	,getFloat32: function(byteOffset,littleEndian) {
		return haxe_io_FPHelper.i32ToFloat(this.getInt32(byteOffset,littleEndian));
	}
	,getFloat64: function(byteOffset,littleEndian) {
		var a = this.getInt32(byteOffset,littleEndian);
		var b = this.getInt32(byteOffset + 4,littleEndian);
		return haxe_io_FPHelper.i64ToDouble(littleEndian?a:b,littleEndian?b:a);
	}
	,setInt8: function(byteOffset,value) {
		if(value < 0) this.buf.a[byteOffset + this.offset] = value + 128 & 255; else this.buf.a[byteOffset + this.offset] = value & 255;
	}
	,setUint8: function(byteOffset,value) {
		this.buf.a[byteOffset + this.offset] = value & 255;
	}
	,setInt16: function(byteOffset,value,littleEndian) {
		this.setUint16(byteOffset,value < 0?value + 65536:value,littleEndian);
	}
	,setUint16: function(byteOffset,value,littleEndian) {
		var p = byteOffset + this.offset;
		if(littleEndian) {
			this.buf.a[p] = value & 255;
			this.buf.a[p++] = value >> 8 & 255;
		} else {
			this.buf.a[p++] = value >> 8 & 255;
			this.buf.a[p] = value & 255;
		}
	}
	,setInt32: function(byteOffset,value,littleEndian) {
		this.setUint32(byteOffset,value,littleEndian);
	}
	,setUint32: function(byteOffset,value,littleEndian) {
		var p = byteOffset + this.offset;
		if(littleEndian) {
			this.buf.a[p++] = value & 255;
			this.buf.a[p++] = value >> 8 & 255;
			this.buf.a[p++] = value >> 16 & 255;
			this.buf.a[p++] = value >>> 24;
		} else {
			this.buf.a[p++] = value >>> 24;
			this.buf.a[p++] = value >> 16 & 255;
			this.buf.a[p++] = value >> 8 & 255;
			this.buf.a[p++] = value & 255;
		}
	}
	,setFloat32: function(byteOffset,value,littleEndian) {
		this.setUint32(byteOffset,haxe_io_FPHelper.floatToI32(value),littleEndian);
	}
	,setFloat64: function(byteOffset,value,littleEndian) {
		var i64 = haxe_io_FPHelper.doubleToI64(value);
		if(littleEndian) {
			this.setUint32(byteOffset,i64.low);
			this.setUint32(byteOffset,i64.high);
		} else {
			this.setUint32(byteOffset,i64.high);
			this.setUint32(byteOffset,i64.low);
		}
	}
	,__class__: js_html_compat_DataView
};
var js_html_compat_Uint8Array = function() { };
js_html_compat_Uint8Array.__name__ = ["js","html","compat","Uint8Array"];
js_html_compat_Uint8Array._new = function(arg1,offset,length) {
	var arr;
	if(typeof(arg1) == "number") {
		arr = [];
		var _g = 0;
		while(_g < arg1) {
			var i = _g++;
			arr[i] = 0;
		}
		arr.byteLength = arr.length;
		arr.byteOffset = 0;
		arr.buffer = new js_html_compat_ArrayBuffer(arr);
	} else if(js_Boot.__instanceof(arg1,js_html_compat_ArrayBuffer)) {
		var buffer = arg1;
		if(offset == null) offset = 0;
		if(length == null) length = buffer.byteLength - offset;
		if(offset == 0) arr = buffer.a; else arr = buffer.a.slice(offset,offset + length);
		arr.byteLength = arr.length;
		arr.byteOffset = offset;
		arr.buffer = buffer;
	} else if((arg1 instanceof Array) && arg1.__enum__ == null) {
		arr = arg1.slice();
		arr.byteLength = arr.length;
		arr.byteOffset = 0;
		arr.buffer = new js_html_compat_ArrayBuffer(arr);
	} else throw new js__$Boot_HaxeError("TODO " + Std.string(arg1));
	arr.subarray = js_html_compat_Uint8Array._subarray;
	arr.set = js_html_compat_Uint8Array._set;
	return arr;
};
js_html_compat_Uint8Array._set = function(arg,offset) {
	var t = this;
	if(js_Boot.__instanceof(arg.buffer,js_html_compat_ArrayBuffer)) {
		var a = arg;
		if(arg.byteLength + offset > t.byteLength) throw new js__$Boot_HaxeError("set() outside of range");
		var _g1 = 0;
		var _g = arg.byteLength;
		while(_g1 < _g) {
			var i = _g1++;
			t[i + offset] = a[i];
		}
	} else if((arg instanceof Array) && arg.__enum__ == null) {
		var a1 = arg;
		if(a1.length + offset > t.byteLength) throw new js__$Boot_HaxeError("set() outside of range");
		var _g11 = 0;
		var _g2 = a1.length;
		while(_g11 < _g2) {
			var i1 = _g11++;
			t[i1 + offset] = a1[i1];
		}
	} else throw new js__$Boot_HaxeError("TODO");
};
js_html_compat_Uint8Array._subarray = function(start,end) {
	var t = this;
	var a = js_html_compat_Uint8Array._new(t.slice(start,end));
	a.byteOffset = start;
	return a;
};
var sui_Sui = function() {
	this.grid = new sui_components_Grid();
	this.el = this.grid.el;
};
sui_Sui.__name__ = ["sui","Sui"];
sui_Sui.createArray = function(defaultValue,defaultElementValue,createControl,options) {
	return new sui_controls_ArrayControl((function($this) {
		var $r;
		var t;
		{
			var _0 = defaultValue;
			if(null == _0) t = null; else t = _0;
		}
		$r = t != null?t:[];
		return $r;
	}(this)),defaultElementValue,createControl,options);
};
sui_Sui.createBool = function(defaultValue,options) {
	if(defaultValue == null) defaultValue = false;
	return new sui_controls_BoolControl(defaultValue,options);
};
sui_Sui.createColor = function(defaultValue,options) {
	if(defaultValue == null) defaultValue = "#AA0000";
	return new sui_controls_ColorControl(defaultValue,options);
};
sui_Sui.createDate = function(defaultValue,options) {
	if(null == defaultValue) defaultValue = new Date();
	{
		var _g;
		var t;
		var _0 = options;
		var _1;
		if(null == _0) t = null; else if(null == (_1 = _0.listonly)) t = null; else t = _1;
		if(t != null) _g = t; else _g = false;
		var _g1;
		var t1;
		var _01 = options;
		var _11;
		if(null == _01) t1 = null; else if(null == (_11 = _01.kind)) t1 = null; else t1 = _11;
		if(t1 != null) _g1 = t1; else _g1 = sui_controls_DateKind.DateOnly;
		if(_g != null) switch(_g) {
		case true:
			return new sui_controls_DateSelectControl(defaultValue,options);
		default:
			switch(_g1[1]) {
			case 1:
				return new sui_controls_DateTimeControl(defaultValue,options);
			default:
				return new sui_controls_DateControl(defaultValue,options);
			}
		} else switch(_g1[1]) {
		case 1:
			return new sui_controls_DateTimeControl(defaultValue,options);
		default:
			return new sui_controls_DateControl(defaultValue,options);
		}
	}
};
sui_Sui.collapsible = function(label,collapsed,attachTo,position) {
	if(collapsed == null) collapsed = false;
	var sui1 = new sui_Sui();
	var folder = sui1.folder((function($this) {
		var $r;
		var t;
		{
			var _0 = label;
			if(null == _0) t = null; else t = _0;
		}
		$r = t != null?t:"";
		return $r;
	}(this)),{ collapsible : true, collapsed : collapsed});
	sui1.attach(attachTo,position);
	return folder;
};
sui_Sui.createFloat = function(defaultValue,options) {
	if(defaultValue == null) defaultValue = 0.0;
	{
		var _g;
		var t;
		var _0 = options;
		var _1;
		if(null == _0) t = null; else if(null == (_1 = _0.listonly)) t = null; else t = _1;
		if(t != null) _g = t; else _g = false;
		var _g1;
		var t1;
		var _01 = options;
		var _11;
		if(null == _01) t1 = null; else if(null == (_11 = _01.kind)) t1 = null; else t1 = _11;
		if(t1 != null) _g1 = t1; else _g1 = sui_controls_FloatKind.FloatNumber;
		if(_g != null) switch(_g) {
		case true:
			return new sui_controls_NumberSelectControl(defaultValue,options);
		default:
			switch(_g1[1]) {
			case 1:
				return new sui_controls_TimeControl(defaultValue,options);
			default:
				if(null != options && options.min != null && options.max != null) return new sui_controls_FloatRangeControl(defaultValue,options); else return new sui_controls_FloatControl(defaultValue,options);
			}
		} else switch(_g1[1]) {
		case 1:
			return new sui_controls_TimeControl(defaultValue,options);
		default:
			if(null != options && options.min != null && options.max != null) return new sui_controls_FloatRangeControl(defaultValue,options); else return new sui_controls_FloatControl(defaultValue,options);
		}
	}
};
sui_Sui.createInt = function(defaultValue,options) {
	if(defaultValue == null) defaultValue = 0;
	if((function($this) {
		var $r;
		var t;
		{
			var _0 = options;
			var _1;
			if(null == _0) t = null; else if(null == (_1 = _0.listonly)) t = null; else t = _1;
		}
		$r = t != null?t:false;
		return $r;
	}(this))) return new sui_controls_NumberSelectControl(defaultValue,options); else if(null != options && options.min != null && options.max != null) return new sui_controls_IntRangeControl(defaultValue,options); else return new sui_controls_IntControl(defaultValue,options);
};
sui_Sui.createIntMap = function(defaultValue,createKeyControl,createValueControl,options) {
	return new sui_controls_MapControl(defaultValue,function() {
		return new haxe_ds_IntMap();
	},createKeyControl,createValueControl,options);
};
sui_Sui.createLabel = function(defaultValue,label,callback) {
	if(defaultValue == null) defaultValue = "";
	return new sui_controls_LabelControl(defaultValue);
};
sui_Sui.createObjectMap = function(defaultValue,createKeyControl,createValueControl,options) {
	return new sui_controls_MapControl(defaultValue,function() {
		return new haxe_ds_ObjectMap();
	},createKeyControl,createValueControl,options);
};
sui_Sui.createStringMap = function(defaultValue,createKeyControl,createValueControl,options) {
	return new sui_controls_MapControl(defaultValue,function() {
		return new haxe_ds_StringMap();
	},createKeyControl,createValueControl,options);
};
sui_Sui.createText = function(defaultValue,options) {
	if(defaultValue == null) defaultValue = "";
	{
		var _g;
		var t;
		var _0 = options;
		var _1;
		if(null == _0) t = null; else if(null == (_1 = _0.listonly)) t = null; else t = _1;
		if(t != null) _g = t; else _g = false;
		var _g1;
		var t1;
		var _01 = options;
		var _11;
		if(null == _01) t1 = null; else if(null == (_11 = _01.kind)) t1 = null; else t1 = _11;
		if(t1 != null) _g1 = t1; else _g1 = sui_controls_TextKind.PlainText;
		if(_g != null) switch(_g) {
		case true:
			return new sui_controls_TextSelectControl(defaultValue,options);
		default:
			switch(_g1[1]) {
			case 0:
				return new sui_controls_EmailControl(defaultValue,options);
			case 1:
				return new sui_controls_PasswordControl(defaultValue,options);
			case 3:
				return new sui_controls_TelControl(defaultValue,options);
			case 2:
				return new sui_controls_SearchControl(defaultValue,options);
			case 5:
				return new sui_controls_UrlControl(defaultValue,options);
			default:
				return new sui_controls_TextControl(defaultValue,options);
			}
		} else switch(_g1[1]) {
		case 0:
			return new sui_controls_EmailControl(defaultValue,options);
		case 1:
			return new sui_controls_PasswordControl(defaultValue,options);
		case 3:
			return new sui_controls_TelControl(defaultValue,options);
		case 2:
			return new sui_controls_SearchControl(defaultValue,options);
		case 5:
			return new sui_controls_UrlControl(defaultValue,options);
		default:
			return new sui_controls_TextControl(defaultValue,options);
		}
	}
};
sui_Sui.createTrigger = function(actionLabel,options) {
	return new sui_controls_TriggerControl(actionLabel,options);
};
sui_Sui.prototype = {
	el: null
	,grid: null
	,array: function(label,defaultValue,defaultElementValue,createControl,options,callback) {
		return this.control(label,sui_Sui.createArray(defaultValue,defaultElementValue,createControl,options),callback);
	}
	,bool: function(label,defaultValue,options,callback) {
		if(defaultValue == null) defaultValue = false;
		return this.control(label,sui_Sui.createBool(defaultValue,options),callback);
	}
	,choice: function(label,createControl,list) {
		var select = sui_Sui.createText(list[0].value,{ listonly : true, list : list});
		var container = { el : dots_Html.parseNodes("<div class=\"sui-choice\">\r\n<header class=\"sui-choice-header\"></header>\r\n<div class=\"sui-choice-options\"></div>\r\n</div>")[0]};
		var header = dots_Query.first(".sui-choice-header",container.el);
		var options = dots_Query.first(".sui-choice-options",container.el);
		header.appendChild(select.el);
		select.streams.value.subscribe(function(value) {
			var container1 = createControl(value);
			options.innerHTML = "";
			if(null == container1) null; else options.appendChild(container1.el);
		});
		this.grid.add(null == label?sui_components_CellContent.Single(container):sui_components_CellContent.HorizontalPair(new sui_controls_LabelControl(label),container));
	}
	,color: function(label,defaultValue,options,callback) {
		if(defaultValue == null) defaultValue = "#AA0000";
		return this.control(label,sui_Sui.createColor(defaultValue,options),callback);
	}
	,date: function(label,defaultValue,options,callback) {
		return this.control(label,sui_Sui.createDate(defaultValue,options),callback);
	}
	,'float': function(label,defaultValue,options,callback) {
		if(defaultValue == null) defaultValue = 0.0;
		return this.control(label,sui_Sui.createFloat(defaultValue,options),callback);
	}
	,folder: function(label,options) {
		var collapsible;
		var t;
		var _0 = options;
		var _1;
		if(null == _0) t = null; else if(null == (_1 = _0.collapsible)) t = null; else t = _1;
		if(t != null) collapsible = t; else collapsible = true;
		var collapsed;
		var t1;
		var _01 = options;
		var _11;
		if(null == _01) t1 = null; else if(null == (_11 = _01.collapsed)) t1 = null; else t1 = _11;
		if(t1 != null) collapsed = t1; else collapsed = false;
		var sui1 = new sui_Sui();
		var header = { el : dots_Html.parseNodes("<header class=\"sui-folder\">\r\n<i class=\"sui-trigger-toggle sui-icon sui-icon-collapse\"></i>\r\n" + label + "</header>")[0]};
		var trigger = dots_Query.first(".sui-trigger-toggle",header.el);
		if(collapsible) {
			header.el.classList.add("sui-collapsible");
			if(collapsed) sui1.grid.el.style.display = "none";
			var collapse = thx_stream_EmitterBools.negate(thx_stream_dom_Dom.streamEvent(header.el,"click",false).map(function(_) {
				return collapsed = !collapsed;
			}));
			collapse.subscribe(thx_core_Functions1.join(thx_stream_dom_Dom.subscribeToggleVisibility(sui1.grid.el),thx_stream_dom_Dom.subscribeSwapClass(trigger,"sui-icon-collapse","sui-icon-expand")));
		} else trigger.style.display = "none";
		sui1.grid.el.classList.add("sui-grid-inner");
		this.grid.add(sui_components_CellContent.VerticalPair(header,sui1.grid));
		return sui1;
	}
	,'int': function(label,defaultValue,options,callback) {
		if(defaultValue == null) defaultValue = 0;
		return this.control(label,sui_Sui.createInt(defaultValue,options),callback);
	}
	,intMap: function(label,defaultValue,createValueControl,options,callback) {
		return this.control(label,sui_Sui.createIntMap(defaultValue,function(v) {
			return sui_Sui.createInt(v);
		},createValueControl,options),callback);
	}
	,label: function(defaultValue,label,callback) {
		if(defaultValue == null) defaultValue = "";
		return this.control(label,sui_Sui.createLabel(defaultValue),callback);
	}
	,objectMap: function(label,defaultValue,createKeyControl,createValueControl,options,callback) {
		return this.control(label,sui_Sui.createObjectMap(defaultValue,createKeyControl,createValueControl,options),callback);
	}
	,stringMap: function(label,defaultValue,createValueControl,options,callback) {
		return this.control(label,sui_Sui.createStringMap(defaultValue,function(v) {
			return sui_Sui.createText(v);
		},createValueControl,options),callback);
	}
	,text: function(label,defaultValue,options,callback) {
		if(defaultValue == null) defaultValue = "";
		return this.control(label,sui_Sui.createText(defaultValue,options),callback);
	}
	,trigger: function(actionLabel,label,options,callback) {
		return this.control(label,new sui_controls_TriggerControl(actionLabel,options),function(_) {
			callback();
		});
	}
	,control: function(label,control,callback) {
		this.grid.add(null == label?sui_components_CellContent.Single(control):sui_components_CellContent.HorizontalPair(new sui_controls_LabelControl(label),control));
		control.streams.value.subscribe(callback);
		return control;
	}
	,attach: function(el,anchor) {
		if(null == el) el = window.document.body;
		this.el.classList.add((function($this) {
			var $r;
			var t;
			{
				var _0 = anchor;
				if(null == _0) t = null; else t = _0;
			}
			$r = t != null?t:el == window.document.body?"sui-top-right":"sui-append";
			return $r;
		}(this)));
		el.appendChild(this.el);
	}
	,__class__: sui_Sui
};
var sui_components_Grid = function() {
	this.el = dots_Html.parseNodes("<table class=\"sui-grid\"></table>")[0];
};
sui_components_Grid.__name__ = ["sui","components","Grid"];
sui_components_Grid.prototype = {
	el: null
	,add: function(cell) {
		var _g = this;
		switch(cell[1]) {
		case 0:
			var control = cell[2];
			var container = dots_Html.parseNodes("<tr class=\"sui-single\"><td colspan=\"2\"></td></tr>")[0];
			dots_Query.first("td",container).appendChild(control.el);
			this.el.appendChild(container);
			break;
		case 2:
			var right = cell[3];
			var left = cell[2];
			var container1 = dots_Html.parseNodes("<tr class=\"sui-horizontal\"><td class=\"sui-left\"></td><td class=\"sui-right\"></td></tr>")[0];
			dots_Query.first(".sui-left",container1).appendChild(left.el);
			dots_Query.first(".sui-right",container1).appendChild(right.el);
			this.el.appendChild(container1);
			break;
		case 1:
			var bottom = cell[3];
			var top = cell[2];
			var containers = dots_Html.nodeListToArray(dots_Html.parseNodes("<tr class=\"sui-vertical sui-top\"><td colspan=\"2\"></td></tr><tr class=\"sui-vertical sui-bottom\"><td colspan=\"2\"></td></tr>"));
			dots_Query.first("td",containers[0]).appendChild(top.el);
			dots_Query.first("td",containers[1]).appendChild(bottom.el);
			containers.map(function(_) {
				return _g.el.appendChild(_);
			});
			break;
		}
	}
	,__class__: sui_components_Grid
};
var sui_components_CellContent = { __ename__ : ["sui","components","CellContent"], __constructs__ : ["Single","VerticalPair","HorizontalPair"] };
sui_components_CellContent.Single = function(control) { var $x = ["Single",0,control]; $x.__enum__ = sui_components_CellContent; $x.toString = $estr; return $x; };
sui_components_CellContent.VerticalPair = function(top,bottom) { var $x = ["VerticalPair",1,top,bottom]; $x.__enum__ = sui_components_CellContent; $x.toString = $estr; return $x; };
sui_components_CellContent.HorizontalPair = function(left,right) { var $x = ["HorizontalPair",2,left,right]; $x.__enum__ = sui_components_CellContent; $x.toString = $estr; return $x; };
var sui_controls_IControl = function() { };
sui_controls_IControl.__name__ = ["sui","controls","IControl"];
sui_controls_IControl.prototype = {
	el: null
	,defaultValue: null
	,streams: null
	,set: null
	,get: null
	,isEnabled: null
	,isFocused: null
	,disable: null
	,enable: null
	,focus: null
	,blur: null
	,reset: null
	,__class__: sui_controls_IControl
};
var sui_controls_ArrayControl = function(defaultValue,defaultElementValue,createElementControl,options) {
	var _g = this;
	var template = "<div class=\"sui-control sui-control-single sui-type-array\">\r\n<ul class=\"sui-array\"></ul>\r\n<div class=\"sui-array-add\"><i class=\"sui-icon sui-icon-add\"></i></div>\r\n</div>";
	var t;
	var _0 = options;
	if(null == _0) t = null; else t = _0;
	if(t != null) options = t; else options = { };
	this.defaultValue = defaultValue;
	this.defaultElementValue = defaultElementValue;
	this.createElementControl = createElementControl;
	this.elements = [];
	this.length = 0;
	this.values = new sui_controls_ControlValues(defaultValue);
	this.streams = new sui_controls_ControlStreams(this.values.value,this.values.focused.debounce(0),this.values.enabled);
	this.el = dots_Html.parseNodes(template)[0];
	this.ul = dots_Query.first("ul",this.el);
	this.addButton = dots_Query.first(".sui-icon-add",this.el);
	thx_stream_dom_Dom.streamEvent(this.addButton,"click",false).subscribe(function(_) {
		_g.addControl(defaultElementValue);
	});
	this.values.enabled.subscribe(function(v) {
		if(v) _g.el.classList.add("sui-disabled"); else _g.el.classList.remove("sui-disabled");
	});
	this.values.focused.subscribe(function(v1) {
		if(v1) _g.el.classList.add("sui-focused"); else _g.el.classList.remove("sui-focused");
	});
	thx_stream_EmitterBools.negate(this.values.enabled).subscribe(thx_stream_dom_Dom.subscribeToggleClass(this.el,"sui-disabled"));
	this.values.enabled.subscribe(function(v2) {
		_g.elements.map(function(_1) {
			if(v2) _1.control.enable(); else _1.control.disable();
			return;
		});
	});
	this.setValue(defaultValue);
	this.reset();
	if(options.autofocus) this.focus();
	if(options.disabled) this.disable();
};
sui_controls_ArrayControl.__name__ = ["sui","controls","ArrayControl"];
sui_controls_ArrayControl.__interfaces__ = [sui_controls_IControl];
sui_controls_ArrayControl.prototype = {
	el: null
	,ul: null
	,addButton: null
	,defaultValue: null
	,defaultElementValue: null
	,streams: null
	,createElementControl: null
	,length: null
	,values: null
	,elements: null
	,addControl: function(value) {
		var _g = this;
		var o = { control : this.createElementControl(value), el : dots_Html.parseNodes("<li class=\"sui-array-item\">\r\n    <div class=\"sui-move\"><i class=\"sui-icon-mini sui-icon-up\"></i><i class=\"sui-icon-mini sui-icon-down\"></i></div>\r\n    <div class=\"sui-control-container\"></div>\r\n    <div class=\"sui-remove\"><i class=\"sui-icon sui-icon-remove\"></i></div>\r\n</li>")[0], index : this.length++};
		this.ul.appendChild(o.el);
		var removeElement = dots_Query.first(".sui-icon-remove",o.el);
		var upElement = dots_Query.first(".sui-icon-up",o.el);
		var downElement = dots_Query.first(".sui-icon-down",o.el);
		var controlContainer = dots_Query.first(".sui-control-container",o.el);
		controlContainer.appendChild(o.control.el);
		thx_stream_dom_Dom.streamEvent(removeElement,"click",false).subscribe(function(_) {
			_g.ul.removeChild(o.el);
			_g.elements.splice(o.index,1);
			var _g2 = o.index;
			var _g1 = _g.elements.length;
			while(_g2 < _g1) {
				var i = _g2++;
				_g.elements[i].index--;
			}
			_g.length--;
			_g.updateValue();
		});
		this.elements.push(o);
		o.control.streams.value.subscribe(function(_1) {
			_g.updateValue();
		});
		o.control.streams.focused.subscribe(thx_stream_dom_Dom.subscribeToggleClass(o.el,"sui-focus"));
		o.control.streams.focused.feed(this.values.focused);
		thx_stream_dom_Dom.streamEvent(upElement,"click",false).subscribe(function(_2) {
			var pos = o.index;
			var prev = _g.elements[pos - 1];
			_g.elements[pos] = prev;
			_g.elements[pos - 1] = o;
			prev.index = pos;
			o.index = pos - 1;
			_g.ul.insertBefore(o.el,prev.el);
			_g.updateValue();
		});
		thx_stream_dom_Dom.streamEvent(downElement,"click",false).subscribe(function(_3) {
			var pos1 = o.index;
			var next = _g.elements[pos1 + 1];
			_g.elements[pos1] = next;
			_g.elements[pos1 + 1] = o;
			next.index = pos1;
			o.index = pos1 + 1;
			_g.ul.insertBefore(next.el,o.el);
			_g.updateValue();
		});
	}
	,setValue: function(v) {
		var _g = this;
		v.map(function(_) {
			_g.addControl(_);
			return;
		});
	}
	,getValue: function() {
		return this.elements.map(function(_) {
			return _.control.get();
		});
	}
	,updateValue: function() {
		this.values.value.set(this.getValue());
	}
	,set: function(v) {
		this.clear();
		this.setValue(v);
		this.values.value.set(v);
	}
	,get: function() {
		return this.values.value.get();
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
		if(this.elements.length > 0) thx_core_Arrays.last(this.elements).control.focus();
	}
	,blur: function() {
		var el = window.document.activeElement;
		(function(_) {
			if(null == _) null; else el.blur();
			return;
		})(thx_core_Arrays.first(this.elements.filter(function(_1) {
			return _1.control.el == el;
		})));
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,clear: function() {
		var _g = this;
		this.length = 0;
		this.elements.map(function(item) {
			_g.ul.removeChild(item.el);
		});
		this.elements = [];
	}
	,__class__: sui_controls_ArrayControl
};
var sui_controls_SingleInputControl = function(defaultValue,event,name,type,options) {
	var _g = this;
	var template = "<div class=\"sui-control sui-control-single sui-type-" + name + "\"><input type=\"" + type + "\"/></div>";
	if(null == options) options = { };
	if(null == options.allownull) options.allownull = true;
	this.defaultValue = defaultValue;
	this.values = new sui_controls_ControlValues(defaultValue);
	this.streams = new sui_controls_ControlStreams(this.values.value,this.values.focused,this.values.enabled);
	this.el = dots_Html.parseNodes(template)[0];
	this.input = dots_Query.first("input",this.el);
	this.values.enabled.subscribe(function(v) {
		if(v) {
			_g.el.classList.add("sui-disabled");
			_g.input.removeAttribute("disabled");
		} else {
			_g.el.classList.remove("sui-disabled");
			_g.input.setAttribute("disabled","disabled");
		}
	});
	this.values.focused.subscribe(function(v1) {
		if(v1) _g.el.classList.add("sui-focused"); else _g.el.classList.remove("sui-focused");
	});
	this.setInput(defaultValue);
	thx_stream_dom_Dom.streamFocus(this.input).feed(this.values.focused);
	thx_stream_dom_Dom.streamEvent(this.input,event).map(function(_) {
		return _g.getInput();
	}).feed(this.values.value);
	if(!options.allownull) this.input.setAttribute("required","required");
	if(options.autofocus) this.focus();
	if(options.disabled) this.disable();
};
sui_controls_SingleInputControl.__name__ = ["sui","controls","SingleInputControl"];
sui_controls_SingleInputControl.__interfaces__ = [sui_controls_IControl];
sui_controls_SingleInputControl.prototype = {
	el: null
	,input: null
	,defaultValue: null
	,streams: null
	,values: null
	,setInput: function(v) {
		throw new thx_core_error_AbstractMethod({ fileName : "SingleInputControl.hx", lineNumber : 64, className : "sui.controls.SingleInputControl", methodName : "setInput"});
	}
	,getInput: function() {
		throw new thx_core_error_AbstractMethod({ fileName : "SingleInputControl.hx", lineNumber : 67, className : "sui.controls.SingleInputControl", methodName : "getInput"});
	}
	,set: function(v) {
		this.setInput(v);
		this.values.value.set(v);
	}
	,get: function() {
		return this.values.value.get();
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
		this.input.focus();
	}
	,blur: function() {
		this.input.blur();
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,__class__: sui_controls_SingleInputControl
};
var sui_controls_BaseDateControl = function(value,name,type,dateToString,options) {
	if(null == options) options = { };
	this.dateToString = dateToString;
	sui_controls_SingleInputControl.call(this,value,"input",name,type,options);
	if(null != options.autocomplete) this.input.setAttribute("autocomplete",options.autocomplete?"on":"off");
	if(null != options.min) this.input.setAttribute("min",dateToString(options.min));
	if(null != options.max) this.input.setAttribute("max",dateToString(options.max));
	if(null != options.list) new sui_controls_DataList(this.el,options.list.map(function(o) {
		return { label : o.label, value : dateToString(o.value)};
	})).applyTo(this.input); else if(null != options.values) new sui_controls_DataList(this.el,options.values.map(function(o1) {
		return { label : HxOverrides.dateStr(o1), value : dateToString(o1)};
	})).applyTo(this.input);
};
sui_controls_BaseDateControl.__name__ = ["sui","controls","BaseDateControl"];
sui_controls_BaseDateControl.toRFCDate = function(date) {
	var y = date.getFullYear();
	var m = StringTools.lpad("" + (date.getMonth() + 1),"0",2);
	var d = StringTools.lpad("" + date.getDate(),"0",2);
	return "" + y + "-" + m + "-" + d;
};
sui_controls_BaseDateControl.toRFCDateTime = function(date) {
	var d = sui_controls_BaseDateControl.toRFCDate(date);
	var hh = StringTools.lpad("" + date.getHours(),"0",2);
	var mm = StringTools.lpad("" + date.getMinutes(),"0",2);
	var ss = StringTools.lpad("" + date.getSeconds(),"0",2);
	return "" + d + "T" + hh + ":" + mm + ":" + ss;
};
sui_controls_BaseDateControl.toRFCDateTimeNoSeconds = function(date) {
	var d = sui_controls_BaseDateControl.toRFCDate(date);
	var hh = StringTools.lpad("" + date.getHours(),"0",2);
	var mm = StringTools.lpad("" + date.getMinutes(),"0",2);
	return "" + d + "T" + hh + ":" + mm + ":00";
};
sui_controls_BaseDateControl.fromRFC = function(date) {
	var dp = date.split("T")[0];
	var dt;
	var t1;
	var _0 = date;
	var _1;
	var _2;
	if(null == _0) t1 = null; else if(null == (_1 = _0.split("T"))) t1 = null; else if(null == (_2 = _1[1])) t1 = null; else t1 = _2;
	if(t1 != null) dt = t1; else dt = "00:00:00";
	var p = dp.split("-");
	var y = Std.parseInt(p[0]);
	var m = Std.parseInt(p[1]) - 1;
	var d = Std.parseInt(p[2]);
	var t = dt.split(":");
	var hh = Std.parseInt(t[0]);
	var mm = Std.parseInt(t[1]);
	var ss = Std.parseInt(t[2]);
	return new Date(y,m,d,hh,mm,ss);
};
sui_controls_BaseDateControl.__super__ = sui_controls_SingleInputControl;
sui_controls_BaseDateControl.prototype = $extend(sui_controls_SingleInputControl.prototype,{
	dateToString: null
	,setInput: function(v) {
		this.input.value = this.dateToString(v);
	}
	,getInput: function() {
		if(thx_core_Strings.isEmpty(this.input.value)) return null; else return sui_controls_BaseDateControl.fromRFC(this.input.value);
	}
	,__class__: sui_controls_BaseDateControl
});
var sui_controls_BaseTextControl = function(value,name,type,options) {
	if(null == options) options = { };
	sui_controls_SingleInputControl.call(this,value,"input",name,type,options);
	if(null != options.maxlength) this.input.setAttribute("maxlength","" + options.maxlength);
	if(null != options.autocomplete) this.input.setAttribute("autocomplete",options.autocomplete?"on":"off");
	if(null != options.pattern) this.input.setAttribute("pattern","" + options.pattern);
	if(null != options.placeholder) this.input.setAttribute("placeholder","" + options.placeholder);
	if(null != options.list) new sui_controls_DataList(this.el,options.list).applyTo(this.input); else if(null != options.values) sui_controls_DataList.fromArray(this.el,options.values).applyTo(this.input);
};
sui_controls_BaseTextControl.__name__ = ["sui","controls","BaseTextControl"];
sui_controls_BaseTextControl.__super__ = sui_controls_SingleInputControl;
sui_controls_BaseTextControl.prototype = $extend(sui_controls_SingleInputControl.prototype,{
	setInput: function(v) {
		this.input.value = v;
	}
	,getInput: function() {
		return this.input.value;
	}
	,__class__: sui_controls_BaseTextControl
});
var sui_controls_BoolControl = function(value,options) {
	sui_controls_SingleInputControl.call(this,value,"change","bool","checkbox",options);
};
sui_controls_BoolControl.__name__ = ["sui","controls","BoolControl"];
sui_controls_BoolControl.__super__ = sui_controls_SingleInputControl;
sui_controls_BoolControl.prototype = $extend(sui_controls_SingleInputControl.prototype,{
	setInput: function(v) {
		this.input.checked = v;
	}
	,getInput: function() {
		return this.input.checked;
	}
	,__class__: sui_controls_BoolControl
});
var sui_controls_DoubleInputControl = function(defaultValue,name,event1,type1,event2,type2,filter,options) {
	var _g = this;
	var template = "<div class=\"sui-control sui-control-double sui-type-" + name + "\"><input class=\"input1\" type=\"" + type1 + "\"/><input class=\"input2\" type=\"" + type2 + "\"/></div>";
	if(null == options) options = { };
	if(null == options.allownull) options.allownull = true;
	this.defaultValue = defaultValue;
	this.values = new sui_controls_ControlValues(defaultValue);
	this.streams = new sui_controls_ControlStreams(this.values.value,this.values.focused,this.values.enabled);
	this.el = dots_Html.parseNodes(template)[0];
	this.input1 = dots_Query.first(".input1",this.el);
	this.input2 = dots_Query.first(".input2",this.el);
	this.values.enabled.subscribe(function(v) {
		if(v) {
			_g.el.classList.add("sui-disabled");
			_g.input1.removeAttribute("disabled");
			_g.input2.removeAttribute("disabled");
		} else {
			_g.el.classList.remove("sui-disabled");
			_g.input1.setAttribute("disabled","disabled");
			_g.input2.setAttribute("disabled","disabled");
		}
	});
	this.values.focused.subscribe(function(v1) {
		if(v1) _g.el.classList.add("sui-focused"); else _g.el.classList.remove("sui-focused");
	});
	thx_stream_dom_Dom.streamFocus(this.input1).merge(thx_stream_dom_Dom.streamFocus(this.input2)).feed(this.values.focused);
	thx_stream_dom_Dom.streamEvent(this.input1,event1).map(function(_) {
		return _g.getInput1();
	}).subscribe(function(v2) {
		_g.setInput2(v2);
		_g.values.value.set(v2);
	});
	thx_stream_dom_Dom.streamEvent(this.input2,event2).map(function(_1) {
		return _g.getInput2();
	}).filter(filter).subscribe(function(v3) {
		_g.setInput1(v3);
		_g.values.value.set(v3);
	});
	if(!options.allownull) {
		this.input1.setAttribute("required","required");
		this.input2.setAttribute("required","required");
	}
	if(options.autofocus) this.focus();
	if(options.disabled) this.disable();
	if(!dots_Detect.supportsInput(type1)) this.input1.style.display = "none";
};
sui_controls_DoubleInputControl.__name__ = ["sui","controls","DoubleInputControl"];
sui_controls_DoubleInputControl.__interfaces__ = [sui_controls_IControl];
sui_controls_DoubleInputControl.prototype = {
	el: null
	,input1: null
	,input2: null
	,defaultValue: null
	,streams: null
	,values: null
	,setInputs: function(v) {
		this.setInput1(v);
		this.setInput2(v);
	}
	,setInput1: function(v) {
		throw new thx_core_error_AbstractMethod({ fileName : "DoubleInputControl.hx", lineNumber : 89, className : "sui.controls.DoubleInputControl", methodName : "setInput1"});
	}
	,setInput2: function(v) {
		throw new thx_core_error_AbstractMethod({ fileName : "DoubleInputControl.hx", lineNumber : 92, className : "sui.controls.DoubleInputControl", methodName : "setInput2"});
	}
	,getInput1: function() {
		throw new thx_core_error_AbstractMethod({ fileName : "DoubleInputControl.hx", lineNumber : 95, className : "sui.controls.DoubleInputControl", methodName : "getInput1"});
	}
	,getInput2: function() {
		throw new thx_core_error_AbstractMethod({ fileName : "DoubleInputControl.hx", lineNumber : 98, className : "sui.controls.DoubleInputControl", methodName : "getInput2"});
	}
	,set: function(v) {
		this.setInputs(v);
		this.values.value.set(v);
	}
	,get: function() {
		return this.values.value.get();
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
		this.input2.focus();
	}
	,blur: function() {
		var el = window.document.activeElement;
		if(el == this.input1 || el == this.input2) el.blur();
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,__class__: sui_controls_DoubleInputControl
};
var sui_controls_ColorControl = function(value,options) {
	if(null == options) options = { };
	sui_controls_DoubleInputControl.call(this,value,"color","input","color","input","text",($_=sui_controls_ColorControl.PATTERN,$bind($_,$_.match)),options);
	if(null != options.autocomplete) this.input2.setAttribute("autocomplete",options.autocomplete?"on":"off");
	if(null != options.list) new sui_controls_DataList(this.el,options.list).applyTo(this.input1).applyTo(this.input2); else if(null != options.values) sui_controls_DataList.fromArray(this.el,options.values).applyTo(this.input1).applyTo(this.input2);
	this.setInputs(value);
};
sui_controls_ColorControl.__name__ = ["sui","controls","ColorControl"];
sui_controls_ColorControl.__super__ = sui_controls_DoubleInputControl;
sui_controls_ColorControl.prototype = $extend(sui_controls_DoubleInputControl.prototype,{
	setInput1: function(v) {
		this.input1.value = v;
	}
	,setInput2: function(v) {
		this.input2.value = v;
	}
	,getInput1: function() {
		return this.input1.value;
	}
	,getInput2: function() {
		return this.input2.value;
	}
	,__class__: sui_controls_ColorControl
});
var sui_controls_ControlStreams = function(value,focused,enabled) {
	this.value = value;
	this.focused = focused;
	this.enabled = enabled;
};
sui_controls_ControlStreams.__name__ = ["sui","controls","ControlStreams"];
sui_controls_ControlStreams.prototype = {
	value: null
	,focused: null
	,enabled: null
	,__class__: sui_controls_ControlStreams
};
var sui_controls_ControlValues = function(defaultValue) {
	this.value = new thx_stream_Value(defaultValue);
	this.focused = new thx_stream_Value(false);
	this.enabled = new thx_stream_Value(true);
};
sui_controls_ControlValues.__name__ = ["sui","controls","ControlValues"];
sui_controls_ControlValues.prototype = {
	value: null
	,focused: null
	,enabled: null
	,__class__: sui_controls_ControlValues
};
var sui_controls_DataList = function(container,values) {
	this.id = "sui-dl-" + ++sui_controls_DataList.nid;
	var datalist = dots_Html.parse("<datalist id=\"" + this.id + "\" style=\"display:none\">" + values.map(sui_controls_DataList.toOption).join("") + "</datalist>");
	container.appendChild(datalist);
};
sui_controls_DataList.__name__ = ["sui","controls","DataList"];
sui_controls_DataList.fromArray = function(container,values) {
	return new sui_controls_DataList(container,values.map(function(v) {
		return { value : v, label : v};
	}));
};
sui_controls_DataList.toOption = function(o) {
	return "<option value=\"" + StringTools.htmlEscape(o.value) + "\">" + o.label + "</option>";
};
sui_controls_DataList.prototype = {
	id: null
	,applyTo: function(el) {
		el.setAttribute("list",this.id);
		return this;
	}
	,__class__: sui_controls_DataList
};
var sui_controls_DateControl = function(value,options) {
	sui_controls_BaseDateControl.call(this,value,"date","date",sui_controls_BaseDateControl.toRFCDate,options);
};
sui_controls_DateControl.__name__ = ["sui","controls","DateControl"];
sui_controls_DateControl.__super__ = sui_controls_BaseDateControl;
sui_controls_DateControl.prototype = $extend(sui_controls_BaseDateControl.prototype,{
	__class__: sui_controls_DateControl
});
var sui_controls_SelectControl = function(defaultValue,name,options) {
	this.count = 0;
	var _g = this;
	var template = "<div class=\"sui-control sui-control-single sui-type-" + name + "\"><select></select></div>";
	if(null == options) throw new js__$Boot_HaxeError(" A select control requires an option object with values or list set");
	if(null == options.values && null == options.list) throw new js__$Boot_HaxeError(" A select control requires either the values or list option");
	if(null == options.allownull) options.allownull = false;
	this.defaultValue = defaultValue;
	this.values = new sui_controls_ControlValues(defaultValue);
	this.streams = new sui_controls_ControlStreams(this.values.value,this.values.focused,this.values.enabled);
	this.el = dots_Html.parseNodes(template)[0];
	this.select = dots_Query.first("select",this.el);
	this.values.enabled.subscribe(function(v) {
		if(v) {
			_g.el.classList.add("sui-disabled");
			_g.select.removeAttribute("disabled");
		} else {
			_g.el.classList.remove("sui-disabled");
			_g.select.setAttribute("disabled","disabled");
		}
	});
	this.values.focused.subscribe(function(v1) {
		if(v1) _g.el.classList.add("sui-focused"); else _g.el.classList.remove("sui-focused");
	});
	this.options = [];
	(options.allownull?[{ label : (function($this) {
		var $r;
		var t;
		{
			var _0 = options;
			var _1;
			if(null == _0) t = null; else if(null == (_1 = _0.labelfornull)) t = null; else t = _1;
		}
		$r = t != null?t:"- none -";
		return $r;
	}(this)), value : null}]:[]).concat((function($this) {
		var $r;
		var t1;
		{
			var _01 = options;
			var _11;
			if(null == _01) t1 = null; else if(null == (_11 = _01.list)) t1 = null; else t1 = _11;
		}
		$r = t1 != null?t1:options.values.map(function(_) {
			return { value : _, label : Std.string(_)};
		});
		return $r;
	}(this))).map(function(_2) {
		return _g.addOption(_2.label,_2.value);
	});
	this.setInput(defaultValue);
	thx_stream_dom_Dom.streamFocus(this.select).feed(this.values.focused);
	thx_stream_dom_Dom.streamEvent(this.select,"change").map(function(_3) {
		return _g.getInput();
	}).feed(this.values.value);
	if(options.autofocus) this.focus();
	if(options.disabled) this.disable();
};
sui_controls_SelectControl.__name__ = ["sui","controls","SelectControl"];
sui_controls_SelectControl.__interfaces__ = [sui_controls_IControl];
sui_controls_SelectControl.prototype = {
	el: null
	,select: null
	,defaultValue: null
	,streams: null
	,options: null
	,values: null
	,count: null
	,addOption: function(label,value) {
		var index = this.count++;
		var option = dots_Html.parseNodes("<option>" + label + "</option>")[0];
		this.options[index] = value;
		this.select.appendChild(option);
		return option;
	}
	,setInput: function(v) {
		var index = HxOverrides.indexOf(this.options,v,0);
		if(index < 0) throw new js__$Boot_HaxeError("value \"" + Std.string(v) + "\" is not included in this select control");
		this.select.selectedIndex = index;
	}
	,getInput: function() {
		return this.options[this.select.selectedIndex];
	}
	,set: function(v) {
		this.setInput(v);
		this.values.value.set(v);
	}
	,get: function() {
		return this.values.value.get();
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
		this.select.focus();
	}
	,blur: function() {
		this.select.blur();
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,__class__: sui_controls_SelectControl
};
var sui_controls_DateSelectControl = function(defaultValue,options) {
	sui_controls_SelectControl.call(this,defaultValue,"select-date",options);
};
sui_controls_DateSelectControl.__name__ = ["sui","controls","DateSelectControl"];
sui_controls_DateSelectControl.__super__ = sui_controls_SelectControl;
sui_controls_DateSelectControl.prototype = $extend(sui_controls_SelectControl.prototype,{
	__class__: sui_controls_DateSelectControl
});
var sui_controls_DateTimeControl = function(value,options) {
	sui_controls_BaseDateControl.call(this,value,"date-time","datetime-local",sui_controls_BaseDateControl.toRFCDateTimeNoSeconds,options);
};
sui_controls_DateTimeControl.__name__ = ["sui","controls","DateTimeControl"];
sui_controls_DateTimeControl.__super__ = sui_controls_BaseDateControl;
sui_controls_DateTimeControl.prototype = $extend(sui_controls_BaseDateControl.prototype,{
	__class__: sui_controls_DateTimeControl
});
var sui_controls_EmailControl = function(value,options) {
	if(null == options) options = { };
	if(null == options.placeholder) options.placeholder = "name@example.com";
	sui_controls_BaseTextControl.call(this,value,"email","email",options);
};
sui_controls_EmailControl.__name__ = ["sui","controls","EmailControl"];
sui_controls_EmailControl.__super__ = sui_controls_BaseTextControl;
sui_controls_EmailControl.prototype = $extend(sui_controls_BaseTextControl.prototype,{
	__class__: sui_controls_EmailControl
});
var sui_controls_NumberControl = function(value,name,options) {
	if(null == options) options = { };
	sui_controls_SingleInputControl.call(this,value,"input",name,"number",options);
	if(null != options.autocomplete) this.input.setAttribute("autocomplete",options.autocomplete?"on":"off");
	if(null != options.min) this.input.setAttribute("min","" + Std.string(options.min));
	if(null != options.max) this.input.setAttribute("max","" + Std.string(options.max));
	if(null != options.step) this.input.setAttribute("step","" + Std.string(options.step));
	if(null != options.placeholder) this.input.setAttribute("placeholder","" + options.placeholder);
	if(null != options.list) new sui_controls_DataList(this.el,options.list.map(function(o) {
		return { label : o.label, value : "" + Std.string(o.value)};
	})).applyTo(this.input); else if(null != options.values) new sui_controls_DataList(this.el,options.values.map(function(o1) {
		return { label : "" + Std.string(o1), value : "" + Std.string(o1)};
	})).applyTo(this.input);
};
sui_controls_NumberControl.__name__ = ["sui","controls","NumberControl"];
sui_controls_NumberControl.__super__ = sui_controls_SingleInputControl;
sui_controls_NumberControl.prototype = $extend(sui_controls_SingleInputControl.prototype,{
	__class__: sui_controls_NumberControl
});
var sui_controls_FloatControl = function(value,options) {
	sui_controls_NumberControl.call(this,value,"float",options);
};
sui_controls_FloatControl.__name__ = ["sui","controls","FloatControl"];
sui_controls_FloatControl.__super__ = sui_controls_NumberControl;
sui_controls_FloatControl.prototype = $extend(sui_controls_NumberControl.prototype,{
	setInput: function(v) {
		this.input.value = "" + v;
	}
	,getInput: function() {
		return parseFloat(this.input.value);
	}
	,__class__: sui_controls_FloatControl
});
var sui_controls_NumberRangeControl = function(value,options) {
	sui_controls_DoubleInputControl.call(this,value,"float-range","input","range","input","number",function(v) {
		return v != null;
	},options);
	if(null != options.autocomplete) {
		this.input1.setAttribute("autocomplete",options.autocomplete?"on":"off");
		this.input2.setAttribute("autocomplete",options.autocomplete?"on":"off");
	}
	if(null != options.min) {
		this.input1.setAttribute("min","" + Std.string(options.min));
		this.input2.setAttribute("min","" + Std.string(options.min));
	}
	if(null != options.max) {
		this.input1.setAttribute("max","" + Std.string(options.max));
		this.input2.setAttribute("max","" + Std.string(options.max));
	}
	if(null != options.step) {
		this.input1.setAttribute("step","" + Std.string(options.step));
		this.input2.setAttribute("step","" + Std.string(options.step));
	}
	if(null != options.placeholder) this.input2.setAttribute("placeholder","" + options.placeholder);
	if(null != options.list) new sui_controls_DataList(this.el,options.list.map(function(o) {
		return { label : o.label, value : "" + Std.string(o.value)};
	})).applyTo(this.input1).applyTo(this.input2); else if(null != options.values) new sui_controls_DataList(this.el,options.values.map(function(o1) {
		return { label : "" + Std.string(o1), value : "" + Std.string(o1)};
	})).applyTo(this.input1).applyTo(this.input2);
	this.setInputs(value);
};
sui_controls_NumberRangeControl.__name__ = ["sui","controls","NumberRangeControl"];
sui_controls_NumberRangeControl.__super__ = sui_controls_DoubleInputControl;
sui_controls_NumberRangeControl.prototype = $extend(sui_controls_DoubleInputControl.prototype,{
	setInput1: function(v) {
		this.input1.value = "" + Std.string(v);
	}
	,setInput2: function(v) {
		this.input2.value = "" + Std.string(v);
	}
	,__class__: sui_controls_NumberRangeControl
});
var sui_controls_FloatRangeControl = function(value,options) {
	if(null == options) options = { };
	if(null == options.min) options.min = Math.min(value,0);
	if(null == options.min) {
		var s;
		if(null != options.step) s = options.step; else s = 1;
		options.max = Math.max(value,s);
	}
	sui_controls_NumberRangeControl.call(this,value,options);
};
sui_controls_FloatRangeControl.__name__ = ["sui","controls","FloatRangeControl"];
sui_controls_FloatRangeControl.__super__ = sui_controls_NumberRangeControl;
sui_controls_FloatRangeControl.prototype = $extend(sui_controls_NumberRangeControl.prototype,{
	getInput1: function() {
		if(thx_core_Floats.canParse(this.input1.value)) return thx_core_Floats.parse(this.input1.value); else return null;
	}
	,getInput2: function() {
		if(thx_core_Floats.canParse(this.input2.value)) return thx_core_Floats.parse(this.input2.value); else return null;
	}
	,__class__: sui_controls_FloatRangeControl
});
var sui_controls_IntControl = function(value,options) {
	sui_controls_NumberControl.call(this,value,"int",options);
};
sui_controls_IntControl.__name__ = ["sui","controls","IntControl"];
sui_controls_IntControl.__super__ = sui_controls_NumberControl;
sui_controls_IntControl.prototype = $extend(sui_controls_NumberControl.prototype,{
	setInput: function(v) {
		this.input.value = "" + v;
	}
	,getInput: function() {
		return Std.parseInt(this.input.value);
	}
	,__class__: sui_controls_IntControl
});
var sui_controls_IntRangeControl = function(value,options) {
	if(null == options) options = { };
	if(null == options.min) if(value < 0) options.min = value; else options.min = 0;
	if(null == options.min) {
		var s;
		if(null != options.step) s = options.step; else s = 100;
		if(value > s) options.max = value; else options.max = s;
	}
	sui_controls_NumberRangeControl.call(this,value,options);
};
sui_controls_IntRangeControl.__name__ = ["sui","controls","IntRangeControl"];
sui_controls_IntRangeControl.__super__ = sui_controls_NumberRangeControl;
sui_controls_IntRangeControl.prototype = $extend(sui_controls_NumberRangeControl.prototype,{
	getInput1: function() {
		if(thx_core_Ints.canParse(this.input1.value)) return thx_core_Ints.parse(this.input1.value); else return null;
	}
	,getInput2: function() {
		if(thx_core_Ints.canParse(this.input2.value)) return thx_core_Ints.parse(this.input2.value); else return null;
	}
	,__class__: sui_controls_IntRangeControl
});
var sui_controls_LabelControl = function(defaultValue) {
	var _g = this;
	var template = "<div class=\"sui-control sui-control-single sui-type-label\"><output>" + defaultValue + "</output></div>";
	this.defaultValue = defaultValue;
	this.values = new sui_controls_ControlValues(defaultValue);
	this.streams = new sui_controls_ControlStreams(this.values.value,this.values.focused,this.values.enabled);
	this.el = dots_Html.parseNodes(template)[0];
	this.output = dots_Query.first("output",this.el);
	this.values.enabled.subscribe(function(v) {
		if(v) _g.el.classList.add("sui-disabled"); else _g.el.classList.remove("sui-disabled");
	});
};
sui_controls_LabelControl.__name__ = ["sui","controls","LabelControl"];
sui_controls_LabelControl.__interfaces__ = [sui_controls_IControl];
sui_controls_LabelControl.prototype = {
	el: null
	,output: null
	,defaultValue: null
	,streams: null
	,values: null
	,set: function(v) {
		this.output.innerHTML = v;
		this.values.value.set(v);
	}
	,get: function() {
		return this.values.value.get();
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
	}
	,blur: function() {
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,__class__: sui_controls_LabelControl
};
var sui_controls_MapControl = function(defaultValue,createMap,createKeyControl,createValueControl,options) {
	var _g = this;
	var template = "<div class=\"sui-control sui-control-single sui-type-array\">\r\n<table class=\"sui-map\"><tbody></tbody></table>\r\n<div class=\"sui-array-add\"><i class=\"sui-icon sui-icon-add\"></i></div>\r\n</div>";
	var t;
	var _0 = options;
	if(null == _0) t = null; else t = _0;
	if(t != null) options = t; else options = { };
	if(null == defaultValue) defaultValue = createMap();
	this.defaultValue = defaultValue;
	this.createMap = createMap;
	this.createKeyControl = createKeyControl;
	this.createValueControl = createValueControl;
	this.elements = [];
	this.length = 0;
	this.values = new sui_controls_ControlValues(defaultValue);
	this.streams = new sui_controls_ControlStreams(this.values.value,this.values.focused.debounce(0),this.values.enabled);
	this.el = dots_Html.parseNodes(template)[0];
	this.tbody = dots_Query.first("tbody",this.el);
	this.addButton = dots_Query.first(".sui-icon-add",this.el);
	thx_stream_dom_Dom.streamEvent(this.addButton,"click",false).subscribe(function(_) {
		_g.addControl(null,null);
	});
	this.values.enabled.subscribe(function(v) {
		if(v) _g.el.classList.add("sui-disabled"); else _g.el.classList.remove("sui-disabled");
	});
	this.values.focused.subscribe(function(v1) {
		if(v1) _g.el.classList.add("sui-focused"); else _g.el.classList.remove("sui-focused");
	});
	thx_stream_EmitterBools.negate(this.values.enabled).subscribe(thx_stream_dom_Dom.subscribeToggleClass(this.el,"sui-disabled"));
	this.values.enabled.subscribe(function(v2) {
		_g.elements.map(function(_1) {
			if(v2) {
				_1.controlKey.enable();
				_1.controlValue.enable();
			} else {
				_1.controlKey.disable();
				_1.controlValue.disable();
			}
			return;
		});
	});
	this.setValue(defaultValue);
	this.reset();
	if(options.autofocus) this.focus();
	if(options.disabled) this.disable();
};
sui_controls_MapControl.__name__ = ["sui","controls","MapControl"];
sui_controls_MapControl.__interfaces__ = [sui_controls_IControl];
sui_controls_MapControl.prototype = {
	el: null
	,tbody: null
	,addButton: null
	,defaultValue: null
	,streams: null
	,createMap: null
	,createKeyControl: null
	,createValueControl: null
	,length: null
	,values: null
	,elements: null
	,addControl: function(key,value) {
		var _g = this;
		var o = { controlKey : this.createKeyControl(key), controlValue : this.createValueControl(value), el : dots_Html.parseNodes("<tr class=\"sui-map-item\">\r\n<td class=\"sui-map-key\"></td>\r\n<td class=\"sui-map-value\"></td>\r\n<td class=\"sui-remove\"><i class=\"sui-icon sui-icon-remove\"></i></td>\r\n</tr>")[0], index : this.length++};
		this.tbody.appendChild(o.el);
		var removeElement = dots_Query.first(".sui-icon-remove",o.el);
		var controlKeyContainer = dots_Query.first(".sui-map-key",o.el);
		var controlValueContainer = dots_Query.first(".sui-map-value",o.el);
		controlKeyContainer.appendChild(o.controlKey.el);
		controlValueContainer.appendChild(o.controlValue.el);
		thx_stream_dom_Dom.streamEvent(removeElement,"click",false).subscribe(function(_) {
			_g.tbody.removeChild(o.el);
			_g.elements.splice(o.index,1);
			var _g2 = o.index;
			var _g1 = _g.elements.length;
			while(_g2 < _g1) {
				var i = _g2++;
				_g.elements[i].index--;
			}
			_g.length--;
			_g.updateValue();
		});
		this.elements.push(o);
		o.controlKey.streams.value.toNil().merge(o.controlValue.streams.value.toNil()).subscribe(function(_1) {
			_g.updateValue();
		});
		o.controlKey.streams.focused.merge(o.controlValue.streams.focused).subscribe(thx_stream_dom_Dom.subscribeToggleClass(o.el,"sui-focus"));
		o.controlKey.streams.focused.merge(o.controlValue.streams.focused).feed(this.values.focused);
	}
	,setValue: function(v) {
		var _g = this;
		thx_core_Iterators.map(v.keys(),function(_) {
			_g.addControl(_,v.get(_));
			return;
		});
	}
	,getValue: function() {
		var map = this.createMap();
		this.elements.map(function(o) {
			var k = o.controlKey.get();
			var v = o.controlValue.get();
			if(k == null || map.exists(k)) {
				o.controlKey.el.classList.add("sui-invalid");
				return;
			}
			o.controlKey.el.classList.remove("sui-invalid");
			map.set(k,v);
		});
		return map;
	}
	,updateValue: function() {
		this.values.value.set(this.getValue());
	}
	,set: function(v) {
		this.clear();
		this.setValue(v);
		this.values.value.set(v);
	}
	,get: function() {
		return this.values.value.get();
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
		if(this.elements.length > 0) thx_core_Arrays.last(this.elements).controlValue.focus();
	}
	,blur: function() {
		var el = window.document.activeElement;
		(function(_) {
			if(null == _) null; else el.blur();
			return;
		})(thx_core_Arrays.first(this.elements.filter(function(_1) {
			return _1.controlKey.el == el || _1.controlValue.el == el;
		})));
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,clear: function() {
		var _g = this;
		this.length = 0;
		this.elements.map(function(item) {
			_g.tbody.removeChild(item.el);
		});
		this.elements = [];
	}
	,__class__: sui_controls_MapControl
};
var sui_controls_NumberSelectControl = function(defaultValue,options) {
	sui_controls_SelectControl.call(this,defaultValue,"select-number",options);
};
sui_controls_NumberSelectControl.__name__ = ["sui","controls","NumberSelectControl"];
sui_controls_NumberSelectControl.__super__ = sui_controls_SelectControl;
sui_controls_NumberSelectControl.prototype = $extend(sui_controls_SelectControl.prototype,{
	__class__: sui_controls_NumberSelectControl
});
var sui_controls_DateKind = { __ename__ : ["sui","controls","DateKind"], __constructs__ : ["DateOnly","DateTime"] };
sui_controls_DateKind.DateOnly = ["DateOnly",0];
sui_controls_DateKind.DateOnly.toString = $estr;
sui_controls_DateKind.DateOnly.__enum__ = sui_controls_DateKind;
sui_controls_DateKind.DateTime = ["DateTime",1];
sui_controls_DateKind.DateTime.toString = $estr;
sui_controls_DateKind.DateTime.__enum__ = sui_controls_DateKind;
var sui_controls_FloatKind = { __ename__ : ["sui","controls","FloatKind"], __constructs__ : ["FloatNumber","FloatTime"] };
sui_controls_FloatKind.FloatNumber = ["FloatNumber",0];
sui_controls_FloatKind.FloatNumber.toString = $estr;
sui_controls_FloatKind.FloatNumber.__enum__ = sui_controls_FloatKind;
sui_controls_FloatKind.FloatTime = ["FloatTime",1];
sui_controls_FloatKind.FloatTime.toString = $estr;
sui_controls_FloatKind.FloatTime.__enum__ = sui_controls_FloatKind;
var sui_controls_TextKind = { __ename__ : ["sui","controls","TextKind"], __constructs__ : ["TextEmail","TextPassword","TextSearch","TextTel","PlainText","TextUrl"] };
sui_controls_TextKind.TextEmail = ["TextEmail",0];
sui_controls_TextKind.TextEmail.toString = $estr;
sui_controls_TextKind.TextEmail.__enum__ = sui_controls_TextKind;
sui_controls_TextKind.TextPassword = ["TextPassword",1];
sui_controls_TextKind.TextPassword.toString = $estr;
sui_controls_TextKind.TextPassword.__enum__ = sui_controls_TextKind;
sui_controls_TextKind.TextSearch = ["TextSearch",2];
sui_controls_TextKind.TextSearch.toString = $estr;
sui_controls_TextKind.TextSearch.__enum__ = sui_controls_TextKind;
sui_controls_TextKind.TextTel = ["TextTel",3];
sui_controls_TextKind.TextTel.toString = $estr;
sui_controls_TextKind.TextTel.__enum__ = sui_controls_TextKind;
sui_controls_TextKind.PlainText = ["PlainText",4];
sui_controls_TextKind.PlainText.toString = $estr;
sui_controls_TextKind.PlainText.__enum__ = sui_controls_TextKind;
sui_controls_TextKind.TextUrl = ["TextUrl",5];
sui_controls_TextKind.TextUrl.toString = $estr;
sui_controls_TextKind.TextUrl.__enum__ = sui_controls_TextKind;
var sui_controls_PasswordControl = function(value,options) {
	sui_controls_BaseTextControl.call(this,value,"text","password",options);
};
sui_controls_PasswordControl.__name__ = ["sui","controls","PasswordControl"];
sui_controls_PasswordControl.__super__ = sui_controls_BaseTextControl;
sui_controls_PasswordControl.prototype = $extend(sui_controls_BaseTextControl.prototype,{
	__class__: sui_controls_PasswordControl
});
var sui_controls_SearchControl = function(value,options) {
	if(null == options) options = { };
	sui_controls_BaseTextControl.call(this,value,"search","search",options);
};
sui_controls_SearchControl.__name__ = ["sui","controls","SearchControl"];
sui_controls_SearchControl.__super__ = sui_controls_BaseTextControl;
sui_controls_SearchControl.prototype = $extend(sui_controls_BaseTextControl.prototype,{
	__class__: sui_controls_SearchControl
});
var sui_controls_TelControl = function(value,options) {
	if(null == options) options = { };
	sui_controls_BaseTextControl.call(this,value,"tel","tel",options);
};
sui_controls_TelControl.__name__ = ["sui","controls","TelControl"];
sui_controls_TelControl.__super__ = sui_controls_BaseTextControl;
sui_controls_TelControl.prototype = $extend(sui_controls_BaseTextControl.prototype,{
	__class__: sui_controls_TelControl
});
var sui_controls_TextControl = function(value,options) {
	sui_controls_BaseTextControl.call(this,value,"text","text",options);
};
sui_controls_TextControl.__name__ = ["sui","controls","TextControl"];
sui_controls_TextControl.__super__ = sui_controls_BaseTextControl;
sui_controls_TextControl.prototype = $extend(sui_controls_BaseTextControl.prototype,{
	__class__: sui_controls_TextControl
});
var sui_controls_TextSelectControl = function(defaultValue,options) {
	sui_controls_SelectControl.call(this,defaultValue,"select-text",options);
};
sui_controls_TextSelectControl.__name__ = ["sui","controls","TextSelectControl"];
sui_controls_TextSelectControl.__super__ = sui_controls_SelectControl;
sui_controls_TextSelectControl.prototype = $extend(sui_controls_SelectControl.prototype,{
	__class__: sui_controls_TextSelectControl
});
var sui_controls_TimeControl = function(value,options) {
	if(null == options) options = { };
	sui_controls_SingleInputControl.call(this,value,"input","time","time",options);
	if(null != options.autocomplete) this.input.setAttribute("autocomplete",options.autocomplete?"on":"off");
	if(null != options.min) this.input.setAttribute("min",sui_controls_TimeControl.timeToString(options.min));
	if(null != options.max) this.input.setAttribute("max",sui_controls_TimeControl.timeToString(options.max));
	if(null != options.list) new sui_controls_DataList(this.el,options.list.map(function(o) {
		return { label : o.label, value : sui_controls_TimeControl.timeToString(o.value)};
	})).applyTo(this.input); else if(null != options.values) new sui_controls_DataList(this.el,options.values.map(function(o1) {
		return { label : sui_controls_TimeControl.timeToString(o1), value : sui_controls_TimeControl.timeToString(o1)};
	})).applyTo(this.input);
};
sui_controls_TimeControl.__name__ = ["sui","controls","TimeControl"];
sui_controls_TimeControl.timeToString = function(t) {
	var h = Math.floor(t / 3600000);
	t -= h * 3600000;
	var m = Math.floor(t / 60000);
	t -= m * 60000;
	var s = t / 1000;
	var hh = StringTools.lpad("" + h,"0",2);
	var mm = StringTools.lpad("" + m,"0",2);
	var ss;
	ss = (s >= 10?"":"0") + s;
	return "" + hh + ":" + mm + ":" + ss;
};
sui_controls_TimeControl.stringToTime = function(t) {
	var p = t.split(":");
	var h = Std.parseInt(p[0]);
	var m = Std.parseInt(p[1]);
	var s = parseFloat(p[2]);
	return s * 1000 + m * 60000 + h * 3600000;
};
sui_controls_TimeControl.__super__ = sui_controls_SingleInputControl;
sui_controls_TimeControl.prototype = $extend(sui_controls_SingleInputControl.prototype,{
	setInput: function(v) {
		this.input.value = sui_controls_TimeControl.timeToString(v);
	}
	,getInput: function() {
		return sui_controls_TimeControl.stringToTime(this.input.value);
	}
	,__class__: sui_controls_TimeControl
});
var sui_controls_TriggerControl = function(label,options) {
	var _g = this;
	var template = "<div class=\"sui-control sui-control-single sui-type-trigger\"><button>" + label + "</button></div>";
	if(null == options) options = { };
	this.defaultValue = thx_core_Nil.nil;
	this.el = dots_Html.parseNodes(template)[0];
	this.button = dots_Query.first("button",this.el);
	this.values = new sui_controls_ControlValues(thx_core_Nil.nil);
	var emitter = thx_stream_dom_Dom.streamEvent(this.button,"click",false).toNil();
	this.streams = new sui_controls_ControlStreams(emitter,this.values.focused,this.values.enabled);
	this.values.enabled.subscribe(function(v) {
		if(v) {
			_g.el.classList.add("sui-disabled");
			_g.button.removeAttribute("disabled");
		} else {
			_g.el.classList.remove("sui-disabled");
			_g.button.setAttribute("disabled","disabled");
		}
	});
	this.values.focused.subscribe(function(v1) {
		if(v1) _g.el.classList.add("sui-focused"); else _g.el.classList.remove("sui-focused");
	});
	thx_stream_dom_Dom.streamFocus(this.button).feed(this.values.focused);
	if(options.autofocus) this.focus();
	if(options.disabled) this.disable();
};
sui_controls_TriggerControl.__name__ = ["sui","controls","TriggerControl"];
sui_controls_TriggerControl.__interfaces__ = [sui_controls_IControl];
sui_controls_TriggerControl.prototype = {
	el: null
	,button: null
	,defaultValue: null
	,streams: null
	,values: null
	,set: function(v) {
		this.button.click();
	}
	,get: function() {
		return thx_core_Nil.nil;
	}
	,isEnabled: function() {
		return this.values.enabled.get();
	}
	,isFocused: function() {
		return this.values.focused.get();
	}
	,disable: function() {
		this.values.enabled.set(false);
	}
	,enable: function() {
		this.values.enabled.set(true);
	}
	,focus: function() {
		this.button.focus();
	}
	,blur: function() {
		this.button.blur();
	}
	,reset: function() {
		this.set(this.defaultValue);
	}
	,__class__: sui_controls_TriggerControl
};
var sui_controls_UrlControl = function(value,options) {
	if(null == options) options = { };
	if(null == options.placeholder) options.placeholder = "http://example.com";
	sui_controls_BaseTextControl.call(this,value,"url","url",options);
};
sui_controls_UrlControl.__name__ = ["sui","controls","UrlControl"];
sui_controls_UrlControl.__super__ = sui_controls_BaseTextControl;
sui_controls_UrlControl.prototype = $extend(sui_controls_BaseTextControl.prototype,{
	__class__: sui_controls_UrlControl
});
var sui_macro_Embed = function() { };
sui_macro_Embed.__name__ = ["sui","macro","Embed"];
var thx_core_Arrays = function() { };
thx_core_Arrays.__name__ = ["thx","core","Arrays"];
thx_core_Arrays.after = function(array,element) {
	return array.slice(HxOverrides.indexOf(array,element,0) + 1);
};
thx_core_Arrays.all = function(arr,predicate) {
	var _g = 0;
	while(_g < arr.length) {
		var item = arr[_g];
		++_g;
		if(!predicate(item)) return false;
	}
	return true;
};
thx_core_Arrays.any = function(arr,predicate) {
	var _g = 0;
	while(_g < arr.length) {
		var item = arr[_g];
		++_g;
		if(predicate(item)) return true;
	}
	return false;
};
thx_core_Arrays.at = function(arr,indexes) {
	return indexes.map(function(i) {
		return arr[i];
	});
};
thx_core_Arrays.before = function(array,element) {
	return array.slice(0,HxOverrides.indexOf(array,element,0));
};
thx_core_Arrays.compact = function(arr) {
	return arr.filter(function(v) {
		return null != v;
	});
};
thx_core_Arrays.contains = function(array,element,eq) {
	if(null == eq) return HxOverrides.indexOf(array,element,0) >= 0; else {
		var _g1 = 0;
		var _g = array.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(eq(array[i],element)) return true;
		}
		return false;
	}
};
thx_core_Arrays.cross = function(a,b) {
	var r = [];
	var _g = 0;
	while(_g < a.length) {
		var va = a[_g];
		++_g;
		var _g1 = 0;
		while(_g1 < b.length) {
			var vb = b[_g1];
			++_g1;
			r.push([va,vb]);
		}
	}
	return r;
};
thx_core_Arrays.crossMulti = function(array) {
	var acopy = array.slice();
	var result = acopy.shift().map(function(v) {
		return [v];
	});
	while(acopy.length > 0) {
		var array1 = acopy.shift();
		var tresult = result;
		result = [];
		var _g = 0;
		while(_g < array1.length) {
			var v1 = array1[_g];
			++_g;
			var _g1 = 0;
			while(_g1 < tresult.length) {
				var ar = tresult[_g1];
				++_g1;
				var t = ar.slice();
				t.push(v1);
				result.push(t);
			}
		}
	}
	return result;
};
thx_core_Arrays.distinct = function(array) {
	var result = [];
	var _g = 0;
	while(_g < array.length) {
		var v = array[_g];
		++_g;
		if(!thx_core_Arrays.contains(result,v)) result.push(v);
	}
	return result;
};
thx_core_Arrays.eachPair = function(array,callback) {
	var _g1 = 0;
	var _g = array.length;
	while(_g1 < _g) {
		var i = _g1++;
		var _g3 = i;
		var _g2 = array.length;
		while(_g3 < _g2) {
			var j = _g3++;
			if(!callback(array[i],array[j])) return;
		}
	}
};
thx_core_Arrays.equals = function(a,b,equality) {
	if(a == null || b == null || a.length != b.length) return false;
	if(null == equality) equality = thx_core_Functions.equality;
	var _g1 = 0;
	var _g = a.length;
	while(_g1 < _g) {
		var i = _g1++;
		if(!equality(a[i],b[i])) return false;
	}
	return true;
};
thx_core_Arrays.extract = function(a,predicate) {
	var _g1 = 0;
	var _g = a.length;
	while(_g1 < _g) {
		var i = _g1++;
		if(predicate(a[i])) return a.splice(i,1)[0];
	}
	return null;
};
thx_core_Arrays.find = function(array,predicate) {
	var _g = 0;
	while(_g < array.length) {
		var item = array[_g];
		++_g;
		if(predicate(item)) return item;
	}
	return null;
};
thx_core_Arrays.findLast = function(array,predicate) {
	var len = array.length;
	var j;
	var _g = 0;
	while(_g < len) {
		var i = _g++;
		j = len - i - 1;
		if(predicate(array[j])) return array[j];
	}
	return null;
};
thx_core_Arrays.first = function(array) {
	return array[0];
};
thx_core_Arrays.flatMap = function(array,callback) {
	return thx_core_Arrays.flatten(array.map(callback));
};
thx_core_Arrays.flatten = function(array) {
	return Array.prototype.concat.apply([],array);
};
thx_core_Arrays.from = function(array,element) {
	return array.slice(HxOverrides.indexOf(array,element,0));
};
thx_core_Arrays.head = function(array) {
	return array[0];
};
thx_core_Arrays.ifEmpty = function(value,alt) {
	if(null != value && 0 != value.length) return value; else return alt;
};
thx_core_Arrays.initial = function(array) {
	return array.slice(0,array.length - 1);
};
thx_core_Arrays.isEmpty = function(array) {
	return array.length == 0;
};
thx_core_Arrays.last = function(array) {
	return array[array.length - 1];
};
thx_core_Arrays.mapi = function(array,callback) {
	var r = [];
	var _g1 = 0;
	var _g = array.length;
	while(_g1 < _g) {
		var i = _g1++;
		r.push(callback(array[i],i));
	}
	return r;
};
thx_core_Arrays.mapRight = function(array,callback) {
	var i = array.length;
	var result = [];
	while(--i >= 0) result.push(callback(array[i]));
	return result;
};
thx_core_Arrays.order = function(array,sort) {
	var n = array.slice();
	n.sort(sort);
	return n;
};
thx_core_Arrays.pull = function(array,toRemove,equality) {
	var _g = 0;
	while(_g < toRemove.length) {
		var item = toRemove[_g];
		++_g;
		thx_core_Arrays.removeAll(array,item,equality);
	}
};
thx_core_Arrays.pushIf = function(array,condition,value) {
	if(condition) array.push(value);
	return array;
};
thx_core_Arrays.reduce = function(array,callback,initial) {
	return array.reduce(callback,initial);
};
thx_core_Arrays.resize = function(array,length,fill) {
	while(array.length < length) array.push(fill);
	array.splice(length,array.length - length);
	return array;
};
thx_core_Arrays.reducei = function(array,callback,initial) {
	return array.reduce(callback,initial);
};
thx_core_Arrays.reduceRight = function(array,callback,initial) {
	var i = array.length;
	while(--i >= 0) initial = callback(initial,array[i]);
	return initial;
};
thx_core_Arrays.removeAll = function(array,element,equality) {
	if(null == equality) equality = thx_core_Functions.equality;
	var i = array.length;
	while(--i >= 0) if(equality(array[i],element)) array.splice(i,1);
};
thx_core_Arrays.rest = function(array) {
	return array.slice(1);
};
thx_core_Arrays.sample = function(array,n) {
	n = thx_core_Ints.min(n,array.length);
	var copy = array.slice();
	var result = [];
	var _g = 0;
	while(_g < n) {
		var i = _g++;
		result.push(copy.splice(Std.random(copy.length),1)[0]);
	}
	return result;
};
thx_core_Arrays.sampleOne = function(array) {
	return array[Std.random(array.length)];
};
thx_core_Arrays.shuffle = function(a) {
	var t = thx_core_Ints.range(a.length);
	var array = [];
	while(t.length > 0) {
		var pos = Std.random(t.length);
		var index = t[pos];
		t.splice(pos,1);
		array.push(a[index]);
	}
	return array;
};
thx_core_Arrays.take = function(arr,n) {
	return arr.slice(0,n);
};
thx_core_Arrays.takeLast = function(arr,n) {
	return arr.slice(arr.length - n);
};
thx_core_Arrays.rotate = function(arr) {
	var result = [];
	var _g1 = 0;
	var _g = arr[0].length;
	while(_g1 < _g) {
		var i = _g1++;
		var row = [];
		result.push(row);
		var _g3 = 0;
		var _g2 = arr.length;
		while(_g3 < _g2) {
			var j = _g3++;
			row.push(arr[j][i]);
		}
	}
	return result;
};
thx_core_Arrays.zip = function(array1,array2) {
	var length = thx_core_Ints.min(array1.length,array2.length);
	var array = [];
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		array.push({ _0 : array1[i], _1 : array2[i]});
	}
	return array;
};
thx_core_Arrays.zip3 = function(array1,array2,array3) {
	var length = thx_core_ArrayInts.min([array1.length,array2.length,array3.length]);
	var array = [];
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		array.push({ _0 : array1[i], _1 : array2[i], _2 : array3[i]});
	}
	return array;
};
thx_core_Arrays.zip4 = function(array1,array2,array3,array4) {
	var length = thx_core_ArrayInts.min([array1.length,array2.length,array3.length,array4.length]);
	var array = [];
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		array.push({ _0 : array1[i], _1 : array2[i], _2 : array3[i], _3 : array4[i]});
	}
	return array;
};
thx_core_Arrays.zip5 = function(array1,array2,array3,array4,array5) {
	var length = thx_core_ArrayInts.min([array1.length,array2.length,array3.length,array4.length,array5.length]);
	var array = [];
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		array.push({ _0 : array1[i], _1 : array2[i], _2 : array3[i], _3 : array4[i], _4 : array5[i]});
	}
	return array;
};
thx_core_Arrays.unzip = function(array) {
	var a1 = [];
	var a2 = [];
	array.map(function(t) {
		a1.push(t._0);
		a2.push(t._1);
	});
	return { _0 : a1, _1 : a2};
};
thx_core_Arrays.unzip3 = function(array) {
	var a1 = [];
	var a2 = [];
	var a3 = [];
	array.map(function(t) {
		a1.push(t._0);
		a2.push(t._1);
		a3.push(t._2);
	});
	return { _0 : a1, _1 : a2, _2 : a3};
};
thx_core_Arrays.unzip4 = function(array) {
	var a1 = [];
	var a2 = [];
	var a3 = [];
	var a4 = [];
	array.map(function(t) {
		a1.push(t._0);
		a2.push(t._1);
		a3.push(t._2);
		a4.push(t._3);
	});
	return { _0 : a1, _1 : a2, _2 : a3, _3 : a4};
};
thx_core_Arrays.unzip5 = function(array) {
	var a1 = [];
	var a2 = [];
	var a3 = [];
	var a4 = [];
	var a5 = [];
	array.map(function(t) {
		a1.push(t._0);
		a2.push(t._1);
		a3.push(t._2);
		a4.push(t._3);
		a5.push(t._4);
	});
	return { _0 : a1, _1 : a2, _2 : a3, _3 : a4, _4 : a5};
};
var thx_core_ArrayFloats = function() { };
thx_core_ArrayFloats.__name__ = ["thx","core","ArrayFloats"];
thx_core_ArrayFloats.average = function(arr) {
	return thx_core_ArrayFloats.sum(arr) / arr.length;
};
thx_core_ArrayFloats.compact = function(arr) {
	return arr.filter(function(v) {
		return null != v && isFinite(v);
	});
};
thx_core_ArrayFloats.max = function(arr) {
	if(arr.length == 0) return null; else return arr.reduce(function(max,v) {
		if(v > max) return v; else return max;
	},arr[0]);
};
thx_core_ArrayFloats.min = function(arr) {
	if(arr.length == 0) return null; else return arr.reduce(function(min,v) {
		if(v < min) return v; else return min;
	},arr[0]);
};
thx_core_ArrayFloats.resize = function(array,length,fill) {
	if(fill == null) fill = 0.0;
	while(array.length < length) array.push(fill);
	array.splice(length,array.length - length);
	return array;
};
thx_core_ArrayFloats.sum = function(arr) {
	return arr.reduce(function(tot,v) {
		return tot + v;
	},0.0);
};
var thx_core_ArrayInts = function() { };
thx_core_ArrayInts.__name__ = ["thx","core","ArrayInts"];
thx_core_ArrayInts.average = function(arr) {
	return thx_core_ArrayInts.sum(arr) / arr.length;
};
thx_core_ArrayInts.max = function(arr) {
	if(arr.length == 0) return null; else return arr.reduce(function(max,v) {
		if(v > max) return v; else return max;
	},arr[0]);
};
thx_core_ArrayInts.min = function(arr) {
	if(arr.length == 0) return null; else return arr.reduce(function(min,v) {
		if(v < min) return v; else return min;
	},arr[0]);
};
thx_core_ArrayInts.resize = function(array,length,fill) {
	if(fill == null) fill = 0;
	while(array.length < length) array.push(fill);
	array.splice(length,array.length - length);
	return array;
};
thx_core_ArrayInts.sum = function(arr) {
	return arr.reduce(function(tot,v) {
		return tot + v;
	},0);
};
var thx_core_ArrayStrings = function() { };
thx_core_ArrayStrings.__name__ = ["thx","core","ArrayStrings"];
thx_core_ArrayStrings.compact = function(arr) {
	return arr.filter(function(v) {
		return !thx_core_Strings.isEmpty(v);
	});
};
thx_core_ArrayStrings.max = function(arr) {
	if(arr.length == 0) return null; else return arr.reduce(function(max,v) {
		if(v > max) return v; else return max;
	},arr[0]);
};
thx_core_ArrayStrings.min = function(arr) {
	if(arr.length == 0) return null; else return arr.reduce(function(min,v) {
		if(v < min) return v; else return min;
	},arr[0]);
};
var thx_core_Either = { __ename__ : ["thx","core","Either"], __constructs__ : ["Left","Right"] };
thx_core_Either.Left = function(value) { var $x = ["Left",0,value]; $x.__enum__ = thx_core_Either; $x.toString = $estr; return $x; };
thx_core_Either.Right = function(value) { var $x = ["Right",1,value]; $x.__enum__ = thx_core_Either; $x.toString = $estr; return $x; };
var thx_core_Error = function(message,stack,pos) {
	Error.call(this,message);
	this.message = message;
	if(null == stack) {
		try {
			stack = haxe_CallStack.exceptionStack();
		} catch( e ) {
			haxe_CallStack.lastException = e;
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			stack = [];
		}
		if(stack.length == 0) try {
			stack = haxe_CallStack.callStack();
		} catch( e1 ) {
			haxe_CallStack.lastException = e1;
			if (e1 instanceof js__$Boot_HaxeError) e1 = e1.val;
			stack = [];
		}
	}
	this.stackItems = stack;
	this.pos = pos;
};
thx_core_Error.__name__ = ["thx","core","Error"];
thx_core_Error.fromDynamic = function(err,pos) {
	if(js_Boot.__instanceof(err,thx_core_Error)) return err;
	return new thx_core_error_ErrorWrapper("" + Std.string(err),err,null,pos);
};
thx_core_Error.__super__ = Error;
thx_core_Error.prototype = $extend(Error.prototype,{
	pos: null
	,stackItems: null
	,toString: function() {
		return this.message + "\nfrom: " + this.pos.className + "." + this.pos.methodName + "() at " + this.pos.lineNumber + "\n\n" + haxe_CallStack.toString(this.stackItems);
	}
	,__class__: thx_core_Error
});
var thx_core_Floats = function() { };
thx_core_Floats.__name__ = ["thx","core","Floats"];
thx_core_Floats.angleDifference = function(a,b,turn) {
	if(turn == null) turn = 360;
	var r = (b - a) % turn;
	if(r < 0) r += turn;
	if(r > turn / 2) r -= turn;
	return r;
};
thx_core_Floats.ceilTo = function(f,decimals) {
	var p = Math.pow(10,decimals);
	return Math.ceil(f * p) / p;
};
thx_core_Floats.canParse = function(s) {
	return thx_core_Floats.pattern_parse.match(s);
};
thx_core_Floats.clamp = function(v,min,max) {
	if(v < min) return min; else if(v > max) return max; else return v;
};
thx_core_Floats.clampSym = function(v,max) {
	return thx_core_Floats.clamp(v,-max,max);
};
thx_core_Floats.compare = function(a,b) {
	if(a < b) return -1; else if(a > b) return 1; else return 0;
};
thx_core_Floats.floorTo = function(f,decimals) {
	var p = Math.pow(10,decimals);
	return Math.floor(f * p) / p;
};
thx_core_Floats.interpolate = function(f,a,b) {
	return (b - a) * f + a;
};
thx_core_Floats.interpolateAngle = function(f,a,b,turn) {
	if(turn == null) turn = 360;
	return thx_core_Floats.wrapCircular(thx_core_Floats.interpolate(f,a,a + thx_core_Floats.angleDifference(a,b,turn)),turn);
};
thx_core_Floats.interpolateAngleWidest = function(f,a,b,turn) {
	if(turn == null) turn = 360;
	return thx_core_Floats.wrapCircular(thx_core_Floats.interpolateAngle(f,a,b,turn) - turn / 2,turn);
};
thx_core_Floats.interpolateAngleCW = function(f,a,b,turn) {
	if(turn == null) turn = 360;
	a = thx_core_Floats.wrapCircular(a,turn);
	b = thx_core_Floats.wrapCircular(b,turn);
	if(b < a) b += turn;
	return thx_core_Floats.wrapCircular(thx_core_Floats.interpolate(f,a,b),turn);
};
thx_core_Floats.interpolateAngleCCW = function(f,a,b,turn) {
	if(turn == null) turn = 360;
	a = thx_core_Floats.wrapCircular(a,turn);
	b = thx_core_Floats.wrapCircular(b,turn);
	if(b > a) b -= turn;
	return thx_core_Floats.wrapCircular(thx_core_Floats.interpolate(f,a,b),turn);
};
thx_core_Floats.nearEquals = function(a,b) {
	return Math.abs(a - b) <= 10e-10;
};
thx_core_Floats.nearZero = function(n) {
	return Math.abs(n) <= 10e-10;
};
thx_core_Floats.normalize = function(v) {
	if(v < 0) return 0; else if(v > 1) return 1; else return v;
};
thx_core_Floats.parse = function(s) {
	if(s.substring(0,1) == "+") s = s.substring(1);
	return parseFloat(s);
};
thx_core_Floats.root = function(base,index) {
	return Math.pow(base,1 / index);
};
thx_core_Floats.roundTo = function(f,decimals) {
	var p = Math.pow(10,decimals);
	return Math.round(f * p) / p;
};
thx_core_Floats.sign = function(value) {
	if(value < 0) return -1; else return 1;
};
thx_core_Floats.wrap = function(v,min,max) {
	var range = max - min + 1;
	if(v < min) v += range * ((min - v) / range + 1);
	return min + (v - min) % range;
};
thx_core_Floats.wrapCircular = function(v,max) {
	v = v % max;
	if(v < 0) v += max;
	return v;
};
var thx_core_Functions0 = function() { };
thx_core_Functions0.__name__ = ["thx","core","Functions0"];
thx_core_Functions0.after = function(callback,n) {
	return function() {
		if(--n == 0) callback();
	};
};
thx_core_Functions0.join = function(fa,fb) {
	return function() {
		fa();
		fb();
	};
};
thx_core_Functions0.once = function(f) {
	return function() {
		var t = f;
		f = thx_core_Functions.noop;
		t();
	};
};
thx_core_Functions0.negate = function(callback) {
	return function() {
		return !callback();
	};
};
thx_core_Functions0.times = function(n,callback) {
	return function() {
		return thx_core_Ints.range(n).map(function(_) {
			return callback();
		});
	};
};
thx_core_Functions0.timesi = function(n,callback) {
	return function() {
		return thx_core_Ints.range(n).map(function(i) {
			return callback(i);
		});
	};
};
var thx_core_Functions1 = function() { };
thx_core_Functions1.__name__ = ["thx","core","Functions1"];
thx_core_Functions1.compose = function(fa,fb) {
	return function(v) {
		return fa(fb(v));
	};
};
thx_core_Functions1.join = function(fa,fb) {
	return function(v) {
		fa(v);
		fb(v);
	};
};
thx_core_Functions1.memoize = function(callback,resolver) {
	if(null == resolver) resolver = function(v) {
		return "" + Std.string(v);
	};
	var map = new haxe_ds_StringMap();
	return function(v1) {
		var key = resolver(v1);
		if(__map_reserved[key] != null?map.existsReserved(key):map.h.hasOwnProperty(key)) return __map_reserved[key] != null?map.getReserved(key):map.h[key];
		var result = callback(v1);
		if(__map_reserved[key] != null) map.setReserved(key,result); else map.h[key] = result;
		return result;
	};
};
thx_core_Functions1.negate = function(callback) {
	return function(v) {
		return !callback(v);
	};
};
thx_core_Functions1.noop = function(_) {
};
thx_core_Functions1.times = function(n,callback) {
	return function(value) {
		return thx_core_Ints.range(n).map(function(_) {
			return callback(value);
		});
	};
};
thx_core_Functions1.timesi = function(n,callback) {
	return function(value) {
		return thx_core_Ints.range(n).map(function(i) {
			return callback(value,i);
		});
	};
};
thx_core_Functions1.swapArguments = function(callback) {
	return function(a2,a1) {
		return callback(a1,a2);
	};
};
var thx_core_Functions2 = function() { };
thx_core_Functions2.__name__ = ["thx","core","Functions2"];
thx_core_Functions2.memoize = function(callback,resolver) {
	if(null == resolver) resolver = function(v1,v2) {
		return "" + Std.string(v1) + ":" + Std.string(v2);
	};
	var map = new haxe_ds_StringMap();
	return function(v11,v21) {
		var key = resolver(v11,v21);
		if(__map_reserved[key] != null?map.existsReserved(key):map.h.hasOwnProperty(key)) return __map_reserved[key] != null?map.getReserved(key):map.h[key];
		var result = callback(v11,v21);
		if(__map_reserved[key] != null) map.setReserved(key,result); else map.h[key] = result;
		return result;
	};
};
thx_core_Functions2.negate = function(callback) {
	return function(v1,v2) {
		return !callback(v1,v2);
	};
};
var thx_core_Functions3 = function() { };
thx_core_Functions3.__name__ = ["thx","core","Functions3"];
thx_core_Functions3.memoize = function(callback,resolver) {
	if(null == resolver) resolver = function(v1,v2,v3) {
		return "" + Std.string(v1) + ":" + Std.string(v2) + ":" + Std.string(v3);
	};
	var map = new haxe_ds_StringMap();
	return function(v11,v21,v31) {
		var key = resolver(v11,v21,v31);
		if(__map_reserved[key] != null?map.existsReserved(key):map.h.hasOwnProperty(key)) return __map_reserved[key] != null?map.getReserved(key):map.h[key];
		var result = callback(v11,v21,v31);
		if(__map_reserved[key] != null) map.setReserved(key,result); else map.h[key] = result;
		return result;
	};
};
thx_core_Functions3.negate = function(callback) {
	return function(v1,v2,v3) {
		return !callback(v1,v2,v3);
	};
};
var thx_core_Functions = function() { };
thx_core_Functions.__name__ = ["thx","core","Functions"];
thx_core_Functions.constant = function(v) {
	return function() {
		return v;
	};
};
thx_core_Functions.equality = function(a,b) {
	return a == b;
};
thx_core_Functions.identity = function(value) {
	return value;
};
thx_core_Functions.noop = function() {
};
var thx_core_Ints = function() { };
thx_core_Ints.__name__ = ["thx","core","Ints"];
thx_core_Ints.abs = function(v) {
	if(v < 0) return -v; else return v;
};
thx_core_Ints.canParse = function(s) {
	return thx_core_Ints.pattern_parse.match(s);
};
thx_core_Ints.clamp = function(v,min,max) {
	if(v < min) return min; else if(v > max) return max; else return v;
};
thx_core_Ints.clampSym = function(v,max) {
	return thx_core_Ints.clamp(v,-max,max);
};
thx_core_Ints.compare = function(a,b) {
	return a - b;
};
thx_core_Ints.interpolate = function(f,a,b) {
	return Math.round(a + (b - a) * f);
};
thx_core_Ints.isEven = function(v) {
	return v % 2 == 0;
};
thx_core_Ints.isOdd = function(v) {
	return v % 2 != 0;
};
thx_core_Ints.max = function(a,b) {
	if(a > b) return a; else return b;
};
thx_core_Ints.min = function(a,b) {
	if(a < b) return a; else return b;
};
thx_core_Ints.parse = function(s,base) {
	var v = parseInt(s,base);
	if(isNaN(v)) return null; else return v;
};
thx_core_Ints.random = function(min,max) {
	if(min == null) min = 0;
	return Std.random(max + 1) + min;
};
thx_core_Ints.range = function(start,stop,step) {
	if(step == null) step = 1;
	if(null == stop) {
		stop = start;
		start = 0;
	}
	if((stop - start) / step == Infinity) throw new js__$Boot_HaxeError("infinite range");
	var range = [];
	var i = -1;
	var j;
	if(step < 0) while((j = start + step * ++i) > stop) range.push(j); else while((j = start + step * ++i) < stop) range.push(j);
	return range;
};
thx_core_Ints.toString = function(value,base) {
	return value.toString(base);
};
thx_core_Ints.toBool = function(v) {
	return v != 0;
};
thx_core_Ints.sign = function(value) {
	if(value < 0) return -1; else return 1;
};
thx_core_Ints.wrapCircular = function(v,max) {
	v = v % max;
	if(v < 0) v += max;
	return v;
};
var thx_core_Iterators = function() { };
thx_core_Iterators.__name__ = ["thx","core","Iterators"];
thx_core_Iterators.all = function(it,predicate) {
	while( it.hasNext() ) {
		var item = it.next();
		if(!predicate(item)) return false;
	}
	return true;
};
thx_core_Iterators.any = function(it,predicate) {
	while( it.hasNext() ) {
		var item = it.next();
		if(predicate(item)) return true;
	}
	return false;
};
thx_core_Iterators.eachPair = function(it,handler) {
	thx_core_Arrays.eachPair(thx_core_Iterators.toArray(it),handler);
};
thx_core_Iterators.filter = function(it,predicate) {
	return thx_core_Iterators.reduce(it,function(acc,item) {
		if(predicate(item)) acc.push(item);
		return acc;
	},[]);
};
thx_core_Iterators.find = function(it,f) {
	while( it.hasNext() ) {
		var item = it.next();
		if(f(item)) return item;
	}
	return null;
};
thx_core_Iterators.first = function(it) {
	if(it.hasNext()) return it.next(); else return null;
};
thx_core_Iterators.isEmpty = function(it) {
	return !it.hasNext();
};
thx_core_Iterators.isIterator = function(v) {
	var fields;
	if(Reflect.isObject(v) && null == Type.getClass(v)) fields = Reflect.fields(v); else fields = Type.getInstanceFields(Type.getClass(v));
	if(!Lambda.has(fields,"next") || !Lambda.has(fields,"hasNext")) return false;
	return Reflect.isFunction(Reflect.field(v,"next")) && Reflect.isFunction(Reflect.field(v,"hasNext"));
};
thx_core_Iterators.last = function(it) {
	var buf = null;
	while(it.hasNext()) buf = it.next();
	return buf;
};
thx_core_Iterators.map = function(it,f) {
	var acc = [];
	while( it.hasNext() ) {
		var v = it.next();
		acc.push(f(v));
	}
	return acc;
};
thx_core_Iterators.mapi = function(it,f) {
	var acc = [];
	var i = 0;
	while( it.hasNext() ) {
		var v = it.next();
		acc.push(f(v,i++));
	}
	return acc;
};
thx_core_Iterators.order = function(it,sort) {
	var n = thx_core_Iterators.toArray(it);
	n.sort(sort);
	return n;
};
thx_core_Iterators.reduce = function(it,callback,initial) {
	thx_core_Iterators.map(it,function(v) {
		initial = callback(initial,v);
	});
	return initial;
};
thx_core_Iterators.reducei = function(it,callback,initial) {
	thx_core_Iterators.mapi(it,function(v,i) {
		initial = callback(initial,v,i);
	});
	return initial;
};
thx_core_Iterators.toArray = function(it) {
	var items = [];
	while( it.hasNext() ) {
		var item = it.next();
		items.push(item);
	}
	return items;
};
var thx_core_Nil = { __ename__ : ["thx","core","Nil"], __constructs__ : ["nil"] };
thx_core_Nil.nil = ["nil",0];
thx_core_Nil.nil.toString = $estr;
thx_core_Nil.nil.__enum__ = thx_core_Nil;
var thx_core_Nulls = function() { };
thx_core_Nulls.__name__ = ["thx","core","Nulls"];
var thx_core_Options = function() { };
thx_core_Options.__name__ = ["thx","core","Options"];
thx_core_Options.equals = function(a,b,eq) {
	switch(a[1]) {
	case 1:
		switch(b[1]) {
		case 1:
			return true;
		default:
			return false;
		}
		break;
	case 0:
		switch(b[1]) {
		case 0:
			var a1 = a[2];
			var b1 = b[2];
			if(null == eq) eq = function(a2,b2) {
				return a2 == b2;
			};
			return eq(a1,b1);
		default:
			return false;
		}
		break;
	}
};
thx_core_Options.equalsValue = function(a,b,eq) {
	return thx_core_Options.equals(a,null == b?haxe_ds_Option.None:haxe_ds_Option.Some(b),eq);
};
thx_core_Options.flatMap = function(option,callback) {
	switch(option[1]) {
	case 1:
		return [];
	case 0:
		var v = option[2];
		return callback(v);
	}
};
thx_core_Options.map = function(option,callback) {
	switch(option[1]) {
	case 1:
		return haxe_ds_Option.None;
	case 0:
		var v = option[2];
		return haxe_ds_Option.Some(callback(v));
	}
};
thx_core_Options.toArray = function(option) {
	switch(option[1]) {
	case 1:
		return [];
	case 0:
		var v = option[2];
		return [v];
	}
};
thx_core_Options.toBool = function(option) {
	switch(option[1]) {
	case 1:
		return false;
	case 0:
		return true;
	}
};
thx_core_Options.toOption = function(value) {
	if(null == value) return haxe_ds_Option.None; else return haxe_ds_Option.Some(value);
};
thx_core_Options.toValue = function(option) {
	switch(option[1]) {
	case 1:
		return null;
	case 0:
		var v = option[2];
		return v;
	}
};
var thx_core__$Result_Result_$Impl_$ = {};
thx_core__$Result_Result_$Impl_$.__name__ = ["thx","core","_Result","Result_Impl_"];
thx_core__$Result_Result_$Impl_$.optionValue = function(this1) {
	switch(this1[1]) {
	case 1:
		var v = this1[2];
		return haxe_ds_Option.Some(v);
	default:
		return haxe_ds_Option.None;
	}
};
thx_core__$Result_Result_$Impl_$.optionError = function(this1) {
	switch(this1[1]) {
	case 0:
		var v = this1[2];
		return haxe_ds_Option.Some(v);
	default:
		return haxe_ds_Option.None;
	}
};
thx_core__$Result_Result_$Impl_$.value = function(this1) {
	switch(this1[1]) {
	case 1:
		var v = this1[2];
		return v;
	default:
		return null;
	}
};
thx_core__$Result_Result_$Impl_$.error = function(this1) {
	switch(this1[1]) {
	case 0:
		var v = this1[2];
		return v;
	default:
		return null;
	}
};
thx_core__$Result_Result_$Impl_$.get_isSuccess = function(this1) {
	switch(this1[1]) {
	case 1:
		return true;
	default:
		return false;
	}
};
thx_core__$Result_Result_$Impl_$.get_isFailure = function(this1) {
	switch(this1[1]) {
	case 0:
		return true;
	default:
		return false;
	}
};
var thx_core_Strings = function() { };
thx_core_Strings.__name__ = ["thx","core","Strings"];
thx_core_Strings.after = function(value,searchFor) {
	var pos = value.indexOf(searchFor);
	if(pos < 0) return ""; else return value.substring(pos + searchFor.length);
};
thx_core_Strings.capitalize = function(s) {
	return s.substring(0,1).toUpperCase() + s.substring(1);
};
thx_core_Strings.capitalizeWords = function(value,whiteSpaceOnly) {
	if(whiteSpaceOnly == null) whiteSpaceOnly = false;
	if(whiteSpaceOnly) return thx_core_Strings.UCWORDSWS.map(value.substring(0,1).toUpperCase() + value.substring(1),thx_core_Strings.upperMatch); else return thx_core_Strings.UCWORDS.map(value.substring(0,1).toUpperCase() + value.substring(1),thx_core_Strings.upperMatch);
};
thx_core_Strings.collapse = function(value) {
	return thx_core_Strings.WSG.replace(StringTools.trim(value)," ");
};
thx_core_Strings.compare = function(a,b) {
	if(a < b) return -1; else if(a > b) return 1; else return 0;
};
thx_core_Strings.contains = function(s,test) {
	return s.indexOf(test) >= 0;
};
thx_core_Strings.dasherize = function(s) {
	return StringTools.replace(s,"_","-");
};
thx_core_Strings.ellipsis = function(s,maxlen,symbol) {
	if(symbol == null) symbol = "...";
	if(maxlen == null) maxlen = 20;
	if(s.length > maxlen) return s.substring(0,symbol.length > maxlen - symbol.length?symbol.length:maxlen - symbol.length) + symbol; else return s;
};
thx_core_Strings.filter = function(s,predicate) {
	return s.split("").filter(predicate).join("");
};
thx_core_Strings.filterCharcode = function(s,predicate) {
	return thx_core_Strings.toCharcodeArray(s).filter(predicate).map(function(i) {
		return String.fromCharCode(i);
	}).join("");
};
thx_core_Strings.from = function(value,searchFor) {
	var pos = value.indexOf(searchFor);
	if(pos < 0) return ""; else return value.substring(pos);
};
thx_core_Strings.humanize = function(s) {
	return StringTools.replace(thx_core_Strings.underscore(s),"_"," ");
};
thx_core_Strings.isAlphaNum = function(value) {
	return thx_core_Strings.ALPHANUM.match(value);
};
thx_core_Strings.isLowerCase = function(value) {
	return value.toLowerCase() == value;
};
thx_core_Strings.isUpperCase = function(value) {
	return value.toUpperCase() == value;
};
thx_core_Strings.ifEmpty = function(value,alt) {
	if(null != value && "" != value) return value; else return alt;
};
thx_core_Strings.isDigitsOnly = function(value) {
	return thx_core_Strings.DIGITS.match(value);
};
thx_core_Strings.isEmpty = function(value) {
	return value == null || value == "";
};
thx_core_Strings.random = function(value,length) {
	if(length == null) length = 1;
	var pos = Math.floor((value.length - length + 1) * Math.random());
	return HxOverrides.substr(value,pos,length);
};
thx_core_Strings.iterator = function(s) {
	var _this = s.split("");
	return HxOverrides.iter(_this);
};
thx_core_Strings.map = function(value,callback) {
	return value.split("").map(callback);
};
thx_core_Strings.remove = function(value,toremove) {
	return StringTools.replace(value,toremove,"");
};
thx_core_Strings.removeAfter = function(value,toremove) {
	if(StringTools.endsWith(value,toremove)) return value.substring(0,value.length - toremove.length); else return value;
};
thx_core_Strings.removeBefore = function(value,toremove) {
	if(StringTools.startsWith(value,toremove)) return value.substring(toremove.length); else return value;
};
thx_core_Strings.repeat = function(s,times) {
	return ((function($this) {
		var $r;
		var _g = [];
		{
			var _g1 = 0;
			while(_g1 < times) {
				var i = _g1++;
				_g.push(s);
			}
		}
		$r = _g;
		return $r;
	}(this))).join("");
};
thx_core_Strings.reverse = function(s) {
	var arr = s.split("");
	arr.reverse();
	return arr.join("");
};
thx_core_Strings.stripTags = function(s) {
	return thx_core_Strings.STRIPTAGS.replace(s,"");
};
thx_core_Strings.surround = function(s,left,right) {
	return "" + left + s + (null == right?left:right);
};
thx_core_Strings.toArray = function(s) {
	return s.split("");
};
thx_core_Strings.toCharcodeArray = function(s) {
	return thx_core_Strings.map(s,function(s1) {
		return HxOverrides.cca(s1,0);
	});
};
thx_core_Strings.toChunks = function(s,len) {
	var chunks = [];
	while(s.length > 0) {
		chunks.push(s.substring(0,len));
		s = s.substring(len);
	}
	return chunks;
};
thx_core_Strings.trimChars = function(value,charlist) {
	return thx_core_Strings.trimCharsRight(thx_core_Strings.trimCharsLeft(value,charlist),charlist);
};
thx_core_Strings.trimCharsLeft = function(value,charlist) {
	var pos = 0;
	var _g1 = 0;
	var _g = value.length;
	while(_g1 < _g) {
		var i = _g1++;
		if(thx_core_Strings.contains(charlist,value.charAt(i))) pos++; else break;
	}
	return value.substring(pos);
};
thx_core_Strings.trimCharsRight = function(value,charlist) {
	var len = value.length;
	var pos = len;
	var i;
	var _g = 0;
	while(_g < len) {
		var j = _g++;
		i = len - j - 1;
		if(thx_core_Strings.contains(charlist,value.charAt(i))) pos = i; else break;
	}
	return value.substring(0,pos);
};
thx_core_Strings.underscore = function(s) {
	s = new EReg("::","g").replace(s,"/");
	s = new EReg("([A-Z]+)([A-Z][a-z])","g").replace(s,"$1_$2");
	s = new EReg("([a-z\\d])([A-Z])","g").replace(s,"$1_$2");
	s = new EReg("-","g").replace(s,"_");
	return s.toLowerCase();
};
thx_core_Strings.upTo = function(value,searchFor) {
	var pos = value.indexOf(searchFor);
	if(pos < 0) return value; else return value.substring(0,pos);
};
thx_core_Strings.wrapColumns = function(s,columns,indent,newline) {
	if(newline == null) newline = "\n";
	if(indent == null) indent = "";
	if(columns == null) columns = 78;
	return thx_core_Strings.SPLIT_LINES.split(s).map(function(part) {
		return thx_core_Strings.wrapLine(StringTools.trim(thx_core_Strings.WSG.replace(part," ")),columns,indent,newline);
	}).join(newline);
};
thx_core_Strings.upperMatch = function(re) {
	return re.matched(0).toUpperCase();
};
thx_core_Strings.wrapLine = function(s,columns,indent,newline) {
	var parts = [];
	var pos = 0;
	var len = s.length;
	var ilen = indent.length;
	columns -= ilen;
	while(true) {
		if(pos + columns >= len - ilen) {
			parts.push(s.substring(pos));
			break;
		}
		var i = 0;
		while(!StringTools.isSpace(s,pos + columns - i) && i < columns) i++;
		if(i == columns) {
			i = 0;
			while(!StringTools.isSpace(s,pos + columns + i) && pos + columns + i < len) i++;
			parts.push(s.substring(pos,pos + columns + i));
			pos += columns + i + 1;
		} else {
			parts.push(s.substring(pos,pos + columns - i));
			pos += columns - i + 1;
		}
	}
	return indent + parts.join(newline + indent);
};
var thx_core_Timer = function() { };
thx_core_Timer.__name__ = ["thx","core","Timer"];
thx_core_Timer.debounce = function(callback,delayms,leading) {
	if(leading == null) leading = false;
	var cancel = thx_core_Functions.noop;
	var poll = function() {
		cancel();
		cancel = thx_core_Timer.delay(callback,delayms);
	};
	return function() {
		if(leading) {
			leading = false;
			callback();
		}
		poll();
	};
};
thx_core_Timer.throttle = function(callback,delayms,leading) {
	if(leading == null) leading = false;
	var waiting = false;
	var poll = function() {
		waiting = true;
		thx_core_Timer.delay(callback,delayms);
	};
	return function() {
		if(leading) {
			leading = false;
			callback();
			return;
		}
		if(waiting) return;
		poll();
	};
};
thx_core_Timer.repeat = function(callback,delayms) {
	return (function(f,id) {
		return function() {
			f(id);
		};
	})(thx_core_Timer.clear,setInterval(callback,delayms));
};
thx_core_Timer.delay = function(callback,delayms) {
	return (function(f,id) {
		return function() {
			f(id);
		};
	})(thx_core_Timer.clear,setTimeout(callback,delayms));
};
thx_core_Timer.frame = function(callback) {
	var cancelled = false;
	var f = thx_core_Functions.noop;
	var current = performance.now();
	var next;
	f = function() {
		if(cancelled) return;
		next = performance.now();
		callback(next - current);
		current = next;
		requestAnimationFrame(f);
	};
	requestAnimationFrame(f);
	return function() {
		cancelled = true;
	};
};
thx_core_Timer.nextFrame = function(callback) {
	var id = requestAnimationFrame(callback);
	return function() {
		cancelAnimationFrame(id);
	};
};
thx_core_Timer.immediate = function(callback) {
	return (function(f,id) {
		return function() {
			f(id);
		};
	})(thx_core_Timer.clear,setImmediate(callback));
};
thx_core_Timer.clear = function(id) {
	clearTimeout(id);
	return;
};
thx_core_Timer.time = function() {
	return performance.now();
};
var thx_core__$Tuple_Tuple0_$Impl_$ = {};
thx_core__$Tuple_Tuple0_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple0_Impl_"];
thx_core__$Tuple_Tuple0_$Impl_$._new = function() {
	return thx_core_Nil.nil;
};
thx_core__$Tuple_Tuple0_$Impl_$["with"] = function(this1,v) {
	return v;
};
thx_core__$Tuple_Tuple0_$Impl_$.toString = function(this1) {
	return "Tuple0()";
};
thx_core__$Tuple_Tuple0_$Impl_$.toNil = function(this1) {
	return this1;
};
thx_core__$Tuple_Tuple0_$Impl_$.nilToTuple = function(v) {
	return thx_core_Nil.nil;
};
var thx_core__$Tuple_Tuple1_$Impl_$ = {};
thx_core__$Tuple_Tuple1_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple1_Impl_"];
thx_core__$Tuple_Tuple1_$Impl_$._new = function(_0) {
	return _0;
};
thx_core__$Tuple_Tuple1_$Impl_$.get__0 = function(this1) {
	return this1;
};
thx_core__$Tuple_Tuple1_$Impl_$["with"] = function(this1,v) {
	return { _0 : this1, _1 : v};
};
thx_core__$Tuple_Tuple1_$Impl_$.toString = function(this1) {
	return "Tuple1(" + Std.string(this1) + ")";
};
thx_core__$Tuple_Tuple1_$Impl_$.arrayToTuple = function(v) {
	return v[0];
};
var thx_core__$Tuple_Tuple2_$Impl_$ = {};
thx_core__$Tuple_Tuple2_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple2_Impl_"];
thx_core__$Tuple_Tuple2_$Impl_$._new = function(_0,_1) {
	return { _0 : _0, _1 : _1};
};
thx_core__$Tuple_Tuple2_$Impl_$.get_left = function(this1) {
	return this1._0;
};
thx_core__$Tuple_Tuple2_$Impl_$.get_right = function(this1) {
	return this1._1;
};
thx_core__$Tuple_Tuple2_$Impl_$.flip = function(this1) {
	return { _0 : this1._1, _1 : this1._0};
};
thx_core__$Tuple_Tuple2_$Impl_$.dropLeft = function(this1) {
	return this1._1;
};
thx_core__$Tuple_Tuple2_$Impl_$.dropRight = function(this1) {
	return this1._0;
};
thx_core__$Tuple_Tuple2_$Impl_$["with"] = function(this1,v) {
	return { _0 : this1._0, _1 : this1._1, _2 : v};
};
thx_core__$Tuple_Tuple2_$Impl_$.toString = function(this1) {
	return "Tuple2(" + Std.string(this1._0) + "," + Std.string(this1._1) + ")";
};
thx_core__$Tuple_Tuple2_$Impl_$.arrayToTuple2 = function(v) {
	return { _0 : v[0], _1 : v[1]};
};
var thx_core__$Tuple_Tuple3_$Impl_$ = {};
thx_core__$Tuple_Tuple3_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple3_Impl_"];
thx_core__$Tuple_Tuple3_$Impl_$._new = function(_0,_1,_2) {
	return { _0 : _0, _1 : _1, _2 : _2};
};
thx_core__$Tuple_Tuple3_$Impl_$.flip = function(this1) {
	return { _0 : this1._2, _1 : this1._1, _2 : this1._0};
};
thx_core__$Tuple_Tuple3_$Impl_$.dropLeft = function(this1) {
	return { _0 : this1._1, _1 : this1._2};
};
thx_core__$Tuple_Tuple3_$Impl_$.dropRight = function(this1) {
	return { _0 : this1._0, _1 : this1._1};
};
thx_core__$Tuple_Tuple3_$Impl_$["with"] = function(this1,v) {
	return { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : v};
};
thx_core__$Tuple_Tuple3_$Impl_$.toString = function(this1) {
	return "Tuple3(" + Std.string(this1._0) + "," + Std.string(this1._1) + "," + Std.string(this1._2) + ")";
};
thx_core__$Tuple_Tuple3_$Impl_$.arrayToTuple3 = function(v) {
	return { _0 : v[0], _1 : v[1], _2 : v[2]};
};
var thx_core__$Tuple_Tuple4_$Impl_$ = {};
thx_core__$Tuple_Tuple4_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple4_Impl_"];
thx_core__$Tuple_Tuple4_$Impl_$._new = function(_0,_1,_2,_3) {
	return { _0 : _0, _1 : _1, _2 : _2, _3 : _3};
};
thx_core__$Tuple_Tuple4_$Impl_$.flip = function(this1) {
	return { _0 : this1._3, _1 : this1._2, _2 : this1._1, _3 : this1._0};
};
thx_core__$Tuple_Tuple4_$Impl_$.dropLeft = function(this1) {
	return { _0 : this1._1, _1 : this1._2, _2 : this1._3};
};
thx_core__$Tuple_Tuple4_$Impl_$.dropRight = function(this1) {
	return { _0 : this1._0, _1 : this1._1, _2 : this1._2};
};
thx_core__$Tuple_Tuple4_$Impl_$["with"] = function(this1,v) {
	return { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : v};
};
thx_core__$Tuple_Tuple4_$Impl_$.toString = function(this1) {
	return "Tuple4(" + Std.string(this1._0) + "," + Std.string(this1._1) + "," + Std.string(this1._2) + "," + Std.string(this1._3) + ")";
};
thx_core__$Tuple_Tuple4_$Impl_$.arrayToTuple4 = function(v) {
	return { _0 : v[0], _1 : v[1], _2 : v[2], _3 : v[3]};
};
var thx_core__$Tuple_Tuple5_$Impl_$ = {};
thx_core__$Tuple_Tuple5_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple5_Impl_"];
thx_core__$Tuple_Tuple5_$Impl_$._new = function(_0,_1,_2,_3,_4) {
	return { _0 : _0, _1 : _1, _2 : _2, _3 : _3, _4 : _4};
};
thx_core__$Tuple_Tuple5_$Impl_$.flip = function(this1) {
	return { _0 : this1._4, _1 : this1._3, _2 : this1._2, _3 : this1._1, _4 : this1._0};
};
thx_core__$Tuple_Tuple5_$Impl_$.dropLeft = function(this1) {
	return { _0 : this1._1, _1 : this1._2, _2 : this1._3, _3 : this1._4};
};
thx_core__$Tuple_Tuple5_$Impl_$.dropRight = function(this1) {
	return { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3};
};
thx_core__$Tuple_Tuple5_$Impl_$["with"] = function(this1,v) {
	return { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : this1._4, _5 : v};
};
thx_core__$Tuple_Tuple5_$Impl_$.toString = function(this1) {
	return "Tuple5(" + Std.string(this1._0) + "," + Std.string(this1._1) + "," + Std.string(this1._2) + "," + Std.string(this1._3) + "," + Std.string(this1._4) + ")";
};
thx_core__$Tuple_Tuple5_$Impl_$.arrayToTuple5 = function(v) {
	return { _0 : v[0], _1 : v[1], _2 : v[2], _3 : v[3], _4 : v[4]};
};
var thx_core__$Tuple_Tuple6_$Impl_$ = {};
thx_core__$Tuple_Tuple6_$Impl_$.__name__ = ["thx","core","_Tuple","Tuple6_Impl_"];
thx_core__$Tuple_Tuple6_$Impl_$._new = function(_0,_1,_2,_3,_4,_5) {
	return { _0 : _0, _1 : _1, _2 : _2, _3 : _3, _4 : _4, _5 : _5};
};
thx_core__$Tuple_Tuple6_$Impl_$.flip = function(this1) {
	return { _0 : this1._5, _1 : this1._4, _2 : this1._3, _3 : this1._2, _4 : this1._1, _5 : this1._0};
};
thx_core__$Tuple_Tuple6_$Impl_$.dropLeft = function(this1) {
	return { _0 : this1._1, _1 : this1._2, _2 : this1._3, _3 : this1._4, _4 : this1._5};
};
thx_core__$Tuple_Tuple6_$Impl_$.dropRight = function(this1) {
	return { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : this1._4};
};
thx_core__$Tuple_Tuple6_$Impl_$.toString = function(this1) {
	return "Tuple6(" + Std.string(this1._0) + "," + Std.string(this1._1) + "," + Std.string(this1._2) + "," + Std.string(this1._3) + "," + Std.string(this1._4) + "," + Std.string(this1._5) + ")";
};
thx_core__$Tuple_Tuple6_$Impl_$.arrayToTuple6 = function(v) {
	return { _0 : v[0], _1 : v[1], _2 : v[2], _3 : v[3], _4 : v[4], _5 : v[5]};
};
var thx_core_Types = function() { };
thx_core_Types.__name__ = ["thx","core","Types"];
thx_core_Types.isAnonymousObject = function(v) {
	return Reflect.isObject(v) && null == Type.getClass(v);
};
thx_core_Types.isPrimitive = function(v) {
	{
		var _g = Type["typeof"](v);
		switch(_g[1]) {
		case 1:case 2:case 3:
			return true;
		case 0:case 5:case 7:case 4:case 8:
			return false;
		case 6:
			var c = _g[2];
			return Type.getClassName(c) == "String";
		}
	}
};
thx_core_Types.hasSuperClass = function(cls,sup) {
	while(null != cls) {
		if(cls == sup) return true;
		cls = Type.getSuperClass(cls);
	}
	return false;
};
thx_core_Types.sameType = function(a,b) {
	return thx_core_Types.typeToString(Type["typeof"](a)) == thx_core_Types.typeToString(Type["typeof"](b));
};
thx_core_Types.typeInheritance = function(type) {
	switch(type[1]) {
	case 1:
		return ["Int"];
	case 2:
		return ["Float"];
	case 3:
		return ["Bool"];
	case 4:
		return ["{}"];
	case 5:
		return ["Function"];
	case 6:
		var c = type[2];
		var classes = [];
		while(null != c) {
			classes.push(c);
			c = Type.getSuperClass(c);
		}
		return classes.map(Type.getClassName);
	case 7:
		var e = type[2];
		return [Type.getEnumName(e)];
	default:
		throw new js__$Boot_HaxeError("invalid type " + Std.string(type));
	}
};
thx_core_Types.typeToString = function(type) {
	switch(type[1]) {
	case 0:
		return "Null";
	case 1:
		return "Int";
	case 2:
		return "Float";
	case 3:
		return "Bool";
	case 4:
		return "{}";
	case 5:
		return "Function";
	case 6:
		var c = type[2];
		return Type.getClassName(c);
	case 7:
		var e = type[2];
		return Type.getEnumName(e);
	default:
		throw new js__$Boot_HaxeError("invalid type " + Std.string(type));
	}
};
thx_core_Types.valueTypeInheritance = function(value) {
	return thx_core_Types.typeInheritance(Type["typeof"](value));
};
thx_core_Types.valueTypeToString = function(value) {
	return thx_core_Types.typeToString(Type["typeof"](value));
};
var thx_core_error_AbstractMethod = function(posInfo) {
	thx_core_Error.call(this,"method " + posInfo.className + "." + posInfo.methodName + "() is abstract",null,posInfo);
};
thx_core_error_AbstractMethod.__name__ = ["thx","core","error","AbstractMethod"];
thx_core_error_AbstractMethod.__super__ = thx_core_Error;
thx_core_error_AbstractMethod.prototype = $extend(thx_core_Error.prototype,{
	__class__: thx_core_error_AbstractMethod
});
var thx_core_error_ErrorWrapper = function(message,innerError,stack,pos) {
	thx_core_Error.call(this,message,stack,pos);
	this.innerError = innerError;
};
thx_core_error_ErrorWrapper.__name__ = ["thx","core","error","ErrorWrapper"];
thx_core_error_ErrorWrapper.__super__ = thx_core_Error;
thx_core_error_ErrorWrapper.prototype = $extend(thx_core_Error.prototype,{
	innerError: null
	,__class__: thx_core_error_ErrorWrapper
});
var thx_promise_Future = function() {
	this.handlers = [];
	this.state = haxe_ds_Option.None;
};
thx_promise_Future.__name__ = ["thx","promise","Future"];
thx_promise_Future.sequence = function(arr) {
	return thx_promise_Future.create(function(callback) {
		var poll;
		var poll1 = null;
		poll1 = function(_) {
			if(arr.length == 0) callback(thx_core_Nil.nil); else arr.shift().then(poll1);
		};
		poll = poll1;
		poll(null);
	});
};
thx_promise_Future.afterAll = function(arr) {
	return thx_promise_Future.create(function(callback) {
		thx_promise_Future.all(arr).then(function(_) {
			callback(thx_core_Nil.nil);
		});
	});
};
thx_promise_Future.all = function(arr) {
	return thx_promise_Future.create(function(callback) {
		var results = [];
		var counter = 0;
		thx_core_Arrays.mapi(arr,function(p,i) {
			p.then(function(value) {
				results[i] = value;
				counter++;
				if(counter == arr.length) callback(results);
			});
		});
	});
};
thx_promise_Future.create = function(handler) {
	var future = new thx_promise_Future();
	handler($bind(future,future.setState));
	return future;
};
thx_promise_Future.flatMap = function(future) {
	return thx_promise_Future.create(function(callback) {
		future.then(function(future1) {
			future1.then(callback);
		});
	});
};
thx_promise_Future.value = function(v) {
	return thx_promise_Future.create(function(callback) {
		callback(v);
	});
};
thx_promise_Future.prototype = {
	handlers: null
	,state: null
	,delay: function(delayms) {
		if(null == delayms) return thx_promise_Future.flatMap(this.map(function(value) {
			return thx_promise_Timer.immediateValue(value);
		})); else return thx_promise_Future.flatMap(this.map(function(value1) {
			return thx_promise_Timer.delayValue(value1,delayms);
		}));
	}
	,hasValue: function() {
		return thx_core_Options.toBool(this.state);
	}
	,map: function(handler) {
		var _g = this;
		return thx_promise_Future.create(function(callback) {
			_g.then(function(value) {
				callback(handler(value));
			});
		});
	}
	,mapAsync: function(handler) {
		var _g = this;
		return thx_promise_Future.create(function(callback) {
			_g.then(function(result) {
				handler(result,callback);
			});
		});
	}
	,mapPromise: function(handler) {
		var _g = this;
		return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
			_g.then(function(result) {
				thx_promise__$Promise_Promise_$Impl_$.failure(thx_promise__$Promise_Promise_$Impl_$.success(handler(result),resolve),reject);
			});
		});
	}
	,mapFuture: function(handler) {
		return thx_promise_Future.flatMap(this.map(handler));
	}
	,then: function(handler) {
		this.handlers.push(handler);
		this.update();
		return this;
	}
	,toString: function() {
		return "Future";
	}
	,setState: function(newstate) {
		{
			var _g = this.state;
			switch(_g[1]) {
			case 1:
				this.state = haxe_ds_Option.Some(newstate);
				break;
			case 0:
				var r = _g[2];
				throw new thx_core_Error("future was already \"" + Std.string(r) + "\", can't apply the new state \"" + Std.string(newstate) + "\"",null,{ fileName : "Future.hx", lineNumber : 108, className : "thx.promise.Future", methodName : "setState"});
				break;
			}
		}
		this.update();
		return this;
	}
	,update: function() {
		{
			var _g = this.state;
			switch(_g[1]) {
			case 1:
				break;
			case 0:
				var result = _g[2];
				var index = -1;
				while(++index < this.handlers.length) this.handlers[index](result);
				this.handlers = [];
				break;
			}
		}
	}
	,__class__: thx_promise_Future
};
var thx_promise_Futures = function() { };
thx_promise_Futures.__name__ = ["thx","promise","Futures"];
thx_promise_Futures.join = function(p1,p2) {
	return thx_promise_Future.create(function(callback) {
		var counter = 0;
		var v1 = null;
		var v2 = null;
		var complete = function() {
			if(counter < 2) return;
			callback({ _0 : v1, _1 : v2});
		};
		p1.then(function(v) {
			counter++;
			v1 = v;
			complete();
		});
		p2.then(function(v3) {
			counter++;
			v2 = v3;
			complete();
		});
	});
};
thx_promise_Futures.log = function(future,prefix) {
	if(prefix == null) prefix = "";
	return future.then(function(r) {
		haxe_Log.trace("" + prefix + " VALUE: " + Std.string(r),{ fileName : "Future.hx", lineNumber : 155, className : "thx.promise.Futures", methodName : "log"});
	});
};
var thx_promise_FutureTuple6 = function() { };
thx_promise_FutureTuple6.__name__ = ["thx","promise","FutureTuple6"];
thx_promise_FutureTuple6.mapTuple = function(future,callback) {
	return future.map(function(t) {
		return callback(t._0,t._1,t._2,t._3,t._4,t._5);
	});
};
thx_promise_FutureTuple6.mapTupleAsync = function(future,callback) {
	return future.mapAsync(function(t,cb) {
		callback(t._0,t._1,t._2,t._3,t._4,t._5,cb);
		return;
	});
};
thx_promise_FutureTuple6.mapTupleFuture = function(future,callback) {
	return thx_promise_Future.flatMap(future.map(function(t) {
		return callback(t._0,t._1,t._2,t._3,t._4,t._5);
	}));
};
thx_promise_FutureTuple6.tuple = function(future,callback) {
	return future.then(function(t) {
		callback(t._0,t._1,t._2,t._3,t._4,t._5);
	});
};
var thx_promise_FutureTuple5 = function() { };
thx_promise_FutureTuple5.__name__ = ["thx","promise","FutureTuple5"];
thx_promise_FutureTuple5.join = function(p1,p2) {
	return thx_promise_Future.create(function(callback) {
		thx_promise_Futures.join(p1,p2).then(function(t) {
			callback((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : this1._4, _5 : t._1};
				return $r;
			}(this)));
		});
	});
};
thx_promise_FutureTuple5.mapTuple = function(future,callback) {
	return future.map(function(t) {
		return callback(t._0,t._1,t._2,t._3,t._4);
	});
};
thx_promise_FutureTuple5.mapTupleAsync = function(future,callback) {
	return future.mapAsync(function(t,cb) {
		callback(t._0,t._1,t._2,t._3,t._4,cb);
		return;
	});
};
thx_promise_FutureTuple5.mapTupleFuture = function(future,callback) {
	return thx_promise_Future.flatMap(future.map(function(t) {
		return callback(t._0,t._1,t._2,t._3,t._4);
	}));
};
thx_promise_FutureTuple5.tuple = function(future,callback) {
	return future.then(function(t) {
		callback(t._0,t._1,t._2,t._3,t._4);
	});
};
var thx_promise_FutureTuple4 = function() { };
thx_promise_FutureTuple4.__name__ = ["thx","promise","FutureTuple4"];
thx_promise_FutureTuple4.join = function(p1,p2) {
	return thx_promise_Future.create(function(callback) {
		thx_promise_Futures.join(p1,p2).then(function(t) {
			callback((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : t._1};
				return $r;
			}(this)));
		});
	});
};
thx_promise_FutureTuple4.mapTuple = function(future,callback) {
	return future.map(function(t) {
		return callback(t._0,t._1,t._2,t._3);
	});
};
thx_promise_FutureTuple4.mapTupleAsync = function(future,callback) {
	return future.mapAsync(function(t,cb) {
		callback(t._0,t._1,t._2,t._3,cb);
		return;
	});
};
thx_promise_FutureTuple4.mapTupleFuture = function(future,callback) {
	return thx_promise_Future.flatMap(future.map(function(t) {
		return callback(t._0,t._1,t._2,t._3);
	}));
};
thx_promise_FutureTuple4.tuple = function(future,callback) {
	return future.then(function(t) {
		callback(t._0,t._1,t._2,t._3);
	});
};
var thx_promise_FutureTuple3 = function() { };
thx_promise_FutureTuple3.__name__ = ["thx","promise","FutureTuple3"];
thx_promise_FutureTuple3.join = function(p1,p2) {
	return thx_promise_Future.create(function(callback) {
		thx_promise_Futures.join(p1,p2).then(function(t) {
			callback((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : t._1};
				return $r;
			}(this)));
		});
	});
};
thx_promise_FutureTuple3.mapTuple = function(future,callback) {
	return future.map(function(t) {
		return callback(t._0,t._1,t._2);
	});
};
thx_promise_FutureTuple3.mapTupleAsync = function(future,callback) {
	return future.mapAsync(function(t,cb) {
		callback(t._0,t._1,t._2,cb);
		return;
	});
};
thx_promise_FutureTuple3.mapTupleFuture = function(future,callback) {
	return thx_promise_Future.flatMap(future.map(function(t) {
		return callback(t._0,t._1,t._2);
	}));
};
thx_promise_FutureTuple3.tuple = function(future,callback) {
	return future.then(function(t) {
		callback(t._0,t._1,t._2);
	});
};
var thx_promise_FutureTuple2 = function() { };
thx_promise_FutureTuple2.__name__ = ["thx","promise","FutureTuple2"];
thx_promise_FutureTuple2.join = function(p1,p2) {
	return thx_promise_Future.create(function(callback) {
		thx_promise_Futures.join(p1,p2).then(function(t) {
			callback((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : t._1};
				return $r;
			}(this)));
		});
	});
};
thx_promise_FutureTuple2.mapTuple = function(future,callback) {
	return future.map(function(t) {
		return callback(t._0,t._1);
	});
};
thx_promise_FutureTuple2.mapTupleAsync = function(future,callback) {
	return future.mapAsync(function(t,cb) {
		callback(t._0,t._1,cb);
		return;
	});
};
thx_promise_FutureTuple2.mapTupleFuture = function(future,callback) {
	return thx_promise_Future.flatMap(future.map(function(t) {
		return callback(t._0,t._1);
	}));
};
thx_promise_FutureTuple2.tuple = function(future,callback) {
	return future.then(function(t) {
		callback(t._0,t._1);
	});
};
var thx_promise_FutureNil = function() { };
thx_promise_FutureNil.__name__ = ["thx","promise","FutureNil"];
thx_promise_FutureNil.join = function(p1,p2) {
	return thx_promise_Future.create(function(callback) {
		thx_promise_Futures.join(p1,p2).then(function(t) {
			callback(t._1);
		});
	});
};
thx_promise_FutureNil.nil = function(p) {
	return thx_promise_Future.create(function(callback) {
		p.then(function(_) {
			callback(thx_core_Nil.nil);
		});
	});
};
var thx_promise__$Promise_Promise_$Impl_$ = {};
thx_promise__$Promise_Promise_$Impl_$.__name__ = ["thx","promise","_Promise","Promise_Impl_"];
thx_promise__$Promise_Promise_$Impl_$.futureToPromise = function(future) {
	return future.map(function(v) {
		return thx_core_Either.Right(v);
	});
};
thx_promise__$Promise_Promise_$Impl_$.sequence = function(arr) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		var poll;
		var poll1 = null;
		poll1 = function(_) {
			if(arr.length == 0) resolve(thx_promise__$Promise_Promise_$Impl_$.nil); else thx_promise__$Promise_Promise_$Impl_$.mapFailure(thx_promise__$Promise_Promise_$Impl_$.mapSuccess(arr.shift(),poll1),reject);
		};
		poll = poll1;
		poll(null);
	});
};
thx_promise__$Promise_Promise_$Impl_$.afterAll = function(arr) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.either(thx_promise__$Promise_Promise_$Impl_$.all(arr),function(_) {
			resolve(thx_core_Nil.nil);
		},reject);
	});
};
thx_promise__$Promise_Promise_$Impl_$.all = function(arr) {
	if(arr.length == 0) return thx_promise__$Promise_Promise_$Impl_$.value([]);
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		var results = [];
		var counter = 0;
		var hasError = false;
		thx_core_Arrays.mapi(arr,function(p,i) {
			thx_promise__$Promise_Promise_$Impl_$.either(p,function(value) {
				if(hasError) return;
				results[i] = value;
				counter++;
				if(counter == arr.length) resolve(results);
			},function(err) {
				if(hasError) return;
				hasError = true;
				reject(err);
			});
		});
	});
};
thx_promise__$Promise_Promise_$Impl_$.create = function(callback) {
	return thx_promise_Future.create(function(cb) {
		callback(function(value) {
			cb(thx_core_Either.Right(value));
		},function(error) {
			cb(thx_core_Either.Left(error));
		});
	});
};
thx_promise__$Promise_Promise_$Impl_$.createFulfill = function(callback) {
	return thx_promise_Future.create(callback);
};
thx_promise__$Promise_Promise_$Impl_$.error = function(err) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(_,reject) {
		reject(err);
	});
};
thx_promise__$Promise_Promise_$Impl_$.value = function(v) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,_) {
		resolve(v);
	});
};
thx_promise__$Promise_Promise_$Impl_$.always = function(this1,handler) {
	this1.then(function(_) {
		handler();
	});
};
thx_promise__$Promise_Promise_$Impl_$.either = function(this1,success,failure) {
	this1.then(function(r) {
		switch(r[1]) {
		case 1:
			var value = r[2];
			success(value);
			break;
		case 0:
			var error = r[2];
			failure(error);
			break;
		}
	});
	return this1;
};
thx_promise__$Promise_Promise_$Impl_$.delay = function(this1,delayms) {
	return this1.delay(delayms);
};
thx_promise__$Promise_Promise_$Impl_$.isFailure = function(this1) {
	{
		var _g = this1.state;
		switch(_g[1]) {
		case 1:
			return false;
		case 0:
			switch(_g[2][1]) {
			case 1:
				return false;
			default:
				return true;
			}
			break;
		}
	}
};
thx_promise__$Promise_Promise_$Impl_$.isResolved = function(this1) {
	{
		var _g = this1.state;
		switch(_g[1]) {
		case 1:
			return false;
		case 0:
			switch(_g[2][1]) {
			case 0:
				return false;
			default:
				return true;
			}
			break;
		}
	}
};
thx_promise__$Promise_Promise_$Impl_$.failure = function(this1,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.either(this1,function(_) {
	},failure);
};
thx_promise__$Promise_Promise_$Impl_$.mapAlways = function(this1,handler) {
	return this1.map(function(_) {
		return handler();
	});
};
thx_promise__$Promise_Promise_$Impl_$.mapAlwaysAsync = function(this1,handler) {
	return this1.mapAsync(function(_,cb) {
		handler(cb);
		return;
	});
};
thx_promise__$Promise_Promise_$Impl_$.mapAlwaysFuture = function(this1,handler) {
	return thx_promise_Future.flatMap(this1.map(function(_) {
		return handler();
	}));
};
thx_promise__$Promise_Promise_$Impl_$.mapEither = function(this1,success,failure) {
	return this1.map(function(result) {
		switch(result[1]) {
		case 1:
			var value = result[2];
			return success(value);
		case 0:
			var error = result[2];
			return failure(error);
		}
	});
};
thx_promise__$Promise_Promise_$Impl_$.mapEitherFuture = function(this1,success,failure) {
	return thx_promise_Future.flatMap(this1.map(function(result) {
		switch(result[1]) {
		case 1:
			var value = result[2];
			return success(value);
		case 0:
			var error = result[2];
			return failure(error);
		}
	}));
};
thx_promise__$Promise_Promise_$Impl_$.mapFailure = function(this1,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.mapEither(this1,function(value) {
		return value;
	},failure);
};
thx_promise__$Promise_Promise_$Impl_$.mapFailureFuture = function(this1,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.mapEitherFuture(this1,function(value) {
		return thx_promise_Future.value(value);
	},failure);
};
thx_promise__$Promise_Promise_$Impl_$.mapSuccess = function(this1,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapEitherFuture(this1,function(v) {
		return thx_promise__$Promise_Promise_$Impl_$.value(success(v));
	},function(err) {
		return thx_promise__$Promise_Promise_$Impl_$.error(err);
	});
};
thx_promise__$Promise_Promise_$Impl_$.mapSuccessPromise = function(this1,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapEitherFuture(this1,success,function(err) {
		return thx_promise__$Promise_Promise_$Impl_$.error(err);
	});
};
thx_promise__$Promise_Promise_$Impl_$.success = function(this1,success) {
	return thx_promise__$Promise_Promise_$Impl_$.either(this1,success,function(_) {
	});
};
thx_promise__$Promise_Promise_$Impl_$.throwFailure = function(this1) {
	return thx_promise__$Promise_Promise_$Impl_$.failure(this1,function(err) {
		throw err;
	});
};
thx_promise__$Promise_Promise_$Impl_$.toString = function(this1) {
	return "Promise";
};
var thx_promise_Promises = function() { };
thx_promise_Promises.__name__ = ["thx","promise","Promises"];
thx_promise_Promises.join = function(p1,p2) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		var hasError = false;
		var counter = 0;
		var v1 = null;
		var v2 = null;
		var complete = function() {
			if(counter < 2) return;
			resolve({ _0 : v1, _1 : v2});
		};
		var handleError = function(error) {
			if(hasError) return;
			hasError = true;
			reject(error);
		};
		thx_promise__$Promise_Promise_$Impl_$.either(p1,function(v) {
			if(hasError) return;
			counter++;
			v1 = v;
			complete();
		},handleError);
		thx_promise__$Promise_Promise_$Impl_$.either(p2,function(v3) {
			if(hasError) return;
			counter++;
			v2 = v3;
			complete();
		},handleError);
	});
};
thx_promise_Promises.log = function(promise,prefix) {
	if(prefix == null) prefix = "";
	return thx_promise__$Promise_Promise_$Impl_$.either(promise,function(r) {
		haxe_Log.trace("" + prefix + " SUCCESS: " + Std.string(r),{ fileName : "Promise.hx", lineNumber : 199, className : "thx.promise.Promises", methodName : "log"});
	},function(e) {
		haxe_Log.trace("" + prefix + " ERROR: " + e.toString(),{ fileName : "Promise.hx", lineNumber : 200, className : "thx.promise.Promises", methodName : "log"});
	});
};
var thx_promise_PromiseTuple6 = function() { };
thx_promise_PromiseTuple6.__name__ = ["thx","promise","PromiseTuple6"];
thx_promise_PromiseTuple6.mapTuplePromise = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccessPromise(promise,function(t) {
		return success(t._0,t._1,t._2,t._3,t._4,t._5);
	});
};
thx_promise_PromiseTuple6.mapTuple = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccess(promise,function(t) {
		return success(t._0,t._1,t._2,t._3,t._4,t._5);
	});
};
thx_promise_PromiseTuple6.tuple = function(promise,success,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.either(promise,function(t) {
		success(t._0,t._1,t._2,t._3,t._4,t._5);
	},null == failure?function(_) {
	}:failure);
};
var thx_promise_PromiseTuple5 = function() { };
thx_promise_PromiseTuple5.__name__ = ["thx","promise","PromiseTuple5"];
thx_promise_PromiseTuple5.join = function(p1,p2) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.either(thx_promise_Promises.join(p1,p2),function(t) {
			resolve((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : this1._4, _5 : t._1};
				return $r;
			}(this)));
		},function(e) {
			reject(e);
		});
	});
};
thx_promise_PromiseTuple5.mapTuplePromise = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccessPromise(promise,function(t) {
		return success(t._0,t._1,t._2,t._3,t._4);
	});
};
thx_promise_PromiseTuple5.mapTuple = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccess(promise,function(t) {
		return success(t._0,t._1,t._2,t._3,t._4);
	});
};
thx_promise_PromiseTuple5.tuple = function(promise,success,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.either(promise,function(t) {
		success(t._0,t._1,t._2,t._3,t._4);
	},null == failure?function(_) {
	}:failure);
};
var thx_promise_PromiseTuple4 = function() { };
thx_promise_PromiseTuple4.__name__ = ["thx","promise","PromiseTuple4"];
thx_promise_PromiseTuple4.join = function(p1,p2) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.either(thx_promise_Promises.join(p1,p2),function(t) {
			resolve((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : this1._3, _4 : t._1};
				return $r;
			}(this)));
		},function(e) {
			reject(e);
		});
	});
};
thx_promise_PromiseTuple4.mapTuplePromise = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccessPromise(promise,function(t) {
		return success(t._0,t._1,t._2,t._3);
	});
};
thx_promise_PromiseTuple4.mapTuple = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccess(promise,function(t) {
		return success(t._0,t._1,t._2,t._3);
	});
};
thx_promise_PromiseTuple4.tuple = function(promise,success,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.either(promise,function(t) {
		success(t._0,t._1,t._2,t._3);
	},null == failure?function(_) {
	}:failure);
};
var thx_promise_PromiseTuple3 = function() { };
thx_promise_PromiseTuple3.__name__ = ["thx","promise","PromiseTuple3"];
thx_promise_PromiseTuple3.join = function(p1,p2) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.either(thx_promise_Promises.join(p1,p2),function(t) {
			resolve((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : this1._2, _3 : t._1};
				return $r;
			}(this)));
		},function(e) {
			reject(e);
		});
	});
};
thx_promise_PromiseTuple3.mapTuplePromise = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccessPromise(promise,function(t) {
		return success(t._0,t._1,t._2);
	});
};
thx_promise_PromiseTuple3.mapTuple = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccess(promise,function(t) {
		return success(t._0,t._1,t._2);
	});
};
thx_promise_PromiseTuple3.tuple = function(promise,success,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.either(promise,function(t) {
		success(t._0,t._1,t._2);
	},null == failure?function(_) {
	}:failure);
};
var thx_promise_PromiseTuple2 = function() { };
thx_promise_PromiseTuple2.__name__ = ["thx","promise","PromiseTuple2"];
thx_promise_PromiseTuple2.join = function(p1,p2) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.either(thx_promise_Promises.join(p1,p2),function(t) {
			resolve((function($this) {
				var $r;
				var this1 = t._0;
				$r = { _0 : this1._0, _1 : this1._1, _2 : t._1};
				return $r;
			}(this)));
		},function(e) {
			reject(e);
		});
	});
};
thx_promise_PromiseTuple2.mapTuplePromise = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccessPromise(promise,function(t) {
		return success(t._0,t._1);
	});
};
thx_promise_PromiseTuple2.mapTuple = function(promise,success) {
	return thx_promise__$Promise_Promise_$Impl_$.mapSuccess(promise,function(t) {
		return success(t._0,t._1);
	});
};
thx_promise_PromiseTuple2.tuple = function(promise,success,failure) {
	return thx_promise__$Promise_Promise_$Impl_$.either(promise,function(t) {
		success(t._0,t._1);
	},null == failure?function(_) {
	}:failure);
};
var thx_promise_PromiseNil = function() { };
thx_promise_PromiseNil.__name__ = ["thx","promise","PromiseNil"];
thx_promise_PromiseNil.join = function(p1,p2) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.either(thx_promise_Promises.join(p1,p2),function(t) {
			resolve(t._1);
		},function(e) {
			reject(e);
		});
	});
};
thx_promise_PromiseNil.nil = function(p) {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,reject) {
		thx_promise__$Promise_Promise_$Impl_$.failure(thx_promise__$Promise_Promise_$Impl_$.success(p,function(_) {
			resolve(thx_core_Nil.nil);
		}),reject);
	});
};
var thx_promise_Timer = function() { };
thx_promise_Timer.__name__ = ["thx","promise","Timer"];
thx_promise_Timer.delay = function(delayms) {
	return thx_promise_Timer.delayValue(thx_core_Nil.nil,delayms);
};
thx_promise_Timer.delayValue = function(value,delayms) {
	return thx_promise_Future.create(function(callback) {
		thx_core_Timer.delay((function(f,a1) {
			return function() {
				f(a1);
			};
		})(callback,value),delayms);
	});
};
thx_promise_Timer.immediate = function() {
	return thx_promise_Timer.immediateValue(thx_core_Nil.nil);
};
thx_promise_Timer.immediateValue = function(value) {
	return thx_promise_Future.create(function(callback) {
		thx_core_Timer.immediate((function(f,a1) {
			return function() {
				f(a1);
			};
		})(callback,value));
	});
};
var thx_stream_Emitter = function(init) {
	this.init = init;
};
thx_stream_Emitter.__name__ = ["thx","stream","Emitter"];
thx_stream_Emitter.prototype = {
	init: null
	,feed: function(value) {
		var stream = new thx_stream_Stream(null);
		stream.subscriber = function(r) {
			switch(r[1]) {
			case 0:
				var v = r[2];
				value.set(v);
				break;
			case 1:
				var c = r[2];
				if(c) stream.cancel(); else stream.end();
				break;
			}
		};
		value.upStreams.push(stream);
		stream.addCleanUp(function() {
			HxOverrides.remove(value.upStreams,stream);
		});
		this.init(stream);
		return stream;
	}
	,plug: function(bus) {
		var stream = new thx_stream_Stream(null);
		stream.subscriber = $bind(bus,bus.emit);
		bus.upStreams.push(stream);
		stream.addCleanUp(function() {
			HxOverrides.remove(bus.upStreams,stream);
		});
		this.init(stream);
		return stream;
	}
	,sign: function(subscriber) {
		var stream = new thx_stream_Stream(subscriber);
		this.init(stream);
		return stream;
	}
	,subscribe: function(pulse,end) {
		if(null != pulse) pulse = pulse; else pulse = function(_) {
		};
		if(null != end) end = end; else end = function(_1) {
		};
		var stream = new thx_stream_Stream(function(r) {
			switch(r[1]) {
			case 0:
				var v = r[2];
				pulse(v);
				break;
			case 1:
				var c = r[2];
				end(c);
				break;
			}
		});
		this.init(stream);
		return stream;
	}
	,concat: function(other) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					stream.pulse(v);
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						other.init(stream);
						break;
					}
					break;
				}
			}));
		});
	}
	,count: function() {
		return this.map((function() {
			var c = 0;
			return function(_) {
				return ++c;
			};
		})());
	}
	,debounce: function(delay) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var cancel = function() {
			};
			stream.addCleanUp(function() {
				cancel();
			});
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					cancel();
					cancel = thx_core_Timer.delay((function(f,v1) {
						return function() {
							f(v1);
						};
					})($bind(stream,stream.pulse),v),delay);
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						thx_core_Timer.delay($bind(stream,stream.end),delay);
						break;
					}
					break;
				}
			}));
		});
	}
	,delay: function(time) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var cancel = thx_core_Timer.delay(function() {
				_g.init(stream);
			},time);
			stream.addCleanUp(cancel);
		});
	}
	,diff: function(init,f) {
		return this.window(2,null != init).map(function(a) {
			if(a.length == 1) return f(init,a[0]); else return f(a[0],a[1]);
		});
	}
	,merge: function(other) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			_g.init(stream);
			other.init(stream);
		});
	}
	,previous: function() {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var value = null;
			var first = true;
			var pulse = function() {
				if(first) {
					first = false;
					return;
				}
				stream.pulse(value);
			};
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					pulse();
					value = v;
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,reduce: function(acc,f) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					acc = f(acc,v);
					stream.pulse(acc);
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,window: function(size,emitWithLess) {
		if(emitWithLess == null) emitWithLess = false;
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var buf = [];
			var pulse = function() {
				if(buf.length > size) buf.shift();
				if(buf.length == size || emitWithLess) stream.pulse(buf.slice());
			};
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					buf.push(v);
					pulse();
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,map: function(f) {
		return this.mapFuture(function(v) {
			return thx_promise_Future.value(f(v));
		});
	}
	,mapFuture: function(f) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					f(v).then($bind(stream,stream.pulse));
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,toOption: function() {
		return this.map(function(v) {
			if(null == v) return haxe_ds_Option.None; else return haxe_ds_Option.Some(v);
		});
	}
	,toNil: function() {
		return this.map(function(_) {
			return thx_core_Nil.nil;
		});
	}
	,toTrue: function() {
		return this.map(function(_) {
			return true;
		});
	}
	,toFalse: function() {
		return this.map(function(_) {
			return false;
		});
	}
	,toValue: function(value) {
		return this.map(function(_) {
			return value;
		});
	}
	,filter: function(f) {
		return this.filterFuture(function(v) {
			return thx_promise_Future.value(f(v));
		});
	}
	,filterFuture: function(f) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					f(v).then(function(c) {
						if(c) stream.pulse(v);
					});
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,first: function() {
		return this.take(1);
	}
	,distinct: function(equals) {
		if(null == equals) equals = function(a,b) {
			return a == b;
		};
		var last = null;
		return this.filter(function(v) {
			if(equals(v,last)) return false; else {
				last = v;
				return true;
			}
		});
	}
	,last: function() {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var last = null;
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					last = v;
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.pulse(last);
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,memberOf: function(arr,equality) {
		return this.filter(function(v) {
			return thx_core_Arrays.contains(arr,v,equality);
		});
	}
	,notNull: function() {
		return this.filter(function(v) {
			return v != null;
		});
	}
	,skip: function(n) {
		return this.skipUntil((function() {
			var count = 0;
			return function(_) {
				return count++ < n;
			};
		})());
	}
	,skipUntil: function(predicate) {
		return this.filter((function() {
			var flag = false;
			return function(v) {
				if(flag) return true;
				if(predicate(v)) return false;
				return flag = true;
			};
		})());
	}
	,take: function(count) {
		return this.takeUntil((function(counter) {
			return function(_) {
				return counter++ < count;
			};
		})(0));
	}
	,takeAt: function(index) {
		return this.take(index + 1).last();
	}
	,takeLast: function(n) {
		return thx_stream_EmitterArrays.flatten(this.window(n).last());
	}
	,takeUntil: function(f) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var instream = null;
			instream = new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					if(f(v)) stream.pulse(v); else {
						instream.end();
						stream.end();
					}
					break;
				case 1:
					switch(r[2]) {
					case true:
						instream.cancel();
						stream.cancel();
						break;
					case false:
						instream.end();
						stream.end();
						break;
					}
					break;
				}
			});
			_g.init(instream);
		});
	}
	,withValue: function(expected) {
		return this.filter(function(v) {
			return v == expected;
		});
	}
	,pair: function(other) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var _0 = null;
			var _1 = null;
			stream.addCleanUp(function() {
				_0 = null;
				_1 = null;
			});
			var pulse = function() {
				if(null == _0 || null == _1) return;
				stream.pulse({ _0 : _0, _1 : _1});
			};
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					_0 = v;
					pulse();
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
			other.init(new thx_stream_Stream(function(r1) {
				switch(r1[1]) {
				case 0:
					var v1 = r1[2];
					_1 = v1;
					pulse();
					break;
				case 1:
					switch(r1[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,sampleBy: function(sampler) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var _0 = null;
			var _1 = null;
			stream.addCleanUp(function() {
				_0 = null;
				_1 = null;
			});
			var pulse = function() {
				if(null == _0 || null == _1) return;
				stream.pulse({ _0 : _0, _1 : _1});
			};
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					_0 = v;
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
			sampler.init(new thx_stream_Stream(function(r1) {
				switch(r1[1]) {
				case 0:
					var v1 = r1[2];
					_1 = v1;
					pulse();
					break;
				case 1:
					switch(r1[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,samplerOf: function(sampled) {
		return sampled.sampleBy(this).map(function(t) {
			return { _0 : t._1, _1 : t._0};
		});
	}
	,zip: function(other) {
		var _g = this;
		return new thx_stream_Emitter(function(stream) {
			var _0 = [];
			var _1 = [];
			stream.addCleanUp(function() {
				_0 = null;
				_1 = null;
			});
			var pulse = function() {
				if(_0.length == 0 || _1.length == 0) return;
				stream.pulse((function($this) {
					var $r;
					var _01 = _0.shift();
					var _11 = _1.shift();
					$r = { _0 : _01, _1 : _11};
					return $r;
				}(this)));
			};
			_g.init(new thx_stream_Stream(function(r) {
				switch(r[1]) {
				case 0:
					var v = r[2];
					_0.push(v);
					pulse();
					break;
				case 1:
					switch(r[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
			other.init(new thx_stream_Stream(function(r1) {
				switch(r1[1]) {
				case 0:
					var v1 = r1[2];
					_1.push(v1);
					pulse();
					break;
				case 1:
					switch(r1[2]) {
					case true:
						stream.cancel();
						break;
					case false:
						stream.end();
						break;
					}
					break;
				}
			}));
		});
	}
	,audit: function(handler) {
		return this.map(function(v) {
			handler(v);
			return v;
		});
	}
	,log: function(prefix,posInfo) {
		if(prefix == null) prefix = ""; else prefix = "" + prefix + ": ";
		return this.map(function(v) {
			haxe_Log.trace("" + prefix + Std.string(v),posInfo);
			return v;
		});
	}
	,split: function() {
		var _g = this;
		var inited = false;
		var streams = [];
		var init = function(stream) {
			streams.push(stream);
			if(!inited) {
				inited = true;
				thx_core_Timer.immediate(function() {
					_g.init(new thx_stream_Stream(function(r) {
						switch(r[1]) {
						case 0:
							var v = r[2];
							var _g1 = 0;
							while(_g1 < streams.length) {
								var s = streams[_g1];
								++_g1;
								s.pulse(v);
							}
							break;
						case 1:
							switch(r[2]) {
							case true:
								var _g11 = 0;
								while(_g11 < streams.length) {
									var s1 = streams[_g11];
									++_g11;
									s1.cancel();
								}
								break;
							case false:
								var _g12 = 0;
								while(_g12 < streams.length) {
									var s2 = streams[_g12];
									++_g12;
									s2.end();
								}
								break;
							}
							break;
						}
					}));
				});
			}
		};
		var _0 = new thx_stream_Emitter(init);
		var _1 = new thx_stream_Emitter(init);
		return { _0 : _0, _1 : _1};
	}
	,__class__: thx_stream_Emitter
};
var thx_stream_Bus = function(distinctValuesOnly,equal) {
	if(distinctValuesOnly == null) distinctValuesOnly = false;
	var _g = this;
	this.distinctValuesOnly = distinctValuesOnly;
	if(null == equal) this.equal = function(a,b) {
		return a == b;
	}; else this.equal = equal;
	this.downStreams = [];
	this.upStreams = [];
	thx_stream_Emitter.call(this,function(stream) {
		_g.downStreams.push(stream);
		stream.addCleanUp(function() {
			HxOverrides.remove(_g.downStreams,stream);
		});
	});
};
thx_stream_Bus.__name__ = ["thx","stream","Bus"];
thx_stream_Bus.__super__ = thx_stream_Emitter;
thx_stream_Bus.prototype = $extend(thx_stream_Emitter.prototype,{
	downStreams: null
	,upStreams: null
	,distinctValuesOnly: null
	,equal: null
	,value: null
	,cancel: function() {
		this.emit(thx_stream_StreamValue.End(true));
	}
	,clear: function() {
		this.clearEmitters();
		this.clearStreams();
	}
	,clearStreams: function() {
		var _g = 0;
		var _g1 = this.downStreams.slice();
		while(_g < _g1.length) {
			var stream = _g1[_g];
			++_g;
			stream.end();
		}
	}
	,clearEmitters: function() {
		var _g = 0;
		var _g1 = this.upStreams.slice();
		while(_g < _g1.length) {
			var stream = _g1[_g];
			++_g;
			stream.cancel();
		}
	}
	,emit: function(value) {
		switch(value[1]) {
		case 0:
			var v = value[2];
			if(this.distinctValuesOnly) {
				if(this.equal(v,this.value)) return;
				this.value = v;
			}
			var _g = 0;
			var _g1 = this.downStreams.slice();
			while(_g < _g1.length) {
				var stream = _g1[_g];
				++_g;
				stream.pulse(v);
			}
			break;
		case 1:
			switch(value[2]) {
			case true:
				var _g2 = 0;
				var _g11 = this.downStreams.slice();
				while(_g2 < _g11.length) {
					var stream1 = _g11[_g2];
					++_g2;
					stream1.cancel();
				}
				break;
			case false:
				var _g3 = 0;
				var _g12 = this.downStreams.slice();
				while(_g3 < _g12.length) {
					var stream2 = _g12[_g3];
					++_g3;
					stream2.end();
				}
				break;
			}
			break;
		}
	}
	,end: function() {
		this.emit(thx_stream_StreamValue.End(false));
	}
	,pulse: function(value) {
		this.emit(thx_stream_StreamValue.Pulse(value));
	}
	,__class__: thx_stream_Bus
});
var thx_stream_Emitters = function() { };
thx_stream_Emitters.__name__ = ["thx","stream","Emitters"];
thx_stream_Emitters.skipNull = function(emitter) {
	return emitter.filter(function(value) {
		return null != value;
	});
};
thx_stream_Emitters.unique = function(emitter) {
	return emitter.filter((function() {
		var buf = [];
		return function(v) {
			if(HxOverrides.indexOf(buf,v,0) >= 0) return false; else {
				buf.push(v);
				return true;
			}
		};
	})());
};
var thx_stream_EmitterStrings = function() { };
thx_stream_EmitterStrings.__name__ = ["thx","stream","EmitterStrings"];
thx_stream_EmitterStrings.match = function(emitter,pattern) {
	return emitter.filter(function(s) {
		return pattern.match(s);
	});
};
thx_stream_EmitterStrings.toBool = function(emitter) {
	return emitter.map(function(s) {
		return s != null && s != "";
	});
};
thx_stream_EmitterStrings.truthy = function(emitter) {
	return emitter.filter(function(s) {
		return s != null && s != "";
	});
};
thx_stream_EmitterStrings.unique = function(emitter) {
	return emitter.filter((function() {
		var buf = new haxe_ds_StringMap();
		return function(v) {
			if(__map_reserved[v] != null?buf.existsReserved(v):buf.h.hasOwnProperty(v)) return false; else {
				if(__map_reserved[v] != null) buf.setReserved(v,true); else buf.h[v] = true;
				return true;
			}
		};
	})());
};
var thx_stream_EmitterInts = function() { };
thx_stream_EmitterInts.__name__ = ["thx","stream","EmitterInts"];
thx_stream_EmitterInts.average = function(emitter) {
	return emitter.map((function() {
		var sum = 0.0;
		var count = 0;
		return function(v) {
			return (sum += v) / ++count;
		};
	})());
};
thx_stream_EmitterInts.greaterThan = function(emitter,x) {
	return emitter.filter(function(v) {
		return v > x;
	});
};
thx_stream_EmitterInts.greaterThanOrEqualTo = function(emitter,x) {
	return emitter.filter(function(v) {
		return v >= x;
	});
};
thx_stream_EmitterInts.inRange = function(emitter,min,max) {
	return emitter.filter(function(v) {
		return v <= max && v >= min;
	});
};
thx_stream_EmitterInts.insideRange = function(emitter,min,max) {
	return emitter.filter(function(v) {
		return v < max && v > min;
	});
};
thx_stream_EmitterInts.lessThan = function(emitter,x) {
	return emitter.filter(function(v) {
		return v < x;
	});
};
thx_stream_EmitterInts.lessThanOrEqualTo = function(emitter,x) {
	return emitter.filter(function(v) {
		return v <= x;
	});
};
thx_stream_EmitterInts.max = function(emitter) {
	return emitter.filter((function() {
		var max = null;
		return function(v) {
			if(null == max || v > max) {
				max = v;
				return true;
			} else return false;
		};
	})());
};
thx_stream_EmitterInts.min = function(emitter) {
	return emitter.filter((function() {
		var min = null;
		return function(v) {
			if(null == min || v < min) {
				min = v;
				return true;
			} else return false;
		};
	})());
};
thx_stream_EmitterInts.sum = function(emitter) {
	return emitter.map((function() {
		var value = 0;
		return function(v) {
			return value += v;
		};
	})());
};
thx_stream_EmitterInts.toBool = function(emitter) {
	return emitter.map(function(i) {
		return i != 0;
	});
};
thx_stream_EmitterInts.unique = function(emitter) {
	return emitter.filter((function() {
		var buf = new haxe_ds_IntMap();
		return function(v) {
			if(buf.h.hasOwnProperty(v)) return false; else {
				buf.h[v] = true;
				return true;
			}
		};
	})());
};
var thx_stream_EmitterFloats = function() { };
thx_stream_EmitterFloats.__name__ = ["thx","stream","EmitterFloats"];
thx_stream_EmitterFloats.average = function(emitter) {
	return emitter.map((function() {
		var sum = 0.0;
		var count = 0;
		return function(v) {
			return (sum += v) / ++count;
		};
	})());
};
thx_stream_EmitterFloats.greaterThan = function(emitter,x) {
	return emitter.filter(function(v) {
		return v > x;
	});
};
thx_stream_EmitterFloats.greaterThanOrEqualTo = function(emitter,x) {
	return emitter.filter(function(v) {
		return v >= x;
	});
};
thx_stream_EmitterFloats.inRange = function(emitter,min,max) {
	return emitter.filter(function(v) {
		return v <= max && v >= min;
	});
};
thx_stream_EmitterFloats.insideRange = function(emitter,min,max) {
	return emitter.filter(function(v) {
		return v < max && v > min;
	});
};
thx_stream_EmitterFloats.lessThan = function(emitter,x) {
	return emitter.filter(function(v) {
		return v < x;
	});
};
thx_stream_EmitterFloats.lessThanOrEqualTo = function(emitter,x) {
	return emitter.filter(function(v) {
		return v <= x;
	});
};
thx_stream_EmitterFloats.max = function(emitter) {
	return emitter.filter((function() {
		var max = -Infinity;
		return function(v) {
			if(v > max) {
				max = v;
				return true;
			} else return false;
		};
	})());
};
thx_stream_EmitterFloats.min = function(emitter) {
	return emitter.filter((function() {
		var min = Infinity;
		return function(v) {
			if(v < min) {
				min = v;
				return true;
			} else return false;
		};
	})());
};
thx_stream_EmitterFloats.sum = function(emitter) {
	return emitter.map((function() {
		var sum = 0.0;
		return function(v) {
			return sum += v;
		};
	})());
};
var thx_stream_EmitterOptions = function() { };
thx_stream_EmitterOptions.__name__ = ["thx","stream","EmitterOptions"];
thx_stream_EmitterOptions.either = function(emitter,some,none,end) {
	if(null == some) some = function(_) {
	};
	if(null == none) none = function() {
	};
	return emitter.subscribe(function(o) {
		switch(o[1]) {
		case 0:
			var v = o[2];
			some(v);
			break;
		case 1:
			none();
			break;
		}
	},end);
};
thx_stream_EmitterOptions.filterOption = function(emitter) {
	return emitter.filter(function(opt) {
		return thx_core_Options.toBool(opt);
	}).map(function(opt1) {
		return thx_core_Options.toValue(opt1);
	});
};
thx_stream_EmitterOptions.toBool = function(emitter) {
	return emitter.map(function(opt) {
		return thx_core_Options.toBool(opt);
	});
};
thx_stream_EmitterOptions.toValue = function(emitter) {
	return emitter.map(function(opt) {
		return thx_core_Options.toValue(opt);
	});
};
var thx_stream_EmitterBools = function() { };
thx_stream_EmitterBools.__name__ = ["thx","stream","EmitterBools"];
thx_stream_EmitterBools.negate = function(emitter) {
	return emitter.map(function(v) {
		return !v;
	});
};
var thx_stream_EmitterEmitters = function() { };
thx_stream_EmitterEmitters.__name__ = ["thx","stream","EmitterEmitters"];
thx_stream_EmitterEmitters.flatMap = function(emitter) {
	return new thx_stream_Emitter(function(stream) {
		emitter.init(new thx_stream_Stream(function(r) {
			switch(r[1]) {
			case 0:
				var em = r[2];
				em.init(stream);
				break;
			case 1:
				switch(r[2]) {
				case true:
					stream.cancel();
					break;
				case false:
					stream.end();
					break;
				}
				break;
			}
		}));
	});
};
var thx_stream_EmitterArrays = function() { };
thx_stream_EmitterArrays.__name__ = ["thx","stream","EmitterArrays"];
thx_stream_EmitterArrays.containerOf = function(emitter,value) {
	return emitter.filter(function(arr) {
		return HxOverrides.indexOf(arr,value,0) >= 0;
	});
};
thx_stream_EmitterArrays.flatten = function(emitter) {
	return new thx_stream_Emitter(function(stream) {
		emitter.init(new thx_stream_Stream(function(r) {
			switch(r[1]) {
			case 0:
				var arr = r[2];
				arr.map($bind(stream,stream.pulse));
				break;
			case 1:
				switch(r[2]) {
				case true:
					stream.cancel();
					break;
				case false:
					stream.end();
					break;
				}
				break;
			}
		}));
	});
};
var thx_stream_EmitterValues = function() { };
thx_stream_EmitterValues.__name__ = ["thx","stream","EmitterValues"];
thx_stream_EmitterValues.left = function(emitter) {
	return emitter.map(function(v) {
		return v._0;
	});
};
thx_stream_EmitterValues.right = function(emitter) {
	return emitter.map(function(v) {
		return v._1;
	});
};
var thx_stream_IStream = function() { };
thx_stream_IStream.__name__ = ["thx","stream","IStream"];
thx_stream_IStream.prototype = {
	cancel: null
	,__class__: thx_stream_IStream
};
var thx_stream_Stream = function(subscriber) {
	this.subscriber = subscriber;
	this.cleanUps = [];
	this.finalized = false;
	this.canceled = false;
};
thx_stream_Stream.__name__ = ["thx","stream","Stream"];
thx_stream_Stream.__interfaces__ = [thx_stream_IStream];
thx_stream_Stream.prototype = {
	subscriber: null
	,cleanUps: null
	,finalized: null
	,canceled: null
	,addCleanUp: function(f) {
		this.cleanUps.push(f);
	}
	,cancel: function() {
		this.canceled = true;
		this.finalize(thx_stream_StreamValue.End(true));
	}
	,end: function() {
		this.finalize(thx_stream_StreamValue.End(false));
	}
	,pulse: function(v) {
		this.subscriber(thx_stream_StreamValue.Pulse(v));
	}
	,finalize: function(signal) {
		if(this.finalized) return;
		this.finalized = true;
		while(this.cleanUps.length > 0) (this.cleanUps.shift())();
		this.subscriber(signal);
		this.subscriber = function(_) {
		};
	}
	,__class__: thx_stream_Stream
};
var thx_stream_StreamValue = { __ename__ : ["thx","stream","StreamValue"], __constructs__ : ["Pulse","End"] };
thx_stream_StreamValue.Pulse = function(value) { var $x = ["Pulse",0,value]; $x.__enum__ = thx_stream_StreamValue; $x.toString = $estr; return $x; };
thx_stream_StreamValue.End = function(cancel) { var $x = ["End",1,cancel]; $x.__enum__ = thx_stream_StreamValue; $x.toString = $estr; return $x; };
var thx_stream_Value = function(value,equals) {
	var _g = this;
	if(null == equals) this.equals = thx_core_Functions.equality; else this.equals = equals;
	this.value = value;
	this.downStreams = [];
	this.upStreams = [];
	thx_stream_Emitter.call(this,function(stream) {
		_g.downStreams.push(stream);
		stream.addCleanUp(function() {
			HxOverrides.remove(_g.downStreams,stream);
		});
		stream.pulse(_g.value);
	});
};
thx_stream_Value.__name__ = ["thx","stream","Value"];
thx_stream_Value.createOption = function(value,equals) {
	var def;
	if(null == value) def = haxe_ds_Option.None; else def = haxe_ds_Option.Some(value);
	return new thx_stream_Value(def,function(a,b) {
		return thx_core_Options.equals(a,b,equals);
	});
};
thx_stream_Value.__super__ = thx_stream_Emitter;
thx_stream_Value.prototype = $extend(thx_stream_Emitter.prototype,{
	value: null
	,downStreams: null
	,upStreams: null
	,equals: null
	,get: function() {
		return this.value;
	}
	,clear: function() {
		this.clearEmitters();
		this.clearStreams();
	}
	,clearStreams: function() {
		var _g = 0;
		var _g1 = this.downStreams.slice();
		while(_g < _g1.length) {
			var stream = _g1[_g];
			++_g;
			stream.end();
		}
	}
	,clearEmitters: function() {
		var _g = 0;
		var _g1 = this.upStreams.slice();
		while(_g < _g1.length) {
			var stream = _g1[_g];
			++_g;
			stream.cancel();
		}
	}
	,set: function(value) {
		if(this.equals(this.value,value)) return;
		this.value = value;
		this.update();
	}
	,update: function() {
		var _g = 0;
		var _g1 = this.downStreams.slice();
		while(_g < _g1.length) {
			var stream = _g1[_g];
			++_g;
			stream.pulse(this.value);
		}
	}
	,__class__: thx_stream_Value
});
var thx_stream_dom_Dom = function() { };
thx_stream_dom_Dom.__name__ = ["thx","stream","dom","Dom"];
thx_stream_dom_Dom.ready = function() {
	return thx_promise__$Promise_Promise_$Impl_$.create(function(resolve,_) {
		window.document.addEventListener("DOMContentLoaded",function(_1) {
			resolve(thx_core_Nil.nil);
		},false);
	});
};
thx_stream_dom_Dom.streamClick = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"click",capture);
};
thx_stream_dom_Dom.streamEvent = function(el,name,capture) {
	if(capture == null) capture = false;
	return new thx_stream_Emitter(function(stream) {
		el.addEventListener(name,$bind(stream,stream.pulse),capture);
		stream.addCleanUp(function() {
			el.removeEventListener(name,$bind(stream,stream.pulse),capture);
		});
	});
};
thx_stream_dom_Dom.streamFocus = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"focus",capture).toTrue().merge(thx_stream_dom_Dom.streamEvent(el,"blur",capture).toFalse());
};
thx_stream_dom_Dom.streamKey = function(el,name,capture) {
	if(capture == null) capture = false;
	return new thx_stream_Emitter((function($this) {
		var $r;
		if(!StringTools.startsWith(name,"key")) name = "key" + name;
		$r = function(stream) {
			el.addEventListener(name,$bind(stream,stream.pulse),capture);
			stream.addCleanUp(function() {
				el.removeEventListener(name,$bind(stream,stream.pulse),capture);
			});
		};
		return $r;
	}(this)));
};
thx_stream_dom_Dom.streamChecked = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"change",capture).map(function(_) {
		return el.checked;
	});
};
thx_stream_dom_Dom.streamChange = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"change",capture).map(function(_) {
		return el.value;
	});
};
thx_stream_dom_Dom.streamInput = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"input",capture).map(function(_) {
		return el.value;
	});
};
thx_stream_dom_Dom.streamMouseDown = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"mousedown",capture);
};
thx_stream_dom_Dom.streamMouseEvent = function(el,name,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,name,capture);
};
thx_stream_dom_Dom.streamMouseMove = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"mousemove",capture);
};
thx_stream_dom_Dom.streamMouseUp = function(el,capture) {
	if(capture == null) capture = false;
	return thx_stream_dom_Dom.streamEvent(el,"mouseup",capture);
};
thx_stream_dom_Dom.subscribeAttribute = function(el,name) {
	return function(value) {
		if(null == value) el.removeAttribute(name); else el.setAttribute(name,value);
	};
};
thx_stream_dom_Dom.subscribeFocus = function(el) {
	return function(focus) {
		if(focus) el.focus(); else el.blur();
	};
};
thx_stream_dom_Dom.subscribeHTML = function(el) {
	return function(html) {
		el.innerHTML = html;
	};
};
thx_stream_dom_Dom.subscribeText = function(el,force) {
	if(force == null) force = false;
	return function(text) {
		if(el.textContent != text || force) el.textContent = text;
	};
};
thx_stream_dom_Dom.subscribeToggleAttribute = function(el,name,value) {
	if(null == value) value = el.getAttribute(name);
	return function(on) {
		if(on) el.setAttribute(name,value); else el.removeAttribute(name);
	};
};
thx_stream_dom_Dom.subscribeToggleClass = function(el,name) {
	return function(on) {
		if(on) el.classList.add(name); else el.classList.remove(name);
	};
};
thx_stream_dom_Dom.subscribeSwapClass = function(el,nameOn,nameOff) {
	return function(on) {
		if(on) {
			el.classList.add(nameOn);
			el.classList.remove(nameOff);
		} else {
			el.classList.add(nameOff);
			el.classList.remove(nameOn);
		}
	};
};
thx_stream_dom_Dom.subscribeToggleVisibility = function(el) {
	var originalDisplay = el.style.display;
	if(originalDisplay == "none") originalDisplay = "";
	return function(on) {
		if(on) el.style.display = originalDisplay; else el.style.display = "none";
	};
};
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; }
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
if(Array.prototype.indexOf) HxOverrides.indexOf = function(a,o,i) {
	return Array.prototype.indexOf.call(a,o,i);
};
String.prototype.__class__ = String;
String.__name__ = ["String"];
Array.__name__ = ["Array"];
Date.prototype.__class__ = Date;
Date.__name__ = ["Date"];
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
if(Array.prototype.map == null) Array.prototype.map = function(f) {
	var a = [];
	var _g1 = 0;
	var _g = this.length;
	while(_g1 < _g) {
		var i = _g1++;
		a[i] = f(this[i]);
	}
	return a;
};
if(Array.prototype.filter == null) Array.prototype.filter = function(f1) {
	var a1 = [];
	var _g11 = 0;
	var _g2 = this.length;
	while(_g11 < _g2) {
		var i1 = _g11++;
		var e = this[i1];
		if(f1(e)) a1.push(e);
	}
	return a1;
};
haxe_Resource.content = [{ name : "australia", data : "AgAAABYDAAAK19FDZ2YoQwrX0UPieipDKlzSQ1yPLENnZtNDmpktQ2dm00MVri9DZ2bTQ4/CMUOF69NDC9czQ6Nw1EOF6zVDo3DUQwAAOEPietVDAAA4Q+J61UOF6zVDH4XWQ0jhNEM9CtdDw/U2Q3sU2EMAADhDuB7ZQz4KOUOamdhDw/U2Q9ej2UPD9TZD9yjaQz4KOUP3KNpDuB47Q/co2kMzMz1D9yjaQ69HP0P3KNpDKVxBQxWu2kOkcENDUrjbQ6RwQ0OQwtxDH4VFQ83M3UOamUdDCtfeQ9ejSENI4d9DFa5JQ2dm4EOPwktDo3DhQwvXTUPieuJDSOFOQwAA40PD9VBDH4XjQz4KU0Ndj+RDuB5VQ5qZ5UMzM1dDexTlQ69HWUOameVDKlxbQ7ge5kOjcF1DuB7mQx+FX0O4HuZDmplhQ7ge5kMVrmNDuB7mQ5DCZUPXo+ZDCtdnQ5qZ5UNI4WhD16PmQ8P1akP3KOdDPQptQxWu50O4Hm9DFa7nQzMzcUMzM+hDr0dzQ1K46EMqXHVDUrjoQ6Nwd0NSuOhDH4V5QzMz6EOamXtDFa7nQxWufUMVrudDkMJ/Q/co50OF64BD9yjnQ8P1gUPXo+ZDAACDQ9ej5kM+CoRDuB7mQ3sUhUOameVDuB6GQ5qZ5UP2KIdDuB7mQzMziEOameVDcT2JQ3sU5UOvR4pDexTlQ+tRi0Ndj+RDKVyMQx+F40NnZo1DH4XjQ6RwjkMAAOND4nqPQ8P14UMAAJBDhevgQz4KkUNI4d9DXI+RQwrX3kOamZJD61HeQ9ejk0PNzN1DFa6UQ5DC3ENSuJVDkMLcQ4/ClkNwPdxDzcyXQ1K420ML15hDFa7aQ0jhmUMVrtpDheuaQ/co2kPD9ZtD9yjaQwAAnUO4HtlDPgqeQ5qZ2EN7FJ9DexTYQ7geoEM9CtdD16OgQz0K10MVrqFDH4XWQ1K4okMfhdZDj8KjQx+F1kPNzKRDAADWQwvXpUPietVDSOGmQ+J61UOF66dDAADWQ8P1qEMAANZDAACqQ8P11EMAAKpDhevTQz4Kq0NI4dJDXI+rQwrX0UNcj6tDzczQQ1yPq0OQws9DXI+rQ1K4zkNcj6tDFa7NQ1yPq0PXo8xDexSsQ5qZy0N7FKxDPgrKQ5qZrEMAAMlDuB6tQ8P1x0P2KK5DhevGQxWurkNI4cVDUrivQwvXxENxPbBDzczDQ3E9sEOPwsJDcT2wQ4/CwkOvR7FDzczDQ+tRskOPwsJDzcyxQ1K4wUOPwrBDFa7AQ69HsUP2KMBDcT2wQ7gev0NxPbBDexS+QzMzr0Oamb5D9iiuQ1yPvUPXo61DPgq9QxWurkMAALxDMzOvQ8P1ukMVrq5DAAC8Q/YorkMfhbxDuB6tQwAAvEN7FKxDw/W6Q5qZrEOF67lDuB6tQ0jhuEO4Hq1Dheu5Q9ejrUNI4bhD9iiuQwvXt0MVrq5Dzcy2Q1K4r0NxPbVDcT2wQzMztEOvR7FD9iizQ4/CsEO4HrJDcT2wQ3sUsUNSuK9DPgqwQzMzr0MAAK9DFa6uQ8P1rUMVrq5DheusQxWurkNI4atD9iiuQwvXqkP2KK5DzcypQxWurkOPwqhD9iiuQ1K4p0O4Hq1DFa6mQ7gerUPXo6VDuB6tQ5qZpEOamaxDXI+jQ1yPq0M+CqNDH4WqQwAAokMAAKpDw/WgQ8P1qEPD9aBDheunQ8P1oENI4aZD4nqhQwvXpUPD9aBDzcykQ6RwoEOPwqNDheufQ1K4okNI4Z5DFa6hQwvXnUPXo6BDzcycQ7geoEML151D16OgQ0jhnkMVrqFDheufQ1K4okNI4Z5DFa6hQwvXnUPXo6BDC9edQ5qZn0MpXJ5D16OgQylcnkOamZ9DKVyeQ1yPnkPrUZ1DexSfQ4/Cm0OamZ9DzcycQ5qZn0OPwptDuB6gQ1K4mkO4HqBDFa6ZQ9ejoEPXo5hD16OgQ7gemEOamZ9D9iiZQ3sUn0MzM5pDPgqeQzMzmkMAAJ1DMzOaQ8P1m0MVrplDheuaQ/YomUNI4ZlD16OYQwvXmEOamZdDKVyZQ3sUl0NnZppDexSXQ6Rwm0Ncj5ZD4nqcQz4KlkMfhZ1DAACVQx+FnUPD9ZNDPgqeQ4XrkkM+Cp5DSOGRQ1yPnkNnZpJDH4WdQ4XrkkPiepxDw/WTQ+J6nEMAAJVD4nqcQwAAlUOkcJtDAACVQ0jhmUMAAJVDC9eYQwAAlUPNzJdDH4WVQ4/ClkNcj5ZDUriVQ3sUl0MVrpRDexSXQ9ejk0OamZdDmpmSQ3sUl0Ncj5FDXI+WQx+FkENcj5ZDXI+RQz4KlkOamZJDAACVQ7gek0PiepRD9iiUQ8P1k0MzM5VDpHCTQ3E9lkNnZpJDcT2WQylckUOPwpZD61GQQ69Hl0OvR49DzcyXQ4/CjkML15hDUriNQ0jhmUMVroxDheuaQ/YojEPD9ZtDMzONQ6Rwm0MzM41D4nqcQ/YojEPiepxDuB6LQ+J6nEN7FIpDpHCbQz4KiUOF65pDexSKQ4XrmkN7FIpDSOGZQ1yPiUML15hDXI+JQ83Ml0MfhYhDj8KWQ+J6h0NxPZZD4nqHQzMzlUOkcIZD9iiUQ4XrhUO4HpNDSOGEQ9ejk0ML14NDmpmSQ+tRg0Ncj5FDKVyEQz4KkUML14NDAACQQ83MgkMAAJBDr0eCQ8P1jkNxPYFDpHCOQzMzgEOkcI5D61F+Q6RwjkNwPXxDpHCOQ/coekNnZo1DexR4Q2dmjUMAAHZDZ2aNQ4Xrc0NnZo1DCtdxQ0jhjEOQwm9DKVyMQxWubUML14tDmplrQ+tRi0MfhWlDzcyKQ6NwZ0PNzIpDKlxlQ+tRi0OvR2ND61GLQzMzYUPrUYtDuB5fQ+tRi0M9Cl1D61GLQ8P1WkPrUYtDSOFYQ+tRi0PNzFZD61GLQ1K4VEML14tD16NSQwvXi0Ndj1BDC9eLQ+J6TkMpXIxDZ2ZMQ0jhjEPrUUpDZ2aNQ3E9SEOF641D9ihGQ4XrjUN7FERDpHCOQwAAQkOkcI5Dhes/Q8P1jkML1z1Dw/WOQ4/CO0PD9Y5DFa45Q8P1jkOamTdDw/WOQx+FNUPD9Y5DpHAzQ8P1jkMpXDFDw/WOQ69HL0Pieo9DMzMtQx+FkEO4HitDH4WQQz4KKUM+CpFDw/UmQ1yPkUNI4SRDexSSQ83MIkN7FJJDUrggQ5qZkkPXox5D16OTQ5qZHUMVrpRDXI8cQ1K4lUPiehpDj8KWQ2dmGEOvR5dD61EWQ69Hl0NxPRRDr0eXQ/YoEkOvR5dDexQQQ69Hl0MAAA5Dr0eXQ4XrC0OvR5dDC9cJQ83Ml0PNzAhDj8KWQ1K4BkOvR5dD16MEQ4/ClkNcjwJDj8KWQ+J6AEOvR5dDzcz8Qq9Hl0PXo/hCr0eXQ+J69EKvR5dD61HwQs3Ml0N7FOpCr0eXQ4Xr5ULNzJdDkMLhQs3Ml0MVrt9CC9eYQ5qZ3UJI4ZlDo3DZQmdmmkOvR9VCZ2aaQ7ge0UJnZppDw/XMQoXrmkPNzMhCpHCbQ1K4xkLiepxDXI/CQuJ6nENnZr5CAACdQ3E9ukIfhZ1DexS2Qh+FnUOF67FCAACdQ4/CrUIAAJ1DmpmpQgAAnUOkcKVCAACdQ69HoUIAAJ1DuB6dQgAAnUPD9ZhC4nqcQ83MlELD9ZtD16OQQoXrmkPieoxCZ2aaQ+tRiEJI4ZlD9iiEQilcmUMAAIBCKVyZQwAAgELrUZhDAACAQq9Hl0MAAIBCcT2WQ/YohEJSuJVD61GIQlK4lUPieoxCFa6UQ1yPjkLXo5NDXI+OQpqZkkPieoxCXI+RQ+J6jEIfhZBD16OQQh+FkENcj45C4nqPQ1yPjkKkcI5DXI+OQmdmjUNcj45CKVyMQ+J6jELrUYtDZ2aKQq9HikPrUYhCcT2JQ3E9hkIzM4hD9iiEQvYoh0N7FIJCuB6GQwAAgEJ7FIVDAACAQj4KhEMAAIBCAACDQwrXe0LD9YFDAACAQoXrgEMK13tCkMJ/QwrXe0IVrn1DH4VzQpqZe0MqXG9C4np4QzMza0JnZnZDPQpnQutRdENSuF5Cr0dzQ12PWkIzM3FDXY9aQrgeb0Ndj1pCPQptQ2dmVkLD9WpDcD1SQkjhaEN7FE5CzcxmQ4XrSUJSuGRDmplBQtejYkOvRzlCmplhQ69HOUIfhV9Dr0c5QqNwXUOvRzlCH4VfQ6RwPUKjcF1DmplBQh+FX0OamUFCmplhQ4XrSULXo2JDcD1SQl2PYEOF60lC4npeQ5qZQUJnZlxDpHA9QutRWkOamUFCcD1YQ4XrSULrUVpDhetJQmdmXEN7FE5C4npeQ3A9UkJnZlxDcD1SQuJ6XkNnZlZCXY9gQ1K4XkIfhV9DUrheQqNwXUNSuF5CKlxbQ12PWkKvR1lDZ2ZWQjMzV0NwPVJCuB5VQ4XrSUI+ClNDhetJQsP1UEOPwkVCSOFOQ6RwPULNzExDpHA9QlK4SkOkcD1C16NIQ5qZQUJcj0ZDj8JFQuJ6REOF60lCZ2ZCQ3sUTkLrUUBDexROQnE9PkN7FE5C9ig8Q4XrSUJ7FDpDhetJQgAAOEN7FE5Ches1Q3A9UkIL1zNDZ2ZWQo/CMUNSuF5CUrgwQ12PWkLNzDJDXY9aQkjhNENdj1pCw/U2Q0jhYkIAADhDPQpnQoXrNUMzM2tCC9czQypcb0KPwjFDFa53QlK4MEMAAIBCFa4vQ/YohELXoy5D61GIQpqZLUPieoxCH4UrQ9ejkELieipDzcyUQmdmKEPD9ZhCKVwnQ7genULrUSZDr0ehQq9HJUOkcKVCcT0kQ5qZqUKvRyVDj8KtQq9HJUOF67FCr0clQ3sUtkKvRyVDcT26QnE9JENnZr5CMzMjQ1yPwkL2KCJDUrjGQrgeIUNI4cpCuB4hQz0Kz0K4HiFDMzPTQj4KH0MqXNdCAAAeQx+F20IAAB5DFa7fQj4KH0MK1+NCAAAeQwAA6ELD9RxD9yjsQsP1HEPrUfBChesbQ+J69EKF6xtD16P4QkjhGkPNzPxCC9cZQ+J6AEOPwhdDXI8CQxWuFUOamQNDmpkTQ9ejBEMfhRFDUrgGQ6RwD0PNzAhDKVwNQ0jhCkOvRwtDw/UMQ3E9CkNI4QpD9igIQ0jhCkN7FAZDC9cJQwAABENI4QpDhesBQ4XrC0MVrv9CAAAOQ5qZ/UI+Cg9Do3D5QrgeEUOvR/VCMzMTQ7ge8UIzMxNDr0f1QnE9FEOjcPlCr0cVQ5qZ/ULrURZDSOEAQ2dmGEPD9QJDpHAZQ0jhAEOkcBlDmpn9Qh+FG0MVrv9CXI8cQx+F+0LiehpDo3D5QqRwGUOvR/VCZ2YYQ7ge8ULiehpDuB7xQqRwGUPD9exCH4UbQ8P17EJcjxxDuB7xQtejHkM9Cu9CUrggQ7ge8ULNzCJDuB7xQkjhJEO4HvFCw/UmQ7ge8UJI4SRDPQrvQs3MIkM9Cu9Cj8IhQ0jh6kIL1yNDSOHqQkjhJEPXo+RCzcwiQ1K45kKPwiFDXY/iQo/CIUNnZt5CC9cjQ2dm3kJI4SRDcT3aQsP1JkPrUdxCPgopQ2dm3kI+CilDcT3aQsP1JkNxPdpCw/UmQ3sU1kI+CilDAADUQrgeK0N7FNZCuB4rQ4Xr0UI+CilDj8LNQrgeK0MVrstCMzMtQ5qZyUJxPS5DpHDFQq9HL0OamclCKVwxQxWuy0JnZjJDH4XHQqRwM0MpXMNCZ2YyQzMzv0LiejRDMzO/Qh+FNUMpXMNCXI82QzMzv0LXozhDr0fBQlK4OkMzM79CUrg6Qz4Ku0LNzDxDPgq7QkjhPkO4Hr1Cw/VAQ7gevUIAAEJDr0fBQnsUREOkcMVCuB5FQ5qZyUIzM0dDFa7LQq9HSUOPws1CcT1IQ4Xr0UJxPUhDexTWQnE9SENxPdpCMzNHQ2dm3kJxPUhDcT3aQutRSkPrUdxCr0dJQ/Yo2ELrUUpDAADUQilcS0ML189Co3BNQwvXz0IfhU9DC9fPQpqZUUOF69FCFa5TQwAA1EIVrlND9ijYQhWuU0MAANRCkMJVQ4Xr0UIK11dDexTWQgrXV0OF69FChetZQwvXz0IK11dDj8LNQs3MVkOamclCkMJVQ6RwxULNzFZDr0fBQkjhWEMzM79ChetZQz4Ku0KF61lDSOG2QgAAXEPNzLRCexReQ1K4skI9Cl1DXI+uQj0KXUNnZqpCuB5fQ+tRqEL3KGBD9iikQnA9YkP2KKRCcD1iQwAAoELrUWRDAACgQmdmZkMAAKBCKlxlQwvXm0KjcGdDj8KZQh+FaUMVrpdCXY9qQwvXm0IVrm1DC9ebQpDCb0OPwplCCtdxQwvXm0KF63NDj8KZQgAAdkMVrpdCexR4QxWul0J7FHhDH4WTQnsUeEMpXI9CAAB2QzMzi0KF63NDMzOLQgrXcUMzM4tCkMJvQ7geiUJSuG5Dw/WEQs3McEPD9YRCCtdxQ7geiUIK13FDw/WEQoXrc0NI4YJCAAB2Qz4Kh0I9CndDMzOLQrgeeUO4HolCMzN7QzMzi0JwPXxDKVyPQutRfkMpXI9CMzOAQ6RwkUJxPYFDpHCRQq9HgkOkcJFC61GDQx+Fk0IpXIRDmpmVQmdmhUMVrpdCpHCGQ5qZlULieodDFa6XQh+FiEOPwplCXI+JQ4/CmUKamYpDFa6XQteji0MfhZNCFa6MQ6RwkULXo4tDmpmVQhWujEOamZVC16OLQ4/CmUIVroxDFa6XQjMzjUML15tCcT2OQwAAoEKPwo5DC9ebQnE9jkMVrpdCr0ePQ5qZlULrUZBDmpmVQgvXkEML15tCSOGRQ4/CmUJI4ZFDheudQgvXkEN7FKJC61GQQ3E9pkLrUZBDZ2aqQs3Mj0Ncj65Cj8KOQ1yPrkJSuI1D4nqsQjMzjUPXo7BCFa6MQ83MtEIVroxDw/W4QjMzjUO4Hr1CFa6MQ69HwUL2KIxDpHDFQrgei0OamclCmpmKQ4/CzUJ7FIpDhevRQrgei0MAANRC9iiMQ3sU1kIzM41DcT3aQnE9jkPrUdxCj8KOQ+J64ELNzI9DXY/iQgvXkEPXo+RCSOGRQ1K45kKF65JDzczoQsP1k0NI4epCAACVQ8P17EI+CpZDw/XsQnsUl0O4HvFCuB6YQ69H9UL2KJlDKlz3QjMzmkOjcPlCcT2bQ6Nw+UKvR5xDH4X7QutRnUOamf1CC9edQ0jhAEMpXJ5Dw/UCQ2dmn0PD9QJDpHCgQz4KBUPieqFDPgoFQx+FokN7FAZDXI+jQ3sUBkOamaRDPgoFQ9ejpUMAAARDFa6mQ8P1AkMVrqZDSOEAQxWupkOamf1CUrinQ6Nw+UJxPahDr0f1Qo/CqEO4HvFCr0epQ8P17EKvR6lDzczoQq9HqUPXo+RCr0epQ+J64ELNzKlD61HcQutRqkP2KNhCC9eqQwAA1ELrUapDC9fPQs3MqUMVrstCzcypQx+Fx0LrUapDKVzDQs3MqUMzM79CzcypQz4Ku0LNzKlDSOG2QutRqkNSuLJC61GqQ1yPrkLrUapDZ2aqQilcq0NxPaZCZ2asQ3sUokIpXKtDexSiQutRqkN7FKJC61GqQ4XrnUIL16pDj8KZQilcq0OamZVCZ2asQxWul0JnZqxDH4WTQmdmrEMpXI9CheusQzMzi0KF66xDPgqHQqRwrUNI4YJCheusQ6NwfULD9a1Do3B9QgAAr0O4HnVCAACvQ6NwfUI+CrBDzcyAQlyPsEPD9YRCexSxQ7geiUJcj7BDr0eNQnsUsUOkcJFCuB6yQx+Fk0K4HrJDFa6XQrgeskML15tC9iizQ4XrnUIVrrNDexSiQhWus0NxPaZCMzO0Q2dmqkIzM7RDXI+uQlK4tENSuLJCUri0Q0jhtkIzM7RDPgq7QlK4tEMzM79CcT21Qylcw0KPwrVDH4XHQs3MtkOamclCC9e3Qx+Fx0JI4bhDpHDFQoXruUOkcMVCheu5Q5qZyULD9bpDFa7LQgAAvEML189CPgq9Q4Xr0UI+Cr1D9ijYQlyPvUPrUdxCXI+9Q+J64EJ7FL5D16PkQnsUvkPNzOhCexS+Q8P17EJ7FL5DuB7xQpqZvkOvR/VC16O/Qypc90L2KMBDH4X7QjMzwUMfhftCFa7AQxWu/0IzM8FDhesBQ1K4wUMAAARDUrjBQ3sUBkNSuMFD9igIQzMzwUNxPQpDUrjBQ+tRDENxPcJDZ2YOQ4/CwkPiehBDj8LCQ1yPEkPNzMND16MUQwvXxEMVrhVDSOHFQ1K4FkOF68ZDUrgWQ8P1x0OPwhdDAADJQ4/CF0MfhclDC9cZQz4KykOF6xtDexTLQ4XrG0O4HsxDw/UcQ/cozUMAAB5DFa7NQ3sUIENSuM5DexQgQ5DCz0O4HiFDr0fQQzMzI0NwPc9D9igiQ3A9z0NxPSRDkMLPQ+tRJkPNzNBDKVwnQz4AAACamctD16O6Q9ejzEP2KLtD9yjNQzMzvEP3KM1DcT29Q/cozUOvR75D9yjNQ+tRv0P3KM1DKVzAQ/cozUNnZsFD9yjNQ6RwwkPXo8xDZ2bBQ7gezEOkcMJDmpnLQ+J6w0N7FMtDH4XEQ3sUy0Ncj8VDmpnLQ5qZxkOamctD16PHQ1yPykPXo8dDH4XJQ7gex0Ncj8pDmpnGQx+FyUN7FMZD4nrIQ5qZxkOkcMdD16PHQ2dmxkPXo8dDZ2bGQxWuyENI4cVDUrjJQwvXxENSuMlDzczDQzMzyUOPwsJDMzPJQ1K4wUMzM8lDUrjBQ/YoyEMVrsBD16PHQ9ejv0O4HsdDmpm+Q5qZxkN7FL5DXI/FQ1yPvUMfhcRDPgq9Q+J6w0M+Cr1DpHDCQ3sUvkPiesNDXI+9Q6RwwkM+Cr1DZ2bBQwAAvEMpXMBD4nq7Q+tRv0PD9bpDr0e+Q6RwukNxPb1Dheu5QzMzvEOkcLpD9ii7Q+J6u0P2KLtDH4W8Q/You0Ncj71D9ii7Q5qZvkMVrrtD16O/QxWuu0MVrsBDUri8Q1K4wUNSuLxDj8LCQ3E9vUPNzMNDUri8QwvXxENSuLxDSOHFQ3E9vUNI4cVDMzO8Q4XrxkMzM7xDw/XHQxWuu0MAAMlDFa67Q1yPykMVrrtD"}];
var __map_reserved = {}
var ArrayBuffer = typeof(window) != "undefined" && window.ArrayBuffer || typeof(global) != "undefined" && global.ArrayBuffer || js_html_compat_ArrayBuffer;
if(ArrayBuffer.prototype.slice == null) ArrayBuffer.prototype.slice = js_html_compat_ArrayBuffer.sliceImpl;
var DataView = typeof(window) != "undefined" && window.DataView || typeof(global) != "undefined" && global.DataView || js_html_compat_DataView;
var Uint8Array = typeof(window) != "undefined" && window.Uint8Array || typeof(global) != "undefined" && global.Uint8Array || js_html_compat_Uint8Array._new;
dots_Dom.addCss(".sui-icon-add,.sui-icon-collapse,.sui-icon-down,.sui-icon-expand,.sui-icon-remove,.sui-icon-up{background-repeat:no-repeat}.sui-icon-add{background-image:url(\"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2264%22%20height%3D%2264%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cpath%20d%3D%22M45%2029H35V19c0-1.657-1.343-3-3-3s-3%201.343-3%203v10H19c-1.657%200-3%201.343-3%203s1.343%203%203%203h10v10c0%201.657%201.343%203%203%203s3-1.343%203-3V35h10c1.657%200%203-1.343%203-3s-1.343-3-3-3zM32%200C14.327%200%200%2014.327%200%2032s14.327%2032%2032%2032%2032-14.327%2032-32S49.673%200%2032%200zm0%2058C17.64%2058%206%2046.36%206%2032S17.64%206%2032%206s26%2011.64%2026%2026-11.64%2026-26%2026z%22%20enable-background%3D%22new%22%2F%3E%3C%2Fsvg%3E\")}.sui-icon-collapse{background-image:url(\"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2264%22%20height%3D%2264%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cpath%20d%3D%22M52.16%2038.918l-18-18C33.612%2020.352%2032.847%2020%2032%2020h-.014c-.848%200-1.613.352-2.16.918l-18%2018%20.008.007c-.516.54-.834%201.27-.834%202.075%200%201.657%201.343%203%203%203%20.91%200%201.725-.406%202.275-1.046l15.718-15.718L47.917%2043.16c.54.52%201.274.84%202.083.84%201.657%200%203-1.343%203-3%200-.81-.32-1.542-.84-2.082z%22%20enable-background%3D%22new%22%2F%3E%3C%2Fsvg%3E\")}.sui-icon-down{background-image:url(\"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2264%22%20height%3D%2264%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cpath%20d%3D%22M53%2023c0-1.657-1.343-3-3-3-.81%200-1.542.32-2.082.84L31.992%2036.764%2016.275%2021.046C15.725%2020.406%2014.91%2020%2014%2020c-1.657%200-3%201.343-3%203%200%20.805.318%201.536.835%202.075l-.008.008%2018%2018c.547.565%201.312.917%202.16.917H32c.85%200%201.613-.352%202.16-.918l18-18c.52-.54.84-1.273.84-2.082z%22%20enable-background%3D%22new%22%2F%3E%3C%2Fsvg%3E\")}.sui-icon-expand{background-image:url(\"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2264%22%20height%3D%2264%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cpath%20d%3D%22M53%2023c0-1.657-1.343-3-3-3-.81%200-1.542.32-2.082.84L31.992%2036.764%2016.275%2021.046C15.725%2020.406%2014.91%2020%2014%2020c-1.657%200-3%201.343-3%203%200%20.805.318%201.536.835%202.075l-.008.008%2018%2018c.547.565%201.312.917%202.16.917H32c.85%200%201.613-.352%202.16-.918l18-18c.52-.54.84-1.273.84-2.082z%22%20enable-background%3D%22new%22%2F%3E%3C%2Fsvg%3E\")}.sui-icon-remove{background-image:url(\"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2264%22%20height%3D%2264%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cpath%20d%3D%22M45%2029H19c-1.657%200-3%201.343-3%203s1.343%203%203%203h26c1.657%200%203-1.343%203-3s-1.343-3-3-3zM32%200C14.327%200%200%2014.327%200%2032s14.327%2032%2032%2032%2032-14.327%2032-32S49.673%200%2032%200zm0%2058C17.64%2058%206%2046.36%206%2032S17.64%206%2032%206s26%2011.64%2026%2026-11.64%2026-26%2026z%22%20enable-background%3D%22new%22%2F%3E%3C%2Fsvg%3E\")}.sui-icon-up{background-image:url(\"data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2264%22%20height%3D%2264%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cpath%20d%3D%22M52.16%2038.918l-18-18C33.612%2020.352%2032.847%2020%2032%2020h-.014c-.848%200-1.613.352-2.16.918l-18%2018%20.008.007c-.516.54-.834%201.27-.834%202.075%200%201.657%201.343%203%203%203%20.91%200%201.725-.406%202.275-1.046l15.718-15.718L47.917%2043.16c.54.52%201.274.84%202.083.84%201.657%200%203-1.343%203-3%200-.81-.32-1.542-.84-2.082z%22%20enable-background%3D%22new%22%2F%3E%3C%2Fsvg%3E\")}.sui-grid{border-collapse:collapse;}.sui-grid *{box-sizing:border-box}.sui-grid td{border-bottom:1px solid #ddd;margin:0;padding:0}.sui-grid tr:first-child td{border-top:1px solid #ddd}.sui-grid td:first-child{border-left:1px solid #ddd}.sui-grid td:last-child{border-right:1px solid #ddd}.sui-grid td.sui-top,.sui-grid td.sui-left{background-color:#fff}.sui-grid td.sui-bottom,.sui-grid td.sui-right{background-color:#f6f6f6}.sui-bottom-left,.sui-bottom-right,.sui-top-left,.sui-top-right{position:absolute;background-color:#fff}.sui-top-right{top:0;right:0;-webkit-box-shadow:-1px 1px 6px rgba(0,0,0,0.1);-moz-box-shadow:-1px 1px 6px rgba(0,0,0,0.1);box-shadow:-1px 1px 6px rgba(0,0,0,0.1);}.sui-top-right.sui-grid tr:first-child td{border-top:none}.sui-top-right.sui-grid td:last-child{border-right:none}.sui-top-left{top:0;left:0;-webkit-box-shadow:1px 1px 6px rgba(0,0,0,0.1);-moz-box-shadow:1px 1px 6px rgba(0,0,0,0.1);box-shadow:1px 1px 6px rgba(0,0,0,0.1);}.sui-top-left.sui-grid tr:first-child td{border-top:none}.sui-top-left.sui-grid td:last-child{border-left:none}.sui-bottom-right{bottom:0;right:0;-webkit-box-shadow:-1px 1px 6px rgba(0,0,0,0.1);-moz-box-shadow:-1px 1px 6px rgba(0,0,0,0.1);box-shadow:-1px 1px 6px rgba(0,0,0,0.1);}.sui-bottom-right.sui-grid tr:first-child td{border-bottom:none}.sui-bottom-right.sui-grid td:last-child{border-right:none}.sui-bottom-left{bottom:0;left:0;-webkit-box-shadow:1px 1px 6px rgba(0,0,0,0.1);-moz-box-shadow:1px 1px 6px rgba(0,0,0,0.1);box-shadow:1px 1px 6px rgba(0,0,0,0.1);}.sui-bottom-left.sui-grid tr:first-child td{border-bottom:none}.sui-bottom-left.sui-grid td:last-child{border-left:none}.sui-fill{position:absolute;width:100%;max-height:100%;top:0;left:0}.sui-append{width:100%}.sui-control,.sui-folder{-moz-user-select:-moz-none;-khtml-user-select:none;-webkit-user-select:none;-o-user-select:none;user-select:none;font-size:11px;font-family:Helvetica,\"Nimbus Sans L\",\"Liberation Sans\",Arial,sans-serif;line-height:18px;vertical-align:middle;}.sui-control *,.sui-folder *{box-sizing:border-box;margin:0;padding:0}.sui-control button,.sui-folder button{line-height:18px;vertical-align:middle}.sui-control input,.sui-folder input{line-height:18px;vertical-align:middle;border:none;background-color:#f6f6f6;max-width:16em}.sui-control button:hover,.sui-folder button:hover{background-color:#fafafa;border:1px solid #ddd}.sui-control button:focus,.sui-folder button:focus{background-color:#fafafa;border:1px solid #aaa;outline:#eee solid 2px}.sui-control input:focus,.sui-folder input:focus{outline:#eee solid 2px;$outline-offset:-2px;background-color:#fafafa}.sui-control output,.sui-folder output{padding:0 6px;background-color:#fff;display:inline-block}.sui-control input[type=\"number\"],.sui-folder input[type=\"number\"],.sui-control input[type=\"date\"],.sui-folder input[type=\"date\"],.sui-control input[type=\"datetime-local\"],.sui-folder input[type=\"datetime-local\"],.sui-control input[type=\"time\"],.sui-folder input[type=\"time\"]{text-align:right}.sui-control input[type=\"number\"],.sui-folder input[type=\"number\"]{font-family:Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New,monospace}.sui-control input,.sui-folder input{padding:0 6px}.sui-control input[type=\"color\"],.sui-folder input[type=\"color\"],.sui-control input[type=\"checkbox\"],.sui-folder input[type=\"checkbox\"]{padding:0;margin:0}.sui-control input[type=\"range\"],.sui-folder input[type=\"range\"]{margin:0 8px;min-height:19px}.sui-control button,.sui-folder button{background-color:#eee;border:1px solid #aaa;border-radius:4px}.sui-control.sui-control-single input,.sui-folder.sui-control-single input,.sui-control.sui-control-single output,.sui-folder.sui-control-single output,.sui-control.sui-control-single button,.sui-folder.sui-control-single button,.sui-control.sui-control-single select,.sui-folder.sui-control-single select{width:100%}.sui-control.sui-control-single input[type=\"checkbox\"],.sui-folder.sui-control-single input[type=\"checkbox\"]{width:initial}.sui-control.sui-control-double input,.sui-folder.sui-control-double input,.sui-control.sui-control-double output,.sui-folder.sui-control-double output,.sui-control.sui-control-double button,.sui-folder.sui-control-double button{width:50%}.sui-control.sui-control-double .input1,.sui-folder.sui-control-double .input1{width:calc(100% - 7em);max-width:8em}.sui-control.sui-control-double .input2,.sui-folder.sui-control-double .input2{width:7em}.sui-control.sui-control-double .input1[type=\"range\"],.sui-folder.sui-control-double .input1[type=\"range\"]{width:calc(100% - 7em - 16px)}.sui-control.sui-type-bool,.sui-folder.sui-type-bool{text-align:center}.sui-control.sui-invalid,.sui-folder.sui-invalid{border-left:4px solid #d00}.sui-array{list-style:none;}.sui-array .sui-array-item{border-bottom:1px dotted #aaa;position:relative;}.sui-array .sui-array-item .sui-icon,.sui-array .sui-array-item .sui-icon-mini{opacity:.1}.sui-array .sui-array-item .sui-array-add .sui-icon,.sui-array .sui-array-item .sui-array-add .sui-icon-mini{opacity:.2}.sui-array .sui-array-item > *{vertical-align:top}.sui-array .sui-array-item:first-child > .sui-move > .sui-icon-up{visibility:hidden}.sui-array .sui-array-item:last-child{border-bottom:none;}.sui-array .sui-array-item:last-child > .sui-move > .sui-icon-down{visibility:hidden}.sui-array .sui-array-item > div{display:inline-block}.sui-array .sui-array-item .sui-move{position:absolute;width:8px;height:100%;}.sui-array .sui-array-item .sui-move .sui-icon-mini{display:block;position:absolute}.sui-array .sui-array-item .sui-move .sui-icon-up{top:0;left:1px}.sui-array .sui-array-item .sui-move .sui-icon-down{bottom:0;left:1px}.sui-array .sui-array-item .sui-control-container{margin:0 14px 0 10px;width:calc(100% - 24px)}.sui-array .sui-array-item .sui-remove{width:12px;position:absolute;right:1px;top:0}.sui-array .sui-array-item .sui-icon-remove,.sui-array .sui-array-item .sui-icon-up,.sui-array .sui-array-item .sui-icon-down{cursor:pointer}.sui-array .sui-array-item.sui-focus > .sui-move .sui-icon,.sui-array .sui-array-item.sui-focus > .sui-remove .sui-icon,.sui-array .sui-array-item.sui-focus > .sui-move .sui-icon-mini,.sui-array .sui-array-item.sui-focus > .sui-remove .sui-icon-mini{opacity:.4}.sui-array ~ .sui-control{margin-bottom:0}.sui-map{border-collapse:collapse;}.sui-map .sui-map-item > td{border-bottom:1px dotted #aaa;}.sui-map .sui-map-item > td:first-child{border-left:none}.sui-map .sui-map-item:last-child > td{border-bottom:none}.sui-map .sui-map-item .sui-icon{opacity:.1}.sui-map .sui-map-item .sui-array-add .sui-icon{opacity:.2}.sui-map .sui-map-item .sui-remove{width:14px;text-align:right;padding:0 1px}.sui-map .sui-map-item .sui-icon-remove{cursor:pointer}.sui-map .sui-map-item.sui-focus > .sui-remove .sui-icon{opacity:.4}.sui-disabled .sui-icon,.sui-disabled .sui-icon-mini,.sui-disabled .sui-icon:hover,.sui-disabled .sui-icon-mini:hover{opacity:.05 !important;cursor:default}.sui-array-add{text-align:right;}.sui-array-add .sui-icon,.sui-array-add .sui-icon-mini{margin-right:1px;opacity:.2;cursor:pointer}.sui-icon,.sui-icon-mini{display:inline-block;opacity:.4;vertical-align:middle;}.sui-icon:hover,.sui-icon-mini:hover{opacity:.8 !important}.sui-icon{width:12px;height:12px;background-size:12px 12px}.sui-icon-mini{width:8px;height:8px;background-size:8px 8px}.sui-folder{padding:0 6px;font-weight:bold}.sui-collapsible{cursor:pointer}.sui-bottom-left .sui-trigger-toggle,.sui-bottom-right .sui-trigger-toggle{transform:rotate(180deg)}.sui-choice-options > .sui-grid,.sui-grid-inner{width:100%}.sui-choice-options > .sui-grid > tr > td:first-child,.sui-choice-options > .sui-grid > tbody > tr > td:first-child{border-left:none}.sui-choice-options > .sui-grid > tr:last-child > td,.sui-choice-options > .sui-grid > tbody > tr:last-child > td{border-bottom:none}.sui-grid-inner{border-left:6px solid #f6f6f6}.sui-choice-header select{width:100%}");

      // Production steps of ECMA-262, Edition 5, 15.4.4.21
      // Reference: http://es5.github.io/#x15.4.4.21
      if (!Array.prototype.reduce) {
        Array.prototype.reduce = function(callback /*, initialValue*/) {
          'use strict';
          if (this == null) {
            throw new TypeError('Array.prototype.reduce called on null or undefined');
          }
          if (typeof callback !== 'function') {
            throw new TypeError(callback + ' is not a function');
          }
          var t = Object(this), len = t.length >>> 0, k = 0, value;
          if (arguments.length == 2) {
            value = arguments[1];
          } else {
            while (k < len && ! k in t) {
              k++;
            }
            if (k >= len) {
              throw new TypeError('Reduce of empty array with no initial value');
            }
            value = t[k++];
          }
          for (; k < len; k++) {
            if (k in t) {
              value = callback(value, t[k], k, t);
            }
          }
          return value;
        };
      }
    ;
var scope = ("undefined" !== typeof window && window) || ("undefined" !== typeof global && global) || this;
if(!scope.setImmediate) scope.setImmediate = function(callback) {
	scope.setTimeout(callback,0);
};
var lastTime = 0;
var vendors = ["webkit","moz"];
var x = 0;
while(x < vendors.length && !scope.requestAnimationFrame) {
	scope.requestAnimationFrame = scope[vendors[x] + "RequestAnimationFrame"];
	scope.cancelAnimationFrame = scope[vendors[x] + "CancelAnimationFrame"] || scope[vendors[x] + "CancelRequestAnimationFrame"];
	x++;
}
if(!scope.requestAnimationFrame) scope.requestAnimationFrame = function(callback1) {
	var currTime = new Date().getTime();
	var timeToCall = Math.max(0,16 - (currTime - lastTime));
	var id = scope.setTimeout(function() {
		callback1(currTime + timeToCall);
	},timeToCall);
	lastTime = currTime + timeToCall;
	return id;
};
if(!scope.cancelAnimationFrame) scope.cancelAnimationFrame = function(id1) {
	scope.clearTimeout(id1);
};
if(typeof(scope.performance) == "undefined") scope.performance = { };
if(typeof(scope.performance.now) == "undefined") {
	var nowOffset = new Date().getTime();
	if(scope.performance.timing && scope.performance.timing.navigationStart) nowOffset = scope.performance.timing.navigationStart;
	var now = function() {
		return new Date() - nowOffset;
	};
	scope.performance.now = now;
}
SuiDemoJS.width = 800;
SuiDemoJS.height = 500;
dots_Html.pattern = new EReg("[<]([^> ]+)","");
dots_Query.doc = document;
haxe_crypto_Base64.CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
haxe_crypto_Base64.BYTES = haxe_io_Bytes.ofString(haxe_crypto_Base64.CHARS);
haxe_ds_ObjectMap.count = 0;
haxe_io_FPHelper.i64tmp = (function($this) {
	var $r;
	var x = new haxe__$Int64__$_$_$Int64(0,0);
	$r = x;
	return $r;
}(this));
hxClipper_ClipperBase.HORIZONTAL = -3.4E+38;
hxClipper_ClipperBase.SKIP = -2;
hxClipper_ClipperBase.UNASSIGNED = -1;
hxClipper_ClipperBase.TOLERANCE = 1.0E-20;
hxClipper_ClipperBase.LO_RANGE = 32767;
hxClipper_ClipperBase.HI_RANGE = 32767;
hxClipper_ClipperOffset.TWO_PI = 6.283185307179586476925286766559;
hxClipper_ClipperOffset.DEFAULT_ARC_TOLERANCE = 0.25;
js_Boot.__toStr = {}.toString;
js_html_compat_Uint8Array.BYTES_PER_ELEMENT = 1;
sui_controls_ColorControl.PATTERN = new EReg("^[#][0-9a-f]{6}$","i");
sui_controls_DataList.nid = 0;
thx_core_Floats.TOLERANCE = 10e-5;
thx_core_Floats.EPSILON = 10e-10;
thx_core_Floats.pattern_parse = new EReg("^(\\+|-)?\\d+(\\.\\d+)?(e-?\\d+)?$","");
thx_core_Ints.pattern_parse = new EReg("^[+-]?(\\d+|0x[0-9A-F]+)$","i");
thx_core_Ints.BASE = "0123456789abcdefghijklmnopqrstuvwxyz";
thx_core_Strings.UCWORDS = new EReg("[^a-zA-Z]([a-z])","g");
thx_core_Strings.UCWORDSWS = new EReg("\\s[a-z]","g");
thx_core_Strings.ALPHANUM = new EReg("^[a-z0-9]+$","i");
thx_core_Strings.DIGITS = new EReg("^[0-9]+$","");
thx_core_Strings.STRIPTAGS = new EReg("</?[a-z]+[^>]*?/?>","gi");
thx_core_Strings.WSG = new EReg("\\s+","g");
thx_core_Strings.SPLIT_LINES = new EReg("\r\n|\n\r|\n|\r","g");
thx_core_Timer.FRAME_RATE = Math.round(16.666666666666668);
thx_promise__$Promise_Promise_$Impl_$.nil = thx_promise__$Promise_Promise_$Impl_$.value(thx_core_Nil.nil);
SuiDemoJS.main();
})(typeof console != "undefined" ? console : {log:function(){}});

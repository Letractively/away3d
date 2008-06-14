﻿package away3d.extrusions{		import away3d.core.math.Number3D;	import away3d.core.base.*;	import away3d.core.arcane;	import away3d.materials.*;	import away3d.core.utils.Init;	import away3d.core.math.Matrix3D;	import away3d.animators.data.Path;	import away3d.animators.data.CurveSegment; 	public class PathExtrude extends Mesh{				use namespace arcane;				private var varr:Array;		private var xAxis:Number3D = new Number3D();    	private var yAxis:Number3D = new Number3D();    	private var zAxis:Number3D = new Number3D();		private var _worldAxis:Number3D = new Number3D(0,1,0);		private var _transform:Matrix3D = new Matrix3D();				private var _path:Path;		private var _points:Array;		private var _scales:Array;		private var _subdivision:int = 2;		private var _scaling:Number =  1;		private var _coverall:Boolean = true;		private var _recenter:Boolean = false;		private var _flip:Boolean = false;		private var _closepath:Boolean = false;		private var _aligntopath:Boolean = true;		private var _smoothscale:Boolean = true;		 		        private function orientateAt(target:Number3D, position:Number3D):void        {            zAxis.sub(target, position);            zAxis.normalize();                if (zAxis.modulo > 0.1)            {                xAxis.cross(zAxis, _worldAxis);                xAxis.normalize();                    yAxis.cross(zAxis, xAxis);                yAxis.normalize();                    _transform.sxx = xAxis.x;                _transform.syx = xAxis.y;                _transform.szx = xAxis.z;                    _transform.sxy = -yAxis.x;                _transform.syy = -yAxis.y;                _transform.szy = -yAxis.z;                    _transform.sxz = zAxis.x;                _transform.syz = zAxis.y;                _transform.szz = zAxis.z;				            }        }				private function tweenScales( startVal:Number3D, endVal:Number3D, duration:int):Array {			var aTween:Array = [];			var step:int = 1;			 			var stepx:Number = (endVal.x-startVal.x) / duration;			var stepy:Number = (endVal.y-startVal.y) / duration;			var stepz:Number = (endVal.z-startVal.z) / duration;						var scalestep:Number3D;			while (step < duration) { 				scalestep = new Number3D();				scalestep.x = startVal.x+(stepx*step);				scalestep.y = startVal.y+(stepy*step);				scalestep.z = startVal.z+(stepz*step);								aTween.push(scalestep);								step ++;			}						aTween.push(endVal);			return aTween;		}				private function generate(points:Array, subdivision:int = 1, coverall:Boolean = false, closepath:Boolean = false, flip:Boolean = false):void		{				var uvlength = points.length-1;			for(var i:int = 0;i< points.length-1;i++){				varr = new Array();				extrudePoints( points[i], points[i+1], subdivision, coverall, (1/uvlength)*i, uvlength, flip);			}					}				private function extrudePoints(points1:Array, points2:Array, subdivision:int, coverall:Boolean, vscale:Number, indexv:int, flip:Boolean):void		{						var i:int;			var j:int;			var stepx:Number;			var stepy:Number;			var stepz:Number;						var uva:UV;			var uvb:UV;			var uvc:UV;			var uvd:UV;						var va:Vertex;			var vb:Vertex;			var vc:Vertex;			var vd:Vertex;						var u1:Number;			var u2:Number;			var index:int = 0;			var bu:Number = 0;			var bincu = 1/(points1.length-1);			var v1:Number = 0;			var v2:Number = 0;			 			for( i = 0; i < points1.length; i++){				stepx = (points2[i].x - points1[i].x) / subdivision;				stepy = (points2[i].y - points1[i].y) / subdivision;				stepz = (points2[i].z - points1[i].z)  / subdivision;								for( j = 0; j < subdivision+1; j++){					varr.push( new Vertex( points1[i].x+(stepx*j) , points1[i].y+(stepy*j), points1[i].z+(stepz*j)) );				}			}						for( i = 0; i < points1.length-1; i++){								u1 = bu;				bu += bincu;				u2 = bu;								for( j = 0; j < subdivision; j++){										v1 = (coverall)? vscale+((j/subdivision)/indexv) :  j/subdivision;					v2 = (coverall)? vscale+(( (j+1)/subdivision)/indexv) :  (j+1)/subdivision;										uva = new UV( u1 , v1);					uvb = new UV( u1 , v2 );					uvc = new UV( u2 , v2 );					uvd = new UV( u2 , v1 );											va = varr[index+j];					vb = varr[(index+j) + 1];					vc = varr[((index+j) + (subdivision + 2))];					vd = varr[((index+j) + (subdivision + 1))];					 					if(flip){												addFace(new Face(vb,va,vc, null, uvb, uva, uvc ));						addFace(new Face(vc,va,vd, null, uvc, uva, uvd));					}else{												addFace(new Face(va,vb,vc, null, uva, uvb, uvc ));						addFace(new Face(va,vc,vd, null, uva, uvc, uvd));					}				}								index += subdivision +1;			}					}				private function getPointsOnCurve(_path:Path, subdivision:int):Array 		{				var aSegPoints = [ getSegmentPoints(_path.array[0].v0, _path.array[0].va, _path.array[0].v1, subdivision)];						for (var i:int = 1; i < _path.length; i++)				aSegPoints.push(getSegmentPoints(_path.array[i-1].v1, _path.array[i].va, _path.array[i].v1, subdivision));							return aSegPoints;		}				private function getSegmentPoints(v0:Number3D, va:Number3D, v1:Number3D, n:Number):Array		{			var aPts:Array = [];			v0.x = (v0.x == 0)? 0.00001 : v0.x;			v0.y = (v0.y == 0)? 0.00001 : v0.y;			v0.z = (v0.y == 0)? 0.00001 : v0.z;			va.x = (va.x == 0)? 0.00001 : va.x;			va.y = (va.y == 0)? 0.00001 : va.y;			va.z = (va.z == 0)? 0.00001 : va.z;			v1.x = (v1.x == 0)? 0.00001 : v1.x;			v1.y = (v1.y == 0)? 0.00001 : v1.y;			v1.z = (v1.z == 0)? 0.00001 : v1.z;						for (var i:int = 0; i < n; i++) {				aPts.push(getNewPoint(v0.x, v0.y, v0.z, va.x, va.y, va.z, v1.x, v1.y, v1.z, i / n));			}			return aPts;		}				private function getNewPoint(x0:Number = 0, y0:Number = 0, z0:Number=0, aX:Number = 0, aY:Number = 0, aZ:Number=0, x1:Number = 0, y1:Number = 0, z1:Number=0, t:Number = 0):Number3D 		{			return new Number3D(x0 + t * (2 * (1 - t) * (aX - x0) + t * (x1 - x0)), y0 + t * (2 * (1 - t) * (aY - y0) + t * (y1 - y0)), z0 + t * (2 * (1 - t) * (aZ - z0) + t * (z1 - z0)));		}				/**		 * Creates a new <PathExtrude>PathExtrude</code>		 * 		 * @param	 	path			A Path object. The _path definition.		 * @param	 	points		An array containing a series of Number3D's. Defines the profile to extrude on the _path definition.		 * @param 	init			[optional]	An initialisation object for specifying default instance properties.		 * @param 	scales		[optional]	An array containing a series of Number3D [Number3D(1,1,1)]. Defines the scale per segment. Init object smoothscale true smooth the scale across the segments, set to false the scale is applied equally to the whole segment, default is true. 		 * 		 */		 		function PathExtrude(path:Path=null, points:Array=null, scales:Array=null, init:Object = null)		{				_path = path;				_points = points;				_scales = scales;								init = Init.parse(init);				super(init);					_subdivision = init.getInt("subdivision", 2, {min:2});				_scaling = init.getNumber("scaling", 1);				_coverall = init.getBoolean("coverall", true);				_recenter = init.getBoolean("recenter", false);				_flip = init.getBoolean("flip", false);				_closepath = init.getBoolean("closepath", false);				_aligntopath = init.getBoolean("aligntopath", true);				_smoothscale = init.getBoolean("smoothscale", true);								if(_path != null && _points!= null) build();		}				public function build():void		{			if(_path.length != 0 && _points.length >=2){								_worldAxis = _path.worldAxis;				if(_closepath){					 var ref:CurveSegment = _path.array[_path.array.length-1];					 var va:Number3D = new Number3D(  (_path.array[0].va.x+ref.va.x)*.5,  (_path.array[0].va.y+ref.va.y)*.5, (_path.array[0].va.z+ref.va.z)*.5   );					_path.add( new CurveSegment( _path.array[0].v1, va, _path.array[0].v0 )   );				}								var aSegPoints:Array = getPointsOnCurve(_path, _subdivision);				 				var aPointlist:Array = [];				var aSegresult:Array = [];				var atmp:Array;				var tmppt:Number3D = new Number3D(0,0,0);				 				var i:int;				var j:int;				var k:int;								var nextpt:Number3D;								var lastscale:Number3D = new Number3D(1, 1, 1);				var rescale:Boolean = (_scales != null);								if(_smoothscale && rescale)					var nextscale:Number3D = new Number3D(1, 1, 1);					var aTs:Array = [];				 				for (i = 0; i <aSegPoints.length; i++) {										if(rescale)						lastscale = (_scales[i] == null) ? lastscale : _scales[i];											if(_smoothscale && rescale &&  i <aSegPoints.length){						nextscale = (_scales[i+1] == null) ? lastscale : _scales[i+1];						aTs = aTs.concat(tweenScales( lastscale, nextscale, _subdivision));					}										for(j = 0; j<aSegPoints[i].length;j++){						atmp = [];						atmp = atmp.concat(_points);						aPointlist = [];												if(_aligntopath) {							_transform = new Matrix3D();							if(i == aSegPoints.length -1 && j==aSegPoints[i].length-1){																if(_closepath){									nextpt = aSegPoints[0][0];									orientateAt(nextpt, aSegPoints[i][j]);								} else{									nextpt = aSegPoints[i][j-1];									orientateAt(aSegPoints[i][j], nextpt);								}															} else {								nextpt = (j<aSegPoints[i].length-1)? aSegPoints[i][j+1]:  aSegPoints[i+1][0];								orientateAt(nextpt, aSegPoints[i][j]);							}													}												for (k = 0; k <atmp.length; k++) {														if(_aligntopath) {								tmppt = new Number3D();								tmppt.x = atmp[k].x * _transform.sxx + atmp[k].y * _transform.sxy + atmp[k].z * _transform.sxz + _transform.tx;								tmppt.y = atmp[k].x * _transform.syx + atmp[k].y * _transform.syy + atmp[k].z * _transform.syz + _transform.ty;								tmppt.z = atmp[k].x * _transform.szx + atmp[k].y * _transform.szy + atmp[k].z * _transform.szz + _transform.tz;														tmppt.x +=  aSegPoints[i][j].x;								tmppt.y +=  aSegPoints[i][j].y;								tmppt.z +=  aSegPoints[i][j].z;								 								aPointlist.push(tmppt);															} else {																tmppt = new Number3D(atmp[k].x+aSegPoints[i][j].x, atmp[k].y+aSegPoints[i][j].y, atmp[k].z+aSegPoints[i][j].z);								aPointlist.push(tmppt );							}														if(rescale && !_smoothscale){									tmppt.x *= lastscale.x;									tmppt.y *= lastscale.y;									tmppt.z *= lastscale.z;							}						}												if (_scaling != 1) {								for (k = 0; k < aPointlist.length; k++) {									aPointlist[k].x *= _scaling;									aPointlist[k].y *= _scaling;									aPointlist[k].z *= _scaling;								}						}												aSegresult.push(aPointlist);					}									}				 				if(rescale && _smoothscale){					 					for (i = 0; i < aTs.length; i++) {												 for (j = 0;j < aSegresult[i].length; j++) {							aSegresult[i][j].x *= aTs[i].x;							aSegresult[i][j].y *= aTs[i].y;							aSegresult[i][j].z *= aTs[i].z;						 }						 					}										aTs = null;				}				 				generate(aSegresult, 1, _coverall, _closepath, _flip);								if(_recenter) {					movePivot( (this.minX+this.maxX)*.5,  (this.minY+this.maxY)*.5, (this.minZ+this.maxZ)*.5);				} else {					x =  _path.array[0].v1.x;					y =  _path.array[0].v1.y;					z =  _path.array[0].v1.z;				}				 				type = "PathExtrude";				url = "Extrude";						} else {				trace("PathExtrude error: at least 2 Number3D are required in points. Path definition requires at least 1 object with 3 parameters: {v0:Number3D, va:Number3D ,v1:Number3D}, all properties being Number3D.");			} 		}		 		/**    	 * Defines the resolution beetween each CurveSegments. Default 2, minimum 2.    	 */ 		public function set subdivision(val:int):void		{			_subdivision = (val<2)? 2 :val;		}		/**    	 * Defines the scaling of the final generated mesh. Not being considered while building the mesh. Default 1.    	 */		public function set scaling(val:Number):void		{			_scaling = val;		}		/**    	 * Defines if the texture should cover entire mesh or per segments. Default true.    	 */		public function set coverall(b:Boolean):void		{			_coverall = b;		}		/**    	 * Defines if the final mesh should have its pivot reset to its center after generation. Default false.    	 */		public function set recenter(b:Boolean):void		{			_recenter = b;		}		/**    	 * Defines if the generated faces should be inversed. Default false.    	 */		public function set flip(b:Boolean):void		{			_flip = b;		}		/**    	 * Defines if the last segment should join the first one and close the loop. Default false.    	 */		public function set closepath(b:Boolean):void		{			_closepath = b;		}		/**    	 * Defines if the profile point array should be orientated on path or not. Default true. Note that Path object worldaxis property might need to be changed. default = 0,1,0.    	 */		public function set aligntopath(b:Boolean):void		{			_aligntopath = b;		}		/**    	 * Defines if a scale array of number3d is passed if the scaling should be affecting the whole segment or spreaded from previous curvesegmentscale to the next curvesegmentscale. Default true.    	 */		public function set smoothscale(b:Boolean):void		{			_smoothscale = b;		}		 /**    	 * Sets and defines the Path object. See animators.data package. Required.    	 */ 		 public function set path(p:Path):void    	{    		_path = p;    	}		 public function get path():Path    	{    		return _path;    	}		 		/**    	 * Sets and defines the Array of Number3D's (the profile information to be projected according to the Path object). Required.    	 */		 public function set points(aR:Array):void    	{    		_points = aR;    	}		 public function get points():Array    	{    		return _points;    	}		 		/**    	 * Sets and defines the optional Array of Number3D's. A series of scales to be set on each CurveSegments    	 */		 		 public function set scales(aR:Array):void    	{    		_scales = aR;    	}		 public function get scales():Array    	{    		return _scales;    	}		 	}}
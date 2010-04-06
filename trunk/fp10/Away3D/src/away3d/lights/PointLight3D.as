﻿package away3d.lights{	import away3d.arcane;	import away3d.containers.*;	import away3d.core.base.*;	import away3d.core.light.*;	import away3d.core.math.*;	import away3d.core.utils.*;	import away3d.events.*;	import away3d.geom.Merge;	import away3d.materials.ColorMaterial;	import away3d.primitives.Sphere;    		use namespace arcane;	    /**    * Lightsource that colors all shaded materials proportional to the dot product of the distance vector with the normal vector.    * The scalar value of the distance is used to calulate intensity using the inverse square law of attenuation.    */    public class PointLight3D extends AbstractLight    {    	/** @private */		arcane var _vertex:Vertex = new Vertex();		    	private var _position:Number3D = new Number3D();        private var _radius:Number = 200;    	private var _scenePosition:Number3D = new Number3D();    	private var _scenePositionDirty:Boolean;    			private var _ls:PointLight = new PointLight();        private var _debugPrimitive:Sphere;        private var _debugMaterial:ColorMaterial;				private function onParentChange(event:Object3DEvent):void        {			_scenePositionDirty = true;        }            	/** @private */		protected override function updateParent(val:ObjectContainer3D):void		{			if (_parent != null) {                _parent.removeOnSceneChange(onParentChange);                _parent.removeOnSceneTransformChange(onParentChange);            }			            _parent = val;			            if (_parent != null) {                _parent.addOnSceneChange(onParentChange);                _parent.addOnSceneTransformChange(onParentChange);                                _scenePositionDirty = true;            }		}				/**		 * Defines a coefficient for the ambient light intensity.		 */        public var ambient:Number;				/**		 * Defines a coefficient for the diffuse light intensity.		 */        public var diffuse:Number;				/**		 * Defines a coefficient for the specular light intensity.		 */        public var specular:Number;				/**		 * Defines a coefficient for the overall light intensity.		 */        public var brightness:Number;		            	/**    	 * Defines the x coordinate of the light relative to the local coordinates of the parent <code>ObjectContainer3D</code>.    	 */        public function get x():Number        {            return _vertex.x;        }            public function set x(value:Number):void        {            if (isNaN(value))                throw new Error("isNaN(x)");						if (_vertex.x == value)				return;			            if (value == Infinity)                Debug.warning("x == Infinity");            if (value == -Infinity)                Debug.warning("x == -Infinity");            _vertex.x = _position.x = value;                        _scenePositionDirty = true;        }		    	/**    	 * Defines the y coordinate of the light relative to the local coordinates of the parent <code>ObjectContainer3D</code>.    	 */        public function get y():Number        {            return _vertex.y;        }            public function set y(value:Number):void        {            if (isNaN(value))                throw new Error("isNaN(y)");						if (_vertex.y == value)				return;			            if (value == Infinity)                Debug.warning("y == Infinity");            if (value == -Infinity)                Debug.warning("y == -Infinity");            _vertex.y = _position.y = value;                        _scenePositionDirty = true;        }		    	/**    	 * Defines the z coordinate of the light relative to the local coordinates of the parent <code>ObjectContainer3D</code>.    	 */        public function get z():Number        {            return _vertex.z;        }    	        public function set z(value:Number):void        {            if (isNaN(value))                throw new Error("isNaN(z)");						if (_vertex.z == value)				return;			            if (value == Infinity)                Debug.warning("z == Infinity");            if (value == -Infinity)                Debug.warning("z == -Infinity");            _vertex.z = _position.z = value;                        _scenePositionDirty = true;        }                    	/**    	 * Defines the position of the light relative to the local coordinates of the parent <code>ObjectContainer3D</code>.    	 */        public function get position():Number3D        {            return _position;        }		        public function set position(value:Number3D):void        {            _vertex.x = _position.x = value.x;            _vertex.y = _position.y = value.y;            _vertex.z = _position.z = value.z;            			_scenePositionDirty = true;        }		        		/**		 * Defines the radius of the light at full intensity, infleunced object get within this range full color of the light		 */		public function get radius():Number        {        	return _radius;        }                public function set radius(val:Number):void        {        	_radius = val;			_falloff = (radius>_falloff)? radius+1 : _falloff;			_debugPrimitive = null;        }				/**		 * Defines the max length of the light rays, beyond this distance, light doesn't have influence		 * the light values are from radius 100% to falloff 0%		 */        private var _falloff:Number = 1000;		        public function get fallOff():Number        {        	return _falloff;        }                public function set fallOff(val:Number):void        {        	_falloff = (radius>_falloff)? radius+1 : val;			_debugPrimitive = null;			//_scene.clearId(_id);        }        		public function get debugPrimitive():Object3D		{			if (!_debugPrimitive){				_debugPrimitive = new Sphere({radius:radius});				 				if(!_debugMaterial){					_debugMaterial = new ColorMaterial();					_debugMaterial.alpha = .15;				}								_debugPrimitive.material = _debugMaterial;				_debugMaterial.color = color;				  				var m:Merge = new Merge(true, false, true);				var spherefalloff:Sphere = new Sphere({segmentsW:10, segmentsH:8,material:_debugMaterial, radius:_falloff});				m.apply(_debugPrimitive, spherefalloff);								//_scene.setId(_debugPrimitive);			}            			return _debugPrimitive;		}				public function get scenePosition():Number3D		{			if (_scenePositionDirty) {				_scenePositionDirty = false;								_scenePosition.add(_parent.scenePosition, _position);								_ls.setPosition(_scenePosition);			}						return _scenePosition;		}				/**		 * Creates a new <code>PointLight3D</code> object.		 * 		 * @param	init	[optional]	An initialisation object for specifying default instance properties.		 */        public function PointLight3D(init:Object = null)        {            super(init);                        x = ini.getNumber("x", 0);            y = ini.getNumber("y", 0);            z = ini.getNumber("z", 0);            ambient = ini.getNumber("ambient", 1);            diffuse = ini.getNumber("diffuse", 1);            specular = ini.getNumber("specular", 1);            brightness = ini.getNumber("brightness", 1);            			_radius = ini.getNumber("radius", 50);			_falloff = ini.getNumber("fallOff", 1000);			             _ls.light = this;        }        		/**		 * @inheritDoc		 */        public override function light(consumer:ILightConsumer):void        {        	if (_scenePositionDirty) {				_scenePositionDirty = false;								_scenePosition.add(_parent.scenePosition, _position);								_ls.setPosition(_scenePosition);			}						_ls.red = _red;            _ls.green = _green;            _ls.blue  = _blue;                        //multiple by 250000 with shadingcolormaterial to maintain a consistent intensity with other lights at a distance of 500 units            _ls.ambient = ambient*brightness;            _ls.diffuse = diffuse*brightness;            _ls.specular = specular*brightness;			 			_ls.radius = _radius;            _ls.fallOff = _falloff;			             consumer.pointLight(_ls);        }				/**		 * Duplicates the light object's properties to another <code>PointLight3D</code> object		 * 		 * @param	light	[optional]	The new light instance into which all properties are copied		 * @return						The new light instance with duplicated properties applied		 */        public override function clone(light:AbstractLight = null):AbstractLight        {            var pointLight3D:PointLight3D = (light as PointLight3D) || new PointLight3D();            super.clone(pointLight3D);            pointLight3D.ambient = ambient;            pointLight3D.diffuse = diffuse;            pointLight3D.specular = specular;			  			pointLight3D.radius = _radius;            pointLight3D.fallOff = _falloff;			             return pointLight3D;        }    }}
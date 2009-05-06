﻿package away3d.loaders{    import away3d.arcane;    import away3d.containers.*;    import away3d.core.base.*;    import away3d.core.utils.*;    import away3d.events.*;    import away3d.loaders.data.*;    import away3d.loaders.utils.*;        import flash.display.*;    import flash.events.*;    import flash.net.*;    import flash.utils.getTimer;    			    use namespace arcane;    	 /**	 * Dispatched when the 3d object loader completes a file load successfully.	 * 	 * @eventType away3d.events.LoaderEvent	 */	[Event(name="loadSuccess",type="away3d.events.LoaderEvent")]    				 /**	 * Dispatched when the 3d object loader fails to load a file.	 * 	 * @eventType away3d.events.LoaderEvent	 */	[Event(name="loadError",type="away3d.events.LoaderEvent")]		/**	 * Abstract loader class used as a placeholder for loading 3d content	 */    public class Object3DLoader extends ObjectContainer3D    {		/** @private */        arcane static function loadGeometry(url:String, Parser:Class, binary:Boolean, init:Object):Object3DLoader        {            var ini:Init = Init.parse(init);            var loaderClass:Class = ini.getObject("loader") as Class || CubeLoader;            var loader:Object3DLoader = new loaderClass(ini);                        loader.startLoadingGeometry(url, Parser, binary);                        return loader;        }		/** @private */        arcane static function parseGeometry(data:*, Parser:Class, init:Object):Object3DLoader        {            var ini:Init = Init.parse(init);            var loaderClass:Class = ini.getObject("loader") as Class || CubeLoader;            var loader:Object3DLoader = new loaderClass(ini);                        loader.startParsingGeometry(data, Parser);                        return loader;        }                private var _broadcaster:Sprite = new Sprite();        private var Parser:Class;        public var parser:AbstractParser;        private var _parseStart:int;                private var _parseTime:int;        private var _object:Object3D;        private var _result:Object3D;        private var _urlloader:URLLoader;        private var _loadQueue:TextureLoadQueue;        private var _loadsuccess:LoaderEvent;        private var _loaderror:LoaderEvent;		        private function registerURL(object:Object3D):void        {        	if (object is ObjectContainer3D) {        		for each (var _child:Object3D in (object as ObjectContainer3D).children)        			registerURL(_child);        	} else if (object is Mesh) {        		(object as Mesh).url = url;        	}        }                private function startLoadingGeometry(url:String, Parser:Class, binary:Boolean):void        {        	mode = LOADING_GEOMETRY;        	            this.Parser = Parser;            this.url = url;            _urlloader = new URLLoader();            _urlloader.dataFormat = binary ? URLLoaderDataFormat.BINARY : URLLoaderDataFormat.TEXT;            _urlloader.addEventListener(IOErrorEvent.IO_ERROR, onGeometryError);            _urlloader.addEventListener(ProgressEvent.PROGRESS, onGeometryProgress);            _urlloader.addEventListener(Event.COMPLETE, onGeometryComplete);            _urlloader.load(new URLRequest(url));        	        }                private function startParsingGeometry(data:*, Parser:Class):void        {        	_broadcaster.addEventListener(Event.ENTER_FRAME, update);        	mode = PARSING_GEOMETRY;        	        	_parseStart = getTimer();        	this.Parser = Parser;        	this.parser = new Parser(data, ini);        	parser.addEventListener(ParserEvent.PARSE_SUCCESS, onParserComplete, false, 0, true);        	parser.addEventListener(ParserEvent.PARSE_ERROR, onParserError, false, 0, true);        	parser.addEventListener(ParserEvent.PARSE_PROGRESS, onParserProgress, false, 0, true);        	parser.parseNext();        }                private function startLoadingTextures():void        {        	mode = LOADING_TEXTURES;        	        	_loadQueue = new TextureLoadQueue();			for each (var _materialData:MaterialData in materialLibrary)			{				if (_materialData.materialType == MaterialData.TEXTURE_MATERIAL && !_materialData.material)				{					var req:URLRequest = new URLRequest(materialLibrary.texturePath + _materialData.textureFileName);					var loader:TextureLoader = new TextureLoader();										_loadQueue.addItem(loader, req);				}			}			_loadQueue.addEventListener(IOErrorEvent.IO_ERROR, onTextureError);			_loadQueue.addEventListener(ProgressEvent.PROGRESS, onTextureProgress);			_loadQueue.addEventListener(Event.COMPLETE, onTextureComplete);			_loadQueue.start();        }                private function update(event:Event):void        {        	parser.parseNext();        }                protected function notifySuccess(event:Event):void        {        	mode = COMPLETE;        	            ini.addForCheck();						_result = _object;			            _result.transform.multiply(_result.transform, transform);			_result.name = name;            _result.ownCanvas = ownCanvas;            _result.filters = filters;            _result.visible = visible;            _result.mouseEnabled = mouseEnabled;            _result.useHandCursor = useHandCursor;            _result.alpha = alpha;            _result.pushback = pushback;            _result.pushfront = pushfront;            _result.pivotPoint = pivotPoint;            _result.extra = (extra is IClonable) ? (extra as IClonable).clone() : extra;			            if (parent != null) {                _result.parent = parent;                parent = null;            }						//register url with hierarchy			registerURL(_result);						//dispatch event			if (!_loadsuccess)				_loadsuccess = new LoaderEvent(LoaderEvent.LOAD_SUCCESS, this);							dispatchEvent(_loadsuccess);        }                protected function notifyError(event:Event):void        {        	mode = ERROR;        				//dispatch event			if (!_loaderror)				_loaderror = new LoaderEvent(LoaderEvent.LOAD_ERROR, this);						dispatchEvent(_loaderror);        }                protected function notifyProgress(event:Event):void        {        }                /**        * Automatically fired on an geometry error event.        *         * @see away3d.loaders.utils.TextureLoadQueue        */        protected function onGeometryError(event:IOErrorEvent):void         {        	notifyError(event);        }                /**        * Automatically fired on a geometry progress event        */        protected function onGeometryProgress(event:ProgressEvent):void         {        	notifyProgress(event);        	dispatchEvent(event);        }                /**        * Automatically fired on a geometry complete event        */        protected function onGeometryComplete(event:Event):void         {        	startParsingGeometry(_urlloader.data, Parser);        }                /**        * Automatically fired on an parser error event.        *         * @see away3d.loaders.utils.TextureLoadQueue        */        protected function onParserError(event:ParserEvent):void         {        	_broadcaster.removeEventListener(Event.ENTER_FRAME, update);        	notifyError(event);        }                /**        * Automatically fired on a parser progress event        */        protected function onParserProgress(event:ParserEvent):void         {        	notifyProgress(event);        	        	_parseTime = getTimer() - _parseStart;        	        	if (_parseTime < parseTimeout) {        		parser.parseNext();        	}else {        		dispatchEvent(event);        		_parseStart = getTimer();        	}        }                /**        * Automatically fired on a parser complete event        */        protected function onParserComplete(event:ParserEvent):void         {        	_broadcaster.removeEventListener(Event.ENTER_FRAME, update);        	_object = event.result;        	materialLibrary = _object.materialLibrary;        	if (materialLibrary && materialLibrary.autoLoadTextures && materialLibrary.loadRequired) {	        	texturePath = materialLibrary.texturePath;	        	startLoadingTextures();	        } else {	        	notifySuccess(event);	        }        }                /**        * Automatically fired on an texture error event.        *         * @see away3d.loaders.utils.TextureLoadQueue        */        protected function onTextureError(event:IOErrorEvent):void         {        	notifyError(event);        }                /**        * Automatically fired on a texture progress event        */        protected function onTextureProgress(event:ProgressEvent):void         {        	notifyProgress(event);        	dispatchEvent(event);        }                /**        * Automatically fired on a texture complete event        */        protected function onTextureComplete(event:Event):void         {        	materialLibrary.texturesLoaded(_loadQueue);			            notifySuccess(event);        }                /**        * Constant value string representing the geometry loading mode of the 3d object loader.        */		public const LOADING_GEOMETRY:String = "loading_geometry";                /**        * Constant value string representing the geometry parsing mode of the 3d object loader.        */		public const PARSING_GEOMETRY:String = "parsing_geometry";		        /**        * Constant value string representing the texture loading mode of the 3d object loader.        */		public const LOADING_TEXTURES:String = "loading_textures";		        /**        * Constant value string representing a completed loader mode.        */		public const COMPLETE:String = "complete";		        /**        * Constant value string representing a problem loader mode.        */		public const ERROR:String = "error";		        /**        * Returns the current loading mode of the 3d object loader.        */		public var mode:String;                /**        * Returns the the data container being used by the loaded file.        */        public var containerData:ContainerData;                /**        * Returns the filepath to the directory where any required texture files are located.        */        public var texturePath:String;                /**        * Returns the url string of the file being loaded.        */        public var url:String;				/**		 * Defines a timeout period for file parsing (in milliseconds).		 */		public var parseTimeout:int;				/**		 * Returns a 3d object relating to the currently visible model.		 * While a file is being loaded, this takes the form of the 3d object loader placeholder.		 * The default placeholder is <code>CubeLoader</code>		 * 		 * Once the file has been loaded and is ready to view, the <code>handle</code> returns the 		 * parsed 3d object file and the placeholder object is swapped in the scenegraph tree.		 * 		 * @see	away3d.loaders.CubeLoader		 */        public function get handle():Object3D        {            return _result || this;        }        		/**		 * Creates a new <code>Object3DLoader</code> object.		 * Not intended for direct use, use the static <code>parse</code> or <code>load</code> methods found on the file loader classes.		 * 		 * @param	init	[optional]	An initialisation object for specifying default instance properties.		 */        public function Object3DLoader(init:Object = null)         {        	super(init);        	            parseTimeout = ini.getNumber("parseTimeout", 40000);            ini.removeFromCheck();        }				/**		 * Default method for adding a loadsuccess event listener		 * 		 * @param	listener		The listener function		 */        public function addOnSuccess(listener:Function):void        {            addEventListener(LoaderEvent.LOAD_SUCCESS, listener, false, 0, true);        }				/**		 * Default method for removing a loadsuccess event listener		 * 		 * @param	listener		The listener function		 */        public function removeOnSuccess(listener:Function):void        {            removeEventListener(LoaderEvent.LOAD_SUCCESS, listener, false);        }				/**		 * Default method for adding a loaderror event listener		 * 		 * @param	listener		The listener function		 */        public function addOnError(listener:Function):void        {            addEventListener(LoaderEvent.LOAD_ERROR, listener, false, 0, true);        }				/**		 * Default method for removing a loaderror event listener		 * 		 * @param	listener		The listener function		 */        public function removeOnError(listener:Function):void        {            removeEventListener(LoaderEvent.LOAD_ERROR, listener, false);        }    }}
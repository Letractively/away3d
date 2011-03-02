﻿package away3d.loading.parsers{	import away3d.arcane;	import away3d.errors.AbstractMethodError;	import away3d.events.LoaderEvent;	import away3d.loading.IResource;	import away3d.loading.ResourceDependency;	import away3d.loading.parsers.data.DefaultBitmapData;	import flash.events.EventDispatcher;	import flash.events.TimerEvent;	import flash.utils.ByteArray;	import flash.utils.getTimer;	import flash.utils.Timer;	import flash.display.BitmapData;		use namespace arcane;	/**	 * <code>ParserBase</code> provides an abstract base class for objects that convert blocks of data to data structures	 * supported by Away3D.	 *	 * If used by <code>AssetLoader</code> to automatically determine the parser type, two static public methods should	 * be implemented, with the following signatures:	 *	 * <code>public static function supportsType(extension : String) : Boolean</code>	 * Indicates whether or not a given file extension is supported by the parser.	 *	 * <code>public static function supportsData(data : *) : Boolean</code>	 * Tests whether a data block can be parsed by the parser.	 *	 * Furthermore, for any concrete subtype, the method <code>initHandle</code> should be overridden to immediately	 * create the object that will contain the parsed data. This allows <code>ResourceManager</code> to return an object	 * handle regardless of whether the object was loaded or not.	 *	 * @see away3d.loading.parsers.AssetLoader	 * @see away3d.loading.ResourceManager	 */	public class ParserBase extends EventDispatcher	{		protected var _dataFormat : String;		protected var _byteData : ByteArray;		protected var _textData : String;		protected var _frameLimit : Number;		protected var _lastFrameTime : Number;				private var _parsingFailure:Boolean;		private var _timer : Timer;		private var _uri : String;		private var _baseUri : String;		private var _eventVerbosity : int;		private var _handle : IResource;		/**		 * Returned by <code>proceedParsing</code> to indicate no more parsing is needed.		 */		protected static const PARSING_DONE : Boolean = true;		/**		 * Returned by <code>proceedParsing</code> to indicate more parsing is needed, allowing asynchronous parsing.		 */		protected static const MORE_TO_PARSE : Boolean = false;				/**		 * A list of dependencies that need to be loaded and resolved for the object being parsed.		 *		 * @see away3d.loading.ResourceDependency		 */		protected var _dependencies : Vector.<ResourceDependency>;		/**		 * Creates a new ParserBase object		 * @param uri The url or id of the data or file to be parsed.		 * @param format The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>, and should be provided by the concrete subtype.		 *		 * @see away3d.loading.parsers.ParserDataFormat		 */		public function ParserBase(uri : String, format : String)		{			_uri = uri;			resolveUri();			_dataFormat = format;			_dependencies = new Vector.<ResourceDependency>();			_handle = initHandle();		}				/**		 * The url or id of the data or file to be parsed.		 */		public function get defaultBitmapData() : BitmapData		{			return DefaultBitmapData.bitmapData;		}						public function set parsingFailure(b:Boolean) : void		{			_parsingFailure = b;		}		public function get parsingFailure() : Boolean		{			return _parsingFailure;		}				/**		 * The url or id of the data or file to be parsed.		 */		public function get uri() : String		{			return _uri;		}				/**		 * The parent url of the file to be parsed.		 */		public function get baseUri() : String		{			return _baseUri;		}		/**		 * The threshold that define which events are dispatched.		 */		public function get eventVerbosity() : int		{			return _eventVerbosity;		}		public function set eventVerbosity(val : int) : void		{			_eventVerbosity = val;		}		/**		 * The data format of the file data to be parsed. Can be either <code>ParserDataFormat.BINARY</code> or <code>ParserDataFormat.PLAIN_TEXT</code>.		 */		public function get dataFormat() : String		{			return _dataFormat;		}		/**		 * Parse byte array (possibly containing plain text) asynchronously, meaning that		 * the parser will periodically stop parsing so that the AVM may proceed to the		 * next frame.		 *		 * @param bytes The byte array in which the loaded data resides.		 * @param frameLimit number of milliseconds of parsing allowed per frame. The		 * actual time spent on a frame can exceed this number since time-checks can		 * only be performed between logical sections of the parsing procedure.		 */		public function parseBytesAsync(bytes : ByteArray, frameLimit : Number = 30) : void		{			if (_dataFormat == ParserDataFormat.BINARY)				_byteData = bytes;			else if (_dataFormat == ParserDataFormat.PLAIN_TEXT)				_textData = bytes.readUTFBytes(bytes.bytesAvailable);			startParsing(frameLimit);		}		/**		 * Parse plaintext string asynchronously, meaning that the parser will periodically		 * stop parsing so that the AVM may proceed to the next frame. If this parser		 * requires binary data, an error will be thrown.		 *		 * @param str Text data used for parsing.		 * @param frameLimit number of milliseconds of parsing allowed per frame. The		 * actual time spent on a frame can exceed this number since time-checks can		 * only be performed between logical sections of the parsing procedure.		 */		public function parseTextAsync(str : String, frameLimit : Number = 30) : void		{			if (_dataFormat == ParserDataFormat.PLAIN_TEXT)				_textData = str;			else if (_dataFormat == ParserDataFormat.BINARY) {				// TODO: Throw error when trying to parse text with binary parser			}			startParsing(frameLimit);		}		/**		 * The object that will contain all the parsed data.		 */		public function get handle() : IResource		{			return _handle;		}		/**		 * A list of dependencies that need to be loaded and resolved for the object being parsed.		 */		public function get dependencies() : Vector.<ResourceDependency>		{			return _dependencies;		}		/**		 * Resolve a dependency when it's loaded. For example, a dependency containing an ImageResource would be assigned		 * to a Mesh instance as a BitmapMaterial, a scene graph object would be added to its intended parent. The		 * dependency should be a member of the dependencies property.		 *		 * @param resourceDependency The dependency to be resolved.		 */		arcane function resolveDependency(resourceDependency : ResourceDependency) : void		{			throw new AbstractMethodError();		}				/**		 * Resolve a dependency loading failure. Used by parser to eventually provide a default map		 *		 * @param resourceDependency The dependency to be resolved.		 */		arcane function resolveDependencyFailure(resourceDependency : ResourceDependency) : void		{			throw new AbstractMethodError();		}		/**		 * Creates the object that will be returned to the user and will contain all the loaded data. This allows		 * <code>ResourceManager</code> to return an object handle regardless of whether the object was loaded or not,		 * which in turn allows users to add objects to the scene or assign materials before they are actually loaded.		 * This method needs to be overridden by concrete subclasses.		 * @return A reference to the handle.		 */		protected function initHandle() : IResource		{			throw new AbstractMethodError();		}		/**		 * Parse the next block of data.		 * @return Whether or not more data needs to be parsed. Can be <code>ParserBase.PARSING_DONE</code> or		 * <code>ParserBase.MORE_TO_PARSE</code>.		 */		protected function proceedParsing() : Boolean		{			throw new AbstractMethodError();			return true;		}		/**		 * Finish parsing the data.		 */		protected function finishParsing() : void		{			_timer.removeEventListener(TimerEvent.TIMER, onInterval);			_timer.stop();			_timer = null;			dispatchEvent(new LoaderEvent(LoaderEvent.PARSE_COMPLETE, _handle));		}		/**		 * Tests whether or not there is still time left for parsing within the maximum allowed time frame per session.		 * @return True if there is still time left, false if the maximum allotted time was exceeded and parsing should be interrupted.		 */		protected function hasTime() : Boolean		{			return ((getTimer() - _lastFrameTime) < _frameLimit);		}		/**		 * Called when the parsing pause interval has passed and parsing can proceed.		 */		protected function onInterval(event : TimerEvent = null) : void		{			_lastFrameTime = getTimer();			if (proceedParsing() && !_parsingFailure)				finishParsing();		}		/**		 * Initializes the parsing of data.		 * @param frameLimit The maximum duration of a parsing session.		 */		private function startParsing(frameLimit : Number) : void		{			_frameLimit = frameLimit;			_timer = new Timer(_frameLimit, 0);			_timer.addEventListener(TimerEvent.TIMER, onInterval); 			_timer.start();			// synchronously right away			onInterval();		}		/**		 * resolves parent file directory from uri		 */		private function resolveUri() : void		{			var aPath : Array = _uri.split("/");			aPath.pop();			_baseUri = aPath.join("/") + "/";		}	}}
﻿package away3d.containers
{
    import away3d.animators.skin.Bone;
    import away3d.core.*;
    import away3d.core.base.*;
    import away3d.core.draw.*;
    import away3d.core.math.*;
    import away3d.core.traverse.*;
    import away3d.events.*;
    
    /**
    * 3d object container node for other 3d objects in a scene
    */
    public class ObjectContainer3D extends Object3D implements IPrimitiveProvider
    {
        use namespace arcane;
		/** @private */
        arcane function internalAddChild(child:Object3D):void
        {
            _children.push(child);

            child.addOnTransformChange(onChildChange);
            child.addOnDimensionsChange(onChildChange);

            notifyDimensionsChange();
        }
		/** @private */
        arcane function internalRemoveChild(child:Object3D):void
        {
            var index:int = children.indexOf(child);
            if (index == -1)
                return;
			
            child.removeOnTransformChange(onChildChange);
            child.addOnDimensionsChange(onChildChange);

            _children.splice(index, 1);

            notifyDimensionsChange();
        }
        
        private var _children:Array = new Array();
        private var _radiusChild:Object3D = null;

        private function onChildChange(event:Object3DEvent):void
        {
            notifyDimensionsChange();
        }
                
        protected override function updateDimensions():void
        {
        	//update bounding radius
        	var children:Array = _children.concat();
        	var mradius:Number = 0;
        	var cradius:Number;
            var num:Number3D = new Number3D();
            for each (var child:Object3D in children) {
            	child.setParentPivot(_pivotPoint);
                cradius = child.parentradius;
                if (mradius < cradius)
                    mradius = cradius;
            }
            _boundingRadius = cradius;
            
            //update max/min X
            children.sortOn("parentmaxX", Array.DESCENDING | Array.NUMERIC);
            _maxX = children[0];
            children.sortOn("parentminX", Array.NUMERIC);
            _minX = children[0];
            
            //update max/min Y
            children.sortOn("parentmaxY", Array.DESCENDING | Array.NUMERIC);
            _maxY = children[0];
            children.sortOn("parentminY", Array.NUMERIC);
            _minY = children[0];
            
            //update max/min Z
            children.sortOn("parentmaxZ", Array.DESCENDING | Array.NUMERIC);
            _maxZ = children[0];
            children.sortOn("parentminZ", Array.NUMERIC);
            _minZ = children[0];
            
            _dimensionsDirty = false;
        }
        
        /**
        * Returns the children of the container as an array of 3d objects
        */
        public function get children():Array
        {
            return _children;
        }
    	
	    /**
	    * Creates a new <code>ObjectContainer3D</code> object
	    * 
	    * @param	init			[optional]	An initialisation object for specifying default instance properties
	    * @param	...childarray				An array of 3d objects to be added as children of the container on instatiation
	    */
        public function ObjectContainer3D(init:Object = null, ...childarray)
        {
            if (init != null && init is Object3D) {
                addChild(init as Object3D);
                init = null;
            }

            super(init);
            
            for each (var child:Object3D in childarray)
                addChild(child);
        }
        
		/**
		 * Adds an array of 3d objects to the scene as children of the container
		 * 
		 * @param	...childarray		An array of 3d objects to be added
		 */
        public function addChildren(...childarray):void
        {
            for each (var child:Object3D in childarray)
                addChild(child);
        }
        
		/**
		 * Adds a 3d object to the scene as a child of the container
		 * 
		 * @param	child	The 3d object to be added
		 * @throws	Error	ObjectContainer3D.addChild(null)
		 */
        public function addChild(child:Object3D):void
        {
            if (child == null)
                throw new Error("ObjectContainer3D.addChild(null)");
            if (child.parent == this)
                return;
            child.parent = this;
        }
        
		/**
		 * Removes a 3d object from the child array of the container
		 * 
		 * @param	child	The 3d object to be removed
		 * @throws	Error	ObjectContainer3D.removeChild(null)
		 */
        public function removeChild(child:Object3D):void
        {
            if (child == null)
                throw new Error("ObjectContainer3D.removeChild(null)");
            if (child.parent != this)
                return;
            child.parent = null;
        }
        
		/**
		 * Returns a 3d object specified by name from the child array of the container
		 * 
		 * @param	name	The name of the 3d object to be returned
		 * @return			The 3d object, or <code>null</code> if no such child object exists with the specified name
		 */
        public function getChildByName(childName:String):Object3D
        {	
			var child:Object3D;
            for each(var object3D:Object3D in children) {
            	if (object3D.name)
					if (object3D.name == childName)
						return object3D;
				
            	if (object3D is ObjectContainer3D) {
	                child = (object3D as ObjectContainer3D).getChildByName(childName);
	                if (child)
	                    return child;
	            }
            }
			
            return null;
        }
        
		/**
		 * Returns a bone object specified by name from the child array of the container
		 * 
		 * @param	name	The name of the bone object to be returned
		 * @return			The bone object, or <code>null</code> if no such bone object exists with the specified name
		 */
        public function getBoneByName(boneName:String):Bone
        {	
			var bone:Bone;
            for each(var object3D:Object3D in children) {
            	if (object3D is Bone) {
            		bone = object3D as Bone;
            		
	            	if (bone.name)
						if (bone.name == boneName)
							return bone;
					
					if (bone.id)
						if (bone.id == boneName)
							return bone;
            	}
            	if (object3D is ObjectContainer3D) {
	                bone = (object3D as ObjectContainer3D).getBoneByName(boneName);
	                if (bone)
	                    return bone;
	            }
            }
			
            return null;
        }
        
		/**
		 * Removes a 3d object from the child array of the container
		 * 
		 * @param	name	The name of the 3d object to be removed
		 */
        public function removeChildByName(name:String):void
        {
            removeChild(getChildByName(name));
        }
        
		/**
		 * @inheritDoc
		 */
        public override function traverse(traverser:Traverser):void
        {
            if (traverser.match(this))
            {
                traverser.enter(this);
                traverser.apply(this);                for each (var child:Object3D in children)
                    child.traverse(traverser);
                traverser.leave(this);
            }
        }
		
		/**
		 * Duplicates the 3d object's properties to another <code>ObjectContainer3D</code> object
		 * 
		 * @param	object	[optional]	The new object instance into which all properties are copied
		 * @return						The new object instance with duplicated properties applied
		 */
        public override function clone(object:* = null):*
        {
            var container:ObjectContainer3D = object || new ObjectContainer3D();
            super.clone(container);

            for each (var child:Object3D in children)
                container.addChild(child.clone());
                
            return container;
        }
    }
}

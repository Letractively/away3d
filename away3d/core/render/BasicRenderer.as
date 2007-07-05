package away3d.core.render
{
    import away3d.core.*;
    import away3d.core.scene.*;
    import away3d.core.draw.*;
    import away3d.core.block.*;
    import flash.utils.*;
    import flash.geom.*;
    import flash.display.*;

    /** Basic renderer implementation */
    public class BasicRenderer implements IRenderer
    {
        private var filters:Array;

        public function BasicRenderer(...filters)
        {
            this.filters = filters;
            this.filters.push(new ZSortFilter());
        }

        private var tricount:int;
        private var maxtriarea:Number;
        private var sumtriarea:int;
        private var info:String;

        public function render(view:View3D/*scene:Scene3D, camera:Camera3D, container:Sprite, clip:Clipping*/):void
        {
            var scene:Scene3D = view.scene;
            var camera:Camera3D = view.camera;
            var container:Sprite = view.canvas;
            var clip:Clipping = view.clip;

            var start:int = getTimer();
            info = "";

            var graphics:Graphics = container.graphics;

            // get blockers for occlution culling
            var blockerarray:BlockerArray = new BlockerArray(clip);
            var blocktraverser:BlockerTraverser = new BlockerTraverser(blockerarray, view);
            scene.traverse(blocktraverser);
            var blockers:Array = blockerarray.list();

            // get lights and drawing primitives
            var priarray:PrimitiveArray = new PrimitiveArray(clip, blockers);
            var lightarray:LightArray = new LightArray();
            var pritraverser:PrimitiveTraverser = new PrimitiveTraverser(priarray, lightarray, view);
            scene.traverse(pritraverser);
            var primitives:Array = priarray.list();

            info += (getTimer() - start) + "ms ";
            start = getTimer();

            // apply filters
            for each (var filter:IPrimitiveFilter in filters)
                primitives = filter.filter(primitives, scene, camera, container, clip);

            tricount = primitives.length;

            info += (getTimer() - start) + "ms ";
            start = getTimer();
            
            var session:RenderSession = new RenderSession(scene, camera, container, clip, lightarray);

            // render all
            for each (var primitive:DrawPrimitive in primitives)
                primitive.render(session);

            info += (getTimer() - start) + "ms ";
            start = getTimer();

        }

        public function desc():String
        {
            return "Basic ["+filters.join("+")+"]";
        }

        public function stats():String
        {
            return "";
            //return tricount+" triangles "+info;
        }
    }
}

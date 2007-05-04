package away3d.core.proto
{
    import away3d.core.*;
    import away3d.core.proto.*;
    import away3d.core.draw.*;
    import away3d.core.math.*;
    import flash.geom.*;
    import flash.display.*;

    public interface ILightProvider
    {
        function light(transform:Matrix3D, consumer:ILightConsumer):void;
    }
}

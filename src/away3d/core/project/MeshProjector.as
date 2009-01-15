package away3d.core.project
{
	import away3d.cameras.*;
	import away3d.cameras.lenses.*;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.core.draw.*;
	import away3d.core.math.*;
	import away3d.core.utils.*;
	import away3d.materials.*;
	
	import flash.utils.*;
	
	public class MeshProjector implements IPrimitiveProvider
	{
		private var _view:View3D;
		private var _vertexDictionary:Dictionary;
		private var _drawPrimitiveStore:DrawPrimitiveStore;
		private var _mesh:Mesh;
		private var _faces:Array;
		private var _triangles:Array;
		private var _clippedTriangles:Array;
		private var _segments:Array;
		private var _billboards:Array;
		private var _camera:Camera3D;
		private var _lens:AbstractLens;
		private var _focus:Number;
		private var _zoom:Number;
		private var _faceMaterial:ITriangleMaterial;
		private var _segmentMaterial:ISegmentMaterial;
		private var _billboardMaterial:IBillboardMaterial;
		private var _vertex:Vertex;
		private var _screenVertex:ScreenVertex;
		private var _face:Face;
		private var _tri:DrawTriangle;
		private var _uvt:UV;
		private var _smaterial:ISegmentMaterial;
		private var _bmaterial:IBillboardMaterial;
		private var _segment:Segment;
		private var _billboard:Billboard;
		private var _drawTriangle:DrawTriangle;
		private var _drawSegment:DrawSegment;
		private var _drawBillBoard:DrawBillboard;
		private var _backmat:ITriangleMaterial;
        private var _backface:Boolean;
        private var _uvmaterial:Boolean;
        private var _vt:ScreenVertex;
		private var _n01:Face;
		private var _n12:Face;
		private var _n20:Face;
		private var _sv0:ScreenVertex;
		private var _sv1:ScreenVertex;
		private var _sv2:ScreenVertex;
		
        private function front(face:Face):Number
        {
            _sv0 = _vertexDictionary[face.v0];
            _sv1 = _vertexDictionary[face.v1];
            _sv2 = _vertexDictionary[face.v2];
                
            return (_sv0.x*(_sv2.y - _sv1.y) + _sv1.x*(_sv0.y - _sv2.y) + _sv2.x*(_sv1.y - _sv0.y));
        }
        
        public function get view():View3D
        {
        	return _view;
        }
        public function set view(val:View3D):void
        {
        	_view = val;
        	_drawPrimitiveStore = view.drawPrimitiveStore;
        }
        
		public function primitives(source:Object3D, viewTransform:Matrix3D, consumer:IPrimitiveConsumer):void
		{
			_vertexDictionary = _drawPrimitiveStore.createVertexDictionary(source);
			
			_mesh = source as Mesh;
			_faces = _mesh.faces;
			_segments = _mesh.segments;
			_billboards = _mesh.billboards;
			
			_camera = _view.camera;
			_lens = _camera.lens;
        	_focus = _camera.focus;
        	_zoom = _camera.zoom;
        	
			_faceMaterial = _mesh.faceMaterial;
			_segmentMaterial = _mesh.segmentMaterial;
			_billboardMaterial = _mesh.billboardMaterial;
			
			_backmat = _mesh.back || _faceMaterial;
			
			_triangles = new Array();
			
			//loop through all faces
            for each (_face in _faces)
            {
                 if (!_face.visible)
                    continue;
				
				_sv0 = _lens.project(viewTransform, _face.v0, _vertexDictionary);
				_sv1 = _lens.project(viewTransform, _face.v1, _vertexDictionary);
				_sv2 = _lens.project(viewTransform, _face.v2, _vertexDictionary);
				
                if (!_sv0.visible && !_sv1.visible && !_sv2.visible)
                    continue;
				
				_drawTriangle = _drawPrimitiveStore.createDrawTriangle(source, _face, null, _sv0, _sv1, _sv2, _face.uv0, _face.uv1, _face.uv2);
	            
				_clippedTriangles = _view.screenClip.check(_drawTriangle);
				
				for each (_tri in _clippedTriangles)
					_triangles.push(_tri);
            }

            for each (_tri in _triangles) {
				
				//calculate Draw_triangle properties
                _tri.calc();
                
				//determine if _triangle is facing towards or away from camera
                _backface = _tri.area < 0;
				
				//if _triangle facing away, check for backface material
                if (_backface) {
                    if (!_mesh.bothsides)
                    	continue;
                    
                    _tri.material = _face.back;
                    
                    if (!_tri.material)
                    	_tri.material = _face.material;
                } else {
                    _tri.material = _face.material;
                }
                
				//determine the material of the _triangle
                if (!_tri.material) {
                    if (_backface)
                        _tri.material = _backmat;
                    else
                        _tri.material = _faceMaterial;
                }
                
				//do not draw material if visible is false
                if (_tri.material && !_tri.material.visible)
                    _tri.material = null;
				
				//if there is no material and no outline, continue
                if (!_mesh.outline && !_tri.material)
                        continue;
				
                if (_mesh.pushback)
                    _tri.screenZ = _tri.maxZ;
				
                if (_mesh.pushfront)
                    _tri.screenZ = _tri.minZ;
				
				_uvmaterial = (_tri.material is IUVMaterial || _tri.material is ILayerMaterial);
				
				//swap ScreenVerticies if _triangle facing away from camera
                if (_backface) {
                    _vt = _tri.v1;
                    _tri.v1 = _tri.v2;
                    _tri.v2 = _vt;
					
                    _tri.area = -_tri.area;
                    
                    if (_uvmaterial) {
						//pass accross uv values
						_uvt = _tri.uv1;
						_tri.uv1 = _tri.uv2;
                    	_tri.uv2 = _uvt;
                    }
                }
				
                //check if face swapped direction
                if (_tri.backface != _backface) {
                	_tri.backface = _backface;
                	if (_tri.material is IUVMaterial)
                		(_tri.material as IUVMaterial).getFaceVO(_tri.face).texturemapping = null;
                }
				
                if (_mesh.outline && !_backface)
                {
                    _n01 = _mesh.geometry.neighbour01(_face);
                    if (_n01 == null || front(_n01) <= 0)
                    	consumer.primitive(_drawPrimitiveStore.createDrawSegment(source, _mesh.outline, _tri.v0, _tri.v1));
					
                    _n12 = _mesh.geometry.neighbour12(_face);
                    if (_n12 == null || front(_n12) <= 0)
                    	consumer.primitive(_drawPrimitiveStore.createDrawSegment(source, _mesh.outline, _tri.v1, _tri.v2));
					
                    _n20 = _mesh.geometry.neighbour20(_face);
                    if (_n20 == null || front(_n20) <= 0)
                    	consumer.primitive(_drawPrimitiveStore.createDrawSegment(source, _mesh.outline, _tri.v2, _tri.v0));
					
                    if (!_tri.material)
                    	continue;
                }
                
                consumer.primitive(_tri);
            }
            //loop through all segments
            for each (_segment in _segments)
            {
            	_sv0 = _lens.project(viewTransform, _segment.v0, _vertexDictionary);
            	_sv1 = _lens.project(viewTransform, _segment.v1, _vertexDictionary);
    
                if (!_sv0.visible && !_sv1.visible)
                    continue;
            	
            	_smaterial = _segment.material || _segmentMaterial;
				
                if (!_smaterial.visible)
                    continue;
                
            	_drawSegment = _drawPrimitiveStore.createDrawSegment(source, _smaterial, _sv0, _sv1)
                
                consumer.primitive(_drawSegment);
            }
            
            //loop through all billboards
            for each (_billboard in _billboards)
            {
                if (!_billboard.visible)
                    continue;
				
				_sv0 = _lens.project(viewTransform, _billboard.vertex, _vertexDictionary);
				
            	if (!_sv0.visible)
                    continue;
                
                _bmaterial = _billboard.material || _billboardMaterial;
                
                if (!_bmaterial.visible)
                    continue;
                    
				_drawBillBoard = _drawPrimitiveStore.createDrawBillboard(source, _bmaterial, _sv0, _billboard.width, _billboard.height, _billboard.scaling*_zoom / (1 + _screenVertex.z / _focus), _billboard.rotation);
		        
	            consumer.primitive(_drawBillBoard);
            }
		}
	}
}
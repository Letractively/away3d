﻿package away3dlite.loaders;import away3dlite.animators.frames.Frame;import away3dlite.animators.MovieMesh;import away3dlite.core.utils.Cast;import flash.Error;import flash.Lib;import flash.utils.ByteArray;import flash.utils.Endian;import flash.Vector;//use namespace arcane;using away3dlite.namespace.Arcane;using away3dlite.haxeutils.HaxeUtils;/*** File loader for the Md2 file format.*/class MD2 extends AbstractParser{	/** @private */	/*arcane*/ private override function prepareData(data:Dynamic):Void	{		md2 = Cast.bytearray(data);				var a:Int, b:Int, c:Int, ta:Int, tb:Int, tc:Int, i1:Int, i2:Int, i3:Int;		var i:Int;		var uvs:Array<Float> = [];				// Make sure to have this in Little Endian or you will hate you life.		// At least I did the first time I did this for a while.		data.endian = Endian.LITTLE_ENDIAN;		// Read the header and make sure it is valid MD2 file		readMd2Header(data);		if (ident != 844121161 || version != 8) {			#if flash			throw new Error("Error loading MD2 file: Not a valid MD2 file/bad version");			#else			throw "Error loading MD2 file: Not a valid MD2 file/bad version";			#end		}		// UV coordinates		//		Load them!		data.position = offset_st;		i = -1;		while (++i < num_st)			uvs.push(data.readShort() / skinwidth); uvs.push((data.readShort() / skinheight));					mesh.arcaneNS()._uvtData.length = mesh.arcaneNS()._vertices.length = num_tris*9;		#if flash		vertices.length = num_tris*3;		#end						// Faces		//		Creates the faces with the proper references to vertices		//		NOTE: DO NOT change the order of the variable assignments here, 		//			  or nothing will work.		data.position = offset_tris;		i = -1;		while (++i < num_tris)		{			i1 = i*3;			i2 = i1 + 1;			i3 = i1 + 2;						//collect vertices			a = data.readUnsignedShort();			b = data.readUnsignedShort();			c = data.readUnsignedShort();			vertices[i1] = a;			vertices[i2] = b;			vertices[i3] = c;						//var _mesh_arcane = mesh.arcaneNS();						//collect indices			mesh.arcaneNS()._indices.push(i3);			mesh.arcaneNS()._indices.push(i2);			mesh.arcaneNS()._indices.push(i1);			//collect face lengths			mesh.arcaneNS()._faceLengths.push(3);						//collect uvData 			ta = data.readUnsignedShort();			tb = data.readUnsignedShort();			tc = data.readUnsignedShort();						mesh.arcaneNS()._uvtData[i1*3] = uvs[ta*2];			mesh.arcaneNS()._uvtData[i1*3 + 1] = uvs[ta*2 + 1];			mesh.arcaneNS()._uvtData[i1*3 + 2] = 1;			mesh.arcaneNS()._uvtData[i2*3] = uvs[tb*2];			mesh.arcaneNS()._uvtData[i2*3 + 1] = uvs[tb*2 + 1];			mesh.arcaneNS()._uvtData[i2*3 + 2] = 1;			mesh.arcaneNS()._uvtData[i3*3] = uvs[tc*2];			mesh.arcaneNS()._uvtData[i3*3 + 1] = uvs[tc*2 + 1];			mesh.arcaneNS()._uvtData[i3*3 + 2] = 1;		}				// Frame animation data		//		This part is a little funky.		data.position = offset_frames;		readFrames(data);				//setup vertices for the first frame		i = mesh.arcaneNS()._vertices.length;		vertices = mesh.frames[0].vertices;		while (i-- != 0)			mesh.arcaneNS()._vertices[i] = vertices[i];				if (material != null)			mesh.material = material;				mesh.arcaneNS().buildFaces();				mesh.type = ".Md2";	}		private var md2:ByteArray;	private var ident:Int;	private var version:Int;	private var skinwidth:Int;	private var skinheight:Int;	private var framesize:Int;	private var num_skins:Int;	private var num_vertices:Int;	private var num_st:Int;	private var num_tris:Int;	private var num_glcmds:Int;	private var num_frames:Int;	private var offset_skins:Int;	private var offset_st:Int;	private var offset_tris:Int;	private var offset_frames:Int;	private var offset_glcmds:Int;	private var offset_end:Int;	private var mesh:MovieMesh;	private var vertices:Vector<Float>;		/**	 * Reads in all the frames	 */	private function readFrames(data:ByteArray):Void	{		var sx:Float = 0, sy:Float, sz:Float;		var tx:Float, ty:Float, tz:Float;		var fvertices:Vector<Float>, frame:Frame;		var tvertices:Vector<Float>;		var i:Int, j:Int, k:Int, char:Int;				i = -1;		while (++i < num_frames)		{			tvertices = new Vector<Float>();			#if flash			fvertices = new Vector<Float>(num_tris*9, true);			#else			fvertices = new Vector<Float>();			#end			frame = new Frame("", fvertices);			try {				sx = data.readFloat();			} catch (e: Dynamic)			{				trace(e);			}						trace("HSHS");			sy = data.readFloat();			sz = data.readFloat();			tx = data.readFloat();			ty = data.readFloat();			tz = data.readFloat();						//read frame name			k = 0;			j = -1;			while (++j < 16)			{				char = data.readUnsignedByte();								if (Std.int(char) >= 0x30 && Std.int(char) <= 0x7A && k < 3)					frame.name += String.fromCharCode(char);								if (Std.int(char) >= 0x30 && Std.int(char) <= 0x39)					k++; 			}						// Note, the extra data.position++ in the for loop is there 			// to skip over a byte that holds the "vertex normal index"			j = -1;			while (++j < num_vertices)			{								tvertices.push((sx * data.readUnsignedByte() + tx) * scaling);				tvertices.push((sy * data.readUnsignedByte() + ty) * scaling);				tvertices.push((sz * data.readUnsignedByte() + tz) * scaling);				data.position++;			}						j = -1;			while (++j < num_tris * 3)			{				fvertices[j*3] = tvertices[Std.int(vertices[j]*3)];				fvertices[j*3 + 1] = tvertices[Std.int(vertices[j]*3 + 1)];				fvertices[j*3 + 2] = tvertices[Std.int(vertices[j]*3 + 2)];			}						mesh.addFrame(frame);		}		trace("dsdsodfsjodfsoj");		#if flash		vertices.fixed = true;		#end	}	/**	 * Reads in all that MD2 Header data that is declared as private variables.	 * I know its a lot, and it looks ugly, but only way to do it in Flash	 */	private function readMd2Header(data:ByteArray):Void	{		ident = data.readInt();		version = data.readInt();		skinwidth = data.readInt();		skinheight = data.readInt();		framesize = data.readInt();		num_skins = data.readInt();		num_vertices = data.readInt();		num_st = data.readInt();		num_tris = data.readInt();		num_glcmds = data.readInt();		num_frames = data.readInt();		offset_skins = data.readInt();		offset_st = data.readInt();		offset_tris = data.readInt();		offset_frames = data.readInt();		offset_glcmds = data.readInt();		offset_end = data.readInt();	}		/**	 * A scaling factor for all geometry in the model. Defaults to 1.	 */	public var scaling:Float;		/**	 * Controls the automatic centering of geometry data in the model, improving culling and the accuracy of bounding dimension values.	 */	public var centerMeshes:Bool;		/**	 * Creates a new <code>Md2</code> object.	 */	public function new()	{		super();				vertices = new Vector<Float>();		mesh = Lib.as(_container = new MovieMesh(), MovieMesh);		scaling = 1;				binary = true;	}}
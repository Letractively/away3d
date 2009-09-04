﻿/*
   Copyright (c) 2007 Danny Chapman
   http://www.rowlhouse.co.uk

   This software is provided 'as-is', without any express or implied
   warranty. In no event will the authors be held liable for any damages
   arising from the use of this software.
   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it
   freely, subject to the following restrictions:
   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
   3. This notice may not be removed or altered from any source
   distribution.
 */

/**
 * @author Muzer(muzerly@gmail.com)
 * @link http://code.google.com/p/jiglibflash
 */

package jiglib.geometry
{
	import flash.geom.Vector3D;

	import jiglib.math.*;
	import jiglib.physics.PhysicsState;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.ISkin3D;

	public class JSphere extends RigidBody
	{

		public var name:String;
		private var _radius:Number;

		public function JSphere(skin:ISkin3D, r:Number)
		{

			super(skin);
			_type = "SPHERE";
			_radius = r;
			_boundingSphere = _radius;
			mass = 1;
		}

		public function set radius(r:Number):void
		{
			_radius = r;
			_boundingSphere = _radius;
			setInertia(getInertiaProperties(mass));
			setActive();
		}

		public function get radius():Number
		{
			return _radius;
		}

		override public function segmentIntersect(out:Object, seg:JSegment, state:PhysicsState):Boolean
		{
			out.fracOut = 0;
			out.posOut = new JNumber3D();
			out.normalOut = new JNumber3D();

			var frac:Number = 0;
			var r:Vector3D = seg.delta;
			var s:Vector3D = seg.origin.subtract(state.position);

			var radiusSq:Number = _radius * _radius;
			var rSq:Number = r.lengthSquared;
			if (rSq < radiusSq)
			{
				out.fracOut = 0;
				out.posOut = seg.origin.clone();
				out.normalOut = out.posOut.subtract(state.position);
				out.normalOut.normalize();
				return true;
			}

			var sDotr:Number = JNumber3D.dot(s, r);
			var sSq:Number = s.lengthSquared;
			var sigma:Number = sDotr * sDotr - rSq * (sSq - radiusSq);
			if (sigma < 0)
			{
				return false;
			}
			var sigmaSqrt:Number = Math.sqrt(sigma);
			var lambda1:Number = (-sDotr - sigmaSqrt) / rSq;
			var lambda2:Number = (-sDotr + sigmaSqrt) / rSq;
			if (lambda1 > 1 || lambda2 < 0)
			{
				return false;
			}
			frac = Math.max(lambda1, 0);
			out.fracOut = frac;
			out.posOut = seg.getPoint(frac);
			out.normalOut = out.posOut.subtract(state.position);
			out.normalOut.normalize();
			return true;
		}

		override public function getInertiaProperties(m:Number):JMatrix3D
		{
			var inertiaTensor:JMatrix3D = new JMatrix3D();
			var Ixx:Number = 0.4 * m * _radius * _radius;
			inertiaTensor.n11 = Ixx;
			inertiaTensor.n22 = Ixx;
			inertiaTensor.n33 = Ixx;

			return inertiaTensor;
		}
	}
}
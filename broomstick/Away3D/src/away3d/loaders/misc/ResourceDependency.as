﻿package away3d.loaders.misc
{
	
		
		{
			
		{
			return _retrieveAsRawData;
		}
		
		
		/**
		/**
		 * Method to set data after having already created the dependency object, e.g. after load.
		*/
		arcane function setData(data : *) : void
		{
			_data = data;
		}
		
		/**
		 * The parser which is dependent on this ResourceDependency object.
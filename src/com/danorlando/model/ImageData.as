package com.danorlando.model
{
    import flash.display.BitmapData;
    import flash.events.EventDispatcher;
	
    /**
     * This class is a hybrid "value object" type of class that also acts as 
     * a container for the bitmap data of a given image. 
     * 
     * @author danorlando
     * 
     */	
    public class ImageData extends EventDispatcher
    {
        private var _name:String;
        private var _url:String;
        private var _bitmapData:BitmapData;
        private var _thumbnail:BitmapData;

        public function ImageData( sName:String, sUrl:String, bBitmapData:BitmapData, bThumbnail:BitmapData = null ) {
            _name = sName;
            _url = sUrl;
            _bitmapData = bBitmapData;
            _thumbnail = bThumbnail;
        }

         public function clean():void {
            if( _thumbnail != null ) _thumbnail.dispose();
            if( _bitmapData != null ) _bitmapData.dispose();
        }
        
        public function clone():ImageData {
            return new ImageData( _name, _url, _bitmapData.clone() );
        }
        
        public function get fileExtension():String {
            return _name.substr( _name.lastIndexOf( "." ), name.length ).toLowerCase();
        }

        [Bindable]
        public function set name( str:String ):void {
            _name = str;
        }
        
        public function get name():String {
            return _name;
        }

        [Bindable]
        public function set url( str:String ):void {
            _url = str;
        }
       
        public function get url():String {
            return _url;
        }

        [Bindable]
        public function set bitmapData( bmp:BitmapData ):void {
            _bitmapData = bmp;
        }
       
        public function get bitmapData():BitmapData {
            return _bitmapData;
        }

        [Bindable]
        public function set thumbnail( bmp:BitmapData ):void {
            _thumbnail = bmp;
        }
        
        public function get thumbnail():BitmapData {
            return _thumbnail;
        }
        
    }
}
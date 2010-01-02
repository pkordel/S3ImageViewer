package com.danorlando.controller
{
    import com.danorlando.model.ImageData;
    import com.danorlando.events.ImageLoadEvent;
    
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.net.URLRequest;

    [Event(name="load", type="flash.events.Event")]
    [Event(name="invalid", type="flash.events.Event")]
    [Event(name="complete", type="flash.events.Event")]
    /**
     * This class acts as a queue for the loading of multiple 
     * images into the ImageBrowser.
     * 
     * @author danorlando
     * 
     */    
    public class ImageLoadQueue extends EventDispatcher
    {
        [ArrayElementType("flash.filesystem.File")]
        private var _queue:Array;
        private var _loader:Loader;
        private var _file:File;

        private var _filter:RegExp = /^\S+\.(jpg|jpeg|png)$/i;

        public static const INVALID:String = "invalid";
        public static const COMPLETE:String = "complete";

        public function ImageLoadQueue() {
            _queue = new Array();
            _loader = new Loader();
            _loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoadComplete );
            _loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onLoadError );
        }

        private function validateFile( file:File ):Boolean {
            return _filter.exec( file.name ) != null;
        }

        private function onLoadError( evt:IOErrorEvent ):void {
            dispatchEvent( new ErrorEvent(ErrorEvent.ERROR, false, false, evt.text) );
        }

        private function onLoadComplete( evt:Event ):void {
            var data:ImageData = new ImageData( _file.name, _file.url, ( _loader.content as Bitmap ).bitmapData );
            dispatchEvent( new ImageLoadEvent( ImageLoadEvent.LOAD, data ) );
            if( _queue.length <= 0 ) {
                clear();
                dispatchEvent( new Event( COMPLETE ) );
            }
            else {
                loadNext();    
            }
        }

        private function loadFile( file:File ):void {
            _file = file;
            if( validateFile( _file ) ) {
                _loader.load( new URLRequest( _file.url ) );
            }
            else {
                dispatchEvent( new Event( INVALID ) );
                if( _queue.length > 0 ) loadNext();
                else dispatchEvent( new Event( COMPLETE ) );
            }
        }

        public function loadNext():void {
            if( _queue.length > 0 ) {
                loadFile( _queue.shift() );
            }
        }
        
        public function loadAll():void {
            if( _queue.length <= 0 ) return;
             loadFile( _queue[0] );
            _queue.shift();
        }

        public function addFile( file:File ):void {
            _queue.push( file );
        }

        public function addFiles( arr:Array ):void {
            _queue = _queue.concat( arr );
        }

        public function clear():void {
            _queue = new Array();
        }
        
    }
}
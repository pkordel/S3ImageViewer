package com.danorlando.events
{
    import com.danorlando.model.ImageData;
    
    import flash.events.Event;

    public class ImageLoadEvent extends Event
    {
        private var _imageData:ImageData;
        
        public static const LOAD:String = "load";
    
        public function ImageLoadEvent(type:String, imgData:ImageData)
        {
            super( type );
            _imageData = imgData;
        }
    
        public function get imageData():ImageData
        {
            return _imageData;
        }
    }
}
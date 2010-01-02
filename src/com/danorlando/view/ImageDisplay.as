package com.danorlando.view
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    import mx.containers.Canvas;
    import mx.core.Container;
    import mx.core.UIComponent;
	
	
    [Event(name="dragCopy", type="flash.events.Event")]
    /**
     * This class is essentially the parent container for the larger portion of the gallery
     * where the full-size image is displayed when an image is selected.
     * 
     * @author danorlando
     * 
     */    
    public class ImageDisplay extends UIComponent {
        private var _canvas:Container;
        private var _holder:UIComponent;
        private var _imgSource:BitmapData;
        private var _image:Bitmap;

        private var _scale:Number = 1.0;
        private var _rotation:Number = 0;

        public static const DRAG_COPY:String = "dragCopy";

        public function ImageDisplay() {
            addEventListener( Event.RESIZE, doLayout );
        }

        override protected function createChildren():void {
            super.createChildren();

            _canvas = new Canvas();
            addChild( _canvas );

            _holder = new UIComponent();
            _holder.addEventListener( MouseEvent.MOUSE_DOWN, onImageSelect );
            _canvas.addChild( _holder );

            _image = new Bitmap();
            _holder.addChild( _image );
        }

        private function doLayout( evt:Event = null ):void {
            if( _imgSource == null ) return;
            _image.rotation = _rotation;
            _image.scaleX = _image.scaleY = _scale;

            var bounds:Rectangle = getImageBounds();
            _image.x = bounds.x;
            _image.y = bounds.y;

            _holder.width = _image.width;
            _holder.height = _image.height;    
            _holder.x = Math.max( 0, ( width - bounds.width ) / 2 );
            _holder.y = Math.max( 0, ( height -  bounds.height ) / 2 );

            _canvas.width = width;
            _canvas.height = height;
            _canvas.horizontalScrollPosition =
                    Math.max( 0, ( bounds.width - _canvas.width ) / 2 );
            _canvas.verticalScrollPosition =
                    Math.max( 0, ( bounds.height - _canvas.height ) / 2 );
        }

        private function getImageBounds():Rectangle {
            var x:Number = 0;
            var y:Number = 0;
            var w:Number = _imgSource.width * _scale;
            var h:Number = _imgSource.height * _scale;
        
            switch( _rotation ) {
                case 90:
                    x = h;
                    w = h ^ w;
                    h = h ^ w;
                    w = h ^ w;
                    break;
                case 180:
                    x = w;
                    y = h;
                    break;
             	case 270:
                    y = w;
                    w = h ^ w;
                    h = h ^ w;
                    w = h ^ w;
                    break;
            }
            return new Rectangle( x, y, w, h );
        }

        private function onImageSelect( evt:MouseEvent ):void {
            dispatchEvent( new Event( ImageDisplay.DRAG_COPY, true ) );
        }

		public function get source():BitmapData {
            return _imgSource;
        }
       
        public function set source( bmp:BitmapData ):void {
            _imgSource = bmp;
            _rotation = 0;
            _image.bitmapData = _imgSource;
            doLayout();
        }

		public function get scale():Number {
            return _scale;
        }
       
        public function set scale( num:Number ):void {
            _scale = num;
            doLayout();
        }

		override public function get rotation():Number {
            return _rotation;
        }
        
        override public function set rotation( value:Number ):void {
            _rotation = ( value > 360 ) ? value - 360 : value;
            _rotation = ( _rotation < 0 ) ? _rotation + 360 : _rotation;
            doLayout();
        }
    }
}
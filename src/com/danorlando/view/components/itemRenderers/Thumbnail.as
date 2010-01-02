package com.danorlando.view.components.itemRenderers
{
    import com.danorlando.model.ImageData;
    import com.danorlando.util.BitmapUtil;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.geom.Rectangle;
    
    import mx.controls.listClasses.IListItemRenderer;
    import mx.core.IDataRenderer;
    import mx.core.UIComponent;
    import mx.events.FlexEvent;

    [Style(name="borderColor", type="Number")]
    [Style(name="borderWeight", type="Number")]
    /**
     * This is the item renderer for the horizontal list items that appears in the image browser.
     * 
     * @author danorlando
     * 
     */	
    public class Thumbnail extends UIComponent implements IDataRenderer, IListItemRenderer
    {
        protected var _data:ImageData;
        private var _holder:UIComponent;
        private var _bitmap:Bitmap;
        private var _border:Shape;
        private var _useThumbnail:Boolean = false;

        private static const PADDING:int = 4;

        public function Thumbnail() {
            super();
        }

        protected function doLayout():void {
            var bounds:Rectangle = getBoundingArea();
            _border.graphics.clear();
            _border.graphics.lineStyle( getStyle( "borderWeight" ), getStyle( "borderColor" ), 1, true, "normal", "miter" );
            _border.graphics.drawRect( bounds.x, bounds.y, bounds.width, bounds.height );
            if( null == _data.thumbnail ) {
    			 var bmd:BitmapData = BitmapUtil.generateThumbnail( _bitmap.bitmapData, bounds.width - ( PADDING * 2 ), bounds.height - ( PADDING * 2 ) );
                _data.thumbnail = bmd;
                _bitmap.bitmapData.dispose();
                _bitmap.bitmapData = bmd;
            }
            _bitmap.x = ( unscaledWidth / 2 ) - ( _bitmap.width / 2 );
            _bitmap.y = ( unscaledHeight / 2 ) - ( _bitmap.height / 2 );
        }

        private function getBoundingArea():Rectangle {
            var bw:Number = getStyle( "borderWeight" );
            var px:Number = getStyle( "paddingLeft" ) + bw;
            var py:Number = bw;
            var pw:Number = unscaledWidth - ( getStyle( "paddingRight" ) + ( bw ) + px );
            var ph:Number = unscaledHeight - ( ( bw ) + py );
            return new Rectangle( px, py, pw, ph );
        }

        override protected function createChildren():void {
            super.createChildren();
            if( _holder == null ) {
                _holder = new UIComponent();
                addChild( _holder );

                _border = new Shape();
                _holder.addChild( _border );

                _bitmap = new Bitmap();
                _holder.addChild( _bitmap );
            }
        }

        override protected function commitProperties():void {
            if( _data != null ) {
                if( _data.thumbnail != null ) {
                    _bitmap.bitmapData = _data.thumbnail;
                }
                else _bitmap.bitmapData = _data.bitmapData.clone();
            }
        }

        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
            super.updateDisplayList( unscaledWidth, unscaledHeight );
            doLayout();
        }

        [Bindable("dataChange")]
        public function set data( value:Object ):void {
            _data = ( value as ImageData );
            dispatchEvent( new FlexEvent( FlexEvent.DATA_CHANGE ) );
        }
        
        public function get data():Object {
            return _data;
        }
        
    }
}
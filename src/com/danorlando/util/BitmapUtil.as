package com.danorlando.util
{
    import flash.display.BitmapData;
    import flash.geom.Matrix;

    public class BitmapUtil
    {
        public static function generateThumbnail( bmp:BitmapData, w:Number,
                                        h:Number, crop:Boolean = false ):BitmapData
        {
            var scale:Number = 1.0;
            if( bmp.width > w || bmp.height > h )
            {
                scale = Math.min( w / bmp.width, h / bmp.height );
            }
            var m:Matrix = new Matrix();
            m.scale( scale, scale );

            if( !crop )
            {
                m.tx = ( w / 2 ) - ( ( bmp.width * scale ) / 2 );
                m.ty = ( h / 2 ) - ( ( bmp.height * scale ) / 2 );
            }
            else
            {
                w = bmp.width * scale;
                h = bmp.height * scale;
            }

            var bmd:BitmapData = new BitmapData( w, h, true );
            bmd.draw( bmp, m );
            
            return bmd;
        }
    }
}
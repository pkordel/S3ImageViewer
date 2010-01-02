package com.danorlando.controller
{
    import com.danorlando.model.ImageData;
    
    import flash.events.Event;
    import flash.events.EventDispatcher;
    
    import mx.collections.ArrayCollection;

    [Event(name="indexChange", type="flash.events.Event")]
    /**
     * This is a singleton manager class responsible for keeping track of the 
     * currently selected image, dispatching a <code>indexChange</code> event
     * when the selected image changes, and also acts as a factory-like class
     * for managing the collection of ImageData objects in our gallery. 
     * 
     * @author danorlando
     * 
     */    
    public class GalleryDataManager extends EventDispatcher
    {
        public static var instance:GalleryDataManager;

        private var _currentIndex:int = 0;
        private var _list:ArrayCollection = new ArrayCollection();; // collection of ImageData objects

        public static const INDEX_CHANGE:String = "indexChange";

        public static function getInstance():GalleryDataManager {
           	if (GalleryDataManager.instance == null) {
				GalleryDataManager.instance  = new GalleryDataManager(new SingletonEnforcer());
			}
			return GalleryDataManager.instance;
        }

        public function GalleryDataManager(enforcer:SingletonEnforcer) { }

        public function addImage( img:ImageData ):void {
            _list.addItem( img );
        }

        public function addMultipleImages( arr:Array ):void {
          _list = new ArrayCollection( _list.toArray().concat( arr ) );
        }

         public function clean():void  {
            for( var i:int = 0; i < _list.length; i++ ) {
                 ( _list.getItemAt( i ) as ImageData ).clean();
            }
            _list = new ArrayCollection();
        }

        [Bindable]
        public function set list( arr:ArrayCollection ):void {
             _list = arr;
        }
        
        public function get list():ArrayCollection {
            return _list;
        }

        [Bindable("indexChange")]
        public function set currentIndex( index:int ):void {
            if( index < 0 || index > _list.length - 1 ) return;
            _currentIndex = index;
            dispatchEvent( new Event( INDEX_CHANGE ) );
        }
        
        public function get currentIndex():int {
            return _currentIndex;
        }
        
    }
}

class SingletonEnforcer{}
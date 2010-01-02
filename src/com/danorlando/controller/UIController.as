package com.danorlando.controller {

	import com.adobe.webapis.awss3.AWSS3;
	import com.adobe.webapis.awss3.AWSS3Event;
	import com.adobe.webapis.awss3.S3Object;
	import com.adobe.webapis.awss3.S3PostOptions;
	import com.adobe.webapis.awss3.S3PostRequest;
	import com.danorlando.model.ImageData;
	import com.danorlando.util.BitmapUtil;
	import com.danorlando.util.PolicyFactory;
	import com.danorlando.view.components.containers.ImageBrowser;
	import com.danorlando.view.components.containers.ImageCanvas;
	
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.graphics.codec.IImageEncoder;
	import mx.graphics.codec.JPEGEncoder;
	import mx.graphics.codec.PNGEncoder;
		
	/**
	 * This is the most important class in the application. It is the central controller
	 * by which almost everything runs through. It is a singleton class, and holds references to 
	 * the various display elements of the application as well as the parameters that were
	 * entered during authentication. Its most important function however, is handling the 
	 * communications between the application and the S3 data store.
	 * 
	 * @author danorlando
	 * 
	 */	
	public class UIController {
		
		public static var instance:UIController;
		
		public function UIController(enforcer:SingletonEnforcer) { }

		public static function getInstance():UIController	{
			if (UIController.instance == null) {
				UIController.instance = new UIController(new SingletonEnforcer());
			}
			return UIController.instance;
		}
	
//------------------------------
//
//   VARIABLES
//
//------------------------------	
		private var _manager:GalleryDataManager = GalleryDataManager.getInstance();
		private var _tempS3Obj:S3Object;
		private var _postRequest:S3PostRequest;
		private var _postOptions:S3PostOptions;
		
		private var _tempDir:File;
        private var _tempFile:File;
        private var _dragCopy:Boolean = false;

//------------------------------
//
//   CONSTANTS
//
//------------------------------	
        private static const DRAG_WIDTH:int = 100;
        private static const DRAG_HEIGHT:int = 100;

//------------------------------
//
//   PROPERTIES
//
//------------------------------	
		private var _viewer:S3ImageViewer;
		public function get viewer():S3ImageViewer { return this._viewer }
		public function set viewer(viewer:S3ImageViewer):void { _viewer = viewer }
		
		private var _browser:ImageBrowser;
		public function get browser():ImageBrowser { return this._browser }
		public function set browser(browser:ImageBrowser):void { this._browser = browser }
		
		private var _bucket:String;
		public function get bucket():String { return this._bucket }
		public function set bucket(name:String):void { this._bucket = name }
		
		private var _accessId:String;
		public function get accessId():String { return this._accessId }
		public function set accessId(id:String):void { this._accessId = id }
		
		private var _secretKey:String;
		public function get secretKey():String { return this._secretKey }
		public function set secretKey(key:String):void { this._secretKey = key }
		
		private var _awsAPI:AWSS3;
		public function get awsAPI():AWSS3 { return this._awsAPI }
		
		private var _currentImage:ImageData;
		public function get currentImage():ImageData { return this._currentImage }
		public function set currentImage(img:ImageData):void { 	this._currentImage = img }
		
		private var _canvas:ImageCanvas;
		public function get canvas():ImageCanvas { return this._canvas }
		public function set canvas(canvas:ImageCanvas):void { this._canvas = canvas; }
		

//------------------------------
//
//   METHODS
//
//------------------------------			

		/**
		 * Called when the submit button is selected from the authentication window
		 * that is displayed on application initialization. This creates the initial
		 * connection to AWS S3.
		 * 
		 * @param accessID The S3 Access ID provided with your S3 account
		 * @param secretKey The secret private key assigned to your S3 account
		 * @param bucketName The name of the bucket that the application should connect to
		 * 
		 */		
		public function authenticate(accessID:String, secretKey:String, bucketName:String):void {
			this.bucket = bucketName;
			this.accessId = accessID;
			this.secretKey = secretKey;
			//instantiate the AWS S3 API 
			_awsAPI = new AWSS3(accessID,secretKey);	
			//add listeners for the events that we are interested in
			_awsAPI.addEventListener(AWSS3Event.LIST_OBJECTS, listObjectsHandler);
			_awsAPI.addEventListener(AWSS3Event.ERROR, awsErrorHandler);
			_awsAPI.addEventListener(AWSS3Event.OBJECT_RETRIEVED, objectRetrievedHandler);
			_awsAPI.listObjects(this._bucket);
			//create a temp directory for creating temp copies of images
			_tempDir = File.createTempDirectory();
		}
		
		/**
		 * Grabs the array of file objects sent from S3 from the <code>event.data</code>
		 * parameter and iterates through the array. For each filename, or <code>key</code> in 
		 * the array, a call is made to <code>AWSS3.getObject(bucket,key)</code>. Each time an
		 * object is successfully retrieved, the <code>AWSS3Event.OBJECT_RETRIEVED</code> event
		 * is fired, which then calls the <code>objectRetrievedHandler</code> function.
		 * 
		 * @param event AWSS3Event
		 * 
		 * @see com.adobe.webapis.awss3.AWSS3.getObject
		 * @see com.danorlando.controller.UIController.objectRetrievedHandler
		 * 
		 */		
		public function listObjectsHandler(event:AWSS3Event):void {
			var objects:Array = event.data as Array;
			for (var i:int=0; i < objects.length; i++) {
				var filename:String = objects[i].key as String;
				_awsAPI.getObject(this._bucket, filename);
			}
		}
		
		/**
		 * The handler function that is called when the <code>AWSS3Event.OBJECT_RETRIEVED</code> event
		 * is fired. When the event is fired, the associated <code>S3Object<code> object that was created
		 * for that file is passed through the event's <code>data</code> parameter. The bytes for the file
		 * is stored in the <code>byteArray</code> variable, at which point a Loader object is instantiated
		 * to load the <code>byteArray</code>. When the Loader has finished loading the bytes, a call is made
		 * to <code>getBitmapData</code>.
		 *  
		 * @param event AWSS3Event
		 * 
		 */		
		public function objectRetrievedHandler(event:AWSS3Event):void {
			_tempS3Obj = event.data as S3Object;
			var byteArray:ByteArray = _tempS3Obj.bytes as ByteArray;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, getBitmapData);
			loader.loadBytes(byteArray);
		}	
		
		/**
		 * This method is called in association with the <code>objectRetrievedHandler</code>, and is
		 * responsible for creating a new ImageData object from the S3Object that was passed from
		 * the AWSS3 api.
		 *  
		 * @param event
		 * 
		 */		
		private function getBitmapData(event:Event):void {
			var bmd:BitmapData = Bitmap(event.target.content).bitmapData;
			var imgData:ImageData = new ImageData(_tempS3Obj.key, _tempS3Obj.key, bmd);
			_manager.addImage(imgData);
		}
		
		/**
		 * Handles errors sent back fom AWS.
		 *  
		 * @param event
		 * 
		 */		
		public function awsErrorHandler(event:AWSS3Event):void {
			var data:String = event.data as String;
			trace("ERROR: " + data);
		}
		
	  	/**
	  	 * Determines if an image object has been dragged over accepting canvas area. 
	  	 * @param px
	  	 * @param py
	  	 * @return 
	  	 * 
	  	 */		
	  	public function dragOverCanvas( px:Number, py:Number ):Boolean {
             return ( ( px > canvas.x && px < canvas.x + canvas.width ) &&
                  ( py > canvas.y && py < canvas.y + canvas.height ) );
        }
		
        /**
         * Writes the temp file bitmap data to a file and returns the File object.
         * 
         * @return File 
         * 
         */		
        private function getBitmapFile():File  {
            _tempFile = _tempDir.resolvePath( _currentImage.name );
            var fileStream:FileStream = new FileStream();
            fileStream.open( _tempFile, FileMode.WRITE );
            fileStream.writeBytes(getEncodedBitmap(_currentImage.bitmapData));
            fileStream.close();
            return _tempFile;
        }
		
        /**
         * Finds the center point of the bitmap being dragged and returns that Point.
         * 
         * @param bmp BitmapData
         * @return Point
         * 
         */		
        public function getDragPoint( bmp:BitmapData ):Point {
            return new Point( -bmp.width / 2, -bmp.height / 2 );
        }

        /**
         * When the initial drag starts from the file system, we must tell the application
         * to allow our <code>ImageBrowser</code> container to accept the drop.
         * 
         * @param evt NativeDragEvent
         * 
         */		
        public function onDragEnter( evt:NativeDragEvent ):void {
            NativeDragManager.acceptDragDrop( this._browser );
        }
		
        /**
         * This method is called only when copying to another location
         * outside of the application is complete.
         * 
         * @param evt NativeDragEvent
         * 
         */		
        public function onDragComplete( evt:NativeDragEvent ):void {
            _dragCopy = false;
            if( _tempFile.exists ) _tempFile.deleteFile();
        }

        /**
         * This method gets the bitmap data for each image that was dropped into the browser and
         * adds the new files to the collection. It then makes the call to <code>postFilesToBucket</code> 
         * which is responsible for uploading the respective files.
         * 
         * @param evt NativeDragEvent
         * 
         */		
        public function onDragDrop( evt:NativeDragEvent ):void {
            if( _dragCopy ) return;
            NativeDragManager.dropAction = "copy";
            var files:Array = evt.clipboard.getData( ClipboardFormats.FILE_LIST_FORMAT ) as Array;
            var ac:ArrayCollection = new ArrayCollection(files);
            browser.addFiles(files, dragOverCanvas( evt.localX, evt.localY ));
            postFilesToBucket(ac);
        }
		
		/**
		 * Instantiates the PolicyFactory class, and iterates the <code>ArrayCollection</code> of files that
		 * were dropped onto the browser. It uploads the files by first instantiating a FileReference object
		 * for each File in the array collection, then it creates a <code>S3PostOptions</code> objects to hold
		 * the necessary parameters for S3 to accept the upload. The respective policy and signature are generated
		 * by the <code>PolicyFactory</code> class, and finally the call to <code>S3PostRequest.upload</code> is made
		 * with the FileReference passed in as a parameter.
		 * 
		 * @param files ArrayCollection
		 * 
		 */		
		public function postFilesToBucket(files:ArrayCollection):void {
			var policyFactory:PolicyFactory = new PolicyFactory();
			for each(var f:Object in files) {
				var file:FileReference = f as FileReference;
				var key:String = file.name;
				var date:Date = new Date();
				var dateString:String = _awsAPI.getDateString(date);
				var options:S3PostOptions = new S3PostOptions();
				options.acl = "authenticated-read";
				options.contentType = "image/jpg";
				options.policy = policyFactory.generatePolicy(_bucket,key,_accessId,secretKey);
				options.signature = policyFactory.signPolicy(options.policy, this._secretKey);
				var post:S3PostRequest = new S3PostRequest(this._accessId, this._bucket, key, options);
				post.upload(file);
			}
		}
	
        /**
         * Called when a new thumbnail is selected from the horizontal list contained in the file browser.
         * The newly selected image is cloned and the new <code>ImageData</code> object is passed to the
         * <code>ImageCanvas</code> for display in the main image viewing area of the application.
         *  
         * @param evt Event
         * 
         */  		
        public function onThumbnailSelect( evt:Event ):void  {
            _currentImage = browser.selectedImage.clone();
            canvas.imageData = _currentImage;
        }
		
        /**
         * Called when an image is dropped onto the ImageCanvas instead of the ImageBrowser.  
         * 
         * @param evt Event
         * 
         */		
        public function onImageCanvasDragCopy( evt:Event ):void  {
            _dragCopy = true;
            var transfer:Clipboard = new Clipboard();
            transfer.setData( ClipboardFormats.FILE_LIST_FORMAT, [getBitmapFile()], false );
            var thumb:BitmapData = BitmapUtil.generateThumbnail( _currentImage.bitmapData, DRAG_WIDTH, DRAG_HEIGHT,true );
            NativeDragManager.dropAction = "copy";
            NativeDragManager.doDrag( this._canvas, transfer, thumb, getDragPoint( thumb ) );
        }
        
        /**
         * Takes a BitmapData object and encodes it as either a jpg or png file and returns the ByteArray.
         *  
         * @param bmp BitmapData
         * @return ByteArray
         * 
         */        
        public function getEncodedBitmap( bmp:BitmapData ):ByteArray {
            var encoder:IImageEncoder;
            switch( _currentImage.fileExtension )  {
                case ".jpg":
                case ".jpeg":
                    encoder = new JPEGEncoder();
                    break;
                case ".png":
                    encoder = new PNGEncoder();
                    break;
            }
            return encoder.encode( bmp );
        }

        /**
         * Convenience method for garbage collection on application shutdown. 
         * 
         */ 		
        public function onAppClosing():void {
            GalleryDataManager.getInstance().clean();
            if( _currentImage != null ) _currentImage.clean();
            _tempDir.deleteDirectory( true );
        }
	
	}
}

class SingletonEnforcer{}
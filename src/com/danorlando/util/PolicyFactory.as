package com.danorlando.util
{
	import com.hurlant.crypto.hash.HMAC;
	import com.hurlant.crypto.hash.SHA1;
	import com.hurlant.util.Base64;
	import flash.utils.ByteArray;
	
	/**
	 * The <code>PolicyFactory</code> implements the Factory Method design pattern 
	 * and is responsible for generating the policy and signature for POST requests to S3. 
	 * Aside from the constructor, there are only 2 public methods available from this class;
	 * thus they are the only 2 methods you will ever need: <code>generatePolicy</code generates
	 * the policy "document" and returns it as a string, and <code>signPolicy</code> signs the
	 * policy document with your secret access key to an HMAC-SHA1 encrypted string.
	 * 
	 * @author danorlando
	 * 
	 */
	public class PolicyFactory {
		
		private var _expirationMonth:String = "04";
		private var _expirationDay:String = "01";
		private var _expirationYear:String = "2011";
		private var _accessId:String;
		private var _secretKey:String;
		private var _contentType:String = "image/jpg";
		private var _acl:String = "authenticated-read";
		private var _key:String;
		private var _bucket:String;
		private var _unsignedPolicy:String;
		private var _base64policy:String;
		private var _signature:String;
				
		public function PolicyFactory() {
			 _expirationYear = new Date().getFullYear().toString();
		}
		
        /**
         * Generates the Base64 policy document for S3 POST requests.
         * 
         * @param bucket The destination bucket that the file will be uploaded to.
         * @param key The file name.
         * @param accessId The public access key for the account.
         * @param secretKey The private access key for the account.
         * 
         * @return String The Base64 policy document
         * 
         */		
        public function generatePolicy(bucket:String, key:String, accessId:String, secretKey:String):String {
            this._bucket = bucket;
			this._key = key;
			this._secretKey = secretKey;
			this._accessId = accessId;
			 
            var buffer:Array = new Array();
            buffer.indents = 0;
            
            write(buffer, "{\n");
            indent(buffer);
            
                // expiration
                var mm:String = _expirationMonth;
                var dd:String = _expirationDay;
                var yyyy:String = _expirationYear;
              
                write(buffer, "'expiration': '");
                write(buffer, yyyy);
                write(buffer, "-");
                write(buffer, mm);
                write(buffer, "-");
                write(buffer, dd);
                write(buffer, "T12:00:00.000Z'");
                write(buffer, ",\n");
                
                // conditions
                write(buffer, "'conditions': [\n");
                indent(buffer);
                
                writeSimpleCondition(buffer, "bucket", _bucket, true);
                writeSimpleCondition(buffer, "key", _key, true);
                writeSimpleCondition(buffer, "acl", _acl, true);
                writeSimpleCondition(buffer, "Content-Type", _contentType, true);

                // Warning: Do NOT remove this condition!
                writeCondition(buffer, "starts-with", "$Filename", "", true);
               
                // Warning: Do NOT remove this condition!  
                writeCondition(buffer, "eq", "$success_action_status", "201", false);
                    
                write(buffer, "\n");
                outdent(buffer);
                write(buffer, "]");
                
            write(buffer, "\n");
            outdent(buffer);
            write(buffer, "}");
            
            _unsignedPolicy = buffer.join("");
            _base64policy = Base64.encode(_unsignedPolicy);
            return _base64policy;
        }
        
        private function write(buffer:Array, value:String):void {
            if(buffer.length > 0) {
                var lastPush:String =  String(buffer[buffer.length-1]);
                if(lastPush.length && lastPush.charAt(lastPush.length - 1) == "\n") {
                    writeIndents(buffer);
                }
            }
            buffer.push(value);
        }
        
        private function indent(buffer:Array):void {
            buffer.indents++;
        }
        
        private function outdent(buffer:Array):void {
            buffer.indents = Math.max(0, buffer.indents-1);
        }
        
        private function writeIndents(buffer:Array):void {
            for(var i:int=0;i<buffer.indents;i++) {
                buffer.push("    ");
            }
        }
        
        private function writeCondition(buffer:Array, type:String, name:String, value:String, commaNewLine:Boolean):void {
            write(buffer, "['");
                write(buffer, type);
            write(buffer, "', '");
                write(buffer, name);
            write(buffer, "', '");
                write(buffer, value);
            write(buffer, "'");
            write(buffer, "]");
            if(commaNewLine) {
                write(buffer, ",\n");
            }
            
        }
        
        private function writeSimpleCondition(buffer:Array, name:String, value:String, commaNewLine:Boolean):void {
            write(buffer, "{'");
                write(buffer, name);
            write(buffer, "': ");
            write(buffer, "'");
                write(buffer, value);
            write(buffer, "'");
            write(buffer, "}");
            if(commaNewLine) {
                write(buffer, ",\n");
            }
        }
        
        /**
         * Signs the policy with the private key for the account 
         * 
         * @param policy
         * @param secretKey
         * @return String Signature
         * 
         */        
        public function signPolicy(policy:String, secretKey:String):String { 
            _signature = generateSignature(policy, secretKey);
            return _signature;
        }
        
        private function generateSignature(data:String, secretKey:String):String {
            
            var secretKeyByteArray:ByteArray = new ByteArray();
            secretKeyByteArray.writeUTFBytes(secretKey);
            secretKeyByteArray.position = 0;
            
            var dataByteArray:ByteArray = new ByteArray();
            dataByteArray.writeUTFBytes(data);
            dataByteArray.position = 0;
            
            var hmac:HMAC = new HMAC(new SHA1());            
            var signatureByteArray:ByteArray = hmac.compute(secretKeyByteArray, dataByteArray);
            return Base64.encodeByteArray(signatureByteArray);
        }
        
            
	}
}
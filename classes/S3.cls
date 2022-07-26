/*
Copyright (c) 2008 salesforce.com, inc.
All rights reserved.
	
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
	 notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
	 notice, this list of conditions and the following disclaimer in the
	 documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
	 derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
public class S3 {
	public class ListBucketResponse_element {
		public S3.ListBucketResult ListBucketResponse;
		private String[] ListBucketResponse_type_info = new String[]{'ListBucketResponse','http://s3.amazonaws.com/doc/2006-03-01/','ListBucketResult','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'ListBucketResponse'};
	}

	public class ListBucketResult {
		public S3.MetadataEntry[] Metadata { get; set; }
		public String Name {get;set;} //added by davidv
		public String Prefix;
		public String Marker;
		public String NextMarker;
		public Integer MaxKeys;
		public String Delimiter;
		public Boolean IsTruncated;
		public S3.ListEntry[] Contents;
		public S3.PrefixEntry[] CommonPrefixes;
		private String[] Metadata_type_info = new String[]{'Metadata','http://s3.amazonaws.com/doc/2006-03-01/','MetadataEntry','0','-1','false'};
		private String[] Name_type_info = new String[]{'Name','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Prefix_type_info = new String[]{'Prefix','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Marker_type_info = new String[]{'Marker','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] NextMarker_type_info = new String[]{'NextMarker','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] MaxKeys_type_info = new String[]{'MaxKeys','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
		private String[] Delimiter_type_info = new String[]{'Delimiter','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] IsTruncated_type_info = new String[]{'IsTruncated','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
		private String[] Contents_type_info = new String[]{'Contents','http://s3.amazonaws.com/doc/2006-03-01/','ListEntry','0','-1','false'};
		private String[] CommonPrefixes_type_info = new String[]{'CommonPrefixes','http://s3.amazonaws.com/doc/2006-03-01/','PrefixEntry','0','-1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Metadata','Name','Prefix','Marker','NextMarker','MaxKeys','Delimiter','IsTruncated','Contents','CommonPrefixes'};
	}
		
	public class ListAllMyBucketsList {
		public S3.ListAllMyBucketsEntry[] Bucket {get;set;}
		private String[] Bucket_type_info = new String[]{'Bucket','http://s3.amazonaws.com/doc/2006-03-01/','ListAllMyBucketsEntry','0','-1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Bucket'};
	}
		
		
	public class MetadataEntry {
		public String Name {get; set;}
		public String Value;
		private String[] Name_type_info = new String[]{'Name','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Value_type_info = new String[]{'Value','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Name','Value'};
	}

	public class AmazonS3 {
		public AmazonS3(String key, String secret){
				this.key = key;
				this.secret= secret;    
		}
		
		public AmazonS3(){
			
		}
			
		public string signature( string op, Datetime now) {
			//format should be  2006-01-01T12:00:00.000Z
			system.assert( this.secret != null ,' missing S3.secret key');
			String formattednow = now.formatGmt('yyyy-MM-dd')+'T'+now.formatGmt('HH:mm:ss')+'.'+now.formatGMT('SSS')+'Z';           
			String canonical = 'AmazonS3'+op+formattednow; //"AmazonS3" + OPERATION + Timestamp              
			Blob bsig = Crypto.generateMac('HmacSHA1', Blob.valueOf(canonical), Blob.valueOf(this.secret));          
			return EncodingUtil.base64Encode(bsig); 
		}
		
		public string Authorization_Signature(string op, string contentType, string now, string resource) {
			String canonical = '';
			canonical += op + '\n';
			canonical += '\n';  //Content-Md5
			canonical += contentType + '\n';  //ContentType
			canonical += now + '\n';
			canonical += resource;
			//Blob bsig = Crypto.generateMac('HmacSHA1', Blob.valueOf(EncodingUtil.urlEncode(canonical, 'UTF-8')), Blob.valueOf(this.secret));
			Blob bsig = Crypto.generateMac('HmacSHA1', Blob.valueOf(canonical), Blob.valueOf(this.secret));
			return 'AWS ' + this.key + ':' + EncodingUtil.base64Encode(bsig);
		}
		
		public string secret { get; set; }
		public string key { get; set; }
		public String endpoint_x = 'https://s3.amazonaws.com/soap';
		public Map<String,String> inputHttpHeaders_x;
		public Map<String,String> outputHttpHeaders_x;
		public String clientCert_x;
		public String clientCertPasswd_x;
		private String[] ns_map_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/', 'S3'};

		/*
			 This method invokes the S3 ListAllMyBuckets web service operation.
		*/
		public S3.ListAllMyBucketsResult ListAllMyBuckets(String AWSAccessKeyId,DateTime Timestamp,String Signature) {
			S3.ListAllMyBuckets_element request_x = new S3.ListAllMyBuckets_element();
			S3.ListAllMyBucketsResponse_element response_x;
			request_x.AWSAccessKeyId = AWSAccessKeyId;
			request_x.Timestamp = Timestamp;
			request_x.Signature = Signature;
			Map<String, S3.ListAllMyBucketsResponse_element> response_map_x = new Map<String, S3.ListAllMyBucketsResponse_element>();
			response_map_x.put('response_x', response_x);
			if(!Test.isRunningTest()){
				WebServiceCallout.invoke(
					this,
					request_x,
					response_map_x,
					new String[]{endpoint_x,
					'',
					'http://s3.amazonaws.com/doc/2006-03-01/',
					'ListAllMyBuckets',
					'http://s3.amazonaws.com/doc/2006-03-01/',
					'ListAllMyBucketsResponse',
					'S3.ListAllMyBucketsResponse_element'}
				);
				response_x = response_map_x.get('response_x');
			} else {
				return new S3.ListAllMyBucketsResult();
			}
			
			return response_x.ListAllMyBucketsResponse;
		}
				
		/*
			 This method invokes the S3 CreateBucket web service operation.
		*/
		public S3.CreateBucketResult CreateBucket(String Bucket,S3.AccessControlList AccessControlList,String AWSAccessKeyId,DateTime Timestamp,String Signature) {
			S3.CreateBucket_element request_x = new S3.CreateBucket_element();
			S3.CreateBucketResponse_element response_x;
			request_x.Bucket = Bucket;
			request_x.AccessControlList = AccessControlList;
			request_x.AWSAccessKeyId = AWSAccessKeyId;
			request_x.Timestamp = Timestamp;
			request_x.Signature = Signature;
			Map<String, S3.CreateBucketResponse_element> response_map_x = new Map<String, S3.CreateBucketResponse_element>();
			response_map_x.put('response_x', response_x);
			if(!Test.isRunningTest()){
				WebServiceCallout.invoke(
					this,
					request_x,
					response_map_x,
					new String[]{endpoint_x,
					'',
					'http://s3.amazonaws.com/doc/2006-03-01/',
					'CreateBucket',
					'http://s3.amazonaws.com/doc/2006-03-01/',
					'CreateBucketResponse',
					'S3.CreateBucketResponse_element'}
				);
				response_x = response_map_x.get('response_x');
			} else {
				return new S3.CreateBucketResult();
			}
			
			return response_x.CreateBucketResponse;
		}

		/*
			This method uses the S3 REST API to upload an object to the specified bucket and apply an Access Policy.  
		*/
		public Boolean REST_PutObject_ACL(String Bucket,
												String Key,
												S3.MetadataEntry[] Metadata,
												String Data,
												Integer ContentLength,
												String accessType,
												String AWSAccessKeyId,
												DateTime Timestamp,
												String Credential, 
												String canonicalUserId ){
												
			S3RESTRequest S3RR =  new S3RESTRequest();
			
			string formatdatenow = Timestamp.formatGmt('EEE, dd MMM yyyy HH:mm:ss Z');
			system.debug('formatdatenow: ' + formatdatenow);
			string formatedKey = Key.replace(' ', '%20');
			string formatedResource = '/' + Bucket + '/' + formatedKey;
			string authorization = Authorization_Signature('PUT', 'application/pdf', formatdatenow, formatedResource);
			
			system.debug('authorization:: ' + authorization);
			
			S3RR.request.setEndpoint('https://s3.amazonaws.com' + formatedResource);
			S3RR.request.setMethod('PUT');
			
			S3RR.request.setHeader('Content-Type', 'application/pdf' );
			S3RR.request.setHeader('Content-Length', String.valueOf(ContentLength));
			S3RR.request.setHeader('Connection','close');
			
			
			S3RR.request.setHeader('Date', formatdatenow);
			S3RR.request.setHeader('Authorization', authorization);
			
			Blob original = EncodingUtil.base64Decode(Data);
			S3RR.request.setBodyasBlob(original);
			
				
			try {
				HttpResponse response = S3RR.makeRequest();
				if(response == null){
					return false;
				} else if(response.getStatusCode() != 200){
					return false;
				} else{
					return true;
				}
			} catch(Exception e) {
				system.debug('Failure, returning false');
			}

			return false;
		}
	}

	public class ListAllMyBucketsEntry {
		public String Name { get; set; }
		public DateTime CreationDate;
		private String[] Name_type_info = new String[]{'Name','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] CreationDate_type_info = new String[]{'CreationDate','http://www.w3.org/2001/XMLSchema','dateTime','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Name','CreationDate'};
	}

	public class CreateBucketResult {
		public String BucketName;
		private String[] BucketName_type_info = new String[]{'BucketName','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'BucketName'};
	}

	public class ListEntry {
		public String Key {get;set;}
		public DateTime LastModified {get;set;}
		public String ETag {get;set;}
		public Double Size {get;set;}
		public S3.CanonicalUser Owner {get;set;}
		public String StorageClass {get;set;}
		private String[] Key_type_info = new String[]{'Key','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] LastModified_type_info = new String[]{'LastModified','http://www.w3.org/2001/XMLSchema','dateTime','1','1','false'};
		private String[] ETag_type_info = new String[]{'ETag','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Size_type_info = new String[]{'Size','http://www.w3.org/2001/XMLSchema','long','1','1','false'};
		private String[] Owner_type_info = new String[]{'Owner','http://s3.amazonaws.com/doc/2006-03-01/','CanonicalUser','0','1','false'};
		private String[] StorageClass_type_info = new String[]{'StorageClass','http://s3.amazonaws.com/doc/2006-03-01/','StorageClass','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Key','LastModified','ETag','Size','Owner','StorageClass'};
	}

	public class ListAllMyBucketsResult {
		public S3.CanonicalUser Owner;
		public S3.ListAllMyBucketsList Buckets { get; set; }
		private String[] Owner_type_info = new String[]{'Owner','http://s3.amazonaws.com/doc/2006-03-01/','CanonicalUser','1','1','false'};
		private String[] Buckets_type_info = new String[]{'Buckets','http://s3.amazonaws.com/doc/2006-03-01/','ListAllMyBucketsList','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Owner','Buckets'};
	}

	public class ListAllMyBucketsResponse_element {
		public S3.ListAllMyBucketsResult ListAllMyBucketsResponse;
		private String[] ListAllMyBucketsResponse_type_info = new String[]{'ListAllMyBucketsResponse','http://s3.amazonaws.com/doc/2006-03-01/','ListAllMyBucketsResult','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'ListAllMyBucketsResponse'};
	}
		
	public class CreateBucketResponse_element {
		public S3.CreateBucketResult CreateBucketResponse;
		private String[] CreateBucketResponse_type_info = new String[]{'CreateBucketResponse','http://s3.amazonaws.com/doc/2006-03-01/','CreateBucketResponse','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'CreateBucketResonse'};
	}
		
	public class PrefixEntry {
		public String Prefix;
		private String[] Prefix_type_info = new String[]{'Prefix','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Prefix'};
	}

	public class ListAllMyBuckets_element {
		public String AWSAccessKeyId;
		public DateTime Timestamp;
		public String Signature;
		private String[] AWSAccessKeyId_type_info = new String[]{'AWSAccessKeyId','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Timestamp_type_info = new String[]{'Timestamp','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
		private String[] Signature_type_info = new String[]{'Signature','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'AWSAccessKeyId','Timestamp','Signature'};
	}

	public class PutObjectResult {
		public String ETag;
		public DateTime LastModified;
		private String[] ETag_type_info = new String[]{'ETag','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] LastModified_type_info = new String[]{'LastModified','http://www.w3.org/2001/XMLSchema','dateTime','1','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'ETag','LastModified'};
	}
	public class AccessControlList {
		private String[] Grant_type_info = new String[]{'Grant','http://s3.amazonaws.com/doc/2006-03-01/','Grant','0','100','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Grant'};
	}
	
	public class CanonicalUser {
		public String ID;
		public String DisplayName;
		private String[] ID_type_info = new String[]{'ID','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] DisplayName_type_info = new String[]{'DisplayName','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'ID','DisplayName'};
	}
		
	public class ListBucket_element {
		public String Bucket;
		public String Prefix;
		public String Marker;
		public Integer MaxKeys;
		public String Delimiter;
		public String AWSAccessKeyId;
		public DateTime Timestamp;
		public String Signature;
		public String Credential;
		private String[] Bucket_type_info = new String[]{'Bucket','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Prefix_type_info = new String[]{'Prefix','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Marker_type_info = new String[]{'Marker','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] MaxKeys_type_info = new String[]{'MaxKeys','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
		private String[] Delimiter_type_info = new String[]{'Delimiter','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] AWSAccessKeyId_type_info = new String[]{'AWSAccessKeyId','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Timestamp_type_info = new String[]{'Timestamp','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
		private String[] Signature_type_info = new String[]{'Signature','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Credential_type_info = new String[]{'Credential','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Bucket','Prefix','Marker','MaxKeys','Delimiter','AWSAccessKeyId','Timestamp','Signature','Credential'};
	}

	public class PutObjectInline_element {
		public String Bucket;
		public String Key;
		public S3.MetadataEntry[] Metadata;
		public String Data;
		public Integer ContentLength;
		public S3.AccessControlList AccessControlList;
		public String StorageClass;
		public String AWSAccessKeyId;
		public DateTime Timestamp;
		public String Signature;
		public String Credential;
		private String[] Bucket_type_info = new String[]{'Bucket','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Key_type_info = new String[]{'Key','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] Metadata_type_info = new String[]{'Metadata','http://s3.amazonaws.com/doc/2006-03-01/','MetadataEntry','0','100','false'};
		private String[] Data_type_info = new String[]{'Data','http://www.w3.org/2001/XMLSchema','base64Binary','1','1','false'};
		private String[] ContentLength_type_info = new String[]{'ContentLength','http://www.w3.org/2001/XMLSchema','long','1','1','false'};
		private String[] AccessControlList_type_info = new String[]{'AccessControlList','http://s3.amazonaws.com/doc/2006-03-01/','AccessControlList','0','1','false'};
		private String[] StorageClass_type_info = new String[]{'StorageClass','http://s3.amazonaws.com/doc/2006-03-01/','StorageClass','0','1','false'};
		private String[] AWSAccessKeyId_type_info = new String[]{'AWSAccessKeyId','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Timestamp_type_info = new String[]{'Timestamp','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
		private String[] Signature_type_info = new String[]{'Signature','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Credential_type_info = new String[]{'Credential','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Bucket','Key','Metadata','Data','ContentLength','AccessControlList','StorageClass','AWSAccessKeyId','Timestamp','Signature','Credential'};
	}

	public class CreateBucket_element {
		public String Bucket;
		public S3.AccessControlList AccessControlList;
		public String AWSAccessKeyId;
		public DateTime Timestamp;
		public String Signature;
		private String[] Bucket_type_info = new String[]{'Bucket','http://www.w3.org/2001/XMLSchema','string','1','1','false'};
		private String[] AccessControlList_type_info = new String[]{'AccessControlList','http://s3.amazonaws.com/doc/2006-03-01/','AccessControlList','0','1','false'};
		private String[] AWSAccessKeyId_type_info = new String[]{'AWSAccessKeyId','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] Timestamp_type_info = new String[]{'Timestamp','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
		private String[] Signature_type_info = new String[]{'Signature','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
		private String[] apex_schema_type_info = new String[]{'http://s3.amazonaws.com/doc/2006-03-01/','true'};
		private String[] field_order_type_info = new String[]{'Bucket','AccessControlList','AWSAccessKeyId','Timestamp','Signature'};
	}
	
	public class S3RESTRequest {
		public string body {get;set;}
		public HttpRequest request = new HttpRequest();
		transient HttpResponse response = null;
		public string error {get;set;}

		public S3RESTRequest(){
		}
		
		public HttpResponse makeRequest(){
			System.debug('making S3 REST request...: ' + request);
			error = null;
			Http http = new Http();
			if(!Test.isRunningTest()){
				try{
					response = http.send(request);
				} catch(System.CalloutException e){
					system.debug(e);
					response = null;
				}
				
				if(response == null || response.getStatusCode() != 200){
					try{
						response = http.send(request);
					} catch(System.CalloutException e){
						system.debug(e);
						response = null;
					}
				}
			} else {
				response = new HttpResponse();
				response.setStatusCode(200);
			}
			

			if(response != null && response.getStatusCode() == 200){
				System.debug('STATUS:'+response.getStatus());
				System.debug('STATUS_CODE:'+response.getStatusCode());
				System.debug('BODY: '+response.getBody());

				return response;
			} else if(response != null){
				for(String s:response.getHeaderKeys()){
					system.debug(s);
					try{
						system.debug('Header: '+s+'=>'+response.getHeader(s));
					} catch(Exception e){
						//
					}	
				}

				try{
					AWS_XMLDom dom = new AWS_XMLDom( response.getBody() );
					dom.dumpAll();
					if (response.getStatusCode() == 500) {
						string reasonPath = '';  
						AWS_XMLDom.element e = dom.getElementByPath('/.*/Fault') ;
						if ( e!= null ) {
							e.dumpAll();
							error = body + response.getBody();
						} else { 
							system.debug( 'no fault found' ); 
						}
					}
				} catch(Exception e){
					//
				}
				return null;
			} else {
				return null;
			}
		}		
	}
 
	 /* Below are all the test methods required to deploy this apex code and meet the Test Method Code Coverage requirements of the Force.com platform*/
	 public static testmethod void test1() {
	 	Test.startTest();
			s3.ListBucketResponse_element lbre = new s3.ListBucketResponse_element();
			s3.ListBucketResult lbr = new s3.ListBucketResult();
			s3.ListAllMyBucketsList lambl = new s3.ListAllMyBucketsList();
			s3.metadataEntry me = new s3.metadataEntry();
			s3.ListAllMyBucketsEntry lambe = new s3.ListAllMyBucketsEntry();   
			s3.ListAllMyBucketsResult lambr = new s3.ListAllMyBucketsResult();
			s3.CreateBucketResult cbr = new s3.CreateBucketResult();
			s3.listEntry le = new s3.listEntry();
			s3.CanonicalUser co = new s3.CanonicalUser();
			s3.PrefixEntry pe = new s3.PrefixEntry();
			s3.ListAllMyBucketsResponse_element labre = new s3.ListAllMyBucketsResponse_element();
			s3.CreateBucketResponse_element cbre = new s3.CreateBucketResponse_element();
			S3.AmazonS3 sss = new S3.AmazonS3();
		Test.stopTest();
	}

	public static testmethod void test3() {
		Test.startTest();
			S3.AmazonS3 S3 = new S3.AmazonS3();
			S3.secret = '42';
			system.assert( S3.signature('encode',system.now() ) != null);
			S3.ListAllMyBuckets('key',system.now(),'sig');
		Test.stopTest();
	}  
 
	public static testmethod void test4() {
		Test.startTest();
			S3.AmazonS3 S3 = new S3.AmazonS3();
			S3.secret = '42';
			system.assert( S3.signature('encode',system.now() ) != null);
			s3.AccessControlList acl = new s3.AccessControlList();
			S3.CreateBucket('bucket',acl,'key',system.now(),'sig');
		Test.stopTest();
	}  
 
	public static testmethod void test5() {
		Test.startTest();
			S3.AmazonS3 S3 = new S3.AmazonS3();
			S3.secret = '42';
			system.assert( S3.signature('encode',system.now() ) != null);
		Test.stopTest();
	}
		
	public static testmethod void test6(){
		Test.startTest();
			S3.AmazonS3 S3 = new S3.AmazonS3();
			S3.PutObjectInline_element putObjectElem = new S3.PutObjectInline_element();
			putObjectElem.Bucket='test';
			putObjectElem.Key = 'testKey';
			putObjectElem.Metadata = null;
			putObjectElem.Data= 'a';
			putObjectElem.ContentLength = 1;
			putObjectElem.AccessControlList = null;
			putObjectElem.StorageClass='classname';
			putObjectElem.AWSAccessKeyId='asdf';
			putObjectElem.Timestamp = Datetime.now();
			putObjectElem.Signature='test';
			putObjectElem.Credential='test';
		Test.stopTest();
	}
	
	public static testmethod void test7(){
		Test.startTest();
			S3.AmazonS3 S3 = new S3.AmazonS3();
			S3.secret = '42';
			system.assert( S3.signature('encode',system.now() ) != null);
			S3.REST_PutObject_ACL('bucket','key',null,'datatesting',6,'public-read','keyid',System.now(),'sig', 'ownerid');
		Test.stopTest();
	}
}
cd "%~dp0"
openssl dgst -sha256 -sign rsaprikey.pem -out text_id.sig text_id.txt
openssl base64 -in text_id.sig -out text_id.sig_e64


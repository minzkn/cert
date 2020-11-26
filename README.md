# cert

openssl 명령어를 이용한 인증서 생성 script

https://www.minzkn.com/moniwiki/wiki.php/GenerateCertificate

---

우선 openssl 명령이 실행가능한 환경이어야 합니다.

발급하고자 하는 인증서의 상세 기술내용을 rootca.conf 및 host.conf 를 편집하여 내용을 수정합니다.

"cert.sh" script 는 다음과 같은 인자 형식을 사용할 수 있습니다.
<pre>
usage: ./cert.sh {rootca | gen [{name}] | clean}
</pre>

우선 자체서명 최상위 인증서 (Self-signed CA certificate) 파일을 다음의 명령으로 생성합니다.
<pre>
./cert.sh rootca
</pre>
대부분의 입력사항은 rootca.conf 에 기술된 내용이므로 ENTER를 입력합니다.

이제 생성된 rootca로부터 발급인증서를 무한하게 발급할 수 있습니다. 발급을 위해서 다음과 같은 명령을 사용합니다.
<pre>
./cert.sh gen {발급할 인증서 파일명}
</pre>
역시 대부분의 입력사항은 host.conf 에 기술된 내용이므로 ENTER를 입력합니다.


본 script 의 실행에 따라서 생성되는 파일들은 다음과 같습니다.
<pre>
*.key : 개인키 파일 (유출 주의)
*.enc.key : 개인키 암호화된 파일 (유출 주의)
*.csr : 인증서 요청 파일
*.der : DER형식의 인증서 파일
*.pem : PEM형식의 인증서 파일
*.srl : Serial 파일
</pre>

---

참고: "rsyslog 인증서 관련 설치 및 사용법":http://10.0.8.201/issues/74009

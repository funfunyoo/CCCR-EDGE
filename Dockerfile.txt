#base image
FROM ubuntu:18.04

#package 설치
RUN apt-get update

#nginx 설치
RUN apt-get install -y nginx

#작업 디렉터리 설정
WORKDIR /etc/nginx

#외부에서 내부로 접속 시 사용할 포트 번호
EXPOSE 80

#nginx 실행
CMD ["nginx", "-g", "daemon off;"]
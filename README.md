# windows-grafana
Dockerfile and instructions on running grafana on windows server docker.

This is based on this post: https://community.grafana.com/t/docker-image-for-windows-nanoserver/14862


First , build the Docker file:
docker build --build-arg WindowsServerCoreVersion={Version of windows server you are running (1809 etc.)} --build-arg GRAFANA_VERSION={Version of Grafana(6.7.1 etc.)} --build-arg GRAFANA_SHA256={SHA256 of the grafana windows ZIP file (example: bd0980e55627c4d55e85bedc312652451377b56d2fdafcec2ae15050fc71309e)} -t {tag,whatever you want} .

Second , Create two docker volumes:
docker volume create grafana_conf
docker volume create grafana_data

Third, copy the conf directory from the windows zip of grafana to the grafana_conf directory:
copy {extracted zip file path}\* -destination c:\ProgramData\docker\volumes\grafana_conf\_data -Recurse

Fourth, fix permissions on the volume folders:
icacls  C:\ProgramData\docker\volumes\grafana_conf\_data\ /grant "Authenticated Users":(OI)(CI)M
icacls  C:\ProgramData\docker\volumes\grafana_data\_data\ /grant "Authenticated Users":(OI)(CI)M

Fifth, run the container:
docker run -d -p 3000:3000 -v grafana_conf:"c:\Program Files\Grafana\conf" -v grafana_data:"c:\Program Files\Grafana\data" --name grafana --restart always  {Image Name}

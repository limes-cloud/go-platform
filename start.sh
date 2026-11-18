
cd server/configure
nohup go run cmd/configure/main.go &
cd ../

cd gateway
nohup go run cmd/gateway/main.go &
cd ../

cd resource
nohup go run cmd/resource/main.go &
cd ../
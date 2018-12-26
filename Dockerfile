FROM golang
RUN cd /go/src; git clone https://github.com/quii/learn-go-with-tests.git
WORKDIR /go/src/learn-go-with-tests/http-server/v5
ENTRYPOINT ["go", "test", "-v"]

FROM golang:latest
LABEL author="VulnCheck"
LABEL website="https://vulncheck.com"

# build the binary in a subdirectory
WORKDIR /vulncheck

# add all Go files
COPY *.go ./

# add go.sum and go.mod
COPY go.* ./

# add the Makefile
COPY Makefile .

# change working directory and compile
RUN make compile

# mv the compiled binary to a generic name because our generic makefile appends arch info
RUN mv ./build/* ./exploit

# exec <3
ENTRYPOINT ["/vulncheck/exploit"]

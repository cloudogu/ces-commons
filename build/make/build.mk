ADDITIONAL_LDFLAGS?=-extldflags -static
LDFLAGS?=-ldflags "$(ADDITIONAL_LDFLAGS) -X main.Version=$(VERSION) -X main.CommitID=$(COMMIT_ID)"
GOIMAGE?=cloudogu/golang
GOTAG?=1.10.2-2
GOOS?=linux
GOARCH?=amd64
PRE_COMPILE?=

.PHONY: compile
compile: $(BINARY)

compile-generic:
	@echo "Compiling..."
	@go build -a -tags netgo $(LDFLAGS) -installsuffix cgo -o $(BINARY)


ifeq ($(ENVIRONMENT), ci)

$(BINARY): $(SRC) vendor $(PRE_COMPILE)
	@echo "Built on CI server"
	@make compile-generic

else

$(BINARY): $(SRC) vendor $(PASSWD) $(HOME_DIR) $(PRE_COMPILE)
	@echo "Building locally (in Docker)"
	@docker run --rm \
	 -e GOOS=$(GOOS) \
	 -e GOARCH=$(GOARCH) \
	 -u "$(UID_NR):$(GID_NR)" \
	 -v $(PASSWD):/etc/passwd:ro \
	 -v $(HOME_DIR):/home/$(USER) \
	 -v $(WORKDIR):/go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 -w /go/src/github.com/cloudogu/$(ARTIFACT_ID) \
	 $(GOIMAGE):$(GOTAG) \
  make compile-generic

endif
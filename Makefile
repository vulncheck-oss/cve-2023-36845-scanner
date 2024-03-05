# Don't touch this variable
export GO111MODULE := on

# HACK: "Detect" exploit and payload filenames
exploit_files := scan.go
payload_files := $(wildcard *_shell.go)

# Don't touch these variables
exploit_os := $(shell go env GOOS)
exploit_arch := $(shell go env GOARCH)

# NOTE: Don't forget to update these variables
payload_oses := #windows
payload_archs := #amd64

# Output directory for binaries
output_dir := build

# Don't touch this definition
define newline


endef

ifndef exploit_files
$(error You haven't written any exploit code)
endif

all: format lint compile

format:
	gofmt -d -w $(exploit_files) $(payload_files)

lint:
	$(foreach file,$(exploit_files),golangci-lint run --fix $(file)$(newline))
ifneq ($(payload_files),)
	$(foreach file,$(payload_files),golangci-lint run --fix $(file)$(newline))
endif

compile: exploit payload extra

exploit: ext = $(if $(findstring windows,$(exploit_os)),.exe)
exploit:
	$(foreach file,$(exploit_files),\
		$(eval out := $(output_dir)/$(file:.go=)_$(exploit_os)-$(exploit_arch)$(ext))\
			GOOS=$(exploit_os) GOARCH=$(exploit_arch) go build -o $(out) $(file)$(newline))

# Change this value if you need to
payload: export GOARM := 7
payload:
ifneq ($(payload_files),)
	$(foreach file,$(payload_files),\
		$(foreach os,$(payload_oses),\
			$(foreach arch,$(payload_archs),\
				$(eval ext := $(if $(findstring windows,$(os)),.exe))\
				$(eval out := $(output_dir)/$(file:.go=)_$(os)-$(arch)$(ext))\
					GOOS=$(os) GOARCH=$(arch) go build -ldflags "-s -w" -o $(out) $(file)$(newline))))
endif

# Add extra stuff to this recipe
extra:

clean:
	@rm -rfv $(output_dir)

docker:
	@docker build --network=host -t $(notdir $(CURDIR)) .

# make darwin-amd64|darwin-arm64|...
darwin-%:
# HACK: Reinvoke make to pass in vars
	@$(MAKE) --no-print-directory exploit_os=darwin exploit_arch=$*

# make linux-amd64|linux-arm64|...
linux-%:
# HACK: Reinvoke make to pass in vars
	@$(MAKE) --no-print-directory exploit_os=linux exploit_arch=$*

# make windows-amd64|windows-arm64|...
windows-%:
# HACK: Reinvoke make to pass in vars
	@$(MAKE) --no-print-directory exploit_os=windows exploit_arch=$*

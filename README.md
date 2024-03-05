# Vulnerability Scanner for Juniper CVE-2023-36845

This vulnerability scanner can be used to scan Juniper firewalls to determine if they are vulnerable to [CVE-2023-36845](https://nvd.nist.gov/vuln/detail/CVE-2023-36845). Because this is built on top of [go-exploit](https://github.com/vulncheck-oss/go-exploit), this scanner has two phases:

* Target verification to ensure the target is a potentially impacted Juniper firewall.
* Target exploitation in which the scanner sends an `LD_PRELOAD` message to generate a (harmless) error message from vulnerable systems.

For more details on exploiting CVE-2023-36845 see our blog, [Fileless Remote Code Execution on Juniper Firewalls](https://vulncheck.com/blog/juniper-cve-2023-36845/).

## Compiling

You can use the makefile to build a docker container:

```
make docker
```

Or, if you have a Go build environment ready to go, just use `make`:

```sh
albinolobster@mournland:~/cve-2023-36845-scanner$ make
gofmt -d -w scan.go
golangci-lint run --fix scan.go
GOOS=linux GOARCH=arm64 go build -o build/scan_linux-arm64 scan.go
```

## Usage

The tool is built on top of [go-exploit](https://github.com/vulncheck-oss/go-exploit), so there are multipe ways to provide targets to scan. A full description can be found in the project's [scanning documentation](https://github.com/vulncheck-oss/go-exploit/blob/main/docs/scanning.md). However, the following shows some examples:

### Scanning One Host

```sh
$ ./build/scan_linux-arm64 -a -v -e -rhost 10.12.72.1 -log-json=true | jq 'select(.msg == "Vulnerable")'
{
  "time": "2023-09-16T06:18:01.964471183-04:00",
  "level": "SUCCESS",
  "msg": "Vulnerable",
  "vulnerable": true,
  "rhost": "10.12.72.1",
  "rport": 80
}
```

### Scanning Multiple Hosts

```sh
$ ./build/scan_linux-arm64 -a -v -e -rhosts 10.12.72.1,10.12.72.2
time=2023-09-16T06:19:26.592-04:00 level=STATUS msg="Starting target" index=0 host=10.12.72.1 port=80 ssl=false "ssl auto"=true
time=2023-09-16T06:19:36.607-04:00 level=STATUS msg="Validating JunOS Web Interface target" host=10.12.72.1 port=80
time=2023-09-16T06:19:37.528-04:00 level=SUCCESS msg="Target validation succeeded!" host=10.12.72.1 port=80
time=2023-09-16T06:19:37.574-04:00 level=SUCCESS msg=Vulnerable vulnerable=true rhost=10.12.72.1 rport=80
time=2023-09-16T06:19:37.575-04:00 level=STATUS msg="Exploit successfully completed"
time=2023-09-16T06:19:37.575-04:00 level=STATUS msg="Starting target" index=1 host=10.12.72.2 port=80 ssl=false "ssl auto"=true
time=2023-09-16T06:19:37.575-04:00 level=STATUS msg="Validating JunOS Web Interface target" host=10.12.72.2 port=80
time=2023-09-16T06:19:37.576-04:00 level=ERROR msg="The target isn't recognized as JunOS Web Interface, quitting" host=10.12.72.2 port=80
```

### Scanning a File of Hosts Using a Proxy (and logging to file)

go-exploit provides the ability to scan via a provided target csv, where the csv is: `host, port, anything if ssl is enabled` (although the SSL field is ignored if -a is used). Please see the scanning documentation for full details. It also provides the ability to scan through a proxy. The command works like so:

```sh
$ ./build/scan_linux-arm64 -v -e -rhosts-file ~/junos/junos.targets.csv -proxy socks5://127.0.0.1:9050 -log-file vulnscan.json
^C
$ tail vulnscan.json 
time=2023-09-17T05:11:19.256-04:00 level=STATUS msg="Starting target" index=0 host=x port=443 ssl=true "ssl auto"=false
time=2023-09-17T05:11:19.256-04:00 level=STATUS msg="Validating JunOS Web Interface target" host=x port=443
time=2023-09-17T05:11:29.257-04:00 level=ERROR msg="HTTP request error: Get \"https://x:443/\": context deadline exceeded (Client.Timeout exceeded while awaiting headers)"
time=2023-09-17T05:11:29.257-04:00 level=ERROR msg="The target isn't recognized as JunOS Web Interface, quitting" host=x port=443
time=2023-09-17T05:11:29.257-04:00 level=STATUS msg="Starting target" index=1 host=x port=80 ssl=false "ssl auto"=false
time=2023-09-17T05:11:29.257-04:00 level=STATUS msg="Validating JunOS Web Interface target" host=xport=80
```
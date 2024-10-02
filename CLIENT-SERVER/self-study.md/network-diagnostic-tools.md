
# Network Diagnostic Commands in Linux

1. **Ping**
Tests the reachability of a host and measures round-trip time.

Basic Usage:
```sh
ping google.com
```

Limit the Number of Pings:
```sh
ping -c 5 google.com
```

Specify Packet Size:

```sh
ping -s 64 google.com
```
2. **Traceroute**
Maps the path that packets take from your machine to a specified destination.

Basic Usage:

```sh
traceroute google.com
```
3. **Nslookup**
Queries the DNS to obtain domain name or IP address mapping.

Basic Usage:

```sh
nslookup google.com
```

4. **Netstat**
Displays network connections, routing tables, interface statistics, and more.

Basic Usage:

```sh
netstat -tuln
```
5. **Tcpdump**
Captures and analyzes network packets.

Basic Usage:

```sh
tcpdump -i eth0
```
6. **Iperf**
Measures bandwidth between two hosts over TCP or UDP.

Server Mode:

```sh
iperf -s
```
Client Mode:

```sh
iperf -c <server_ip>
```

7. **Dig**
Performs DNS lookups and displays the answers from the name server(s).

Basic Usage:

```sh
dig google.com
```
8. **Nmap**
Network exploration tool and security scanner.

Basic Usage:

```sh
nmap 192.168.1.0/24
```
9. **Curl**
Transfers data using various protocols.

Basic Usage:
```sh
curl https://example.com
```
10. **Ss**
Another utility to investigate sockets.

Basic Usage:
```sh
ss -tuln
```
11. **Hostname**
Displays or sets the system's host name.

Basic Usage:

```sh
hostname
```
12. **Ifconfig / Ip**
Configures network interfaces.

Basic Usage:

```sh
ifconfig
ip addr show
```
13. **Mtr**
Combines the functionality of 'traceroute' and 'ping'.

Basic Usage:

```sh
mtr google.com
```
14. **Wireshark**
Graphical network protocol analyzer (usually needs to be installed).

Basic Usage:

```sh
wireshark
```
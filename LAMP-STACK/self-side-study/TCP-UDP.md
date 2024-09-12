# TCP AND UDP

TCP (Transmission Control Protocol) and UDP (User Datagram Protocol) are both transport layer protocols used for data transmission over networks. They serve different purposes and have distinct characteristics.

### TCP vs. UDP
**TCP (Transmission Control Protocol)**

- **Connection-oriented**: TCP establishes a connection between the sender and receiver before data transmission begins. This ensures that data packets are delivered in order and without errors.
- **Reliability**: TCP guarantees the delivery of data. If packets are lost during transmission, TCP will retransmit them. It also includes mechanisms for error-checking and flow control.
- **Use Cases**: TCP is ideal for applications where reliability and order are critical, such as web browsing (HTTP/HTTPS), email (SMTP, POP3), and file transfers (FTP).

**UDP (User Datagram Protocol)**
- **Connectionless**: UDP does not establish a connection before sending data. It simply sends packets, called datagrams, without ensuring that they reach their destination.
- **Speed**: UDP is faster than TCP because it has lower overhead. It does not wait for acknowledgments or retransmit lost packets.
- **Use Cases**: UDP is suitable for applications where speed is more important than reliability, such as video streaming, online gaming, and voice over IP (VoIP).


### Commonly Used Ports

| Protocol        | Port Number | Description                                  |
|-----------------|-------------|----------------------------------------------|
| HTTP            | 80          | Hypertext Transfer Protol                    |
| HTTPS           | 443         | HTTP secure(SSL/TLS)                         |
| SSH             | 22          | Secure Shell                                 |
| TELNET          | 23          | Telnet (unsecured remote access )            |
| FTP             | 21          | File Transfer Protocol                       |
| SFTP            | 22          | Secure File Trransfer Protocol               |
| SMTP            | 25          | Simple Mail Transfer Protocol                |








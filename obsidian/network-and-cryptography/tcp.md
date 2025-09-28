# Transmission Control Protocol

A Reliable, Connection-Oriented Protocol: TCP's primary goal is to provide a reliable and ordered data stream between two applications. This means it ensures that data arrives correctly (no errors, no lost packets) and in the sequence it was sent.

To establish a TCP connection, the parties complete a 3 part syn -> syn-ack -> ack transmission handshake. Afterwards, message data is split into segments. The segments are each assigned a sequence number, which is used by the receiver to ackowledge receipt of data.

TCP enables more complex application layer communication protocols like HTTP.
![specs](https://github.com/ignacy/stenohttp2/actions/workflows/rspec.yml/badge.svg)


# Steganography in HTTP/2

[http2](https://www.wikiwand.com/en/HTTP/2) felt like a major step forward from http1. Things like connection multiplexing and header compression decreased network load and improved speed for many applications without requiring them to change anything.

But the whole [http/2 RFC](https://datatracker.ietf.org/doc/html/rfc7540) felt like a revolution compared to simpler text like semantics of http/1.

This project implements a hidden channel communication based on http/2 features in an effort to learn more about the protocol.

# Steganography

Steganography is a way of hidding a message in a communication in a way that not only the message is unreadable (by cryptografic measures) but the presence of communication itself is hidden from anyone watching.

# Potential hidden channels in HTTP/2

There are many ways one can go about implementing a hidden channel in http/2, in part this is possible because the protocol is so much more complex than previous version. For a great overview you can read this [paper](https://www.scirp.org/journal/paperinformation.aspx?paperid=75115).

For my implementation I selected [PING frames](https://datatracker.ietf.org/doc/html/rfc7540#section-6.7)


# Technical notes

This project is using Ruby with [http2 gem](https://github.com/igrigorik/http-2).
One interesting aspect is that I used Sorbet for typechecking in most of the places.

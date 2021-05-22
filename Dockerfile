# docker run -it $(docker build . | tail -n 1 | cut -c20-35) /bin/sh
# proxy-delete rust-space; proxy-create rust-space $(docker build . | tail -n 1 | cut -c20-35)

FROM rust:alpine AS bootstrapper
RUN apk --update add git musl-dev ncurses-terminfo-base && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*

RUN git clone https://github.com/uutils/coreutils
RUN cargo install --path=coreutils --root=/prefix/ --debug

RUN git clone https://github.com/hiking90/rushell
RUN cargo install --path=rushell --root=/prefix/ --debug

FROM scratch
# shell
COPY profile /etc/profile
COPY --from=bootstrapper /etc/terminfo /etc/terminfo
COPY --from=bootstrapper /prefix/bin/rushell /bin/sh

# coreutils
COPY --from=bootstrapper /prefix/bin/coreutils /bin/coreutils
RUN /bin/coreutils ln -s /bin/coreutils /bin/ln
RUN ln -s / /usr
RUN ln -s /bin/coreutils /bin/env
RUN ln -s /bin/coreutils /bin/ls

# libc
COPY --from=bootstrapper /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
RUN ln -s /lib/ld-musl-x86_64.so.1 /lib/libc.musl-x86_64.so.1
RUN ln -s /lib/ld-musl-x86_64.so.1 /bin/ldd

CMD ["/bin/sh"]
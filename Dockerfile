# docker build . && docker run -it ${docker build . | tail -n 1 | cut -c20-35} /bin/sh
# docker build . && proxy-delete rust-space; proxy-create rust-space ${docker build . | tail -n 1 | cut -c20-35}
FROM rust:latest AS bootstrapper
#RUN rustup target add x86_64-unknown-linux-musl
#RUN apt update && apt install -y musl-tools

RUN git clone https://github.com/uutils/coreutils
RUN cargo install --path=coreutils --root=/  # --target x86_64-unknown-linux-musl

RUN git clone https://github.com/RustPython/RustPython
RUN cargo install --path=RustPython --root=/ # --target x86_64-unknown-linux-musl

#RUN git clone https://github.com/shawnanastasio/rudo.git
#RUN cargo install --path=rudo --root=/

FROM scratch
# dynamic linker:
copy --from=bootstrapper /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

# libc:
COPY --from=bootstrapper /lib/x86_64-linux-gnu/libc.so.6 /lib/libc.so.6
COPY --from=bootstrapper /lib/x86_64-linux-gnu/libm.so.6 /lib/libm.so.6
COPY --from=bootstrapper /lib/x86_64-linux-gnu/libutil.so.1 /lib/libutil.so.1
copy --from=bootstrapper /lib/x86_64-linux-gnu/libdl.so.2 /lib/libdl.so.2
copy --from=bootstrapper /lib/x86_64-linux-gnu/librt.so.1 /lib/librt.so.1
copy --from=bootstrapper /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/libgcc_s.so.1
copy --from=bootstrapper /lib/x86_64-linux-gnu/libpthread.so.0 /lib/libpthread.so.0

# dash:
COPY profile /etc/profile
COPY --from=bootstrapper /bin/sh /bin/sh

# coreutils:
COPY --from=bootstrapper /bin/uutils /bin/uutils
RUN /bin/uutils ln -s /bin/uutils /bin/ln

# emacs tramp:
RUN ln -s /bin/uutils /bin/env
RUN ln -s /bin/uutils /bin/uname
## coreutils todo:
COPY --from=bootstrapper /bin/stty /bin/stty
## needed for ls:
RUN ln -s /bin/uutils /bin/ls
RUN ln -s /bin/uutils /bin/test
RUN ln -s /bin/uutils /bin/tty
## needed for cp
RUN ln -s /bin/uutils /bin/base64
## needed for compression
COPY --from=bootstrapper /bin/gzip /bin/gzip

# python:
COPY --from=bootstrapper /lib/x86_64-linux-gnu/libz.so.1 /lib/libz.so.1
COPY --from=bootstrapper /bin/rustpython /bin/python

CMD ["/bin/sh"]

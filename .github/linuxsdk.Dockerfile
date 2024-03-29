FROM ubuntu:20.04 as base
LABEL maintainer = "Huaqi Fang <hqfang@nucleisys.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Certificate verification failed: The certificate is NOT trusted. The certificate issuer is unknown.
# https://github.com/tuna/issues/issues/1342
RUN apt update
RUN apt install -y libgnutls30 ca-certificates

# Don't copy source list for github ci build docker
#COPY ubuntu20.04.list /etc/apt/sources.list

RUN apt update && apt upgrade -y

COPY apt.txt /home/

RUN xargs apt install -y < /home/apt.txt

RUN rm -f /home/apt.txt

RUN ln -s /lib/x86_64-linux-gnu/libgmp.so /lib/x86_64-linux-gnu/libgmp.so.3

COPY pipreq.txt /home/

RUN pip3 install -U pip

RUN pip install -r /home/pipreq.txt

RUN rm -f /home/pipreq.txt

# Cleanup apt/pip cache
RUN apt autoclean
RUN apt clean
RUN pip3 cache purge

# create USER with PASS
ARG USER=nuclei
ARG PASS=riscv123
ARG QEMUVER=2023.10
ARG BRANCH=dev_nuclei_next

RUN groupadd --system $USER

RUN useradd -rm -d /home/$USER -s /bin/bash -g $USER -G sudo -u 1001 $USER

RUN echo "$USER:$PASS" | chpasswd

USER $USER

WORKDIR /home/$USER/

RUN mkdir -p prebuilt

RUN wget -q https://nucleisys.com/upload/files/toochain/qemu/nuclei-qemu-$QEMUVER-linux-x64.tar.gz -O prebuilt/nuclei-qemu.tar.gz

RUN cd prebuilt && tar --no-same-owner -xzf nuclei-qemu.tar.gz

ENV PATH "/home/$USER/prebuilt/qemu/bin:$PATH"

RUN ldd `which qemu-system-riscv64`

# do shallow clone for main repo
RUN git clone --depth 5 -b $BRANCH https://github.com/Nuclei-Software/nuclei-linux-sdk

# gitee mirror no longer works
#RUN cd nuclei-linux-sdk && git remote add gitee https://gitee.com/Nuclei-Software/nuclei-linux-sdk

# only do shallow clone for submodule to reduce clone size
RUN cd nuclei-linux-sdk && git submodule init && git submodule update --recursive --init --depth 5

RUN cd nuclei-linux-sdk && make freeloader bootimages

COPY run_qemu.sh /home/$USER

CMD [ "/bin/bash" ]

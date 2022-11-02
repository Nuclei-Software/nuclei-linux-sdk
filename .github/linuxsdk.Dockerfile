FROM ubuntu:20.04 as base
LABEL maintainer = "Huaqi Fang <hqfang@nucleisys.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Certificate verification failed: The certificate is NOT trusted. The certificate issuer is unknown.
# https://github.com/tuna/issues/issues/1342
RUN apt update
RUN apt install -y libgnutls30 ca-certificates

COPY ubuntu20.04.list /etc/apt/sources.list

RUN apt update && apt upgrade -y

RUN apt install -y build-essential git python3 python3-pip autotools-dev make cmake texinfo bison minicom flex \
    liblz4-tool libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler libncursesw5-dev \
    libncursesw5 mtools wget cpio zip unzip rsync bc sudo libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev

RUN apt autoclean

RUN ln -s /lib/x86_64-linux-gnu/libgmp.so /lib/x86_64-linux-gnu/libgmp.so.3

RUN pip install git-archive-all

# create USER with PASS
ARG USER=nuclei
ARG PASS=riscv123

RUN groupadd --system $USER

RUN useradd -rm -d /home/$USER -s /bin/bash -g $USER -G sudo -u 1001 $USER

RUN echo "$USER:$PASS" | chpasswd

USER $USER

WORKDIR /home/$USER/

RUN mkdir -p prebuilt

RUN wget -q https://nucleisys.com/upload/files/toochain/qemu/nuclei-qemu-2022.08-linux-x64.tar.gz -O prebuilt/nuclei-qemu.tar.gz

RUN cd prebuilt && tar --no-same-owner -xzf nuclei-qemu.tar.gz

ENV PATH "/home/$USER/prebuilt/qemu/bin:$PATH"

RUN git clone https://github.com/Nuclei-Software/nuclei-linux-sdk

RUN cd nuclei-linux-sdk && git remote add gitee https://gitee.com/Nuclei-Software/nuclei-linux-sdk

RUN cd nuclei-linux-sdk && git submodule init && git submodule update --recursive --init

RUN cd nuclei-linux-sdk && make freeloader bootimages

CMD [ "/bin/bash" ]

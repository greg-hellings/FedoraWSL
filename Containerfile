FROM fedora:34

RUN dnf -y install 'dnf-command(copr)' passwd sudo && \
    dnf -y copr enable trustywolf/wslu && \
    dnf -y install wslu && \
    dnf clean all

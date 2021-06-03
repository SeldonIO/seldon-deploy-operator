ARG VERSION
# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.7.2
ARG VERSION
LABEL name="Seldon Deploy Operator" \
      vendor="Seldon Technologies" \
      version=$VERSION \
      release=$VERSION \
      summary="Seldon Deploy Operator" \
      description="Helm-based Operator for installing Seldon Deploy."
COPY deployenterpriselicense.txt /licenses/license.txt

USER root
RUN microdnf --setopt=install_weak_deps=0 install yum \
         && yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical \
         && yum clean all \
         && microdnf remove yum \
         && microdnf clean all
USER helm

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}

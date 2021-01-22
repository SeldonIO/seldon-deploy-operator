ARG VERSION
# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.3.0
ARG VERSION
LABEL name="Seldon Deploy Operator" \
      vendor="Seldon Technologies" \
      version=$VERSION \
      release=$VERSION \
      summary="Seldon Deploy Operator" \
      description="Helm-based Operator for installing Seldon Deploy."
COPY deployenterpriselicense.txt /licenses/license.txt

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts  ${HOME}/helm-charts
WORKDIR ${HOME}

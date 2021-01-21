ARG VERSION
FROM seldonio/seldon-core-s2i-python37-ubi8:$VERSION
ARG VERSION
LABEL name="Seldon Batch Processor" \
      vendor="Seldon Technologies" \
      version=$VERSION \
      release=$VERSION \
      summary="Seldon Batch Processor" \
      description="Image used for processing seldon batch jobs."
COPY apache2license.txt licenses/license.txt
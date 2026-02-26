FROM cgr.dev/chainguard/wolfi-base:latest

COPY ./headless.sh /tmp/headless.sh
RUN sed -i 's/\r$//' /tmp/headless.sh && \
  mv /tmp/headless.sh /usr/bin/soffice && \
  chmod +x /usr/bin/soffice

ENV NO_UPDATE_NOTIFIER=true \
  PATH="/usr/lib/libreoffice/program:${PATH}"

RUN apk add --no-cache \
    openjdk-17 \
    libreoffice \
    ttf-dejavu \
    fontconfig \
    && fc-cache -fv && \
    rm -rf /var/cache/apk/*

RUN apk --no-cache add msttcorefonts-installer fontconfig && \
  update-ms-fonts && \
  fc-cache -f && \
  rm -rf /var/cache/apk/*

RUN mkdir -p /app && \
  chgrp  -R 0 /app && \
  chmod -R g=u /app && \
  chmod 777 /app

RUN chmod 1777 /tmp

ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
  PATH=$PATH:/usr/lib/jvm/java-17-openjdk \
  HOME=/tmp \
  SAL_NO_X11=1 \
  SAL_USE_VCLPLUGIN=svp \
  DISPLAY= 

WORKDIR /app

RUN apk add --no-cache shadow

RUN echo "=== Test 1. As root ===" && \
  mkdir -p /tmp/.config-root && \
  echo "test" > /app/test-root.txt && \
  soffice -env:UserInstallation=file:///tmp/.config-root \
  --convert-to pdf --outdir /app /app/test-root.txt && \
  echo "Root conversion ok" && \
  rm -rf /app/test-root.* /tmp/.config-root


RUN useradd -u 1000 -g 0 test1000 && \
  echo "=== Test 2. As UID 1000 ===" && \
  su test1000 -c "mkdir -p /tmp/.config-1000" && \
  su test1000 -c "echo 'test 1000' > /app/test-1000.txt" && \
  su test1000 -c "soffice -env:UserInstallation=file:///tmp/.config-1000 --convert-to pdf --outdir /app /app/test-1000.txt" && \
  echo "1000 conversion ok" && \
  rm -rf /app/test-1000.* /tmp/.config-1000

RUN useradd -u 1001 -g 0 test1001 && \
  echo "=== Test 2. As UID 1001 ===" && \
  su test1001 -c "mkdir -p /tmp/.config-1001" && \
  su test1001 -c "echo 'test 1001' > /app/test-1001.txt" && \
  su test1001 -c "soffice -env:UserInstallation=file:///tmp/.config-1001 --convert-to pdf --outdir /app /app/test-1001.txt" && \
  echo "1001 conversion ok" && \
  rm -rf /app/test-1001.* /tmp/.config-1001

RUN apk del shadow && rm -rf /var/cache/apk/*

RUN rm -rf /tmp/.config-*

ENTRYPOINT ["java", \
"-XX:+UseZGC", \
"-XX:InitialRAMPercentage=50.0",\
"-XX:MaxRAMPercentage=80.0",\
"-Djava.awt.headless=true",\
"-Dquarkus.http.host=0.0.0.0",\
"-jar"]

CMD ["app.jar"]

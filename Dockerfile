FROM cgr.dev/chainguard/wolfi-base:latest

COPY ./headless.sh /tmp/headless.sh
RUN sed -i 's/\r$//' /tmp/headless.sh && \
  mv /tmp/headless.sh /usr/bin/soffice && \
  chmod +x /usr/bin/soffice

ENV NO_UPDATE_NOTIFIER=true \
  PATH="/usr/lib/libreoffice/program:${PATH}" \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  JAVA_HOME=/usr/lib/jvm/java-25-openjdk \
  HOME=/tmp \
  SAL_NO_X11=1 \
  SAL_USE_VCLPLUGIN=svp \
  DISPLAY= 

ENV PATH="${PATH}:/usr/lib/jvm/java-25-openjdk/bin"

RUN apk update && apk upgrade --no-cache && \
  apk add --no-cache \
  openjdk-25 \
  libreoffice \
  ttf-dejavu \
  fontconfig \
  msttcorefonts-installer \
  shadow && \
  update-ms-fonts && \
  fc-cache -fv && \
  apk del msttcorefonts-installer py3-pip shadow || true && \
  rm -rf /var/cache/apk/* /tmp/*

RUN mkdir -p /app && \
  chgrp -R 0 /app && \
  chmod -R g=u /app && \
  chmod 777 /app && \
  chmod 1777 /tmp

WORKDIR /app

RUN soffice --headless --version && echo "LibreOffice check version OK"
RUN java -version && echo "Java OK"

RUN echo "=== Test 1. As root ===" && \
  mkdir -p /tmp/.config-root && \
  echo "test" > /app/test-root.txt && \
  soffice -env:UserInstallation=file:///tmp/.config-root \
  --convert-to pdf --outdir /app /app/test-root.txt && \
  echo "Root conversion ok" && \
  rm -rf /app/test-root.* /tmp/.config-root

RUN apk add --no-cache shadow && \
  useradd -u 1000 -g 0 test1000 && \
  echo "=== Test 2. As UID 1000 ===" && \
  su test1000 -c "mkdir -p /tmp/.config-1000" && \
  su test1000 -c "echo 'test 1000' > /app/test-1000.txt" && \
  su test1000 -c "soffice -env:UserInstallation=file:///tmp/.config-1000 --convert-to pdf --outdir /app /app/test-1000.txt" && \
  echo "1000 conversion ok" && \
  rm -rf /app/test-1000.* /tmp/.config-1000 && \
  userdel test1000 && \
  \
  useradd -u 1001 -g 0 test1001 && \
  echo "=== Test 3. As UID 1001 ===" && \
  su test1001 -c "mkdir -p /tmp/.config-1001" && \
  su test1001 -c "echo 'test 1001' > /app/test-1001.txt" && \
  su test1001 -c "soffice -env:UserInstallation=file:///tmp/.config-1001 --convert-to pdf --outdir /app /app/test-1001.txt" && \
  echo "1001 conversion ok" && \
  rm -rf /app/test-1001.* /tmp/.config-1001 && \
  userdel test1001 && \
  apk del shadow && \
  rm -rf /var/cache/apk/*

ENTRYPOINT ["java", \
  "-XX:+UseZGC", \
  "-XX:InitialRAMPercentage=50.0",\
  "-XX:MaxRAMPercentage=80.0",\
  "-Djava.awt.headless=true",\
  "-Dquarkus.http.host=0.0.0.0",\
  "-jar"]

CMD ["app.jar"]

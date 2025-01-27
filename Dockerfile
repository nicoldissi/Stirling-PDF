


# Étape 1 : Build
FROM gradle:8-jdk17 as builder
WORKDIR /home/gradle/project
COPY . .
RUN ./gradlew build --no-daemon -Dorg.gradle.unsafe.watch-fs=false

# Étape 2 : Image finale
FROM alpine:3.21.2
ARG VERSION_TAG

# Set Environment Variables
ENV DOCKER_ENABLE_SECURITY=false \
    HOME=/home/stirlingpdfuser \
    VERSION_TAG=$VERSION_TAG \
    JAVA_TOOL_OPTIONS="-XX:+UnlockExperimentalVMOptions \
    -XX:MaxRAMPercentage=75 \
    -XX:InitiatingHeapOccupancyPercent=20 \
    -XX:+G1PeriodicGCInvokesConcurrent \
    -XX:G1PeriodicGCInterval=10000 \
    -XX:+UseStringDeduplication \
    -XX:G1PeriodicGCSystemLoadThreshold=70" \
    PUID=1000 \
    PGID=1000 \
    UMASK=022

COPY --from=builder /home/gradle/project/build/libs/*.jar app.jar
# le reste de tes instructions...
# Copy necessary files
COPY scripts/download-security-jar.sh /scripts/download-security-jar.sh
COPY scripts/init-without-ocr.sh /scripts/init-without-ocr.sh
COPY scripts/installFonts.sh /scripts/installFonts.sh
COPY pipeline /pipeline

# Set up necessary directories and permissions
RUN echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/main" | tee -a /etc/apk/repositories && \
    echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/community" | tee -a /etc/apk/repositories && \
    echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" | tee -a /etc/apk/repositories && \
    apk upgrade --no-cache -a && \
    apk add --no-cache \
        ca-certificates \
        tzdata \
        tini \
        bash \
        curl \
        shadow \
        su-exec \
        openjdk21-jre && \
    # User permissions
    mkdir -p /configs /logs /customFiles /usr/share/fonts/opentype/noto && \
    chmod +x /scripts/*.sh && \
    addgroup -S stirlingpdfgroup && adduser -S stirlingpdfuser -G stirlingpdfgroup && \
    chown -R stirlingpdfuser:stirlingpdfgroup $HOME /scripts  /configs /customFiles /pipeline && \
    chown stirlingpdfuser:stirlingpdfgroup /app.jar

# Set environment variables
ENV ENDPOINTS_GROUPS_TO_REMOVE=CLI

EXPOSE 8080/tcp

# Run the application
ENTRYPOINT ["/scripts/init-without-ocr.sh"]
CMD ["java", "-Dfile.encoding=UTF-8", "-jar", "/app.jar"]

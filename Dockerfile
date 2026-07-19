FROM eclipse-temurin:17-jdk-jammy AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=$ANDROID_SDK_ROOT
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

RUN mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" && \
    curl -fSL -o /tmp/cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip && \
    unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools" && \
    mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest" && \
    rm /tmp/cmdline-tools.zip

RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager --install "platform-tools" > /dev/null

ENV FLUTTER_ROOT=/opt/flutter
ENV PATH=$PATH:$FLUTTER_ROOT/bin
RUN git clone -b stable --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_ROOT" && \
    flutter --version

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN echo "sdk.dir=$ANDROID_SDK_ROOT" > android/local.properties && \
    echo "flutter.sdk=$FLUTTER_ROOT" >> android/local.properties
RUN flutter build apk --debug

FROM alpine:3.20 AS final
COPY --from=build /app/build/app/outputs/flutter-apk/app-debug.apk /apk/app-debug.apk

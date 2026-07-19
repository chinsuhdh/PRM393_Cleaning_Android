FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN echo "sdk.dir=$ANDROID_SDK_ROOT" > android/local.properties && \
    echo "flutter.sdk=$FLUTTER_ROOT" >> android/local.properties
RUN flutter build apk --debug

FROM alpine:3.20 AS final
COPY --from=build /app/build/app/outputs/flutter-apk/app-debug.apk /apk/app-debug.apk

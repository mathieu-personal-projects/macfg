FROM eclipse-temurin:21-jdk-alpine AS builder

LABEL mpp.macfg.maintainer="mathieu.audibert@edu.devinci.fr"
LABEL mpp.macfg.version="2.0.0"
LABEL mpp.macfg.vendor="Mathieu Personnal Projects"
LABEL mpp.macfg.name="macfg"
LABEL mpp.macfg.description="Machine Configuration Tool - Dev Environment Installer CLI"

WORKDIR /build

RUN apk add --no-cache maven

COPY pom.xml .
RUN mvn dependency:go-offline -B


COPY src ./src
RUN mvn clean package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN apk add --no-cache bash git curl ncurses sudo

COPY --from=builder /build/target/*.jar app.jar

VOLUME ["/root/dev"]

ENV TERM=xterm-256color
ENTRYPOINT ["java", "-jar", "app.jar"]

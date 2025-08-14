# Etapa 1: Build do jar e criação da JRE customizada
FROM eclipse-temurin:17-jdk as builder

WORKDIR /app

# Copia o código para o container
COPY . .

# Compila o projeto (sem rodar testes para agilizar)
RUN ./mvnw package -DskipTests

# Descobre os módulos necessários para a JRE mínima
RUN jdeps --print-module-deps --ignore-missing-deps --recursive target/*.jar > modules.txt

# Cria a JRE customizada
RUN jlink \
    --module-path $JAVA_HOME/jmods \
    --add-modules $(cat modules.txt) \
    --output /opt/jre \
    --strip-debug \
    --no-header-files \
    --no-man-pages \
    --compress=2

# Etapa 2: Imagem final enxuta
FROM debian:bullseye-slim

# Copia a JRE customizada e o jar do app
COPY --from=builder /opt/jre /opt/jre
COPY --from=builder /app/target/*.jar app.jar

# Adiciona a JRE ao PATH
ENV PATH="/opt/jre/bin:$PATH"

# Configura porta
EXPOSE 8080

# Executa o app
ENTRYPOINT ["java", "-jar", "app.jar"]

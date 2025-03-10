# Dockerfile
# Build stage
FROM amazoncorretto:17-alpine AS build
WORKDIR /workspace/app

# Copy maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Make the maven wrapper executable
RUN chmod +x ./mvnw

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src src

# Build the application
RUN ./mvnw package -DskipTests

# Runtime stage
FROM amazoncorretto:17-alpine

# Install wget for health check
RUN apk add --no-cache wget

# Add a non-root user to run the app
RUN addgroup -S spring && adduser -S spring -G spring

# Set JVM options for containers - explicitly set heap size to 80% of container memory (512Mi * 0.8 = ~410Mi)
ENV JAVA_OPTS="-XX:+UseContainerSupport -Xms410m -Xmx410m"

# Create directory for the application
WORKDIR /app

# Copy the JAR file from the build stage
COPY --from=build --chown=spring:spring /workspace/app/target/*.jar app.jar

# Switch to non-root user
USER spring:spring

# Run the application with explicit JVM settings for container awareness
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]

# Document that the container listens on port 8080
EXPOSE 8080

# Set health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -q -O /dev/null http://localhost:8080/actuator/health || exit 1

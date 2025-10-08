package com.macode101.java_springboot_docker_k8s_example.exception;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {
    private String timestamp;
    private int status;
    private String error;
    private String message;
    private String path;
    private String correlationId;

    private ErrorResponse() {}

    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private final ErrorResponse errorResponse = new ErrorResponse();

        public Builder timestamp(String timestamp) {
            errorResponse.timestamp = timestamp;
            return this;
        }

        public Builder status(int status) {
            errorResponse.status = status;
            return this;
        }

        public Builder error(String error) {
            errorResponse.error = error;
            return this;
        }

        public Builder message(String message) {
            errorResponse.message = message;
            return this;
        }

        public Builder path(String path) {
            errorResponse.path = path;
            return this;
        }

        public Builder correlationId(String correlationId) {
            errorResponse.correlationId = correlationId;
            return this;
        }

        public ErrorResponse build() {
            return errorResponse;
        }
    }

    // Getters
    public String getTimestamp() {
        return timestamp;
    }

    public int getStatus() {
        return status;
    }

    public String getError() {
        return error;
    }

    public String getMessage() {
        return message;
    }

    public String getPath() {
        return path;
    }

    public String getCorrelationId() {
        return correlationId;
    }

    // Setters for JSON deserialization
    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public void setError(String error) {
        this.error = error;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public void setCorrelationId(String correlationId) {
        this.correlationId = correlationId;
    }

    @Override
    public String toString() {
        return "ErrorResponse{" +
                "timestamp='" + timestamp + '\'' +
                ", status=" + status +
                ", error='" + error + '\'' +
                ", message='" + message + '\'' +
                ", path='" + path + '\'' +
                ", correlationId='" + correlationId + '\'' +
                '}';
    }
}

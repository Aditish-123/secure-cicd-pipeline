package com.securecicd;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;

public class App {

    public static String getMessage() {
        return "Java CI/CD Demo Application is running successfully!";
    }

    public static void main(String[] args) throws IOException {

        HttpServer server = HttpServer.create(
                new InetSocketAddress("0.0.0.0", 8080),
                0
        );

        server.createContext("/", App::handleHome);

        server.createContext("/health", App::handleHealth);

        server.start();

        System.out.println("Java server running on port 8080");
    }

    private static void handleHome(HttpExchange exchange) throws IOException {

        String response = getMessage();

        exchange.getResponseHeaders()
                .set("Content-Type", "text/plain");

        exchange.sendResponseHeaders(200, response.length());

        try (OutputStream outputStream = exchange.getResponseBody()) {
            outputStream.write(response.getBytes());
        }
    }

    private static void handleHealth(HttpExchange exchange) throws IOException {

        String response = "{\"status\":\"healthy\"}";

        exchange.getResponseHeaders()
                .set("Content-Type", "application/json");

        exchange.sendResponseHeaders(200, response.length());

        try (OutputStream outputStream = exchange.getResponseBody()) {
            outputStream.write(response.getBytes());
        }
    }
}

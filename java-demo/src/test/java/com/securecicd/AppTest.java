package com.securecicd;

public class AppTest {

    public static void main(String[] args) {

        String message = App.getMessage();

        if (!message.contains("Java CI/CD")) {
            throw new RuntimeException("Java application test failed!");
        }

        System.out.println("Java test passed!");
    }
}

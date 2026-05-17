# Flux App Blueprint

## Overview

A Flutter-based chat application that leverages Firebase for backend services. The app provides a modern, intuitive user experience for real-time messaging, group chats, and an AI-powered assistant.

## Style and Design

- **Theming:** The app uses a centralized `ThemeData` object with a Material 3 design. It supports both light and dark modes and uses the `google_fonts` package for typography.
- **Colors:** The color scheme is generated from a seed color, ensuring a harmonious and accessible palette.
- **Components:** Custom themes are applied to widgets like `AppBar` and `ElevatedButton` for a consistent look and feel.

## Features

- **Authentication:** Users can sign up and log in using Firebase Authentication.
- **Real-time Messaging:** One-on-one and group chats are supported using Cloud Firestore as the backend. The app displays messages in real-time, including sender information, timestamps, and message status.
- **AI Assistant:** The app includes a chatbot screen where users can interact with a Gemini-powered AI assistant. The AI responses are streamed in real-time for a more interactive experience.
- **Navigation:** The app uses the `go_router` package for declarative navigation, supporting deep linking and a structured routing system.

## Current Plan

- No active plan. The chatbot feature has been successfully integrated.

# Flutter Frontend Architecture Guide

## 1. Core Principles

This project enforces a strict **Clean Architecture** combined with a **Model-View-ViewModel (MVVM)** pattern for the presentation layer. State management is handled exclusively by **Riverpod**.

## 2. Layer Definitions & Rules

### `domain` Layer
- **Contents:**
    - `Entities`: Pure Dart data classes (using Freezed). The core data model.
    - `Repositories`: Abstract interfaces for data access (e.g., `abstract class PostRepository`).
    - `UseCases`: Business logic classes that orchestrate calls to repositories.
- **Rules:**
    - MUST NOT depend on any other layer.
    - MUST NOT contain any Flutter-specific imports (`package:flutter/**`).

### `data` Layer
- **Contents:**
    - `Repositories`: Implementations of the `domain` repository interfaces.
    - `DataSources`: Remote (API clients via Dio) and Local (database/cache) implementations.
    - `Models`: DTOs for API responses, mapped to/from `domain` Entities.
- **Rules:**
    - Implements interfaces from the `domain` layer.
    - Handles all I/O operations.
    - MUST NOT be accessed directly by the `presentation` layer.

### `presentation` Layer (MVVM)
- **Contents:**
    - Organized into `features`. Each feature contains `pages` (screens) and `widgets`.
- **Rules:**
    - Depends only on the `domain` layer (via UseCases).
    - All stateful logic MUST be in a Riverpod `Provider`.

#### MVVM Pattern Implementation:
- **View (`pages`/`widgets`):**
    - **Role:** Renders UI based on state from the ViewModel.
    - **Rules:** MUST be "dumb". Delegates all user events to the ViewModel. MUST NOT contain business logic.
- **ViewModel (`*provider.dart`):**
    - **Role:** A Riverpod `(State)NotifierProvider` that holds UI state and presentation logic.
    - **Rules:**
        - Calls `domain` UseCases to perform actions.
        - Exposes state (`State`) for the View to consume.
        - MUST be scoped to a specific feature or screen. AVOID monolithic providers.

## 3. Directory Structure

- **`core`**: App-wide utilities, routing, theme, and base classes.
- **`features`**: Self-contained feature modules (e.g., `post`, `profile`). Each feature has its own `presentation` directory.

## 4. AI Agent Mandates
1.  **Enforce Dependency Rule:** `presentation` -> `domain` <- `data`. No direct `presentation` -> `data` calls.
2.  **Isolate Business Logic:** No business logic in View widgets. It belongs in `domain` UseCases or `presentation` ViewModels.
3.  **Scoped Providers:** Prohibit large, monolithic providers. State must be scoped to the feature that requires it.

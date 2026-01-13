# AI Coding Best Practices for Ruby on Rails

This document outlines the architectural patterns and coding standards used in this project. When building new features or a new project inspired by this codebase, adhere to these practices.

## 1. Architectural Patterns

### 1.1 Service Objects

Move complex business logic out of controllers and models into dedicated services.

- **Location**: `app/services/`
- **Return Type**: Use a `ServiceResult` object to return `success`, `message`, and `data`.
- **Example**:
  ```ruby
  class MyService
    def call(params)
      # ... logic ...
      ServiceResult.new(success: true, message: "Success!", data: { result: result })
    end
  end
  ```

### 1.2 Decorators

Handle view-specific logic (formatting, CSS classes) in decorators instead of models or helpers.

- **Library**: `draper`
- **Location**: `app/decorators/`
- **Example**: `SurveyFormDecorator` handles status badge colors and date formatting.

### 1.3 Policies

Use Pundit for all authorization logic.

- **Location**: `app/policies/`
- **Standard**: Every controller action should call `authorize @record`.

### 1.4 Scopes & Fat Models

Keep controllers thin by moving query logic into models using scopes.

- Use `Arel.sql` for complex SQL queries to avoid breaking eager loading and pagination.
- Filter logic can be delegated to a service if it becomes too complex (see `User.filtered_by_criteria`).

## 2. Internationalization (i18n)

This project is built for multi-language support (default: French `fr`, secondary: English `en`).

### 2.1 Localization Rules

- **Never** hardcode strings in views or controllers. Use `I18n.t("key")`.
- **Routes**: Localize routes using scopes in `config/routes.rb`. Use `path_names` for Devise.
- **Models**: Use enums for statuses and translate them in YAML files.

### 2.2 Path Helpers

When routes are localized, use helper methods in `ApplicationController` to handle locale-specific path generation if needed (e.g., `edit_profile_path_helper`).

## 3. UI and Frontend

### 3.1 Styling

- **Framework**: Tailwind CSS.
- **Shared Components**: Use partials in `app/views/shared/` for reusable UI elements like buttons, badges, and cards.
- **Dynamic Content**: Use Hotwire (Turbo) and Stimulus for interactivity.

### 3.2 Form Handling

- Use standard Rails `form_with`.
- Provide consistent error handling using the `shared/form_errors` partial.

## 4. Background Processing

- **Tool**: ActiveJob.
- **Use Case**: Use for long-running tasks, bulk operations, or third-party API calls (e.g., `AssignUserToGroupsJob`).

## 5. Development Standards

- **Authentication**: Use Devise. Customize layouts in `ApplicationController#layout_by_resource`.
- **Pagination**: Use Pagy.
- **Naming**: Follow standard Rails naming conventions (PascalCase for classes, snake_case for methods and variables).
- **Slim Controllers**: Controllers should only handle request/response flow, session management, and delegating to services/models.

## 6. Prompting Strategy for AI

When asking an AI to generate code for this project, use this template:

> "Implement [feature] following the project's standards:
>
> 1. Use a Service Object for business logic with `ServiceResult`.
> 2. Use Pundit for authorization.
> 3. Use Draper for view logic.
> 4. Ensure full i18n support in French and English.
> 5. Use Tailwind CSS and existing shared partials for the UI.
> 6. Keep the controller slim."

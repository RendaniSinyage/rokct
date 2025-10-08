# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import ast
import importlib.util
import inspect
import json
import os
import re
import urllib.parse
import traceback

import frappe
from pydantic import BaseModel
from datetime import datetime, date

def find_pydantic_model_in_decorator(node):
    """Find the name of the Pydantic model used in the validate_request decorator.

    Args:
        node (ast.AST): The AST node representing the function definition.

    Returns:
        str: The name of the Pydantic model used in the decorator, if found.
    """
    for n in ast.walk(node):
        if isinstance(n, ast.FunctionDef):
            for decorator in n.decorator_list:
                if isinstance(decorator, ast.Call):
                    if (
                        isinstance(decorator.func, ast.Name)
                        and decorator.func.id == "validate_request"
                    ):
                        if decorator.args:
                            if isinstance(decorator.args[0], ast.Name):
                                return decorator.args[0].id
                            elif isinstance(decorator.args[0], ast.Attribute):
                                return f"{ast.dump(decorator.args[0].value)}.{decorator.args[0].attr}"
    return None

def get_pydantic_model_schema(model_name, module):
    """Extract the schema from a Pydantic model.

    Args:
        model_name (str): The name of the Pydantic model.
        module (module): The module where the model is defined.

    Returns:
        dict: The JSON schema of the Pydantic model, if valid.
    """
    if hasattr(module, model_name):
        model = getattr(module, model_name)
        if issubclass(model, BaseModel):
            return model.model_json_schema()
    return None

def process_function(app_name, module_name, func_name, func, swagger, module):
    """Process each function to update the Swagger paths.

    Args:
        app_name (str): The name of the app.
        module_name (str): The name of the module.
        func_name (str): The name of the function being processed.
        func (function): The function object.
        swagger (dict): The Swagger specification to be updated.
        module (module): The module where the function is defined.
    """
    try:
        source_code = inspect.getsource(func)
        tree = ast.parse(source_code)

        # Skip functions that do not contain validate_http_method calls
        if not any(
            "validate_http_method" in ast.dump(node) and isinstance(node, ast.Call)
            for node in ast.walk(tree)
        ):
            print(f"Skipping {func_name}: 'validate_http_method' not found")
            return

        # Find the Pydantic model used in the validate_request decorator
        pydantic_model_name = find_pydantic_model_in_decorator(tree)

        # Construct the API path for the function
        path = f"/api/v1/method/{app_name}.api.{module_name}.{func_name}".lower()

        # Define the mapping of HTTP methods to check for in the source code
        http_methods = {
            "GET": "GET",
            "POST": "POST",
            "PUT": "PUT",
            "DELETE": "DELETE",
            "PATCH": "PATCH",
            "OPTIONS": "OPTIONS",
            "HEAD": "HEAD",
        }

        # Default HTTP method is POST
        http_method = "POST"
        for method in http_methods:
            if method in source_code:
                http_method = method
                break

        # Define the request body for methods that modify data
        request_body = {}
        if pydantic_model_name and http_method in ["POST", "PUT", "PATCH"]:
            pydantic_schema = get_pydantic_model_schema(pydantic_model_name, module)
            if pydantic_schema:
                request_body = {
                    "description": "Request body",
                    "required": True,
                    "content": {"application/json": {"schema": pydantic_schema}},
                }

        # Define query parameters for methods that retrieve data
        params = []
        if http_method in ["GET", "DELETE", "OPTIONS", "HEAD"]:
            signature = inspect.signature(func)
            for param_name, param in signature.parameters.items():
                if (
                    param.default is inspect.Parameter.empty
                    and not "kwargs" in param_name
                ):
                    param_type = "string"
                    params.append(
                        {
                            "name": param_name,
                            "in": "query",
                            "required": True,
                            "schema": {"type": param_type},
                        }
                    )

        # Define the response schema
        responses = {
            "200": {
                "description": "Successful response",
                "content": {"application/json": {"schema": {"type": "object"}}},
            }
        }

        # Assign tags for the Swagger documentation
        tags = [module_name]

        # Initialize the path if not already present
        if path not in swagger["paths"]:
            swagger["paths"][path] = {}

        # Update the Swagger specification with the function details
        swagger["paths"][path][http_method.lower()] = {
            "summary": func_name.title().replace("_", " "),
            "tags": tags,
            "parameters": params,
            "requestBody": request_body if request_body else None,
            "responses": responses,
            "security": [{"basicAuth": []}],
        }
    except Exception as e:
        # Log any errors that occur during processing
        frappe.log_error(
            f"Error processing function {func_name} in module {module_name}: {str(e)}"
        )

def load_module_from_file(file_path):
    """Load a module dynamically from a given file path.

    Args:
        file_path (str): The file path of the module.

    Returns:
        module: The loaded module.
    """
    module_name = os.path.basename(file_path).replace(".py", "")
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def get_doctype_schema(doctype, example_doc=None):
    """Dynamically generate a schema for a given DocType, including custom fields and child tables."""
    meta = frappe.get_meta(doctype)
    schema_properties = {}
    required_fields = []
    example_values = {}

    # Define system fields that are read-only
    read_only_fields = ["name", "creation", "modified", "owner"]

    for field in meta.fields:
        field_schema = {}

        # Add field descriptions
        if field.description:
            field_schema["description"] = field.description

        # Add required constraint
        if frappe.db.get_value("DocField", {"parent": doctype, "fieldname": field.fieldname}, "reqd"):
            required_fields.append(field.fieldname)

        # Add read-only flag for system fields
        if field.fieldname in read_only_fields:
            field_schema["readOnly"] = True

        # Get the value from the example doc, if it exists
        example_val = example_doc.get(field.fieldname) if example_doc else None

        if field.fieldtype == "Table":
            child_doctype = field.options
            if child_doctype:
                child_example_data = example_doc.get(field.fieldname, []) if example_doc else None
                child_schema = get_child_table_schema(child_doctype, child_example_data)
                field_schema.update({
                    "type": "array",
                    "items": child_schema
                })
                example_values[field.fieldname] = [child_schema.get("example", {})] if child_schema.get("example") else []
        elif field.fieldtype in ["Data", "Text", "Read Only", "Link", "HTML Editor"]:
            field_schema["type"] = "string"
            if field.fieldtype == "Link" and field.options:
                # Add enum if the field is a Link to a small, fixed-value DocType
                if frappe.get_meta(field.options).issingle:
                     # For simplicity, we'll assume it's a fixed list
                     field_schema["enum"] = frappe.db.get_list(field.options, pluck="name")
            example_values[field.fieldname] = example_val.isoformat() if isinstance(example_val, (date, datetime)) else (example_val if example_val is not None else f"Example {field.label}")
        elif field.fieldtype in ["Int", "Check"]:
            field_schema["type"] = "integer"
            example_values[field.fieldname] = example_val if example_val is not None else 0
        elif field.fieldtype in ["Float", "Currency", "Percent"]:
            field_schema["type"] = "number"
            example_values[field.fieldname] = example_val if example_val is not None else 0.0
        elif field.fieldtype == "Date":
            field_schema["type"] = "string"
            field_schema["format"] = "date"
            example_values[field.fieldname] = example_val.isoformat() if isinstance(example_val, (date, datetime)) else "2025-09-04"
        elif field.fieldtype == "Datetime":
            field_schema["type"] = "string"
            field_schema["format"] = "date-time"
            example_values[field.fieldname] = example_val.isoformat() if isinstance(example_val, (date, datetime)) else "2025-09-04T00:00:00Z"
        # Add other field types as needed

        schema_properties[field.fieldname] = field_schema

    schema = {
        "type": "object",
        "properties": schema_properties,
        "example": example_values
    }

    if required_fields:
        schema["required"] = required_fields

    return schema

def get_child_table_schema(child_doctype, example_data=None):
    """Dynamically generate a schema for a child DocType."""
    child_meta = frappe.get_meta(child_doctype)
    schema_properties = {}
    required_fields = []
    example_values = {}

    # Define system fields that are read-only
    read_only_fields = ["name", "creation", "modified", "owner"]

    for field in child_meta.fields:
        field_schema = {}

        # Add field descriptions
        if field.description:
            field_schema["description"] = field.description

        # Add required constraint
        if frappe.db.get_value("DocField", {"parent": child_doctype, "fieldname": field.fieldname}, "reqd"):
            required_fields.append(field.fieldname)

        # Add read-only flag for system fields
        if field.fieldname in read_only_fields:
            field_schema["readOnly"] = True

        # Get the value from the example data, if it exists
        example_val = example_data.get(field.fieldname) if example_data and isinstance(example_data, dict) else None

        if field.fieldtype in ["Data", "Text", "Read Only", "Link", "HTML Editor"]:
            field_schema["type"] = "string"
            if field.fieldtype == "Link" and field.options:
                if frappe.get_meta(field.options).issingle:
                     field_schema["enum"] = frappe.db.get_list(field.options, pluck="name")
            example_values[field.fieldname] = example_val.isoformat() if isinstance(example_val, (date, datetime)) else (example_val if example_val is not None else f"Example {field.label}")
        elif field.fieldtype in ["Int", "Check"]:
            field_schema["type"] = "integer"
            example_values[field.fieldname] = example_val if example_val is not None else 0
        elif field.fieldtype in ["Float", "Currency", "Percent"]:
            field_schema["type"] = "number"
            example_values[field.fieldname] = example_val if example_val is not None else 0.0
        elif field.fieldtype == "Date":
            field_schema["type"] = "string"
            field_schema["format"] = "date"
            example_values[field.fieldname] = example_val.isoformat() if isinstance(example_val, (date, datetime)) else "2025-09-04"
        elif field.fieldtype == "Datetime":
            field_schema["type"] = "string"
            field_schema["format"] = "date-time"
            example_values[field.fieldname] = example_val.isoformat() if isinstance(example_val, (date, datetime)) else "2025-09-04T00:00:00Z"
        # Add other field types as needed

        schema_properties[field.fieldname] = field_schema

    schema = {
        "type": "object",
        "properties": schema_properties,
        "example": example_values
    }

    if required_fields:
        schema["required"] = required_fields

    return schema

@frappe.whitelist(allow_guest=True)
def generate_swagger_json():
    """Generate Swagger JSON documentation for all API methods.

    This function processes all Python files in the `api` directories of installed apps
    to generate a Swagger JSON file that describes the API methods.
    """
    swagger_settings = frappe.get_single("Swagger Settings")
    swagger_settings.generation_status = "In Progress"
    swagger_settings.last_generation_time = frappe.utils.now_datetime()
    swagger_settings.generation_log = ""  # Clear previous logs
    swagger_settings.save(ignore_permissions=True)
    frappe.db.commit()

    try:
        # Get the list of excluded modules and doctypes from Swagger Settings
        excluded_modules = {d.module.lower() for d in swagger_settings.get("excluded_modules", [])}
        excluded_doctypes = {d.doctype for d in swagger_settings.get("excluded_doctypes", [])}

        # Define the output directory and ensure it exists
        output_dir = os.path.join(frappe.get_app_path('rokct'), 'public', 'api')
        os.makedirs(output_dir, exist_ok=True)

        # Clean up old JSON files before generating new ones
        for filename in os.listdir(output_dir):
            if filename.endswith(".json"):
                os.remove(os.path.join(output_dir, filename))

        # Initialize the Swagger specification
        base_swagger = {
            "openapi": "3.0.0",
            "info": {
                "title": "PLATFORM API",
                "version": "v1.0.0",
            },
            "paths": {},
            "components": {
                "schemas": {
                    "Error": {
                        "type": "object",
                        "properties": {
                            "exc_type": {"type": "string", "description": "The type of the exception."},
                            "exc": {"type": "string", "description": "The stack trace of the exception."},
                            "message": {"type": "string", "description": "A human-readable error message."},
                        }
                    },
                    "Success": {
                        "type": "object",
                        "properties": {
                            "data": {"type": "object", "description": "The data returned by the API."}
                        }
                    }
                },
                "securitySchemes": {
                    "BasicAuth": {
                        "type": "http",
                        "scheme": "basic",
                        "description": "Standard HTTP Basic Authentication with API Key and API Secret. Example: `Authorization: Basic <base64-encoded api_key:api_secret>`"
                    },
                    "BearerAuth": {
                        "type": "http",
                        "scheme": "bearer",
                        "bearerFormat": "JWT",
                        "description": "Bearer token authentication. Example: `Authorization: Bearer <token>`"
                    }
                }
            },
            "security": [
                {"BasicAuth": []},
                {"BearerAuth": []}
            ],
            "tags": []
        }

        # Define common error responses for reuse
        base_swagger["components"]["responses"] = {
            "UnauthorizedError": {
                "description": "Authentication information is missing or invalid.",
                "content": {
                    "application/json": {
                        "schema": {"$ref": "#/components/schemas/Error"},
                        "examples": {
                            "Unauthorized": {
                                "value": {
                                    "exc_type": "frappe.exceptions.AuthenticationError",
                                    "exc": "Traceback (most recent call last):...",
                                    "message": "Authentication failed"
                                }
                            }
                        }
                    }
                }
            },
            "NotFoundError": {
                "description": "The requested resource could not be found.",
                "content": {
                    "application/json": {
                        "schema": {"$ref": "#/components/schemas/Error"},
                        "examples": {
                            "Not Found": {
                                "value": {
                                    "exc_type": "frappe.exceptions.DoesNotExistError",
                                    "exc": "Traceback (most recent call last):...",
                                    "message": "The resource was not found"
                                }
                            }
                        }
                    }
                }
            },
            "BadRequestError": {
                "description": "The request was malformed or invalid.",
                "content": {
                    "application/json": {
                        "schema": {"$ref": "#/components/schemas/Error"},
                        "examples": {
                            "Bad Request": {
                                "value": {
                                    "exc_type": "frappe.exceptions.ValidationError",
                                    "exc": "Traceback (most recent call last):...",
                                    "message": "Mandatory field 'title' is not set."
                                }
                            }
                        }
                    }
                }
            }
        }


        # Get the path to the Frappe bench directory
        frappe_bench_dir = frappe.utils.get_bench_path()
        file_paths = []

        # Store DocTypes grouped by app/module for a better HTML display
        app_doctypes = {}

        # Get all DocTypes and group them by app
        all_doctypes = frappe.db.get_list("DocType", pluck="name", ignore_permissions=True)
        failed_doctypes = []
        for doctype in all_doctypes:
            try:
                doctype_meta = frappe.get_meta(doctype)
                # Skip child tables for the main grouping, as they will be handled within their parent's schema
                if doctype_meta.istable:
                    continue
                app_name = doctype_meta.module.lower()
                if app_name not in app_doctypes:
                    app_doctypes[app_name] = []
                app_doctypes[app_name].append(doctype)
            except Exception as e:
                # Log the error silently and continue
                failed_doctypes.append({"doctype": doctype, "error": str(e)})
                continue


        # Gather all Python files in the `api` folders of each installed app, except for 'frappe'
        for app in frappe.get_installed_apps():
            if app == 'frappe':
                continue
            try:
                api_dir = os.path.join(frappe_bench_dir, "apps", app, app, "api")
                if os.path.exists(api_dir) and os.path.isdir(api_dir):
                    for root, dirs, files in os.walk(api_dir):
                        for file in files:
                            if file.endswith(".py"):
                                file_paths.append((app,os.path.join(root, file)))
            except Exception as e:
                # Log any errors encountered while processing the app
                frappe.log_error(f"Error processing app '{app}': {str(e)}")
                continue

        # Initialize data structures for modular and full spec generation
        modules_list = []
        full_swagger = base_swagger.copy()
        full_swagger["paths"] = {}
        full_swagger["tags"] = []
        full_swagger["components"] = base_swagger["components"]

        total_doctypes = len(all_doctypes)
        processed_doctypes_count = 0

        # Process each Python file found to create module-specific JSONs
        for app,file_path in file_paths:
            try:
                if os.path.isfile(file_path) and app in str(file_path):
                    module = load_module_from_file(file_path)
                    module_name = os.path.basename(file_path).replace(".py", "")

                    # Skip excluded modules
                    if module_name.lower() in excluded_modules:
                        continue

                    module_spec = {
                        "openapi": "3.0.0",
                        "info": {
                            "title": "PLATFORM API",
                            "version": "v1.0.0"
                        },
                        "paths": {},
                        "tags": [],
                        "components": base_swagger["components"],
                        "security": base_swagger["security"]
                    }

                    module_spec["tags"].append({"name": module_name, "description": f"Endpoints for the **{module_name}** module in the **{app}** app."})
                    modules_list.append(f"{app}-{module_name}")

                    for func_name, func in inspect.getmembers(module, inspect.isfunction):
                        process_function(app, module_name, func_name, func, module_spec, module)

                    safe_module_name = re.sub(r'[^a-zA-Z0-9\-_]', '', f"{app}-{module_name}")
                    module_file_path = os.path.join(output_dir, f"module-{safe_module_name}.json")
                    with open(module_file_path, "w") as module_file:
                        json.dump(module_spec, module_file, indent=4)

                    full_swagger["paths"].update(module_spec["paths"])
                    full_swagger["tags"].extend(module_spec["tags"])

                else:
                    print(f"File not found: {file_path}")
            except Exception as e:
                frappe.log_error(f"Error loading or processing file {file_path}: {str(e)}")

        # Add DocType endpoints to the full swagger spec and create module-specific DocType JSONs
        for app_name, doctypes in app_doctypes.items():
            # Skip excluded modules
            if app_name.lower() in excluded_modules:
                continue

            module_spec = {
                "openapi": "3.0.0",
                "info": {
                    "title": "PLATFORM API",
                    "version": "v1.0.0"
                },
                "paths": {},
                "tags": [],
                "components": base_swagger["components"],
                "security": base_swagger["security"]
            }

            modules_list.append(app_name)

            for doctype in doctypes:
                try:
                    # Skip excluded doctypes
                    if doctype in excluded_doctypes:
                        continue

                    doctype_meta = frappe.get_meta(doctype)
                    sanitized_doctype = doctype.replace(" ", "_")

                    # Default operation IDs
                    get_op_id = f"get_api_v1_resource_{sanitized_doctype}"
                    list_op_id = f"get_api_v1_resource_{sanitized_doctype}"
                    create_op_id = f"post_api_v1_resource_{sanitized_doctype}"
                    update_op_id = f"put_api_v1_resource_{sanitized_doctype}"
                    delete_op_id = f"delete_api_v1_resource_{sanitized_doctype}"

                    # Custom operation IDs for 'paas' module
                    if doctype_meta.module.lower() == 'paas':
                        try:
                            # Dynamically find the app name from the module definition
                            module_def = frappe.get_doc("Module Def", doctype_meta.module)
                            app_name_for_path = module_def.app_name

                            # Construct the custom prefix for the operationId
                            prefix = f"/api/v1/method/{app_name_for_path}.{doctype_meta.module.lower()}"

                            # Set the custom operation IDs
                            get_op_id = f"{prefix}.get_{sanitized_doctype}"
                            list_op_id = f"{prefix}.list_{sanitized_doctype}"
                            create_op_id = f"{prefix}.create_{sanitized_doctype}"
                            update_op_id = f"{prefix}.update_{sanitized_doctype}"
                            delete_op_id = f"{prefix}.delete_{sanitized_doctype}"

                        except frappe.DoesNotExistError:
                            # If Module Def is not found for some reason, log it and fall back to default operation IDs
                            frappe.log_error(f"Swagger Generation: Module Def '{doctype_meta.module}' not found for DocType '{doctype}'.")
                            pass

                    tag_name = f"{doctype} DocType"
                    tag_description = f"Endpoints for the **{doctype}** DocType in the **{app_name}** module."
                    module_spec["tags"].append({"name": tag_name, "description": tag_description})
                    full_swagger["tags"].append({"name": tag_name, "description": tag_description})

                    if doctype_meta.issingle:
                        # Handle single DocTypes
                        example_doc = frappe.get_doc(doctype).as_dict()
                        doctype_schema = get_doctype_schema(doctype, example_doc)
                        endpoint = f"/api/v1/resource/{urllib.parse.quote(doctype)}"

                        # Add GET operation for single DocType
                        module_spec["paths"][endpoint] = {
                            "get": {
                                "summary": f"Get {doctype}",
                                "operationId": get_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "responses": {
                                    "200": {
                                        "description": f"Returns the {doctype} document.",
                                        "content": {
                                            "application/json": {
                                                "schema": {
                                                    "type": "object",
                                                    "properties": {"data": doctype_schema}
                                                }
                                            }
                                        }
                                    },
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"}
                                }
                            },
                            "put": {
                                "summary": f"Update {doctype}",
                                "operationId": update_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "requestBody": {
                                    "description": f"The {doctype} document to be updated.",
                                    "required": True,
                                    "content": {
                                        "application/json": {"schema": doctype_schema}
                                    }
                                },
                                "responses": {
                                    "200": {
                                        "description": f"Successfully updated the {doctype} document.",
                                        "content": {
                                            "application/json": {
                                                "schema": {"$ref": "#/components/schemas/Success"}
                                            }
                                        }
                                    },
                                    "400": {"$ref": "#/components/responses/BadRequestError"},
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"}
                                }
                            }
                        }
                    else:
                        # Handle regular DocTypes
                        try:
                            example_doc = frappe.get_list(doctype, limit=1, as_list=False)
                            example_doc = example_doc[0] if example_doc else {}
                        except Exception:
                            example_doc = {}
                        doctype_schema = get_doctype_schema(doctype, example_doc)

                        endpoint = f"/api/v1/resource/{urllib.parse.quote(doctype)}"
                        module_spec["paths"][endpoint] = {
                            "get": {
                                "summary": f"List {doctype}",
                                "operationId": list_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "parameters": [
                                    {
                                        "name": "limit_start",
                                        "in": "query",
                                        "description": "Start fetching records from this index.",
                                        "required": False,
                                        "schema": {
                                            "type": "integer",
                                            "default": 0
                                        }
                                    },
                                    {
                                        "name": "limit_page_length",
                                        "in": "query",
                                        "description": "Number of records to return in this page.",
                                        "required": False,
                                        "schema": {
                                            "type": "integer",
                                            "default": 20
                                        }
                                    },
                                    {
                                        "name": "filters",
                                        "in": "query",
                                        "description": "Filters to apply to the list of documents. Example: [[\"status\",\"=\",\"Open\"]]",
                                        "required": False,
                                        "schema": { "type": "string" }
                                    },
                                    {
                                        "name": "fields",
                                        "in": "query",
                                        "description": "Fields to retrieve. Example: [\"name\", \"subject\"]",
                                        "required": False,
                                        "schema": { "type": "string" }
                                    },
                                    {
                                        "name": "order_by",
                                        "in": "query",
                                        "description": "Field to sort the results by. Example: 'creation desc'",
                                        "required": False,
                                        "schema": { "type": "string" }
                                    }
                                ],
                                "responses": {
                                    "200": {
                                        "description": f"Returns a list of {doctype} documents.",
                                        "content": {
                                            "application/json": {
                                                "schema": {
                                                    "type": "object",
                                                    "properties": {
                                                        "data": {
                                                            "type": "array",
                                                            "items": doctype_schema
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"}
                                }
                            },
                            "post": {
                                "summary": f"Create {doctype}",
                                "operationId": create_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "requestBody": {
                                    "description": f"The {doctype} document to be created.",
                                    "required": True,
                                    "content": {
                                        "application/json": {
                                            "schema": doctype_schema
                                        }
                                    }
                                },
                                "responses": {
                                    "200": {
                                        "description": f"Successfully created a new {doctype} document.",
                                        "content": {
                                            "application/json": {
                                                "schema": {"$ref": "#/components/schemas/Success"}
                                            }
                                        }
                                    },
                                    "400": {"$ref": "#/components/responses/BadRequestError"},
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"}
                                }
                            }
                        }
                        module_spec["paths"][f"{endpoint}/{{name}}"] = {
                            "parameters": [
                                {
                                    "name": "name",
                                    "in": "path",
                                    "required": True,
                                    "schema": {
                                        "type": "string"
                                    },
                                    "description": f"The name of the {doctype} to retrieve, update, or delete."
                                }
                            ],
                            "get": {
                                "summary": f"Get {doctype} by name",
                                "operationId": get_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "responses": {
                                    "200": {
                                        "description": f"Returns a single {doctype} document.",
                                        "content": {
                                            "application/json": {
                                                "schema": {
                                                    "type": "object",
                                                    "properties": {
                                                        "data": doctype_schema
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"},
                                    "404": {"$ref": "#/components/responses/NotFoundError"}
                                }
                            },
                            "put": {
                                "summary": f"Update {doctype}",
                                "operationId": update_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "requestBody": {
                                    "description": "The fields of the DocType to be updated. Only send the fields you want to change.",
                                    "required": True,
                                    "content": {
                                        "application/json": {
                                            "schema": doctype_schema
                                        }
                                    }
                                },
                                "responses": {
                                    "200": {
                                        "description": f"Successfully updated the {doctype} document.",
                                        "content": {
                                            "application/json": {
                                                "schema": {"$ref": "#/components/schemas/Success"}
                                            }
                                        }
                                    },
                                    "400": {"$ref": "#/components/responses/BadRequestError"},
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"},
                                    "404": {"$ref": "#/components/responses/NotFoundError"}
                                }
                            },
                            "delete": {
                                "summary": f"Delete {doctype}",
                                "operationId": delete_op_id,
                                "security": [{"BasicAuth": []}, {"BearerAuth": []}],
                                "tags": [tag_name],
                                "responses": {
                                    "200": {
                                        "description": f"Successfully deleted the {doctype} document.",
                                        "content": {
                                            "application/json": {
                                                "schema": {
                                                    "type": "object",
                                                    "properties": {
                                                        "message": {"type": "string", "example": "ok"}
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    "401": {"$ref": "#/components/responses/UnauthorizedError"},
                                    "404": {"$ref": "#/components/responses/NotFoundError"}
                                }
                            }
                        }
                    processed_doctypes_count += 1
                except Exception as e:
                    failed_doctypes.append({"doctype": doctype, "error": str(e)})
                    continue

            safe_module_name = re.sub(r'[^a-zA-Z0-9\-_]', '', app_name)
            module_file_path = os.path.join(output_dir, f"module-{safe_module_name}.json")
            with open(module_file_path, "w") as module_file:
                json.dump(module_spec, module_file, indent=4)

            full_swagger["paths"].update(module_spec["paths"])

        full_swagger["info"]["title"] = "PLATFORM API"
        full_swagger["x-total-doctypes"] = total_doctypes
        full_swagger["x-processed-doctypes"] = processed_doctypes_count

        full_file_path = os.path.join(output_dir, "swagger-full.json")
        with open(full_file_path, "w") as full_file:
            json.dump(full_swagger, full_file, indent=4)

        modules_file_path = os.path.join(output_dir, "modules.json")
        with open(modules_file_path, "w") as modules_file:
            json.dump({"modules": modules_list}, modules_file, indent=4)

        if failed_doctypes:
            log_message = "The following DocTypes failed to process:\n\n"
            for failure in failed_doctypes:
                log_message += f"- DocType: {failure['doctype']}\n  Error: {failure['error']}\n\n"

            swagger_settings.generation_log = log_message
            swagger_settings.generation_status = "Failed"
            frappe.log_error(
                title=f"Swagger Generation: Failed to process {len(failed_doctypes)} DocTypes.",
                message=log_message
            )
        else:
            swagger_settings.generation_status = "Success"
            swagger_settings.generation_log = ""

        frappe.msgprint(f"""
            <b>Swagger Generation Complete</b><br><br>
            Successfully processed: {processed_doctypes_count}<br>
            Failed: {len(failed_doctypes)}<br>
            Total found: {total_doctypes}<br><br>
            <i>Check the Error Log for details on failed DocTypes.</i>
        """)

        swagger_settings.save(ignore_permissions=True)
        frappe.db.commit()

    except Exception as e:
        # On failure
        swagger_settings.generation_status = "Failed"
        swagger_settings.generation_log = f"A critical error occurred during generation:\n\n{traceback.format_exc()}"
        swagger_settings.save(ignore_permissions=True)
        frappe.db.commit()
        frappe.log_error(f"Swagger Generation Failed: {str(e)}", "Swagger Generator")
        raise
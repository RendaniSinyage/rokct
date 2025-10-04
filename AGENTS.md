\# AGENTS.md - Instructions for AI Agents



This document provides instructions and guidelines for AI agents working on this project. Please read it carefully before starting any work.



\## Project Overview and Goals

This project is an AI-first ERP that runs on Frappe. The core application is `rokct`. Within this app, there is a side-project module called `paas` (Platform as a Service), which is being converted from a legacy Laravel application. Your main task is to continue this conversion effort by implementing features from the Laravel backend into the `rokct` Frappe app.

\## Application Structure

The key components of the application are located in the following directories:

*   **Primary Frappe App:** `rokct/rokct` - This is the main application where all business logic, customizations, and the PaaS module are implemented.
*   **PaaS Module (Source of Truth):** `rokct/paas/juvo/backend` - The original Laravel backend. This serves as the reference for the features and logic you will be converting for the PaaS module.
*   **Flutter Frontend Apps:** `rokct/paas/juvo/customer` and `rokct/paas/juvo/pos` - These are the customer-facing and Point-of-Sale (POS) applications that will connect to the new Frappe backend.



\## Development Workflow



To ensure a smooth and consistent development process, please follow these steps:



1\.  \*\*Understand the Current State:\*\* Before you begin, you \*\*must\*\* read the following files to understand the project's progress and pending tasks:

&nbsp;   \*   `rokct/paas/roadmap\_progress.txt`

&nbsp;   \*   `rokct/paas/TODO.md`



2\.  \*\*Log Your Progress:\*\* As you work on features, please update the `rokct/paas/roadmap\_progress.txt` file to reflect your progress. Mark completed tasks and add notes where necessary.



3\.  \*\*Pagination:\*\* When converting features, if the original Laravel implementation includes pagination, you \*\*must\*\* implement pagination in the new Frappe version as well. If you encounter a feature that does not have pagination in the Laravel code but you believe it should, do \*\*not\*\* add it. Instead, add a note to the `rokct/paas/TODO.md` file so that it can be discussed later.



4\.  \*\*Frontend Compatibility:\*\* While the primary focus is on the backend conversion, it is crucial to ensure that the frontend Flutter applications remain compatible with the new Frappe backend. As you convert each feature, you should consider the impact on the frontend. While you should not make major UI/UX changes to the Flutter apps, you \*\*are expected\*\* to update the repository files that handle API endpoint connections to point to the new Frappe endpoints. Please test these connections to ensure they work correctly.



\## Repository Rules

Please adhere to the following rules when working on this repository:

*   **Copyright:** All files in this repository are subject to the license defined in the root `license.txt` file. Before committing any changes, please ensure that any file you create or modify contains the correct copyright notice at the top of the file. The correct copyright notice can be found in the `license.txt` file.

*   **Dependencies:** Do **not** install any new dependencies or packages without first asking for and receiving permission from the user.

*   **Resetting the Environment:** Do **not** use the `reset_all` tool without explicit permission from the user. This is a destructive action that will revert all changes.

*   **Frontend Changes:** Do not make any changes to the frontend Flutter applications (`rokct/paas/juvo/customer` and `rokct/paas/juvo/pos`) beyond what is necessary for API compatibility, without explicit permission from the user.



\## Agent Setup Instructions



This document provides instructions for setting up the development environment for this project. This is especially important for running tests.



\### Dependencies



This is a Frappe application, but it is being developed outside of a standard `bench` environment. To run the code and tests, you will need to install the necessary dependencies manually.



1\.  \*\*Install requirements:\*\*

&nbsp;   Install the dependencies listed in `dev-requirements.txt`. This includes `pytest` and `pytest-frappe`.

&nbsp;   ```bash

&nbsp;   pip install -r dev-requirements.txt

&nbsp;   ```



2\.  \*\*Install Frappe Bench:\*\*

&nbsp;   The core `frappe` module is not included in the requirements file. You need to install it separately. The `frappe-bench` package includes it.

&nbsp;   ```bash

&nbsp;   pip install frappe-bench

&nbsp;   ```



\### Running Tests



The test suite uses `pytest`. However, running `pytest` directly may fail with a `ModuleNotFoundError: No module named 'frappe'`.



This is because the test runner expects to be run within a Frappe "bench" context, which has a `sites` directory and a default site. This environment does not have a pre-configured bench or site.



\*\*Note:\*\* The tests could not be successfully run in the current environment due to this configuration issue. A full `bench init` and `new-site` setup may be required to get the tests to pass.




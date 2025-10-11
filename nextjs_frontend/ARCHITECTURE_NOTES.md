# Next.js Frontend Architecture & Integration Plan

This document outlines the architecture of the Vercel Gemini Chatbot template and a clear plan for integrating it with our Frappe backend.

## 1. Frontend Architecture Analysis

Based on a review of the `vercel-labs/gemini-chatbot` repository, the frontend has the following key components:

-   **Framework:** [Next.js 14](https://nextjs.org/) with the App Router. This enables a modern, performant, server-centric frontend.
-   **AI SDK:** [Vercel AI SDK](https://sdk.vercel.ai/docs). This provides a unified API for interacting with various Large Language Models (LLMs), including Google Gemini. It handles the complexities of streaming responses.
-   **Database:** [Vercel Postgres](https://vercel.com/storage/postgres) (powered by Neon) is used for data persistence.
-   **ORM:** [Drizzle ORM](https://orm.drizzle.team/) is used to interact with the Postgres database in a type-safe way. The schema for the chat history is defined in `db/schema.ts`.
-   **API Layer:** The Next.js App Router is used to create API endpoints. The core chat logic resides in `app/api/chat/route.ts`. This endpoint is responsible for receiving user messages and streaming back the AI's response.

## 2. The "Two Brains" Architecture

Our integrated system is designed around a "Two Brains" concept:

1.  **The Frontend's "Conversational" Brain:** This is the chat history stored in the Vercel Postgres database. Its purpose is to maintain the state of a single conversation, providing short-term, tactical memory.
2.  **The Frappe Backend's "Operational" Brain:** This is our custom `brain` module. Its purpose is to create a permanent, auditable record of significant business events (`Engrams`). This provides long-term, strategic memory.

## 3. The Integration Plan: An API Bridge

The key to unlocking the system's full potential is to connect these two brains. We will do this by creating an **API Bridge**.

The flow will be as follows:

1.  **User Finishes Chat:** A user completes a conversation with the AI on the Next.js frontend.
2.  **Frontend Server Action:** A new server-side function will be created in the Next.js application. This function will be triggered when a chat session is deemed complete. It will:
    a.  Accept a `chatId` as input.
    b.  Use Drizzle ORM to fetch the entire conversation transcript (all user and AI messages) from the Vercel Postgres database.
    c.  Package this transcript into a JSON object.
3.  **Call the Frappe Backend:** The Next.js server will then make a `POST` request to a new, dedicated endpoint on our Frappe backend.
4.  **Backend Summarization:** The Frappe endpoint will receive the chat transcript. It will then:
    a.  Make its own API call to an AI model (like Gemini) with a specific prompt: *"Summarize the key outcomes and actions from this conversation."*
    b.  Take the AI's summary.
5.  **Create the Engram:** The Frappe endpoint will call the `brain.record_event` function, passing the AI-generated summary as the `message`. This will create a new `Engram` record, permanently storing a memory of the conversation's purpose and outcome in our long-term operational brain.

This architecture creates a powerful feedback loop, allowing the system to have a memory of not just *what* happened, but *why* it happened, based on user intent.

---

## 4. Frontend Implementation Guide

To integrate the Next.js frontend with the Frappe backend, the following steps should be taken:

### Step 1: Identify Chat Session "Type"

The frontend application should be aware of the context or "type" of each chat session. Examples include:
-   `"Onboarding"`: The initial series of questions to set up a user's account.
-   `"General Inquiry"`: A user asking questions or requesting information.
-   `"Support Request"`: A user asking for help with a problem.
-   `"Data Entry"`: A user asking the AI to create or modify data (e.g., "create an invoice").

### Step 2: Implement Conditional Summarization

At the end of a chat session, the frontend should decide **whether or not** to create a summary based on the session type.

-   **DO NOT Summarize:** Sessions where the primary outcome is a series of successful API calls to create or update data (e.g., `"Onboarding"`, `"Data Entry"`). The `brain` module's document hooks will have already recorded these actions. A summary would be redundant.
-   **DO Summarize:** Sessions where the user's intent and the AI's response are not captured by other means (e.g., `"General Inquiry"`, `"Support Request"`).

### Step 3: Call the Backend API

If a summary is required, the frontend server should:
1.  Use the Gemini AI to generate a concise summary of the conversation.
2.  Make a `POST` request to the `rokct.brain.api.record_chat_summary` endpoint.
3.  Send the `summary_text` in the request body.
4.  (Optional) If the conversation was about a specific document (e.g., a specific project or invoice), include the `reference_doctype` and `reference_name` in the request body to link the memory correctly. If not, the memory will be automatically linked to the user who initiated the chat.
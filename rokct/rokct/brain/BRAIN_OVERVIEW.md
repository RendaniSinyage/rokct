# Brain Module Overview

## The Vision: An Autonomous Business Brain

The `brain` module is designed to be the cognitive engine of the application. Its purpose is to transform the raw data of everyday business operations into a structured, persistent memory. This memory then becomes the foundation for a system that can learn from past events, identify patterns, and eventually take automated actions.

The system is built on three pillars, designed to mimic the functions of a real brain:

### 1. The Senses (Event Detection)

Just as a real brain has senses to perceive the world, this module has "senses" to detect events happening within the application.

*   **What it does:** Using a powerful, system-wide hook, the `brain` automatically "sees" almost every important action that occurs—a new order being created, a customer's address being updated, an invoice being sent, etc.
*   **How it works:** These raw events are captured as **`Synaptic Events`**. Each one is a small, temporary record of a single action. This is the system's "nervous system."

### 2. Reasoning (The Storytelling Engine)

A brain doesn't just store raw data; it processes it into a coherent story. This is the "reasoning" pillar of our system.

*   **What it does:** A scheduled background job runs every few minutes, acting as the "storytelling" part of the brain. It reads the raw `Synaptic Events` and intelligently weaves them together.
*   **How it works:** It groups all the events related to a single document (like a specific invoice) and compounds them into a clean, human-readable summary. It understands who did what and when, and it combines related actions to tell a clear story.

### 3. Memory (The Permanent Record)

The final result of this reasoning process is a permanent, long-term memory.

*   **What it is:** The compounded story for each document is stored in a permanent record called an **`Engram`** (the scientific term for a memory trace).
*   **How it works:** There is one `Engram` for each core business document. This record provides a complete, evolving history of everything that has ever happened to that document, from its creation to its most recent update. This is the system's "long-term memory."

By building this foundation of Senses, Reasoning, and Memory, we have created a system that is not just a passive database, but an active, learning "business brain" that can be extended in the future to perform truly autonomous actions.